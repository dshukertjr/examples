import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  Supabase.initialize(
      url: 'http://127.0.0.1:54321',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 60,
      ));
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ArtBoardPage(),
    );
  }
}

class ArtBoardPainter extends CustomPainter {
  // Map<int, Offset> _otherUsers = {};
  final ValueNotifier<Map<int, Offset>> otherUsers;

  ArtBoardPainter({required this.otherUsers}) : super(repaint: otherUsers);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    // const RadialGradient gradient = RadialGradient(
    //   center: Alignment(0.7, -0.6),
    //   radius: 0.2,
    //   colors: <Color>[Color(0xFFFFFF00), Color(0xFF0099FF)],
    //   stops: <double>[0.4, 1.0],
    // );
    // canvas.drawRect(
    //   rect,
    //   Paint()..shader = gradient.createShader(rect),
    // );
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
    for (final entry in otherUsers.value.entries) {
      // canvas.drawCircle(entry.value, 3, Paint()..color = Colors.red);
      final position = entry.value;
      canvas.drawPath(
          Path()
            ..moveTo(position.dx, position.dy)
            ..lineTo(position.dx + 7.145, position.dy + 22.42)
            ..lineTo(position.dx + 10.175, position.dy + 12.965)
            ..lineTo(position.dx + 19.925, position.dy + 12.255)
            ..lineTo(position.dx, position.dy),
          Paint()..color = Color(entry.key));
    }
  }

  @override
  bool shouldRepaint(ArtBoardPainter painter) {
    return true;
  }
}

enum DrawMode {
  rectangle,
  oval,
  line,
}

class ArtBoardPage extends StatefulWidget {
  const ArtBoardPage({super.key});

  @override
  State<ArtBoardPage> createState() => _ArtBoardPageState();
}

class CursorPosition {
  final String userId;
  final Offset position;

  CursorPosition({
    required this.userId,
    required this.position,
  });
}

class _ArtBoardPageState extends State<ArtBoardPage> {
  final ValueNotifier<Map<int, Offset>> _otherUsers =
      ValueNotifier<Map<int, Offset>>({});

  late final RealtimeChannel _cursorChannel;

  late final int _myColorCode;

  late final ArtBoardPainter _artBoardPainter;

  @override
  void initState() {
    super.initState();
    _artBoardPainter = ArtBoardPainter(otherUsers: _otherUsers);
    final random = Random();
    _myColorCode =
        Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0).value;
    _cursorChannel = supabase
        .channel('cursor')
        .onBroadcast(
            event: 'cursor',
            callback: (payload) {
              _otherUsers.value[payload['color']] = Offset(
                  payload['position']['x'] as double,
                  payload['position']['y'] as double);
              _otherUsers.notifyListeners();
            })
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        return MouseRegion(
          onHover: (event) {
            _cursorChannel.sendBroadcastMessage(event: 'cursor', payload: {
              'color': _myColorCode,
              'position': {
                'x': event.position.dx,
                'y': event.position.dy,
              }
            });
          },
          child: GestureDetector(
            onPanDown: (details) {},
            onPanUpdate: (details) {},
            onPanEnd: (details) {},
            child: CustomPaint(
              size: Size(maxWidth, maxHeight),
              painter: _artBoardPainter,
            ),
          ),
        );
      }),
    );
  }
}
