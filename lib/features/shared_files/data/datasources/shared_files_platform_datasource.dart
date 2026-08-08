import 'dart:async';

import 'package:flutter/services.dart';

abstract interface class SharedFilesPlatformDataSource {
  Future<List<Map<Object?, Object?>>> getInitialFiles();

  Stream<List<Map<Object?, Object?>>> observeIncomingFiles();
}

class SharedFilesPlatformDataSourceImpl
    implements SharedFilesPlatformDataSource {
  static const channelName = 'com.animalrecord/shared_files';

  final MethodChannel channel;
  final StreamController<List<Map<Object?, Object?>>> _controller;

  SharedFilesPlatformDataSourceImpl({MethodChannel? channel})
    : channel = channel ?? const MethodChannel(channelName),
      _controller = StreamController.broadcast() {
    this.channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'sharedFilesReceived') return;
    _controller.add(_parseFiles(call.arguments));
  }

  @override
  Future<List<Map<Object?, Object?>>> getInitialFiles() async {
    final result = await channel.invokeMethod<Object?>('getInitialSharedFiles');
    return _parseFiles(result);
  }

  @override
  Stream<List<Map<Object?, Object?>>> observeIncomingFiles() {
    return _controller.stream;
  }

  List<Map<Object?, Object?>> _parseFiles(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<Object?, Object?>>()
        .where((file) => file['path']?.toString().isNotEmpty == true)
        .toList(growable: false);
  }
}
