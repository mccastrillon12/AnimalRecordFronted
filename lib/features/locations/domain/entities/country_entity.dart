import 'package:equatable/equatable.dart';

class CountryEntity extends Equatable {
  final String id;
  final String name;
  final String isoCode;

  const CountryEntity({
    required this.id,
    required this.name,
    required this.isoCode,
  });

  @override
  List<Object?> get props => [id, name, isoCode];
}
