import 'package:filmsearch/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://feuummkkcaubrfnzimgu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZldXVtbWtrY2F1YnJmbnppbWd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDk2MjM4ODksImV4cCI6MjAyNTE5OTg4OX0.zAvUyEXcwLBjaO3Fuy06aQ_z_N2ONedf99JoheAZ1hk',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
