import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum Availability { none, some, full }

const Availability n = Availability.none;
const Availability s = Availability.some;
const Availability f = Availability.full;

Availability _fromDouble(double val) {
  if (val == 0.0) return n;
  if (val == 1.0) return f;
  return s;
}

double _toDouble(Availability av) {
  if (av == n) return 0.0;
  if (av == f) return 1.0;
  return 0.5;
}

int compareAvailabilities(List<Availability> av1, List<Availability> av2) {
  // ASSUMING: av1.length == av2.length
  for (int i = 0; i < av1.length; ++i) {
    int comp = _toDouble(av2[i]).compareTo(_toDouble(av1[i]));
    if (comp != 0) return comp;
  }
  return 0;
}

int getIconAlphaFromAvailability(Availability av) {
  if (av == n) return 230;
  if (av == f) return 200;
  return 120;
}

const Map<Availability, double> availabilityToIconAlphaFactor = {
  Availability.none: 1.0,
  Availability.full: 1.0,
  Availability.some: 0.5
};

const Map<int, IconData> availabilityModeIcons = {
  0: Icons.home,
  1: Icons.local_shipping,
  2: Icons.directions_boat,
  3: Icons.airplanemode_active,
  -1: Icons.remove,
};
Map<int, Color> availabilityModeColor = {
  0: Colors.lightGreenAccent[100],
  1: Colors.lime[200],
  2: Colors.yellowAccent[100],
  3: Colors.orangeAccent[100],
  -1: Colors.grey[200],
};
const Map<String, int> availabilityModeValues = {
  "local": 0,
  "landTransport": 1,
  "seaTransport": 2,
  "flightTransport": 3,
  "notAvailable": -1,
};

List<Food> getFoodsFromIds(List<String> foodIds, List<Food> allFoods) {
  List<Food> matchingFoods = new List();
  Map<String, Food> allFoodsMap =
      Map.fromIterable(allFoods, key: (food) => food.id, value: (food) => food);
  foodIds.forEach((id) {
    if (allFoodsMap.containsKey(id)) {
      matchingFoods.add(allFoodsMap[id]);
    }
  });
  return matchingFoods;
}

List<String> splitByCommaAndTrim(String stringifiedList) {
  List<String> res = List<String>();
  stringifiedList.split(",").forEach((elem) {
    res.add(elem.trim());
  });
  return res;
}

List<Availability> availabilitiesFromStringList(List<String> avStringList) {
  List<Availability> availabilities = new List<Availability>();
  avStringList.forEach((av) {
    double avDouble = double.tryParse(av);
    availabilities.add(_fromDouble(avDouble ?? 0.0));
  });
  return availabilities;
}

class Food {
  String id;
  String displayName;
  List<String> synonyms;
  String type;
  bool isCommon;
  LinkedHashMap<String, List<Availability>> availabilities;
  String infoUrl;
  String assetImgPath;
  String assetImgSourceUrl;
  String assetImgInfo;

  Food(
      String id,
      String foodNamesString,
      String type,
      int isCommon,
      String avLocal,
      String avLand,
      String avSea,
      String avAir,
      String infoUrl,
      String assetImgPath,
      String assetImgSourceUrl,
      String assetImgInfo)
      : this.id = id,
        this.type = type,
        this.isCommon = isCommon == 1,
        this.infoUrl = infoUrl,
        this.assetImgPath = assetImgPath,
        this.assetImgSourceUrl = assetImgSourceUrl,
        this.assetImgInfo = assetImgInfo {
    // handle names and synonyms
    this.synonyms = splitByCommaAndTrim(foodNamesString);
    this.displayName = this.synonyms[0];

    // handle availabilities
    this.availabilities = LinkedHashMap<String, List<Availability>>();
    this.availabilities['local'] =
        availabilitiesFromStringList(splitByCommaAndTrim(avLocal));
    this.availabilities['landTransport'] =
        availabilitiesFromStringList(splitByCommaAndTrim(avLand));
    this.availabilities['seaTransport'] =
        availabilitiesFromStringList(splitByCommaAndTrim(avSea));
    this.availabilities['flightTransport'] =
        availabilitiesFromStringList(splitByCommaAndTrim(avAir));
  }

  List<Availability> getAvailabilitiesByMonth(int monthIndex) {
    List<Availability> availabilitiesThisMonth = [
      Availability.none,
      Availability.none,
      Availability.none,
      Availability.none
    ];

    var avKeys = this.availabilities.keys.toList();
    for (int i = 0; i < avKeys.length; ++i) {
      var curKey = avKeys[i];
      var curAv = this.availabilities[curKey][monthIndex];
      availabilitiesThisMonth[availabilityModeValues[curKey]] = curAv;

      // lower av modes are disregarded if any mode is "full"
      if (curAv == f) break;
    }

    return availabilitiesThisMonth;
  }
}
