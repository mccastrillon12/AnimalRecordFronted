import 'package:equatable/equatable.dart';

class SpeciesEntity extends Equatable {
  final String id;
  final String name;

  const SpeciesEntity({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
