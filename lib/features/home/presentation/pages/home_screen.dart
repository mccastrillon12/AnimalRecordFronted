import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import '../widgets/user_header.dart';
import '../widgets/navigation_menu.dart';
import '../widgets/animals_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // User header (profile info and notifications)
            const UserHeader(),

            // Navigation menu (Mapa, +Animal, Agenda, etc.)
            const NavigationMenu(),

            // Separator
            Container(
              height: 1,
              color: AppColors.greyClaro,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.m),
            ),

            // Animals section (scrollable content)
            const Expanded(child: AnimalsSection()),
          ],
        ),
      ),
    );
  }
}
