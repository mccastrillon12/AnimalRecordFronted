import 'package:equatable/equatable.dart';
import '../../../../core/validators/phone_input.dart';
import '../../../../core/validators/text_input.dart';

class SocialRegisterState extends Equatable {
  final TextInput name;
  final String email; // Solo de lectura, originario del proveedor social
  final PhoneInput phone;
  final TextInput identificationNumber;
  final String identificationType;
  final String phoneCountryId;

  // Custom validation fields just for view rendering
  final bool isNameAttempted;
  final bool isIdAttempted;
  final bool isPhoneAttempted;

  const SocialRegisterState({
    this.name = const TextInput.pure(),
    this.email = '',
    this.phone = const PhoneInput.pure(),
    this.identificationNumber = const TextInput.pure(),
    this.identificationType = 'CC',
    this.phoneCountryId = '',
    this.isNameAttempted = false,
    this.isIdAttempted = false,
    this.isPhoneAttempted = false,
  });

  bool get isValid {
    return name.isValid && identificationNumber.isValid && phone.isValid;
  }

  SocialRegisterState copyWith({
    TextInput? name,
    String? email,
    PhoneInput? phone,
    TextInput? identificationNumber,
    String? identificationType,
    String? phoneCountryId,
    bool? isNameAttempted,
    bool? isIdAttempted,
    bool? isPhoneAttempted,
  }) {
    return SocialRegisterState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      identificationType: identificationType ?? this.identificationType,
      phoneCountryId: phoneCountryId ?? this.phoneCountryId,
      isNameAttempted: isNameAttempted ?? this.isNameAttempted,
      isIdAttempted: isIdAttempted ?? this.isIdAttempted,
      isPhoneAttempted: isPhoneAttempted ?? this.isPhoneAttempted,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        identificationNumber,
        identificationType,
        phoneCountryId,
        isNameAttempted,
        isIdAttempted,
        isPhoneAttempted,
      ];
}
