import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:provider/provider.dart';

import '../../domain/models/freebook.dart';
import '../../domain/models/freebook_link.dart';
import '../../freebooks_router.dart';
import '../genre/genre.dart';
import '../view_models/home_provider.dart';
import '../widgets/body_builder.dart';
import '../widgets/book_card.dart';
import '../widgets/book_list_item.dart';

class FreebookBooksPage extends StatefulWidget {
  const FreebookBooksPage({super.key});

  @override
  FreebookBooksPageState createState() => FreebookBooksPageState();
}

class FreebookBooksPageState extends State<FreebookBooksPage> with AutomaticKeepAliveClientMixin {

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => Provider.of<FreebooksHomeProvider>(context, listen: false).getFeeds(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<FreebooksHomeProvider>(
      builder: (BuildContext context, FreebooksHomeProvider homeProvider, Widget? child) {
        return Scaffold(
          backgroundColor: AppColor.main50,
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
    return RefreshIndicator(
      onRefresh: () => homeProvider.getFeeds(),
      child: ListView(
        children: <Widget>[
          Container(
            height: AppTheme.fullHeight(context) / 15,
            width: AppTheme.fullWidth(context),
            decoration: const BoxDecoration(
              color: AppColor.bondiBlue75,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppTheme.heightSpace10,
                Text(AppTranslationConstants.publicDomainReadings.tr,
                    style: Theme.of(context).textTheme.headlineSmall!
                        .copyWith(color: AppColor.white)
                ),
                AppTheme.heightSpace10,
              ],
            ),
          ),
          _buildFeaturedSection(homeProvider),
          const SizedBox(height: 20.0),
          _buildSectionTitle(AppTranslationConstants.categories.tr),
          const SizedBox(height: 10.0),
          _buildGenreSection(homeProvider),
          const SizedBox(height: 20.0),
          _buildSectionTitle(AppTranslationConstants.freeDomain.tr),
          // _buildSectionTitle('Todo lo que encuentres en esta sección es de dominio público. Puedes descargarlo y darle uso con confianza.'),
          const SizedBox(height: 20.0),
          _buildNewSection(homeProvider),
        ],
      ),
    );
  }

  Padding _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  SizedBox _buildFeaturedSection(FreebooksHomeProvider homeProvider) {
    return SizedBox(
      height: 200.0,
      child: Center(
        child: ListView.builder(
          primary: false,
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          scrollDirection: Axis.horizontal,
          itemCount: homeProvider.top.feed?.entry?.length ?? 0,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            Freebook entry = homeProvider.top.feed!.entry![index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              child: BookCard(
                img: (entry.link?.length ?? 0) > 1 ? entry.link![1].href! : entry.link![0].href!,
                entry: entry,
              ),
            );
          },
        ),
      ),
    );
  }

  SizedBox _buildGenreSection(FreebooksHomeProvider homeProvider) {
    return SizedBox(
      height: 50.0,
      child: Center(
        child: ListView.builder(
          primary: false,
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          scrollDirection: Axis.horizontal,
          itemCount: homeProvider.top.feed?.link?.length ?? 0,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            FreebookLink link = homeProvider.top.feed!.link![index];

            // We don't need the tags from 0-9 because
            // they are not categories
            if (index < 10) {
              return const SizedBox();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColor.bondiBlue75,
                  borderRadius: BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                ),
                child: InkWell(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20.0),
                  ),
                  onTap: () {
                    NeomFreebooksRouter.pushPage(
                      context,
                      Genre(
                        title: '${link.title}',
                        url: link.href!,
                      ),
                    );
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        '${link.title}',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ListView _buildNewSection(FreebooksHomeProvider homeProvider) {
    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: (homeProvider.recent.feed?.entry?.length ?? 0) > 20 ? 20 : homeProvider.recent.feed?.entry?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        Freebook? entry = homeProvider.recent.feed?.entry?[index];

        return entry !=null ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
          child: BookListItem(
            entry: entry,
          ),
        ) : SizedBox.shrink();
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
