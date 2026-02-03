import '../entities/country_entity.dart';
import '../entities/department_entity.dart';
import '../entities/city_entity.dart';

abstract class LocationsRepository {
  Future<List<CountryEntity>> getCountries();
  Future<List<DepartmentEntity>> getDepartmentsByCountry(String countryId);
  Future<List<CityEntity>> getCitiesByDepartment(String departmentId);
}
