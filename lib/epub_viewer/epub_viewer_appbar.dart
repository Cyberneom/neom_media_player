import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

// ignore: must_be_immutable
class EPUBViewerAppBar extends StatelessWidget implements PreferredSizeWidget {

  final String title;
  Color? color;
  bool goBack;

  EPUBViewerAppBar({this.title = "", this.color, this.goBack = false, super.key});

  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {

    color ??= AppColor.appBar;

    return AppBar(
      title: Text(title.capitalize, style: TextStyle(color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      elevation: 0.0,
      actions: [
        TextButton(
          child: Text(AppTranslationConstants.goBack.tr,
            style: const TextStyle(fontSize: 15,
                color: AppColor.lightGrey,
                decoration: TextDecoration.underline
            ),
          ),
          onPressed: ()=> Navigator.pop(context)
        ),
      ],
    );
  }

}
