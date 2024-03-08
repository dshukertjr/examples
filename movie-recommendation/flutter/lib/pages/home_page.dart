import 'package:filmsearch/components/movie_cell.dart';
import 'package:filmsearch/main.dart';
import 'package:filmsearch/models/movie.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final moviesFuture = supabase
      .from('movies')
      .select()
      .order('release_date')
      .withConverter<List<Movie>>((data) => data.map(Movie.fromJson).toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
      ),
      body: FutureBuilder(
          future: moviesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrintStack(stackTrace: snapshot.stackTrace);
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final movies = snapshot.data!;
            return ListView.builder(
              itemBuilder: (context, index) {
                final movie = movies[index];
                return MovieCell(movie: movie);
              },
              itemCount: movies.length,
            );
          }),
    );
  }
}
