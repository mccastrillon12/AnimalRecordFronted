import 'package:equatable/equatable.dart';

class AnimalTransferRecipient extends Equatable {
  final String id;
  final String name;

  /// Exact backend value for confirmation. Display [maskedIdentification].
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

  String get formattedIdentificationType {
    final type = identificationType.trim().toUpperCase();
    return switch (type.replaceAll(RegExp(r'[.\s]'), '')) {
      'CC' => 'C.C.',
      'CE' => 'C.E.',
      'TI' => 'T.I.',
      'PAS' || 'PASSPORT' => 'PASAPORTE',
      _ => type,
    };
  }

  String get maskedIdentification {
    final number = identificationNumber.trim();
    final type = formattedIdentificationType;
    if (number.isEmpty) return type;
    final suffix = number.length > 4 ? number.substring(number.length - 4) : '';
    return '$type ****${suffix.toUpperCase()}'.trimLeft();
  }

  @override
  List<Object?> get props => [
    id,
    name,
    identificationNumber,
    identificationType,
    imageUrl,
  ];
}
