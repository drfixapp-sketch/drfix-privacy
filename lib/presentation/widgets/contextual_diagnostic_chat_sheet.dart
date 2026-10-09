import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../data/models/diagnostic_report_model.dart';
import '../../data/network/ai_config.dart';
import 'stt_helper.dart';

/// نموذج رسالة المحادثة السياقية بين الفني والمساعد الذكي
class DiagnosticChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  DiagnosticChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'sender': isUser ? 'technician' : 'assistant',
    'message': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DiagnosticChatMessage.fromJson(Map<String, dynamic> json) => DiagnosticChatMessage(
    text: json['message'] as String? ?? '',
    isUser: (json['sender'] as String? ?? 'technician') == 'technician',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
  );
}

/// واجهة المحادثة السياقية المنبثقة المستقلة (Contextual Diagnostic Chat Sheet)
class ContextualDiagnosticChatSheet extends StatefulWidget {
  final DiagnosticReportModel report;
  final String? initialQuestion;
  final List<String> initialImages;
  final List<DiagnosticChatMessage> chatHistory;
  final bool isRtl;

  const ContextualDiagnosticChatSheet({
    Key? key,
    required this.report,
    this.initialQuestion,
    this.initialImages = const [],
    this.chatHistory = const [],
    required this.isRtl,
  }) : super(key: key);

  @override
  State<ContextualDiagnosticChatSheet> createState() => _ContextualDiagnosticChatSheetState();
}

class _ContextualDiagnosticChatSheetState extends State<ContextualDiagnosticChatSheet> {
  final List<DiagnosticChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Speech-to-text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _messages.addAll(widget.chatHistory);

    // إضافة رسالة ترحيبية استرشادية أولى إن كانت المحادثة فارغة
    if (_messages.isEmpty) {
      _messages.add(DiagnosticChatMessage(
        text: widget.isRtl
            ? 'مرحباً بك! أنا مستشارك الهندسي الذكي لهذا العطل. يمكنك سؤالي عن تفاصيل الفحص، أسباب العطل، أو كيفية قياس القطع المشتبه بها.'
            : 'Welcome! I am your AI engineering assistant for this fault. Ask me anything about inspection steps, fault causes, or testing suspected components.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    _initSpeech();

    // إرسال السؤال المبدئي تلقائياً إن وُجد
    if (widget.initialQuestion != null && widget.initialQuestion!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendUserMessage(widget.initialQuestion!.trim());
      });
    }
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
        options: [stt.SpeechToText.webDoNotAggregate],
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendUserMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = DiagnosticChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final responseText = await _queryOpenRouter(text.trim());
      if (mounted) {
        setState(() {
          _messages.add(DiagnosticChatMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(DiagnosticChatMessage(
            text: widget.isRtl
                ? 'تعذر الاتصال بالمساعد الذكي حالياً. يرجى التحقق من اتصال الإنترنت والمحاولة ثانية.'
                : 'Unable to reach the assistant right now. Please check your network and try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<String> _queryOpenRouter(String userQuestion) async {
    final apiKey = AiConfig.openRouterApiKey;
    final model = (dotenv.env['OPENROUTER_MODEL']?.trim().isNotEmpty == true)
        ? dotenv.env['OPENROUTER_MODEL']!.trim()
        : 'qwen/qwen3.8-27b:free';

    final deviceName = widget.report.primaryDiagnosis.faultName;
    final explanation = widget.report.primaryDiagnosis.mechanicalExplanation;
    final causes = widget.report.differentialDiagnoses.map((d) => '${d.faultName} (${d.probability}%)').join(', ');
    final steps = widget.report.actionableSteps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join(' | ');
    final parts = widget.report.potentialPartsToInspect.join(', ');

    final systemPrompt = '''
أنت مستشار الصيانة الميداني وخبير الأعطال لـ Dr. Fix.
أنت تجري الآن محادثة هندسية مباشرة مع فني في موقع العمل لمساعدته في استفساراته حول التقرير التشخيصي التالي:
- اسم الجهاز/العطل: $deviceName
- التفسير الميكانيكي: $explanation
- الأسباب المحتملة: $causes
- خطوات الفحص المقترحة: $steps
- قطع الغيار المشتبه بها: $parts

إرشادات هامة:
1. أجب عن استفسار الفني باختصار ودقة هندسية عالية وبشكل مباشر ومفيد ميدانياً.
2. ركز على إجراءات السلامة وقيم القياس المعيارية وطرق فحص المكونات.
3. اكتب الرد بنص عادي ومنظم (Markdown)، ولا تُرجع أي كود JSON نهائياً.
4. اللغة: ${widget.isRtl ? 'اللغة العربية التقنية' : 'English'}.
''';

    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    // إرفاق تاريخ المحادثة
    for (final m in _messages) {
      if (m.text.isNotEmpty) {
        messages.add({
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text,
        });
      }
    }

    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 40);
    dio.options.receiveTimeout = const Duration(seconds: 40);

    final res = await dio.post(
      'https://openrouter.ai/api/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        if (!kIsWeb) 'Referer': 'https://openrouter.ai/',
        'X-Title': 'Dr Fix Contextual Chat',
      }),
      data: {
        'model': model,
        'messages': messages,
      },
    );

    final content = res.data['choices']?[0]?['message']?['content'];
    if (content != null && content.toString().trim().isNotEmpty) {
      return content.toString().trim();
    }
    return widget.isRtl ? 'تم استلام الاستفسار، ولا توجد توصيات إضافية.' : 'Inquiry received, no additional recommendations.';
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.isRtl;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // مقبض السحب
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // الرأس (Header)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F75BC).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Color(0xFF0F75BC), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRtl ? 'المساعد الهندسي الميداني' : 'Field Engineering Assistant',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            Text(
                              widget.report.primaryDiagnosis.faultName.isNotEmpty
                                  ? widget.report.primaryDiagnosis.faultName
                                  : (isRtl ? 'سياق العطل الحالي' : 'Active Fault Context'),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: 'Tajawal',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isRtl ? 'إغلاق والعودة للتقرير' : 'Close and back to report',
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(context, _messages),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // قائمة الرسائل
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return Align(
                          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F75BC)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isRtl ? 'جاري التفكير وصياغة التوصية...' : 'Thinking...',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'Tajawal'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
                            : (isRtl ? Alignment.centerRight : Alignment.centerLeft),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: msg.isUser ? const Color(0xFF0F75BC) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(msg.isUser ? 14 : 2),
                              bottomRight: Radius.circular(msg.isUser ? 2 : 14),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: msg.isUser ? Colors.white : const Color(0xFF1E293B),
                                  fontFamily: 'Tajawal',
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: msg.isUser ? Colors.white70 : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // شريط إدخال الرسائل
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        // زر الميكروفون
                        IconButton(
                          tooltip: isRtl ? 'تسجيل صوتي' : 'Voice input',
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.red : const Color(0xFF0F75BC),
                          ),
                          onPressed: () async {
                            if (_isListening) {
                              await _speech.stop();
                              setState(() => _isListening = false);
                            } else {
                              if (!_speechAvailable) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(isRtl ? 'التعرف الصوتي غير متوفر' : 'Speech not available'),
                                ));
                                return;
                              }
                              setState(() => _isListening = true);
                              final localeId = await resolveBestSttLocale(_speech, isRtl);
                              await _speech.listen(
                                onResult: (result) {
                                  if (mounted) {
                                    setState(() {
                                      _inputController.text = result.recognizedWords;
                                    });
                                  }
                                },
                                localeId: localeId,
                                listenMode: stt.ListenMode.dictation,
                                listenFor: const Duration(seconds: 30),
                                pauseFor: const Duration(seconds: 4),
                                listenOptions: stt.SpeechListenOptions(
                                  localeId: localeId,
                                  listenMode: stt.ListenMode.dictation,
                                  partialResults: true,
                                  cancelOnError: false,
                                ),
                              );
                            }
                          },
                        ),
                        // حقل النص
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            minLines: 1,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 13, fontFamily: 'Tajawal'),
                            decoration: InputDecoration(
                              hintText: isRtl ? 'اكتب استفسارك الهندسي هنا...' : 'Type your technical question...',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontFamily: 'Tajawal'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Color(0xFF0F75BC), width: 1.5),
                              ),
                            ),
                            onSubmitted: (val) => _sendUserMessage(val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // زر الإرسال
                        Material(
                          color: const Color(0xFF0F75BC),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _isLoading ? null : () => _sendUserMessage(_inputController.text),
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
