import '../entities/country_entity.dart';
import '../repositories/locations_repository.dart';

class GetCountriesUseCase {
  final LocationsRepository repository;

  GetCountriesUseCase({required this.repository});

  Future<List<CountryEntity>> call() async {
    return await repository.getCountries();
  }
}
