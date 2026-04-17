import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  String query = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search")),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search students, teachers...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() => query = val);
              },
            ),
          ),

          Expanded(
            child: Center(
              child: Text("Search results for: $query"),
            ),
          ),
        ],
      ),
    );
  }
}