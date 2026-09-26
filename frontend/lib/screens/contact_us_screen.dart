import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/api_config.dart';
import '../models/event_models.dart';
import '../services/api_client.dart';
import '../theme/profile_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/app_alert.dart';
import '../widgets/event_map_view.dart';
import '../widgets/profile_widgets.dart';

/// General functionality - Contact Us.
///
/// SRS: "Inquiry form through which users can submit enquiries / Contact
/// details about the organization/team that has developed the app / Google
/// Maps integration for office location(s)."
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _sending = false;

  /// Office location shown on the map card. Mirrors `TEAM_OFFICE` in
  /// `backend/Controllers/contactcontroller.js`.
  static const MapPin _officePin = MapPin(
    id: 0,
    title: 'FANDOM VERSE Studio',
    city: 'Karachi',
    venue: 'Aptech Learning, Shahrah-e-Faisal',
    latitude: 24.8607,
    longitude: 67.0011,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label copied'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _sending = true);

    final result = await ApiClient.send(
      'POST',
      ApiConfig.contactUrl,
      body: {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
      },
    );

    if (!mounted) return;
    setState(() => _sending = false);

    final ok = result != null && result['success'] == true;

    if (ok) {
      _messageController.clear();
      _subjectController.clear();
      await showSuccessAlert(
        context,
        (result['message'] as String?) ??
            'Your enquiry has been received. Our team replies within 2 working days.',
        title: 'Enquiry Sent',
      );
    } else {
      await showErrorAlert(
        context,
        (result?['message'] as String?) ??
            'Could not send your enquiry. Please check your connection and try again.',
        title: 'Could Not Send',
        accent: ProfileTheme.rose,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      title: 'Contact Us',
      subtitle: 'Questions, feedback or a bug? Tell us.',
      bottomBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: ProfileTheme.card,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
          ),
        ),
        child: GradientActionButton(
          label: 'Send Enquiry',
          icon: Icons.send_rounded,
          busy: _sending,
          onPressed: _submit,
        ),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            // ------------------------------------------------ team details
            SectionHeader(title: 'Reach the team', accent: ProfileTheme.primary),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: ProfileTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: 'support@fandomverse.com',
                    onCopy: () =>
                        _copy('Email', 'support@fandomverse.com'),
                  ),
                  _InfoRow(
                    icon: Icons.call_rounded,
                    label: 'Phone',
                    value: '+92 21 3456 7890',
                    onCopy: () => _copy('Phone', '+92 21 3456 7890'),
                  ),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Support hours',
                    value: 'Mon - Sat, 10:00 AM - 7:00 PM (PKT)',
                  ),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Office',
                    value: 'Aptech Learning, Shahrah-e-Faisal, Karachi',
                    onCopy: () => _copy(
                      'Address',
                      'Aptech Learning, Shahrah-e-Faisal, Karachi',
                    ),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ------------------------------------------------ office map
            SectionHeader(
              title: 'Find us',
              subtitle: 'Office location on the map',
              accent: ProfileTheme.cyan,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 190,
                child: EventMapView(
                  pins: const [_officePin],
                  showCurrentLocation: false,
                  showOverlays: false,
                  overlayPadding: const EdgeInsets.only(top: 8, bottom: 8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'FANDOM VERSE Studio - Aptech Learning, Shahrah-e-Faisal, Karachi',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: ProfileTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 22),

            // ------------------------------------------------ enquiry form
            SectionHeader(
              title: 'Send an enquiry',
              subtitle: 'We reply within 2 working days',
              accent: ProfileTheme.tertiary,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _nameController,
              label: 'Your name',
              hint: 'e.g. Emma Carter',
              icon: Icons.person_outline_rounded,
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _subjectController,
              label: 'Subject (optional)',
              hint: 'What is this about?',
              icon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _messageController,
              label: 'Message',
              hint: 'Tell us how we can help...',
              icon: Icons.chat_bubble_outline_rounded,
              maxLines: 5,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Please write your message';
                if (text.length > 2000) return 'Please keep it under 2000 characters';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// small building blocks
// ---------------------------------------------------------------------------
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
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
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ProfileTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ProfileTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onCopy != null)
                IconButton(
                  tooltip: 'Copy $label',
                  icon: const Icon(Icons.copy_rounded,
                      size: 16, color: ProfileTheme.textMuted),
                  onPressed: onCopy,
                ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: ProfileTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
