import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// When true, items keep their original list order instead of being sorted
  /// alphabetically.
  final bool preserveOrder;

  /// Optional custom builder for each option row.
  /// Receives the item and whether it is currently selected.
  /// When null a plain [Text] with [itemAsString] is used.
  final Widget Function(T item, bool isSelected)? itemBuilder;

  /// Optional custom builder for the trigger content (the area inside the
  /// input box, excluding the arrow icon).
  /// Receives the currently selected item (or null).
  /// When null the default text / search-field trigger is rendered.
  final Widget Function(T? selectedItem)? triggerBuilder;

  /// Optional max length for the search input.
  final int? searchMaxLength;

  /// Optional input formatters for the search input.
  final List<TextInputFormatter>? searchInputFormatters;

  /// Called when the user taps the "Add" button shown when there are no
  /// matching results. Receives the current search text.
  /// When null the "Add" row is never shown.
  final ValueChanged<String>? onAddItem;

  /// Label for the add button. Defaults to `'Agregar'`.
  final String addItemLabel;

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
    this.preserveOrder = false,
    this.itemBuilder,
    this.triggerBuilder,
    this.searchMaxLength = 50,
    this.searchInputFormatters,
    this.onAddItem,
    this.addItemLabel = 'Agregar',
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
  /// When true the search [TextField] is editable and the keyboard is shown.
  /// Starts as false so the first tap only opens the options list.
  bool _keyboardAllowed = false;
  late List<T> _filtered;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  List<T> _getSortedItems(List<T> items) {
    final list = List<T>.from(items);
    if (widget.preserveOrder) return list;
    list.sort((a, b) => widget.itemAsString(a).toLowerCase().compareTo(widget.itemAsString(b).toLowerCase()));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _filtered = _getSortedItems(widget.items);
  }

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filtered = _getSortedItems(widget.items);
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
    setState(() {
      if (query.isEmpty) {
        _filtered = _getSortedItems(widget.items);
      } else {
        final lowerQuery = query.toLowerCase();
        final matched = widget.items.where((item) {
          return widget.itemAsString(item).toLowerCase().contains(lowerQuery);
        }).toList();
        _filtered = _getSortedItems(matched);
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  // ── Open / close ────────────────────────────────────────────────────────────

  void _openDropdown({bool withKeyboard = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isOpen) return;
    _filtered = _getSortedItems(widget.items);
    _keyboardAllowed = withKeyboard;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (withKeyboard && widget.searchable) {
        _focusNode.requestFocus();
        _searchController.selection = TextSelection.collapsed(
          offset: _searchController.text.length,
        );
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Enables the keyboard for searching when the dropdown is already open.
  void _enableKeyboard() {
    if (!widget.searchable || _keyboardAllowed) return;
    setState(() => _keyboardAllowed = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _removeOverlay();
    _filtered = _getSortedItems(widget.items);

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
    final query = _searchController.text.trim();
    final showAddRow = widget.onAddItem != null && query.isNotEmpty;
    final addRowOffset = showAddRow ? 1 : 0;

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _filtered.length + clearOffset + addRowOffset,
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

        // "Add custom" row — always last
        if (showAddRow && index == _filtered.length + clearOffset) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.bgBlancoAntiFlash,
              borderRadius: AppBorders.small(),
            ),
            child: InkWell(
              borderRadius: AppBorders.small(),
              onTap: () {
                final text = _searchController.text.trim();
                widget.onAddItem?.call(text);
                _closeDropdown();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        query,
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyTextos,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.addItemLabel,
                      style: AppTypography.body3.copyWith(
                        color: AppColors.primaryFrances,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
          child: Container(
            height: AppSpacing.inputHeight,
            width: widget.width ?? double.infinity,
            padding: const EdgeInsets.only(left: 12, right: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: !widget.enabled
                    ? AppColors.greyDelineante
                    : _isOpen
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
                // ── Input area: tap opens dropdown; shows keyboard if already open ──
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: !widget.enabled
                        ? null
                        : () {
                            if (_isOpen) {
                              _enableKeyboard();
                            } else {
                              _openDropdown();
                            }
                          },
                    child: widget.triggerBuilder != null
                        // ── Custom trigger ──────────────────────────
                        ? widget.triggerBuilder!(selectedItem)
                        : widget.searchable && _isOpen
                            // ── Searchable & open: text field ──────
                            ? TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                readOnly: !_keyboardAllowed,
                                showCursor: _keyboardAllowed,
                                onTap: !_keyboardAllowed ? _enableKeyboard : null,
                                onChanged: _applyFilter,
                                maxLength: widget.searchMaxLength,
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                inputFormatters: widget.searchInputFormatters ?? [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\u00C0-\u017F]')),
                                ],
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
                            : selectedItem == null && widget.value == null
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
                                      selectedItem != null
                                          ? widget.itemAsString(selectedItem)
                                          : _labelOf(widget.value),
                                    ),
                                  ),
                  ),
                ),
                // ── Arrow: tap only toggles open/close (no keyboard) ──
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: !widget.enabled
                      ? null
                      : () => _isOpen ? _closeDropdown() : _openDropdown(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      _isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: widget.enabled
                          ? AppColors.greyMedio
                          : Color.lerp(AppColors.greyMedio, Colors.white, 0.6),
                      size: AppSpacing.iconSizeSmall,
                    ),
                  ),
                ),
              ],
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
