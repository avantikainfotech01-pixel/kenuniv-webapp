import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenuniv/models/kyc_model.dart';
import '../../core/api_service.dart';
import '../../utils/constant.dart';

final kycAdminProvider =
    StateNotifierProvider<KycAdminNotifier, AsyncValue<List<KycAdmin>>>(
      (ref) => KycAdminNotifier(ApiService(token: '')),
    );

class KycAdminNotifier extends StateNotifier<AsyncValue<List<KycAdmin>>> {
  final ApiService api;
  KycAdminNotifier(this.api) : super(const AsyncLoading()) {
    fetchKycList();
  }

  Future<void> fetchKycList() async {
    try {
      final res = await api.getRequest('$baseUrl/api/kyc/admin/kyc');
      final list = (res['data'] as List)
          .map((e) => KycAdmin.fromJson(e))
          .toList();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    await api.putRequest('$baseUrl/api/kyc/status/$id', {'status': status});
    await fetchKycList();
  }
}
