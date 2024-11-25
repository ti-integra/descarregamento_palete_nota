import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
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

class XmlFileListScreen extends StatefulWidget {
  const XmlFileListScreen({super.key});

  @override
  _XmlFileListScreenState createState() => _XmlFileListScreenState();
}

class _XmlFileListScreenState extends State<XmlFileListScreen> {
  // List<ArchiveFile> xmlFiles = [];
  final _barcodeController = TextEditingController();

  Future<void> _selectAndExtractXmlFiles() async {
    List<ArchiveFile> xmlFiles = [];
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
      print("filebytes");
      final archive = ZipDecoder().decodeBytes(fileBytes);
      print("archive");
      setState(() {
        xmlFiles = archive.files
            .where((file) => file.isFile && file.name.endsWith('.xml'))
            .toList();
        globals.extractItemsFromXml(xmlFiles);
      });
    } catch (e) {
      print("Erro ao processar o arquivo ZIP: $e");
    }
  }

  void _showXmlOptionsForBarcode(String barcode) {
    barcode = barcode.split("]").last.substring(2);

    // Filtrar os XMLs que contêm o item com quantidade > 0
    List<int> availableXmlIndexes = [];
    for (int i = 0; i < globals.todasNotas.length; i++) {
      final produtos = globals.todasNotas[i].produtos;
      if (produtos.any(
          (item) => item.codigo == barcode && item.quantidadeFaltante > 0)) {
        availableXmlIndexes.add(i);
      }
    }

    if (availableXmlIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content:
              Text('Produto com EAN $barcode não disponível em nenhum XML.'),
        ),
      );
      return;
    }

    // Mostrar diálogo para selecionar o XML
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione um XML'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableXmlIndexes.map((index) {
              return ListTile(
                title: Text(
                    "${globals.todasNotas[index].numero}\t\t${globals.todasNotas[index].destinatario}"),
                onTap: () {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  _decreaseQuantityInXml(index, barcode);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _decreaseQuantityInXml(int xmlIndex, String barcode) {
    bool itemFound = false;

    for (var item in globals.todasNotas[xmlIndex].produtos) {
      if (item.codigo == barcode && item.quantidadeFaltante > 0) {
        setState(() {
          item.quantidadeFaltante -= 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Quantidade de ${item.descricao} atualizada para ${item.quantidadeFaltante} no arquivo ${globals.todasNotas[xmlIndex].numero}.'),
          ),
        );
        itemFound = true;
        break;
      }
    }

    if (!itemFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Produto não encontrado ou quantidade já é zero.'),
        ),
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
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    _barcodeController.clear();
                  },
                ),
              ),
              onSubmitted: _showXmlOptionsForBarcode,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: globals.todasNotas.length,
                itemBuilder: (context, index) {
                  final fileName =
                      "Nota: ${globals.todasNotas[index].numero}\nDestinatario: ${globals.todasNotas[index].destinatario}\nChave: ${globals.todasNotas[index].chave} ";

                  return ListTile(
                    title: Text(fileName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => XmlFileDetailScreen(
                            localIndex: index,
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
  final int localIndex;

  const XmlFileDetailScreen({super.key, required this.localIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itens do Arquivo XML'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          // itemCount: globals.allItens[localIndex].length,
          itemCount: globals.todasNotas[localIndex].produtos.length,
          itemBuilder: (context, index) {
            final item = globals.todasNotas[localIndex].produtos[index];
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
