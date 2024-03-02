import 'package:filmsearch/components/film_cell.dart';
import 'package:filmsearch/main.dart';
import 'package:filmsearch/models/film.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.film});

  final Film film;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late final Future<List<Film>> relatedFilmsFuture;

  @override
  void initState() {
    super.initState();
    relatedFilmsFuture = supabase.rpc('get_related_film', params: {
      'embedding': widget.film.embedding,
      'film_id': widget.film.id,
    }).withConverter<List<Film>>((data) =>
        List<Map<String, dynamic>>.from(data).map(Film.fromJson).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.film.title),
      ),
      body: ListView(
        children: [
          Hero(
            tag: widget.film.imageUrl,
            child: Image.network(widget.film.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  DateFormat.yMMMd().format(widget.film.releaseDate),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.film.overview,
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
          FutureBuilder<List<Film>>(
              future: relatedFilmsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final films = snapshot.data!;
                return Wrap(
                  children: films
                      .map((film) => InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      DetailsPage(film: film)));
                            },
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              child: FilmCell(
                                film: film,
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
