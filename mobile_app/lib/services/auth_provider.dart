import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    _user = await ApiService.login(email, password);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password, String role) async {
    _user = await ApiService.register(name, email, password, role);
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }
}
