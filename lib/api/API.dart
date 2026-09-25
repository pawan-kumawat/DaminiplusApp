import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../Helper/AppAlert.dart';
import '../Helper/AppSharedPreferencesData.dart';
import '../screens/login_screen.dart';
import 'Loader.dart';

class APIService {
  static const String _version = "1.0";

  // ── Common headers ─────────────────────────────────────
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await AppSharedPreferencesData.getToken();
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ── Public header builder (for silent raw calls) ───────
  static Future<Map<String, String>> buildHeaders({bool auth = true}) =>
      _headers(auth: auth);

  // ── Raw GET — returns full response, no alert shown ────
  static Future<http.Response> rawGet(
      String url,
      Map<String, String> headers,
      ) async {
    if (kDebugMode) print("GET ▶ $url");
    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (kDebugMode) {
      print("GET ◀ [${response.statusCode}] ${response.body}");
    }
    return response;
  }

  // ── GET ────────────────────────────────────────────────
  static Future<String> getApiCaller({
    required BuildContext context,
    required String url,
    bool showLoader = true,
    bool auth = true,
  }) async {
    if (showLoader) Loader.showLoader(context);
    try {
      final headers = await _headers(auth: auth);
      if (kDebugMode) print("GET ▶ $url");
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));
      if (kDebugMode) {
        print("GET ◀ [${response.statusCode}] ${response.body}");
      }
      if (showLoader) Loader.hidesLoader(context);
      return await _handleResponse(context, response, auth: auth);
    } on SocketException {
      if (showLoader) Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "No internet connection");
      return "Error";
    } catch (e) {
      if (showLoader) Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "Something went wrong. Please try again.");
      return "Error";
    }
  }

  // ── POST ───────────────────────────────────────────────
  static Future<String> postApiCaller({
    required BuildContext context,
    required String url,
    required Map<String, dynamic> body,
    bool showLoader = true,
    bool auth = true,
  }) async {
    if (showLoader) Loader.showLoader(context);
    try {
      final headers = await _headers(auth: auth);
      if (kDebugMode) print("POST ▶ $url\nBODY: ${jsonEncode(body)}");
      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      if (kDebugMode) {
        print("POST ◀ [${response.statusCode}] ${response.body}");
      }
      if (showLoader) Loader.hidesLoader(context);
      return await _handleResponse(context, response, auth: auth);
    } on SocketException {
      if (showLoader) Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "No internet connection");
      return "Error";
    } catch (e) {
      if (showLoader) Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "Something went wrong. Please try again.");
      return "Error";
    }
  }

  // ── PUT ────────────────────────────────────────────────
  static Future<String> putApiCaller({
    required BuildContext context,
    required String url,
    required Map<String, dynamic> body,
    bool showLoader = true,
    bool auth = true,
  }) async {
    if (showLoader) Loader.showLoader(context);
    try {
      final headers = await _headers(auth: auth);
      if (kDebugMode) print("PUT ▶ $url\nBODY: ${jsonEncode(body)}");
      final response = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      if (kDebugMode) {
        print("PUT ◀ [${response.statusCode}] ${response.body}");
      }
      if (showLoader) Loader.hidesLoader(context);
      return await _handleResponse(context, response, auth: auth);
    } on SocketException {
      if (showLoader) Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "No internet connection");
      return "Error";
    } catch (e) {
      if (showLoader) Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "Something went wrong. Please try again.");
      return "Error";
    }
  }

  // ── DELETE ─────────────────────────────────────────────
  static Future<String> deleteApiCaller({
    required BuildContext context,
    required String url,
    bool showLoader = true,
    bool auth = true,
  }) async {
    if (showLoader) Loader.showLoader(context);
    try {
      final headers = await _headers(auth: auth);
      if (kDebugMode) print("DELETE ▶ $url");
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));
      if (kDebugMode) {
        print("DELETE ◀ [${response.statusCode}] ${response.body}");
      }
      if (showLoader) Loader.hidesLoader(context);
      return await _handleResponse(context, response, auth: auth);
    } on SocketException {
      if (showLoader) Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "No internet connection");
      return "Error";
    } catch (e) {
      if (showLoader) Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "Something went wrong. Please try again.");
      return "Error";
    }
  }

  // ── Multipart POST ─────────────────────────────────────
  static Future<String> uploadFile({
    required BuildContext context,
    required String url,
    required File imageFile,
    String fieldName = 'image',
  }) async {
    Loader.showLoader(context);
    try {
      final token = await AppSharedPreferencesData.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Accept'] = 'application/json';
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, imageFile.path),
      );
      if (kDebugMode) {
        final sizeMb = (await imageFile.length()) / (1024 * 1024);
        print(
          "UPLOAD ▶ $url\nFIELD: $fieldName FILE: ${imageFile.path} SIZE: ${sizeMb.toStringAsFixed(2)} MB",
        );
      }
      final streamed = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamed);
      if (kDebugMode) {
        print("UPLOAD ◀ [${response.statusCode}] ${response.body}");
      }
      Loader.hidesLoader(context);
      return await _handleResponse(context, response, auth: true);
    } on SocketException {
      Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "No internet connection");
      return "Error";
    } catch (e) {
      Loader.hidesLoader(context);
      ShowAlert.showAlert(context, "Upload failed. Please try again.");
      return "Error";
    }
  }

  // Session-level failures — an expired/invalid token (401) or a
  // server crash (500) both mean the current session can't be trusted
  // to keep working, so there's nothing useful the student can do
  // except log back in. Ordinary validation/business errors (400,
  // 403, 404, 409...) are NOT routed here — those carry a message the
  // student needs to read and act on (e.g. "Name is required"),
  // forcing a logout for those would make the app unusable.
  static Future<void> _forceLogout(BuildContext context, String message) async {
    await AppSharedPreferencesData.logout();
    OneSignal.logout();
    if (!context.mounted) return;
    ShowAlert.showAlert(context, message);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── Response handler ───────────────────────────────────
  // [auth] tells us whether this call was even meant to carry a
  // session token — public endpoints (OTP verification during login,
  // etc.) also use 401 for plain validation failures like "Invalid
  // OTP", which is NOT a session problem and must not force a logout
  // while the student is mid-login.
  static Future<String> _handleResponse(BuildContext context, http.Response response, {bool auth = true}) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      final status = json['status'];
      final message = json['message'] ?? '';
      if (status == false) {
        ShowAlert.showAlert(context, message);
        return "Error";
      }
      return response.body;
    }

    if (response.statusCode == 401 && auth) {
      String message = "Your session has expired. Please log in again.";
      try {
        final json = jsonDecode(response.body);
        message = json['message'] ?? message;
      } catch (_) {}
      await _forceLogout(context, message);
      return "Error";
    }

    // Server error — session ke bharose nahi raha ja sakta (ho sakta
    // hai token/user state hi corrupt/inconsistent ho), isliye seedha
    // logout karke login par bhej dete hain instead of showing an
    // error the student can't do anything about.
    if (response.statusCode == 500) {
      String message = "Something went wrong. Please log in again.";
      try {
        final json = jsonDecode(response.body);
        message = json['message'] ?? message;
      } catch (_) {}
      await _forceLogout(context, message);
      return "Error";
    }

    try {
      final json = jsonDecode(response.body);
      final message =
          json['message'] ?? 'Server error (${response.statusCode})';
      ShowAlert.showAlert(context, message);
    } catch (_) {
      ShowAlert.showAlert(context, "Server error (${response.statusCode})");
    }
    return "Error";
  }
}