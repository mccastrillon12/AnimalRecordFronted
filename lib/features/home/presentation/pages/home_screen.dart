import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_event.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/services/token_storage.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/navigation/home_section_navigation.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_feedback.dart';
import 'package:animal_record/features/shared_files/presentation/shared_file_upload_result.dart';
import '../widgets/user_header.dart';
import '../widgets/navigation_menu.dart';
import '../widgets/animals_section.dart';
import '../widgets/my_animals_content.dart';
import '../widgets/vaccination_cards_content.dart';

class HomeScreen extends StatefulWidget {
  final String? initialSection;

  const HomeScreen({super.key, this.initialSection});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Which section of the nav menu is active.
  /// null = Inicio (home), 'mis_animales' = Mis animales page, etc.
  String? _activeSection;
  bool _isPresentingPendingSharedUpload = false;

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SharedFilesCubit>().grantAccess();
      context.read<AuthBloc>().add(FetchUserRequested());
      _presentPendingSharedUpload();
      _checkBiometricActivation();
    });
  }

  Future<void> _presentPendingSharedUpload() async {
    final sharedFiles = context.read<SharedFilesCubit>();
    if (_isPresentingPendingSharedUpload || !sharedFiles.hasPendingFiles) {
      return;
    }

    _isPresentingPendingSharedUpload = true;
    final uploaded = await Navigator.of(context).pushNamed(
      AppRoutes.sharedFileUpload,
      arguments: const {sharedFileExternalUploadArgument: true},
    );
    if (!mounted) return;
    _isPresentingPendingSharedUpload = false;

    if (uploaded is SharedFileUploadResult) {
      setState(() => _activeSection = homeMyAnimalsSection);
      _openSingleAnimalUploadDestination(uploaded);
    } else if (uploaded == true) {
      setState(() => _activeSection = homeMyAnimalsSection);
      ErrorDisplay.showSuccess(context, sharedFileUploadSuccessMessage);
    } else if (uploaded == false) {
      ErrorDisplay.showError(context, sharedFileUploadErrorMessage);
    }
  }

  void _openSingleAnimalUploadDestination(SharedFileUploadResult result) {
    final destination = resolveSharedFileUploadDestination(result);
    if (destination == null) {
      ErrorDisplay.showSuccess(context, sharedFileUploadSuccessMessage);
      return;
    }

    final navigator = Navigator.of(context);
    navigator.pushNamed(AppRoutes.animalDetail, arguments: destination.animal);
    final sectionRouteName = destination.sectionRouteName;
    if (sectionRouteName != null) {
      navigator.pushNamed(
        sectionRouteName,
        arguments: destination.sectionArguments,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ErrorDisplay.showSuccess(context, sharedFileUploadSuccessMessage);
    });
  }

  Future<void> _checkBiometricActivation() async {
    final tokenStorage = sl<TokenStorage>();
    final isPending = await tokenStorage.isBiometricActivationPending();

    if (isPending && mounted) {
      await tokenStorage.setBiometricActivationPending(false);
      if (!mounted) return;

      ErrorDisplay.showSuccess(context, 'Biometría activada exitosamente.');
    }
  }

  void _navigateToSection(String? section) {
    if (openSingleAnimalVaccinations(context, section)) return;

    setState(() {
      _activeSection = section;
    });
  }

  void _handleExternalUploadCancelled() {
    setState(() => _activeSection = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ErrorDisplay.showError(context, sharedFileUploadErrorMessage);
      }
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

                  const SizedBox(height: AppSpacing.l),

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
      case homeMyAnimalsSection:
        return MyAnimalsContent(
          onUploadCancelled: _handleExternalUploadCancelled,
        );
      case 'vaccination_cards':
        return const VaccinationCardsContent();
      default:
        // Home / Inicio
        return AnimalsSection(
          onViewAll: () => _navigateToSection(homeMyAnimalsSection),
        );
    }
  }
}
