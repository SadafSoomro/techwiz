import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/fandom_logo.dart';
import '../widgets/profile_widgets.dart';

/// General functionality - About Us.
///
/// SRS: "About Us: Details about the team/people behind the app." The SRS also
/// asks for the AI tooling used to be acknowledged, so that lives here too.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const List<({IconData icon, String title, String body})> _features = [
    (
      icon: Icons.auto_awesome_rounded,
      title: 'Fandom Hub',
      body:
          'News, galleries, video clips, podcasts, deep-dive lore and a beginner glossary for every universe.',
    ),
    (
      icon: Icons.event_rounded,
      title: 'Events & Maps',
      body:
          'Nearby conventions, meetups and screenings on a map and a calendar, filterable by city and category.',
    ),
    (
      icon: Icons.shopping_bag_rounded,
      title: 'Merch Store',
      body:
          'Official apparel, figures and digital assets with a wishlist, cart and a simulated checkout.',
    ),
    (
      icon: Icons.forum_rounded,
      title: 'Community',
      body:
          'Discussions, likes, comments, follows, bookmarks and notifications with fellow fans.',
    ),
    (
      icon: Icons.smart_toy_rounded,
      title: 'AI Fan Helper',
      body:
          'Ask about lore, characters, the store or the event calendar - it answers from the live app data.',
    ),
    (
      icon: Icons.cloud_off_rounded,
      title: 'Offline & Bookmarks',
      body:
          'Save articles, media and events for offline reading, with everything cached locally.',
    ),
  ];

  static const List<({String role, String scope})> _team = [
    (role: 'Member 1', scope: 'Profile, fandom interests & home dashboard'),
    (role: 'Member 2', scope: 'Fandom content hub, news, gallery, video & podcasts'),
    (role: 'Member 3', scope: 'Search, discussions & community'),
    (role: 'Member 4', scope: 'Events, maps & calendar'),
    (role: 'Member 5', scope: 'Merchandise store & AI Fan Helper'),
  ];

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      title: 'About Us',
      subtitle: 'Fandom Verse Pocket Edition',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          // ------------------------------------------------ hero
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                gradient: ProfileTheme.headerGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: ProfileTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const FandomLogoWidget(height: 76),
                  const SizedBox(height: 14),
                  Text(
                    'Your Fandom. All in One Place.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Version 1.0.0  •  Multi-Platform App Computing',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // ------------------------------------------------ what it is
          const SectionHeader(
            title: 'Why Fandom Verse',
            accent: ProfileTheme.primary,
          ),
          const SizedBox(height: 12),
          _Paragraph(
            'Fandom life is scattered across social media, standalone websites and niche forums. '
            'Fandom Verse Pocket Edition pulls all of it into one mobile app: content, events, '
            'community and official merchandise, so a fan never has to hunt across five platforms '
            'for one answer.',
          ),
          const SizedBox(height: 22),

          // ------------------------------------------------ features
          const SectionHeader(
            title: 'What you can do',
            subtitle: 'Built from the project SRS',
            accent: ProfileTheme.tertiary,
          ),
          const SizedBox(height: 12),
          ..._features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FeatureTile(
                icon: feature.icon,
                title: feature.title,
                body: feature.body,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------ tech
          const SectionHeader(
            title: 'How it is built',
            accent: ProfileTheme.cyan,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProfileTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: const [
                _TechRow(
                  icon: Icons.phone_iphone_rounded,
                  label: 'App',
                  value: 'Flutter 3 / Dart, Provider state management',
                ),
                _TechRow(
                  icon: Icons.dns_rounded,
                  label: 'Backend',
                  value: 'Node.js + Express REST API',
                ),
                _TechRow(
                  icon: Icons.storage_rounded,
                  label: 'Database',
                  value: 'SQLite (schema initialised on boot)',
                ),
                _TechRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Auth',
                  value: 'Email/password + Google, JWT sessions',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ------------------------------------------------ team
          const SectionHeader(
            title: 'The team',
            subtitle: 'Who built what',
            accent: ProfileTheme.amber,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProfileTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              children: [
                for (final member in _team)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: ProfileTheme.badgeGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            member.role.replaceAll('Member ', ''),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.role,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: ProfileTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member.scope,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: ProfileTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'FANDOM VERSE Studio  •  Aptech Learning, Karachi',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ProfileTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ------------------------------------------------ ai note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProfileTheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: ProfileTheme.tertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.smart_toy_outlined,
                    size: 18, color: ProfileTheme.tertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI tools acknowledged: GitHub Copilot was used as a coding assistant for '
                    'scaffolding, debugging and review. All design decisions, data modelling and '
                    'implementation were reviewed and adapted by the team.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.5,
                      color: ProfileTheme.textSecondary,
                    ),
                  ),
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
// building blocks
// ---------------------------------------------------------------------------
class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          height: 1.6,
          color: ProfileTheme.textSecondary,
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfileTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ProfileTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: ProfileTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ProfileTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.45,
                    color: ProfileTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  const _TechRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 16, color: ProfileTheme.cyan),
              const SizedBox(width: 10),
              SizedBox(
                width: 62,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: ProfileTheme.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ProfileTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
      ],
    );
  }
}
