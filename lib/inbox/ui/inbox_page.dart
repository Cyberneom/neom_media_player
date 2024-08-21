import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/inbox.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_in_use.dart';
import 'inbox_controller.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InboxController>(
      id: AppPageIdConstants.inbox,
      init: InboxController(),
      builder: (_) =>
        Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppFlavour.appInUse == AppInUse.c ? null : AppBarChild(title: AppTranslationConstants.inbox.tr),
          backgroundColor: AppColor.main50,
          body: Container(
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading.value
              ? const AppCircularProgressIndicator()
              : _.inboxs.isNotEmpty ? ListView.builder(
                  itemCount: _.sortedInbox.value.length,
                  itemBuilder: (context, index) {
                    Inbox inbox = _.sortedInbox.value.values.toList().reversed.elementAt(index);
                    List<AppProfile> profiles = inbox.profiles ?? [];
                    AppProfile itemmate = profiles.isNotEmpty ? profiles.first : AppProfile();
                    return GestureDetector(
                      child: ListTile(
                        onTap: () =>
                            Get.toNamed(AppRouteConstants.inboxRoom,
                                arguments: [inbox]),
                        leading: itemmate.name.isEmpty ? const CircularProgressIndicator()
                        : Hero(
                          tag: itemmate.photoUrl,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(itemmate.photoUrl.isEmpty
                                ? AppFlavour.getNoImageUrl() : itemmate.photoUrl),
                          ),
                        ),
                        title: itemmate.name.isEmpty ? const LinearProgressIndicator(minHeight: 0.5) : Text(itemmate.name),
                        subtitle: Text(inbox.lastMessage!.text)
                      ),
                      onLongPress: () => {},
                    );
                  }
              ) : Center(child: Text(AppTranslationConstants.noMsgsWereFound.tr)),
            ),
          ),
    );
  }
}
