import 'dart:async';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:animal_record/core/widgets/buttons/custom_button.dart';
import 'package:animal_record/core/widgets/display/app_user_avatar.dart';
import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/widgets/feedback/process_cancellation_dialog.dart';
import 'package:animal_record/core/widgets/layout/modal_page_layout.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_state.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_recipient.dart';
import 'package:animal_record/features/home/presentation/widgets/animal_record_search_field.dart';
import 'package:animal_record/features/home/presentation/widgets/transfer_animals_summary.dart';
import 'package:animal_record/features/home/presentation/widgets/transfer_recipient_confirmation_form.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_verification_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_success_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_requests_screen.dart';
import 'package:animal_record/features/home/presentation/navigation/home_section_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnimalTransferScreen extends StatefulWidget {
  const AnimalTransferScreen({super.key});

  @override
  State<AnimalTransferScreen> createState() => _AnimalTransferScreenState();
}

class _AnimalTransferScreenState extends State<AnimalTransferScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _animalsExpanded = false;
  bool _allowPop = false;
  bool _isCancelling = false;
  bool _isFinishing = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<AnimalTransferCubit>().state.query;
    _searchController.addListener(_search);
  }

  void _search() {
    _searchDebounce?.cancel();
    final query = _searchController.text;
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) context.read<AnimalTransferCubit>().search(query);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_search)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _backToSearch() {
    context.read<AnimalTransferCubit>().backToSearch();
    _scrollToTop();
  }

  void _backToConfirmation() {
    context.read<AnimalTransferCubit>().backToConfirmation();
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _cancel() async {
    if (_isCancelling) return;
    _isCancelling = true;
    final confirmed = await showProcessCancellationDialog(context);
    if (!mounted) return;
    _isCancelling = false;
    if (!confirmed) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _finish() {
    if (_isFinishing) return;
    _isFinishing = true;
    Navigator.of(context).pushNamedAndRemoveUntil<void>(
      AppRoutes.home,
      (_) => false,
      arguments: const {homeInitialSectionArgument: homeMyAnimalsSection},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnimalTransferCubit, AnimalTransferState>(
      builder: (context, state) {
        final confirming = state.step == AnimalTransferStep.confirmUser;
        final verifying = state.step == AnimalTransferStep.verifyContact;
        final completed = state.step == AnimalTransferStep.completed;
        final cubit = context.read<AnimalTransferCubit>();
        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (completed) return;
            if (verifying) {
              _backToConfirmation();
            } else if (confirming) {
              _backToSearch();
            } else {
              _cancel();
            }
          },
          child: completed
              ? AnimalTransferSuccessScreen(
                  recipientName: state.selectedRecipient!.name,
                  onFinish: _finish,
                )
              : verifying
              ? AnimalTransferVerificationScreen(
                  challenge: state.challenge!,
                  onBack: _backToConfirmation,
                  onVerify: cubit.verifyAndCreate,
                  onResend: cubit.resendCode,
                  isLoading: state.isLoading,
                  error: state.error,
                  canRetryCreation: state.canRetryCreation,
                  onRetryCreation: cubit.retryCreation,
                  onRenewAuthorization: cubit.renewAuthorization,
                  authorizationExpiresAt: state.authorizationExpiresAt,
                  canRenewAuthorization: cubit.canRenewAuthorization,
                  canBack: !cubit.hasPendingIntent,
                  onInspectRequests: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AnimalTransferRequestsScreen(
                        repository: cubit.repository,
                        initialDirection: 'OUTGOING',
                      ),
                    ),
                  ),
                )
              : ModalPageLayout(
                  title: 'Transferencia de animal(es)',
                  titlePadding: EdgeInsets.only(
                    top: confirming ? 80 : 88,
                    bottom: 6,
                  ),
                  fixedTitle: true,
                  fixedHeaderHeight: confirming ? 152 : 176,
                  fixedHeaderChild: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Text.rich(
                      TextSpan(
                        text: confirming
                            ? 'Confirmar usuario'
                            : 'Buscar usuario',
                        style: AppTypography.body4.copyWith(
                          color: AppColors.greyTextos,
                        ),
                        children: [
                          TextSpan(
                            text: confirming ? ' - 2 de 2' : ' - 1 de 2',
                            style: AppTypography.body4.copyWith(
                              color: AppColors.greyBordes,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottomSafeAreaColor: AppColors.white,
                  scrollController: _scrollController,
                  onClose: _cancel,
                  headerChildren: [
                    if (confirming)
                      Positioned(
                        top: 18,
                        left: 16,
                        child: IconButton(
                          key: const Key('transfer-back'),
                          tooltip: 'Volver a buscar usuario',
                          onPressed: _backToSearch,
                          icon: const Icon(Icons.arrow_back, size: 20),
                          color: AppColors.greyMedio,
                        ),
                      ),
                  ],
                  bottomChild: confirming
                      ? CustomButton(
                          key: const Key('transfer-confirm'),
                          text: 'Transferir',
                          isLoading: state.isLoading,
                          onPressed: state.canTransfer
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  cubit.startVerification();
                                  _scrollToTop();
                                }
                              : null,
                        )
                      : state.results.isEmpty
                      ? const SizedBox.shrink()
                      : CustomButton(
                          key: const Key('transfer-select-recipient'),
                          text: 'Seleccionar',
                          onPressed: state.canContinue
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  cubit.confirmRecipient();
                                  _scrollToTop();
                                }
                              : null,
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!confirming) ...[
                          Text(
                            'Enviarás una solicitud de transferencia. Mientras '
                            'esté pendiente, sigues siendo el propietario y '
                            'puedes consultar sus datos.',
                            style: AppTypography.body4.copyWith(height: 1.6),
                          ),
                          const SizedBox(height: AppSpacing.l),
                        ],
                        TransferAnimalsSummary(
                          animals: state.animals,
                          expanded: _animalsExpanded,
                          onToggle: () => setState(
                            () => _animalsExpanded = !_animalsExpanded,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.l),
                        if (confirming) ...[
                          TransferRecipientConfirmationForm(
                            state: state,
                            onIdentificationChanged:
                                cubit.updateIdentificationNumber,
                            onReasonChanged: cubit.selectTransferReason,
                            onOtherReasonChanged: cubit.updateOtherReasonDetail,
                          ),
                          if (state.error != null)
                            Text(
                              state.error!,
                              style: AppTypography.body4.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                        ] else ...[
                          Text(
                            'Utiliza la barra de búsqueda para encontrar el '
                            'usuario al que se le realizará la transferencia.',
                            style: AppTypography.body4.copyWith(height: 1.6),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          AnimalRecordSearchField(
                            controller: _searchController,
                            fieldKey: const Key('transfer-recipient-search'),
                            maxLength: 20,
                            onClear: state.query.isEmpty
                                ? null
                                : _searchController.clear,
                          ),
                          const SizedBox(height: AppSpacing.l),
                          const Divider(
                            height: 1,
                            color: AppColors.greyDelineante,
                          ),
                          const SizedBox(height: AppSpacing.l),
                          Text('Resultados', style: AppTypography.body3),
                          const SizedBox(height: AppSpacing.l),
                          if (state.isLoading)
                            const Center(child: CircularProgressIndicator()),
                          if (!state.isLoading &&
                              state.query.trim().length >= 2 &&
                              state.results.isEmpty)
                            Text(
                              'No se han encontrado resultados',
                              style: AppTypography.body4.copyWith(
                                color: AppColors.greyMedio,
                              ),
                            ),
                          for (final recipient in state.results)
                            _RecipientTile(
                              recipient: recipient,
                              selected: state.selectedRecipient == recipient,
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                cubit.selectRecipient(recipient);
                              },
                            ),
                          if (state.nextRecipientCursor != null)
                            TextButton(
                              onPressed: state.isLoading
                                  ? null
                                  : cubit.loadMoreRecipients,
                              child: const Text('Cargar más usuarios'),
                            ),
                          if (state.results.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.l),
                            const Divider(
                              height: 1,
                              color: AppColors.greyDelineante,
                            ),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.l),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _RecipientTile extends StatelessWidget {
  final AnimalTransferRecipient recipient;
  final bool selected;
  final VoidCallback? onTap;

  const _RecipientTile({
    required this.recipient,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: Material(
        color: selected ? AppColors.bgBlancoAntiFlash : AppColors.white,
        child: InkWell(
          key: ValueKey('transfer-recipient-${recipient.id}'),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 63),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                AppUserAvatar(
                  name: recipient.name,
                  imageUrl: recipient.imageUrl,
                  size: 32,
                  borderRadius: 4,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body3,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        recipient.maskedIdentification,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body6.copyWith(
                          color: AppColors.greyBordes,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
