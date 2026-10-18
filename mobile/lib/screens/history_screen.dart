import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_settings.dart';
import '../services/translation_history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.account,
    required this.isEnglish,
    super.key,
  });

  final GoogleSignInAccount account;
  final bool isEnglish;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = TranslationHistoryService();
  late Future<List<TranslationHistoryEntry>> _history;

  HandTechStrings get _strings => HandTechStrings(widget.isEnglish);

  @override
  void initState() {
    super.initState();
    _history = _historyService.load(widget.account.email);
  }

  Future<void> _clearHistory() async {
    try {
      await _historyService.clear(widget.account.email);
      if (!mounted) return;
      setState(() {
        _history = Future.value(const []);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.historyCleared)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.historyClearError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<List<TranslationHistoryEntry>>(
      future: _history,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Row(
              children: [
                Image.asset('logo.jpeg', width: 40, height: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _strings.historyTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (entries != null && entries.isNotEmpty)
                  IconButton(
                    onPressed: _clearHistory,
                    tooltip: _strings.clearHistory,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_strings.historyLocalOnly),
            const SizedBox(height: 8),
            Text(_strings.historySignRecognitionPending),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              Text(
                '${_strings.historySaveError} ${snapshot.error}',
                style: TextStyle(color: colors.error),
              )
            else if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (entries == null || entries.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_strings.historyEmpty),
                ),
              )
            else
              ...entries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_strings.getLanguageName(entry.sourceLanguage)}'
                                ' → '
                                '${_strings.getLanguageName(entry.targetLanguage)}',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: colors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            Text(
                              _strings.formatHistoryDate(entry.createdAt),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _strings.sourceText,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        SelectableText(entry.text),
                        const SizedBox(height: 8),
                        Text(
                          _strings.translatedText,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        SelectableText(
                          entry.translatedText,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
