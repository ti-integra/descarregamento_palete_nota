import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyData {
  final String ean;
  int quantidade;
  final String descricao;

  MyData({
    required this.ean,
    required this.quantidade,
    required this.descricao,
  });

  @override
  String toString() {
    return 'EAN: $ean\\nQuantidade: $quantidade\\nDescrição: $descricao';
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZIP XML Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: XmlFileListScreen(),
    );
  }
}

// Tela que exibe a lista de arquivos XML no ZIP
class XmlFileListScreen extends StatefulWidget {
  const XmlFileListScreen({super.key});

  @override
  _XmlFileListScreenState createState() => _XmlFileListScreenState();
}

class _XmlFileListScreenState extends State<XmlFileListScreen> {
  List<ArchiveFile> xmlFiles = []; // Lista de arquivos XML

  Future<void> _selectAndExtractXmlFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null) return; // Cancelado pelo usuário

    String? zipFilePath = result.files.single.path;
    if (zipFilePath == null) return;

    try {
      final fileBytes = File(zipFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(fileBytes);

      setState(() {
        xmlFiles = archive.files
            .where((file) => file.isFile && file.name.endsWith('.xml'))
            .toList();
      });
    } catch (e) {
      print("Erro ao processar o arquivo ZIP: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arquivos XML no ZIP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _selectAndExtractXmlFiles,
              child: Text('Selecionar e Processar Arquivo ZIP'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: xmlFiles.length,
                itemBuilder: (context, index) {
                  final xmlFile = xmlFiles[index];
                  return ListTile(
                    title: Text(xmlFile.name),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => XmlItemScreen(xmlFile: xmlFile),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tela que exibe os itens de um arquivo XML específico
class XmlItemScreen extends StatefulWidget {
  final ArchiveFile xmlFile;

  const XmlItemScreen({super.key, required this.xmlFile});

  @override
  _XmlItemScreenState createState() => _XmlItemScreenState();
}

class _XmlItemScreenState extends State<XmlItemScreen> {
  List<MyData> items = [];

  @override
  void initState() {
    super.initState();
    items = _extractItemsFromXml(widget.xmlFile);
  }

  List<MyData> _extractItemsFromXml(ArchiveFile file) {
    final document = XmlDocument.parse(utf8.decode(file.content as List<int>));
    final List<MyData> items = [];

    for (var det in document.findAllElements('det')) {
      final prod = det.findElements('prod').first;
      final eanCode = prod.getElement('cEAN')?.innerText ?? '';
      final quantidadeString = prod.getElement('qCom')?.innerText ?? '0';
      final quantidadeInt = double.parse(quantidadeString).round();
      final descricao = prod.getElement('xProd')?.innerText ?? '';

      items.add(MyData(
        ean: eanCode,
        quantidade: quantidadeInt,
        descricao: descricao,
      ));
    }
    return items;
  }

  void _searchAndDecreaseQuantity(String barcode) {
    bool itemFound = false;

    for (var item in items) {
      if (item.ean == barcode && item.quantidade > 0) {
        setState(() {
          item.quantidade -= 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Quantidade de ${item.descricao} atualizada para ${item.quantidade}.'),
          ),
        );
        itemFound = true;
        break;
      }
    }

    if (!itemFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Item com EAN $barcode não encontrado ou todos os itens estão com quantidade zero.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController _barcodeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Itens do Arquivo XML'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _barcodeController,
              decoration:
                  InputDecoration(labelText: 'Digite o EAN para buscar'),
              onSubmitted: _searchAndDecreaseQuantity,
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item.descricao),
                    subtitle: Text(
                        'EAN: ${item.ean} | Quantidade: ${item.quantidade}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
