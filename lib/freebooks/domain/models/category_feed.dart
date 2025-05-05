import 'feed.dart';

class CategoryFeed {
  String? version;
  String? encoding;
  Feed? feed;

  CategoryFeed({this.version, this.encoding, this.feed});

  CategoryFeed.fromJson(Map<String, dynamic> json) {
    version = json['version'];
    encoding = json['encoding'];
    feed = json['feed'] != null ? Feed.fromJson(json['feed']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['version'] = version;
    data['encoding'] = encoding;
    if (feed != null) {
      data['feed'] = feed!.toJson();
    }
    return data;
  }
}
