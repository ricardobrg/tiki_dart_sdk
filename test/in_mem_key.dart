/*
 * Copyright (c) TIKI Inc.
 * MIT license. See LICENSE file in root directory.
 */

import 'package:tiki_sdk_dart/node/node_service.dart';

/// {@category Utils}

/// A ephemeral key-value storage.
class InMemoryKey extends KeyStorage {
  Map<String, String> storage = {};

  @override
  Future<String?> read({required String key}) async => storage[key];

  @override
  Future<void> write({required String key, required String value}) async =>
      storage[key] = value;
}
