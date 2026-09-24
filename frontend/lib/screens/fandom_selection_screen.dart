import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class FandomSelectionScreen extends StatefulWidget {
  const FandomSelectionScreen({super.key});

  @override
  State<FandomSelectionScreen> createState() => _FandomSelectionScreenState();
}

class _FandomSelectionScreenState extends State<FandomSelectionScreen> {
  final List<Map<String, dynamic>> _fandoms = [
    {
      'id': 'anime',
      'title': 'Anime',
      'icon': Icons.auto_awesome_rounded,
      'gradient': const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      'selected': true,
    },
    {
      'id': 'gaming',
      'title': 'Gaming',
      'icon': Icons.sports_esports_rounded,
      'gradient': const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      'selected': true,
    },
    {
      'id': 'movies',
      'title': 'Movies & TV',
      'icon': Icons.movie_creation_rounded,
      'gradient': const [Color(0xFFEF4444), Color(0xFFB91C1C)],
      'selected': false,
    },
    {
      'id': 'comics',
      'title': 'Comics',
      'icon': Icons.menu_book_rounded,
      'gradient': const [Color(0xFFF59E0B), Color(0xFFD97706)],
      'selected': false,
    },
    {
      'id': 'music',
      'title': 'Music / K-Pop',
      'icon': Icons.music_note_rounded,
      'gradient': const [Color(0xFF10B981), Color(0xFF047857)],
      'selected': true,
    },
  ];

  void _toggleSelection(int index) {
    setState(() {
      _fandoms[index]['selected'] = !(_fandoms[index]['selected'] as bool);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Choose Your Fandoms',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Select what you're interested in",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Grid of Fandom cards
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _fandoms.length,
                    itemBuilder: (context, index) {
                      final item = _fandoms[index];
                      final isSelected = item['selected'] as bool;
                      final colors = item['gradient'] as List<Color>;

                      return GestureDetector(
                        onTap: () => _toggleSelection(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: colors,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.first.withOpacity(isSelected ? 0.5 : 0.2),
                                blurRadius: isSelected ? 20 : 8,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Background pattern
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child: Icon(
                                  item['icon'] as IconData,
                                  size: 90,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),

                              // Content
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item['title'] as String,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection check icon
                              if (isSelected)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Continue Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
