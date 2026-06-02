import 'dart:convert';

import 'package:http/http.dart' as http;

import 'secrets.dart';

/// 智谱 GLM 一条聊天消息。
class GlmMessage {
  const GlmMessage({required this.role, required this.content});
  final String role; // system / user / assistant
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// 智谱 GLM HTTP 客户端（OpenAI 兼容风格）。
///
/// API: https://open.bigmodel.cn/api/paas/v4/chat/completions
/// 鉴权：`Authorization: Bearer <API_KEY>`
class GlmClient {
  GlmClient({
    String? apiKey,
    this.baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    this.timeout = const Duration(seconds: 30),
    http.Client? httpClient,
  })  : _apiKey = apiKey ?? Secrets.glmApiKey,
        _http = httpClient ?? http.Client();

  final String _apiKey;
  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  /// 发起一次聊天补全。
  ///
  /// [messages] 含 system / user / assistant 角色；
  /// [temperature] 控制随机性；
  /// [responseFormat] 可选 `{"type":"json_object"}` 强制 JSON 输出。
  Future<String> chat({
    required String model,
    required List<GlmMessage> messages,
    double temperature = 0.7,
    Map<String, dynamic>? responseFormat,
  }) async {
    final Map<String, dynamic> payload = {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
    };
    if (responseFormat != null) {
      payload['response_format'] = responseFormat;
    }

    final http.Response resp = await _http
        .post(
          Uri.parse(baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(json.encode(payload)),
        )
        .timeout(timeout);

    if (resp.statusCode != 200) {
      throw GlmException(
        statusCode: resp.statusCode,
        body: utf8.decode(resp.bodyBytes),
      );
    }

    final Map<String, dynamic> data =
        json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final List<dynamic> choices = data['choices'] as List<dynamic>? ?? const [];
    if (choices.isEmpty) {
      throw GlmException(
        statusCode: resp.statusCode,
        body: 'empty choices',
      );
    }
    final Map<String, dynamic> first = choices.first as Map<String, dynamic>;
    final Map<String, dynamic> message =
        first['message'] as Map<String, dynamic>;
    return (message['content'] as String?) ?? '';
  }

  void close() => _http.close();
}

class GlmException implements Exception {
  GlmException({required this.statusCode, required this.body});
  final int statusCode;
  final String body;

  @override
  String toString() => 'GlmException($statusCode): $body';
}
