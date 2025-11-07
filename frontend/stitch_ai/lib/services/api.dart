import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/fabric.dart';

class APIService {
  static const int _defaultPort = 8000;

  static String baseUrl() {
    // Use Android emulator loopback for mobile; localhost for web preview
    if (kIsWeb) {
      return 'http://localhost:$_defaultPort';
    }
    return 'http://10.0.2.2:$_defaultPort';
  }

  static Uri _endpoint(String path) => Uri.parse('${baseUrl()}$path');

  static Future<List<Fabric>> recommendFabrics({
    String? material,
    String? color,
    String? pattern,
  }) async {
    final payload = <String, dynamic>{};
    if (material != null && material.trim().isNotEmpty) payload['material'] = material.trim();
    if (color != null && color.trim().isNotEmpty) payload['color'] = color.trim();
    if (pattern != null && pattern.trim().isNotEmpty) payload['pattern'] = pattern.trim();

    final resp = await http.post(
      _endpoint('/recommend-fabrics/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body);
      if (data is List) {
        return data.map((e) => Fabric.fromJson(e as Map<String, dynamic>)).toList();
      }
      return const [];
    } else {
      throw Exception('Backend error ${resp.statusCode}: ${resp.body}');
    }
  }
}