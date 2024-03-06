import 'package:filmsearch/models/movie.dart';
import 'package:filmsearch/pages/details_page.dart';
import 'package:flutter/material.dart';

class MovieCell extends StatelessWidget {
  const MovieCell({
    super.key,
    required this.movie,
    this.fontSize = 20,
    this.isHeroEnabled = true,
  });
  final Movie movie;
  final double fontSize;
  final bool isHeroEnabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailsPage(movie: movie),
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
                tag: movie.imageUrl,
                child: Image.network(movie.imageUrl),
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
                  movie.title,
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
