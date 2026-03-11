import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/locations/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';

class DepartmentDropdown extends StatefulWidget {
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
  State<DepartmentDropdown> createState() => _DepartmentDropdownState();
}

class _DepartmentDropdownState extends State<DepartmentDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (!widget.enabled) return;

    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    final validDepartments = widget.departments
        .where((d) => d.name.trim().isNotEmpty)
        .toList();

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0.0, AppSpacing.inputHeight),
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.greyDelineante),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: validDepartments.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return InkWell(
                          onTap: () {
                            if (widget.onChanged != null) {
                              widget.onChanged!(null);
                            }
                            _closeDropdown();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              '-- Seleccionar --',
                              style: AppTypography.body4.copyWith(
                                color: AppColors.greyMedio,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }

                      final department = validDepartments[index - 1];
                      return InkWell(
                        onTap: () {
                          if (widget.onChanged != null) {
                            widget.onChanged!(department.id);
                          }
                          _closeDropdown();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            department.name,
                            style: AppTypography.body4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DepartmentEntity? selectedDepartment;
    if (widget.value != null) {
      try {
        selectedDepartment = widget.departments
            .cast<DepartmentEntity>()
            .firstWhere((d) => d.id == widget.value);
      } catch (e) {
        selectedDepartment = null;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 18,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.label,
              style: (widget.labelStyle ?? AppTypography.body6).copyWith(
                color: widget.labelStyle?.color ?? AppColors.greyNegroV2,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.inputTopPadding),

        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: _toggleDropdown,
            child: Container(
              height: AppSpacing.inputHeight,
              width: widget.width ?? double.infinity,
              padding: const EdgeInsets.only(left: 12, right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isOpen
                      ? AppColors.primaryFrances
                      : AppColors.greyBordes,
                ),
                borderRadius: BorderRadius.circular(4),
                color: widget.enabled
                    ? Colors.white
                    : AppColors.bgBlancoAntiFlash,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDepartment?.name ?? 'Selecciona un departamento',
                      style: AppTypography.body4.copyWith(
                        color: selectedDepartment == null
                            ? AppColors.greyBordes
                            : AppColors.greyTextos,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.greyMedio,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
