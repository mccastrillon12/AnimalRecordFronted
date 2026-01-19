import 'dart:async';
import 'dart:io';

import 'package:animal_record/core/theme/app_colors.dart';
import 'package:animal_record/core/theme/app_spacing.dart';
import 'package:animal_record/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.animalRecord.animal_record/share');
  List<String> _savedFilePaths = [];

  @override
  void initState() {
    super.initState();
    _loadSavedFiles();
    _checkForSharedFiles();
    _setupMethodChannelListener();
  }

  Future<void> _loadSavedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedFilePaths = prefs.getStringList('saved_shared_files') ?? [];
    });
  }

  Future<void> _checkForSharedFiles() async {
    try {
      final List<dynamic>? sharedFiles = await platform.invokeMethod(
        'getSharedFiles',
      );

      if (sharedFiles != null && sharedFiles.isNotEmpty) {
        for (var filePath in sharedFiles) {
          if (filePath is String) {
            await _saveSharedFile(filePath);
          }
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Error getting shared files: ${e.message}");
    }
  }

  void _setupMethodChannelListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onSharedFiles') {
        _checkForSharedFiles();
      }
    });
  }

  Future<void> _saveSharedFile(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sourceFile = File(sourcePath);
      final fileName = sourcePath.split('/').last;
      final String newPath = '${directory.path}/$fileName';

      await sourceFile.copy(newPath);

      final prefs = await SharedPreferences.getInstance();
      final List<String> currentFiles =
          prefs.getStringList('saved_shared_files') ?? [];

      if (!currentFiles.contains(newPath)) {
        currentFiles.add(newPath);
        await prefs.setStringList('saved_shared_files', currentFiles);

        setState(() {
          _savedFilePaths = currentFiles;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo guardado exitosamente')),
          );
        }
      }

      try {
        await sourceFile.delete();
      } catch (e) {
        debugPrint("Could not delete temp file: $e");
      }
    } catch (e) {
      debugPrint("Error saving file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildActionGrid(),
              const SizedBox(height: AppSpacing.s),
              _buildSectionIndicator(),
              const SizedBox(height: AppSpacing.m),
              _buildMyAnimalsSection(),
              if (_savedFilePaths.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.l),
                _buildSharedFilesSection(),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.secondaryCoral,
        child: const Icon(Icons.more_horiz, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      color: AppColors.primaryDark,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hola,',
                      style: AppTypography.body3.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      ' Jonh Doe',
                      style: AppTypography.body3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Propietario',
                  style: AppTypography.body6.copyWith(
                    color: AppColors.primaryFrances,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.notifications, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = [
      {'icon': Icons.map, 'label': 'Mapa'},
      {'icon': Icons.add_box, 'label': '+ Animal'},
      {'icon': Icons.calendar_today, 'label': 'Agenda'},
      {
        'icon': Icons.pets,
        'label': 'Mis animales',
        'color': AppColors.primaryFrances,
      },
      {'icon': Icons.home, 'label': 'Inicio'},
      {'icon': Icons.medical_services, 'label': 'Carné vacunas'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          final isSelected = action['label'] == 'Mis animales';
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action['icon'] as IconData,
                color: isSelected
                    ? (action['color'] as Color?)
                    : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                action['label'] as String,
                style: AppTypography.body6.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionIndicator() {
    return const Icon(
      Icons.keyboard_arrow_up,
      color: AppColors.greyMedio,
      size: 20,
    );
  }

  Widget _buildMyAnimalsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis animales', style: AppTypography.heading2),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildFilterButton(Icons.grid_view),
              const SizedBox(width: 8),
              _buildFilterButton(Icons.tune),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'No tienes ningún animal registrado todavía.',
              style: AppTypography.body4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedFilesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text('Archivos Compartidos', style: AppTypography.heading2),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _savedFilePaths.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final path = _savedFilePaths[index];
              final fileName = path.split('/').last;
              final isImage =
                  fileName.toLowerCase().endsWith('.jpg') ||
                  fileName.toLowerCase().endsWith('.png') ||
                  fileName.toLowerCase().endsWith('.jpeg');

              return Card(
                elevation: 1,
                child: ListTile(
                  leading: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                          size: 50,
                        ),
                  title: Text(
                    fileName,
                    style: AppTypography.body3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Guardado en dispositivo',
                    style: AppTypography.body6.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.greyMedio, size: 20),
    );
  }
}
