import 'package:equatable/equatable.dart';

/// Generic catalog item used for: housing types, animal purposes,
/// temperaments, identification types, and registration associations.
/// All share the same {id, name, speciesId} shape from the backend.
/// AdoptionSource also uses this (speciesId will be null).
class CatalogItemEntity extends Equatable {
  final String id;
  final String name;
  final String? speciesId;

  const CatalogItemEntity({
    required this.id,
    required this.name,
    this.speciesId,
  });

  @override
  List<Object?> get props => [id, name, speciesId];
}
