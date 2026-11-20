import 'package:animal_record/features/home/domain/services/animal_write_policy.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

bool canWriteAnimal(
  BuildContext context,
  AnimalModel snapshot, {
  bool listen = false,
}) {
  final cubit = listen
      ? context.watch<AnimalCubit?>()
      : context.read<AnimalCubit?>();
  return AnimalWritePolicy.canWrite(
    snapshot: snapshot.toEntity(),
    currentAnimals: cubit?.animals,
  );
}
