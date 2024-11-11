List<MyData> allItems = [];

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
    return 'EAN: $ean\nQuantidade: $quantidade\nDescrição: $descricao';
  }
}
