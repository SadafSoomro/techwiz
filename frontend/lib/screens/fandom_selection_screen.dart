import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/content_widgets.dart';
import '../widgets/profile_widgets.dart';
import 'home_screen.dart';

/// MEMBER 1 - Fandom Selection (the onboarding step after Sign Up).
///
/// SRS: "Role and Category Selection - users can select primary fandom
/// interests (for example, Anime, Gaming, Sci-Fi, or Comics) during setup."
///
/// The choice is persisted through `PUT /api/profile/fandoms`; "Skip" stores
/// nothing so the fan can pick later from My Fandoms.
class FandomSelectionScreen extends StatefulWidget {
  const FandomSelectionScreen({super.key});

  @override
  State<FandomSelectionScreen> createState() => _FandomSelectionScreenState();
}

class _FandomSelectionScreenState extends State<FandomSelectionScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadFandoms();
    });
  }

  Future<void> _goHome({bool skipped = false}) async {
    if (_navigated) return;

    final provider = context.read<ProfileProvider>();
    final message = await provider.saveFandoms(skipped: skipped);
    if (!mounted) return;

    if (message == null) {
      await showErrorAlert(
        context,
        provider.errorMessage ?? 'Could not save your fandoms',
        title: 'Could Not Save',
        accent: ProfileTheme.rose,
      );
      return;
    }

    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final fandoms = provider.fandoms;
    final selected = provider.selected;
    final canContinue = selected.isNotEmpty && !provider.saving;

    final selectedColor = selected.isEmpty
        ? ProfileTheme.primary
        : ProfileTheme.fandomColor(selected.first);

    return Scaffold(
      backgroundColor: ProfileTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: ProfileTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ------------------------------------------------ header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: Column(
                  children: [
                    FadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: ProfileTheme.headerGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ProfileTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 22,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 26),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 70),
                      child: const Text(
                        'Select Fandoms',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: const Text(
                        'Pick what you love - you can change this anytime',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ProfileTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // selection counter
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selectedColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: selectedColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PulsingCounter(count: selected.length),
                            const SizedBox(width: 7),
                            Text(
                              selected.length == 1
                                  ? 'fandom selected'
                                  : 'fandoms selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ------------------------------------------------ grid
              Expanded(
                child: !provider.fandomSelectionLoaded
                    ? _buildLoading()
                    : fandoms.isEmpty
                        ? const EmptyContentState(
                            title: 'No fandoms available',
                            message:
                                'The fandom list could not be loaded. Check that the backend is running.',
                            icon: Icons.cloud_off_rounded,
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.92,
                            ),
                            itemCount: fandoms.length,
                            itemBuilder: (context, index) {
                              final fandom = fandoms[index];
                              final isSelected = selected.contains(fandom.name);
                              return FadeSlideIn(
                                delay: Duration(milliseconds: 60 * index),
                                child: FandomSelectCard(
                                  fandom: fandom,
                                  selected: isSelected,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    provider.toggleFandom(fandom.name);
                                  },
                                ),
                              );
                            },
                          ),
              ),

              // ------------------------------------------------ actions
              Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                decoration: BoxDecoration(
                  color: ProfileTheme.card.withValues(alpha: 0.7),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
                  ),
                ),
                child: Column(
                  children: [
                    GradientActionButton(
                      label: selected.isEmpty
                          ? 'Next'
                          : 'Next · ${selected.length} selected',
                      icon: Icons.arrow_forward_rounded,
                      busy: provider.saving,
                      enabled: canContinue,
                      onPressed: () => _goHome(),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed:
                          provider.saving ? null : () => _goHome(skipped: true),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          color: ProfileTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.92,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const Shimmer(
        height: 170,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}

/// Small number that bumps every time the selection changes.
class PulsingCounter extends StatefulWidget {
  const PulsingCounter({super.key, required this.count});

  final int count;

  @override
  State<PulsingCounter> createState() => _PulsingCounterState();
}

class _PulsingCounterState extends State<PulsingCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.85,
      upperBound: 1.15,
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant PulsingCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _controller.forward(from: 1.15).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Text(
        '${widget.count}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
