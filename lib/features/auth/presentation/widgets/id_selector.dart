import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

/// Reusable component for ID selection with type dropdown and number input
class IdSelector extends StatefulWidget {
  final TextEditingController idController;
  final String? initialIdType;
  final ValueChanged<String>? onIdTypeChanged;

  const IdSelector({
    super.key,
    required this.idController,
    this.initialIdType,
    this.onIdTypeChanged,
  });

  @override
  State<IdSelector> createState() => _IdSelectorState();
}

class _IdSelectorState extends State<IdSelector> {
  late String _selectedIdType;

  @override
  void initState() {
    super.initState();
    _selectedIdType = widget.initialIdType ?? 'C.C.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Common label for the row
        SizedBox(
          height: 18,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Identificación', style: AppTypography.body6),
          ),
        ),

        const SizedBox(height: AppSpacing.inputTopPadding),

        // Row with type dropdown and number input
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID Type selector
            Container(
              height: AppSpacing.inputHeight,
              width: 100, // Fixed width
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyMedio),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedIdType,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: const [
                    DropdownMenuItem(value: 'C.C.', child: Text('C.C.')),
                    DropdownMenuItem(value: 'C.E.', child: Text('C.E.')),
                    DropdownMenuItem(
                      value: 'Pasaporte',
                      child: Text('Pasaporte'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedIdType = value;
                      });
                      widget.onIdTypeChanged?.call(value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.xs), // 8px spacing
            // ID Number input
            SizedBox(
              height: AppSpacing.inputHeight,
              width: 270, // Fixed width
              child: TextFormField(
                controller: widget.idController,
                keyboardType: TextInputType.number,
                style: AppTypography.body4, // Force normal weight style
                decoration: InputDecoration(
                  hintText: '1234567890',
                  hintStyle: AppTypography.body4.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: AppColors.greyMedio,
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: AppColors.greyMedio,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: AppColors.primaryFrances,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
