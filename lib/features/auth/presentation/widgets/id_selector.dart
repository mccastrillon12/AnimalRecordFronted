import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

class IdSelector extends StatefulWidget {
  final TextEditingController idController;
  final String? initialIdType;
  final ValueChanged<String>? onIdTypeChanged;
  final String? errorText;

  const IdSelector({
    super.key,
    required this.idController,
    this.initialIdType,
    this.onIdTypeChanged,
    this.errorText,
  });

  @override
  State<IdSelector> createState() => _IdSelectorState();
}

class _IdSelectorState extends State<IdSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late String _selectedIdType;
  final List<String> _idTypes = ['C.C.', 'C.E.', 'Pasaporte'];

  @override
  void initState() {
    super.initState();
    _selectedIdType = widget.initialIdType ?? 'C.C.';
  }

  void _toggleDropdown() {
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
            width: _selectedIdType == 'Pasaporte' ? 140 : 100,
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
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _idTypes.length,
                    itemBuilder: (context, index) {
                      final type = _idTypes[index];

                      final isSelected = type == _selectedIdType;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIdType = type;
                          });
                          widget.onIdTypeChanged?.call(type);
                          _closeDropdown();
                        },
                        child: Container(
                          color: isSelected ? AppColors.greyClaro : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            type,
                            style: AppTypography.body4.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 18,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Identificación', style: AppTypography.body6),
          ),
        ),
        const SizedBox(height: AppSpacing.inputTopPadding),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                onTap: _toggleDropdown,
                child: Container(
                  height: AppSpacing.inputHeight,
                  width: _selectedIdType == 'Pasaporte' ? 140 : 100,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isOpen
                          ? AppColors.primaryFrances
                          : (widget.errorText != null
                                ? AppColors.error
                                : AppColors.greyMedio),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedIdType, style: AppTypography.body4),
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
            const SizedBox(width: AppSpacing.xs),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: AppSpacing.inputHeight,
                    child: TextFormField(
                      controller: widget.idController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9]'),
                        ),
                      ],
                      maxLength: 50,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                      style: AppTypography.body4,
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
                          borderSide: BorderSide(
                            color: widget.errorText != null
                                ? AppColors.error
                                : AppColors.greyMedio,
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: widget.errorText != null
                                ? AppColors.error
                                : AppColors.greyMedio,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: widget.errorText != null
                                ? AppColors.error
                                : AppColors.primaryFrances,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.errorText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.errorText!,
                      style: AppTypography.body6.copyWith(
                        color: AppColors.error,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
