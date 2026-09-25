import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/profile_widgets.dart';

/// MEMBER 1 - Invite Friends.
///
/// "Refer a friend and earn rewards" - shows the personal invite code, share
/// actions, the friends who joined and lets the user claim a friend's code.
class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final TextEditingController _code = TextEditingController();
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadInvite();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _toast(String message) {
    showInfoAlert(context, message, title: 'Invite Friends');
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    if (mounted) _toast('Invite code $code copied');
  }

  Future<void> _share(String message) async {
    // The SRS scope has no external share plugin, so the message is copied to
    // the clipboard ready to paste into any social app.
    await Clipboard.setData(ClipboardData(text: message));
    HapticFeedback.lightImpact();
    if (mounted) _toast('Invite message copied - paste it anywhere');
  }

  Future<void> _claim() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      _toast('Enter a friend\'s invite code first');
      return;
    }

    setState(() => _claiming = true);
    final provider = context.read<ProfileProvider>();
    final message = await provider.claimInvite(code);

    if (!mounted) return;
    setState(() => _claiming = false);
    _toast(message ?? provider.errorMessage ?? 'Could not claim that code');
    if (message != null) _code.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final invite = provider.invite;

    return ProfileScaffold(
      title: 'Invite Friends',
      subtitle: 'Refer a friend and earn rewards',
      child: provider.loading && invite == null
          ? const Center(child: CircularProgressIndicator(color: ProfileTheme.cyan))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                // ------------------------------------------- code card
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: ProfileTheme.headerGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: ProfileTheme.primary.withValues(alpha: 0.34),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.card_giftcard_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Refer a friend and earn rewards',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You get ${invite?.rewardPerInvite ?? 50} fan points for every friend who joins with your code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'YOUR INVITE CODE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.26),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            invite?.inviteCode ?? '——',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _action(
                                'Copy',
                                Icons.copy_rounded,
                                () => _copy(invite?.inviteCode ?? ''),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _action(
                                'Share',
                                Icons.ios_share_rounded,
                                () => _share(invite?.shareMessage ?? ''),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ------------------------------------------- stats
                FadeSlideIn(
                  delay: const Duration(milliseconds: 70),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Friends joined',
                          value: invite?.inviteCount ?? 0,
                          icon: Icons.diversity_3_rounded,
                          color: ProfileTheme.cyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: 'Points earned',
                          value: invite?.pointsEarned ?? 0,
                          icon: Icons.workspace_premium_rounded,
                          color: ProfileTheme.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ------------------------------------------- claim
                const SectionHeader(
                  title: 'Have an invite code?',
                  subtitle: 'Claim it once to get started',
                  accent: ProfileTheme.primary,
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            color: Colors.white,
                            letterSpacing: 1.4,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. FV00001AB12',
                            prefixIcon: Icon(Icons.confirmation_number_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 104,
                        child: GradientActionButton(
                          label: 'Claim',
                          busy: _claiming,
                          height: 54,
                          onPressed: _claim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ------------------------------------------- invited list
                SectionHeader(
                  title: 'Friends you invited',
                  subtitle: '${invite?.invited.length ?? 0} total',
                  accent: ProfileTheme.primary,
                ),
                const SizedBox(height: 12),
                if ((invite?.invited ?? []).isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: ProfileTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.person_add_alt_1_rounded,
                            color: ProfileTheme.textMuted, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nobody yet - share your code and your friends will appear here.',
                            style: TextStyle(
                              color: ProfileTheme.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(invite!.invited.length, (index) {
                    final friend = invite.invited[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 45 * index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: ProfileTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor:
                                  ProfileTheme.primary.withValues(alpha: 0.2),
                              child: Text(
                                friend.name.isEmpty
                                    ? 'F'
                                    : friend.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                friend.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              friend.joinedAgo,
                              style: const TextStyle(
                                color: ProfileTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.check_circle_rounded,
                                color: ProfileTheme.green, size: 17),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
