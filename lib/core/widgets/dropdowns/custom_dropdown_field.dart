import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_spacing.dart';

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
  /// When true the trigger box becomes a search field; typing filters the list.
  final bool searchable;

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
    this.searchable = false,
  });

  @override
  State<CustomDropdownField<T>> createState() => _CustomDropdownFieldState<T>();
}

class _CustomDropdownFieldState<T> extends State<CustomDropdownField<T>> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late List<DropdownMenuItem<T>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void didUpdateWidget(covariant CustomDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filtered = widget.items;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _labelOf(T? value) {
    if (value == null) return '';
    try {
      final item = widget.items.firstWhere((i) => i.value == value);
      if (item.child is Text) return (item.child as Text).data ?? '';
    } catch (_) {}
    return '';
  }

  void _applyFilter(String query) {
    if (query.isEmpty) {
      _filtered = widget.items;
    } else {
      _filtered = widget.items.where((item) {
        final text = (item.child is Text)
            ? (item.child as Text).data?.toLowerCase() ?? ''
            : '';
        return text.contains(query.toLowerCase());
      }).toList();
    }
    _overlayEntry?.markNeedsBuild();
  }

  // ── Open / close ─────────────────────────────────────────────────────────────

  void _toggleDropdown() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_isOpen) return;
    // Always start with full list
    _filtered = widget.items;
    if (widget.searchable) {
      // Show current selection so user can clear it and search
      _searchController.text = _labelOf(widget.value);
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    if (widget.searchable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        // Place cursor at end so user can backspace to edit
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
      });
    }
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _filtered = widget.items;
    if (widget.searchable) {
      _focusNode.unfocus();
      _searchController.clear();
    }
    if (mounted) setState(() => _isOpen = false);
  }

  void _selectItem(T? value) {
    widget.onChanged?.call(value);
    _closeDropdown();
  }

  // ── Overlay ──────────────────────────────────────────────────────────────────

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (_) {
        final renderBox = context.findRenderObject() as RenderBox?;
        final width = renderBox?.size.width ?? 200;
        final mq = MediaQuery.of(context);
        final position = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
        final boxHeight = renderBox?.size.height ?? AppSpacing.inputHeight;
        final dropdownTop = position.dy + boxHeight;
        final bottomBoundary = mq.size.height - mq.padding.bottom - 60.0;
        final maxH = (bottomBoundary - dropdownTop).clamp(80.0, 250.0);

        return Stack(
          children: [
            // Dismiss: closes dropdown
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDropdown,
                behavior: HitTestBehavior.translucent,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              width: width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: Offset.zero,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.greyDelineante),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filtered.length + 1,
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return InkWell(
                            onTap: () => _selectItem(null),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Text(
                                '-- Seleccionar --',
                                style: AppTypography.body4
                                    .copyWith(color: AppColors.greyMedio),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }

                        final item = _filtered[index - 1];
                        return InkWell(
                          onTap: () => _selectItem(item.value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: DefaultTextStyle(
                              style: AppTypography.body4
                                  .copyWith(color: AppColors.greyTextos),
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
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    DropdownMenuItem<T>? selectedItem;
    if (widget.value != null) {
      try {
        selectedItem = widget.items.firstWhere((i) => i.value == widget.value);
      } catch (_) {}
    }

    final hasLabel = widget.label.isNotEmpty;
    final displayLabel = widget.label
        .replaceAll(' (Opcional)', '')
        .replaceAll('(Opcional)', '')
        .trim();
    final isOptional = widget.label.contains('(Opcional)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ─────────────────────────────────────────────────
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
                      style:
                          (widget.labelStyle ?? AppTypography.body6).copyWith(
                        color:
                            widget.labelStyle?.color ?? AppColors.greyNegroV2,
                      ),
                    ),
                    if (isOptional)
                      TextSpan(
                        text: ' (Opcional)',
                        style: AppTypography.body6
                            .copyWith(color: AppColors.greyBordes),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (hasLabel) const SizedBox(height: AppSpacing.inputTopPadding),

        // ── Trigger ───────────────────────────────────────────────
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
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
                color: widget.enabled
                    ? Colors.white
                    : AppColors.bgBlancoAntiFlash,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: widget.searchable && _isOpen
                        // ── Searchable & open: show text field ────────
                        ? TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: _applyFilter,
                            style: AppTypography.body4
                                .copyWith(color: AppColors.greyTextos),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: widget.hint,
                              hintStyle: AppTypography.body4
                                  .copyWith(color: AppColors.greyBordes),
                            ),
                          )
                        // ── Closed or non-searchable: show value/hint ─
                        : selectedItem == null
                            ? Text(
                                widget.hint,
                                style: AppTypography.body4
                                    .copyWith(color: AppColors.greyBordes),
                                overflow: TextOverflow.ellipsis,
                              )
                            : DefaultTextStyle(
                                style: AppTypography.body4
                                    .copyWith(color: AppColors.greyTextos),
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

        // ── Error ──────────────────────────────────────────────────
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: AppTypography.body5
                .copyWith(color: AppColors.error, height: 1.2),
          ),
        ],
      ],
    );
  }
}
