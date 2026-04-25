import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/byok_settings.dart';
import '../models/sources.dart';
import '../models/user_prefs.dart';
import '../providers.dart';
import '../services/byok_summarizer.dart';
import '../widgets/bottom_banner.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPrefsProvider);
    final isKo = prefsAsync.maybeWhen(
        data: (p) => p.language == 'ko', orElse: () => true);

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '설정' : 'Settings')),
      bottomNavigationBar: const BottomBanner(),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (prefs) => _Body(prefs: prefs),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final UserPrefs prefs;
  const _Body({required this.prefs});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late UserPrefs _local;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _local = widget.prefs;
  }

  bool get _isKo => _local.language == 'ko';

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved =
          await ref.read(supabaseServiceProvider).savePrefs(_local);
      ref.invalidate(userPrefsProvider);
      setState(() => _local = saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isKo ? '저장됨' : 'Saved'),
            duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (h, m) = _local.notifyHourMinute;
    return ListView(
      children: [
        _Section(
          title: _isKo ? '알림' : 'Notifications',
          children: [
            SwitchListTile(
              title: Text(_isKo ? '알림 받기' : 'Receive notifications'),
              value: _local.enabled,
              onChanged: _saving
                  ? null
                  : (v) {
                      setState(() => _local = _local.copyWith(enabled: v));
                      _save();
                    },
            ),
            ListTile(
              title: Text(_isKo ? '알림 시간' : 'Notification time'),
              subtitle: Text(
                  '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} KST'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _saving ? null : _pickTime,
            ),
          ],
        ),
        _Section(
          title: _isKo ? '언어' : 'Language',
          children: [
            RadioGroup<String>(
              groupValue: _local.language,
              onChanged: (String? v) {
                if (_saving || v == null) return;
                setState(() => _local = _local.copyWith(
                      language: v,
                      languageExplicit: true,
                    ));
                _save();
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    title: Text('한국어'),
                    value: 'ko',
                  ),
                  RadioListTile<String>(
                    title: Text('English'),
                    value: 'en',
                  ),
                ],
              ),
            ),
          ],
        ),
        _Section(
          title: _isKo ? '소스 선택' : 'Sources',
          children: [
            for (final s in kAllSources)
              CheckboxListTile(
                title: Text(kSourceDisplayNames[s]!),
                value: _local.enabledSources.contains(s),
                onChanged: _saving
                    ? null
                    : (v) {
                        final next = List<String>.from(_local.enabledSources);
                        if (v == true) {
                          if (!next.contains(s)) next.add(s);
                        } else {
                          next.remove(s);
                        }
                        setState(
                            () => _local = _local.copyWith(enabledSources: next));
                        _save();
                      },
              ),
          ],
        ),
        _Section(
          title: _isKo ? '프리미엄 요약 (선택)' : 'Premium Summaries (Optional)',
          children: [_ByokTile(isKo: _isKo)],
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final (h, m) = _local.notifyHourMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (picked == null) return;
    final newTime =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    setState(() => _local = _local.copyWith(notifyTime: newTime));
    await _save();
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ByokTile extends ConsumerStatefulWidget {
  final bool isKo;
  const _ByokTile({required this.isKo});
  @override
  ConsumerState<_ByokTile> createState() => _ByokTileState();
}

class _ByokTileState extends ConsumerState<_ByokTile> {
  ByokProvider _provider = ByokProvider.none;
  final _keyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  bool get _isKo => widget.isKo;

  void _seed(ByokSettings s) {
    if (_seeded) return;
    _provider = s.provider;
    _keyCtrl.text = s.apiKey;
    _modelCtrl.text = s.modelOverride ?? '';
    _seeded = true;
  }

  Future<void> _save({required bool validateFirst}) async {
    final settings = ByokSettings(
      provider: _provider,
      apiKey: _keyCtrl.text.trim(),
      modelOverride:
          _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
    );
    if (settings.provider != ByokProvider.none && settings.apiKey.isEmpty) {
      _toast(_isKo ? 'API 키를 입력하세요' : 'Enter an API key');
      return;
    }
    setState(() => _busy = true);
    try {
      if (validateFirst && settings.isActive) {
        final s = ByokSummarizer(settings);
        try {
          await s.validateKey();
        } finally {
          s.close();
        }
      }
      await ref.read(byokStorageProvider).save(settings);
      ref.invalidate(byokSettingsProvider);
      _toast(_isKo ? '저장됨' : 'Saved');
    } catch (e) {
      _toast(_isKo ? '실패: $e' : 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(byokSettingsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ListTile(title: Text(e.toString())),
      data: (loaded) {
        _seed(loaded);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isKo
                    ? '본인의 API 키로 더 높은 품질의 요약을 받습니다. 키는 휴대폰 보안 저장소에만 저장됩니다.'
                    : 'Use your own API key for higher-quality summaries. '
                        'Keys stay in device secure storage only.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ByokProvider>(
                initialValue: _provider,
                decoration: InputDecoration(
                  labelText: _isKo ? '제공자' : 'Provider',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final p in ByokProvider.values)
                    DropdownMenuItem(value: p, child: Text(p.displayName)),
                ],
                onChanged: _busy
                    ? null
                    : (p) => setState(() => _provider = p ?? ByokProvider.none),
              ),
              if (_provider != ByokProvider.none) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _keyCtrl,
                  obscureText: _obscure,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'API key',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelCtrl,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: _isKo ? '모델 (선택)' : 'Model (optional)',
                    hintText: _defaultModelHint(_provider),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_provider != ByokProvider.none) ...[
                    OutlinedButton(
                      onPressed: _busy ? null : () => _save(validateFirst: true),
                      child: Text(_isKo ? '테스트 & 저장' : 'Test & Save'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: _busy ? null : () => _save(validateFirst: false),
                    child: Text(_isKo ? '저장만' : 'Save only'),
                  ),
                  const Spacer(),
                  if (_busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _defaultModelHint(ByokProvider p) => switch (p) {
        ByokProvider.openai => 'gpt-4o-mini',
        ByokProvider.gemini => 'gemini-2.0-flash',
        ByokProvider.claude => 'claude-haiku-4-5',
        ByokProvider.none => '',
      };
}
