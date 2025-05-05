import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:xml2json/xml2json.dart';

import '../domain/models/author_1.dart';
import '../domain/models/category.dart';
import '../domain/models/category_feed.dart';
import '../domain/models/feed.dart';
import '../domain/models/freebook.dart';
import '../domain/models/link_1.dart';


class FreebooksAPI {

  Dio _dio = Dio();
  static const String baseURL = 'https://gutendex.com/books';
  ///ENDPOINT IS404 static String baseURL = 'https://catalog.feedbooks.com';

  Future<CategoryFeed> fetchBooks({String language = 'es'}) async {
    try {
      // Se utiliza queryParameters para enviar el filtro de idioma
      final response = await _dio.get(
        baseURL,
        queryParameters: {'languages': language},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return _convertBooksResponseToCategoryFeed(BooksResponse.fromJson(data));
      } else {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener libros: $e');
    }
  }


  /// Convierte un objeto BooksResponse en un CategoryFeed
  CategoryFeed _convertBooksResponseToCategoryFeed(BooksResponse booksResponse) {
    // Filtra los libros: solo se incluyen aquellos que tengan en sus formatos "application/epub+zip" o "application/pdf"
    List<Freebook> bookEntries = booksResponse.results
        .where((book) => book.formats.containsKey("application/epub+zip") ||
        book.formats.containsKey("application/pdf"))
        .map((book) => _convertBookToFreebook(book))
        .toList();

    // Creamos un objeto Feed con algunos datos mapeados desde la respuesta
    Feed feed = Feed(
      xmlLang: "es",
      xmlns: "http://www.w3.org/2005/Atom",
      // En este caso asignamos un identificador fijo o podrías utilizar otro valor
      id: "gutendex",
      title: "Libros de dominio público",
      updated: DateTime.now().toIso8601String(),
      icon: "", // Puedes asignar un icono predeterminado si lo deseas
      // Para el autor, dejamos null o creamos un autor genérico
      author: null,
      opensearchTotalResults: booksResponse.count.toString(),
      opensearchItemsPerPage: bookEntries.length.toString(),
      opensearchStartIndex: "0",
      // Convertimos cada Book en un Freebook
      entry: bookEntries,
    );

    // Devolvemos el CategoryFeed con datos de versión y codificación predeterminados
    return CategoryFeed(
      version: "1.0",
      encoding: "UTF-8",
      feed: feed,
    );
  }

  /// Convierte un objeto Book en un objeto Freebook (modelo utilizado en CategoryFeed)
  Freebook _convertBookToFreebook(Book book) {
    // Creamos un objeto Author1 a partir del primer autor (si existe)
    Author1? author;
    if (book.authors.isNotEmpty) {
      author = Author1(name: book.authors.first);
    }

    // Mapeamos los subjects del libro a una lista de Category
    List<Category> categories = book.subjects.map((subject) => Category(
      label: subject,
      term: subject,
      scheme: "",
    )).toList();

    // Creamos una lista de links a partir de los formatos disponibles
    List<Link1> links = [];
    if (book.formats.containsKey("text/html")) {
      links.add(Link1(
        rel: "alternate",
        type: "text/html",
        title: "HTML",
        href: book.formats["text/html"],
      ));
    }
    if (book.formats.containsKey("application/pdf")) {
      links.add(Link1(
        rel: "alternate",
        type: "application/pdf",
        title: "PDF",
        href: book.formats["application/pdf"],
      ));
    }
    if (book.formats.containsKey("application/epub+zip")) {
      links.add(Link1(
        rel: "alternate",
        type: "application/epub+zip",
        title: "EPUB.zip",
        href: book.formats["application/epub+zip"],
      ));
    }

    String imgUrl = '';
    if (book.formats.containsKey("image/jpeg")) {
      imgUrl = book.formats["image/jpeg"];
    }

    // Retornamos el Freebook con los datos mapeados (algunos campos pueden quedar vacíos si no están disponibles)
    return Freebook(
      id: book.id.toString(),
      title: book.title,
      author: author,
      published: "",
      updated: "",
      imgUrl: imgUrl,
      dctermsLanguage: "es",
      dctermsPublisher: "",
      dctermsIssued: "",
      summary: "",
      category: categories,
      link: links,
      // schemaSeries: null,
    );
  }

  static String publicDomainURL = '$baseURL/publicdomain/browse';
  static String popular = '$publicDomainURL/top.atom?locale=es';
  static String recent = '$publicDomainURL/recent.atom?locale=es';
  static String awards = '$publicDomainURL/awards.atom?locale=es';
  static String noteworthy = '$publicDomainURL/homepage_selection.atom';
  static String shortStory = '$publicDomainURL/top.atom?cat=FBFIC029000';
  static String sciFi = '$publicDomainURL/top.atom?cat=FBFIC028000';
  static String actionAdventure = '$publicDomainURL/top.atom?cat=FBFIC002000';
  static String mystery = '$publicDomainURL/top.atom?cat=FBFIC022000';
  static String romance = '$publicDomainURL/top.atom?cat=FBFIC027000';
  static String horror = '$publicDomainURL/top.atom?cat=FBFIC015000';

  Future<CategoryFeed> getCategory(String url) async {
    var res = await _dio.get(url).catchError((e) {
      throw(e);
    });
    CategoryFeed category;
    if (res.statusCode == 200) {
      Xml2Json xml2json = Xml2Json();
      xml2json.parse(res.data.toString());
      var json = jsonDecode(xml2json.toGData());
      category = CategoryFeed.fromJson(json);
    } else {
      throw ('Error ${res.statusCode}');
    }
    return category;
  }
}

// books_response.dart

class BooksResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Book> results;

  BooksResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory BooksResponse.fromJson(Map<String, dynamic> json) {
    return BooksResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>)
          .map((item) => Book.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Book {
  final int id;
  final String title;
  final List<String> authors;
  final List<String> subjects;
  final Map<String, dynamic> formats;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.subjects,
    required this.formats,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // Procesa el arreglo de autores para extraer solo el nombre
    List<String> authors = [];
    if (json['authors'] != null) {
      for (var author in json['authors']) {
        if (author['name'] != null) {
          authors.add(author['name']);
        }
      }
    }
    return Book(
      id: json['id'],
      title: json['title'] ?? '',
      authors: authors,
      subjects: List<String>.from(json['subjects'] ?? []),
      formats: json['formats'] ?? {},
    );
  }
}
