import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:tiki_sdk_dart/consent/consent_service.dart';
import 'package:tiki_sdk_dart/node/node_service.dart';
import 'package:tiki_sdk_dart/ownership/ownership_service.dart';
import 'package:tiki_sdk_dart/tiki_sdk.dart';
import 'package:tiki_sdk_dart/utils/bytes.dart';

import '../in_mem_key.dart';
import '../in_mem_l0_storage.dart';

void main() {
  group('Consent Tests', () {
    OwnershipModel ownershipModel = OwnershipModel(
        transactionId: Uint8List.fromList('random1'.codeUnits),
        source: 'tiki app',
        type: TikiSdkDataTypeEnum.point,
        origin: 'com.mytiki.test');
    OwnershipModel ownershipModel2 = OwnershipModel(
        transactionId: Uint8List.fromList('random2'.codeUnits),
        source: 'tiki desktop',
        type: TikiSdkDataTypeEnum.pool,
        origin: 'com.mytiki.test');
    OwnershipModel ownershipModel3 = OwnershipModel(
        transactionId: Uint8List.fromList('random3'.codeUnits),
        source: 'tiki sdk',
        type: TikiSdkDataTypeEnum.point,
        origin: 'com.mytiki.test');
    TikiSdkDestination destination = const TikiSdkDestination(['com.mytiki/*']);
    test('Repository tests. Save and get by assetRef', () {
      Database db = sqlite3.openInMemory();
      ConsentRepository repository = ConsentRepository(db);
      ConsentModel consentModel = ConsentModel(
          ownershipModel.transactionId!, destination,
          about: 'test 1', reward: '1 point');
      ConsentModel consentModel2 = ConsentModel(
          ownershipModel2.transactionId!, destination,
          about: 'test 2', reward: '2 points');
      ConsentModel consentModel3 = ConsentModel(
          ownershipModel3.transactionId!, destination,
          about: 'test 3', reward: '3 points');
      repository.save(consentModel);
      repository.save(consentModel2);
      repository.save(consentModel3);
      ConsentModel? consent =
          repository.getByOwnershipId(ownershipModel.transactionId!);
      ConsentModel? consent2 =
          repository.getByOwnershipId(ownershipModel2.transactionId!);
      ConsentModel? consent3 =
          repository.getByOwnershipId(ownershipModel3.transactionId!);
      expect(consent == null, false);
      expect(consent!.reward, '1 point');
      expect(consent2 == null, false);
      expect(consent2!.reward, '2 points');
      expect(consent3 == null, false);
      expect(consent3!.reward, '3 points');
    });

    test('Give consent', () async {
      Database db = sqlite3.openInMemory();
      KeyStorage inMemKeyStorage = InMemKeyStorage();
      InMemL0Storage inMemL0Storage = InMemL0Storage();
      NodeService nodeService =
          await NodeService().init(db, inMemKeyStorage, inMemL0Storage);
      OwnershipService ownershipService =
          OwnershipService('com.mytiki', nodeService, db);
      ConsentService consentService = ConsentService(db, nodeService);
      Uint8List ownershipModelId = (await ownershipService.create(
              source: 'test', type: TikiSdkDataTypeEnum.pool))
          .transactionId!;
      await consentService.create(ownershipModelId,
          destinations: const TikiSdkDestination.all());
      ConsentModel? consentModel =
          consentService.getByOwnershipId(ownershipModelId);
      expect(consentModel == null, false);
      expect(
          Bytes.memEquals(consentModel!.ownershipId, ownershipModelId), true);
      expect(consentModel.destination.uses.contains('*'), true);
      expect(consentModel.destination.paths.contains('*'), true);
    });

    test('Revoke consent', () async {
      Database db = sqlite3.openInMemory();
      KeyStorage inMemKeyStorage = InMemKeyStorage();
      InMemL0Storage inMemL0Storage = InMemL0Storage();
      NodeService nodeService =
          await NodeService().init(db, inMemKeyStorage, inMemL0Storage);
      OwnershipService ownershipService =
          OwnershipService('com.mytiki', nodeService, db);
      ConsentService consentService = ConsentService(db, nodeService);
      Uint8List ownershipModelId = (await ownershipService.create(
              source: 'test', type: TikiSdkDataTypeEnum.pool))
          .transactionId!;
      await consentService.create(ownershipModelId,
          destinations: const TikiSdkDestination.all());
      await consentService.create(ownershipModelId,
          destinations: const TikiSdkDestination.none());
      ConsentModel? consentModel =
          consentService.getByOwnershipId(ownershipModelId);
      expect(consentModel == null, false);
      expect(
          Bytes.memEquals(consentModel!.ownershipId, ownershipModelId), true);
      expect(consentModel.destination.uses.contains('*'), false);
      expect(consentModel.destination.paths.contains('*'), false);
    });
  });
}
