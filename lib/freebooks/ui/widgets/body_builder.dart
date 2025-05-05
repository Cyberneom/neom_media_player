import 'package:flutter/material.dart';
import 'package:neom_commons/core/ui/widgets/app_circular_progress_indicator.dart';
import '../../utils/enum/api_request_status.dart';
import 'error_widget.dart';
import 'loading_widget.dart';

class BodyBuilder extends StatelessWidget {
  final APIRequestStatus apiRequestStatus;
  final Widget child;
  final Function reload;

  const BodyBuilder(
      {super.key,
      required this.apiRequestStatus,
      required this.child,
      required this.reload});

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  Widget _buildBody() {
    switch (apiRequestStatus) {
      case APIRequestStatus.loading:
        return const AppCircularProgressIndicator();
      case APIRequestStatus.unInitialized:
        return const LoadingWidget();
      case APIRequestStatus.connectionError:
        return MyErrorWidget(
          refreshCallBack: reload,
          isConnection: true,
        );
      case APIRequestStatus.error:
        return MyErrorWidget(
          refreshCallBack: reload,
          isConnection: false,
        );
      case APIRequestStatus.loaded:
        return child;
      default:
        return const LoadingWidget();
    }
  }
}
