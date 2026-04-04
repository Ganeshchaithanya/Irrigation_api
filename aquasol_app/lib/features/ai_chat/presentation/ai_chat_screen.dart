import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/providers/language_provider.dart';
import 'package:aquasol_app/core/localization/app_localizations.dart';
import 'package:aquasol_app/shared/widgets/glass_nav.dart';
import 'package:aquasol_app/providers/system_status_provider.dart';
import 'package:aquasol_app/providers/auth_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<({bool isAi, String text, List<dynamic> actions})> _messages = [
    (isAi: true, text: "Hello! I am Aura AI. How can I help you with your farm today?", actions: []),
  ];
  bool _isTyping = false;
  String _sessionName = "New Chat";


  static const _suggestions = [
    'Check A-2 moisture',
    'When to irrigate?',
    'Farm health score',
    'Saving water tips',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final query = text.trim();
    setState(() {
      _messages.add((isAi: false, text: query, actions: []));
      _isTyping = true;
      _ctrl.clear();
    });
    _scrollToBottom();

    try {
      final api = ref.read(apiServiceProvider);
      final lang = ref.read(languageProvider);
      final auth = ref.read(authProvider);
      
      final response = await api.askAI(query, userId: auth.userId!, language: lang);

      String displayMsg = response;
      List<dynamic> actions = [];
      try {
        final decoded = jsonDecode(response);
        if (decoded is Map) {
          displayMsg = decoded['message']?.toString() ?? response;
          if (decoded['actions'] is List) {
            actions = decoded['actions'];
          }
        }
      } catch (e) {
        // Fallback to raw string if parsing fails
      }

      if (mounted) {
        setState(() {
          _messages.add((isAi: true, text: displayMsg, actions: actions));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add((isAi: true, text: "Backend service unreachable. Please check your connection.", actions: []));
          _isTyping = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _showNameSessionDialog() {
    final ctrl = TextEditingController(text: _sessionName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Name Chat Session", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: "E.g. Kharif Disease Plan"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() => _sessionName = ctrl.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    
    // ── WebSocket Feedback Listener (Learning Loop) ──
    ref.listen(systemStatusProvider, (prev, next) {
      if (next.status == SystemStatus.success && (prev?.message != next.message)) {
        setState(() {
          _messages.add((
            isAi: true, 
            text: "✅ Continuous Learning Loop Update: ${next.message}",
            actions: []
          ));
        });
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_sessionName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, size: 20),
            onPressed: _showNameSessionDialog,
            tooltip: 'Rename Session',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final msg = _messages[i];
                    return _buildBubble(msg.isAi, msg.text, msg.actions);
                  },
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildAppShortcuts(),
              _buildInputSection(lang),
            ],
          ),
          const GlassNav(currentPath: '/chat'),
        ],
      ),
    );
  }

  Widget _buildBubble(bool isAi, String text, List<dynamic> actions) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
        child: Column(
          crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAi ? Colors.white : AppColors.emerald,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(isAi ? 4 : 24),
                  bottomRight: Radius.circular(isAi ? 24 : 4),
                ),
                border: isAi ? Border.all(color: AppColors.borderLight) : null,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Text(text, style: TextStyle(color: isAi ? AppColors.textPrimary : Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
            ),
            if (actions.isNotEmpty) const SizedBox(height: 8),
            if (actions.isNotEmpty)
              ...actions.map((act) => _buildActionButton(act)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(dynamic action) {
    final type = action['type'] ?? 'Unknown Action';
    final zoneId = action['zone_id'] ?? '';
    final duration = action['duration'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8),
      child: ElevatedButton.icon(
        onPressed: () => _executeAIAction(zoneId, type, duration),
        icon: const Icon(LucideIcons.zap, size: 16),
        label: Text('Apply $type ($duration mins)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _executeAIAction(String zoneId, String action, int duration) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.executeAICommand(zoneId, action, duration);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Action executed successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠ Action blocked: $e')));
      }
    }
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          const CircleAvatar(radius: 4, backgroundColor: AppColors.emerald),
          const SizedBox(width: 4),
          const CircleAvatar(radius: 4, backgroundColor: AppColors.emerald),
          const SizedBox(width: 4),
          const CircleAvatar(radius: 4, backgroundColor: AppColors.emerald),
        ],
      ),
    );
  }

  Widget _buildAppShortcuts() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _appShortcut(LucideIcons.leaf, 'Crop Planner', '/crop-planner', AppColors.info),
            const SizedBox(width: 12),
            _appShortcut(LucideIcons.book, 'Farm Diary', '/diary', AppColors.emerald),
          ],
        ),
      ),
    );
  }

  Widget _appShortcut(IconData icon, String label, String route, Color color) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(String lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _send(s),
                  backgroundColor: AppColors.emerald.withAlpha(15),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: AppLocalizations.get('Ask anything about your farm...', lang),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.send, color: AppColors.emerald),
                onPressed: () => _send(_ctrl.text),
              ),
              fillColor: AppColors.background,
              filled: true,
            ),
            onSubmitted: _send,
          ),
        ],
      ),
    );
  }
}
