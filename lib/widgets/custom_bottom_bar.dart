import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;
  final VoidCallback? onScanTap;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    this.onTap,
    this.onScanTap,
  });

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
    }

    if (index == selectedIndex) return;

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/document');
        break;
      case 2:
        context.go('/activity');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  void _handleScanTap(BuildContext context) {
    if (onScanTap != null) {
      onScanTap!();
    } else {
      context.push('/documentScanner');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem(context, icon: Icons.home_outlined, label: 'Home', index: 0),
              _buildItem(context, icon: Icons.folder_outlined, label: 'Docs', index: 1),

              // Empty space for center floating scan button
              const SizedBox(width: 70),

              _buildItem(context, icon: Icons.access_time_outlined, label: 'Activity', index: 2),
              _buildItem(context, icon: Icons.settings_outlined, label: 'Settings', index: 3),
            ],
          ),
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _handleScanTap(context),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5046E5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5046E5).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(context, index),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF5046E5) : const Color(0xFF5F6470),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF5046E5) : const Color(0xFF5F6470),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
