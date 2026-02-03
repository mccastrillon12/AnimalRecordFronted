import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/features/locations/domain/entities/country_entity.dart';
import 'package:flutter/material.dart';

class CountryDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final List<CountryEntity> countries;
  final double? width;
  final bool enabled;
  final bool showIsoCodeAsValue;
  final TextStyle? labelStyle;

  const CountryDropdown({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    required this.countries,
    this.width,
    this.enabled = true,
    this.showIsoCodeAsValue = false,
    this.labelStyle,
  });

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
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
    final validCountries = widget.countries
        .where((c) => c.name.trim().isNotEmpty)
        .toList();

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Modal barrier to close on tap outside
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
                    itemCount: validCountries.length,
                    itemBuilder: (context, index) {
                      final country = validCountries[index];
                      // Flag logic based on standard country codes or API response

                      return InkWell(
                        onTap: () {
                          if (widget.onChanged != null) {
                            widget.onChanged!(country.id);
                          }
                          _closeDropdown();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/icons/${country.isoCode}.png',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: AppColors.greyMedio,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.showIsoCodeAsValue
                                      ? country.isoCode
                                      : country.name,
                                  style: AppTypography.body4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
    // Find selected country
    // Find selected country
    final CountryEntity selectedCountry = widget.countries
        .cast<CountryEntity>()
        .firstWhere(
          (c) => c.id == widget.value,
          orElse: () => widget.countries.isNotEmpty
              ? widget.countries.first
              : const CountryEntity(
                  id: '',
                  name: '',
                  isoCode: '',
                  dialCode: '',
                ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
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
              width: widget.width ?? 116,
              padding: const EdgeInsets.only(left: 12, right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isOpen
                      ? AppColors.primaryFrances
                      : AppColors.greyMedio,
                ),
                borderRadius: BorderRadius.circular(4),
                color: widget.enabled
                    ? Colors.white
                    : AppColors.bgBlancoAntiFlash,
              ),
              child: Row(
                children: [
                  if (widget.countries.isNotEmpty) ...[
                    ClipOval(
                      child: Image.asset(
                        'assets/icons/${selectedCountry.isoCode}.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.greyMedio,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.showIsoCodeAsValue
                            ? selectedCountry.isoCode
                            : selectedCountry.name,
                        style: AppTypography.body4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  // Custom arrow icon to match design
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
