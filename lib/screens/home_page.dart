import 'package:flutter/material.dart';
import 'package:interactivesubs/models/subtitle.dart';
import 'package:interactivesubs/widgets/subtitle_container.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late YoutubePlayerController _controller;
  List<Subtitle> _subtitles = [];
  Subtitle? _currentSubtitle;
  final Dio _dio = Dio(); // Initialize Dio
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: 'eIho2S0ZahI', // Replace with your actual video ID
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
    _fetchSubtitles('eIho2S0ZahI'); // Replace with your actual video ID
    _controller.addListener(_updateSubtitle);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSubtitle);
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubtitles(String videoId) async {
    try {
      var yt = YoutubeExplode();
      var manifest = await yt.videos.closedCaptions.getManifest(videoId);
      var englishTrack = manifest.tracks.firstWhere(
        (track) => track.language.code == 'en',
        orElse: () => throw Exception('No English track available'),
      );
      var response = await _dio
          .get(englishTrack.url.toString()); // Use Dio to fetch subtitles
      var subtitleString = response.data;
      _subtitles = parseSubtitles(subtitleString);
      yt.close();
      setState(() {});
    } catch (e) {
      print('Error fetching subtitles: $e');
      _showSnackbar('Failed to fetch subtitles or video is invalid.');
    }
  }

  List<Subtitle> parseSubtitles(String subtitleString) {
    var document = xml.XmlDocument.parse(subtitleString);
    var subtitles = <Subtitle>[];

    for (var textElement in document.findAllElements('text')) {
      var start = textElement.getAttribute('start') ?? '0';
      var duration = textElement.getAttribute('dur') ?? '1';
      var end = (double.parse(start) + double.parse(duration)).toString();
      var text = textElement.text.trim();
      subtitles.add(Subtitle(start: start, end: end, text: text));
    }
    return subtitles;
  }

  void _updateSubtitle() {
    final currentTime = _controller.value.position.inSeconds.toDouble();
    final currentSubtitle = _subtitles.firstWhere(
      (subtitle) =>
          currentTime >= double.parse(subtitle.start) &&
          currentTime <= double.parse(subtitle.end),
      orElse: () => Subtitle(start: '0', end: '0', text: ''),
    );

    if (currentSubtitle != _currentSubtitle) {
      setState(() {
        _currentSubtitle = currentSubtitle;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final url = _urlController.text;
    final videoId = YoutubePlayer.convertUrlToId(url);

    if (videoId != null) {
      try {
        await _fetchSubtitles(videoId);
        setState(() {
          _controller.load(videoId);
          _urlController.text = '';
        });
      } catch (e) {
        _showSnackbar('Invalid URL or no subtitles available.');
      }
    } else {
      _showSnackbar('Invalid YouTube URL.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.amber,
              onReady: () {
                print('Player is ready.');
              },
            ),
            Expanded(
              child: SubtitlesContainer(
                subtitle: _currentSubtitle,
                controller: _controller, // Pass the controller
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter YouTube URL',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
