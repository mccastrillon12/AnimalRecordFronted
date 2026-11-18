import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/domain/entities/animal_entity.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_cubit.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/services/transfer_pending_medical_work.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/home/presentation/pages/animal_transfer_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_requests_screen.dart';
import 'package:animal_record/features/shared_files/presentation/widgets/animal_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Both entry points use the same route. Detail preserves its current model;
/// My animals uses the current active-animal search before selection.
Future<void> openAnimalTransfer(
  BuildContext context, {
  AnimalModel? animal,
}) async {
  if (animal != null && !animal.isActive) return;
  final List<AnimalModel> selected;
  if (animal != null) {
    selected = [animal];
  } else {
    final List<AnimalEntity> animals;
    try {
      animals = await di.sl<AnimalTransferRepository>().getActiveAnimals();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron consultar los animales activos.'),
          ),
        );
      }
      return;
    }
    if (!context.mounted || animals.isEmpty) return;
    final selection = await showAnimalSelectionModal(
      context: context,
      animals: animals,
      selectedAnimals: const [],
      title: 'Transferir animales',
      continueLabel: 'Transferir',
      searchMaxLength: 20,
    );
    if (!context.mounted || selection == null || selection.isEmpty) return;
    selected = selection.map(AnimalModel.fromEntity).toList(growable: false);
  }
  if (!context.mounted) return;
  if (di.sl<TransferPendingMedicalWork>().overlaps(
    selected.map((item) => item.id).toList(growable: false),
  )) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Termina o descarta el documento médico pendiente antes de transferir.',
        ),
      ),
    );
    return;
  }
  await Navigator.of(
    context,
  ).pushNamed(AppRoutes.animalTransfer, arguments: selected);
}

Future<void> openAnimalTransferRequests(
  BuildContext context, {
  bool focusPending = false,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AnimalTransferRequestsScreen(
        repository: di.sl<AnimalTransferRepository>(),
        focusPending: focusPending,
      ),
    ),
  );
}

PageRouteBuilder<void> buildAnimalTransferRoute(RouteSettings settings) {
  final animals = settings.arguments as List<AnimalModel>;
  return PageRouteBuilder<void>(
    settings: settings,
    opaque: false,
    pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
      create: (_) => AnimalTransferCubit(
        animals: animals,
        repository: di.sl<AnimalTransferRepository>(),
      )..loadReasons(),
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
