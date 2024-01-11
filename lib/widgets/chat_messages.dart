import 'package:bak_bak/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticateUserId = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snapshots) {
        if (snapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshots.hasData || snapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages yet'),
          );
        }
        if (snapshots.hasError) {
          return const Center(
            child: Text('Something went wrong..'),
          );
        }
        final loadedMessage = snapshots.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 13,
            right: 13,
          ),
          reverse: true,
          itemCount: loadedMessage.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessage[index].data();
            final nextMessage = index + 1 < loadedMessage.length
                ? loadedMessage[index + 1].data()
                : null;
            final currentUserId = chatMessage['userId'];
            //print(currentUserId);
            //print(authenticateUserId.uid);

            final nextUserId =
                nextMessage != null ? nextMessage['userId'] : null;
            if (currentUserId != nextUserId) {
              return MessageBubble.first(
                  userImage: chatMessage['image-url'],
                  username: chatMessage['user-name'],
                  message: chatMessage['text'],
                  isMe: authenticateUserId.uid == currentUserId);
            } else {
              return MessageBubble.next(
                  message: chatMessage['text'],
                  isMe: authenticateUserId.uid == currentUserId);
            }
          },
        );
      },
    );
  }
}
