import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_news/model/news.dart';

class NewsApi {
  static Future<NewsList> getHeadLines(
      {String category: "General", int page: 0}) async {
    print("request $category - $page");
    final response = await http.get(
        "https://newsapi.org/v2/top-headlines?country=ph&apiKey=70eb3a7536554bdebef48174b40d4018&page=$page&category=$category");

    return compute(parseResult, response.body);
  }

  static NewsList parseResult(String respond) {
    return NewsList.fromJson(json.decode(respond));
  }
}
