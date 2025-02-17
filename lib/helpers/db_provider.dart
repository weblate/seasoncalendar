import 'dart:io';

import 'package:mutex/mutex.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:seasoncalendar/generated/l10n.dart';
import 'package:seasoncalendar/models/food.dart';
import 'package:seasoncalendar/models/region.dart';
import 'package:seasoncalendar/screens/settings/settings_screen.dart';
import 'package:sqflite/sqflite.dart';

import 'lang_helper.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();
  static final Mutex _db_file_mutex = Mutex();
  static Database? _database;
  static String dbViewName = "null";

  Future<Database> get database async {
    var settings = await SettingsPageState.getSettings();
    var langCode = settings['languageCode'];
    if (langCode == "null") {
      langCode = L10n.current.languageCode;
    }
    String targetDBViewName =
        "foods_" + langCode + "_" + settings['regionCode'];
    dbViewName = targetDBViewName;

    if (_database == null) {
      await _db_file_mutex.acquire();
      try {
        if (_database == null) _database = await initDB();
      } finally {
        _db_file_mutex.release();
      }
    }

    return _database!;
  }

  initDB() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "foods.db");

    // always get a fresh asset copy
    await deleteDatabase(path);

    // Make sure the parent directory exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    // Copy from asset
    ByteData data = await rootBundle.load(join("assets/db", "foods.db"));
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Write and flush the bytes written
    await File(path).writeAsBytes(bytes, flush: true);

    // open and return the database
    var res = await openDatabase(path);
    return res;
  }

  Future<Iterable<Region>> getRegions() async {
    final Database db = await database;

    final List<Map<String, dynamic>> results = await db.rawQuery("""
        SELECT id, fallbackRegion, assetPath
        FROM regions 
        """, []);

    return results.map((item) {
      Region region = Region();
      region.id = item['id'];
      region.fallbackRegion = item['fallbackRegion'];
      region.assetPath = item['assetPath'];
      region.name = getTranslationByKey(region.assetPath);
      return region;
    }).toList();
  }

  Future<Region> getCurrentRegion() async {
    final Database db = await database;
    var settings = await SettingsPageState.getSettings();
    var regionCode = settings['regionCode'];

    final List<Map<String, dynamic>> results = await db.rawQuery("""
        SELECT id, fallbackRegion, assetPath
        FROM regions 
        WHERE id = ?
        """, [regionCode]);

    if (results.length != 1) {
      throw "current Region not in Database";
    }

    Region region = Region();
    region.id = results[0]['id'];
    region.fallbackRegion = results[0]['fallbackRegion'];
    region.assetPath = results[0]['assetPath'];
    region.name = getTranslationByKey(region.assetPath);
    return region;
  }

  Future<List<Food>> getFoods() async {
    final Database db = await database;

    var region = await getCurrentRegion();
    var allRegions = await getRegions();

    var fallbackRegion = region.fallbackRegion ?? "NULL";

    // get the foods
    final List<Map<String, dynamic>> results = await db.rawQuery("""
        SELECT f.id AS id, f.type AS type, f.assetImgPath AS assetImgPath, f.assetImgInfo AS assetImgInfo, f.assetImgSourceUrl as assetImgSourceUrl, 
               fr.region_id as region_id, fr.is_common as is_common, fr.avLocal as avLocal, fr.avLand as avLand, fr.avSea as avSea, fr.avAir as avAir
        FROM foods AS f
        INNER JOIN food_region_availability AS fr ON (f.id == fr.food_id)
        WHERE fr.region_id = ?
        
        UNION
        
        SELECT f.id AS id, f.type AS type, f.assetImgPath AS assetImgPath, f.assetImgInfo AS assetImgInfo, f.assetImgSourceUrl as assetImgSourceUrl, 
               fr.region_id as region_id, fr.is_common as is_common, fr.avLocal as avLocal, fr.avLand as avLand, fr.avSea as avSea, fr.avAir as avAir
        FROM foods AS f
        INNER JOIN food_region_availability AS fr ON (f.id == fr.food_id)
        WHERE fr.region_id = ?
        AND f.id NOT IN (SELECT f.id
        FROM foods AS f
        INNER JOIN food_region_availability AS fr ON (f.id == fr.food_id)
        WHERE fr.region_id = ?)
        """, [region.id, fallbackRegion, region.id ]);

    return results.map((item) {
      String foodId = item['id'];
      String type = item['type'];
      String assetImgPath = item['assetImgPath'];
      String assetImgSourceUrl = item['assetImgSourceUrl'];
      String assetImgInfo = item['assetImgInfo'];

      Region region = allRegions.firstWhere((region) => region.id == item['region_id']);
      int isCommon = item['is_common'];
      String avLocal = item['avLocal'];
      String avLand = item['avLand'];
      String avSea = item['avSea'];
      String avAir = item['avAir'];

      String foodNamesString = getTranslationByKey(foodId + "_names");
      String infoUrl = getTranslationByKey(foodId + "_infoUrl");

      return Food(foodId, foodNamesString, type, isCommon, avLocal, avLand,
          avSea, avAir, infoUrl, assetImgPath, assetImgSourceUrl, assetImgInfo, region);
    }).toList();
  }
}
