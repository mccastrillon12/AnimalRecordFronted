import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/home/domain/usecases/animal_history_usecases.dart';
import 'package:animal_record/features/home/presentation/models/animal_model.dart';
import 'package:flutter/material.dart';

/// Loads the publication and hands its data to the existing animal screens.
class HistoricalAnimalLoader extends StatefulWidget {
  final AnimalModel animal;
  final Widget Function(AnimalModel) builder;
  const HistoricalAnimalLoader({
    super.key,
    required this.animal,
    required this.builder,
  });
  @override
  State<HistoricalAnimalLoader> createState() => _HistoricalAnimalLoaderState();
}

class _HistoricalAnimalLoaderState extends State<HistoricalAnimalLoader> {
  late Future<AnimalModel> _future;
  AnimalModel? _cached;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(HistoricalAnimalLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animal.id != widget.animal.id ||
        oldWidget.animal.ownershipHistory != widget.animal.ownershipHistory) {
      _initialize();
    }
  }

  void _initialize() {
    final cached = di.sl<LoadHistoricalAnimalUseCase>().cached(
      widget.animal.toEntity(),
    );
    _cached = cached == null ? null : AnimalModel.fromEntity(cached);
    _future = _cached == null ? _load() : Future.value(_cached!);
  }

  Future<AnimalModel> _load() async => AnimalModel.fromEntity(
    await di.sl<LoadHistoricalAnimalUseCase>()(widget.animal.toEntity()),
  );

  @override
  Widget build(BuildContext context) {
    if (_cached case final animal?) return widget.builder(animal);
    return FutureBuilder<AnimalModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.data case final animal?) {
          _cached = animal;
          return widget.builder(animal);
        }
        return Scaffold(
          appBar: AppBar(title: Text(widget.animal.name)),
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No se pudo cargar la información del animal.',
                      ),
                      TextButton(
                        onPressed: () => setState(() => _future = _load()),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
