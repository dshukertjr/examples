import 'package:flutter/material.dart';
import 'package:gemini/main.dart';
import 'package:gemini/posts/post.dart';
import 'package:gemini/posts/post_cell.dart';

class PostPage extends StatelessWidget {
  const PostPage({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: Column(
        children: <Widget>[
          PostCell(
            post: post,
            showAll: true,
          ),
          FutureBuilder(
              future: supabase.rpc('get_related_posts', params: {
                'embedding': post.embedding,
                'open_ai_embedding': post.openAIEmbedding,
                'post_id': post.id,
                'match_threshold': 0.2,
                'match_count': 20,
              }).withConverter<List<Post>>((data) =>
                  (List<Map<String, dynamic>>.from(data))
                      .map(Post.fromJson)
                      .toList()),
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
                return Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const Padding(
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
                  ),
                );
              }),
        ],
      ),
    );
  }
}
