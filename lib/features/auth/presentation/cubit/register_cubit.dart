import 'package:bloc/bloc.dart';
import '../../../../core/validators/email_input.dart';
import '../../../../core/validators/password_input.dart';
import '../../../../core/validators/phone_input.dart';
import '../../../../core/validators/text_input.dart';
import 'register_state.dart';
import '../../domain/entities/register_params.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({required String role})
      : super(RegisterState(role: role));

  void accessMethodChanged(AccessMethod method) {
    emit(state.copyWith(accessMethod: method));
  }

  void nameChanged(String value) {
    emit(state.copyWith(
      name: TextInput.dirty(value),
      isNameAttempted: true,
    ));
  }

  void emailChanged(String value) {
    emit(state.copyWith(
      email: EmailInput.dirty(value),
      isEmailAttempted: true,
    ));
  }

  void phoneChanged(String value) {
    emit(state.copyWith(
      phone: PhoneInput.dirty(value),
      isPhoneAttempted: true,
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

  void countryIdChanged(String value) {
    // Residencia (Colombia fija)
    emit(state.copyWith(countryId: value));
  }

  void phoneCountryIdChanged(String value) {
    // País del teléfono (seleccionable por el usuario)
    emit(state.copyWith(phoneCountryId: value));
  }

  void cityChanged(String value) {
    emit(state.copyWith(city: TextInput.dirty(value)));
  }

  void addressChanged(String value) {
    emit(state.copyWith(address: TextInput.dirty(value)));
  }

  void professionalCardChanged(String value) {
    emit(state.copyWith(professionalCard: TextInput.dirty(value)));
  }

  void animalTypesChanged(List<String> types) {
    emit(state.copyWith(animalTypes: types));
  }

  void servicesChanged(List<String> svcs) {
    emit(state.copyWith(services: svcs));
  }

  void passwordChanged(String value) {
    emit(state.copyWith(password: PasswordInput.dirty(value)));
  }

  void confirmPasswordChanged(String value) {
    emit(state.copyWith(confirmPassword: PasswordInput.dirty(value)));
  }

  void acceptTermsChanged(bool value) {
    emit(state.copyWith(acceptTerms: value));
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  RegisterParams buildParams({required String userId, required String finalPhone}) {
    return RegisterParams(
      id: userId,
      name: state.name.value,
      email: state.email.value,
      password: state.password.value,
      identificationType: state.role == 'PROPIETARIO_MASCOTA'
          ? state.identificationType.replaceAll('.', '').toUpperCase()
          : 'CC',
      identificationNumber: state.identificationNumber.value,
      cellPhone: finalPhone,
      country: '',
      countryId: state.phoneCountryId.isNotEmpty ? state.phoneCountryId : state.countryId,
      city: state.role == 'PROPIETARIO_MASCOTA' ? '' : state.city.value,
      address: '',
      roles: [state.role],
      professionalCard: state.role == 'VETERINARIO' ? state.professionalCard.value : '',
      animalTypes: state.role == 'VETERINARIO' ? state.animalTypes : [],
      services: state.role == 'VETERINARIO' ? state.services : [],
      isHomeDelivery: state.role == 'VETERINARIO' ? true : false,
      authMethod: state.accessMethod == AccessMethod.phone ? 'PHONE' : 'EMAIL',
    );
  }
}
