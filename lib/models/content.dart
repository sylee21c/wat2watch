class Content {
  final String? id;
  final String? title;
  final String? originalTitle;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final String? releaseDate;
  final double? voteAverage;
  final int? voteCount;
  final double? popularity;
  final bool isMovie;
  final int? runtime;
  final List<String>? genres;
  final List<String>? productionCompanies;
  final List<String>? productionCountries;
  final List<String>? spokenLanguages;
  List<String>? ottList;
  final int? budget;
  final int? revenue;
  final String? tagline;
  final String? status;
  final String? homepage;
  final String? imdbId;
  final bool? adult;
  final bool? video;

  Content({
    this.id,
    this.title,
    this.originalTitle,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.releaseDate,
    this.voteAverage,
    this.ottList,
    this.voteCount,
    this.popularity,
    this.isMovie = true,
    this.runtime,
    this.genres,
    this.productionCompanies,
    this.productionCountries,
    this.spokenLanguages,
    this.budget,
    this.revenue,
    this.tagline,
    this.status,
    this.homepage,
    this.imdbId,
    this.adult,
    this.video,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id']?.toString(),
      title: json['title'] ?? json['name'],
      originalTitle: json['original_title'] ?? json['original_name'],
      overview: json['overview'],
      posterUrl: json['poster_path'],
      backdropUrl: json['backdrop_path'],
      releaseDate: json['release_date'] ?? json['first_air_date'],
      voteAverage: json['vote_average']?.toDouble(),
      voteCount: json['vote_count'],
      popularity: json['popularity']?.toDouble(),
      isMovie: json['title'] != null,
      runtime: json['runtime'],
      genres: json['genres'] != null
          ? (json['genres'] as List).map((g) => g['name'].toString()).toList()
          : null,
      productionCompanies: json['production_companies'] != null
          ? (json['production_companies'] as List)
          .map((pc) => pc['name'].toString())
          .toList()
          : null,
      productionCountries: json['production_countries'] != null
          ? (json['production_countries'] as List)
          .map((pc) => pc['name'].toString())
          .toList()
          : null,
      spokenLanguages: json['spoken_languages'] != null
          ? (json['spoken_languages'] as List)
          .map((sl) => sl['english_name'].toString())
          .toList()
          : null,
      ottList: json['ottList'] != null
          ? List<String>.from(json['ottList'])
          : null,
      budget: json['budget'],
      revenue: json['revenue'],
      tagline: json['tagline'],
      status: json['status'],
      homepage: json['homepage'],
      imdbId: json['imdb_id'],
      adult: json['adult'],
      video: json['video'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'original_title': originalTitle,
      'overview': overview,
      'poster_path': posterUrl,
      'backdrop_path': backdropUrl,
      'release_date': releaseDate,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'popularity': popularity,
      'runtime': runtime,
      'genres': genres?.map((g) => {'name': g}).toList(),
      'production_companies': productionCompanies?.map((pc) => {'name': pc}).toList(),
      'production_countries': productionCountries?.map((pc) => {'name': pc}).toList(),
      'spoken_languages': spokenLanguages?.map((sl) => {'english_name': sl}).toList(),
      'ottList': ottList,
      'budget': budget,
      'revenue': revenue,
      'tagline': tagline,
      'status': status,
      'homepage': homepage,
      'imdb_id': imdbId,
      'adult': adult,
      'video': video,
    };
  }
}