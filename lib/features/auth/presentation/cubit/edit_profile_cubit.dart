import 'package:bloc/bloc.dart';
import '../../../../core/validators/email_input.dart';
import '../../../../core/validators/phone_input.dart';
import '../../../../core/validators/text_input.dart';
import 'edit_profile_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/constants/country_constants.dart';
import '../../../../core/utils/string_formatters.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit({required UserEntity user}) : super(_initializeState(user));

  static EditProfileState _initializeState(UserEntity user) {
    final name = StringFormatters.formatName(user.name);
    final email = user.email;
    final address = user.address;

    // As in original code, clean raw phone from country prefix explicitly
    final cleanRawPhone = CountryConstants.stripDialCode(user.cellPhone);
    final countryId = user.countryId;
    final departmentId = user.departmentId;
    final cityId = user.cityId;

    return EditProfileState(
      originalUser: user,
      initialName: name,
      initialEmail: email,
      initialPhone: cleanRawPhone,
      initialAddress: address,
      initialPhoneCountryId: countryId,
      initialDepartmentId: departmentId,
      initialCityId: cityId,
      name: TextInput.dirty(name),
      email: EmailInput.dirty(email),
      phone: PhoneInput.dirty(cleanRawPhone),
      address: TextInput.dirty(address),
      phoneCountryId: countryId,
      departmentId: departmentId,
      cityId: cityId,
    );
  }

  void nameChanged(String value) {
    emit(state.copyWith(name: TextInput.dirty(value)));
  }

  void emailChanged(String value) {
    emit(
      state.copyWith(email: EmailInput.dirty(value), isEmailAttempted: true),
    );
  }

  void phoneChanged(String value) {
    emit(
      state.copyWith(phone: PhoneInput.dirty(value), isPhoneAttempted: true),
    );
  }

  void addressChanged(String value) {
    emit(state.copyWith(address: TextInput.dirty(value)));
  }

  void phoneCountryIdChanged(String value, String prefix) {
    // If the prefix changes, we might want to clean the phone explicitly
    String phoneVal = state.phone.value.replaceAll(RegExp(r'\D'), '');
    final purePrefix = prefix.replaceAll('+', '');
    if (phoneVal.startsWith(purePrefix)) {
      phoneVal = phoneVal.substring(purePrefix.length);
    }
    emit(
      state.copyWith(phoneCountryId: value, phone: PhoneInput.dirty(phoneVal)),
    );
  }

  void departmentChanged(String value) {
    emit(state.copyWith(departmentId: value, cityId: ''));
  }

  void cityChanged(String value) {
    emit(state.copyWith(cityId: value));
  }

  Map<String, dynamic> buildUpdatePayload(String prefix) {
    String cellPhone = state.phone.value.trim();
    if (cellPhone.isNotEmpty && prefix.isNotEmpty) {
      String numbersOnly = cellPhone.replaceAll(RegExp(r'\D'), '');
      final purePrefix = prefix.replaceAll('+', '');
      if (numbersOnly.startsWith(purePrefix)) {
        numbersOnly = numbersOnly.substring(purePrefix.length);
      }
      cellPhone = '$prefix$numbersOnly';
    }

    final updatedData = <String, dynamic>{
      'name': state.name.value,
      'address': state.address.value,
      if (state.originalUser.authMethod == 'PHONE')
        'email': state.email.value.trim(),
      if (state.originalUser.authMethod != 'PHONE') ...{
        'cellPhone': cellPhone,
        if (state.phoneCountryId.isNotEmpty) 'countryId': state.phoneCountryId,
      },
      'cityId': state.cityId,
      'departmentId': state.departmentId,
      if (state.phoneCountryId.isNotEmpty) 'countryId': state.phoneCountryId,
    };

    return updatedData;
  }
}
