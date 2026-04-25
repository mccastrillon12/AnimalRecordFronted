import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_borders.dart';

/// A unified, reusable dropdown component for the entire app.
///
/// Replaces `CustomDropdownField`, `CityDropdown`, and `CountryDropdown`
/// with a single implementation that ensures consistent design, states,
/// and behaviour.
///
/// **States:**
/// - **Idle** — grey border, arrow ↓, shows hint or selected value.
/// - **Open** — primary border, arrow ↑, overlay panel visible.
/// - **Error** — red border, error text below.
/// - **Disabled** — anti-flash background, ignores taps.
///
/// **Modes:**
/// - **Overlay** (default) — options float via [OverlayEntry]; a spacer
///   pushes sibling content down so nothing hides behind the panel.
/// - **Inline** (`isInline: true`) — options render directly in the
///   column layout (no overlay).
class AppDropdown<T> extends StatefulWidget {
  /// Text shown above the input box.
  final String label;

  /// Placeholder when no value is selected.
  final String hint;

  /// Currently selected item (nullable).
  final T? value;

  /// Full list of selectable items.
  final List<T> items;

  /// Converts an item to its display string.
  final String Function(T) itemAsString;

  /// Called when the user selects or clears the value.
  final ValueChanged<T?>? onChanged;

  /// If non-null, shown below the input in red.
  final String? errorText;

  /// Whether the dropdown responds to taps.
  final bool enabled;

  /// Fixed width; defaults to `double.infinity`.
  final double? width;

  /// Override the default label style.
  final TextStyle? labelStyle;

  /// When true the trigger becomes a search field that filters items.
  final bool searchable;

  /// When true the options list renders inline in the layout instead of
  /// using an [OverlayEntry].
  final bool isInline;

  /// When true a "-- Seleccionar --" entry is added at the top of the list
  /// to allow the user to clear the selection.
  final bool showClearOption;

  /// When true (default), opening the overlay injects a spacer that pushes
  /// sibling content down. Set to false for screens that already scroll
  /// (e.g. Edit Profile) where the overlay should float over content.
  final bool pushContent;

  /// Optional custom builder for each option row.
  /// Receives the item and whether it is currently selected.
  /// When null a plain [Text] with [itemAsString] is used.
  final Widget Function(T item, bool isSelected)? itemBuilder;

  /// Optional custom builder for the trigger content (the area inside the
  /// input box, excluding the arrow icon).
  /// Receives the currently selected item (or null).
  /// When null the default text / search-field trigger is rendered.
  final Widget Function(T? selectedItem)? triggerBuilder;

  const AppDropdown({
    super.key,
    required this.label,
    required this.hint,
    this.value,
    required this.items,
    required this.itemAsString,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.width,
    this.labelStyle,
    this.searchable = false,
    this.isInline = false,
    this.showClearOption = true,
    this.pushContent = true,
    this.itemBuilder,
    this.triggerBuilder,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late List<T> _filtered;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filtered = widget.items;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _labelOf(T? value) {
    if (value == null) return '';
    return widget.itemAsString(value);
  }

  void _applyFilter(String query) {
    if (query.isEmpty) {
      _filtered = widget.items;
    } else {
      final lowerQuery = query.toLowerCase();
      _filtered = widget.items.where((item) {
        return widget.itemAsString(item).toLowerCase().contains(lowerQuery);
      }).toList();
    }
    _overlayEntry?.markNeedsBuild();
  }

  // ── Open / close ────────────────────────────────────────────────────────────

  void _toggleDropdown() {
    if (!widget.enabled) return;
    _isOpen ? _closeDropdown() : _openDropdown();
  }

  void _openDropdown() {
    if (_isOpen) return;
    _filtered = widget.items;

    if (widget.searchable) {
      _searchController.text = _labelOf(widget.value);
    }

    if (widget.isInline) {
      setState(() => _isOpen = true);
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
    }

    if (widget.searchable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
      });
    }
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _removeOverlay();
    _filtered = widget.items;

    if (widget.searchable) {
      _focusNode.unfocus();
      _searchController.clear();
    }
    if (mounted) setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(T? value) {
    widget.onChanged?.call(value);
    _closeDropdown();
  }

  // ── Overlay ─────────────────────────────────────────────────────────────────

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
            // Dismiss layer
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
                child: _buildPanel(maxH),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Panel & option list ─────────────────────────────────────────────────────

  Widget _buildPanel(double maxHeight) {
    return Material(
      elevation: 4,
      borderRadius: AppBorders.small(),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyDelineante),
          borderRadius: AppBorders.small(),
          color: Colors.white,
        ),
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: _buildOptionsList(),
      ),
    );
  }

  Widget _buildOptionsList() {
    final clearOffset = widget.showClearOption ? 1 : 0;

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filtered.length + clearOffset,
      itemBuilder: (_, index) {
        // "-- Seleccionar --" option
        if (widget.showClearOption && index == 0) {
          return InkWell(
            onTap: () => _selectItem(null),
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

        final item = _filtered[index - clearOffset];
        final isSelected = widget.value == item;

        return InkWell(
          onTap: () => _selectItem(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: widget.itemBuilder != null
                ? widget.itemBuilder!(item, isSelected)
                : DefaultTextStyle(
                    style: AppTypography.body4.copyWith(
                      color: AppColors.greyTextos,
                    ),
                    child: Text(widget.itemAsString(item)),
                  ),
          ),
        );
      },
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    T? selectedItem;
    if (widget.value != null) {
      try {
        selectedItem = widget.items.firstWhere((i) => i == widget.value);
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
        // ── Label ──────────────────────────────────────────────────
        if (hasLabel)
          SizedBox(
            height: AppSpacing.labelHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: displayLabel,
                      style: (widget.labelStyle ?? AppTypography.body6),
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
        if (hasLabel) const SizedBox(height: AppSpacing.inputTopPadding),

        // ── Trigger ────────────────────────────────────────────────
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
                borderRadius: AppBorders.small(),
                color: widget.enabled
                    ? Colors.white
                    : AppColors.bgBlancoAntiFlash,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: widget.triggerBuilder != null
                        // ── Custom trigger ──────────────────────────
                        ? widget.triggerBuilder!(selectedItem)
                        : widget.searchable && _isOpen
                            // ── Searchable & open: text field ──────
                            ? TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                onChanged: _applyFilter,
                                style: AppTypography.body4.copyWith(
                                  color: AppColors.greyTextos,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: widget.hint,
                                  hintStyle: AppTypography.body4.copyWith(
                                    color: AppColors.greyBordes,
                                  ),
                                ),
                              )
                            // ── Closed or non-searchable ───────────
                            : selectedItem == null
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
                                    child: Text(
                                      widget.itemAsString(selectedItem),
                                    ),
                                  ),
                  ),
                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.greyMedio,
                    size: AppSpacing.iconSizeSmall,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Error ──────────────────────────────────────────────────
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            widget.errorText!,
            style: AppTypography.body5.copyWith(
              color: AppColors.error,
              height: 1.2,
            ),
          ),
        ],

        // ── Spacer for Overlay ─────────────────────────────────────
        // Injects space so sibling content below is pushed down while
        // the overlay is visible.
        if (_isOpen && !widget.isInline && widget.pushContent)
          SizedBox(
            height: ((_filtered.length + (widget.showClearOption ? 1 : 0)) *
                    44.0)
                .clamp(80.0, 250.0),
          ),

        // ── Inline List ────────────────────────────────────────────
        if (_isOpen && widget.isInline)
          _buildPanel(250.0),
      ],
    );
  }
}
