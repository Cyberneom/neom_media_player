import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epub_view/epub_view.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';


class EPUBViewerController extends GetxController {

  final userController = Get.find<UserController>();

  final Rx<AppProfile> profile = AppProfile().obs;
  RxBool isLoading = true.obs;

  // late PDFViewController pdfVewController;
  int currentPage = 0;
  int pdfPages = 250;
  int currentPercentage = 1;
  int? readSessions;
  int minPagesBySession = 20;
  bool isReady = false;
  String errorMessage = '';
  int indexPage = 0;
  String filename = "";
  bool isRemote = true;

  String epubUrl = "";
  File pdfFile = File("");
  bool allowFullAccess = false;
  int maxPage = 0;

  // Freebook freebook = Freebook();
  EpubController? epubReaderController;
  String epubTitle = "";

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("EPUB Viewer Controller");

    try {

      profile.value = userController.profile;
      if(Get.arguments != null && Get.arguments.isNotEmpty) {

        ///DEPRECATED
        // if(Get.arguments[0] is Freebook) {
        //   freebook = Get.arguments[0];
        //   epubUrl = freebook.link![3].href!;
        //   epubTitle = freebook.title!;
        // } else {
        //   AppUtilities.logger.e("A different object was send to EPUB Viewer Controller");
        // }

        if(Get.arguments.length > 1) isRemote = Get.arguments[1] ?? true;
        if(Get.arguments.length > 2) currentPage = Get.arguments[2] ?? 1;
        if(Get.arguments.length > 3) pdfPages = Get.arguments[3] ?? 250;
        if(Get.arguments.length > 4) allowFullAccess = Get.arguments[4] ?? true;

        if(isRemote) {
          final response = await http.get(Uri.parse(epubUrl));

          if (response.statusCode == 200) {
            final Uint8List bytes = response.bodyBytes;
            epubReaderController = EpubController(
              document: EpubDocument.openData(bytes),
              // epubCfi:
              //     'epubcfi(/6/26[id4]!/4/2/2[id4]/22)', // book.epub Chapter 3 paragraph 10
              // epubCfi:
              //     'epubcfi(/6/6[chapter-2]!/4/2/1612)', // book_2.epub Chapter 16 paragraph 3
            );
          } else {
            throw Exception('Failed to download file');
          }
        } else {
          allowFullAccess = true;
          epubReaderController = EpubController(
            document: EpubDocument.openAsset(epubUrl),
            // epubCfi:
            //     'epubcfi(/6/26[id4]!/4/2/2[id4]/22)', // book.epub Chapter 3 paragraph 10
            // epubCfi:
            //     'epubcfi(/6/6[chapter-2]!/4/2/1612)', // book_2.epub Chapter 16 paragraph 3
          );
        }

        maxPage = allowFullAccess ? pdfPages : 10;

      }
      isLoading.value = false;
    } catch (e) {
      AppUtilities.logger.e(e);
    }
  }

  @override
  void onReady() async {
    super.onReady();
    AppUtilities.logger.d("EPUB View Controller Ready");
    try {

    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.epubViewer]);
  }

  void setPages(int pages) {
    pdfPages = pages;
    addReadSessions();
    update([AppPageIdConstants.epubViewer]);
  }

  void removeReadSessions() {
    readSessions = null;
    update([AppPageIdConstants.epubViewer]);
  }

  void addReadSessions() {
    readSessions = (pdfPages / minPagesBySession).ceil();
    update([AppPageIdConstants.epubViewer]);
  }

  Future<void> setEPUBPage(int page) async {
    epubReaderController!.jumpTo(index: page);
    pageChanged(page);
    update([AppPageIdConstants.epubViewer]);
  }

  void pageChanged(int page) {
    AppUtilities.logger.d('page change: $page/$pdfPages');
    currentPage = page;
    currentPercentage = ((currentPage*100)/pdfPages).ceil();
    if(currentPercentage == 0) currentPercentage = 1;
    update([AppPageIdConstants.epubViewer]);
  }

}
