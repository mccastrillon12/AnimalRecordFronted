import 'dart:convert';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/features/home/domain/entities/animal_transfer_data.dart';
import 'package:animal_record/features/home/domain/repositories/animal_transfer_repository.dart';
import 'package:animal_record/features/home/domain/services/historical_file_save_service.dart';
import 'package:animal_record/features/home/presentation/cubit/animal_transfer_history_cubit.dart';
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
    child: _HistoryBody(fileSaver: fileSaver),
  );
}

class _HistoryBody extends StatelessWidget {
  final HistoricalFileSaveService fileSaver;
  const _HistoryBody({required this.fileSaver});

  Future<void> _download(
    BuildContext context,
    HistoricalEntry entry,
    HistoricalFile file,
  ) async {
    final cubit = context.read<TransferHistoryCubit>();
    try {
      final bytes = await cubit.download(entry, file);
      final suggestedName = entry.data['fileName'] is String
          ? entry.data['fileName'] as String
          : '${file.fileId}.bin';
      final saved = await fileSaver.save(bytes, suggestedName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saved ? 'Archivo guardado' : 'Descarga cancelada'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo descargar el archivo completo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TransferHistoryCubit, TransferHistoryState>(
        builder: (context, state) {
          final cubit = context.read<TransferHistoryCubit>();
          final period = state.selectedPeriod;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Histórico de propiedad'),
              leading: period == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Volver a períodos',
                      onPressed: cubit.closePeriod,
                    ),
            ),
            body: RefreshIndicator(
              onRefresh: period == null
                  ? cubit.loadPeriods
                  : () => cubit.openPeriod(period),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Solo lectura'),
                  if (state.loading) const LinearProgressIndicator(),
                  if (state.error != null)
                    Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  if (period == null) ...[
                    if (state.periods.isEmpty && !state.loading)
                      const ListTile(title: Text('No hay períodos publicados')),
                    for (final item in state.periods)
                      ListTile(
                        title: Text('Animal ${item.animalId}'),
                        subtitle: Text('Finalizó: ${item.endedAt.toLocal()}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => cubit.openPeriod(item),
                      ),
                    if (state.periodsCursor != null)
                      TextButton(
                        onPressed: state.loading ? null : cubit.loadMorePeriods,
                        child: const Text('Cargar más períodos'),
                      ),
                  ] else ...[
                    Text(
                      'Animal ${period.animalId}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    for (final entry in state.entries)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.kind,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                const JsonEncoder.withIndent(
                                  '  ',
                                ).convert(entry.data),
                              ),
                              for (final file in entry.media)
                                TextButton.icon(
                                  onPressed: () =>
                                      _download(context, entry, file),
                                  icon: const Icon(Icons.download),
                                  label: Text(file.path ?? 'Descargar archivo'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (state.entriesCursor != null)
                      TextButton(
                        onPressed: state.loading ? null : cubit.loadMoreEntries,
                        child: const Text('Cargar más entradas'),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      );
}
