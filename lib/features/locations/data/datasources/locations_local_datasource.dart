import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/country_model.dart';
import '../models/department_model.dart';
import '../models/city_model.dart';

abstract class LocationsLocalDataSource {
  Future<List<CountryModel>?> getCachedCountries();
  Future<void> cacheCountries(List<CountryModel> countries);

  Future<List<DepartmentModel>?> getCachedDepartments(String countryId);
  Future<void> cacheDepartments(
    String countryId,
    List<DepartmentModel> departments,
  );

  Future<List<CityModel>?> getCachedCities(String departmentId);
  Future<void> cacheCities(String departmentId, List<CityModel> cities);
}

class LocationsLocalDataSourceImpl implements LocationsLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _cachedCountriesKey = 'CACHED_COUNTRIES';
  static const String _cachedDepartmentsPrefix = 'CACHED_DEPARTMENTS_';
  static const String _cachedCitiesPrefix = 'CACHED_CITIES_';

  LocationsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<CountryModel>?> getCachedCountries() async {
    final jsonString = sharedPreferences.getString(_cachedCountriesKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => CountryModel.fromJson(json)).toList();
    }
    return null;
  }

  @override
  Future<void> cacheCountries(List<CountryModel> countries) async {
    final List<Map<String, dynamic>> jsonList = countries
        .map((c) => c.toJson())
        .toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(_cachedCountriesKey, jsonString);
  }

  @override
  Future<List<DepartmentModel>?> getCachedDepartments(String countryId) async {
    final jsonString = sharedPreferences.getString(
      '$_cachedDepartmentsPrefix$countryId',
    );
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => DepartmentModel.fromJson(json)).toList();
    }
    return null;
  }

  @override
  Future<void> cacheDepartments(
    String countryId,
    List<DepartmentModel> departments,
  ) async {
    final List<Map<String, dynamic>> jsonList = departments
        .map((d) => d.toJson())
        .toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(
      '$_cachedDepartmentsPrefix$countryId',
      jsonString,
    );
  }

  @override
  Future<List<CityModel>?> getCachedCities(String departmentId) async {
    final jsonString = sharedPreferences.getString(
      '$_cachedCitiesPrefix$departmentId',
    );
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => CityModel.fromJson(json)).toList();
    }
    return null;
  }

  @override
  Future<void> cacheCities(String departmentId, List<CityModel> cities) async {
    final List<Map<String, dynamic>> jsonList = cities
        .map((c) => c.toJson())
        .toList();
    final jsonString = json.encode(jsonList);
    await sharedPreferences.setString(
      '$_cachedCitiesPrefix$departmentId',
      jsonString,
    );
  }
}
