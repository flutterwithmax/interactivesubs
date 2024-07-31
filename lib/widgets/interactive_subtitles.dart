import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/subtitle.dart';

class InteractiveSubtitles extends StatelessWidget {
  final Subtitle subtitle;
  final YoutubePlayerController controller;

  const InteractiveSubtitles(
      {super.key, required this.subtitle, required this.controller});

  @override
  Widget build(BuildContext context) {
    List<String> words = subtitle.text.split(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          children: words.map((word) {
            return TextSpan(
              text: "$word ",
              style: const TextStyle(color: Colors.black, fontSize: 18),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Pause the video
                  controller.pause();

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text("Translation or information for '$word'"),
                      actions: [
                        TextButton(
                          child: const Text('Close'),
                          onPressed: () {
                            // Resume the video
                            controller.play();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
            );
          }).toList(),
        ),
      ),
    );
  }
}
