import 'package:flutter/material.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:provider/provider.dart';

import '../../data/freebooks_api.dart';
import '../../domain/models/category_feed.dart';
import '../../domain/models/freebook.dart';
import '../../domain/models/freebook_link.dart';
import '../../freebooks_router.dart';
import '../genre/genre.dart';
import '../view_models/home_provider.dart';
import '../widgets/body_builder.dart';
import '../widgets/book_card.dart';

class ExploreLibraryPage extends StatefulWidget {
  const ExploreLibraryPage({super.key});

  @override
  ExploreLibraryPageState createState() => ExploreLibraryPageState();
}

class ExploreLibraryPageState extends State<ExploreLibraryPage> {
  FreebooksAPI api = FreebooksAPI();

  @override
  Widget build(BuildContext context) {
    return Consumer<FreebooksHomeProvider>(
      builder: (BuildContext context, FreebooksHomeProvider homeProvider, Widget? child) {
        return Scaffold(
          backgroundColor: AppColor.getMain(),
          body: BodyBuilder(
            apiRequestStatus: homeProvider.apiRequestStatus,
            child: _buildBodyList(homeProvider),
            reload: () => homeProvider.getFeeds(),
          ),
        );
      },
    );
  }

  Widget _buildBodyList(FreebooksHomeProvider homeProvider) {
    return ListView.builder(
      itemCount: homeProvider.top.feed?.link?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        FreebookLink link = homeProvider.top.feed!.link![index];

        // We don't need the tags from 0-9 because
        // they are not categories
        if (index < 10) {
          return const SizedBox();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            children: <Widget>[
              _buildSectionHeader(link),
              const SizedBox(height: 10.0),
              _buildSectionBookList(link),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(FreebookLink link) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              '${link.title}',
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              NeomFreebooksRouter.pushPage(
                context,
                Genre(
                  title: '${link.title}',
                  url: link.href!,
                ),
              );
            },
            child: Text(
              'Ver Todo',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBookList(FreebookLink link) {
    return FutureBuilder<CategoryFeed>(
      future: api.getCategory(link.href!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          CategoryFeed category = snapshot.data!;

          return SizedBox(
            height: 200.0,
            child: Center(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                scrollDirection: Axis.horizontal,
                itemCount: category.feed!.entry!.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  Freebook entry = category.feed!.entry![index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.0,
                      vertical: 10.0,
                    ),
                    child: BookCard(
                      img: entry.link![1].href!,
                      entry: entry,
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          return const AppCircularProgressIndicator();
        }
      },
    );
  }
}
