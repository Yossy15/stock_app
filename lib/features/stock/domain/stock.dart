import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock.freezed.dart';
part 'stock.g.dart';

@freezed
class Stock with _$Stock {
  const factory Stock({
    @Default('') String id,
    @Default('Unknown') String name,
    @Default(0) int qty,
    @Default(0.0) double price,
    DateTime? updatedAt,
  }) = _Stock;

  factory Stock.fromJson(Map<String, dynamic> json) => _$StockFromJson(json);
}
