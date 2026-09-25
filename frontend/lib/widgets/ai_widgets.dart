import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ai_models.dart';
import '../theme/app_theme.dart';
import '../theme/shop_theme.dart';
import 'product_image.dart';
import 'shop_animated.dart';
import 'shop_widgets.dart';

/// MEMBER 5 - AI Fan Helper
/// Chat presentation widgets: the animated assistant avatar, the message
/// bubbles, the typing indicator and the starter/follow-up chips.

// ---------------------------------------------------------------------------
// AiAvatar - rotating gradient ring + floating assistant glyph
// ---------------------------------------------------------------------------
class AiAvatar extends StatelessWidget {
  final double size;
  final bool thinking;

  const AiAvatar({super.key, this.size = 40, this.thinking = false});

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: ShopTheme.aiGradient,
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: size * 0.46,
          color: Colors.white,
        ),
      ),
    );

    return FloatingBox(
      amplitude: thinking ? 4 : 3,
      period: const Duration(milliseconds: 3000),
      child: PulseGlow(
        color: ShopTheme.accent,
        minRadius: 8,
        maxRadius: 18,
        child: SpinningGradientRing(
          padding: 2.5,
          period: Duration(milliseconds: thinking ? 1500 : 4200),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ShopTheme.surface,
            ),
            child: inner,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AiMessageBubble
// ---------------------------------------------------------------------------
class AiMessageBubble extends StatelessWidget {
  final AiMessage message;
  final void Function(String question)? onFollowUp;
  final VoidCallback? onProductTap;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onFollowUp,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isPending) return const AiTypingBubble();

    return message.isUser ? _userBubble() : _aiBubble(context);
  }

  // ------------------------------ user ------------------------------
  Widget _userBubble() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 4, 14, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                gradient: ShopTheme.buyGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ShopTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------ ai ------------------------------
  Widget _aiBubble(BuildContext context) {
    final source = message.sourceLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 40, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiAvatar(size: 32),
          const SizedBox(width: 9),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: ShopTheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.topic != null && source != null) ...[
                    Row(
                      children: [
                        ShopTag(
                          label: message.topic!,
                          icon: Icons.local_offer_rounded,
                          color: ShopTheme.accent,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            source,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ShopTheme.label(size: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                  ],

                  // AI answer image (comes from the FAQ row)
                  if (message.imageUrl != null) ...[
                    ProductImage(
                      imageUrl: message.imageUrl,
                      height: 132,
                      width: double.infinity,
                      radius: 12,
                      animated: true,
                    ),
                    const SizedBox(height: 10),
                  ],

                  Text(
                    message.message,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),

                  if (message.followUps.isNotEmpty && onFollowUp != null) ...[
                    const SizedBox(height: 11),
                    Text(
                      'You might also ask',
                      style: ShopTheme.label(size: 10.5),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.followUps
                          .map(
                            (question) => GestureDetector(
                              onTap: () => onFollowUp!(question),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ShopTheme.accent.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: ShopTheme.accent.withValues(
                                      alpha: 0.32,
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
                  ],

                  if (message.createdAgo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(message.createdAgo, style: ShopTheme.label(size: 9.5)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AiTypingBubble - the "assistant is thinking" placeholder
// ---------------------------------------------------------------------------
class AiTypingBubble extends StatelessWidget {
  const AiTypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 40, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AiAvatar(size: 32, thinking: true),
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: ShopTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TypingDots(),
                SizedBox(width: 8),
                Text(
                  'Looking that up...',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AiSuggestionChips - the starter questions shown before the first message
// ---------------------------------------------------------------------------
class AiSuggestionChips extends StatelessWidget {
  final List<AiSuggestion> suggestions;
  final ValueChanged<String> onSelected;

  const AiSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text('Try asking', style: ShopTheme.label(size: 11)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(suggestions.length, (index) {
              final suggestion = suggestions[index];

              return BounceIn(
                delay: Duration(milliseconds: 70 * index),
                child: GestureDetector(
                  onTap: () => onSelected(suggestion.question),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: ShopTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ShopTheme.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 12,
                          color: ShopTheme.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          suggestion.question,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AiInfoSheet content - explains how the assistant answers
// ---------------------------------------------------------------------------
class AiKnowledgeSummary extends StatelessWidget {
  final List<AiTopicCount> topics;
  final bool externalAiEnabled;

  const AiKnowledgeSummary({
    super.key,
    required this.topics,
    required this.externalAiEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AiAvatar(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fandom AI Helper', style: ShopTheme.title(size: 17)),
                  const SizedBox(height: 2),
                  Text(
                    externalAiEnabled
                        ? 'Knowledge base + external AI API'
                        : 'Offline fandom knowledge base',
                    style: ShopTheme.label(size: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'I answer from a curated fandom knowledge base first, so the app works '
          'without internet. Questions about a product price or stock are answered '
          'straight from the live catalogue.',
          style: ShopTheme.body(size: 12.5),
        ),
        if (topics.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Topics I know about', style: ShopTheme.title(size: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: topics
                .map(
                  (topic) => ShopTag(
                    label: '${topic.topic} (${topic.count})',
                    icon: Icons.auto_awesome_rounded,
                    color: ShopTheme.accent,
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ShopTheme.surfaceLight,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: ShopTheme.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  externalAiEnabled
                      ? 'External AI is configured, so anything outside the knowledge '
                            'base is forwarded to the configured AI API.'
                      : 'Add AI_API_URL and AI_API_KEY to backend/.env to also forward '
                            'unknown questions to an AI API. Without them the assistant '
                            'stays fully offline.',
                  style: ShopTheme.label(size: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
