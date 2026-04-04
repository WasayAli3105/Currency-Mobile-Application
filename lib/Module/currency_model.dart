class CurrencyModel {
  final String code;
  final String name;

  CurrencyModel({required this.code, required this.name});

  factory CurrencyModel.fromJson(MapEntry<String, dynamic> entry) {
    return CurrencyModel(
      code: entry.key.toUpperCase(),
      name: entry.value.toString(),
    );
  }
}