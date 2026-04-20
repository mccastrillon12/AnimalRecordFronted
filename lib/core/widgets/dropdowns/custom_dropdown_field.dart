import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_borders.dart';

class CustomDropdownField<T> extends StatefulWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;
  final bool enabled;
  final double? width;
  final TextStyle? labelStyle;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.width,
    this.labelStyle,
  });

  @override
  State<CustomDropdownField<T>> createState() => _CustomDropdownFieldState<T>();
}

class _CustomDropdownFieldState<T> extends State<CustomDropdownField<T>> {
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
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    // Boundary logic
    final mq = MediaQuery.of(context);
    final position = renderBox.localToGlobal(Offset.zero);
    final dropdownTop = position.dy + AppSpacing.inputHeight;
    final bottomBoundary = mq.size.height - mq.padding.bottom - 60.0;
    final maxDropdownHeight = (bottomBoundary - dropdownTop).clamp(80.0, 250.0);

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
                  constraints: BoxConstraints(maxHeight: maxDropdownHeight),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.items.length + 1,
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
                              vertical: 12,
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

                      final item = widget.items[index - 1];
                      return InkWell(
                        onTap: () {
                          if (widget.onChanged != null) {
                            widget.onChanged!(item.value);
                          }
                          _closeDropdown();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: DefaultTextStyle(
                            style: AppTypography.body4.copyWith(
                               color: AppColors.greyTextos,
                            ),
                            child: item.child,
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
    DropdownMenuItem<T>? selectedItem;
    if (widget.value != null) {
      try {
        selectedItem = widget.items.firstWhere((i) => i.value == widget.value);
      } catch (e) {
        selectedItem = null;
      }
    }

    final hasLabel = widget.label.isNotEmpty;
    String displayLabel = widget.label.replaceAll(' (Opcional)', '').replaceAll('(Opcional)', '').trim();
    bool isOptional = widget.label.contains('(Opcional)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel)
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: displayLabel,
                      style: (widget.labelStyle ?? AppTypography.body6).copyWith(
                        color: widget.labelStyle?.color ?? AppColors.greyNegroV2,
                      ),
                    ),
                    if (isOptional)
                      TextSpan(
                        text: ' (Opcional)',
                        style: AppTypography.body6.copyWith(
                          color: AppColors.greyBordes,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        if (hasLabel)
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
                      : widget.errorText != null
                          ? AppColors.errorRojo
                          : AppColors.greyBordes,
                ),
                borderRadius: BorderRadius.circular(4),
                color: widget.enabled ? Colors.white : AppColors.bgBlancoAntiFlash,
              ),
              child: Row(
                children: [
                   Expanded(
                    child: selectedItem == null 
                        ? Text(
                            widget.hint,
                            style: AppTypography.body4.copyWith(
                              color: AppColors.greyBordes,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ) 
                        : DefaultTextStyle(
                            style: AppTypography.body4.copyWith(
                              color: AppColors.greyTextos,
                            ),
                            child: selectedItem.child,
                          ),
                  ),

                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.greyMedio,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: AppTypography.body5.copyWith(
              color: AppColors.error,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
