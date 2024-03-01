import 'package:flutter/material.dart';
import 'package:gemini/posts/post.dart';
import 'package:gemini/posts/post_page.dart';
import 'package:timeago/timeago.dart';

class PostCell extends StatelessWidget {
  const PostCell({super.key, required this.post, this.showAll = false});
  final Post post;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return PostPage(post: post);
            },
          ),
        );
      },
      leading: const CircleAvatar(
        child: Icon(Icons.person_outline),
      ),
      title: Text(
        post.content,
        maxLines: showAll ? 7 : 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(format(post.createdAt, locale: 'en_short')),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (post.similarity != null)
            Text('Gemini: ${post.similarity?.toString()}'),
          if (post.openAISimilarity != null)
            Text('OpenAI: ${post.openAISimilarity?.toString()}'),
        ],
      ),
    );
  }
}
