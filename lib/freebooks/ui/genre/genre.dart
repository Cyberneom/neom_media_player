import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:provider/provider.dart';

import '../../domain/models/freebook.dart';
import '../view_models/genre_provider.dart';
import '../widgets/body_builder.dart';
import '../widgets/book_list_item.dart';
import '../widgets/loading_widget.dart';

class Genre extends StatefulWidget {
  final String title;
  final String url;

  const Genre({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  GenreState createState() => GenreState();
}

class GenreState extends State<Genre> {

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => Provider.of<FreebooksGenreProvider>(context, listen: false)
          .getFeed(widget.url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, FreebooksGenreProvider provider, Widget? child) {
        return Scaffold(
          appBar: AppBarChild(title: widget.title, color: AppColor.bondiBlue75,),
          backgroundColor: AppColor.getMain(),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(FreebooksGenreProvider provider) {
    return BodyBuilder(
      apiRequestStatus: provider.apiRequestStatus,
      child: _buildBodyList(provider),
      reload: () => provider.getFeed(widget.url),
    );
  }

  Widget _buildBodyList(FreebooksGenreProvider provider) {
    return ListView(
      controller: provider.controller,
      children: <Widget>[
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          shrinkWrap: true,
          itemCount: provider.items.length,
          itemBuilder: (BuildContext context, int index) {
            Freebook entry = provider.items[index];
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: BookListItem(
                entry: entry,
              ),
            );
          },
        ),
        const SizedBox(height: 10.0),
        provider.loadingMore
            ? SizedBox(
                height: 80.0,
                child: _buildProgressIndicator(),
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return const LoadingWidget();
  }
}
