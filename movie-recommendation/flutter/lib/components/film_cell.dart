import 'package:filmsearch/models/film.dart';
import 'package:filmsearch/pages/details_page.dart';
import 'package:flutter/material.dart';

class FilmCell extends StatelessWidget {
  const FilmCell({
    super.key,
    required this.film,
    this.fontSize = 20,
    this.isHeroEnabled = true,
  });
  final Film film;
  final double fontSize;
  final bool isHeroEnabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailsPage(film: film),
          ),
        );
      },
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: HeroMode(
              enabled: isHeroEnabled,
              child: Hero(
                tag: film.imageUrl,
                child: Image.network(film.imageUrl),
              ),
            ),
          ),
          Positioned.fill(
            top: null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black,
                  Colors.black.withAlpha(0),
                ],
              )),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  film.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
