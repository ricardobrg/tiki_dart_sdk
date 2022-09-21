/*
 * Copyright (c) TIKI Inc.
 * MIT license. See LICENSE file in root directory.
 */
/// {@category Node}
import 'dart:typed_data';

import 'package:pointycastle/api.dart';

import '../../utils/utils.dart';
import 'block_repository.dart';

//TODO this can be treated as just the block header. remove txn count entirely.
/// The block model entity for local storage.
///
/// This model is used only for local operations. For blockchain operations the
/// serialized version of it is used.
class BlockModel {
  /// The unique identifier of this block.
  ///
  /// It is the SHA3-256 hash of the [header].
  Uint8List? id;

  /// The version number indicating the set of block validation rules to follow.
  late int version;

  /// The previous [BlockModel.id].
  ///
  /// It is SHA-3 hash of the previous block’s [header]. If this is the genesis
  /// block, the value is Uint8List(1);
  late Uint8List previousHash;

  /// The [MerkelTree.root] of the [TransactionModel] hashes taht are part of this.
  late Uint8List transactionRoot;

  /// The total number of [TransactionModel] that are part of this.
  late int transactionCount;

  /// The block creation timestamp.
  late final DateTime timestamp;

  /// Buils a new [BlockModel].
  ///
  /// If no [timestamp] is provided, it is considered a new [BlockModel] and
  /// the object creation time becomes the [timestamp].
  BlockModel({
    this.version = 1,
    required this.previousHash,
    required this.transactionRoot,
    required this.transactionCount,
    timestamp,
  }) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  /// Builds a [BlockModel] from a [map].
  ///
  /// It is used mainly for retrieving data from [BlockRepository].
  /// The map strucure is
  /// ```
  ///   Map<String, dynamic> map = {
  ///     BlockRepository.columnId : Uint8List
  ///     BlockRepository.columnVersion : int
  ///     BlockRepository.columnPreviousHash : Uint8List
  ///     BlockRepository.columnTransactionRoot : Uint8List
  ///     BlockRepository.columnTransactionCount : int
  ///    }
  /// ```
  BlockModel.fromMap(Map<String, dynamic> map)
      : id = map[BlockRepository.columnId],
        version = map[BlockRepository.columnVersion],
        previousHash = map[BlockRepository.columnPreviousHash],
        transactionRoot = map[BlockRepository.columnTransactionRoot],
        transactionCount = map[BlockRepository.columnTransactionCount],
        timestamp = DateTime.fromMillisecondsSinceEpoch(
            map[BlockRepository.columnTimestamp] * 1000);

  //TODO this is weird, as it only deserializes part of the object.
  /// Builds a [BlockModel] from a [serialized] list of bytes.
  ///
  /// Check [serialize] for more information on how the [serialized] is built.
  BlockModel.deserialize(Uint8List serialized) {
    List<Uint8List> extractedBlockBytes = UtilsCompactSize.decode(serialized);
    version = UtilsBytes.decodeBigInt(extractedBlockBytes[0]).toInt();
    timestamp = DateTime.fromMillisecondsSinceEpoch(
        UtilsBytes.decodeBigInt(extractedBlockBytes[1]).toInt() * 1000);
    previousHash = extractedBlockBytes[2];
    transactionRoot = extractedBlockBytes[3];
    transactionCount = UtilsBytes.decodeBigInt(extractedBlockBytes[4]).toInt();
    if (extractedBlockBytes.sublist(5).length != transactionCount) {
      throw Exception(
          'Invalid transaction count. Expected $transactionCount. Got ${extractedBlockBytes.sublist(5).length}');
    }
    id = Digest("SHA3-256").process(header());
  }

  //TODO this doesn't belong in the model if you have to pass in the body to do it.
  /// Creates a [Uint8List] representation of the block.
  ///
  /// The serialized [BlockModel] is created by combining in a [Uint8List] the
  /// [BlockModel.header] and the block [body], that is built from the
  /// [TransactionModel] list by [TransactionService.serializeTransactions].
  Uint8List serialize(Uint8List body) {
    Uint8List head = header();
    return (BytesBuilder()
          ..add(head)
          ..add(body))
        .toBytes();
  }

  //TODO the header doesn't normally have the txn count. the txn count is in the body.
  /// Creates the [Uint8List] representation of the block header.
  ///
  /// The block header is represented by a [Uint8List] of the block properties.
  /// Each item is prepended by its size calculate with [UtilsCompactSize.toSize].
  /// The Uint8List structure is:
  /// ```
  /// Uint8List<Uint8List> header = Uin8List.fromList([
  ///   ...UtilsCompactSize.toSize(version),
  ///   ...version,
  ///   ...UtilsCompactSize.toSize(timestamp),
  ///   ...timestamp,
  ///   ...UtilsCompactSize.toSize(previousHash),
  ///   ...previousHash,
  ///   ...UtilsCompactSize.toSize(transactionRoot),
  ///   ...transactionRoot,
  ///   ...UtilsCompactSize.toSize(transactionCount),
  ///   ...transactionCount,
  /// ]);
  /// ```
  Uint8List header() {
    Uint8List serializedVersion = UtilsBytes.encodeBigInt(BigInt.from(version));
    Uint8List serializedTimestamp = (BytesBuilder()
          ..add(UtilsBytes.encodeBigInt(
              BigInt.from(timestamp.millisecondsSinceEpoch ~/ 1000))))
        .toBytes();
    Uint8List serializedPreviousHash = previousHash;
    Uint8List serializedTransactionRoot = transactionRoot;
    Uint8List serializedTransactionCount =
        UtilsBytes.encodeBigInt(BigInt.from(transactionCount));
    return (BytesBuilder()
          ..add(UtilsCompactSize.toSize(serializedVersion))
          ..add(serializedVersion)
          ..add(UtilsCompactSize.toSize(serializedTimestamp))
          ..add(serializedTimestamp)
          ..add(UtilsCompactSize.toSize(serializedPreviousHash))
          ..add(serializedPreviousHash)
          ..add(UtilsCompactSize.toSize(serializedTransactionRoot))
          ..add(serializedTransactionRoot)
          ..add(UtilsCompactSize.toSize(serializedTransactionCount))
          ..add(serializedTransactionCount))
        .toBytes();
  }

  /// Overrides toString() method for useful error messages
  @override
  String toString() => '''BlockModel
      'id': $id,
      'version': $version,
      'previousHash': $previousHash,
      'transactionRoot': $transactionRoot,
      'transactionCount': $transactionCount,
      'timestamp': $timestamp
    ''';
}
