import 'package:equatable/equatable.dart';

class DepartmentEntity extends Equatable {
  final String id;
  final String name;
  final String countryId;

  const DepartmentEntity({
    required this.id,
    required this.name,
    required this.countryId,
  });

  @override
  List<Object?> get props => [id, name, countryId];
}
