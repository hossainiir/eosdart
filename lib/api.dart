import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:eos_dart/serialize.dart';

/**
 * @module API
 */
// copyright defined in eosjs/LICENSE.txt
import "interfaces/api-interfaces.dart";
import "interfaces/rpc-interfaces.dart";
import 'jsonrpc.dart';
import 'jsons.dart';

import 'serialize.dart' as ser;
import 'package:flutter/services.dart' show rootBundle;

class Api {
    /// Issues RPC calls */
    JsonRpc rpc;

    /// Get subset of `availableKeys` needed to meet authorities in a `transaction` */
    AuthorityProvider authorityProvider;

    /// Supplies ABIs in raw form (binary) */
    AbiProvider abiProvider ;

    /// Signs transactions */
    SignatureProvider signatureProvider;

    /// Identifies chain */
    String chainId;


    /// Converts abi files between binary and structured form (`abi.abi.json`) */
    Map<String, ser.Type> abiTypes;

    /// Converts transactions between binary and structured form (`transaction.abi.json`) */
    Map<String, ser.Type> transactionTypes;

    /// Holds information needed to serialize contract actions */
    var contracts = Map<String, ser.Contract>();

    /// Fetched abis */
    var cachedAbis = Map<String, CachedAbi>();

    /// @param args
    ///    * `rpc`: Issues RPC calls
    ///    * `authorityProvider`: Get public keys needed to meet authorities in a transaction
    ///    * `abiProvider`: Supplies ABIs in raw form (binary)
    ///    * `signatureProvider`: Signs transactions
    ///    * `chainId`: Identifies chain
    ///    * `textEncoder`: `TextEncoder` instance to use. Pass in `null` if running in a browser
    ///    * `textDecoder`: `TextDecoder` instance to use. Pass in `null` if running in a browser

    Api({
        this.rpc,
        this.authorityProvider,
        this.abiProvider,
        this.signatureProvider,
        this.chainId,
    }) {
      _initApi();
    }

    _initApi(){
      abiTypes = ser.getTypesFromAbi(ser.createInitialTypes(), Abi.fromJson(json.decode(abiJson)));
      transactionTypes = ser.getTypesFromAbi(ser.createInitialTypes(), Abi.fromJson(json.decode(transactionJson)));
    }

    /// Decodes an abi as Uint8List into json. */
    Abi rawAbiToJson(Uint8List rawAbi) {
      try {
        var buffer = ser.SerialBuffer(rawAbi);
        var str = buffer.getString();
        if (!ser.supportedAbiVersion(str)) {
            throw 'Unsupported abi version';
        }
        buffer.restartRead();
        var t = abiTypes['abi_def'];
        var b = t.deserialize(t,buffer);
        return Abi.fromJson(json.decode(json.encode(b)));        
      } catch (e) {
        print(e.message);
      }
    }

    /// Get abi in both binary and structured forms. Fetch when needed. */
    Future<CachedAbi> getCachedAbi(String accountName, {bool reload = false})async {
        if (!reload && cachedAbis[accountName] != null) {
            return cachedAbis[accountName];
        }
        CachedAbi cachedAbi;
        try {
            var rawAbi = (await rpc.getRawAbi(accountName)).abi;
            var abi = rawAbiToJson(rawAbi);
            cachedAbi = CachedAbi(abi:abi,rawAbi:rawAbi);
        } catch (e) {
            e.message = "fetching abi for $accountName: ${e.message}";
            throw e;
        }
        if (cachedAbi == null) {
            throw "Missing abi for $accountName";
        }
        cachedAbis[accountName]= cachedAbi;
        return cachedAbi;
    }

    /// Get abi in structured form. Fetch when needed. */
    Future<Abi> getAbi(String accountName, {bool reload = false}) async{
        return (await getCachedAbi(accountName, reload:reload)).abi;
    }

    /// Get abis needed by a transaction */
    Future<List<BinaryAbi>> getTransactionAbis(dynamic transaction, {bool reload = false})async {
        var accounts = (transaction["actions"] as List).map((action) => action["account"].toString()).toList();
        
        var uniqueAccounts =  Set.from(accounts).map((item)=>item.toString());
        // List<Future<BinaryAbi>> actionPromises = uniqueAccounts.map(
        //     Future<BinaryAbi>(account) async (
        //       return BinaryAbi(
        //         accountName: account, 
        //         "abi": (await getCachedAbi(account, reload:reload)).rawAbi,
        //       )
        //     }
        //   )
        // );

        var t = uniqueAccounts.map((f) async{
          return BinaryAbi(
            f,
            (await getCachedAbi(f,reload: reload)).rawAbi
          );
        });

        
        return await Future.wait(t);
    }

    /// Get data needed to serialize actions in a contract */
    Future<ser.Contract> getContract(String accountName, {bool reload = false})async {
        if (!reload && contracts[accountName] !=null) {
            return contracts[accountName];
        }
        var abi = await getAbi(accountName, reload:reload);
        var types = ser.getTypesFromAbi(ser.createInitialTypes(), abi);
        var actions = new Map<String, ser.Type>();
        for (var act in abi.actions) {
            actions[act.name] = ser.getType(types, act.type);
        }
        var result = ser.Contract(types:types, actions:actions );
        contracts[accountName] = result;
        return result;
    }

    /// Convert `value` to binary form. `type` must be a built-in abi type or in `transaction.abi.json`. */
    void serialize(ser.SerialBuffer buffer,String type, value) {
        var t = transactionTypes[type];
        t.serialize(t,buffer, value);
    }

    /// Convert data in `buffer` to structured form. `type` must be a built-in abi type or in `transaction.abi.json`. */
    dynamic deserialize(ser.SerialBuffer buffer,String type) {
      var t = transactionTypes[type];
      return t.deserialize(t,buffer);
    }

    /// Convert a transaction to binary */
    Uint8List serializeTransaction(Map<dynamic,dynamic> transaction) {
        var buffer = ser.SerialBuffer(Uint8List(0));
        var tt = <dynamic,dynamic> {
            "max_net_usage_words": 0,
            "max_cpu_usage_ms": 0,
            "delay_sec": 0,
            "context_free_actions": [],
            "actions": [],
            "transaction_extensions": [],
            // ...transaction,
        }..addAll(transaction);
        serialize(buffer, 'transaction',tt);
        print("transaction struct");
        print(tt);
        return buffer.asUint8List();
    }

    /// Convert a transaction from binary. Leaves actions in hex. */
    dynamic deserializeTransaction(Uint8List transaction) {
        var buffer = new ser.SerialBuffer(transaction);
        return deserialize(buffer, 'transaction');
    }

    /// Convert actions to hex */
    Future<List<ser.SerializedAction>> serializeActions(List<ser.Action> actions) async {
      var ac = actions.map((act)async{
        var contract = await getContract(act.account);
        var sr = ser.serializeAction(contract, act.account, act.name, act.authorization, act.data);
        return sr;
      });
      return await Future.wait(ac);
    }

    /// Convert actions from hex */
    Future<List<ser.Action>> deserializeActions(List<ser.Action>actions) async{
      var ac = actions.map((act)async{
        var contract = await getContract(act.account);
        return ser.deserializeAction(
            contract, act.account, act.name, act.authorization, act.data);
      });
      return await Future.wait(ac);
    }

    /// Convert a transaction from binary. Also deserializes actions. */
    Future<dynamic> deserializeTransactionWithActions(Object transaction)async {
        if (transaction is String) {
            transaction = ser.hexToUint8List(transaction);
        }
        var deserializedTransaction = deserializeTransaction(transaction);
        var deserializedActions = await deserializeActions(deserializedTransaction.actions);
        return { "deserializedTransaction":deserializedTransaction, "actions": deserializedActions };
    }

    /// Create and optionally broadcast a transaction.

    ///

    /// Named Parameters:
    ///    * `broadcast`: broadcast this transaction?
    ///    * `sign`: sign this transaction?
    ///    * If both `blocksBehind` and `expireSeconds` are present,
    ///      then fetch the block which is `blocksBehind` behind head block,
    ///      use it as a reference for TAPoS, and expire the transaction `expireSeconds` after that block's time.
    /// @returns node response if `broadcast`, `{signatures, serializedTransaction}` if `!broadcast`
    Future<dynamic> transact(dynamic transaction, 
      { bool broadcast = true, bool sign = true,int blocksBehind, int expireSeconds=180 })async {
        GetInfoResult info;

        if (chainId == null) {
            info = await rpc.get_info();
            chainId = info.chain_id;
        }
        print(chainId);

        if (blocksBehind is int && expireSeconds!=null) { // use config fields to generate TAPOS if they exist
            if (info == null) {
                info = await rpc.get_info();
            }
            var refBlock = await rpc.get_block(info.head_block_num - blocksBehind);
            var exp = ser.transactionHeader(refBlock, expireSeconds);
            transaction = {}..addAll(exp)..addAll(transaction);
        }

        if (!hasRequiredTaposFields( transaction)) {
            throw 'Required configuration or TAPOS fields are not present';
        }

        List<BinaryAbi> abis = await getTransactionAbis(transaction);
        // transaction = { ...transaction, actions: await serializeActions(transaction.actions) };
        var act = await serializeActions((transaction["actions"] as List).map((item)=>Action.fromJson(item)).toList());
        transaction = {}..addAll(transaction)..addAll({"actions":act});
        var serializedTransaction = serializeTransaction(transaction);
        var pushTransactionArgs   = PushTransactionArgs(signatures: [],serializedTransaction: serializedTransaction);

        if (sign) {
            var availableKeys = await signatureProvider.getAvailableKeys();
            var requiredKeys = await rpc.getRequiredKeys(AuthorityProviderArgs( transaction, availableKeys ));
            pushTransactionArgs = await signatureProvider.sign(SignatureProviderArgs(
                chainId: chainId,
                requiredKeys:requiredKeys,
                serializedTransaction:serializedTransaction,
                abis:abis,
            ));
        }
        if (broadcast) {
          print(pushTransactionArgs);
            return pushSignedTransaction(pushTransactionArgs);
        }
        return pushTransactionArgs;
    }

    Future<dynamic> transactTest(Map testInfo,String chainId,dynamic transaction, 
      { bool broadcast = true, bool sign = true,int blocksBehind, int expireSeconds=180 })async {
        GetInfoResult info = GetInfoResult.fromJson(testInfo);

        // if (chainId == null) {
        //     info = await rpc.get_info();
        //     chainId = info.chain_id;
        // }
        // print(chainId);

        if (blocksBehind is int && expireSeconds!=null) { // use config fields to generate TAPOS if they exist
            if (info == null) {
                info = await rpc.get_info();
            }
            var refBlock = await rpc.get_block(info.head_block_num - blocksBehind);
            var exp = ser.transactionHeader(refBlock, expireSeconds);
            transaction = {}..addAll(exp)..addAll(transaction);
        }

        if (!hasRequiredTaposFields( transaction)) {
            throw 'Required configuration or TAPOS fields are not present';
        }

        List<BinaryAbi> abis = await getTransactionAbis(transaction);
        // transaction = { ...transaction, actions: await serializeActions(transaction.actions) };
        var act = await serializeActions((transaction["actions"] as List).map((item)=>Action.fromJson(item)).toList());
        transaction = {}..addAll(transaction)..addAll({"actions":act});
        var serializedTransaction = serializeTransaction(transaction);
        var pushTransactionArgs   = PushTransactionArgs(signatures: [],serializedTransaction: serializedTransaction);

        if (sign) {
            var availableKeys = await signatureProvider.getAvailableKeys();
            var requiredKeys = await rpc.getRequiredKeys(AuthorityProviderArgs( transaction, availableKeys ));
            pushTransactionArgs = await signatureProvider.sign(SignatureProviderArgs(
                chainId: chainId,
                requiredKeys:requiredKeys,
                serializedTransaction:serializedTransaction,
                abis:abis,
            ));
        }
        if (broadcast) {
          print(pushTransactionArgs);
            return pushSignedTransaction(pushTransactionArgs);
        }
        return pushTransactionArgs;
    }

//     void test(String chainId,String expiration,String ref_block_num,String ref_block_prefix,List<Action> actions){
// var transaction = {
//   "expiration":expiration,
//   "ref_block_num":ref_block_num,
//   "ref_block_prefix"
// }
//     }
    /// Broadcast a signed transaction
    Future<dynamic> pushSignedTransaction(PushTransactionArgs push) async {
        return rpc.push_transaction(push);
    }

    // eventually break out into TransactionValidator class
    bool hasRequiredTaposFields( dynamic tr) {
        return tr["expiration"]!=null && tr["ref_block_num"]!=null && tr["ref_block_prefix"]!=null;
    }

} // Api
