import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:sint/sint.dart';

import 'full_screen_image_controller.dart';

class FullScreenImagePage extends StatelessWidget {
  const FullScreenImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SintBuilder<FullScreenImageController>(
      id: AppPageIdConstants.mediaFullScreen,
      init: FullScreenImageController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppFlavour.getBackgroundColor(),
        body: InteractiveViewer(
          child: Container(
            decoration: AppTheme.boxDecoration,
            child: GestureDetector(
              child: Center(
                child: Hero(
                    tag: controller.isRemote ? 'img_url_hero_${controller.mediaUrl}' : 'img_file_hero_${controller.mediaUrl}',
                    child: controller.isRemote || kIsWeb
                        ? HandledCachedNetworkImage(controller.mediaUrl)
                        : Image.file(File(controller.mediaUrl) as dynamic,
                    ),
                ),
              ),
              onTap: () {
                Sint.back();
              },
            ),
          ),
        )
      )
    );
  }

}
