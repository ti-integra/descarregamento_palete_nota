import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:file_picker/file_picker.dart';
import 'global.dart' as globals;

void main() {
  runApp(MyApp());
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

// Primeira tela que exibe a lista de arquivos XML (categorias) no ZIP
class XmlFileListScreen extends StatefulWidget {
  @override
  _XmlFileListScreenState createState() => _XmlFileListScreenState();
}

class _XmlFileListScreenState extends State<XmlFileListScreen> {
  List<ArchiveFile> xmlFiles = [];
  TextEditingController _barcodeController = TextEditingController();

  Future<void> _selectAndExtractXmlFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null) {
        return; // Cancelado pelo usuário
      }

      String? zipFilePath = result.files.single.path;
      if (zipFilePath == null) {
        return;
      }

      final fileBytes = File(zipFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(fileBytes);

      // Filtrar apenas arquivos XML do ZIP
      setState(() {
        xmlFiles = archive.files
            .where((file) => file.isFile && file.name.endsWith('.xml'))
            .toList();
      });
    } catch (e) {
      print("Erro ao processar o arquivo ZIP: $e");
    }
  }

  List<globals.MyData> _extractItemsFromXml(ArchiveFile file) {
    final document = XmlDocument.parse(utf8.decode(file.content as List<int>));
    final List<globals.MyData> items = [];

    final detElements = document.findAllElements('det', namespace: '*');
    for (var det in detElements) {
      final prod = det.findElements('prod', namespace: '*').first;
      final eanCode = prod.getElement('cEAN', namespace: '*')?.innerText ?? '';
      final quantidadeString =
          prod.getElement('qCom', namespace: '*')?.innerText ?? '0';
      final quantidadeInt = double.parse(quantidadeString).round();
      final descricao =
          prod.getElement('xProd', namespace: '*')?.innerText ?? '';

      items.add(globals.MyData(
        ean: eanCode,
        quantidade: quantidadeInt,
        descricao: descricao,
      ));

      globals.allItems.add(globals.MyData(
        ean: eanCode,
        quantidade: quantidadeInt,
        descricao: descricao,
      ));
    }

    print(globals.allItems);
    return items;
  }

  void _searchAndDecreaseQuantity(String barcode) {
    bool itemFound = false;

    for (var file in xmlFiles) {
      // Extrair os itens do arquivo XML
      // List<MyData> items = _extractItemsFromXml(file);

      // Tentar encontrar o primeiro item com EAN correspondente e quantidade > 0
      for (var item in globals.allItems) {
        if (item.ean == barcode && item.quantidade > 0) {
          print(item.quantidade);
          setState(() {
            item.quantidade -= 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Quantidade de ${item.descricao} atualizada para ${item.quantidade}.')),
          );
          itemFound = true;
          break;
        }
      }
      if (itemFound) break;
    }

    if (!itemFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Item com EAN $barcode não encontrado ou todos os itens estão com quantidade zero.')),
      );
    }

    _barcodeController.clear();
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
            SizedBox(height: 20),
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Código de Barras',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchAndDecreaseQuantity(_barcodeController.text);
                  },
                ),
              ),
              onSubmitted: _searchAndDecreaseQuantity,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: xmlFiles.length,
                itemBuilder: (context, index) {
                  final fileName = xmlFiles[index].name;
                  return ListTile(
                    title: Text('Nota: $fileName'),
                    onTap: () {
                      // Navegar para a tela de detalhes do arquivo XML selecionado
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => XmlFileDetailScreen(
                            xmlFile: xmlFiles[index],
                          ),
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

// Segunda tela que exibe os itens dentro de um arquivo XML específico
class XmlFileDetailScreen extends StatelessWidget {
  final ArchiveFile xmlFile;

  XmlFileDetailScreen({required this.xmlFile});

  List<globals.MyData> _extractItemsFromXml(ArchiveFile file) {
    final document = XmlDocument.parse(utf8.decode(file.content as List<int>));
    final List<globals.MyData> items = [];

    final detElements = document.findAllElements('det', namespace: '*');
    for (var det in detElements) {
      final prod = det.findElements('prod', namespace: '*').first;
      final eanCode = prod.getElement('cEAN', namespace: '*')?.innerText ?? '';
      final quantidadeString =
          prod.getElement('qCom', namespace: '*')?.innerText ?? '0';
      final quantidadeInt = double.parse(quantidadeString).round();
      final descricao =
          prod.getElement('xProd', namespace: '*')?.innerText ?? '';

      items.add(globals.MyData(
        ean: eanCode,
        quantidade: quantidadeInt,
        descricao: descricao,
      ));

      globals.allItems.add(globals.MyData(
        ean: eanCode,
        quantidade: quantidadeInt,
        descricao: descricao,
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _extractItemsFromXml(xmlFile);

    return Scaffold(
      appBar: AppBar(
        title: Text('Itens do Arquivo XML'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: globals.allItems.length,
          itemBuilder: (context, index) {
            final item = globals.allItems[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item.toString()),
              ),
            );
          },
        ),
      ),
    );
  }
}
