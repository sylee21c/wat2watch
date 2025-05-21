import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:wat2watch/wat2watch_server.dart';
import 'package:wat2watch/api/tmdb.dart';

void main() async {
  const tmdbApiKey = '70eacb5a78b9c9c51fabb57426c078e4';

  final tmdb = TmdbApi(tmdbApiKey);
  final server = Wat2WatchServer(tmdb);

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(server.router);

  final httpServer = await shelf_io.serve(handler, 'localhost', 8080);
  print('Server listening on: http://${httpServer.address.host}:${httpServer.port}');
}
