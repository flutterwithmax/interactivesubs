import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/subtitle.dart';
import 'interactive_subtitles.dart';

class SubtitlesContainer extends StatelessWidget {
  final Subtitle? subtitle;
  final YoutubePlayerController controller;

  const SubtitlesContainer(
      {super.key, required this.subtitle, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (subtitle == null || subtitle!.text.isEmpty) {
      return const Center(child: Text('No subtitle available'));
    }
    return InteractiveSubtitles(subtitle: subtitle!, controller: controller);
  }
}
