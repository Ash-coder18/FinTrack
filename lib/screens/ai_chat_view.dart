import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_translations.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AiChatView extends StatefulWidget {
  const AiChatView({super.key});
  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  final List<ChatMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _userName = 'User';
  String _userProfession = 'General User';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    setState(() {
      _userName = (meta?['full_name'] as String?)?.isNotEmpty == true ? meta!['full_name'] as String : 'User';
      _userProfession = (meta?['profession'] as String?)?.isNotEmpty == true ? meta!['profession'] as String : 'General User';
      if (messages.isEmpty) {
        final lang = Provider.of<SettingsProvider>(context, listen: false).languageLabel;
        final t = AppTranslations.of(lang);
        messages.add(ChatMessage(text: "${t['ai_greeting_1']!}$_userName${t['ai_greeting_2']!}", isUser: false, timestamp: DateTime.now().subtract(const Duration(minutes: 5))));
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<String> _getFinancialContext() async {
    final response = await Supabase.instance.client.from('transactions').select().eq('user_id', Supabase.instance.client.auth.currentUser!.id).order('created_at', ascending: false).limit(30);
    final transactions = response as List<dynamic>;
    if (transactions.isEmpty) return 'No transaction data available yet.';
    return transactions.map((t) {
      final date = t['created_at'].toString().split('T').first;
      return 'Date: $date, Category: ${t['category']}, Amount: ${t['amount']}, Type: ${t['type']}';
    }).join('\n');
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    setState(() {
      messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();
    try {
      final contextData = await _getFinancialContext();
      final systemPrompt = 'You are the FinTrack AI, a friendly, human-like financial assistant. You are chatting with $_userName, whose profession is $_userProfession. Talk normally like a real person—be conversational, empathetic, and casual. Tailor your financial advice to their profession. Keep responses concise for a mobile chat interface.';
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: 'AIzaSyA8lxEscYsvGVP6esFjoLU5y0xEJh2QB8M', systemInstruction: Content.system(systemPrompt));
      final prompt = "Here is my transaction data:\n$contextData\n\nMy question is: $text";
      final response = await model.generateContent([Content.text(prompt)]);
      setState(() { messages.add(ChatMessage(text: response.text?.trim() ?? "I failed to process that request.", isUser: false, timestamp: DateTime.now())); });
    } catch (e) {
      setState(() { messages.add(ChatMessage(text: "Error communicating with AI: $e", isUser: false, timestamp: DateTime.now())); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  void dispose() { _controller.dispose(); _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SettingsProvider>(context).languageLabel;
    final t = AppTranslations.of(lang);
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(t['ai_assistant']!, style: TextStyle(color: cs.onSurface, fontSize: 18, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Clear Chat', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18)),
                content: Text('Are you sure you want to delete this chat history?', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('Cancel', style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() { 
                        messages.clear(); 
                        messages.add(ChatMessage(text: "${t['ai_greeting_1']!}$_userName${t['ai_greeting_2']!}", isUser: false, timestamp: DateTime.now())); 
                      });
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Delete', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.error)),
                  ),
                ],
              ),
            );
          }, 
          icon: Icon(Icons.cleaning_services_rounded, color: cs.onSurfaceVariant), 
          splashRadius: 24, 
          tooltip: t['clear_chat']!
        ),
      ])),
      Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(20), itemCount: messages.length + (_isLoading ? 1 : 0), itemBuilder: (context, index) {
        if (index == messages.length) {
          return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 24.0), padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: AppColors.secondaryLight, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20))), child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))));
        }
        final msg = messages[index];
        final timeString = DateFormat('h:mm a').format(msg.timestamp);
        return Padding(padding: const EdgeInsets.only(bottom: 24.0), child: Column(crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Container(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: msg.isUser ? AppColors.primary : AppColors.secondaryLight, borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: Radius.circular(msg.isUser ? 20 : 0), bottomRight: Radius.circular(msg.isUser ? 0 : 20))),
            child: Text(msg.text, style: TextStyle(fontFamily: 'SF Pro', fontSize: 15, height: 1.4, fontWeight: FontWeight.w400, color: msg.isUser ? AppColors.white : Colors.black87))),
          const SizedBox(height: 6),
          Text(timeString, style: TextStyle(fontFamily: 'SF Pro', fontSize: 12, color: cs.onSurfaceVariant)),
        ]));
      })),
      Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), decoration: BoxDecoration(color: cs.surface), child: Row(children: [
        Expanded(child: TextField(controller: _controller, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendMessage(), decoration: InputDecoration(hintText: t['type_here']!, hintStyle: const TextStyle(fontFamily: 'SF Pro', fontSize: 15, fontStyle: FontStyle.italic, color: AppColors.textHint), filled: true, fillColor: cs.surfaceContainerHighest, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: cs.outlineVariant)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: cs.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: cs.outlineVariant)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)), style: TextStyle(fontFamily: 'SF Pro', fontSize: 15, color: cs.onSurface))),
        const SizedBox(width: 8),
        IconButton(onPressed: _sendMessage, icon: Icon(Icons.send, color: cs.onSurface, size: 28), splashRadius: 24),
      ])),
    ]);
  }
}
