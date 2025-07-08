import 'package:get/get.dart';
import 'package:neom_core/app_config.dart';

class MediaFullScreenController extends GetxController {

  String mediaUrl = "";
  bool isRemote = true;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.i("MediaFullScreen Controller Init");

    try {

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        mediaUrl = Get.arguments[0];
        if(Get.arguments.length > 1) {
          isRemote = Get.arguments[1];
        }
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }


}
