import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showOpenAIKey = false;
  bool _showAnthropicKey = false;

  late TextEditingController _openAIController;
  late TextEditingController _anthropicController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _openAIController = TextEditingController(text: settings.openAIKey);
    _anthropicController = TextEditingController(text: settings.anthropicKey);
  }

  @override
  void dispose() {
    _openAIController.dispose();
    _anthropicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Provider section
          _buildSectionHeader('AI Provider'),
          Card(
            child: Column(
              children: [
                RadioListTile<AIProvider>(
                  title: const Text('OpenAI'),
                  subtitle: const Text('DALL-E 3 for image generation'),
                  value: AIProvider.openai,
                  groupValue: settings.defaultProvider,
                  onChanged: (value) {
                    if (value != null) {
                      settings.setDefaultProvider(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<AIProvider>(
                  title: const Text('Anthropic'),
                  subtitle: const Text('Claude (no image generation)'),
                  value: AIProvider.anthropic,
                  groupValue: settings.defaultProvider,
                  onChanged: (value) {
                    if (value != null) {
                      settings.setDefaultProvider(value);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // OpenAI Key section
          _buildSectionHeader('OpenAI API Key'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _openAIController,
                    obscureText: !_showOpenAIKey,
                    decoration: InputDecoration(
                      hintText: 'sk-...',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showOpenAIKey
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _showOpenAIKey = !_showOpenAIKey);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () {
                              settings.setOpenAIKey(_openAIController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API key saved')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (settings.openAIKey.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Key configured',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Get your API key from platform.openai.com',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),

          const SizedBox(height: 24),

          // Anthropic Key section
          _buildSectionHeader('Anthropic API Key'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _anthropicController,
                    obscureText: !_showAnthropicKey,
                    decoration: InputDecoration(
                      hintText: 'sk-ant-...',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showAnthropicKey
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(
                                  () => _showAnthropicKey = !_showAnthropicKey);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () {
                              settings.setAnthropicKey(_anthropicController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('API key saved')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (settings.anthropicKey.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Key configured',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Anthropic doesn\'t offer image generation, but can be used for dream analysis',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),

          const SizedBox(height: 32),

          // About section
          _buildSectionHeader('About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dream Tracker v1.0',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capture your dreams with voice recording and AI visualization.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () =>
                        _launchUrl('https://platform.openai.com/api-keys'),
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Get OpenAI API Key'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _launchUrl('https://console.anthropic.com/'),
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Get Anthropic API Key'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
