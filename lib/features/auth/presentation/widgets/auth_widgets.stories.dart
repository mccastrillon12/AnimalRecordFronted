import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'custom_button.dart';
import 'custom_text_field.dart';

@widgetbook.UseCase(name: 'Default', type: CustomButton)
Widget buildCustomButtonUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: CustomButton(
      text: context.knobs.string(label: 'Text', initialValue: 'Continuar'),
      isLoading: context.knobs.boolean(
        label: 'Is Loading',
        initialValue: false,
      ),
      isSecondary: context.knobs.boolean(
        label: 'Is Secondary',
        initialValue: false,
      ),
      onPressed: () {},
    ),
  );
}

@widgetbook.UseCase(name: 'Default', type: CustomTextField)
Widget buildCustomTextFieldUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: CustomTextField(
      label: context.knobs.string(
        label: 'Label',
        initialValue: 'Correo electrónico',
      ),
      hint: context.knobs.string(
        label: 'Hint',
        initialValue: 'ejemplo@correo.com',
      ),
      isPassword: context.knobs.boolean(
        label: 'Is Password',
        initialValue: false,
      ),
    ),
  );
}
