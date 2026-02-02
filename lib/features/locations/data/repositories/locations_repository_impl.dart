import '../../domain/entities/country_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/repositories/locations_repository.dart';
import '../datasources/locations_remote_datasource.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  final LocationsRemoteDataSource remoteDataSource;

  LocationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CountryEntity>> getCountries() async {
    try {
      return await remoteDataSource.getCountries();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<DepartmentEntity>> getDepartmentsByCountry(
    String countryId,
  ) async {
    try {
      return await remoteDataSource.getDepartmentsByCountry(countryId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CityEntity>> getCitiesByDepartment(String departmentId) async {
    try {
      return await remoteDataSource.getCitiesByDepartment(departmentId);
    } catch (e) {
      rethrow;
    }
  }
}
