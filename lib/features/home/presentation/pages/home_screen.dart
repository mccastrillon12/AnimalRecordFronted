import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import '../widgets/user_header.dart';
import '../widgets/navigation_menu.dart';
import '../widgets/animals_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger user data fetch when home screen is reached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(FetchUserRequested());
    });
  }

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
            // Separator
            const SizedBox(height: 52),

            // Animals section (scrollable content)
            const Expanded(child: AnimalsSection()),
          ],
        ),
      ),
    );
  }
}
