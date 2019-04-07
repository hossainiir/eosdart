library eos_dart;
import 'package:eosdart_ecc/eosdart_ecc.dart';
import 'package:eosdart/eosdart.dart';

class EosDart{
  
  final String nodePath;
  EOSClient _client;
  EosDart({this.nodePath}){
    _client = EOSClient('https://eos.greymass.com', 'v1');
  } 


  void pushTransaction() async{
  }

  Future<NodeInfo> getInfo() async{
    var t = await _client.getInfo();
    return t;
  }

  Future<Block> getBlock(NodeInfo ni) async{
    var t = _client.getBlock(ni.lastIrreversibleBlockNum.toString());
    return t;
  }

  void signTransaction(){
    
  }


}
