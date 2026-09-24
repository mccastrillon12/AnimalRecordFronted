import 'package:animal_record/core/injection_container.dart' as di;
import 'package:animal_record/features/medical_documents/domain/entities/medical_document_entity.dart';
import 'package:animal_record/features/medical_documents/domain/entities/medical_field_catalog.dart';
import 'package:animal_record/features/medical_documents/domain/usecases/medical_document_usecases.dart';
import 'package:flutter/material.dart';

class MedicalFieldCatalogBuilder extends StatefulWidget {
  final MedicalDocumentCategory category;
  final Widget Function(BuildContext context, MedicalFieldCatalog catalog)
  builder;

  const MedicalFieldCatalogBuilder({
    super.key,
    required this.category,
    required this.builder,
  });

  @override
  State<MedicalFieldCatalogBuilder> createState() =>
      _MedicalFieldCatalogBuilderState();
}

class _MedicalFieldCatalogBuilderState
    extends State<MedicalFieldCatalogBuilder> {
  late Future<MedicalFieldCatalog> _catalog;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MedicalFieldCatalogBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) _load();
  }

  void _load() {
    _catalog = di.sl<GetMedicalFieldCatalogUseCase>()(
      category: widget.category,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MedicalFieldCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final catalog = snapshot.data;
        if (catalog != null) return widget.builder(context, catalog);
        return Center(
          child: TextButton(
            onPressed: () => setState(_load),
            child: const Text('Reintentar'),
          ),
        );
      },
    );
  }
}
