import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

import '../../../../core/validators/email_input.dart';
import '../../../../core/validators/password_input.dart';
import '../../../../core/validators/phone_input.dart';
import '../../../../core/validators/text_input.dart';

enum AccessMethod { email, phone }

class RegisterState extends Equatable {
  final String role;
  final int currentStep;
  final AccessMethod? accessMethod;
  final FormzSubmissionStatus status;

  final TextInput name;
  final EmailInput email;
  final PhoneInput phone;
  final TextInput identificationNumber;
  final String identificationType;
  final String countryId;       // País de residencia (siempre Colombia)
  final String phoneCountryId;  // País del teléfono (seleccionable)
  final TextInput city;
  final TextInput address;
  final TextInput professionalCard;
  final List<String> animalTypes;
  final List<String> services;

  final PasswordInput password;
  final PasswordInput confirmPassword;
  final bool acceptTerms;

  final String? errorMessage;
  
  // Custom validation fields just for view rendering
  final bool isNameAttempted;
  final bool isEmailAttempted;
  final bool isPhoneAttempted;
  final bool isIdAttempted;

  const RegisterState({
    required this.role,
    this.currentStep = 0,
    this.accessMethod,
    this.status = FormzSubmissionStatus.initial,
    this.name = const TextInput.pure(),
    this.email = const EmailInput.pure(),
    this.phone = const PhoneInput.pure(),
    this.identificationNumber = const TextInput.pure(),
    this.identificationType = 'CC',
    this.countryId = '',
    this.phoneCountryId = '',
    this.city = const TextInput.pure(),
    this.address = const TextInput.pure(),
    this.professionalCard = const TextInput.pure(),
    this.animalTypes = const [],
    this.services = const [],
    this.password = const PasswordInput.pure(),
    this.confirmPassword = const PasswordInput.pure(),
    this.acceptTerms = false,
    this.errorMessage,
    this.isNameAttempted = false,
    this.isEmailAttempted = false,
    this.isPhoneAttempted = false,
    this.isIdAttempted = false,
  });

  bool get isCurrentStepValid {
    if (role == 'PROPIETARIO_MASCOTA') {
      if (currentStep == 0) {
        if (accessMethod == AccessMethod.email) return email.isValid;
        if (accessMethod == AccessMethod.phone) return phone.isValid;
        return false;
      }
      if (currentStep == 1) {
        return name.isValid && identificationNumber.isValid && countryId.isNotEmpty;
      }
    } else if (role == 'VETERINARIO') {
      if (currentStep == 0) {
        return name.isValid &&
            email.isValid &&
            identificationNumber.isValid &&
            phone.isValid &&
            countryId.isNotEmpty;
      }
      if (currentStep == 1) {
        return professionalCard.isValid && animalTypes.isNotEmpty && services.isNotEmpty;
      }
    } else {
      // Estudiante, laboratorio
      if (currentStep == 0) {
        return name.isValid &&
            email.isValid &&
            identificationNumber.isValid &&
            phone.isValid &&
            countryId.isNotEmpty;
      }
    }

    // Step Final (Passwords)
    if (currentStep == totalSteps - 1) {
      if (!password.isValid) return false;
      if (password.value != confirmPassword.value) return false;
      return acceptTerms;
    }

    return true;
  }

  int get totalSteps {
    if (role == 'PROPIETARIO_MASCOTA') return 3;
    if (role == 'VETERINARIO') return 3;
    return 2;
  }

  RegisterState copyWith({
    String? role,
    int? currentStep,
    AccessMethod? accessMethod,
    FormzSubmissionStatus? status,
    TextInput? name,
    EmailInput? email,
    PhoneInput? phone,
    TextInput? identificationNumber,
    String? identificationType,
    String? countryId,
    String? phoneCountryId,
    TextInput? city,
    TextInput? address,
    TextInput? professionalCard,
    List<String>? animalTypes,
    List<String>? services,
    PasswordInput? password,
    PasswordInput? confirmPassword,
    bool? acceptTerms,
    String? errorMessage,
    bool? isNameAttempted,
    bool? isEmailAttempted,
    bool? isPhoneAttempted,
    bool? isIdAttempted,
  }) {
    return RegisterState(
      role: role ?? this.role,
      currentStep: currentStep ?? this.currentStep,
      accessMethod: accessMethod ?? this.accessMethod,
      status: status ?? this.status,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      identificationType: identificationType ?? this.identificationType,
      countryId: countryId ?? this.countryId,
      phoneCountryId: phoneCountryId ?? this.phoneCountryId,
      city: city ?? this.city,
      address: address ?? this.address,
      professionalCard: professionalCard ?? this.professionalCard,
      animalTypes: animalTypes ?? this.animalTypes,
      services: services ?? this.services,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      acceptTerms: acceptTerms ?? this.acceptTerms,
      errorMessage: errorMessage, // nullable on purpose
      isNameAttempted: isNameAttempted ?? this.isNameAttempted,
      isEmailAttempted: isEmailAttempted ?? this.isEmailAttempted,
      isPhoneAttempted: isPhoneAttempted ?? this.isPhoneAttempted,
      isIdAttempted: isIdAttempted ?? this.isIdAttempted,
    );
  }

  @override
  List<Object?> get props => [
        role,
        currentStep,
        accessMethod,
        status,
        name,
        email,
        phone,
        identificationNumber,
        identificationType,
        countryId,
        phoneCountryId,
        city,
        address,
        professionalCard,
        animalTypes,
        services,
        password,
        confirmPassword,
        acceptTerms,
        errorMessage,
        isNameAttempted,
        isEmailAttempted,
        isPhoneAttempted,
        isIdAttempted,
      ];
}
