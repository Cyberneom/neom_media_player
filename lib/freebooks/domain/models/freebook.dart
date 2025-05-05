import 'author_1.dart';
import 'category.dart';
import 'link_1.dart';

class Freebook {

  String? id;
  String? title;
  Author1? author;
  String? published;
  String? updated;
  String? imgUrl;
  String? dctermsLanguage;
  String? dctermsPublisher;
  String? dctermsIssued;
  String? summary;
  List<Category>? category;
  List<Link1>? link;
  // SchemaSeries? schemaSeries;

  Freebook({
    this.id,
    this.title,
    this.author,
    this.published,
    this.updated,
    this.imgUrl,
    this.dctermsLanguage,
    this.dctermsPublisher,
    this.dctermsIssued,
    this.summary,
    this.category,
    this.link,
    // this.schemaSeries
  });

  Freebook.fromJson(Map<String, dynamic> json) {
    id = json['id']['\$t'];
    title = json['title']['\$t'];
    if (json['author'] != null) {
      if (json['author'].runtimeType.toString() == 'List<dynamic>') {
        author = Author1.fromJson(json['author'][0]);
      } else {
        author = Author1.fromJson(json['author']);
      }
    }

    published = json['published']['\$t'];
    updated = json['updated']['\$t'];
    dctermsLanguage = json[r'dcterms$language']['\$t'];
    dctermsPublisher = json[r'dcterms$publisher']['\$t'];
    dctermsIssued = json[r'dcterms$issued']['\$t'];
    summary = json['summary']['\$t'];
    if (json['category'] != null) {
      String? t = json['category'].runtimeType.toString();
      if (t == 'List<dynamic>' || t == '_GrowableList<dynamic>') {
        category = <Category>[];
        json['category'].forEach((v) {
          category!.add(Category.fromJson(v));
        });
      } else {
        category = <Category>[];
        category!.add(Category.fromJson(json['category']));
      }
    }
    if (json['link'] != null) {
      link = <Link1>[];
      json['link'].forEach((v) {
        link!.add(Link1.fromJson(v));
      });
    }
    // schemaSeries = json[r'schema$Series'] != null
    //     ? SchemaSeries.fromJson(json[r'schema$Series'])
    //     : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'id': id,
      'author': author?.toJson(),
      'published': published,
      'updated': updated,
      r'dcterms$language': dctermsLanguage,
      r'dcterms$publisher': dctermsPublisher,
      r'dcterms$issued': dctermsIssued,
      'summary': summary,
      'category': category?.map((v) => v.toJson()).toList(),
      'link': link?.map((v) => v.toJson()).toList(),
      // r'schema$Series': schemaSeries?.toJson(),
    };
  }
}
