import 'package:filmsearch/components/movie_cell.dart';
import 'package:filmsearch/main.dart';
import 'package:filmsearch/models/movie.dart';
import 'package:flutter/material.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.movie});

  final Movie movie;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late final Future<List<Movie>> relatedMoviesFuture;

  @override
  void initState() {
    super.initState();
    relatedMoviesFuture = supabase.rpc('get_related_movie', params: {
      'embedding': widget.movie.embedding,
      'movie_id': widget.movie.id,
    }).withConverter<List<Movie>>((data) =>
        List<Map<String, dynamic>>.from(data).map(Movie.fromJson).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
      ),
      body: ListView(
        children: [
          Hero(
            tag: widget.movie.imageUrl,
            child: Image.network(widget.movie.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.movie.releaseDate,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.movie.overview,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  'You might also like:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Movie>>(
              future: relatedMoviesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final movies = snapshot.data!;
                return Wrap(
                  children: movies
                      .map((movie) => InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      DetailsPage(movie: movie)));
                            },
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              child: MovieCell(
                                movie: movie,
                                isHeroEnabled: false,
                                fontSize: 16,
                              ),
                            ),
                          ))
                      .toList(),
                );
              }),
        ],
      ),
    );
  }
}
