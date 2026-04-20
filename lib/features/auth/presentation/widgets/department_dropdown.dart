import 'package:animal_record/core/widgets/dropdowns/custom_dropdown_field.dart';
import 'package:animal_record/features/locations/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';

class DepartmentDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final List<DepartmentEntity> departments;
  final double? width;
  final bool enabled;
  final TextStyle? labelStyle;

  const DepartmentDropdown({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.departments,
    this.width,
    this.enabled = true,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final validDepartments =
        departments.where((d) => d.name.trim().isNotEmpty).toList();

    return CustomDropdownField<String>(
      label: label,
      hint: 'Selecciona un departamento',
      value: value,
      enabled: enabled,
      width: width,
      labelStyle: labelStyle,
      items: validDepartments.map((dept) {
        return DropdownMenuItem<String>(
          value: dept.id,
          child: Text(dept.name),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
