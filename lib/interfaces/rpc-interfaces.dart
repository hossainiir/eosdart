
import 'dart:typed_data';

class AbiType{
  final String new_type_name;//new_type_name
  final String type;
  
  AbiType(this.new_type_name,this.type);
  factory AbiType.fromJson(Map json){
    return AbiType(json["new_type_name"],json["type"]);
  }
}

class AbiStructField{
  final String name;
  final String type;

  AbiStructField(this.name,this.type);

  factory AbiStructField.fromJson(Map json){
    return AbiStructField(json["name"],json["type"]);
  }

}

class AbiStruct{
  final String name;
  final String base;
  final List<AbiStructField> fields;

  AbiStruct(this.name,this.base,this.fields);
  factory AbiStruct.fromJson(Map json){
    return AbiStruct(
      json["name"],
      json["base"],
      (json["fields"] as List)?.map((item)=>AbiStructField.fromJson(item))?.toList()
    );
  }

}

class AbiAction {
  final String name;
  final String type;
  final String ricardian_contract;//ricardian_contract
  AbiAction(this.name,this.type,this.ricardian_contract);

  factory AbiAction.fromJson(Map json){
    return AbiAction(json["name"],json["type"],json["ricardian_contract"]);
  }
}

class AbiTable {
  final String name;
  final String type;
  final String index_type;//index_type
  final List<String> key_names;//key_names
  final List<String> key_types;//key_types

  AbiTable(this.name,this.type,this.index_type,this.key_names,this.key_types);

  factory AbiTable.fromJson(Map json){
    return AbiTable(
      json["name"],
      json["type"],
      json["index_type"],
      (json["key_names"] as List).map((item)=>item.toString()).toList(),
      (json["key_types"] as List).map((item)=>item.toString()).toList()
    );
  }

}

class AbiRicardianClauses {
  final String id;
  final String body;

  AbiRicardianClauses(this.id,this.body);

  factory AbiRicardianClauses.fromJson(Map json){
    return AbiRicardianClauses(json["id"],json["body"]);
  }
}

class AbiErrorMessages{
  final String error_code;
  final String error_msg;

  AbiErrorMessages(this.error_code,this.error_msg);
  factory AbiErrorMessages.fromJson(Map json){
    return AbiErrorMessages(json["error_code"],json["error_msg"]);
  }
  
}

class AbiExtensions{
  final int tag;
  final String value;

  AbiExtensions(this.tag,this.value);

  factory AbiExtensions.fromJson(Map json){
    return AbiExtensions(json["tag"],json["value"]);
  }
}

class AbiVariants{
  final String name;
  final List<String> types;

  AbiVariants(this.name,this.types);
  factory AbiVariants.fromJson(Map json){
    return AbiVariants(json["name"],(json["types"] as List).map((item)=>item.toString()).toList());
  }
}

/// Structured format for abis 
class Abi {
  String version;
  List<AbiType> types;
  List<AbiStruct> structs;
  List<AbiAction> actions;
  List<AbiTable> tables;
  List<AbiRicardianClauses> ricardian_clauses;
  List<AbiErrorMessages> error_messages;
  List<AbiExtensions> abi_extensions;
  List<AbiVariants> variants;
  Abi({
    this.abi_extensions,
    this.actions,
    this.error_messages,
    this.ricardian_clauses,
    this.structs,
    this.tables,
    this.types,
    this.variants,
    this.version
  });
  factory Abi.fromJson(Map json){
    return Abi(
      abi_extensions: (json["abi_extensions"] as List)?.map((item)=>AbiExtensions.fromJson(item))?.toList(),
      actions: (json["actions"] as List)?.map((item)=>AbiAction.fromJson(item))?.toList(),
      structs: (json["structs"] as List)?.map((item)=>AbiStruct.fromJson(item))?.toList(),
      tables: (json["tables"] as List)?.map((item)=>AbiTable.fromJson(item))?.toList(),
      types: (json["types"] as List)?.map((item)=>AbiType.fromJson(item))?.toList(),
      variants: (json["variants"] as List)?.map((item)=>AbiVariants.fromJson(item))?.toList(),
      error_messages: (json["error_messages"] as List)?.map((item)=>AbiErrorMessages.fromJson(item))?.toList(),
      ricardian_clauses: (json["ricardian_clauses"] as List)?.map((item)=>AbiRicardianClauses.fromJson(item))?.toList(),
      version: json["version"]
    );
  }
}

/// Return value of `/v1/chain/get_abi` 
class GetAbiResult {
  final String accountName;//account_name
  final Abi abi;

  GetAbiResult(this.accountName,this.abi);

  factory GetAbiResult.fromJson(Map json){
    return GetAbiResult(json["account_name"],Abi.fromJson(json["abi"]));
  }
}

/// Subset of `GetBlockResult` needed to calculate TAPoS fields in transactions 
class BlockTaposInfo {
  final String timestamp;
  final int block_num;
  final int ref_block_prefix;

  BlockTaposInfo(this.timestamp,this.block_num,this.ref_block_prefix);
}

/// Return value of `/v1/chain/get_block` */
class GetBlockResult extends  BlockTaposInfo{
  final String producer; 
  final int confirmed; 
  final String previous; 
  final String transaction_mroot; 
  final String action_mroot; 
  final int schedule_version; 
  final String producer_signature; 
  final String id; 

  GetBlockResult({
    this.action_mroot,
    this.confirmed,
    this.id,
    this.previous,
    this.producer,
    this.producer_signature,
    this.schedule_version,
    this.transaction_mroot,
    timestamp,
    block_num,
    ref_block_prefix
    }
  ):super(timestamp,block_num,ref_block_prefix);

  factory GetBlockResult.fromJson(Map json){
    print(json);
    return GetBlockResult(
      producer:json["producer"],
      confirmed:json["confirmed"],
      previous:json["previous"],
      transaction_mroot:json["transaction_mroot"],
      action_mroot:json["action_mroot"],
      schedule_version:json["schedule_version"],
      producer_signature:json["producer_signature"],
      id:json["id"],
      timestamp:json["timestamp"],
      block_num:json["block_num"],
      ref_block_prefix:json["ref_block_prefix"]
    );
  }
}

/// Return value of `/v1/chain/get_code` 
class GetCodeResult {
  final String account_name;
  final String code_hash;
  final String wast;
  final String wasm;
  final Abi abi;
  
  GetCodeResult({this.abi,this.account_name,this.code_hash,this.wasm,this.wast});

  factory GetCodeResult.fromJson(Map json){
    return GetCodeResult(
      account_name: json["account_name"],
      code_hash: json["code_hash"],
      wast: json["wast"],
      wasm: json["wasm"],
      abi: Abi.fromJson(json["abi"]),
    );
  }
}

/// Return value of `/v1/chain/get_info`
class GetInfoResult {
  final String server_version;
  final String chain_id;
  final int head_block_num;
  final int last_irreversible_block_num;
  final String last_irreversible_block_id;
  final String head_block_id;
  final String head_block_time;
  final String head_block_producer;
  final int virtual_block_cpu_limit;
  final int virtual_block_net_limit;
  final int block_cpu_limit;
  final int block_net_limit;

  GetInfoResult({
    this.block_cpu_limit,
    this.block_net_limit,
    this.chain_id,
    this.head_block_id,
    this.head_block_num,
    this.head_block_producer,
    this.head_block_time,
    this.last_irreversible_block_id,
    this.last_irreversible_block_num,
    this.server_version,
    this.virtual_block_cpu_limit,
    this.virtual_block_net_limit    
    });

  factory   GetInfoResult.fromJson(Map json){
    return GetInfoResult(
      block_cpu_limit: json["block_cpu_limit"],
      block_net_limit: json["block_net_limit"],
      chain_id: json["chain_id"],
      head_block_id: json["head_block_id"],
      head_block_num: json["head_block_num"],
      head_block_producer: json["head_block_producer"],
      head_block_time: json["head_block_time"],
      last_irreversible_block_id: json["last_irreversible_block_id"],
      last_irreversible_block_num: json["last_irreversible_block_num"],
      server_version: json["server_version"],
      virtual_block_cpu_limit: json["virtual_block_cpu_limit"],
      virtual_block_net_limit: json["virtual_block_net_limit"],
    );
  }
}

/// Return value of `/v1/chain/get_raw_code_and_abi` 
class GetRawCodeAndAbiResult {
  final String account_name;
  final String wasm;
  final String abi;

  GetRawCodeAndAbiResult({this.abi,this.account_name,this.wasm});

  factory GetRawCodeAndAbiResult.fromJson(Map json){
    return GetRawCodeAndAbiResult(
      abi: json["abi"],
      account_name: json["account_name"],
      wasm: json["wasm"],
    );
  }
}

/// Arguments for `push_transaction` 
class PushTransactionArgs {
  final List<String> signatures;
  final Uint8List serializedTransaction;

  PushTransactionArgs({this.signatures,this.serializedTransaction});
}
