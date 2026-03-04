import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/core/utils/error_display.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthSuccess) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Column(
              children: [
                const UserHeader(),

                const NavigationMenu(),

                const SizedBox(height: 24),

                const Expanded(child: AnimalsSection()),
              ],
            ),
          );
        },
      ),
    );
  }
}
