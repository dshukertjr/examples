class Movie {
  final int id;
  final String title;
  final String overview;
  final String imageUrl;
  final DateTime releaseDate;
  final String embedding;

  Movie.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        title = json['title'] as String,
        overview = json['overview'] as String,
        imageUrl =
            'https://image.tmdb.org/t/p/w500${json['backdrop_path'] as String}',
        releaseDate = DateTime.parse(json['release_date'] as String),
        embedding = json['embedding'] as String;
}
