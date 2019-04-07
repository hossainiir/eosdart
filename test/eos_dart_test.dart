import 'dart:typed_data';

import 'package:eosdart_ecc/eosdart_ecc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eos_dart/index.dart';
void main() {

  test("Main eos_dart",()async{
    var privateKey = "5HxT6prWB8VuXkoAaX3eby8bWjquMtCvGuakhC8tGEiPSHfsQLR";
    var signatureProvider = EosDartSignatureProvider([privateKey]);
    // var rpc = JsonRpc('http://jungle2.cryptolions.io:80');
    var rpc = JsonRpc('http://145.239.133.201:8888');

    var api = Api(rpc: rpc,signatureProvider: signatureProvider,);
    var trx = await api.transact({
        "actions": [{
          "account": 'eosio.token',
          "name": 'transfer',
          "authorization": [{
            "actor": '12gh12gh12gh',
            "permission": 'active',
          }],
          "data": {
            "from": '12gh12gh12gh',
            "to": 'hossainiiiir',
            "quantity": '0.0030 EOS',
            "memo": 'EOS_DART TEST',
          },
        }]
      },
      blocksBehind: 3,
      expireSeconds: 240+16200,
    );
    // expect(trx["transaction_id"], isNot(""));
  });

}

