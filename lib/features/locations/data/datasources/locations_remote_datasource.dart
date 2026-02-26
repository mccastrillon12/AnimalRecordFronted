import 'package:animal_record/core/network/api_client.dart';
import '../models/country_model.dart';
import '../models/department_model.dart';
import '../models/city_model.dart';

abstract class LocationsRemoteDataSource {
  Future<List<CountryModel>> getCountries();
  Future<List<DepartmentModel>> getDepartmentsByCountry(String countryId);
  Future<List<CityModel>> getCitiesByDepartment(String departmentId);
}

class LocationsRemoteDataSourceImpl implements LocationsRemoteDataSource {
  final ApiClient apiClient;

  LocationsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CountryModel>> getCountries() async {
    final response = await apiClient.get('/locations/countries');
    final List<dynamic> data = response.data;
    return data.map((json) => CountryModel.fromJson(json)).toList();
  }

  @override
  Future<List<DepartmentModel>> getDepartmentsByCountry(
    String countryId,
  ) async {
    final response = await apiClient.get(
      '/locations/countries/$countryId/departments',
    );
    final List<dynamic> data = response.data;
    return data.map((json) => DepartmentModel.fromJson(json)).toList();
  }

  @override
  Future<List<CityModel>> getCitiesByDepartment(String departmentId) async {
    final response = await apiClient.get(
      '/locations/departments/$departmentId/cities',
    );
    final List<dynamic> data = response.data;
    return data.map((json) => CityModel.fromJson(json)).toList();
  }
}
