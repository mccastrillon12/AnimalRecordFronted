import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class CustomMultiSearchDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final List<T> selectedItems;
  final List<T> items;
  final String Function(T) itemAsString;
  final ValueChanged<List<T>> onChanged;
  final String? errorText;

  const CustomMultiSearchDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.selectedItems,
    required this.items,
    required this.itemAsString,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<CustomMultiSearchDropdown<T>> createState() =>
      _CustomMultiSearchDropdownState<T>();
}

class _CustomMultiSearchDropdownState<T>
    extends State<CustomMultiSearchDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late List<T> _selected;
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.selectedItems);
    _filtered = widget.items;

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _openDropdown();
      } else {
        _closeDropdown();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CustomMultiSearchDropdown<T> oldWidget) {
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
            .where((i) => widget
                .itemAsString(i)
                .toLowerCase()
                .contains(query.toLowerCase()))
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

  void _openDropdown() {
    if (_isOpen) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
        _searchController.clear();
        _filtered = widget.items;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (ctx) {
        // Re-read size on every rebuild so position tracks input height changes
        final renderBox = context.findRenderObject() as RenderBox?;
        final width = renderBox?.size.width ?? 200;

        final mq = MediaQuery.of(context);
        final position = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
        final boxHeight = renderBox?.size.height ?? AppSpacing.inputHeight;
        final dropdownTop = position.dy + boxHeight;
        final bottomBoundary = mq.size.height - mq.padding.bottom - 60.0;
        final maxDropdownHeight = (bottomBoundary - dropdownTop).clamp(80.0, 250.0);

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
                // Always track the bottom-left of the input, even as it grows
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
                    constraints: BoxConstraints(maxHeight: maxDropdownHeight),
                    child: ListView.builder(
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
                            _focusNode.requestFocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  text,
                                  style: AppTypography.body4.copyWith(
                                    color: isSelected
                                        ? AppColors.greyBordes
                                        : AppColors.greyTextos,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check,
                                    color: AppColors.primaryFrances,
                                    size: 20,
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
        );
      },
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
            height: 18,
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

        // ── Input box (same design as CustomDropdownField) ───────
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Container(
              width: double.infinity,
              constraints:
                  const BoxConstraints(minHeight: AppSpacing.inputHeight),
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
                color: Colors.white,
              ),
              child: Row(
                children: [
                  // Chips + search field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Selected chips
                          ..._selected.map((item) => _Chip(
                                label: widget.itemAsString(item),
                                onRemove: () => _toggleItem(item),
                              )),
                          // Search input — no border
                          IntrinsicWidth(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onChanged: _filter,
                              style: AppTypography.body4.copyWith(
                                color: AppColors.greyTextos,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: _selected.isEmpty ? widget.hint : null,
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
                  // Arrow icon — mirrors CustomDropdownField
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

        // ── Error text ───────────────────────────────────────────
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

// ── Chip ──────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgHielo,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.body5.copyWith(color: AppColors.greyMedio),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.greyMedio,
            ),
          ),
        ],
      ),
    );
  }
}
