import '../repositories/locations_repository.dart';
import '../entities/department_entity.dart';

class GetDepartmentsByCountryUseCase {
  final LocationsRepository repository;

  GetDepartmentsByCountryUseCase({required this.repository});

  Future<List<DepartmentEntity>> call(String countryId) async {
    return await repository.getDepartmentsByCountry(countryId);
  }
}
