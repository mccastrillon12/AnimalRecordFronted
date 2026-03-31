import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/validators/phone_input.dart';
import '../../../../core/validators/text_input.dart';
import 'social_register_state.dart';

class SocialRegisterCubit extends Cubit<SocialRegisterState> {
  SocialRegisterCubit({required String name, required String email})
      : super(SocialRegisterState(name: TextInput.dirty(name), email: email));

  void nameChanged(String value) {
    emit(state.copyWith(
      name: TextInput.dirty(value),
      isNameAttempted: true,
    ));
  }

  void identificationTypeChanged(String type) {
    emit(state.copyWith(identificationType: type));
  }

  void identificationNumberChanged(String value) {
    emit(state.copyWith(
      identificationNumber: TextInput.dirty(value),
      isIdAttempted: true,
    ));
  }

  void phoneChanged(String value) {
    emit(state.copyWith(
      phone: PhoneInput.dirty(value),
      isPhoneAttempted: true,
    ));
  }

  void phoneCountryIdChanged(String value) {
    emit(state.copyWith(phoneCountryId: value));
  }

  Map<String, dynamic> buildPayload({
    required String preAuthToken,
    required String countryToSend,
    required String countryPrefix,
  }) {
    String idType = 'CC';
    if (state.identificationType == 'C.E.') idType = 'CE';
    if (state.identificationType == 'Pasaporte') idType = 'PAS';

    String cellPhone = state.phone.value.trim();
    if (cellPhone.isNotEmpty && countryPrefix.isNotEmpty) {
      String numbersOnly = cellPhone.replaceAll(RegExp(r'\D'), '');
      final purePrefix = countryPrefix.replaceAll('+', '');
      if (numbersOnly.startsWith(purePrefix)) {
        numbersOnly = numbersOnly.substring(purePrefix.length);
      }
      cellPhone = '$countryPrefix$numbersOnly';
    }

    return {
      'preAuthToken': preAuthToken,
      'identificationNumber': state.identificationNumber.value.trim(),
      'identificationType': idType,
      'cellPhone': cellPhone,
      'country': countryToSend,
      'city': '',
      'roles': ['PROPIETARIO_MASCOTA'],
    };
  }
}
