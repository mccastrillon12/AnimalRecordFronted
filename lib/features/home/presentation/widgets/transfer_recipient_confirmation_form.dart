import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/auth/presentation/widgets/id_selector.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_state.dart';
import 'package:animal_record/features/home/domain/services/transfer_comment_policy.dart';
import 'package:flutter/material.dart';

class TransferRecipientConfirmationForm extends StatelessWidget {
  final AnimalTransferState state;
  final ValueChanged<String> onIdentificationChanged;
  final ValueChanged<String?> onReasonChanged;
  final ValueChanged<String> onOtherReasonChanged;

  const TransferRecipientConfirmationForm({
    super.key,
    required this.state,
    required this.onIdentificationChanged,
    required this.onReasonChanged,
    required this.onOtherReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final recipient = state.selectedRecipient;
    if (recipient == null) return const SizedBox.shrink();
    final firstName = recipient.name.trim().split(RegExp(r'\s+')).first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: 'Solicita a ',
            style: AppTypography.body4.copyWith(height: 1.6),
            children: [
              TextSpan(text: firstName, style: AppTypography.body3),
              const TextSpan(
                text:
                    ' su número de identificación, la cual debe coincidir '
                    'con la que figura en AnimalRecord.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        IdSelector(
          key: ValueKey('transfer-identification-${recipient.id}'),
          initialValue: state.identificationNumber,
          initialIdType: recipient.formattedIdentificationType,
          idTypeEnabled: false,
          hintText: '',
          labelStyle: AppTypography.body6.copyWith(color: AppColors.greyBordes),
          errorText:
              state.identificationNumber.isNotEmpty &&
                  state.identificationNumber != recipient.identificationNumber
              ? 'La identificación no coincide.'
              : null,
          onChanged: onIdentificationChanged,
        ),
        const SizedBox(height: AppSpacing.m),
        AppDropdown<String>(
          key: const Key('transfer-reason'),
          enabled: !state.isLoadingReasons && state.transferReasons.isNotEmpty,
          label: 'Motivo de transferencia',
          hint: 'Seleccionar',
          value: state.transferReasonCode.isEmpty
              ? null
              : state.transferReasonCode,
          items: state.transferReasons.map((reason) => reason.code).toList(),
          itemAsString: (code) => state.transferReasons
              .firstWhere((reason) => reason.code == code)
              .name,
          preserveOrder: true,
          pushContent: false,
          onChanged: (reason) {
            FocusScope.of(context).unfocus();
            onReasonChanged(reason);
          },
        ),
        if (state.requiresOtherReason) ...[
          const SizedBox(height: AppSpacing.m),
          CustomTextField(
            key: const Key('transfer-other-reason'),
            label: '¿Cuál?',
            initialValue: state.otherReasonDetail,
            maxLength: TransferCommentPolicy.maxLength,
            textInputAction: TextInputAction.done,
            onChanged: onOtherReasonChanged,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
      ],
    );
  }
}
