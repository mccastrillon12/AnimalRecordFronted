import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import '../widgets/user_header.dart';
import '../widgets/navigation_menu.dart';
import '../widgets/animals_section.dart';
import '../widgets/my_animals_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Which section of the nav menu is active.
  /// null = Inicio (home), 'mis_animales' = Mis animales page, etc.
  String? _activeSection;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(FetchUserRequested());
      _checkBiometricActivation();
    });
  }

  Future<void> _checkBiometricActivation() async {
    final tokenStorage = sl<TokenStorage>();
    final isPending = await tokenStorage.isBiometricActivationPending();

    if (isPending && mounted) {
      await tokenStorage.setBiometricActivationPending(false);

      ErrorDisplay.showSuccess(context, 'Biometría activada exitosamente.');
    }
  }

  void _navigateToSection(String? section) {
    setState(() {
      _activeSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is! AuthSuccess) {
                return const Center(child: CircularProgressIndicator());
              }

              // Load animals for the authenticated user
              final cubit = context.read<AnimalCubit>();
              cubit.loadAnimals(state.user.id);

              return SafeArea(
                top: false,
                child: Column(
                  children: [
                    const UserHeader(),

                    NavigationMenu(
                      onSectionChanged: _navigateToSection,
                      activeSection: _activeSection,
                    ),

                    const SizedBox(height: 24),

                    Expanded(child: _buildContent()),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }

  Widget _buildContent() {
    switch (_activeSection) {
      case 'mis_animales':
        return const MyAnimalsContent();
      default:
        // Home / Inicio
        return AnimalsSection(
          onViewAll: () => _navigateToSection('mis_animales'),
        );
    }
  }
}
