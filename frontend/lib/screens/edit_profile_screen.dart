import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_image.dart';
import '../widgets/profile_widgets.dart';

/// MEMBER 1 - Edit Profile (name, bio, avatar, visibility).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;

  String _avatar = '';
  bool _isPublic = true;
  bool _initialised = false;

  static const int _bioLimit = 240;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _bio = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProfileProvider>();
      provider.loadAvatars();
      if (provider.user == null) provider.loadProfile();
      _fillFromProvider(provider);
    });
  }

  void _fillFromProvider(ProfileProvider provider) {
    final user = provider.user;
    if (user == null || _initialised) return;
    _initialised = true;
    _name.text = user.name;
    _bio.text = user.bio;
    _avatar = user.avatar;
    _isPublic = user.isPublic;
  }

  /// Fills the form as soon as the profile payload arrives (never during
  /// `build`, so no setState-during-build errors).
  void _scheduleFill(ProfileProvider provider) {
    if (_initialised || provider.user == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _fillFromProvider(provider));
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<ProfileProvider>();
    final name = _name.text.trim();

    if (name.length < 2) {
      _toast('Please enter your name', isError: true);
      return;
    }

    final message = await provider.updateProfile(
      name: name,
      bio: _bio.text.trim(),
      avatar: _avatar,
      isPublic: _isPublic,
    );

    if (!mounted) return;
    if (message != null) {
      await _toast(message);
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } else {
      await _toast(provider.errorMessage ?? 'Could not save your profile',
          isError: true);
    }
  }

  Future<void> _toast(String message, {bool isError = false}) async {
    if (isError) {
      await showErrorAlert(context, message,
          title: 'Could Not Save', accent: ProfileTheme.rose);
    } else {
      await showSuccessAlert(context, message,
          title: 'Profile Updated', accent: ProfileTheme.cyan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    _scheduleFill(provider);

    final avatars = provider.avatars;
    final previewName = _name.text.trim().isEmpty ? 'Fan' : _name.text.trim();

    return ProfileScaffold(
      title: 'Edit Profile',
      subtitle: 'Changes are saved to your account',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          // ------------------------------------------- avatar preview
          FadeSlideIn(
            child: Center(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ProfileTheme.badgeGradient,
                    ),
                    child: AppAvatar(
                      path: _avatar,
                      name: previewName,
                      radius: 52,
                      showRing: false,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose an avatar',
                    style: TextStyle(
                      color: ProfileTheme.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------- avatar picker
          if (avatars.isNotEmpty)
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final path = avatars[index];
                  final selected = _avatar == path;
                  return PressScale(
                    pressedScale: 0.9,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _avatar = selected ? '' : path);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: selected ? ProfileTheme.badgeGradient : null,
                        border: selected
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: ProfileTheme.primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: AppImage(path: path, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // ------------------------------------------- name / bio
          FadeSlideIn(
            delay: const Duration(milliseconds: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Display name'),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                  decoration: const InputDecoration(
                    hintText: 'Your fan name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                _label('Bio'),
                TextField(
                  controller: _bio,
                  maxLines: 4,
                  maxLength: _bioLimit,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Tell other fans what you are into...',
                    counterStyle: TextStyle(
                      color: ProfileTheme.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ------------------------------------------- visibility
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: SettingsSwitchTile(
              title: 'Public profile',
              subtitle: 'Other fans can see your profile, fandoms and badges',
              icon: Icons.public_rounded,
              color: ProfileTheme.cyan,
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
          ),
          const SizedBox(height: 22),

          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: GradientActionButton(
              label: 'Save Changes',
              icon: Icons.check_rounded,
              busy: provider.saving,
              onPressed: _save,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: ProfileTheme.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
