/*
 * Copyright (c) TIKI Inc.
 * MIT license. See LICENSE file in root directory.
 */
/// {@category Node}
/// A L0 Storage Policy Response Model
class PolicyModelRsp {
  DateTime? expires;
  String? keyPrefix;
  List<String>? compute;
  int? maxBytes;
  Map<String, String>? fields;

  PolicyModelRsp(
      {this.expires, this.keyPrefix, this.compute, this.maxBytes, this.fields});

  PolicyModelRsp.fromMap(Map<String, dynamic>? map) {
    if (map != null) {
      keyPrefix = map['keyPrefix'];
      maxBytes = map['maxBytes'];
      if (map['expires'] != null) {
        expires = DateTime.tryParse(map['expires']);
      }
      if (map['compute'] != null) {
        compute = List.from(map['compute']);
      }
      fields = Map.from(map['fields']);
    }
  }

  Map<String, dynamic> toMap() => {
        'expires': expires?.toIso8601String(),
        'keyPrefix': keyPrefix,
        'maxBytes': maxBytes,
        'compute': compute,
        'fields': fields
      };

  /// Overrides toString() method for useful error messages
  @override
  String toString() {
    return 'PolicyModelRsp{expires: $expires, keyPrefix: $keyPrefix, compute: $compute, maxBytes: $maxBytes, fields: $fields}';
  }
}
