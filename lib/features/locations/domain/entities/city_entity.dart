import 'package:equatable/equatable.dart';

class CityEntity extends Equatable {
  final String id;
  final String name;
  final String departmentId;

  const CityEntity({
    required this.id,
    required this.name,
    required this.departmentId,
  });

  @override
  List<Object?> get props => [id, name, departmentId];
}
