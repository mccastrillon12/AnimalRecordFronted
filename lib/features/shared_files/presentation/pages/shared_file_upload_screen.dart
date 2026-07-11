import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/dropdowns/app_multi_search_dropdown.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_state.dart';
import 'package:animal_record/features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedFileUploadScreen extends StatefulWidget {
  const SharedFileUploadScreen({super.key});

  @override
  State<SharedFileUploadScreen> createState() => _SharedFileUploadScreenState();
}

class _SharedFileUploadScreenState extends State<SharedFileUploadScreen> {
  late final TextEditingController _fileNameController;
  final TextEditingController _descriptionController = TextEditingController();
  List<AnimalEntity> _selectedAnimals = const [];

  @override
  void initState() {
    super.initState();
    final files = context.read<SharedFilesCubit>().pendingFiles;
    _fileNameController = TextEditingController(
      text: files.isEmpty ? '' : files.first.name,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess) {
        context.read<AnimalCubit>().loadAnimals(authState.user.id);
      }
    });
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _close() {
    context.read<SharedFilesCubit>().clear();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalPageLayout(
      title: 'Subir documento',
      fixedTitle: true,
      fixedHeaderHeight: 130,
      titlePadding: const EdgeInsets.only(top: 92, bottom: 12),
      titleStyle: AppTypography.body1.copyWith(
        color: AppColors.greyTextos,
        fontWeight: FontWeight.w700,
      ),
      onClose: _close,
      bottomSafeAreaColor: AppColors.bgBlancoAntiFlash,
      bottomPadding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      bottomChild: const CustomButton(text: 'Subir documento', onPressed: null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Los archivos cargados estarán disponibles en la sección '
              'correspondiente a su tipo de documento.',
              style: AppTypography.body4.copyWith(
                color: AppColors.greyTextos,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            CustomTextField(
              label: 'Nombre del archivo',
              controller: _fileNameController,
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.m),
            BlocBuilder<AnimalCubit, AnimalState>(
              builder: (context, state) {
                final cubit = context.read<AnimalCubit>();
                return AppMultiSearchDropdown<AnimalEntity>(
                  label: 'Animal(es)',
                  hint: state is AnimalsLoading
                      ? 'Cargando animales...'
                      : 'Seleccione el animal o animales',
                  selectedItems: _selectedAnimals,
                  items: cubit.animals
                      .where((animal) => animal.isActive)
                      .toList(),
                  itemAsString: (animal) => animal.name,
                  enabled: state is! AnimalsLoading,
                  onChanged: (animals) {
                    setState(() => _selectedAnimals = animals);
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.m),
            CustomTextField(
              label: 'Descripción (Opcional)',
              controller: _descriptionController,
              maxLength: 250,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
