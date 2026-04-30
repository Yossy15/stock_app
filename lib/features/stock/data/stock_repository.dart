import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/stock.dart';
import '../../../core/network/dio_provider.dart';

part 'stock_repository.g.dart';

class StockRepository {
  final Dio _dio;

  StockRepository(this._dio);

  Future<Map<String, dynamic>> getStocks({
    int page = 1,
    int limit = 10,
    String search = '',
    String? sortBy,
    String? order,
  }) async {
    final response = await _dio.get('/stock', queryParameters: {
      'page': page,
      'limit': limit,
      'search': search,
      if (sortBy != null) 'sortBy': sortBy,
      if (order != null) 'order': order,
    });

    final List<dynamic> data = response.data['data'];
    final List<Stock> stocks = data.map((e) => Stock.fromJson(e)).toList();

    return {
      'stocks': stocks,
      'pagination': response.data['pagination'],
    };
  }

  Future<Stock> createStock(String name, int qty, double price, {String? performer}) async {
    final response = await _dio.post('/stock', data: {
      'name': name,
      'qty': qty,
      'price': price,
      if (performer != null) 'performer': performer,
    });
    return Stock.fromJson(response.data);
  }

  Future<Stock> updateStock(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/stock/$id', data: data);
    return Stock.fromJson(response.data);
  }

  Future<void> deleteStock(String id, {String? performer}) async {
    await _dio.delete('/stock/$id', data: {
      if (performer != null) 'performer': performer,
    });
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    final response = await _dio.get('/activities');
    return List<Map<String, dynamic>>.from(response.data);
  }
}

@riverpod
StockRepository stockRepository(StockRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return StockRepository(dio);
}
