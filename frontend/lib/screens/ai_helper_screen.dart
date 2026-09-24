import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/shop_animated.dart';
import '../widgets/shop_scaffold.dart';
import '../widgets/shop_widgets.dart';

/// MEMBER 5 - AI Fan Helper
/// Chat screen matching the design board: animated assistant avatar, welcome
/// message, tappable suggestion chips, the conversation, follow-up chips and
/// the message composer.
class AiHelperScreen extends StatefulWidget {
  /// An optional question to ask as soon as the screen opens (used by the
  /// "Ask the AI" shortcuts elsewhere in the app).
  final String? initialQuestion;

  const AiHelperScreen({super.key, this.initialQuestion});

  @override
  State<AiHelperScreen> createState() => _AiHelperScreenState();
}

class _AiHelperScreenState extends State<AiHelperScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AiProvider>();
      await provider.initialise();
      _scrollToBottom();

      if (widget.initialQuestion != null &&
          widget.initialQuestion!.trim().isNotEmpty) {
        await _send(widget.initialQuestion!);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final target = _scrollController.position.maxScrollExtent;

      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty) return;

    _controller.clear();

    final provider = context.read<AiProvider>();
    _scrollToBottom();
    await provider.send(question);
    _scrollToBottom();

    if (!mounted) return;

    if (provider.errorMessage != null) {
      provider.clearError();
    }
  }

  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear conversation?', style: ShopTheme.title(size: 18)),
        content: Text(
          'This removes the chat transcript from this device and from your saved '
          'history.',
          style: ShopTheme.body(size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: ShopTheme.label(size: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ShopTheme.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final message = await context.read<AiProvider>().clearConversation();

    if (!mounted) return;
    _snack(message ?? 'Conversation cleared');
  }

  void _showKnowledge() {
    final provider = context.read<AiProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        decoration: const BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 20),
              AiKnowledgeSummary(
                topics: provider.topics,
                externalAiEnabled: provider.externalAiEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ShopTheme.surfaceUltra,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiProvider>();

    return ShopScaffold(
      title: 'AI For Helper',
      subtitle: provider.externalAiEnabled
          ? 'Knowledge base + AI API'
          : 'Offline fandom knowledge base',
      glowColor: ShopTheme.accent,
      resizeToAvoidBottomInset: true,
      actions: [
        IconButton(
          tooltip: 'What I know',
          onPressed: _showKnowledge,
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
        ),
        IconButton(
          tooltip: 'Clear conversation',
          onPressed: provider.clearing ? null : _clearConversation,
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
      ],
      bottomBar: _buildComposer(provider),
      child: provider.loading && !provider.hasConversation
          ? const Center(
              child: CircularProgressIndicator(color: ShopTheme.accent),
            )
          : Column(
              children: [
                // ---------------------- assistant header ----------------------
                _AssistantHeader(
                  messageCount: provider.messageCount,
                  lastTopic: provider.lastTopic,
                  externalAiEnabled: provider.externalAiEnabled,
                ),

                // ------------------------- transcript -------------------------
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    children: [
                      ...provider.messages.map(
                        (message) => AiMessageBubble(
                          message: message,
                          onFollowUp: _send,
                        ),
                      ),

                      // Starter chips while the user has not asked anything.
                      if (!provider.hasConversation)
                        AiSuggestionChips(
                          suggestions: provider.suggestions,
                          onSelected: _send,
                        ),

                      // Follow-up chips from the newest answer.
                      if (provider.hasConversation &&
                          !provider.sending &&
                          provider.latestFollowUps.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(56, 4, 14, 6),
                          child: Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: provider.latestFollowUps
                                .map(
                                  (question) => GestureDetector(
                                    onTap: () => _send(question),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ShopTheme.accent.withValues(
                                          alpha: 0.11,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: ShopTheme.accent.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        question,
                                        style: GoogleFonts.inter(
                                          color: ShopTheme.accent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ------------------------------------------------------------------
  // composer
  // ------------------------------------------------------------------
  Widget _buildComposer(AiProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: provider.sending ? null : _send,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  isDense: true,
                  filled: true,
                  fillColor: ShopTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: ShopTheme.accent,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SendButton(
              sending: provider.sending,
              onTap: () => _send(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assistant header strip
// ---------------------------------------------------------------------------
class _AssistantHeader extends StatelessWidget {
  final int messageCount;
  final String? lastTopic;
  final bool externalAiEnabled;

  const _AssistantHeader({
    required this.messageCount,
    required this.lastTopic,
    required this.externalAiEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            ShopTheme.accent.withValues(alpha: 0.16),
            ShopTheme.primary.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShopTheme.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const AiAvatar(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fandom AI Helper',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lastTopic != null
                      ? 'Last topic: $lastTopic'
                      : (externalAiEnabled
                            ? 'Answers from the knowledge base, then the AI API'
                            : 'Ask about lore, characters, merch or the store'),
                  style: ShopTheme.label(size: 10.5),
                ),
              ],
            ),
          ),
          if (messageCount > 1)
            ShopTag(
              label: '$messageCount msgs',
              icon: Icons.forum_rounded,
              color: ShopTheme.accent,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Send button with a springy press
// ---------------------------------------------------------------------------
class _SendButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onTap;

  const _SendButton({required this.sending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: sending ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: ShopTheme.aiGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: ShopTheme.accent.withValues(alpha: 0.36),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
