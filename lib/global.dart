import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

// List<Produtos> localItens = [];
// List<List<Produtos>> allItens = [];
List<Nota> todasNotas = [];

class Nota {
  String destinatario = "";
  String chave = "";
  String numero = "";
  List<Produtos> produtos = [];

  Nota(
      {required this.chave,
      required this.produtos,
      required this.numero,
      required this.destinatario});

  @override
  String toString() {
    return 'EAN: $chave\nQuantidade: $produtos';
  }
}

class Produtos {
  final String codigo;
  int quantidadeFaltante;
  final String descricao;
  int quantidadeTotal;

  Produtos(
      {required this.codigo,
      required this.quantidadeFaltante,
      required this.descricao,
      required this.quantidadeTotal});

  @override
  String toString() {
    return 'EAN: $codigo\nQuantidade: $quantidadeFaltante\nDescrição: $descricao';
  }
}

void extractItemsFromXml(List<ArchiveFile> files) {
  for (var file in files) {
    print(file.name);
    final document = XmlDocument.parse(utf8.decode(file.content as List<int>));
    final detElements = document.findAllElements('det', namespace: '*');
    List<Produtos> listTmp = [];
    try {
      for (var det in detElements) {
        // try {

        final prod = det.findElements('prod', namespace: '*').first;
        final codigo =
            prod.getElement('cProd', namespace: '*')?.innerText ?? '';
        final quantidadeString =
            prod.getElement('qCom', namespace: '*')?.innerText ?? '0';
        final quantidadeInt = double.parse(quantidadeString).round();
        final descricao =
            prod.getElement('xProd', namespace: '*')?.innerText ?? '';

        listTmp.add(Produtos(
          codigo: codigo,
          quantidadeFaltante: quantidadeInt,
          quantidadeTotal: quantidadeInt,
          descricao: descricao,
        ));
      }
      var chave =
          document.findAllElements("chNFe", namespace: "*").first.innerText;
      var dest = document
          .findAllElements("dest", namespace: "*")
          .first
          .findAllElements("xNome", namespace: "*")
          .first
          .innerText;

      var numero =
          document.findAllElements("nFat", namespace: "*").first.innerText;

      var tmp = Nota(
          chave: chave, produtos: listTmp, destinatario: dest, numero: numero);
      todasNotas.add(tmp);
    } catch (e) {
      print(e);
      continue;
    }
  }
}
