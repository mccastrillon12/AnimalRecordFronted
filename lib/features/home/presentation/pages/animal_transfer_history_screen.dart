import 'package:animal_record/features/home/domain/entities/animal_ownership.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/services/historical_file_save_service.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_history_cubit.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:animal_record/features/home/presentation/pages/animal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnimalTransferHistoryScreen extends StatelessWidget {
  final AnimalTransferRepository repository;
  final HistoricalFileSaveService fileSaver;
  const AnimalTransferHistoryScreen({
    super.key,
    required this.repository,
    required this.fileSaver,
  });
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TransferHistoryCubit(repository)..loadPeriods(),
    child: const _HistoryBody(),
  );
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TransferHistoryCubit, TransferHistoryState>(
        builder: (context, state) {
          final cubit = context.read<TransferHistoryCubit>();
          return Scaffold(
            appBar: AppBar(title: const Text('Histórico de propiedad')),
            body: RefreshIndicator(
              onRefresh: cubit.loadPeriods,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.loading) const LinearProgressIndicator(),
                  if (state.error != null) Text(state.error!),
                  if (state.periods.isEmpty && !state.loading)
                    const ListTile(title: Text('No hay períodos publicados')),
                  for (final period in state.periods)
                    ListTile(
                      title: Text('Animal ${period.animalId}'),
                      subtitle: Text('Finalizó: ${period.endedAt.toLocal()}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnimalDetailScreen(
                            animal: AnimalModel(
                              id: period.animalId,
                              name: 'Animal',
                              code: '',
                              family: '',
                              transferStatus: 'TRANSFERRED',
                              readOnly: true,
                              ownershipHistory: AnimalOwnershipHistory(
                                periodId: period.periodId,
                                publicationHash: period.publicationHash,
                                transferredAt: period.endedAt,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (state.periodsCursor != null)
                    TextButton(
                      onPressed: state.loading ? null : cubit.loadMorePeriods,
                      child: const Text('Cargar más períodos'),
                    ),
                ],
              ),
            ),
          );
        },
      );
}
