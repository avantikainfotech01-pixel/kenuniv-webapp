import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenuniv/core/api_service.dart';
import 'package:kenuniv/models/user_model.dart';
import 'package:kenuniv/utils/constant.dart';

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<List<UserModel>>>(
      (ref) => UserNotifier(ref),
    );

class UserNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final Ref ref;
  UserNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> fetchUsers(String token) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ApiService(token: token);
      final data = await apiService.getRequest(userMasterGet);
      final users = (data['users'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addOrUpdateUser(UserModel user, String token) async {
    try {
      final apiService = ApiService(token: token);
      // Backend expects POST for both add & update
      await apiService.postRequest(userMasterEndpoint, user.toJson());
      await fetchUsers(token);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<void> changeStatus(String id, bool active, String token) async {
    try {
      final apiService = ApiService(token: token);
      await apiService.putRequest("$userMasterEndpoint/$id/status", {
        "active": active,
      });
      await fetchUsers(token);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
