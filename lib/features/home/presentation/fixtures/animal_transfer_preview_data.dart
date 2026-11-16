import 'package:animal_record/features/home/presentation/models/animal_transfer_recipient.dart';

/// Temporary UI fixture. Remove this file and replace its route injection when
/// the recipient service is available. Never use these IDs for a real transfer.
const animalTransferPreviewRecipients = [
  AnimalTransferRecipient(
    id: 'preview-recipient',
    name: 'Bárbara James',
    maskedIdentification: 'C.C. ****4567',
    isDemo: true,
  ),
];

/// Temporary display options, pending the backend transfer-reason catalog.
const animalTransferPreviewReasons = ['Venta', 'Adopción', 'Otro'];

/// Fictional display contact. No message or OTP is sent to this address.
const animalTransferPreviewVerificationIdentifier = 'marc_doe@hotmail.com';
