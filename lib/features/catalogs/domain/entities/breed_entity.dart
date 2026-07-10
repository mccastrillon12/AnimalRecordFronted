import 'package:equatable/equatable.dart';

class BreedEntity extends Equatable {
  final String id;
  final String name;

  const BreedEntity({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
