import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import '../services/registration_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final _service = RegistrationService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<RegistrationModel>> getUserRegistrations(String userId) {
    return _service.getUserRegistrations(userId);
  }

  Stream<List<RegistrationModel>> getEventRegistrations(String eventId) {
    return _service.getEventRegistrations(eventId);
  }

  Future<RegistrationModel?> register({
    required String userId,
    required String userName,
    required EventModel event,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reg = await _service.registerForEvent(
          userId: userId, userName: userName, event: event);
      return reg;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancel(String registrationId, String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.cancelRegistration(registrationId, eventId);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RegistrationModel?> getRegistration(
      String userId, String eventId) async {
    try {
      return await _service.getRegistration(userId, eventId);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
