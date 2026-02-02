import 'package:dio/dio.dart';
import '../models/country_model.dart';
import '../models/department_model.dart';
import '../models/city_model.dart';

abstract class LocationsRemoteDataSource {
  Future<List<CountryModel>> getCountries();
  Future<List<DepartmentModel>> getDepartmentsByCountry(String countryId);
  Future<List<CityModel>> getCitiesByDepartment(String departmentId);
}

class LocationsRemoteDataSourceImpl implements LocationsRemoteDataSource {
  final Dio dio;

  LocationsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CountryModel>> getCountries() async {
    try {
      final response = await dio.get('/locations/countries');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CountryModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar países');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Error del servidor: $errorMessage');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<List<DepartmentModel>> getDepartmentsByCountry(
    String countryId,
  ) async {
    try {
      final response = await dio.get(
        '/locations/countries/$countryId/departments',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => DepartmentModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar departamentos');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Error del servidor: $errorMessage');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<List<CityModel>> getCitiesByDepartment(String departmentId) async {
    try {
      final response = await dio.get(
        '/locations/departments/$departmentId/cities',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CityModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar ciudades');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception('Error del servidor: $errorMessage');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
