import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:seasoncalendar/models/region.dart';

import 'availability.dart';


List<Food> getFoodsFromIds(List<String> foodIds, List<Food> allFoods) {
  var matchingFoods = List<Food>.empty(growable: true);
  Map<String, Food> allFoodsMap = {
    for (var food in allFoods)
      food.id: food,
  };
  for (var id in foodIds) {
    if (allFoodsMap.containsKey(id)) {
      matchingFoods.add(allFoodsMap[id]!);
    }
  }
  return matchingFoods;
}

List<String> splitByCommaAndTrim(String stringifiedList) {
  return stringifiedList.split(",").map((elem) => elem.trim()).toList();
}

class Food {
  String id;
  String displayName = "...";
  List<String> synonyms = List.empty();
  String typeInfo;
  bool isCommon;
  LinkedHashMap<String, List<Availability>> availabilities = LinkedHashMap();
  String infoUrl;
  String assetImgPath;
  String assetImgSourceUrl;
  String assetImgInfo;
  Region region;

  Food(
      this.id,
      String foodNamesString,
      this.typeInfo,
      int commonInt,
      String avLocal,
      String avLand,
      String avSea,
      String avAir,
      this.infoUrl,
      this.assetImgPath,
      this.assetImgSourceUrl,
      this.assetImgInfo,
      this.region)
      : isCommon = commonInt == 1 {
    // handle names and synonyms
    synonyms = splitByCommaAndTrim(foodNamesString);
    displayName = synonyms[0];

    // handle availabilities
    availabilities = LinkedHashMap<String, List<Availability>>();
    availabilities['local'] =
        availabilitiesFromStringList(splitByCommaAndTrim(avLocal));
    availabilities['landTransport'] =
        availabilitiesFromStringList(splitByCommaAndTrim(avLand));
    availabilities['seaTransport'] =
        availabilitiesFromStringList(splitByCommaAndTrim(avSea));
    availabilities['flightTransport'] =
        availabilitiesFromStringList(splitByCommaAndTrim(avAir));
  }

  List<Availability> getAvailabilitiesByMonth(int monthIndex) {
    List<Availability> availabilitiesThisMonth = [
      Availability.none,
      Availability.none,
      Availability.none,
      Availability.none
    ];

    var avKeys = availabilities.keys.toList();
    for (int i = 0; i < avKeys.length; ++i) {
      var curKey = avKeys[i];
      var curAv = availabilities[curKey]![monthIndex];
      availabilitiesThisMonth[availabilityModeValues[curKey]!] = curAv;

      // lower av modes are disregarded if any mode is "full"
      if (curAv == f) break;
    }

    return availabilitiesThisMonth;
  }

  List<List<Availability>> getAvailabilitiesList() {
    return List.generate(
        12, (monthIndex) => getAvailabilitiesByMonth(monthIndex));
  }

  changeAvailabilitiesForMonth(List<Availability> av, int month) {
    for (int i = 0; i < availabilityNames.length; i += 1) {
      availabilities[availabilityNames[i]]![month] = av[i];
    }
  }

  bool isFruit() => typeInfo.toLowerCase().contains("fruit");
  bool isVegetable() => typeInfo.toLowerCase().contains("vegetable");
}
