class Author1 {

  String? name;
  String? uri;

  Author1({this.name, this.uri});

  Author1.fromJson(Map<String, dynamic> json) {
    name = json['name']['\$t'];
    uri = json['uri']['\$t'];
  }

  // Method to convert Author1 instance to JSON (Map<String, dynamic>)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
    };
  }
}
