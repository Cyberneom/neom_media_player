import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../data/freebooks_api.dart';
import '../../domain/models/category_feed.dart';
import '../../utils/enum/api_request_status.dart';
import '../../utils/freebooks_utilities.dart';


class FreebooksGenreProvider extends ChangeNotifier {
  ScrollController controller = ScrollController();
  List items = [];
  int page = 1;
  bool loadingMore = false;
  bool loadMore = true;
  APIRequestStatus apiRequestStatus = APIRequestStatus.loading;
  FreebooksAPI api = FreebooksAPI();

  void listener(url) {
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        if (!loadingMore) {
          paginate(url);
          // Animate to bottom of list
          Timer(const Duration(milliseconds: 100), () {
            controller.animateTo(
              controller.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeIn,
            );
          });
        }
      }
    });
  }

  Future<void> getFeed(String url) async {
    setApiRequestStatus(APIRequestStatus.loading);
    AppUtilities.logger.d(url);
    try {
      CategoryFeed feed = await api.getCategory(url);
      items = feed.feed!.entry!;
      setApiRequestStatus(APIRequestStatus.loaded);
      listener(url);
    } catch (e) {
      checkError(e);
      rethrow;
    }
  }

  Future<void> paginate(String url) async {
    if(apiRequestStatus != APIRequestStatus.loading && !loadingMore && loadMore) {
      Timer(const Duration(milliseconds: 100), () {
        controller.jumpTo(controller.position.maxScrollExtent);
      });
      loadingMore = true;
      page = page + 1;
      notifyListeners();
      try {
        CategoryFeed feed = await api.getCategory('$url&page=$page');
        items.addAll(feed.feed!.entry!);
        loadingMore = false;
        notifyListeners();
      } catch (e) {
        loadMore = false;
        loadingMore = false;
        notifyListeners();
        rethrow;
      }
    }
  }

  void checkError(e) {
    if (FreebooksUtilities.checkConnectionError(e)) {
      setApiRequestStatus(APIRequestStatus.connectionError);
      showToast('Connection error');
    } else {
      setApiRequestStatus(APIRequestStatus.error);
      showToast('Something went wrong, please try again');
    }
  }

  void showToast(msg) {
    Fluttertoast.showToast(
      msg: '$msg',
      toastLength: Toast.LENGTH_SHORT,
      timeInSecForIosWeb: 1,
    );
  }

  void setApiRequestStatus(APIRequestStatus value) {
    apiRequestStatus = value;
    notifyListeners();
  }
}
