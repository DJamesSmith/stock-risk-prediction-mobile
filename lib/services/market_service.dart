import '../config/api_endpoints.dart';
import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/formatters.dart';
import '../models/page_result.dart';
import '../models/price.dart';

class MarketService {
  MarketService(this.api);

  static const int maxHistoryPages = 3;

  final ApiClient api;

  Future<PriceRow> latestPrice(String ticker) async {
    final ApiResponse response = await api.get(ApiEndpoints.latestPrice(ticker));
    return PriceRow.fromJson(response.dataMap);
  }

  Future<List<PriceRow>> history(String ticker, {required DateTime start, required DateTime end}) async {
    final List<PriceRow> rows = [];
    String? nextUrl;
    int page = 0;

    do {
      final ApiResponse response;

      if (nextUrl == null) {
        response = await api.get(
          ApiEndpoints.priceHistory(ticker),
          query: {
            'start': Formatters.apiDate(start),
            'end': Formatters.apiDate(end),
            'page_size': 100,
          },
        );
      } else {
        response = await api.get(nextUrl);
      }

      final PageResult<PriceRow> result = PageResult.fromJson(response.dataMap, PriceRow.fromJson);
      rows.addAll(result.results);
      nextUrl = result.next;
      page++;
    } while (nextUrl != null && page < maxHistoryPages);

    rows.sort((first, second) => first.date.compareTo(second.date));
    return rows;
  }

  Future<String> refresh(String ticker) async {
    final ApiResponse response = await api.post(ApiEndpoints.refreshPrices(ticker));
    return response.message;
  }
}
