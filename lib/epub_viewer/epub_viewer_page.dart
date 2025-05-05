import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';

import 'epub_viewer_appbar.dart';
import 'epub_viewer_controller.dart';

class EPUBViewerPage extends StatelessWidget {

  const EPUBViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EPUBViewerController>(
      id: AppPageIdConstants.epubViewer,
      init: EPUBViewerController(),
      builder: (_) => Obx(()=> Scaffold(
        backgroundColor: AppColor.main50,
        appBar: EPUBViewerAppBar(title: _.epubTitle),
        drawer: _.epubReaderController != null ? Drawer(
            child: Container(
              color: AppColor.drawer,
              child: EpubViewTableOfContents(controller: _.epubReaderController!,
              ),
            ),
        ) : null,
        body: _.isLoading.value || _.epubReaderController == null ? const AppCircularProgressIndicator() : Container(
          decoration: AppTheme.appBoxDecoration,
          child: EpubView(
              builders: EpubViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                chapterDividerBuilder: (_) => const Divider(),
              ),
              controller: _.epubReaderController!
          ),
        ),
      ),),
    );
  }

}
