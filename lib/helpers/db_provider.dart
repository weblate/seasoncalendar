import 'dart:typed_data';
import 'dart:io';

import 'package:sprintf/sprintf.dart';

import 'package:path/path.dart';

import 'package:seasoncalendar/screens/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

import 'package:intl/intl.dart';

import 'package:seasoncalendar/generated/l10n.dart';
import 'package:seasoncalendar/models/food.dart';


class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();
  static Database _database;
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
      _database = await initDB();
    }

    return _database;
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

  Future<dynamic> getFoods(BuildContext context) async {
    final Database db = await database;

    // create desired db view if it doesn't exist
    var settings = await SettingsPageState.getSettings();
    var regionCode = settings['regionCode'];

    // get the foods
    final List<Map<String, dynamic>> maps = await db.rawQuery("""
      SELECT f.id, f.type, f.assetImgPath, f.assetImgInfo, f.assetImgSourceUrl, fr.region_id, fr.is_common, fr.avLocal, fr.avLand, fr.avSea, fr.avAir
      FROM foods AS f
      INNER JOIN food_region_availability AS fr ON (f.id == fr.food_id AND fr.region_id = ?)
      WHERE fr.region_id = ?
      """, [regionCode]);

    return List.generate(maps.length, (i) {
      String foodId = maps[i]['id'];
      String type = maps[i]['type'];
      String assetImgPath = maps[i]['assetImgPath'];
      String assetImgSourceUrl = maps[i]['assetImgSourceUrl'];
      String assetImgInfo = maps[i]['assetImgInfo'];

      int isCommon = maps[i]['is_common'];
      String avLocal = maps[i]['avLocal'];
      String avLand = maps[i]['avLand'];
      String avSea = maps[i]['avSea'];
      String avAir = maps[i]['avAir'];

      String foodNamesString = Intl.message('', name: foodId+"_names");
      String infoUrl = Intl.message('', name: foodId+"_infoUrl");

      return Food(foodId, foodNamesString, type, isCommon, avLocal, avLand,
          avSea, avAir, infoUrl, assetImgPath, assetImgSourceUrl, assetImgInfo);
    });
  }
}
