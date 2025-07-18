import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(NewsApp());
}

// News Article Model
class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String urlToImage;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No title',
      description: json['description'] ?? 'No description',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'] ?? '',
    );
  }
}

// Main App
class NewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16),  // Updated to bodyMedium
        ),
      ),
      home: NewsHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Home Page
class NewsHomePage extends StatefulWidget {
  @override
  _NewsHomePageState createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  List<NewsArticle> articles = [];
  bool isLoading = true;
  String query = "";
  final String apiKey = "b56e29379459441c849ce7af89b2bde0"; // Replace with your API key

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    setState(() => isLoading = true);
    String url = query.isNotEmpty
        ? 'https://newsapi.org/v2/everything?q=${Uri.encodeComponent(query)}&apiKey=$apiKey'
        : 'https://newsapi.org/v2/top-headlines?country=us&apiKey=$apiKey'; // Default to US if no query

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articlesJson = data['articles'];

        setState(() {
          articles = articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        showErrorSnackbar('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar('Error fetching data. Please check your internet connection.');
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      showErrorSnackbar('Could not open the article.');
    }
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search News'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Enter keyword'),
          onChanged: (value) {
            setState(() {
              query = value;
            });
          },
        ),
        actions: [
          TextButton(
            child: Text('Search'),
            onPressed: () {
              Navigator.pop(context);
              fetchNews();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Reader'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: showSearchDialog,
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : articles.isEmpty
              ? Center(child: Text('No articles found. Try searching something else.'))
              : ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        leading: article.urlToImage != ""
                            ? Image.network(
                                article.urlToImage,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey,
                              ),
                        title: Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          article.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _launchURL(article.url);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
