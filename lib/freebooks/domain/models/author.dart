class Author {
  String? name;
  String? uri;
  String? email;

  Author({this.name, this.uri, this.email});

  Author.fromJson(Map<String, dynamic> json) {
    name = json['name']['\$t'];
    uri = json['uri']['\$t'];
    email = json['email']['\$t'];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
      'email': email,
    };
  }

}
