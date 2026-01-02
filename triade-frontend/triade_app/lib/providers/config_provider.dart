import 'package:flutter/foundation.dart';
import 'package:triade_app/services/api_service.dart';

class ConfigProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  double _availableHours = 8.0;
  bool _isLoading = false;
  String? _errorMessage;

  double get availableHours => _availableHours;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDailyConfig(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      _availableHours = await _apiService.getDailyConfig(date);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setDailyConfig(DateTime date, double hours) async {
    try {
      await _apiService.setDailyConfig(date, hours);
      _availableHours = hours;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
