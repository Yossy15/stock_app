// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockImpl _$$StockImplFromJson(Map<String, dynamic> json) => _$StockImpl(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? 'Unknown',
  qty: (json['qty'] as num?)?.toInt() ?? 0,
  price: (json['price'] as num?)?.toDouble() ?? 0.0,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$StockImplToJson(_$StockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'qty': instance.qty,
      'price': instance.price,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
