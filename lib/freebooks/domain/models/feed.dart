import 'author.dart';
import 'freebook.dart';
import 'freebook_link.dart';

class Feed {
  String? xmlLang;
  String? xmlns;
  String? xmlnsDcterms;
  String? xmlnsThr;
  String? xmlnsApp;
  String? xmlnsOpensearch;
  String? xmlnsOpds;
  String? xmlnsXsi;
  String? xmlnsOdl;
  String? xmlnsSchema;
  String? id;
  String? title;
  String? updated;
  String? icon;
  Author? author;
  List<FreebookLink>? link;
  String? opensearchTotalResults;
  String? opensearchItemsPerPage;
  String? opensearchStartIndex;
  List<Freebook>? entry;

  Feed(
      {this.xmlLang,
      this.xmlns,
      this.xmlnsDcterms,
      this.xmlnsThr,
      this.xmlnsApp,
      this.xmlnsOpensearch,
      this.xmlnsOpds,
      this.xmlnsXsi,
      this.xmlnsOdl,
      this.xmlnsSchema,
      this.id,
      this.title,
      this.updated,
      this.icon,
      this.author,
      this.link,
      this.opensearchTotalResults,
      this.opensearchItemsPerPage,
      this.opensearchStartIndex,
      this.entry});

  Feed.fromJson(Map<String, dynamic> json) {
    xmlLang = json['xml:lang'];
    xmlns = json[r'xmlns'];
    xmlnsDcterms = json[r'xmlns$dcterms'];
    xmlnsThr = json[r'xmlns$thr'];
    xmlnsApp = json[r'xmlns$app'];
    xmlnsOpensearch = json[r'xmlns$opensearch'];
    xmlnsOpds = json[r'xmlns$opds'];
    xmlnsXsi = json[r'xmlns$xsi'];
    xmlnsOdl = json[r'xmlns$odl'];
    xmlnsSchema = json[r'xmlns$schema'];
    id = json['id']['\$t'];
    title = json['title']['\$t'];
    updated = json['updated']['\$t'];
    icon = json['icon']['\$t'];
    author = json['author'] != null ? Author.fromJson(json['author']) : null;
    if (json['link'] != null) {
      link = <FreebookLink>[];
      json['link'].forEach((v) {
        link!.add(FreebookLink.fromJson(v));
      });
    }
    opensearchTotalResults = json[r'opensearch$totalResults']['\$t'];
    opensearchItemsPerPage = json[r'opensearch$itemsPerPage']['\$t'];
    opensearchStartIndex = json[r'opensearch$startIndex']['\$t'];
    if (json['entry'] != null) {
      String? t = json['entry'].runtimeType.toString();
      if (t == 'List<dynamic>' || t == '_GrowableList<dynamic>') {
        entry = <Freebook>[];
        json['entry'].forEach((v) {
          entry!.add(Freebook.fromJson(v));
        });
      } else {
        entry = <Freebook>[];
        entry!.add(Freebook.fromJson(json['entry']));
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'xml:lang': xmlLang,
      'xmlns': xmlns,
      r'xmlns$dcterms': xmlnsDcterms,
      r'xmlns$thr': xmlnsThr,
      r'xmlns$app': xmlnsApp,
      r'xmlns$opensearch': xmlnsOpensearch,
      r'xmlns$opds': xmlnsOpds,
      r'xmlns$xsi': xmlnsXsi,
      r'xmlns$odl': xmlnsOdl,
      r'xmlns$schema': xmlnsSchema,
      'id': id,
      'title': title,
      'updated': updated,
      'icon': icon,
      'author': author?.toJson(),
      'link': link?.map((v) => v.toJson()).toList(),
      r'opensearch$totalResults': opensearchTotalResults,
      r'opensearch$itemsPerPage': opensearchItemsPerPage,
      r'opensearch$startIndex': opensearchStartIndex,
      'entry': entry?.map((v) => v.toJson()).toList(),
    };
  }
}
