import 'package:flutter/material.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class TagInputWidget extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> tags;
  final Function(List<String>) onTagsChanged;

  const TagInputWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _controller.text.trim();
    if (tag.isNotEmpty && !widget.tags.contains(tag)) {
      final updatedTags = [...widget.tags, tag];
      widget.onTagsChanged(updatedTags);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    final updatedTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(updatedTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label - matching CustomTextField style exactly
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.label,
            style: AppTypography.body6, // Same as CustomTextField
          ),
        ),

        // Input field and tags container - matching CustomTextField style
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // White background like CustomTextField
            borderRadius: BorderRadius.circular(4), // Same as CustomTextField
            border: Border.all(color: AppColors.greyMedio, width: 1.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags display
              if (widget.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greyMedio.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: AppTypography.body4.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _removeTag(tag),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.greyMedio,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              if (widget.tags.isNotEmpty) const SizedBox(height: 8),

              // Input field - matching CustomTextField style
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: AppTypography.body4, // Same as CustomTextField
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: AppTypography.body4.copyWith(
                          color: AppColors.greyMedio,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.greyMedio,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
