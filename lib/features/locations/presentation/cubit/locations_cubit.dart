import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_countries_usecase.dart';
import '../../domain/usecases/get_departments_usecase.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import 'locations_state.dart';

class LocationsCubit extends Cubit<LocationsState> {
  final GetCountriesUseCase getCountriesUseCase;
  final GetDepartmentsByCountryUseCase getDepartmentsByCountryUseCase;
  final GetCitiesByDepartmentUseCase getCitiesByDepartmentUseCase;

  LocationsCubit({
    required this.getCountriesUseCase,
    required this.getDepartmentsByCountryUseCase,
    required this.getCitiesByDepartmentUseCase,
  }) : super(const LocationsInitial());

  Future<void> fetchCountries() async {
    emit(const LocationsLoading());
    try {
      final countries = await getCountriesUseCase();
      emit(LocationsLoaded(countries: countries));
    } catch (e) {
      emit(LocationsError(message: e.toString()));
    }
  }

  Future<void> fetchDepartments(String countryId) async {
    try {
      final departments = await getDepartmentsByCountryUseCase(countryId);
      if (state is LocationsLoaded) {
        emit(
          (state as LocationsLoaded).copyWith(
            departments: departments,
            cities: [],
          ),
        );
      }
    } catch (e) {
      emit(LocationsError(message: e.toString()));
    }
  }

  Future<void> fetchCities(String departmentId) async {
    try {
      final cities = await getCitiesByDepartmentUseCase(departmentId);
      if (state is LocationsLoaded) {
        emit((state as LocationsLoaded).copyWith(cities: cities));
      }
    } catch (e) {
      emit(LocationsError(message: e.toString()));
    }
  }
}
