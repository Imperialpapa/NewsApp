import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sources.dart';
import '../models/user_prefs.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPrefsProvider);
    final isKo = prefsAsync.maybeWhen(
        data: (p) => p.language == 'ko', orElse: () => true);

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '설정' : 'Settings')),
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
