import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:seasoncalendar/theme/themes.dart';
import 'package:seasoncalendar/components/favorite_foods.dart';
import 'package:seasoncalendar/models/food.dart';
import 'package:seasoncalendar/components/food_details_dialog.dart';
import 'package:seasoncalendar/generated/l10n.dart';

class FoodTile extends StatefulWidget {
  final Food _food;
  final int _curMonthIndex;
  final List<List<Availability>> _allAvailabilities;
  late List<Availability> _curAvailabilities;
  Color _curAvailabilityColor = Colors.white70;

  FoodTile(Food foodToDisplay, int curMonthIndex)
      : _food = foodToDisplay,
        _curMonthIndex = curMonthIndex,
        _allAvailabilities = List.generate(12,
                (monthIndex) => foodToDisplay.getAvailabilitiesByMonth(monthIndex)) {
    _curAvailabilities = _allAvailabilities[_curMonthIndex];
    int fstModeIdx = _curAvailabilities.indexWhere((mode) => mode != Availability.none);
    _curAvailabilityColor = availabilityModeColor[fstModeIdx]!;
  }

  @override
  FoodTileState createState() => new FoodTileState();
}

class FoodTileState extends State<FoodTile> {
  // -1 means 'not favorite', +1 means 'favorite', else undefined.
  int _isFavorite = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: isFavoriteFood(widget._food),
      builder: (context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          _isFavorite =
          snapshot.hasData ? (snapshot.data! ? 1 : -1) : _isFavorite;
        }
        return _buildFoodTile();
      },
    );
  }

  Widget _buildFoodTile() {
    GestureTapCallback tapCallback = () {};
    if (_isFavorite == 1) {
      tapCallback = () {
        removeFavoriteFood(widget._food.id);
        setState(() {
          _isFavorite = -1;
        });
      };
    } else if (_isFavorite == -1) {
      tapCallback = () {
        addFavoriteFood(widget._food.id);
        setState(() {
          _isFavorite = 1;
        });
      };
    }

    Image foodImage = Image(
      image: AssetImage(widget._food.assetImgPath),
      filterQuality: FilterQuality.low,
    );

    Container availabilityIconContainer = Container(
      color: Colors.white.withAlpha(220),
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: new LayoutBuilder(builder: (context, constraint) {
        return getAvailabilityIconContainer(
            context, constraint, widget._curAvailabilities);
      }),
    );

    List<Widget> actions = [];

    // TODO feature for editing availabilities
    if (false) {
      actions.add(MaterialButton(
        onPressed: () async {
        },
        child: Text("Edit"), // TODO l10n
      ));
    }

    actions += [
      MaterialButton(
        onPressed: () async {
          final url = widget._food.infoUrl;
          if (await canLaunch(url)) {
            await launch(
              url,
              forceSafariVC: false,
            );
          }
        },
        child: Text(L10n.of(context).wikipedia),
      ),
      MaterialButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(L10n.of(context).back)),
    ];

    GestureTapCallback showFoodInfo = () {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          content: FoodDetailsDialog(
              widget._food,
              foodImage,
              widget._allAvailabilities),
          elevation: 10,
          actions: actions,
         // actionsPadding: EdgeInsets.symmetric(horizontal: 4),
        ),
        barrierDismissible: true,
      );
    };

    return Card(
        elevation: 3,
        color: widget._curAvailabilityColor,
        child: Column(
          children: <Widget>[
            Expanded(
                flex: 10,
                child: Stack(
                  overflow: Overflow.clip,
                  alignment: AlignmentDirectional.topEnd,
                  children: <Widget>[
                    GestureDetector(
                      onTap: showFoodInfo,
                      child: foodImage,
                    ),
                    FractionallySizedBox(
                      widthFactor: 2.5 / 12,
                      heightFactor: 2.5 / 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: ShapeDecoration(
                            color: Colors.white.withAlpha(200),
                            shape: OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(0),
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(0),
                                  topRight: Radius.circular(0)),
                              borderSide: BorderSide(
                                  width: 0, color: Colors.white.withAlpha(200)),
                            )),
                        child: InkWell(
                          onTap: tapCallback,
                          child:
                          new LayoutBuilder(builder: (context, constraint) {
                            return getFavIcon(context, constraint, _isFavorite);
                          }),
                        ),
                      ),
                    ),
                  ],
                )),
            Expanded(
                flex: 2,
                child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                widget._food.displayName,
                                style: foodText,
                              ),
                            ),
                          ),
                        ),
                        availabilityIconContainer
                      ],
                    )))
          ],
        ));
  }
}

Icon getFavIcon(context, constraint, int isFavorite) {
  if (isFavorite == 1)
    return Icon(Icons.star, size: constraint.biggest.height);
  else if (isFavorite == -1)
    return Icon(Icons.star_border, size: constraint.biggest.height);
  else
    return Icon(Icons.star_half, size: constraint.biggest.height);
}

Container getAvailabilityIconContainer(
    BuildContext context, constraint, List<Availability> availabilities) {

  Widget containerChild;
  int fstModeIdx = availabilities.indexWhere((mode) => mode != Availability.none);
  int sndModeIdx = availabilities.indexWhere((mode) => mode != Availability.none, fstModeIdx + 1);


  if (fstModeIdx == -1) {
    int iconAlpha = getIconAlphaFromAvailability(Availability.none);
    containerChild = Icon(availabilityModeIcons[fstModeIdx],
        size: constraint.biggest.height, color: Colors.black.withAlpha(iconAlpha));
  }
  else if (sndModeIdx == -1) {
    int iconAlpha = getIconAlphaFromAvailability(availabilities[fstModeIdx]);
    containerChild = Icon(availabilityModeIcons[fstModeIdx],
        size: constraint.biggest.height, color: Colors.black.withAlpha(iconAlpha));
  } else {
    int primaryIconAlpha = getIconAlphaFromAvailability(availabilities[fstModeIdx]);
    int secondaryIconAlpha = getIconAlphaFromAvailability(availabilities[sndModeIdx]);
    containerChild = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Icon(availabilityModeIcons[fstModeIdx],
            size: constraint.biggest.height,
            color: Colors.black.withAlpha(primaryIconAlpha)),
        Text(" / "),
        Icon(availabilityModeIcons[sndModeIdx],
            size: constraint.biggest.height / 1.4,
            color: Colors.black.withAlpha(secondaryIconAlpha)),
      ],
    );
  }

  return Container(
    child: containerChild,
  );
}
