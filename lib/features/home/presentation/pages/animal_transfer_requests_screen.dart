import 'package:animal_record/core/constants/app_routes.dart';
import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/core/utils/error_display.dart';
import 'package:animal_record/core/widgets/dropdowns/app_dropdown.dart';
import 'package:animal_record/core/widgets/feedback/app_loading_overlay.dart';
import 'package:animal_record/core/widgets/feedback/confirm_dialog.dart';
import 'package:animal_record/core/widgets/inputs/custom_text_field.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:animal_record/features/auth/presentation/bloc/auth_state.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/services/transfer_comment_policy.dart';
import 'package:animal_record/core/network/transfer_error_diagnostics.dart';
import 'package:animal_record/features/home/domain/services/animal_transfer_availability.dart';
import 'package:animal_record/features/home/domain/services/historical_file_save_service.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_requests_cubit.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_cubit.dart';
import 'package:animal_record/features/home/presentation/navigation/home_section_navigation.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_notifications_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_history_screen.dart';
import 'package:animal_record/features/home/presentation/widgets/transfer_acceptance_view.dart';
import 'package:animal_record/features/home/presentation/utils/transfer_status_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animal_record/features/home/domain/repositories/incoming_transfer_preview_repository.dart';

class AnimalTransferRequestsScreen extends StatelessWidget {
  final AnimalTransferRepository repository;
  final String initialDirection;
  final bool focusPending;
  final IncomingTransferPreviewRepository? previewCache;

  const AnimalTransferRequestsScreen({
    super.key,
    required this.repository,
    this.initialDirection = 'INCOMING',
    this.focusPending = false,
    this.previewCache,
  }) : assert(initialDirection == 'INCOMING' || initialDirection == 'OUTGOING');

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TransferRequestsCubit(repository, previewCache: previewCache)
      ..load(
        direction: initialDirection,
        filter: focusPending ? 'PENDING' : null,
      ),
    child: _RequestsBody(focusPending: focusPending),
  );
}

class _RequestsBody extends StatelessWidget {
  final bool focusPending;

  const _RequestsBody({required this.focusPending});

  @override
  Widget build(BuildContext context) {
    if (!focusPending) return const _RequestsListBody();
    return BlocBuilder<TransferRequestsCubit, TransferRequestsState>(
      builder: (context, state) {
        for (final request in state.requests) {
          if (request.status == 'PENDING') {
            return AnimalTransferDetailScreen(
              key: ValueKey(request.id),
              repository: context.read<TransferRequestsCubit>().repository,
              previewCache: context.read<TransferRequestsCubit>().previewCache,
              transferId: request.id,
              incoming: true,
              acceptanceLayout: true,
            );
          }
        }
        if (state.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const _RequestsListBody();
      },
    );
  }
}

class _RequestsListBody extends StatelessWidget {
  const _RequestsListBody();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Solicitudes de transferencia'),
      actions: [
        IconButton(
          tooltip: 'Avisos',
          icon: const Icon(Icons.notifications),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AnimalTransferNotificationsScreen(
                repository: context.read<TransferRequestsCubit>().repository,
              ),
            ),
          ),
        ),
        if (AnimalTransferAvailability.history)
          IconButton(
            tooltip: 'Histórico',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AnimalTransferHistoryScreen(
                  repository: context.read<TransferRequestsCubit>().repository,
                  fileSaver: sl<HistoricalFileSaveService>(),
                ),
              ),
            ),
          ),
      ],
    ),
    body: BlocBuilder<TransferRequestsCubit, TransferRequestsState>(
      builder: (context, state) {
        final cubit = context.read<TransferRequestsCubit>();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'INCOMING',
                          label: Text('Recibidas'),
                        ),
                        ButtonSegment(
                          value: 'OUTGOING',
                          label: Text('Enviadas'),
                        ),
                      ],
                      selected: {state.direction},
                      onSelectionChanged: (values) => cubit.load(
                        direction: values.first,
                        filter: state.filter,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: state.filter ?? 'ALL',
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Todas')),
                      DropdownMenuItem(
                        value: 'PENDING',
                        child: Text('Pendientes'),
                      ),
                      DropdownMenuItem(
                        value: 'REJECTED',
                        child: Text('Rechazadas'),
                      ),
                    ],
                    onChanged: (value) => cubit.load(
                      direction: state.direction,
                      filter: value == 'ALL' ? null : value,
                    ),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => cubit.load(
                  direction: state.direction,
                  filter: state.filter,
                  forceRefresh: true,
                ),
                child: ListView(
                  children: [
                    if (state.requests.isEmpty && !state.loading)
                      const ListTile(title: Text('No hay solicitudes')),
                    for (final request in state.requests)
                      ListTile(
                        title: Text(
                          state.direction == 'INCOMING'
                              ? request.senderName
                              : request.recipientName,
                        ),
                        subtitle: Text(
                          '${request.animalCount} animal(es) · '
                          '${transferStatusLabel(request.status)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AnimalTransferDetailScreen(
                                repository: cubit.repository,
                                previewCache: state.direction == 'INCOMING'
                                    ? cubit.previewCache
                                    : null,
                                transferId: request.id,
                                incoming: state.direction == 'INCOMING',
                                acceptanceLayout: state.direction == 'INCOMING',
                              ),
                            ),
                          );
                          if (context.mounted) {
                            cubit.load(
                              direction: state.direction,
                              filter: state.filter,
                            );
                          }
                        },
                      ),
                    if (state.cursor != null)
                      Center(
                        child: TextButton(
                          onPressed: state.loading ? null : cubit.loadMore,
                          child: const Text('Cargar más'),
                        ),
                      ),
                    if (state.loading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class AnimalTransferDetailScreen extends StatelessWidget {
  final AnimalTransferRepository repository;
  final String transferId;
  final bool incoming;
  final bool acceptanceLayout;
  final IncomingTransferPreviewRepository? previewCache;

  const AnimalTransferDetailScreen({
    super.key,
    required this.repository,
    required this.transferId,
    required this.incoming,
    this.acceptanceLayout = false,
    this.previewCache,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TransferDetailCubit(
      repository,
      transferId,
      previewCache: incoming ? previewCache : null,
    )..initialize(),
    child: _DetailBody(incoming: incoming, acceptanceLayout: acceptanceLayout),
  );
}

class _DetailBody extends StatefulWidget {
  final bool incoming;
  final bool acceptanceLayout;
  const _DetailBody({required this.incoming, required this.acceptanceLayout});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  final _loadingOverlay = AppLoadingOverlay(
    barrierColor: AppColors.overlayBlack,
  );
  TransferDetailState? _decisionBackground;
  bool? _singleAnimalDecision;
  String? _rejectionSender;
  bool _isFinishingDecision = false;

  bool get incoming => widget.incoming;
  bool get acceptanceLayout => widget.acceptanceLayout;

  bool _isLoading(TransferDetailState state) =>
      state.loading ||
      state.submittingDecision ||
      _decisionBackground != null ||
      (_singleAnimalDecision != null && state.request?.status == 'PROCESSING');

  void _syncLoadingOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isFinishingDecision) return;
      if (_isLoading(context.read<TransferDetailCubit>().state)) {
        _loadingOverlay.show(context);
      } else {
        _loadingOverlay.hide();
      }
    });
  }

  void _showDecisionLoading(BuildContext context) {
    if (_decisionBackground == null) {
      final background = context.read<TransferDetailCubit>().state;
      setState(() => _decisionBackground = background);
    }
    _loadingOverlay.show(context);
  }

  void _restoreDecisionView() {
    _loadingOverlay.hide();
    if (_decisionBackground != null) {
      setState(() => _decisionBackground = null);
    }
  }

  @override
  void dispose() {
    _loadingOverlay.hide();
    super.dispose();
  }

  Future<void> _handleDecisionState(
    BuildContext context,
    TransferDetailState state,
  ) async {
    if (state.submittingDecision) {
      _singleAnimalDecision = state.hasSingleAnimal;
      _loadingOverlay.show(context);
      return;
    }
    final singleAnimal = _singleAnimalDecision;
    if (singleAnimal == null) {
      if (state.error != null && _decisionBackground != null) {
        _restoreDecisionView();
        ErrorDisplay.showError(context, state.error!);
      }
      return;
    }
    final status = state.request?.status;
    final error = state.error;
    if (status == 'PROCESSING' && error == null) {
      _loadingOverlay.show(context);
      return;
    }
    if (error != null) {
      _restoreDecisionView();
      if (!state.canRetryDecision && status != 'PROCESSING') {
        _singleAnimalDecision = null;
        _rejectionSender = null;
      }
      ErrorDisplay.showError(context, error);
      return;
    }
    final sender = _rejectionSender ?? state.request?.senderName.trim();
    final received = status == 'ACCEPTED' || status == 'PARTIALLY_ACCEPTED';
    final rejected = status == 'REJECTED' || status == 'PARTIALLY_ACCEPTED';
    if (rejected || received) {
      _singleAnimalDecision = null;
      _rejectionSender = null;
      if (received) {
        final animals = context.read<AnimalCubit?>();
        final authState = context.read<AuthBloc?>()?.state;
        final ownerId = authState is AuthSuccess
            ? authState.user.id
            : animals?.currentOwnerId;
        if (animals != null && ownerId != null) {
          _loadingOverlay.show(context);
          await animals.loadAnimals(ownerId, forceRefresh: true);
          if (!context.mounted) return;
        }
      }
      _isFinishingDecision = true;
      _loadingOverlay.hide();
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.pushNamedAndRemoveUntil<void>(
        AppRoutes.home,
        (_) => false,
        arguments: received
            ? const {homeInitialSectionArgument: homeMyAnimalsSection}
            : null,
      );
      final messages = [
        if (rejected)
          'Los animales han sido rechazados. '
              '${sender?.isNotEmpty == true ? 'El usuario $sender' : 'El remitente'} '
              'será notificado.',
        if (received)
          singleAnimal
              ? 'Los animales han sido recibidos exitosamente. Visualícelos en la '
                    'sección “Mis animales”'
              : 'Los animales seleccionados han sido recibidos exitosamente. '
                    'Visualícelos en la sección “Mis animales”',
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overlay = navigator.overlay;
        if (overlay != null && overlay.mounted) {
          ErrorDisplay.showSuccessesOnOverlay(overlay, messages);
        }
      });
    } else {
      _restoreDecisionView();
      if (status != null && status != 'PENDING') {
        _singleAnimalDecision = null;
        _rejectionSender = null;
      }
    }
  }

  Future<void> _confirmRejection(
    BuildContext context,
    List<String> ids, {
    bool acceptOthers = false,
  }) async {
    final cubit = context.read<TransferDetailCubit>();
    final sender = cubit.state.request?.senderName.trim() ?? '';
    final version = cubit.state.request?.version;
    final List<TransferReason> reasons;
    try {
      reasons = await cubit.loadRejectionReasons();
    } catch (error) {
      TransferErrorDiagnostics.record(error);
      if (context.mounted) {
        ErrorDisplay.showError(
          context,
          'No se pudieron cargar los motivos de rechazo. Intenta nuevamente.',
        );
      }
      return;
    }
    if (!context.mounted) return;
    TransferReason? selectedReason;
    var reasonDetail = '';
    var confirmed = false;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setDialogState) => ConfirmDialog(
          title: '¿Desea rechazar la transferencia?',
          description:
              'Al rechazar la transferencia de los animales no podrá acceder '
              'a su información. Si luego de esta acción se retracta, deberá '
              'comunicarse con el propietario para solicitar una nueva transferencia.'
              '${acceptOthers ? '\n\nLos demás animales se aceptarán.' : ''}',
          showCloseButton: false,
          cancelLabel: 'No',
          confirmLabel: 'Sí',
          isConfirmEnabled:
              selectedReason != null &&
              (!selectedReason!.needsComment ||
                  TransferCommentPolicy.isValid(reasonDetail)),
          onConfirm: () => confirmed = true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<TransferReason>(
                label: 'Seleccione el motivo de rechazo',
                hint: 'Seleccionar',
                value: selectedReason,
                items: reasons,
                itemAsString: (value) => value.name,
                preserveOrder: true,
                showClearOption: false,
                isInline: true,
                onChanged: (value) => setDialogState(() {
                  selectedReason = value;
                  if (value?.needsComment != true) reasonDetail = '';
                }),
              ),
              if (selectedReason?.needsComment == true) ...[
                const SizedBox(height: AppSpacing.m),
                CustomTextField(
                  key: const Key('transfer-rejection-reason-detail'),
                  label: '¿Cuál?',
                  initialValue: reasonDetail,
                  maxLength: TransferCommentPolicy.maxLength,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) =>
                      setDialogState(() => reasonDetail = value),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (confirmed && context.mounted) {
      if (cubit.state.request?.version != version ||
          cubit.state.request?.status != 'PENDING') {
        ErrorDisplay.showError(
          context,
          'La solicitud cambió. Revisa nuevamente los animales.',
        );
        return;
      }
      _rejectionSender = sender;
      if (acceptanceLayout) _showDecisionLoading(context);
      await cubit.decide(
        ids,
        rejectionReason: selectedReason,
        rejectionComment: selectedReason?.needsComment == true
            ? reasonDetail
            : null,
      );
    }
  }

  Future<void> _acceptSelected(BuildContext context) async {
    final cubit = context.read<TransferDetailCubit>();
    final selected = Set<String>.of(cubit.state.selectedAnimalIds);
    if (!await cubit.loadAllAnimals() || !context.mounted) return;
    final pending = cubit.state.items
        .where((item) => item.status == 'PENDING')
        .map((item) => item.animalId)
        .toSet();
    if (selected.isEmpty || !pending.containsAll(selected)) return;
    if (selected.length < pending.length) {
      await _confirmRejection(
        context,
        selected.toList(growable: false),
        acceptOthers: true,
      );
    } else {
      await cubit.decide(selected.toList(growable: false));
    }
  }

  Future<void> _decideMultiple(
    BuildContext context, {
    required bool rejectSelected,
  }) async {
    final cubit = context.read<TransferDetailCubit>();
    if (!rejectSelected) {
      if (_loadingOverlay.isVisible) return;
      _showDecisionLoading(context);
    }
    final loaded = await cubit.loadAllAnimals();
    if (!context.mounted) return;
    final state = cubit.state;
    if (!loaded || state.request?.status != 'PENDING' || state.loading) {
      if (!rejectSelected) _restoreDecisionView();
      return;
    }
    final pendingIds = state.items
        .where((item) => item.status == 'PENDING')
        .map((item) => item.animalId)
        .toSet();
    if (pendingIds.isEmpty) {
      if (!rejectSelected) _restoreDecisionView();
      return;
    }
    if (!rejectSelected) {
      await cubit.decide(pendingIds.toList(growable: false));
      return;
    }
    final rejectedIds = pendingIds.intersection(state.selectedAnimalIds);
    if (rejectedIds.isEmpty) return;
    final acceptedIds = pendingIds
        .difference(rejectedIds)
        .toList(growable: false);
    await _confirmRejection(
      context,
      acceptedIds,
      acceptOthers: acceptedIds.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) => acceptanceLayout
      ? BlocConsumer<TransferDetailCubit, TransferDetailState>(
          listenWhen: (previous, current) =>
              previous.submittingDecision != current.submittingDecision ||
              previous.request?.status != current.request?.status ||
              (current.error != null && previous.error != current.error),
          listener: _handleDecisionState,
          builder: (context, currentState) {
            final cubit = context.read<TransferDetailCubit>();
            final state = _decisionBackground ?? currentState;
            final loading = _isLoading(currentState);
            _syncLoadingOverlay();
            final request = state.request;
            final canRetry = state.canRetryDecision && !loading;
            final retryRejection = _rejectionSender != null;
            void retryDecision() {
              _showDecisionLoading(context);
              cubit.retryDecision();
            }

            final canDecide =
                incoming &&
                request?.status == 'PENDING' &&
                !loading &&
                !state.canRetryDecision;
            final singleAnimalId = state.singlePendingAnimalId;
            final multipleAnimals = !state.hasSingleAnimal;
            final canSelectAnimals = canDecide && multipleAnimals;
            final hasPendingAnimals = state.items.any(
              (item) => item.status == 'PENDING',
            );
            final acceptUnavailableMessage =
                canDecide && !hasPendingAnimals && state.cursor == null
                ? 'No hay animales pendientes para aceptar.'
                : null;
            return PopScope(
              canPop: !loading,
              child: TransferAcceptanceView(
                request: request,
                items: state.items,
                loading: loading,
                error: state.error,
                acceptUnavailableMessage: acceptUnavailableMessage,
                selectedAnimalIds: state.selectedAnimalIds,
                hasMoreAnimals: state.cursor != null,
                onBack: () {
                  if (!loading) {
                    Navigator.of(context).pop();
                  }
                },
                onRefresh: cubit.refresh,
                onImageError: (item, failedUrl) =>
                    cubit.refreshAnimalImage(item.id, failedUrl),
                onLoadMore: loading || state.canRetryDecision
                    ? null
                    : cubit.loadMore,
                onToggleAnimal: canSelectAnimals ? cubit.toggleAnimal : null,
                onToggleAll: canSelectAnimals
                    ? () async {
                        if (await cubit.loadAllAnimals()) {
                          cubit.toggleAllAnimals();
                        }
                      }
                    : null,
                onAccept: canRetry && !retryRejection
                    ? retryDecision
                    : canDecide && (hasPendingAnimals || state.cursor != null)
                    ? () {
                        if (multipleAnimals) {
                          _decideMultiple(context, rejectSelected: false);
                        } else {
                          _showDecisionLoading(context);
                          cubit.decide([singleAnimalId!]);
                        }
                      }
                    : null,
                onReject: canRetry && retryRejection
                    ? retryDecision
                    : canDecide &&
                          (multipleAnimals
                              ? state.selectedAnimalIds.isNotEmpty
                              : singleAnimalId != null)
                    ? () => multipleAnimals
                          ? _decideMultiple(context, rejectSelected: true)
                          : _confirmRejection(context, const [])
                    : null,
              ),
            );
          },
        )
      : Scaffold(
          appBar: AppBar(
            title: const Text('Detalle de solicitud'),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed: context.read<TransferDetailCubit>().refresh,
              ),
            ],
          ),
          body: BlocBuilder<TransferDetailCubit, TransferDetailState>(
            builder: (context, state) {
              final cubit = context.read<TransferDetailCubit>();
              final request = state.request;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.loading) const LinearProgressIndicator(),
                  if (state.error != null)
                    Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  if (request != null) ...[
                    Text(
                      'Estado: ${transferStatusLabel(request.status)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (request.decidedAt != null)
                      Text('Decisión: ${request.decidedAt!.toLocal()}'),
                    const SizedBox(height: 16),
                    for (final item in state.items)
                      CheckboxListTile(
                        title: Text(item.animalName),
                        subtitle: Text(
                          '${item.animalCode} · '
                          '${transferStatusLabel(item.status)}',
                        ),
                        value: request.status == 'PENDING'
                            ? state.selectedAnimalIds.contains(item.animalId)
                            : item.status == 'ACCEPTED',
                        onChanged:
                            incoming &&
                                request.status == 'PENDING' &&
                                item.status == 'PENDING' &&
                                !state.loading &&
                                !state.canRetryDecision
                            ? (_) => cubit.toggleAnimal(item.animalId)
                            : null,
                      ),
                    if (state.cursor != null)
                      TextButton(
                        onPressed: state.loading || state.canRetryDecision
                            ? null
                            : cubit.loadMore,
                        child: const Text('Cargar más animales'),
                      ),
                    if (request.status == 'PROCESSING')
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Traspaso en curso. Actualiza para confirmar el '
                          'resultado de cada animal.',
                        ),
                      ),
                    if (incoming && request.status == 'PENDING') ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: state.loading
                            ? null
                            : state.canRetryDecision
                            ? (_rejectionSender != null
                                  ? cubit.retryDecision
                                  : null)
                            : () => _confirmRejection(context, const []),
                        child: const Text('Rechazar todos'),
                      ),
                      ElevatedButton(
                        onPressed: state.loading
                            ? null
                            : state.canRetryDecision
                            ? (_rejectionSender == null
                                  ? cubit.retryDecision
                                  : null)
                            : state.selectedAnimalIds.isEmpty
                            ? null
                            : () => _acceptSelected(context),
                        child: const Text('Aceptar seleccionados'),
                      ),
                    ],
                  ],
                ],
              );
            },
          ),
        );
}
