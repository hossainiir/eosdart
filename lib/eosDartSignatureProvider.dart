import 'dart:typed_data';

import 'package:eos_dart/interfaces/api-interfaces.dart';
import 'package:eos_dart/interfaces/rpc-interfaces.dart';
import 'package:eos_dart/numeric.dart';
import 'package:eosdart_ecc/eosdart_ecc.dart' as ecc;
import 'package:crypto/crypto.dart';

class EosDartSignatureProvider extends SignatureProvider {
    /// map public to private keys */
    Map<String, String> keys;

    /// public keys */
    List<String> availableKeys;

    /// @param privateKeys private keys to sign with */
    EosDartSignatureProvider(List<String> privateKeys) {
      keys = Map<String, String>();
      availableKeys = [];
      for (var k in privateKeys) {
        var pub = convertLegacyPublicKey(ecc.EOSPrivateKey.fromString(k).toEOSPublicKey().toString());
        keys[pub] = k;
        availableKeys.add(pub);
      }
    }

    /// Public keys associated with the private keys that the `SignatureProvider` holds */
    Future<List<String>> getAvailableKeys() async{
        return availableKeys;
    }

    /// Sign a transaction */
    // sign(SignatureProviderArgs { chainId, requiredKeys, serializedTransaction } ) async {
    Future<PushTransactionArgs> sign(SignatureProviderArgs sig ) async {
      
      var l = List<int>.from(_stringToHex(sig.chainId))
      ..addAll(sig.serializedTransaction)
      ..addAll(Uint8List(32));

      var signatures = sig.requiredKeys.map(
        (pub) {
          var hash = sha256.convert(l);
          var tt =ecc.EOSPrivateKey.fromString(keys[convertLegacyPublicKey(pub)]);
          print("");
          print("hash");
          // print(tt.signHash(hash.bytes));
          print(hash);
          return tt.signHash(hash.bytes).toString();
        }
      ).toList();
      return PushTransactionArgs(signatures: signatures,serializedTransaction: sig.serializedTransaction);
    }

    List<int> _stringToHex(String str){
      List<int> a = [];
      for (var i = 0; i < str.length; i+=2) {
        var t = int.parse(str.substring(i,i+2),radix: 16);
        a.add(t);
      }
      return a;
    }
}
