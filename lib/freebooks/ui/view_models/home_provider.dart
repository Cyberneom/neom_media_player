import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';

import '../../data/freebooks_api.dart';
import '../../domain/models/category_feed.dart';
import '../../utils/enum/api_request_status.dart';
import '../../utils/freebooks_utilities.dart';

class FreebooksHomeProvider with ChangeNotifier {
  CategoryFeed top = CategoryFeed();
  CategoryFeed recent = CategoryFeed();
  APIRequestStatus apiRequestStatus = APIRequestStatus.loading;
  FreebooksAPI api = FreebooksAPI();

  Future<void> getFeeds() async {
    AppUtilities.logger.d("Get Feeds");
    setApiRequestStatus(APIRequestStatus.loading);
    try {
      CategoryFeed spanishBooks = await api.fetchBooks(language: 'es');
      setTop(spanishBooks);
      // CategoryFeed popular = await api.getCategory(FreebooksAPI.popular);
      // setTop(popular);
      // CategoryFeed newReleases = await api.getCategory(FreebooksAPI.recent);
      setRecent(spanishBooks);
      setApiRequestStatus(APIRequestStatus.loaded);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      checkError(e);
    }
  }

  void checkError(e) {
    if (FreebooksUtilities.checkConnectionError(e)) {
      setApiRequestStatus(APIRequestStatus.connectionError);
    } else {
      setApiRequestStatus(APIRequestStatus.error);
    }
  }

  void setApiRequestStatus(APIRequestStatus value) {
    apiRequestStatus = value;
    notifyListeners();
  }

  void setTop(value) {
    top = value;
    notifyListeners();
  }

  CategoryFeed getTop() {
    return top;
  }

  void setRecent(value) {
    recent = value;
    notifyListeners();
  }

  CategoryFeed getRecent() {
    return recent;
  }
}
