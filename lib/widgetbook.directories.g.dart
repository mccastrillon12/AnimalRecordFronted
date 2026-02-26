import 'package:animal_record/features/auth/presentation/widgets/auth_widgets.stories.dart'
    as _animal_record_features_auth_presentation_widgets_auth_widgets_stories;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'core',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'widgets',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'buttons',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'CustomButton',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Default',
                    builder:
                        _animal_record_features_auth_presentation_widgets_auth_widgets_stories
                            .buildCustomButtonUseCase,
                  ),
                ],
              ),
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'inputs',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'CustomTextField',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Default',
                    builder:
                        _animal_record_features_auth_presentation_widgets_auth_widgets_stories
                            .buildCustomTextFieldUseCase,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
