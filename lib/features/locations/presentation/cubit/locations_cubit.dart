import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_countries_usecase.dart';
import 'locations_state.dart';

class LocationsCubit extends Cubit<LocationsState> {
  final GetCountriesUseCase getCountriesUseCase;

  LocationsCubit({required this.getCountriesUseCase})
    : super(const LocationsInitial());

  Future<void> fetchCountries() async {
    emit(const LocationsLoading());
    try {
      final countries = await getCountriesUseCase();
      emit(LocationsLoaded(countries: countries));
    } catch (e) {
      emit(LocationsError(message: e.toString()));
    }
  }
}
