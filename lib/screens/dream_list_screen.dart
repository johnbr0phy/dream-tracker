import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/dream.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import 'dream_detail_screen.dart';

class DreamListScreen extends StatefulWidget {
  const DreamListScreen({super.key});

  @override
  State<DreamListScreen> createState() => _DreamListScreenState();
}

class _DreamListScreenState extends State<DreamListScreen> {
  List<Dream> _dreams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    final db = context.read<DatabaseService>();
    final dreams = await db.getAllDreams();
    setState(() {
      _dreams = dreams;
      _isLoading = false;
    });
  }

  Future<void> _deleteDream(Dream dream) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dream'),
        content: const Text('Are you sure you want to delete this dream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = context.read<DatabaseService>();
      await db.deleteDream(dream.id);

      // Delete audio file if exists
      if (dream.audioPath != null) {
        final audioService = AudioService();
        await audioService.deleteAudioFile(dream.audioPath!);
      }

      _loadDreams();
    }
  }

  Map<String, List<Dream>> _groupDreamsByDate() {
    final grouped = <String, List<Dream>>{};

    for (final dream in _dreams) {
      final date = _formatDateHeader(dream.createdAt);
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(dream);
    }

    return grouped;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dreamDate = DateTime(date.year, date.month, date.day);

    if (dreamDate == today) {
      return 'Today';
    } else if (dreamDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dreams'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dreams.isEmpty
              ? _buildEmptyState()
              : _buildDreamList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.nightlight_round,
            size: 64,
            color: Colors.purple.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No dreams yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the record button to capture your first dream',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDreamList() {
    final grouped = _groupDreamsByDate();
    final dates = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadDreams,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final dreams = grouped[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              ...dreams.map((dream) => _buildDreamCard(dream)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDreamCard(Dream dream) {
    return Dismissible(
      key: Key(dream.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteDream(dream);
        return false; // We handle deletion ourselves
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DreamDetailScreen(dream: dream),
              ),
            );
            _loadDreams(); // Refresh after returning
          },
          title: Row(
            children: [
              Text(
                DateFormat.jm().format(dream.createdAt),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (dream.generatedImage != null)
                Icon(Icons.image, size: 16, color: Colors.purple[300]),
              if (dream.audioPath != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.graphic_eq, size: 16, color: Colors.purple[300]),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              dream.transcript.isEmpty ? 'No transcript' : dream.transcript,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dream.transcript.isEmpty
                    ? Colors.grey[600]
                    : Colors.grey[300],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
