import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_typography.dart';

class PinInputField extends StatefulWidget {
  final String pin;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final FocusNode focusNode;

  const PinInputField({
    super.key,
    required this.pin,
    required this.onChanged,
    required this.focusNode,
    this.obscureText = false,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.pin);
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void didUpdateWidget(PinInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
    if (oldWidget.pin != widget.pin && _controller.text != widget.pin) {
      _controller.text = widget.pin;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Visual Boxes
        GestureDetector(
          onTap: () {
            widget.focusNode.requestFocus();
            _controller.selection =
                TextSelection.collapsed(offset: _controller.text.length);
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFocused = (widget.focusNode.hasFocus &&
                      _controller.text.length == index) ||
                  (_controller.text.length == 4 &&
                      index == 3 &&
                      widget.focusNode.hasFocus);

              // It's also fully filled when length > index
              final isFilled = index < _controller.text.length;

              String char = '';
              if (isFilled) {
                char = widget.obscureText ? '•' : _controller.text[index];
              }

              return Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primaryFrances
                        : const Color(0xFFA8AFBD),
                    width: isFocused ? 2 : 1,
                  ),
                  borderRadius: index == 0
                      ? const BorderRadius.horizontal(left: Radius.circular(8))
                      : index == 3
                          ? const BorderRadius.horizontal(
                              right: Radius.circular(8))
                          : BorderRadius.zero,
                ),
                child: Text(
                  char,
                  style: AppTypography.heading2,
                ),
              );
            }),
          ),
        ),
        // Invisible TextField
        Positioned.fill(
          child: Opacity(
            opacity: 0.0,
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 4,
              autofocus: true,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: widget.onChanged,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
