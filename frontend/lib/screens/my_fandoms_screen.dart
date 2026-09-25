import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/profile_widgets.dart';

/// MEMBER 1 - My Fandoms.
///
/// The same catalogue as the setup flow, but here it edits an existing
/// selection (SRS: "Users can view and update ... fandoms that they liked").
class MyFandomsScreen extends StatefulWidget {
  const MyFandomsScreen({super.key});

  @override
  State<MyFandomsScreen> createState() => _MyFandomsScreenState();
}

class _MyFandomsScreenState extends State<MyFandomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().loadFandoms();
    });
  }

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    final message = await provider.saveFandoms();

    if (!mounted) return;

    if (message != null) {
      await showSuccessAlert(context, message, title: 'Fandoms Saved');
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } else {
      await showErrorAlert(
        context,
        provider.errorMessage ?? 'Could not save',
        title: 'Could Not Save',
        accent: ProfileTheme.rose,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final fandoms = provider.fandoms;
    final selected = provider.selected;

    return ProfileScaffold(
      title: 'My Fandoms',
      subtitle: '${selected.length} selected',
      actions: [
        TextButton(
          onPressed: selected.isEmpty ? null : provider.clearFandomSelection,
          child: const Text('Clear',
              style: TextStyle(color: ProfileTheme.textSecondary, fontSize: 12.5)),
        ),
      ],
      bottomBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: ProfileTheme.card,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
          ),
        ),
        child: GradientActionButton(
          label: 'Save Fandoms',
          icon: Icons.check_rounded,
          busy: provider.saving,
          enabled: selected.isNotEmpty,
          onPressed: _save,
        ),
      ),
      child: !provider.fandomSelectionLoaded
          ? const Center(
              child: CircularProgressIndicator(color: ProfileTheme.primary),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.94,
              ),
              itemCount: fandoms.length,
              itemBuilder: (context, index) {
                final fandom = fandoms[index];
                final isSelected = selected.contains(fandom.name);
                return FadeSlideIn(
                  delay: Duration(milliseconds: 55 * index),
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
    );
  }
}
