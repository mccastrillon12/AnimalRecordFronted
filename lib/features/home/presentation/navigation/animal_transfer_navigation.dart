import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_cubit.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/fixtures/animal_transfer_preview_data.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_screen.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/animal_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Both entry points use the same route. Detail preserves its current model;
/// My animals first uses the existing multi-selection dialog and cached animals.
Future<void> openAnimalTransfer(
  BuildContext context, {
  AnimalModel? animal,
}) async {
  if (animal != null && !animal.isActive) return;
  final List<AnimalModel> selected;
  if (animal != null) {
    selected = [animal];
  } else {
    final animals = context
        .read<AnimalCubit>()
        .animals
        .where((animal) => animal.isActive)
        .toList(growable: false);
    final selection = await showAnimalSelectionModal(
      context: context,
      animals: animals,
      selectedAnimals: const [],
      title: 'Transferir animales',
      continueLabel: 'Transferir',
    );
    if (!context.mounted || selection == null || selection.isEmpty) return;
    selected = selection.map(AnimalModel.fromEntity).toList(growable: false);
  }
  if (!context.mounted) return;
  await Navigator.of(
    context,
  ).pushNamed(AppRoutes.animalTransfer, arguments: selected);
}

PageRouteBuilder<void> buildAnimalTransferRoute(RouteSettings settings) {
  final animals = settings.arguments as List<AnimalModel>;
  return PageRouteBuilder<void>(
    settings: settings,
    opaque: false,
    pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
      create: (_) => AnimalTransferCubit(
        animals: animals,
        recipients: animalTransferPreviewRecipients,
        transferReasons: animalTransferPreviewReasons,
        verificationIdentifier: animalTransferPreviewVerificationIdentifier,
      ),
      child: const AnimalTransferScreen(),
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.ease)),
          ),
          child: child,
        ),
  );
}
