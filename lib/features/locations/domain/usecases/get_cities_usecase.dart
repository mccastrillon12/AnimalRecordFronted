import '../repositories/locations_repository.dart';
import '../entities/city_entity.dart';

class GetCitiesByDepartmentUseCase {
  final LocationsRepository repository;

  GetCitiesByDepartmentUseCase({required this.repository});

  Future<List<CityEntity>> call(String departmentId) async {
    return await repository.getCitiesByDepartment(departmentId);
  }
}
