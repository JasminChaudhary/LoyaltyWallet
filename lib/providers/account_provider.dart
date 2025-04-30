import 'dart:convert';

import 'package:LoyaltyWallet/models/account.dart';
import 'package:LoyaltyWallet/utils/preferences.dart';
import 'package:LoyaltyWallet/utils/url.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AccountProvider with ChangeNotifier {
  // temporary values used for onboarding
  String phoneNumber = '';
  String token = '';
  bool newClient = false;

  // general signals
  bool loading = false;
  String errorMessage = '';

  Account account = Account.fromEmpty();

  AccountProvider() {
    loadAccount();
  }

  loadAccount() async {
    token = await getToken();
    account = await getAccount();

    notifyListeners();
  }

  setLoading(bool newLoading) {
    loading = newLoading;
    notifyListeners();
  }

  setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  Future<void> onboarding(String phone) async {
    phoneNumber = phone;

    // Special handling for web platform
    if (kIsWeb) {
      // For web platform, we'll simulate the SMS verification flow
      // without actually sending SMS (which likely won't work on web)
      setLoading(true);
      
      // Simulate a network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Set a simulated token and newClient status for web
      token = 'web-simulated-token-${DateTime.now().millisecondsSinceEpoch}';
      newClient = true;
      
      setLoading(false);
      setError('');
      return;
    }

    // Normal flow for mobile platforms
    setLoading(true);
    final res = await http.post(Uri.parse('$apiURL/accounts/onboarding'),
        headers: basicHeader,
        body: jsonEncode(<String, String>{
          'phone': phone,
        }));

    final body = json.decode(utf8.decode(res.bodyBytes));
    final statusCode = res.statusCode;

    setLoading(false);

    if (statusCode == 200) {
      newClient = body['newClient'];
      token = body['token'];

      notifyListeners();
      setError('');
    } else {
      setError(body['message']);
    }
  }

  Future<void> verifyCode(String code) async {
    // Special handling for web platform
    if (kIsWeb) {
      // For web testing, we'll accept any 4-digit code
      setLoading(true);
      
      // Simulate a network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Set a simulated token
      token = 'web-verified-token-${DateTime.now().millisecondsSinceEpoch}';
      setToken(token);
      
      // Create a dummy account for web testing
      account = Account(
        id: 'web-user-id',
        firstName: 'Web',
        lastName: 'User',
        phone: phoneNumber,
      );
      setAccount(account);
      
      setLoading(false);
      setError('');
      return;
    }

    // Normal flow for mobile platforms
    setLoading(true);
    final res =
        await http.post(Uri.parse('$apiURL/accounts/onboarding/verify-code'),
            headers: authHeader(token),
            body: jsonEncode(<String, dynamic>{
              'code': code,
              'newClient': newClient,
            }));

    final body = json.decode(utf8.decode(res.bodyBytes));
    final statusCode = res.statusCode;

    setLoading(false);

    if (statusCode == 200) {
      token = body['token'];
      setToken(token);

      account = Account.fromJSON(body['account']);
      setAccount(account);
      account = await getAccount();

      notifyListeners();
      setError('');
    } else {
      setError(body['message']);
    }
  }

  Future<void> addName(String firstName, String lastName) async {
    // Special handling for web platform
    if (kIsWeb) {
      setLoading(true);
      
      // Simulate a network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Update the web account with provided name
      account = Account(
        id: 'web-user-id',
        firstName: firstName,
        lastName: lastName,
        phone: phoneNumber,
      );
      setAccount(account);
      
      setLoading(false);
      setError('');
      return;
    }

    setLoading(true);
    final res = await http.post(Uri.parse('$apiURL/accounts/onboarding/name'),
        headers: authHeader(token),
        body: jsonEncode(<String, dynamic>{
          'firstName': firstName,
          'lastName': lastName,
        }));

    final body = json.decode(utf8.decode(res.bodyBytes));
    final statusCode = res.statusCode;

    setLoading(false);

    if (statusCode == 200) {
      token = body['token'];
      setToken(token);

      account = Account.fromJSON(body['account']);
      setAccount(account);
      account = await getAccount();

      setError('');
    } else {
      setError(body['message']);
    }
  }

  deleteAccount() async {
    if (kIsWeb) {
      logout();
      setError('');
      return;
    }
    
    setLoading(true);
    final res = await http.delete(
      Uri.parse('$apiURL/accounts'),
      headers: authHeader(token),
    );

    final statusCode = res.statusCode;

    setLoading(false);

    if (statusCode == 200) {
      logout();
      setError('');
    }
  }

  logout() {
    account = Account.fromEmpty();
    token = '';
    notifyListeners();

    removeAccount();
    removeToken();
  }
}
