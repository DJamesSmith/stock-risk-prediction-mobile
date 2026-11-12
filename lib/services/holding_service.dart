import '../config/api_endpoints.dart';
import '../core/api_client.dart';
import '../core/api_response.dart';
import '../models/holding.dart';

class SavedHolding {
  SavedHolding({required this.holding, required this.message});

  final Holding holding;
  final String message;
}

class HoldingService {
  HoldingService(this.api);

  final ApiClient api;

  Future<Holding> detail(int id) async {
    final ApiResponse response = await api.get(ApiEndpoints.holdingDetail(id));
    return Holding.fromJson(response.dataMap);
  }

  Future<SavedHolding> create(
    int portfolioId, {
    required String ticker,
    required String quantity,
    required String buyPrice,
    required String buyDate,
  }) async {
    final ApiResponse response = await api.post(
      ApiEndpoints.portfolioHoldings(portfolioId),
      body: {
        'ticker': ticker,
        'quantity': quantity,
        'buy_price': buyPrice,
        'buy_date': buyDate,
      },
    );
    return SavedHolding(holding: Holding.fromJson(response.dataMap), message: response.message);
  }

  Future<SavedHolding> update(
    int id, {
    required String quantity,
    required String buyPrice,
    required String buyDate,
  }) async {
    final ApiResponse response = await api.patch(
      ApiEndpoints.holdingDetail(id),
      body: {
        'quantity': quantity,
        'buy_price': buyPrice,
        'buy_date': buyDate,
      },
    );
    return SavedHolding(holding: Holding.fromJson(response.dataMap), message: response.message);
  }

  Future<void> remove(int id) async {
    await api.delete(ApiEndpoints.holdingDetail(id));
  }
}
