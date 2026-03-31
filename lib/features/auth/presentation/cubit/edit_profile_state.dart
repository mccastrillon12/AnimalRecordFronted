import 'package:equatable/equatable.dart';
import '../../../../core/validators/email_input.dart';
import '../../../../core/validators/phone_input.dart';
import '../../../../core/validators/text_input.dart';
import '../../domain/entities/user_entity.dart';

class EditProfileState extends Equatable {
  final UserEntity originalUser;

  final TextInput name;
  final EmailInput email;
  final PhoneInput phone;
  final String phoneCountryId;
  final TextInput address;
  final String departmentId;
  final String cityId;

  // Initial sanitized values for comparison
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialPhoneCountryId;
  final String initialAddress;
  final String initialDepartmentId;
  final String initialCityId;

  // Custom validation fields
  final bool isEmailAttempted;
  final bool isPhoneAttempted;

  const EditProfileState({
    required this.originalUser,
    this.name = const TextInput.pure(),
    this.email = const EmailInput.pure(),
    this.phone = const PhoneInput.pure(),
    this.phoneCountryId = '',
    this.address = const TextInput.pure(),
    this.departmentId = '',
    this.cityId = '',
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialPhoneCountryId,
    required this.initialAddress,
    required this.initialDepartmentId,
    required this.initialCityId,
    this.isEmailAttempted = false,
    this.isPhoneAttempted = false,
  });

  bool get hasChanges {
    if (name.value.trim() != initialName) return true;
    if (originalUser.authMethod == 'PHONE' && email.value.trim() != initialEmail) return true;
    if (phone.value.trim() != initialPhone) return true;
    if (address.value.trim() != initialAddress) return true;
    
    if (phoneCountryId != initialPhoneCountryId && !(phoneCountryId.isEmpty && initialPhoneCountryId.isEmpty)) return true;
    if (departmentId != initialDepartmentId && !(departmentId.isEmpty && initialDepartmentId.isEmpty)) return true;
    if (cityId != initialCityId && !(cityId.isEmpty && initialCityId.isEmpty)) return true;

    return false;
  }

  bool get isValid {
    return name.isValid && email.isValid && phone.isValid;
  }

  EditProfileState copyWith({
    TextInput? name,
    EmailInput? email,
    PhoneInput? phone,
    String? phoneCountryId,
    TextInput? address,
    String? departmentId,
    String? cityId,
    bool? isEmailAttempted,
    bool? isPhoneAttempted,
  }) {
    return EditProfileState(
      originalUser: originalUser,
      initialName: initialName,
      initialEmail: initialEmail,
      initialPhone: initialPhone,
      initialPhoneCountryId: initialPhoneCountryId,
      initialAddress: initialAddress,
      initialDepartmentId: initialDepartmentId,
      initialCityId: initialCityId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneCountryId: phoneCountryId ?? this.phoneCountryId,
      address: address ?? this.address,
      departmentId: departmentId ?? this.departmentId,
      cityId: cityId ?? this.cityId,
      isEmailAttempted: isEmailAttempted ?? this.isEmailAttempted,
      isPhoneAttempted: isPhoneAttempted ?? this.isPhoneAttempted,
    );
  }

  @override
  List<Object?> get props => [
        originalUser,
        name,
        email,
        phone,
        phoneCountryId,
        address,
        departmentId,
        cityId,
        isEmailAttempted,
        isPhoneAttempted,
      ];
}
