import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/dream.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../services/speech_service.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  final SpeechService _speechService = SpeechService();
  final Uuid _uuid = const Uuid();

  bool _isSaving = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _audioService.addListener(_onAudioStateChanged);
    _speechService.addListener(_onSpeechStateChanged);
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSpeechStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    _speechService.removeListener(_onSpeechStateChanged);
    _audioService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_audioService.isRecording) {
      await _stopAndSave();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final started = await _audioService.startRecording();
    if (started) {
      await _speechService.startListening();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start recording. Check microphone permission.'),
          ),
        );
      }
    }
  }

  Future<void> _stopAndSave() async {
    setState(() => _isSaving = true);

    await _speechService.stopListening();
    final audioPath = await _audioService.stopRecording();
    final transcript = _speechService.transcript;

    if (transcript.isEmpty && audioPath == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio or transcript to save')),
        );
      }
      return;
    }

    final dream = Dream(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      transcript: transcript,
      audioPath: audioPath,
    );

    final db = context.read<DatabaseService>();
    await db.insertDream(dream);

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _cancel() async {
    if (_audioService.isRecording) {
      await _speechService.stopListening();
      await _audioService.cancelRecording();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                const Spacer(),

                // Live transcript
                Expanded(
                  flex: 2,
                  child: _buildTranscriptArea(),
                ),

                const Spacer(),

                // Recording time
                if (_audioService.isRecording)
                  Text(
                    _audioService.formattedDuration,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace',
                      color: Colors.white,
                    ),
                  ),

                const SizedBox(height: 40),

                // Record button
                _buildRecordButton(),

                const SizedBox(height: 16),

                Text(
                  _audioService.isRecording ? 'Tap to stop' : 'Tap to record',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                // Cancel button
                TextButton(
                  onPressed: _cancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),

            // Saving overlay
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Saving dream...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptArea() {
    final transcript = _speechService.transcript;

    if (transcript.isEmpty && !_audioService.isRecording) {
      return const SizedBox.shrink();
    }

    if (transcript.isEmpty && _audioService.isRecording) {
      return Center(
        child: Text(
          'Speak your dream...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 18,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        transcript,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _toggleRecording,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = _audioService.isRecording ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _audioService.isRecording ? Colors.red : Colors.purple,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _audioService.isRecording
                    ? Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
