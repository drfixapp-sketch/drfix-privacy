import 'dart:math';
import 'package:dr_fix/data/network/ai_api_service.dart';

enum BreakItemType { joke, riddle, challenge, funFact }

class TechnicianBreakItem {
  final BreakItemType type;
  final String titleAr;
  final String titleEn;
  final String contentAr;
  final String contentEn;
  final String? answerAr;
  final String? answerEn;
  final String? explanationAr;
  final String? explanationEn;
  final List<String>? optionsAr;
  final List<String>? optionsEn;
  final int? correctOption;
  final bool? isFactual;

  TechnicianBreakItem({
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
    this.answerAr,
    this.answerEn,
    this.explanationAr,
    this.explanationEn,
    this.optionsAr,
    this.optionsEn,
    this.correctOption,
    this.isFactual,
  });

  factory TechnicianBreakItem.fromJson(Map<String, dynamic> json, BreakItemType requestedType) {
    final String typeStr = (json['type'] ?? '').toString().toLowerCase();
    BreakItemType parsedType = requestedType;
    if (typeStr.contains('joke')) {
      parsedType = BreakItemType.joke;
    } else if (typeStr.contains('riddle')) {
      parsedType = BreakItemType.riddle;
    } else if (typeStr.contains('challenge')) {
      parsedType = BreakItemType.challenge;
    } else if (typeStr.contains('fact')) {
      parsedType = BreakItemType.funFact;
    }

    List<String>? optsAr;
    if (json['optionsAr'] is List) {
      optsAr = (json['optionsAr'] as List).map((e) => e.toString()).toList();
    }

    List<String>? optsEn;
    if (json['optionsEn'] is List) {
      optsEn = (json['optionsEn'] as List).map((e) => e.toString()).toList();
    }

    int? correctIdx;
    if (json['correctOption'] != null) {
      correctIdx = int.tryParse(json['correctOption'].toString());
    }

    return TechnicianBreakItem(
      type: parsedType,
      titleAr: (json['titleAr'] ?? '').toString().trim(),
      titleEn: (json['titleEn'] ?? '').toString().trim(),
      contentAr: (json['contentAr'] ?? '').toString().trim(),
      contentEn: (json['contentEn'] ?? '').toString().trim(),
      answerAr: json['answerAr']?.toString().trim(),
      answerEn: json['answerEn']?.toString().trim(),
      explanationAr: json['explanationAr']?.toString().trim(),
      explanationEn: json['explanationEn']?.toString().trim(),
      optionsAr: optsAr,
      optionsEn: optsEn,
      correctOption: correctIdx,
      isFactual: json['isFactual'] is bool ? json['isFactual'] as bool : true,
    );
  }

  bool isValid(BreakItemType expectedType) {
    if (titleAr.isEmpty || titleEn.isEmpty || contentAr.isEmpty || contentEn.isEmpty) {
      return false;
    }

    switch (expectedType) {
      case BreakItemType.joke:
        return true;
      case BreakItemType.riddle:
        return (answerAr != null && answerAr!.isNotEmpty && answerEn != null && answerEn!.isNotEmpty);
      case BreakItemType.challenge:
        return (optionsAr != null &&
            optionsAr!.length >= 2 &&
            optionsEn != null &&
            optionsEn!.length >= 2 &&
            correctOption != null &&
            correctOption! >= 0 &&
            correctOption! < optionsAr!.length);
      case BreakItemType.funFact:
        return true;
    }
  }
}

class TechnicianBreakRepository {
  final AiApiService _aiApiService;
  final Map<BreakItemType, List<TechnicianBreakItem>> _sessionCache = {};
  final Random _random = Random();

  TechnicianBreakRepository({AiApiService? aiApiService})
      : _aiApiService = aiApiService ?? AiApiService();

  Future<TechnicianBreakItem> fetchBreakItem(BreakItemType type) async {
    try {
      final String prompt = _buildPrompt(type);
      final Map<String, dynamic> response = await _aiApiService.executeStructuredRequest(
        prompt: prompt,
      );

      final item = TechnicianBreakItem.fromJson(response, type);

      if (item.isValid(type)) {
        _cacheItem(type, item);
        return item;
      } else {
        print('⚠️ [TechnicianBreakRepository] Response failed validation. Using fallback item.');
        return _getRandomFallback(type);
      }
    } catch (e) {
      print('⚠️ [TechnicianBreakRepository] Error fetching item from AI: $e. Using fallback item.');
      return _getRandomFallback(type);
    }
  }

  void _cacheItem(BreakItemType type, TechnicianBreakItem item) {
    _sessionCache.putIfAbsent(type, () => []);
    _sessionCache[type]!.add(item);
  }

  List<TechnicianBreakItem> getCachedItems(BreakItemType type) {
    return _sessionCache[type] ?? [];
  }

  String _buildPrompt(BreakItemType type) {
    final StringBuffer sb = StringBuffer();
    sb.writeln('Role: You are a professional, polite, and humorous engineering & maintenance expert assistant for Dr Fix app.');
    sb.writeln('Task: Generate a single item of type: "${type.name}".');
    sb.writeln('BILINGUAL REQUIREMENT: Provide high quality Arabic AND accurate English translation for every string field.');

    sb.writeln('\nSAFETY AND APPROPRIATENESS RULES (STRICT MANDATE):');
    sb.writeln('1. Content must be 100% respectful, professional, clean, and general-audience friendly.');
    sb.writeln('2. Strictly NO racism, discrimination, insults based on nationality, race, religion, gender, or social class.');
    sb.writeln('3. NO bullying, harassment, sexual content, political opinions, or religious controversy.');
    sb.writeln('4. NO derogatory mocking of technicians, mechanics, engineers, or clients.');
    sb.writeln('5. NO incorrect engineering facts or advice that could cause physical injury or machine damage.');
    sb.writeln('6. All engineering facts in riddles/challenges/fun_facts MUST be accurate, standard, and verified.');

    sb.writeln('\nSTRICT JSON OUTPUT SCHEMA ONLY (NO markdown codeblocks, NO text before or after):');

    switch (type) {
      case BreakItemType.joke:
        sb.writeln('''
{
  "type": "joke",
  "titleAr": "نكتة فنية طريفة",
  "titleEn": "Technician Joke",
  "contentAr": "<Humorous workshop/engineering joke in Arabic>",
  "contentEn": "<Accurate English translation of the joke>"
}''');
        break;
      case BreakItemType.riddle:
        sb.writeln('''
{
  "type": "riddle",
  "titleAr": "لغز هندسي ذكي",
  "titleEn": "Engineering Riddle",
  "contentAr": "<Riddle prompt about an electrical/mechanical/HVAC/automotive component or fault in Arabic>",
  "contentEn": "<Accurate English translation of the riddle>",
  "answerAr": "<Direct concise answer in Arabic>",
  "answerEn": "<Direct concise answer in English>",
  "explanationAr": "<Brief technical explanation in Arabic>",
  "explanationEn": "<Brief technical explanation in English>"
}''');
        break;
      case BreakItemType.challenge:
        sb.writeln('''
{
  "type": "challenge",
  "titleAr": "تحدي فني سريع",
  "titleEn": "Quick Diagnostic Challenge",
  "contentAr": "<Diagnostic or technical multiple-choice question in Arabic>",
  "contentEn": "<Accurate English translation of the question>",
  "optionsAr": ["<Option 1 Ar>", "<Option 2 Ar>", "<Option 3 Ar>", "<Option 4 Ar>"],
  "optionsEn": ["<Option 1 En>", "<Option 2 En>", "<Option 3 En>", "<Option 4 En>"],
  "correctOption": 0,
  "explanationAr": "<Short technical explanation in Arabic>",
  "explanationEn": "<Short technical explanation in English>"
}''');
        break;
      case BreakItemType.funFact:
        sb.writeln('''
{
  "type": "fun_fact",
  "titleAr": "هل تعلم؟ معلومة هندسية",
  "titleEn": "Did You Know? Engineering Fact",
  "contentAr": "<Fascinating, verified technical/engineering fact in Arabic>",
  "contentEn": "<Accurate English translation of the fact>",
  "explanationAr": "<Additional context or application in Arabic>",
  "explanationEn": "<Additional context or application in English>",
  "isFactual": true
}''');
        break;
    }

    return sb.toString();
  }

  TechnicianBreakItem _getRandomFallback(BreakItemType type) {
    final list = _staticFallbacks[type] ?? [];
    if (list.isEmpty) {
      return TechnicianBreakItem(
        type: type,
        titleAr: 'استراحة Dr. Fix',
        titleEn: 'Dr. Fix Lounge',
        contentAr: 'خذ دقيقة استراحة واستمتع بالصيانة والإصلاح مع Dr. Fix!',
        contentEn: 'Take a break and enjoy professional maintenance with Dr. Fix!',
      );
    }
    return list[_random.nextInt(list.length)];
  }

  static final Map<BreakItemType, List<TechnicianBreakItem>> _staticFallbacks = {
    BreakItemType.joke: [
      TechnicianBreakItem(
        type: BreakItemType.joke,
        titleAr: 'كبّاس التكييف',
        titleEn: 'Central Compressor',
        contentAr: 'سألوا فني تكييف: ليه كبّاس السنترال بيحب الصيف؟ قال: لأنه الوحيد اللي بيشتغل تحت الضغط العالي من غير ما ينَفّس!',
        contentEn: 'They asked an HVAC tech: Why does a central compressor love summer? He said: Because it is the only thing that works under high pressure without venting!',
      ),
      TechnicianBreakItem(
        type: BreakItemType.joke,
        titleAr: 'دعوة زفاف كهربائية',
        titleEn: 'Electrician Wedding',
        contentAr: 'فني كهرباء اتجوز، كتب في دعوة الفرح: التوافق 100% بين الفاز والمحايد، وحضوركم بيقفل الدائرة!',
        contentEn: 'An electrician got married and wrote on the invitation: 100% compatibility between phase and neutral, your presence completes the circuit!',
      ),
      TechnicianBreakItem(
        type: BreakItemType.joke,
        titleAr: 'النظرية والتطبيق',
        titleEn: 'Theory vs Practice',
        contentAr: 'الفرق بين النظرية والتطبيق في الورشة: النظرية إن كل حاجة تشتغل بس ما حدش عارف ليه، والتطبيق إن ما فيش حاجة شغالة وجميع المفاتيح ضايعة!',
        contentEn: 'The difference between theory and practice in the workshop: Theory is when everything works but nobody knows why. Practice is when nothing works and all the 10mm sockets are missing!',
      ),
      TechnicianBreakItem(
        type: BreakItemType.joke,
        titleAr: 'صوت المحرك',
        titleEn: 'Engine Noise',
        contentAr: 'ميكانيكي قال للزبون: الصوت الصادر من المحرك اختفى! الزبون فرح وقال: صلحته؟ الميكانيكي: لا، الراديو بقى أعلى!',
        contentEn: 'A mechanic told the customer: The noise from the engine disappeared! Customer was thrilled: Did you fix it? Mechanic: No, I turned the radio up!',
      ),
    ],
    BreakItemType.riddle: [
      TechnicianBreakItem(
        type: BreakItemType.riddle,
        titleAr: 'لغز الملف الحثي',
        titleEn: 'Inductor Riddle',
        contentAr: 'عنصر كهربائي يُخزن الطاقة في مجال كهرومغناطيسي ويرفض أي تغيير سريع في التيار، فما هو؟',
        contentEn: 'An electrical component that stores energy in a magnetic field and resists rapid changes in current. What is it?',
        answerAr: 'الملف الحثي (Inductor)',
        answerEn: 'Inductor',
        explanationAr: 'الملف يعاكس التغير المفاجئ في التيار بسبب ظاهرة الحث الذاتي والقوة الدافعة الكهربائية العكسية.',
        explanationEn: 'The inductor opposes sudden changes in current due to self-inductance and back EMF.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.riddle,
        titleAr: 'صمام الاتجاه الواحد',
        titleEn: 'One-Way Valve',
        contentAr: 'مكوّن ميكانيكي يسمح بسريان المائع في اتجاه واحد فقط ويمنع التدفق العكسي تماماً، فما اسمه؟',
        contentEn: 'A mechanical component that allows fluid flow in one direction only and completely prevents backflow. What is it?',
        answerAr: 'صمام عدم الرجوع (Check Valve / Non-Return Valve)',
        answerEn: 'Check Valve (Non-Return Valve)',
        explanationAr: 'يعتمد على سستة وبوابات اتجاهية تفتح بضغط المائع وتغلق فوراً إذا عكس الاتجاه.',
        explanationEn: 'It relies on a spring and directional gate that opens under pressure and shuts upon flow reversal.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.riddle,
        titleAr: 'حامي الحياة الكهربائية',
        titleEn: 'Life Saver Circuit',
        contentAr: 'دائرة حماية تفتح تلقائياً عند تسرب التيار إلى الأرض لحماية الإنسان من الصدمة الكهربائية، فما هي؟',
        contentEn: 'A protection circuit that trips automatically when current leaks to ground to protect humans from electrical shock. What is it?',
        answerAr: 'قاطع التسرب الأرضي (RCD / ELCB)',
        answerEn: 'Residual Current Device (RCD / ELCB)',
        explanationAr: 'يقارن بين التيار الداخل عبر الفاز والخارج عبر المحايد، وإذا وجد فرقاً أعلى من 30mA يقطع الدائرة فوراً.',
        explanationEn: 'It compares live and neutral currents; if a difference over 30mA is detected, it trips instantly.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.riddle,
        titleAr: 'مقياس بدون قطع',
        titleEn: 'Non-Invasive Meter',
        contentAr: 'جهاز قياس يعمل بدون قطع السلك لقياس التيار المتردد عبر المجال المغناطيسي، ما هو؟',
        contentEn: 'A measuring tool used to measure AC current without breaking the wire via magnetic field. What is it?',
        answerAr: 'بنسة الأمبير (Clamp Meter)',
        answerEn: 'Clamp Meter',
        explanationAr: 'تعتمد على الحث المغناطيسي المتولد حول الموصل لقياس شدة التيار المار بداخل الكابل.',
        explanationEn: 'It measures current by detecting the magnetic field induced around the conductor.',
      ),
    ],
    BreakItemType.challenge: [
      TechnicianBreakItem(
        type: BreakItemType.challenge,
        titleAr: 'تحدي غاز R-410A',
        titleEn: 'R-410A Pressure Challenge',
        contentAr: 'ما هو ضغط الشحن المعتاد لغاز التكييف R-410A في خط السحب (Low Side) عند العمل الطبيعي؟',
        contentEn: 'What is the typical suction pressure (Low Side) for R-410A refrigerant during normal operation?',
        optionsAr: ['60-70 PSI', '110-130 PSI', '200-220 PSI', '300-350 PSI'],
        optionsEn: ['60-70 PSI', '110-130 PSI', '200-220 PSI', '300-350 PSI'],
        correctOption: 1,
        explanationAr: 'غاز R-410A يعمل على ضغوط أعلى بنسبة 50-60% من غاز R-22 القديم، وضغط السحب الطبيعي هو بين 110 إلى 130 PSI.',
        explanationEn: 'R-410A operates at 50-60% higher pressures than old R-22, with normal suction pressure between 110-130 PSI.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.challenge,
        titleAr: 'تحدي جهد الدلتا',
        titleEn: 'Delta Voltage Challenge',
        contentAr: 'عند توصيل محرك ثلاثي الأوجه بطريقة الدلتا (Delta Δ)، كم يكون جهد الفاز مقارنة بجهد الخط؟',
        contentEn: 'In a 3-phase Delta (Δ) motor connection, how does phase voltage compare to line voltage?',
        optionsAr: ['متساويان (Vphase = Vline)', 'Vphase = Vline / √3', 'Vphase = Vline * √3', 'Vphase = 0'],
        optionsEn: ['Equal (Vphase = Vline)', 'Vphase = Vline / √3', 'Vphase = Vline * √3', 'Vphase = 0'],
        correctOption: 0,
        explanationAr: 'في التوصيل بالدلتا، يتصل كل ملف مباشرة بين فازين، وبالتالي جهد الفاز يساوي جهد الخط تماماً.',
        explanationEn: 'In Delta connection, each phase winding is connected directly across two line conductors, making phase voltage equal line voltage.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.challenge,
        titleAr: 'شفرة عطل OBD2',
        titleEn: 'OBD2 Code Challenge',
        contentAr: 'رمز الشفرة OBD2 المعياري P0300 يشير إلى أي نوع من الأعطال في السيارات؟',
        contentEn: 'The standard OBD2 diagnostic trouble code P0300 indicates which fault in a vehicle?',
        optionsAr: ['عطل حسّاس الأوكسجين', 'تفويت إشعال عشوائي بالمحرك (Random Misfire)', 'ارتفاع حرارة زيت الفتيس', 'عطل مضخة البنزين'],
        optionsEn: ['Oxygen Sensor Fault', 'Random / Multiple Cylinder Misfire', 'Transmission Fluid Overheat', 'Fuel Pump Failure'],
        correctOption: 1,
        explanationAr: 'رمز P0300 يعبر عن حدوث احتراق غير كامل أو تفويت إشعال في بستم واحد أو عدة بساتم بشكل غير منتظم.',
        explanationEn: 'Code P0300 signifies random or multiple cylinder misfiring, indicating incomplete combustion.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.challenge,
        titleAr: 'وظيفة صمام التمدد',
        titleEn: 'Expansion Valve Function',
        contentAr: 'ما هي الوظيفة الأساسية لصمام التمدد (Expansion Valve) في دورة التبريد؟',
        contentEn: 'What is the primary function of the expansion valve in a refrigeration cycle?',
        optionsAr: ['رفع ضغط الفريون', 'تخفيض ضغط الفريون وتحويله لشرذم بارد', 'سحب الزيت للمحرك', 'فصل الماء عن الفريون'],
        optionsEn: ['Increase refrigerant pressure', 'Reduce pressure and meter cold liquid flow', 'Draw oil to compressor', 'Separate water from refrigerant'],
        correctOption: 1,
        explanationAr: 'صمام التمدد يخفض ضغط السائل القادم من المكثف ليتحول إلى رذاذ منخفض الضغط والحرارة يدخل المبخر.',
        explanationEn: 'It reduces high pressure liquid from condenser into a low-pressure, low-temperature atomized spray for evaporator.',
      ),
    ],
    BreakItemType.funFact: [
      TechnicianBreakItem(
        type: BreakItemType.funFact,
        titleAr: 'اختراع التكييف الحديث',
        titleEn: 'Air Conditioning Invention',
        contentAr: 'أول مكيف هواء حديث اخترعه ويليس كاريير عام 1902 لم يكن لتبريد البشر، بل لمنع استطالة وتجعد أوراق الطباعة بسبب الرطوبة العالية في نيويورك!',
        contentEn: 'The first modern air conditioner invented by Willis Carrier in 1902 was not for human comfort, but to control humidity and prevent paper expansion at a Brooklyn printing plant!',
        explanationAr: 'التحكم في الرطوبة ودرجة الحرارة أصلح جودة ألوان الطباعة قبل أن يصبح نظام تبريد للبشر.',
        explanationEn: 'Humidity control fixed printing color alignment long before comfort cooling caught on.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.funFact,
        titleAr: 'قصة اسم Bug',
        titleEn: 'Origin of Bug',
        contentAr: 'مصطلح "Bug" المخصص للأعطال التقنية اشتهر بعد اكتشاف عثة حشرية حقيقية علقت بين ريلايهات حاسوب Harvard Mark II عام 1947 وتم إلزاقها في التقرير الفني!',
        contentEn: 'The term "Bug" for technical glitches became famous after an actual moth was trapped between relays in the Harvard Mark II computer in 1947 and taped to the logbook!',
        explanationAr: 'قامت المهندسة غريس هوبر بإزالة الحشرة وكتبت: First actual case of bug being found.',
        explanationEn: 'Engineer Grace Hopper removed the moth and logged: First actual case of bug being found.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.funFact,
        titleAr: 'أصل كلمة العزم (Torque)',
        titleEn: 'Origin of Torque',
        contentAr: 'كلمة Torque المعتمدة في الميكانيكا مشتقة من الكلمة اللاتينية Torquere والتي تعني حرفياً اللّي أو التدوير القسري.',
        contentEn: 'The mechanical word "Torque" derives from the Latin word "Torquere" which literally means to twist or rotate under force.',
        explanationAr: 'يعبر العزم عن مدى مقدرة القوة على إحداث دوران حول محور تثبيت معين.',
        explanationEn: 'Torque measures the rotational force applied around a fixed pivot point.',
      ),
      TechnicianBreakItem(
        type: BreakItemType.funFact,
        titleAr: 'دور الزيت في التبريد',
        titleEn: 'Oil Cooling Role',
        contentAr: 'زيت محركات السيارات لا يقتصر دوره على التزييت فقط، بل يساهم بنسبة تصل إلى 40% في تبريد أجزاء المحرك الداخلية القريبة من غرف الاحتراق!',
        contentEn: 'Engine oil does not just lubricate; it also accounts for up to 40% of the cooling of internal engine components near combustion chambers!',
        explanationAr: 'يقوم الزيت بنقل الحرارة المباشرة من البساتم والعمود الكرنك إلى كارتير الزيت حيث يتم تبريده.',
        explanationEn: 'Oil absorbs intense heat directly from pistons and crankshaft, carrying it down to the oil pan for dissipation.',
      ),
    ],
  };
}
