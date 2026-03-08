import '../../domain/entities/country_entity.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/city_entity.dart';
import '../../domain/repositories/locations_repository.dart';
import '../datasources/locations_remote_datasource.dart';
import '../datasources/locations_local_datasource.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  final LocationsRemoteDataSource remoteDataSource;
  final LocationsLocalDataSource localDataSource;

  LocationsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<CountryEntity>> getCountries() async {
    try {
      final cached = await localDataSource.getCachedCountries();
      if (cached != null && cached.isNotEmpty) {
        _fetchAndCacheCountries(); // Actualizar caché en background
        return cached;
      }

      return await _fetchAndCacheCountries();
    } catch (e) {
      final cached = await localDataSource.getCachedCountries();
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<List<CountryEntity>> _fetchAndCacheCountries() async {
    final remoteData = await remoteDataSource.getCountries();
    await localDataSource.cacheCountries(remoteData);
    return remoteData;
  }

  @override
  Future<List<DepartmentEntity>> getDepartmentsByCountry(
    String countryId,
  ) async {
    try {
      final cached = await localDataSource.getCachedDepartments(countryId);
      if (cached != null && cached.isNotEmpty) {
        _fetchAndCacheDepartments(countryId);
        return cached;
      }
      return await _fetchAndCacheDepartments(countryId);
    } catch (e) {
      final cached = await localDataSource.getCachedDepartments(countryId);
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<List<DepartmentEntity>> _fetchAndCacheDepartments(
    String countryId,
  ) async {
    final remoteData = await remoteDataSource.getDepartmentsByCountry(
      countryId,
    );
    await localDataSource.cacheDepartments(countryId, remoteData);
    return remoteData;
  }

  @override
  Future<List<CityEntity>> getCitiesByDepartment(String departmentId) async {
    try {
      final cached = await localDataSource.getCachedCities(departmentId);
      if (cached != null && cached.isNotEmpty) {
        _fetchAndCacheCities(departmentId);
        return cached;
      }
      return await _fetchAndCacheCities(departmentId);
    } catch (e) {
      final cached = await localDataSource.getCachedCities(departmentId);
      if (cached != null && cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<List<CityEntity>> _fetchAndCacheCities(String departmentId) async {
    final remoteData = await remoteDataSource.getCitiesByDepartment(
      departmentId,
    );
    await localDataSource.cacheCities(departmentId, remoteData);
    return remoteData;
  }
}
