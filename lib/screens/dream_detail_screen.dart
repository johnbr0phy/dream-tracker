import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/dream.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';
import '../services/image_generation_service.dart';

class DreamDetailScreen extends StatefulWidget {
  final Dream dream;

  const DreamDetailScreen({super.key, required this.dream});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
  late Dream _dream;
  final AudioService _audioService = AudioService();
  final ImageGenerationService _imageService = ImageGenerationService();

  bool _isGeneratingImage = false;
  bool _isEditing = false;
  late TextEditingController _transcriptController;

  @override
  void initState() {
    super.initState();
    _dream = widget.dream;
    _transcriptController = TextEditingController(text: _dream.transcript);
    _audioService.addListener(_onAudioStateChanged);
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    _audioService.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _saveTranscript() async {
    _dream.transcript = _transcriptController.text;
    final db = context.read<DatabaseService>();
    await db.updateDream(_dream);
    setState(() => _isEditing = false);
  }

  Future<void> _generateImage() async {
    final settings = context.read<SettingsService>();

    if (!settings.hasValidAPIKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your OpenAI API key in Settings'),
        ),
      );
      return;
    }

    if (_dream.transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transcript to generate image from')),
      );
      return;
    }

    setState(() => _isGeneratingImage = true);

    try {
      final imageData = await _imageService.generateImage(
        prompt: _dream.transcript,
        apiKey: settings.openAIKey,
      );

      _dream = _dream.copyWith(
        generatedImage: imageData,
        imagePrompt: _dream.transcript,
      );

      final db = context.read<DatabaseService>();
      await db.updateDream(_dream);

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => _isGeneratingImage = false);
    }
  }

  void _togglePlayback() {
    if (_audioService.isPlaying) {
      _audioService.stopPlayback();
    } else if (_dream.audioPath != null) {
      _audioService.playAudio(_dream.audioPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dream'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveTranscript,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              children: [
                const Icon(Icons.nightlight_round, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().add_jm().format(_dream.createdAt),
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Transcript section
            _buildTranscriptSection(),

            const SizedBox(height: 24),

            // Audio section
            if (_dream.audioPath != null) ...[
              _buildAudioSection(),
              const SizedBox(height: 24),
            ],

            // Image section
            _buildImageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dream Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                if (_isEditing) {
                  _saveTranscript();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              child: Text(_isEditing ? 'Done' : 'Edit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isEditing)
          TextField(
            controller: _transcriptController,
            maxLines: null,
            minLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe your dream...',
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          )
        else
          Text(
            _dream.transcript.isEmpty
                ? 'No transcript available'
                : _dream.transcript,
            style: TextStyle(
              color: _dream.transcript.isEmpty
                  ? Colors.grey[600]
                  : Colors.grey[300],
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audio Recording',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _togglePlayback,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _audioService.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 48,
                  color: Colors.purple,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _audioService.isPlaying ? 'Playing...' : 'Tap to play',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Audio recording',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final settings = context.watch<SettingsService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dream Visualization',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_dream.generatedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _dream.generatedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          if (_dream.imagePrompt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Prompt: ${_dream.imagePrompt}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGeneratingImage ? null : _generateImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate Image'),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingImage ||
                      _dream.transcript.isEmpty ||
                      !settings.hasValidAPIKey
                  ? null
                  : _generateImage,
              icon: _isGeneratingImage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGeneratingImage ? 'Generating...' : 'Generate Dream Image',
              ),
            ),
          ),
          if (!settings.hasValidAPIKey) ...[
            const SizedBox(height: 8),
            Text(
              'Add an API key in Settings to generate images',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
