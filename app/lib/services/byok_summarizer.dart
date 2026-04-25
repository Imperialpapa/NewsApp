import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/byok_settings.dart';

/// Calls the user's chosen LLM (OpenAI / Gemini / Claude) via each
/// provider's OpenAI-compatible chat-completions endpoint, so a single
/// HTTP shape covers all three. Returns a string of bullet-formatted
/// summary text (newline-separated), matching what the backend stores.
class ByokSummarizer {
  static const _systemPrompt =
      "You are a financial news editor for busy global finance professionals. "
      "You will be given a news headline and snippet. Produce exactly 3 short "
      "bullet points in English. Each bullet is one sentence focused on WHY "
      "it matters to markets (tickers, sectors, macro). No fluff. No intro "
      "phrases like 'This article'. Do NOT prepend dashes, asterisks, or "
      "bullet characters — the client renders bullets. Join the 3 bullets "
      "with a single newline (\\n) inside the summary_en string. "
      "Return strictly this JSON shape and nothing else:\n"
      '{"summary_en": "first bullet\\nsecond bullet\\nthird bullet"}';

  final ByokSettings settings;
  final http.Client _http;

  ByokSummarizer(this.settings, {http.Client? client})
      : _http = client ?? http.Client();

  /// Returns the bullet-formatted English summary, or throws on error.
  Future<String> summarize({
    required String headline,
    required String snippet,
    required String source,
  }) async {
    if (!settings.isActive) {
      throw StateError('BYOK is not active');
    }
    final cfg = _ProviderConfig.forProvider(settings.provider);
    final model = (settings.modelOverride?.trim().isNotEmpty ?? false)
        ? settings.modelOverride!.trim()
        : cfg.defaultModel;

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': 'Source: $source\nHeadline: $headline\n\nSnippet:\n$snippet',
        },
      ],
      'max_tokens': 600,
      'response_format': {'type': 'json_object'},
    });

    final resp = await _http.post(
      Uri.parse('${cfg.baseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${settings.apiKey}',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    if (resp.statusCode >= 400) {
      throw Exception(
        '${settings.provider.displayName} ${resp.statusCode}: ${resp.body}',
      );
    }
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final content = (json['choices'] as List).first['message']['content']
        as String;
    final cleaned = _stripFences(content);
    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    final summary = parsed['summary_en'] as String?;
    if (summary == null || summary.trim().isEmpty) {
      throw Exception('Empty summary_en in response: $content');
    }
    return summary;
  }

  /// One-shot validation call used by the settings "Test" button.
  Future<void> validateKey() async {
    await summarize(
      headline: 'Federal Reserve holds rates steady at September meeting',
      snippet:
          'The Federal Reserve kept its benchmark interest rate unchanged on '
          'Wednesday, citing persistent inflation and a still-resilient labor '
          'market. Markets had priced in a hold.',
      source: 'Test',
    );
  }

  void close() => _http.close();

  static String _stripFences(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      t = t.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return t.trim();
  }
}

class _ProviderConfig {
  final String baseUrl;
  final String defaultModel;

  const _ProviderConfig(this.baseUrl, this.defaultModel);

  static _ProviderConfig forProvider(ByokProvider p) => switch (p) {
        ByokProvider.openai => const _ProviderConfig(
            'https://api.openai.com/v1',
            'gpt-4o-mini',
          ),
        ByokProvider.gemini => const _ProviderConfig(
            'https://generativelanguage.googleapis.com/v1beta/openai',
            'gemini-2.0-flash',
          ),
        ByokProvider.claude => const _ProviderConfig(
            // Anthropic ships an OpenAI-compat shim that accepts the same
            // chat-completions schema as OpenAI.
            'https://api.anthropic.com/v1',
            'claude-haiku-4-5',
          ),
        ByokProvider.none =>
          throw StateError('No provider config for ByokProvider.none'),
      };
}
