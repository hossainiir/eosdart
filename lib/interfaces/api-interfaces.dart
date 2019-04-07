import 'dart:typed_data';

import 'rpc-interfaces.dart';

/// Arguments to `getRequiredKeys`
class AuthorityProviderArgs {
    /// Transaction that needs to be signed 
  final Object transaction;
    /// Public keys associated with the private keys that the `SignatureProvider` holds
  final List<String> availableKeys;

  AuthorityProviderArgs(this.transaction,this.availableKeys);
}

/// Get subset of `availableKeys` needed to meet authorities in `transaction` 
abstract class AuthorityProvider {
    /// Get subset of `availableKeys` needed to meet authorities in `transaction`
    // getRequiredKeys: (args: AuthorityProviderArgs) => Promise<string[]>;
  Future<List<String>> getRequiredKeys(AuthorityProviderArgs args);
}

/// Retrieves raw ABIs for a specified accountName
abstract class AbiProvider {
    /// Retrieve the BinaryAbi 
    Future<BinaryAbi> getRawAbi(String accountName);
    // getRawAbi: (accountName: string) => Promise<BinaryAbi>;
}

/// Structure for the raw form of ABIs
class BinaryAbi {
    /// account which has deployed the ABI
    final String accountName;

    /// abi in binary form 
    final Uint8List abi;

    BinaryAbi(this.accountName,this.abi);
}

/// Holds a fetched abi
class CachedAbi {
    /// abi in binary form
    final Uint8List rawAbi;

    /// abi in structured form
    final Abi abi;

    CachedAbi({this.abi,this.rawAbi});
}

/// Arguments to `sign`
class SignatureProviderArgs {
    /// Chain transaction is for
    final String chainId;

    /// Public keys associated with the private keys needed to sign the transaction
    final List<String> requiredKeys;

    /// Transaction to sign
    final Uint8List serializedTransaction;

    /// ABIs for all contracts with actions included in `serializedTransaction`
    final List<BinaryAbi> abis;

    SignatureProviderArgs({this.abis,this.chainId,this.requiredKeys,this.serializedTransaction});
}

/// Signs transactions */
abstract class SignatureProvider {
    /// Public keys associated with the private keys that the `SignatureProvider` holds
    // getAvailableKeys: () => Promise<string[]>;
    Future<List<String>> getAvailableKeys();

    /// Sign a transaction 
    // sign: (args: SignatureProviderArgs) => Promise<PushTransactionArgs>;
    Future<PushTransactionArgs> sign(SignatureProviderArgs args);
}
