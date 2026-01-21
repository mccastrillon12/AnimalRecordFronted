import '../entities/country_entity.dart';

abstract class LocationsRepository {
  Future<List<CountryEntity>> getCountries();
}
