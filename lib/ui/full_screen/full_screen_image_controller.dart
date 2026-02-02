import 'package:sint/sint.dart';
import 'package:neom_core/app_config.dart';

class FullScreenImageController extends SintController {

  String mediaUrl = "";
  bool isRemote = true;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.i("MediaFullScreen Controller Init");

    try {

      if(Sint.arguments != null && Sint.arguments.isNotEmpty) {
        mediaUrl = Sint.arguments[0];
        if(Sint.arguments.length > 1) {
          isRemote = Sint.arguments[1];
        }
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }


}
