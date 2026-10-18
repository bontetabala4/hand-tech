import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_settings.dart';
import '../services/nolan_chat_service.dart';

class NolanChatScreen extends StatefulWidget {
  const NolanChatScreen({
    required this.account,
    required this.isEnglish,
    super.key,
  });

  final GoogleSignInAccount? account;
  final bool isEnglish;

  @override
  State<NolanChatScreen> createState() => _NolanChatScreenState();
}

class _NolanChatScreenState extends State<NolanChatScreen> {
  static const _maxMessageLength = 4000;
  final _service = NolanChatService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<NolanChatMessage> _messages = [];
  bool _isSending = false;
  String? _error;

  HandTechStrings get _strings => HandTechStrings(widget.isEnglish);

  @override
  void didUpdateWidget(covariant NolanChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account?.id != widget.account?.id) {
      _messages.clear();
      _error = null;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? suggestedMessage]) async {
    if (_isSending) return;
    final text = (suggestedMessage ?? _inputController.text).trim();
    if (text.isEmpty) return;
    if (text.length > _maxMessageLength) {
      setState(() => _error = _strings.nolanConnectionError);
      return;
    }

    final requestHistory = _messages.length <= 20
        ? List<NolanChatMessage>.of(_messages)
        : List<NolanChatMessage>.of(_messages.skip(_messages.length - 20));
    final accountId = widget.account?.id;

    setState(() {
      _messages.add(NolanChatMessage(role: 'user', content: text));
      _isSending = true;
      _error = null;
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(
        message: text,
        history: requestHistory,
      );
      if (!mounted) return;
      if (widget.account?.id != accountId) return;
      setState(() {
        _messages.add(NolanChatMessage(role: 'assistant', content: reply));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '${_strings.nolanConnectionError}\n$error');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        _NolanHeader(
          isThinking: _isSending,
          subtitle: _strings.nolanHeaderSubtitle,
        ),
        Expanded(
          child: _messages.isEmpty && !_isSending
              ? _WelcomePanel(
                  strings: _strings,
                  onSuggestionSelected: _sendMessage,
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _TypingIndicator(label: _strings.nolanWorking);
                    }
                    return _ChatBubble(message: _messages[index]);
                  },
                ),
        ),
        if (_error case final error?)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              error,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        _MessageComposer(
          controller: _inputController,
          isSending: _isSending,
          strings: _strings,
          onSend: _sendMessage,
        ),
      ],
    );
  }
}

class _NolanHeader extends StatelessWidget {
  const _NolanHeader({required this.isThinking, required this.subtitle});

  final bool isThinking;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071B2D), Color(0xFF0D5262)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isThinking
                    ? const Color(0xFF65F2DC)
                    : const Color(0xFF4AA2C3),
                width: isThinking ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF65F2DC,
                  ).withValues(alpha: isThinking ? 0.45 : 0.15),
                  blurRadius: isThinking ? 18 : 8,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF102D3C),
              child: Icon(Icons.auto_awesome, color: Color(0xFF73F4DF)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nolan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Color(0xFFB5D7DD),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.graphic_eq, color: Color(0xFF73F4DF), size: 24),
        ],
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.strings,
    required this.onSuggestionSelected,
  });

  final HandTechStrings strings;
  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final suggestions = [
      strings.nolanSuggestionAccessibility,
      strings.nolanSuggestionCommunication,
      strings.nolanSuggestionRights,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF0D8794)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.nolanGreeting,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(strings.nolanDescription),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.arrow_outward, size: 16),
                label: Text(suggestion),
                onPressed: () => onSuggestionSelected(suggestion),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final NolanChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final colors = Theme.of(context).colorScheme;
    final background = isUser ? colors.primary : colors.surfaceContainerHigh;
    final foreground = isUser ? colors.onPrimary : colors.onSurface;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(isUser ? 10 * (1 - value) : -10 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 5),
              bottomRight: Radius.circular(isUser ? 5 : 18),
            ),
            border: isUser
                ? null
                : Border.all(color: colors.primary.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SelectableText(
            message.content,
            style: TextStyle(color: foreground, height: 1.4),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.strings,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final HandTechStrings strings;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        10 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              maxLength: _NolanChatScreenState._maxMessageLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: strings.nolanInputHint,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: colors.primary.withValues(alpha: 0.22),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: colors.primary.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final canSend = value.text.trim().isNotEmpty && !isSending;
              return IconButton.filled(
                tooltip: strings.nolanSend,
                onPressed: canSend ? () => onSend(value.text) : null,
                icon: const Icon(Icons.arrow_upward_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0D8794),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(50, 50),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
