import 'package:equatable/equatable.dart';

class AnimalTransferRecipient extends Equatable {
  final String id;
  final String name;

  /// Exact backend value, never rendered as a hint.
  final String identificationNumber;
  final String? imageUrl;
  final String identificationType;

  const AnimalTransferRecipient({
    required this.id,
    required this.name,
    required this.identificationNumber,
    required this.identificationType,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    identificationNumber,
    identificationType,
    imageUrl,
  ];
}
