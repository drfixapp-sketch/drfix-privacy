import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/data/repositories/technician_break_repository.dart';

class TechnicianBreakScreen extends ConsumerStatefulWidget {
  const TechnicianBreakScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TechnicianBreakScreen> createState() => _TechnicianBreakScreenState();
}

class _TechnicianBreakScreenState extends ConsumerState<TechnicianBreakScreen> {
  final TechnicianBreakRepository _repository = TechnicianBreakRepository();

  BreakItemType? _selectedType;
  TechnicianBreakItem? _currentItem;
  bool _isLoading = false;
  bool _showAnswer = false;
  int? _userSelectedOption;

  void _loadItem(BreakItemType type) async {
    setState(() {
      _selectedType = type;
      _isLoading = true;
      _showAnswer = false;
      _userSelectedOption = null;
    });

    final item = await _repository.fetchBreakItem(type);

    if (mounted) {
      setState(() {
        _currentItem = item;
        _isLoading = false;
      });
    }
  }

  void _resetSelection() {
    setState(() {
      _selectedType = null;
      _currentItem = null;
      _isLoading = false;
      _showAnswer = false;
      _userSelectedOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';

    final Map<String, String> txt = isRtl
        ? {
            'app_bar': '☕ استراحة Dr. Fix',
            'title': 'استراحة Dr. Fix ☕',
            'subtitle': 'خذ دقيقة من وقتك، اختبر معلوماتك واستمتع باستراحة فنية قصيرة.',
            'cat_joke': '😂 نكتة فنية',
            'cat_riddle': '🧠 لغز هندسي',
            'cat_challenge': '⚡ تحدي فني سريع',
            'cat_fact': '💡 هل تعلم؟',
            'loading': 'جاري إعداد فنجان القهوة وتحضير المحتوى... ☕',
            'reveal_answer': '👁️ إظهار الحل والتفسير الهندسي',
            'hide_answer': '🙈 إخفاء الحل',
            'another': '🔄 محتوى آخر',
            'change_cat': '⬅️ اختيار قسم آخر',
            'correct': '🎉 إجابة صحيحة! أحسنت يا مهندس.',
            'incorrect': '❌ إجابة غير صحيحة، حاول مجدداً.',
            'explanation_title': '💡 التفسير الفني والهندسي:',
          }
        : {
            'app_bar': '☕ Dr. Fix Lounge',
            'title': 'Dr. Fix Lounge ☕',
            'subtitle': 'Take a minute, test your knowledge, and enjoy a quick technical break.',
            'cat_joke': '😂 Tech Joke',
            'cat_riddle': '🧠 Engineering Riddle',
            'cat_challenge': '⚡ Quick Challenge',
            'cat_fact': '💡 Did You Know?',
            'loading': 'Preparing your coffee & technical content... ☕',
            'reveal_answer': '👁️ Reveal Solution & Explanation',
            'hide_answer': '🙈 Hide Solution',
            'another': '🔄 Another One',
            'change_cat': '⬅️ Change Category',
            'correct': '🎉 Correct Answer! Great job engineer.',
            'incorrect': '❌ Incorrect answer, try again.',
            'explanation_title': '💡 Engineering Explanation:',
          };

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F75BC),
          elevation: 0,
          title: Text(
            txt['app_bar']!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.local_cafe_rounded, color: Color(0xFFF59E0B), size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  txt['title']!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F75BC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            txt['subtitle']!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Content State or Category Selection
                    if (_selectedType == null)
                      _buildCategorySelector(txt)
                    else if (_isLoading)
                      _buildLoadingView(txt['loading']!)
                    else if (_currentItem != null)
                      _buildItemCard(isRtl, txt),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(Map<String, String> txt) {
    return Column(
      children: [
        _buildCategoryCard(
          title: txt['cat_joke']!,
          subtitle: 'نكت ومواقف طريفة من الورش',
          icon: Icons.sentiment_very_satisfied_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () => _loadItem(BreakItemType.joke),
        ),
        const SizedBox(height: 12),
        _buildCategoryCard(
          title: txt['cat_riddle']!,
          subtitle: 'ألغاز هندسية تحتاج تفكير ميكانيكي وكهربائي',
          icon: Icons.psychology_rounded,
          color: const Color(0xFF0F75BC),
          onTap: () => _loadItem(BreakItemType.riddle),
        ),
        const SizedBox(height: 12),
        _buildCategoryCard(
          title: txt['cat_challenge']!,
          subtitle: 'تحدي سريع من 4 اختيارات واختبار دقة التشخيص',
          icon: Icons.bolt_rounded,
          color: const Color(0xFF10B981),
          onTap: () => _loadItem(BreakItemType.challenge),
        ),
        const SizedBox(height: 12),
        _buildCategoryCard(
          title: txt['cat_fact']!,
          subtitle: 'حقائق ومعلومات هندسية موثوقة وغريبة',
          icon: Icons.lightbulb_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => _loadItem(BreakItemType.funFact),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(String loadingText) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF0F75BC)),
          const SizedBox(height: 20),
          Text(
            loadingText,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(bool isRtl, Map<String, String> txt) {
    final item = _currentItem!;
    final String title = isRtl ? item.titleAr : item.titleEn;
    final String content = isRtl ? item.contentAr : item.contentEn;
    final String? answer = isRtl ? item.answerAr : item.answerEn;
    final String? explanation = isRtl ? item.explanationAr : item.explanationEn;
    final List<String>? options = isRtl ? item.optionsAr : item.optionsEn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Category Badge & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.isNotEmpty ? title : txt['app_bar']!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F75BC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.type.name.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // Main Content Text
              Text(
                content,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.6, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Challenge Options
              if (item.type == BreakItemType.challenge && options != null && options.isNotEmpty)
                Column(
                  children: List.generate(options.length, (index) {
                    final isSelected = _userSelectedOption == index;
                    final isCorrect = item.correctOption == index;

                    Color btnColor = const Color(0xFFF8FAFC);
                    Color borderColor = const Color(0xFFE2E8F0);
                    Color textColor = const Color(0xFF334155);

                    if (_userSelectedOption != null) {
                      if (isCorrect) {
                        btnColor = Colors.green.shade50;
                        borderColor = Colors.green;
                        textColor = Colors.green.shade900;
                      } else if (isSelected) {
                        btnColor = Colors.red.shade50;
                        borderColor = Colors.red;
                        textColor = Colors.red.shade900;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: _userSelectedOption == null
                            ? () {
                                setState(() {
                                  _userSelectedOption = index;
                                  _showAnswer = true;
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: btnColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}. ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                              ),
                              Expanded(
                                child: Text(
                                  options[index],
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                                ),
                              ),
                              if (_userSelectedOption != null && isCorrect)
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                              if (_userSelectedOption != null && isSelected && !isCorrect)
                                const Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

              // Result Banner for Challenge
              if (item.type == BreakItemType.challenge && _userSelectedOption != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _userSelectedOption == item.correctOption ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _userSelectedOption == item.correctOption ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    _userSelectedOption == item.correctOption ? txt['correct']! : txt['incorrect']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _userSelectedOption == item.correctOption ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                ),
              ],

              // Riddle Toggle Answer Button
              if (item.type == BreakItemType.riddle && answer != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F75BC),
                    side: const BorderSide(color: Color(0xFF0F75BC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAnswer = !_showAnswer;
                    });
                  },
                  icon: Icon(_showAnswer ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                  label: Text(
                    _showAnswer ? txt['hide_answer']! : txt['reveal_answer']!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              // Solution / Explanation Section
              if (_showAnswer && (answer != null || explanation != null)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (answer != null && answer.isNotEmpty) ...[
                        Text(
                          '✅ $answer',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (explanation != null && explanation.isNotEmpty) ...[
                        Text(
                          txt['explanation_title']!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          explanation,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bottom Actions: Another Item & Change Category
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F75BC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => _loadItem(_selectedType!),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  txt['another']!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              onPressed: _resetSelection,
              child: Text(
                txt['change_cat']!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
