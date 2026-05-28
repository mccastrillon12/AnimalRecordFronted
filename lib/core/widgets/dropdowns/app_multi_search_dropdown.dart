import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/theme/app_borders.dart';

/// Multi-select dropdown with search and chips.
///
/// Follows the same design language as [AppDropdown]:
/// - Consistent label/error rendering
/// - Same overlay positioning (bottomLeft → topLeft)
/// - Same border states and icon size
class AppMultiSearchDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final List<T> selectedItems;
  final List<T> items;
  final String Function(T) itemAsString;
  final ValueChanged<List<T>> onChanged;
  final String? errorText;
  final bool pushContentDown;
  final bool isInline;
  final bool searchable;
  final bool enabled;
  final int? searchMaxLength;
  final List<TextInputFormatter>? searchInputFormatters;

  /// Called when the user taps the "Add" button shown when there are no
  /// matching results. Receives the current search text.
  /// When null the "Add" row is never shown.
  final ValueChanged<String>? onAddItem;

  /// Label for the add button. Defaults to `'Agregar'`.
  final String addItemLabel;

  const AppMultiSearchDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.selectedItems,
    required this.items,
    required this.itemAsString,
    required this.onChanged,
    this.errorText,
    this.pushContentDown = true,
    this.isInline = false,
    this.searchable = true,
    this.enabled = true,
    this.searchMaxLength = 50,
    this.searchInputFormatters,
    this.onAddItem,
    this.addItemLabel = 'Agregar',
  });

  @override
  State<AppMultiSearchDropdown<T>> createState() =>
      _AppMultiSearchDropdownState<T>();
}

class _AppMultiSearchDropdownState<T> extends State<AppMultiSearchDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  /// When true the search [TextField] is editable and the keyboard is shown.
  /// Starts as false so the first tap only opens the options list.
  bool _keyboardAllowed = false;
  late List<T> _selected;
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.selectedItems);
    _filtered = widget.items;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isOpen) {
        _closeDropdown();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppMultiSearchDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if parent resets the list externally
    if (oldWidget.selectedItems != widget.selectedItems) {
      setState(() {
        _selected = List<T>.from(widget.selectedItems);
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.items;
      } else {
        _filtered = widget.items
            .where(
              (i) => widget
                  .itemAsString(i)
                  .toLowerCase()
                  .contains(query.toLowerCase()),
            )
            .toList();
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _toggleItem(T item) {
    // Update local state immediately so the overlay reflects it at once
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
    _overlayEntry?.markNeedsBuild();
    widget.onChanged(List<T>.from(_selected));
  }

  void _openDropdown({bool withKeyboard = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isOpen) return;
    _keyboardAllowed = withKeyboard;
    if (widget.isInline) {
      setState(() => _isOpen = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.findRenderObject() != null) {
          if (withKeyboard && widget.searchable) {
            _focusNode.requestFocus();
          }
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 1.0,
          );
        }
      });
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
      if (withKeyboard && widget.searchable) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _focusNode.requestFocus();
        });
      }
    }
  }

  /// Enables the keyboard for searching when the dropdown is already open.
  void _enableKeyboard() {
    if (!widget.searchable || _keyboardAllowed) return;
    setState(() => _keyboardAllowed = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _removeOverlay();
    if (mounted) {
      setState(() {
        _isOpen = false;
        _searchController.clear();
        _filtered = widget.items;
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (ctx) {
        final renderBox = context.findRenderObject() as RenderBox?;
        final width = renderBox?.size.width ?? 200;

        final mq = MediaQuery.of(context);
        final position = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
        final boxHeight = renderBox?.size.height ?? AppSpacing.inputHeight;
        final dropdownTop = position.dy + boxHeight;
        final bottomBoundary = mq.size.height - mq.padding.bottom - 60.0;
        final maxDropdownHeight = (bottomBoundary - dropdownTop).clamp(
          80.0,
          250.0,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _focusNode.unfocus(),
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
                child: _buildPanel(maxDropdownHeight),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel(double maxHeight) {
    final query = _searchController.text.trim();
    final showAddRow = widget.onAddItem != null &&
        _filtered.isEmpty &&
        query.isNotEmpty;

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
        child: showAddRow
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.bgBlancoAntiFlash,
                  borderRadius: AppBorders.small(),
                ),
                child: InkWell(
                  borderRadius: AppBorders.small(),
                  onTap: () {
                    final text = _searchController.text.trim();
                    widget.onAddItem?.call(text);
                    _searchController.clear();
                    _filter('');
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
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (_, index) {
                  final item = _filtered[index];
                  final isSelected = _selected.contains(item);
                  final text = widget.itemAsString(item);

                  return InkWell(
                    onTap: () {
                      _toggleItem(item);
                      _searchController.clear();
                      _filter('');
                      if (!widget.isInline) {
                        _focusNode.requestFocus();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              text,
                              style: AppTypography.body4.copyWith(
                                color: isSelected
                                    ? AppColors.greyBordes
                                    : AppColors.greyTextos,
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check,
                              color: AppColors.primaryFrances,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLabel = widget.label.isNotEmpty;
    final displayLabel = widget.label
        .replaceAll(' (Opcional)', '')
        .replaceAll('(Opcional)', '')
        .trim();
    final isOptional = widget.label.contains('(Opcional)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ────────────────────────────────────────────────
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
                      style: AppTypography.body6.copyWith(
                        color: AppColors.greyNegroV2,
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
        if (hasLabel) const SizedBox(height: AppSpacing.inputTopPadding),

        // ── Input box ────────────────────────────────────────────
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: AppSpacing.inputHeight,
            ),
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
                    onTap: widget.enabled
                        ? () {
                            if (_isOpen) {
                              _enableKeyboard();
                            } else {
                              _openDropdown();
                            }
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Selected chips
                          ..._selected.map(
                            (item) => _Chip(
                              label: widget.itemAsString(item),
                              onRemove: () => _toggleItem(item),
                              enabled: widget.enabled,
                            ),
                          ),
                          // Search input — no border
                          IntrinsicWidth(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              enabled: widget.enabled,
                              readOnly: !_keyboardAllowed,
                              showCursor: _keyboardAllowed,
                              onTap: () {
                                if (!_isOpen) {
                                  _openDropdown();
                                } else if (!_keyboardAllowed) {
                                  _enableKeyboard();
                                }
                              },
                              onChanged: widget.searchable ? _filter : null,
                              maxLength: widget.searchMaxLength,
                              buildCounter:
                                  (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) => null,
                              inputFormatters:
                                  widget.searchInputFormatters ??
                                  [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9\s\u00C0-\u017F]'),
                                    ),
                                  ],
                              style: AppTypography.body4.copyWith(
                                color: AppColors.greyTextos,
                              ),
                              decoration: InputDecoration(
                                filled: false,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                hintText: _selected.isEmpty
                                    ? widget.hint
                                    : null,
                                hintStyle: AppTypography.body4.copyWith(
                                  color: AppColors.greyBordes,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Arrow: tap only toggles open/close (no keyboard) ──
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.enabled
                      ? () => _isOpen ? _closeDropdown() : _openDropdown()
                      : null,
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

        // ── Error text ───────────────────────────────────────────
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
        if (_isOpen && !widget.isInline && widget.pushContentDown)
          SizedBox(height: (_filtered.length * 44.0).clamp(80.0, 250.0)),

        // ── Inline List ────────────────────────────────────────────
        if (_isOpen && widget.isInline)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _buildPanel(250.0),
          ),
      ],
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final bool enabled;

  const _Chip({
    required this.label,
    required this.onRemove,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabledBg =
        Color.lerp(
          const Color.fromARGB(255, 187, 216, 235),
          Colors.white,
          0.6,
        ) ??
        AppColors.bgHielo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? AppColors.bgHielo : disabledBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.body6.copyWith(
                color: AppColors.greyTextos,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: enabled ? onRemove : null,
            child: Icon(
              Icons.close,
              size: 14,
              color: enabled ? AppColors.greyMedio : AppColors.greyTextos,
            ),
          ),
        ],
      ),
    );
  }
}
