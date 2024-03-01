import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gemini/main.dart';
import 'package:gemini/posts/post.dart';
import 'package:gemini/posts/post_cell.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  Future<void> _save() async {
    final text = _chatController.text;

    _chatController.clear();

    final model = GenerativeModel(model: 'embedding-001', apiKey: apiKey);
    final content = Content.text(text);
    final embeddingResult = await model.embedContent(
      content,
      taskType: TaskType.semanticSimilarity,
    );
    final embedding = embeddingResult.embedding.values;

    final url = Uri.parse('https://api.openai.com/v1/embeddings');
    final response = await post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAiApiKey',
      },
      body: jsonEncode({
        'input': text,
        'model': 'text-embedding-3-small',
      }),
    );

    final json = jsonDecode(response.body);

    final openAIEmbedding = json['data'][0]['embedding'];

    await supabase.from('posts').insert({
      'content': text,
      'embedding': embedding,
      'open_ai_embedding': openAIEmbedding,
    });
  }

  final _chatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Post>>(
                stream: supabase
                    .from('posts')
                    .stream(primaryKey: ['id'])
                    .order('created_at')
                    .map((event) => event.map<Post>(Post.fromJson).toList()),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(snapshot.error.toString()),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final posts = snapshot.data ?? [];
                  return ListView.separated(
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Divider(
                        height: 1,
                        color: Colors.black12,
                      ),
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return PostCell(post: post);
                    },
                  );
                }),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey[100],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLines: null,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Write something fun...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      onPressed: _save,
                      icon: const Icon(Icons.send),
                    ),
                  ),
                  onEditingComplete: _save,
                  controller: _chatController,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
