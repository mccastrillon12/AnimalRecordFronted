import '../../domain/entities/country_entity.dart';
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
}
