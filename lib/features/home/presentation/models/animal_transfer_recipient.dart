import 'package:equatable/equatable.dart';

/// Display-only recipient. The transfer API contract is not defined yet.
class AnimalTransferRecipient extends Equatable {
  final String id;
  final String name;
  final String maskedIdentification;
  final String? imageUrl;
  final bool isDemo;
  final String identificationType;

  const AnimalTransferRecipient({
    required this.id,
    required this.name,
    required this.maskedIdentification,
    this.imageUrl,
    this.isDemo = false,
    this.identificationType = 'C.C.',
  });

  @override
  List<Object?> get props => [
    id,
    name,
    maskedIdentification,
    imageUrl,
    isDemo,
    identificationType,
  ];
}
