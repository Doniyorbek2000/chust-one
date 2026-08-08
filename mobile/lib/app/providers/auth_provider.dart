import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';

class AppUser {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? avatarUrl;
  final String? city;
  final int? age;
  final String? address;
  final String role;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.avatarUrl,
    this.city,
    this.age,
    this.address,
    this.role = 'STUDENT',
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      city: json['city'] as String?,
      age: json['age'] as int?,
      address: json['address'] as String?,
      role: json['role'] as String? ?? 'STUDENT',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
        'city': city,
        'age': age,
        'address': address,
        'role': role,
      };
}

class AuthState {
  final AppUser? user;
  final String? token;
  final bool isLoading;

  const AuthState({this.user, this.token, this.isLoading = true});

  bool get isLoggedIn => user != null && token != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final StorageService storageService;

  AuthNotifier(this.storageService) : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final token = await storageService.getToken();
    final userJson = await storageService.getUser();
    if (token != null && userJson != null) {
      state = AuthState(user: AppUser.fromJson(userJson), token: token, isLoading: false);
    } else {
      state = const AuthState(isLoading: false);
    }
  }

  Future<void> setSession(String token, Map<String, dynamic> userJson) async {
    await storageService.saveToken(token);
    await storageService.saveUser(userJson);
    state = AuthState(user: AppUser.fromJson(userJson), token: token, isLoading: false);
  }

  Future<void> updateUser(Map<String, dynamic> userJson) async {
    await storageService.saveUser(userJson);
    state = AuthState(user: AppUser.fromJson(userJson), token: state.token, isLoading: false);
  }

  Future<void> logout() async {
    await storageService.clearToken();
    await storageService.clearUser();
    state = const AuthState(isLoading: false);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(storageServiceProvider)));

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(storageServiceProvider));
});
