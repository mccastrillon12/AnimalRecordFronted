import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/injection_container.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/services/animal_transfer_availability.dart';
import 'package:animal_record/features/home/domain/services/historical_file_save_service.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_requests_cubit.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_notifications_screen.dart';
import 'package:animal_record/features/home/presentation/pages/animal_transfer_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnimalTransferRequestsScreen extends StatelessWidget {
  final AnimalTransferRepository repository;
  final String initialDirection;

  const AnimalTransferRequestsScreen({
    super.key,
    required this.repository,
    this.initialDirection = 'INCOMING',
  }) : assert(initialDirection == 'INCOMING' || initialDirection == 'OUTGOING');

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        TransferRequestsCubit(repository)..load(direction: initialDirection),
    child: const _RequestsBody(),
  );
}

class _RequestsBody extends StatelessWidget {
  const _RequestsBody();

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
                                transferId: request.id,
                                incoming: state.direction == 'INCOMING',
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

  const AnimalTransferDetailScreen({
    super.key,
    required this.repository,
    required this.transferId,
    required this.incoming,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TransferDetailCubit(repository, transferId)..refresh(),
    child: _DetailBody(incoming: incoming),
  );
}

class _DetailBody extends StatelessWidget {
  final bool incoming;
  const _DetailBody({required this.incoming});

  Future<void> _confirm(BuildContext context, List<String> ids) async {
    final rejectAll = ids.isEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(rejectAll ? 'Rechazar todos' : 'Aceptar selección'),
        content: Text(
          rejectAll
              ? 'Se rechazarán todos los animales de la solicitud, incluso los de otras páginas.'
              : 'Se aceptarán ${ids.length} animal(es). Los demás se rechazarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TransferDetailCubit>().decide(ids);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                      ? state.acceptedAnimalIds.contains(item.animalId)
                      : item.status == 'ACCEPTED',
                  onChanged:
                      incoming &&
                          AnimalTransferAvailability.acceptance &&
                          request.status == 'PENDING' &&
                          item.status == 'PENDING' &&
                          !state.loading &&
                          !state.canRetryDecision
                      ? (_) => cubit.toggleAnimal(item.animalId)
                      : null,
                ),
              if (state.cursor != null)
                TextButton(
                  onPressed: state.loading ? null : cubit.loadMore,
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
              if (incoming &&
                  AnimalTransferAvailability.acceptance &&
                  request.status == 'PENDING' &&
                  !state.canRetryDecision) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: state.loading
                      ? null
                      : () => _confirm(context, const []),
                  child: const Text('Rechazar todos'),
                ),
                if (AnimalTransferAvailability.acceptance &&
                    state.acceptedAnimalIds.isNotEmpty)
                  ElevatedButton(
                    onPressed: state.loading
                        ? null
                        : () => _confirm(
                            context,
                            state.acceptedAnimalIds.toList(growable: false),
                          ),
                    child: const Text('Aceptar seleccionados'),
                  ),
              ],
              if (state.canRetryDecision)
                ElevatedButton(
                  onPressed: state.loading ? null : cubit.retryDecision,
                  child: const Text('Reintentar la misma decisión'),
                ),
            ],
          ],
        );
      },
    ),
  );
}

String transferStatusLabel(String status) => switch (status) {
  'PENDING' => 'Pendiente',
  'PROCESSING' => 'Traspaso en curso',
  'ACCEPTED' => 'Aceptado',
  'PARTIALLY_ACCEPTED' => 'Aceptado parcialmente',
  'REJECTED' => 'Rechazado',
  _ => status,
};
