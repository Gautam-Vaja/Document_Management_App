import 'package:document_management_app/core/app_images.dart';
import 'package:document_management_app/core/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderScreen extends StatelessWidget {
  const HeaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(AppImages.appIcon, width: 40, height: 40),
        const SizedBox(width: 10),
        Text(
          AppStrings.Heading,
          style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        ClipOval(
          child: Image.asset(
            AppImages.profile,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
