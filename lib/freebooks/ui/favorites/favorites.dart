import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../domain/models/freebook.dart';
import '../view_models/favorites_provider.dart';
import '../widgets/book.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  FavoritesState createState() => FavoritesState();
}

class FavoritesState extends State<Favorites> {

  @override
  void initState() {
    super.initState();
    getFavorites();
  }

  void getFavorites() {
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        if (mounted) {
          Provider.of<FreebooksFavoritesProvider>(context, listen: false).listen();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FreebooksFavoritesProvider>(
      builder: (BuildContext context, FreebooksFavoritesProvider favoritesProvider,
          Widget? child) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'Favorites',
            ),
          ),
          body: favoritesProvider.favorites.isEmpty
              ? _buildEmptyListView()
              : _buildGridView(favoritesProvider),
        );
      },
    );
  }

  Widget _buildEmptyListView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            'assets/images/empty.png',
            height: 300.0,
            width: 300.0,
          ),
          const Text(
            'Nothing is here',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(FreebooksFavoritesProvider favoritesProvider) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 0.0),
      shrinkWrap: true,
      itemCount: favoritesProvider.favorites.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 200 / 340,
      ),
      itemBuilder: (BuildContext context, int index) {
        Freebook entry = Freebook.fromJson(favoritesProvider.favorites[index]['item']);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: BookItem(
            img: entry.link![1].href!,
            title: entry.title!,
            entry: entry,
          ),
        );
      },
    );
  }
}
