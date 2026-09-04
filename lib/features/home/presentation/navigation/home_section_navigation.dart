import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const homeInitialSectionArgument = 'initialSection';
const homeMyAnimalsSection = 'mis_animales';

/// Opens the vaccination record directly when there is no animal to choose.
///
/// Returns whether the menu selection was handled as a direct navigation.
bool openSingleAnimalVaccinations(BuildContext context, String? section) {
  if (section != 'vaccination_cards') return false;

  final animals = context.read<AnimalCubit>().animals;
  if (animals.length != 1) return false;

  Navigator.of(context).pushNamed<void>(
    AppRoutes.animalVaccinations,
    arguments: AnimalModel.fromEntity(animals.single),
  );
  return true;
}
