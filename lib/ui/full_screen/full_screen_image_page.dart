import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'full_screen_image_controller.dart';

class FullScreenImagePage extends StatelessWidget {
  const FullScreenImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FullScreenImageController>(
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
                    child: controller.isRemote
                        ? CachedNetworkImage(imageUrl: controller.mediaUrl,)
                        : Image.file(File(controller.mediaUrl)
                    ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        )
      )
    );
  }

}
