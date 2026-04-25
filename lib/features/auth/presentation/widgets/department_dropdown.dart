import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/features/locations/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';

/// Thin wrapper over [AppDropdown] for selecting a department.
class DepartmentDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final List<DepartmentEntity> departments;
  final double? width;
  final bool enabled;
  final TextStyle? labelStyle;
  final bool pushContent;

  const DepartmentDropdown({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.departments,
    this.width,
    this.enabled = true,
    this.labelStyle,
    this.pushContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final validDepartments =
        departments.where((d) => d.name.trim().isNotEmpty).toList();

    // Resolve the selected entity from the id
    DepartmentEntity? selectedDept;
    if (value != null) {
      try {
        selectedDept = validDepartments.firstWhere((d) => d.id == value);
      } catch (_) {}
    }

    return AppDropdown<DepartmentEntity>(
      label: label,
      hint: 'Selecciona un departamento',
      value: selectedDept,
      items: validDepartments,
      itemAsString: (d) => d.name,
      onChanged: (dept) => onChanged?.call(dept?.id),
      enabled: enabled,
      width: width,
      labelStyle: labelStyle,
      isInline: true,
      pushContent: pushContent,
    );
  }
}
