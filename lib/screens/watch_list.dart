import 'package:filmaiada/models/movie.dart';
import 'package:filmaiada/widgets/favorite_movie.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:filmaiada/providers/movies_provider.dart';

class WatchListScreen extends StatefulWidget {
  const WatchListScreen({super.key});

  @override
  State<WatchListScreen> createState() => WatchListScreenState();
}

class WatchListScreenState extends State<WatchListScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? user = FirebaseAuth.instance.currentUser;
  List<Movie> _watchList = [];

  @override
  void initState() {
    super.initState();
    _loadWatchList();
  }

  Future<void> _loadWatchList() async {
    try {
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:Text("Usuário não está logado")));
        return;
      }

      final watchListSnapshot =
          await _database.child('watchLists/${user!.uid}').get();

      if (mounted) {
        if (watchListSnapshot.exists) {
          final watchListData = watchListSnapshot.value as Map?;

          if (watchListData != null && watchListData.containsKey('movies')) {
            final movieList = watchListData['movies'] as List?;

            if (movieList != null) {
              final watchListIds = movieList
                  .asMap()
                  .entries
                  .where((entry) => entry.value == true)
                  .map((entry) => (entry.key).toString())
                  .toList();

              final allMovies = MoviesProvider.of(context).state.movies;

              setState(() {
                _watchList = allMovies
                    .where((movie) => watchListIds.contains(movie.id.toString()))
                    .toList();
              });
            }
          }
        } else {
          setState(() {
            _watchList = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao carregar a Watch List: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Watch List")),
      body: _watchList.isEmpty
          ? const Center(child: Text('Sua Watch List está vazia!'))
          : ListView.builder(
              itemCount: _watchList.length,
              itemBuilder: (ctx, i) => FavoriteMovie(movie: _watchList[i]),
            ),
    );
  }
}
