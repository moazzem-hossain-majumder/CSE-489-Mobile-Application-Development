import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSE 489 Assignment 2',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

/// Simulates a "custom broadcast"

class CustomBroadcast {
  static final StreamController<String> _controller =
  StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  static void send(String message) => _controller.add(message);
}

///HOME PAGE (Drawer)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _goTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.settings_input_antenna),
              title: const Text('Broadcast Receiver'),
              onTap: () => _goTo(context, const BroadcastSelectScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image Scale'),
              onTap: () => _goTo(context, const ImageScaleScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () => _goTo(context, const VideoScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: const Text('Audio'),
              onTap: () => _goTo(context, const AudioScreen()),
            ),
          ],
        ),
      ),
      body: const Center(child: Text('Select an option from the drawer menu ☰')),
    );
  }
}

///A.1 "Activity 1" - choose broadcast type
class BroadcastSelectScreen extends StatefulWidget {
  const BroadcastSelectScreen({super.key});

  @override
  State<BroadcastSelectScreen> createState() => _BroadcastSelectScreenState();
}

class _BroadcastSelectScreenState extends State<BroadcastSelectScreen> {
  static const List<String> _options = [
    'Custom broadcast receiver',
    'System battery notification receiver',
  ];
  String _selected = _options[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Receiver')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select a broadcast type', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _selected,
              items: _options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => setState(() => _selected = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_selected == _options[0]) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CustomInputScreen()));
                } else {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BatteryScreen()));
                }
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }
}

///A.2 option 1 "Activity 2" - take text input
class CustomInputScreen extends StatefulWidget {
  const CustomInputScreen({super.key});

  @override
  State<CustomInputScreen> createState() => _CustomInputScreenState();
}

class _CustomInputScreenState extends State<CustomInputScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Broadcast - Input')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter a message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomReceiverScreen(message: _controller.text),
                  ),
                );
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

///A.2 option 2 "Activity 2" - system battery
class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  final Battery _battery = Battery();
  int? _level;
  StreamSubscription<BatteryState>? _sub;

  @override
  void initState() {
    super.initState();
    _loadBattery();
    // "registers a receiver" for battery state change broadcasts
    _sub = _battery.onBatteryStateChanged.listen((_) => _loadBattery());
  }

  Future<void> _loadBattery() async {
    final level = await _battery.batteryLevel;
    if (mounted) setState(() => _level = level);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Battery Broadcast')),
      body: Center(
        child: _level == null
            ? const CircularProgressIndicator()
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.battery_charging_full, size: 64),
            const SizedBox(height: 12),
            Text('Battery: $_level%', style: const TextStyle(fontSize: 28)),
          ],
        ),
      ),
    );
  }
}

/// A "Activity 3" option 1 - custom broadcast receiver
class CustomReceiverScreen extends StatefulWidget {
  final String message;
  const CustomReceiverScreen({super.key, required this.message});

  @override
  State<CustomReceiverScreen> createState() => _CustomReceiverScreenState();
}

class _CustomReceiverScreenState extends State<CustomReceiverScreen> {
  String _received = 'Waiting for broadcast...';
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    // Register the receiver (subscribe to the broadcast stream)
    _sub = CustomBroadcast.stream.listen((msg) {
      setState(() => _received = msg);
    });
    // Send the broadcast (equivalent of sendBroadcast(intent))
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomBroadcast.send(widget.message);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Broadcast Receiver')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Received message:\n"$_received"',
            style: const TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// B. Image scale
class ImageScaleScreen extends StatelessWidget {
  const ImageScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Scale (pinch to zoom)')),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(
            'https://picsum.photos/id/1015/800/600',
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}

///  C. Video
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
    )
      ..initialize().then((_) => setState(() {}))
      ..setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}

/// D. Audio
class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _toggle,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          label: Text(_isPlaying ? 'Pause' : 'Play Audio'),
        ),
      ),
    );
  }
}