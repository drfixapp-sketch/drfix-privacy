class DynamicFieldConfig {
  final String deviceNameHintAr, deviceNameHintEn;
  final String manufacturerHintAr, manufacturerHintEn;
  final String modelHintAr, modelHintEn;
  final String problemDetailsHintAr, problemDetailsHintEn;
  final String observationsHintAr, observationsHintEn;
  final String errorCodeHintAr, errorCodeHintEn;

  const DynamicFieldConfig({
    required this.deviceNameHintAr, required this.deviceNameHintEn,
    required this.manufacturerHintAr, required this.manufacturerHintEn,
    required this.modelHintAr, required this.modelHintEn,
    required this.problemDetailsHintAr, required this.problemDetailsHintEn,
    required this.observationsHintAr, required this.observationsHintEn,
    required this.errorCodeHintAr, required this.errorCodeHintEn,
  });

  factory DynamicFieldConfig.getConfigForCategory(String categoryName) {
    final cat = categoryName.trim().toLowerCase();

    if (cat.contains('تكييف') || cat.contains('hvac') || cat.contains('cooling')) {
      return const DynamicFieldConfig(
        deviceNameHintAr: 'نوع وجهاز المكيف (مثال: تكييف مركزي، سبلت، صحراوي)',
        deviceNameHintEn: 'AC Device Type (e.g., Split, Central, Window, Package)',
        manufacturerHintAr: 'ماركة المكيف (كاريير، ال جي، دايكن، جري)',
        manufacturerHintEn: 'AC Brand (Carrier, LG, Daikin, Gree)',
        modelHintAr: 'سعة المكيف وموديله (مثال: 5 طن، 24 ألف وحدة)',
        modelHintEn: 'AC Capacity & Model (e.g., 5-Ton, 24000 BTU)',
        problemDetailsHintAr: 'تفاصيل مشكلة التبريد (تنقيط ماء، دفع هواء ضعيف، هواء حار)',
        problemDetailsHintEn: 'Cooling Problem details (water leaking, weak air, blows hot)',
        observationsHintAr: 'ملاحظات حركة الكمبروسر الخارجي، صوت طنين، توقف كامل للمروحة',
        observationsHintEn: 'Observations on outdoor compressor, buzzing, fan stopped',
        errorCodeHintAr: 'رمز الخطأ الظاهر على شاشة المكيف (مثال: E5, F1)',
        errorCodeHintEn: 'Error code on AC screen (e.g., E5, F1)',
      );
    } else if (cat.contains('سيارات') || cat.contains('مركبات') || cat.contains('auto') || cat.contains('car') || cat.contains('automotive')) {
      return const DynamicFieldConfig(
        deviceNameHintAr: 'نوع السيارة وفئتها (مثال: تويوتا كامري، هيونداي توسان)',
        deviceNameHintEn: 'Car Type & Class (e.g., Toyota Camry, Hyundai Tucson)',
        manufacturerHintAr: 'ماركة أو مصنع السيارة (تويوتا، هيونداي، فورد)',
        manufacturerHintEn: 'Car Brand (Toyota, Hyundai, Ford, Mercedes)',
        modelHintAr: 'سنة الصنع وسعة المحرك (مثال: 2021، 2.5 لتر)',
        modelHintEn: 'Year of Manufacture & Engine Size (e.g., 2021, 2.5L)',
        problemDetailsHintAr: 'تفاصيل عطل المحرك أو الجير أو الكهرباء (تفتفة، تأخر تعشيق)',
        problemDetailsHintEn: 'Engine, Gear, or Electrical issue details (misfire, delay)',
        observationsHintAr: 'ملاحظات مثل: لون الدخان، أصوات طقطقة، اهتزاز مع الفرامل',
        observationsHintEn: 'Observations: smoke color, ticking sound, vibration with braking',
        errorCodeHintAr: 'رمز فحص الكمبيوتر OBD-II (مثال: P0300, P0171)',
        errorCodeHintEn: 'OBD-II Diagnostic Error code (e.g., P0300, P0171)',
      );
    } else if (cat.contains('صناعي') || cat.contains('صناعية') || cat.contains('industrial') || cat.contains('manufacturing')) {
      return const DynamicFieldConfig(
        deviceNameHintAr: 'اسم المعدة أو الآلة الصناعية (مثال: خط إنتاج، ضاغط هيدروليكي)',
        deviceNameHintEn: 'Industrial Equipment/Machine Name (e.g., CNC, Hydraulic Press)',
        manufacturerHintAr: 'الشركة المصنعة للمعدة (سيمنز، شنايدر، كاتربيلر)',
        manufacturerHintEn: 'Manufacturer of Equipment (Siemens, Schneider, Caterpillar)',
        modelHintAr: 'الموديل أو الرقم التسلسلي للوحة التحكم (PLC)',
        modelHintEn: 'Model or Serial Number of Control Panel (PLC)',
        problemDetailsHintAr: 'تفاصيل توقف المعدة أو هبوط الكفاءة أو عطل ميكانيكي/كهربائي',
        problemDetailsHintEn: 'Equipment breakdown details, drop in efficiency, mechanical/electrical fault',
        observationsHintAr: 'ملاحظات: ارتفاع الحرارة، انخفاض الضغط، أصوات احتكاك بالتروس',
        observationsHintEn: 'Observations: overheating, drop in pressure, gear friction noise',
        errorCodeHintAr: 'كود خطأ نظام التحكم أو الـ PLC (مثال: SF LED, Code 102)',
        errorCodeHintEn: 'Control system/PLC error code (e.g., SF LED, Code 102)',
      );
    } else if (cat.contains('كهرباء') || cat.contains('electrical') || cat.contains('كهربائي')) {
      return const DynamicFieldConfig(
        deviceNameHintAr: 'اسم اللوحة أو الجهاز الكهربائي (قاطع، لوحة توزيع، عداد)',
        deviceNameHintEn: 'Electrical Panel or Device Name (Breaker, Distribution Panel, Meter)',
        manufacturerHintAr: 'المصنع للمعدات الكهربائية (شنايدر، ايه بي بي، ليجراند)',
        manufacturerHintEn: 'Electrical Brand (Schneider, ABB, Legrand)',
        modelHintAr: 'الجهد الكهربائي والتيار الأقصى (مثال: 3 فاز، 60 أمبير)',
        modelHintEn: 'Voltage & Max Current Rating (e.g., 3-Phase, 60A)',
        problemDetailsHintAr: 'تفاصيل المشكلة (تماس، قفز القاطع تلقائياً، ضعف الجهد)',
        problemDetailsHintEn: 'Electrical issue details (short circuit, breaker tripping, low voltage)',
        observationsHintAr: 'ملاحظات: رائحة احتراق، حرارة في الأسلاك، أصوات شرار خفيفة',
        observationsHintEn: 'Observations: burning smell, wires heating, minor sparking sound',
        errorCodeHintAr: 'رمز خطأ العداد أو جهاز الحماية (إن وجد)',
        errorCodeHintEn: 'Error code on meter or protection relay (if any)',
      );
    } else if (cat.contains('هيدروليك') || cat.contains('hydraulics') || cat.contains('هيدروليكية')) {
      return const DynamicFieldConfig(
        deviceNameHintAr: 'اسم النظام الهيدروليكي (مكبس، رافعة، وحدة ضخ هيدروليكية)',
        deviceNameHintEn: 'Hydraulic System Name (Press, Crane, Hydraulic Power Unit)',
        manufacturerHintAr: 'الماركة المصنعة للصمامات والمضخات (ريكسروث، باركر، فيكرز)',
        manufacturerHintEn: 'Valve & Pump Brand (Rexroth, Parker, Vickers)',
        modelHintAr: 'معدل الضغط الأقصى وسعة الخزان (مثال: 250 بار، 100 لتر)',
        modelHintEn: 'Max Pressure Rate & Reservoir Capacity (e.g., 250 Bar, 100L)',
        problemDetailsHintAr: 'تفاصيل المشكلة (تسريب زيت، عدم ارتفاع الذراع، ضعف الضغط)',
        problemDetailsHintEn: 'Hydraulic issue details (oil leak, arm wont lift, low pressure)',
        observationsHintAr: 'ملاحظات: رغوة في الزيت، صوت صفير عالي بالمضخة، بطء الحركة حركياً',
        observationsHintEn: 'Observations: foam in oil, high pitch whining, extremely slow movement',
        errorCodeHintAr: 'كود الحماية في مستشعر الضغط أو درجة حرارة الزيت',
        errorCodeHintEn: 'Error code on pressure sensor or oil temperature monitor',
      );
    } else if (cat.contains('أجهزة') || cat.contains('منزلية') || cat.contains('appliance') || cat.contains('appliances') || cat.contains('home')) {
      return const DynamicFieldConfig(
        deviceNameHintAr: 'نوع الجهاز المنزلي (غسالة، ثلاجة، فرن كهربائي، ميكروويف)',
        deviceNameHintEn: 'Home Appliance Type (Washer, Fridge, Electric Oven, Microwave)',
        manufacturerHintAr: 'ماركة أو شركة الجهاز المنزلي (سامسونج، بوش، إل جي، بيكو)',
        manufacturerHintEn: 'Appliance Brand (Samsung, Bosch, LG, Beko)',
        modelHintAr: 'الطراز ومواصفات الطاقة (مثال: غسالة 10 كيلو، إنفيرتر)',
        modelHintEn: 'Model & Power Specs (e.g., Washer 10kg, Inverter Technology)',
        problemDetailsHintAr: 'تفاصيل العطل (لا تصرف الماء، لا تبرد الثلاجة، لا يسخن الفرن)',
        problemDetailsHintEn: 'Fault details (does not drain, fridge not cooling, oven not heating)',
        observationsHintAr: 'ملاحظات: اهتزاز في الدوران، مياه متجمعة بالأسفل، أصوات احتكاك',
        observationsHintEn: 'Observations: vibrating on spin cycle, water pooling under, squeaking',
        errorCodeHintAr: 'كود الخطأ الرقمي على لوحة التحكم الإلكترونية (مثال: OE, dE, dH)',
        errorCodeHintEn: 'Error code on the digital panel (e.g., OE, dE, dH)',
      );
    } else if (cat.contains('سباكة') || cat.contains('plumbing') || cat.contains('أنابيب')) {
      return const DynamicFieldConfig(
        deviceNameHintAr: 'نوع شبكة أو جهاز السباكة (مضخة مياه، سخان مركزي، خلاط، شبكة ري)',
        deviceNameHintEn: 'Plumbing System/Device (Water Pump, Central Heater, Mixer, Irrigation)',
        manufacturerHintAr: 'ماركة مضخة المياه أو محبس السباكة (جراندفوس، بيدرولو)',
        manufacturerHintEn: 'Plumbing/Pump Brand (Grundfos, Pedrollo, Grohe)',
        modelHintAr: 'القدرة وسعة الأنابيب (مثال: مضخة 1 حصان، أنابيب 2 إنش)',
        modelHintEn: 'Capacity & Pipe Sizes (e.g., 1 HP Pump, 2-Inch pipes)',
        problemDetailsHintAr: 'تفاصيل مشكلة السباكة (تسريب مخفي، انسداد بالخط، ضعف ضغط المياه)',
        problemDetailsHintEn: 'Plumbing fault details (hidden leak, pipe clog, weak water pressure)',
        observationsHintAr: 'ملاحظات: سماع صوت سريان ماء، تشققات بالجدران، دوران مستمر للمضخة',
        observationsHintEn: 'Observations: water flow sound, wall cracks, pump running continuously',
        errorCodeHintAr: 'رموز أخطاء لوحة التحكم الذكي للمضخة إن وجدت',
        errorCodeHintEn: 'Error code on intelligent pump controller if any',
      );
    } else if (cat.contains('ميكانيك') || cat.contains('mechanical') || cat.contains('ميكانيكية')) {
      return const DynamicFieldConfig(
        deviceNameHintAr: 'نوع النظام الميكانيكي (محرك، علبة تروس، سير ناقل، عمود دوران)',
        deviceNameHintEn: 'Mechanical System (Motor, Gearbox, Conveyor Belt, Shaft)',
        manufacturerHintAr: 'العلامة التجارية المصنعة (سيو، فينر، موتو فاركتوري)',
        manufacturerHintEn: 'Mechanical Brand (SEW-Eurodrive, Fenner, Motovario)',
        modelHintAr: 'نسبة التخفيض أو عدد الأحصنة والمقاس الميكانيكي',
        modelHintEn: 'Reduction Ratio, Horsepower, or Mechanical dimensions',
        problemDetailsHintAr: 'تفاصيل العطل الميكانيكي (احتكاك، ارتخاء السيور، انحراف المحور)',
        problemDetailsHintEn: 'Mechanical fault details (metal friction, belt slippage, shaft misalignment)',
        observationsHintAr: 'ملاحظات: اهتزاز دوراني شديد، انبعاث دخان، تآكل في حواف التروس',
        observationsHintEn: 'Observations: high rotational vibration, smoke, teeth wear on gears',
        errorCodeHintAr: 'رمز حساس الاهتزاز أو الحرارة إن وجد',
        errorCodeHintEn: 'Error code on vibration or heat sensor if any',
      );
    } else {
      // General / Other (أخرى)
      return const DynamicFieldConfig(
        deviceNameHintAr: 'اسم الجهاز أو المعدة الفنية يدوياً',
        deviceNameHintEn: 'Device or Technical Equipment Name',
        manufacturerHintAr: 'الشركة المصنعة أو العلامة التجارية',
        manufacturerHintEn: 'Manufacturer or Official Brand',
        modelHintAr: 'الموديل أو الطراز المكتوب باللوحة الخلفية',
        modelHintEn: 'Model or Style Number from Nameplate',
        problemDetailsHintAr: 'تفاصيل المشكلة والتشخيص والعطل الملاحظ بدقة',
        problemDetailsHintEn: 'Details of the problem, diagnosis, and signs observed',
        observationsHintAr: 'ملاحظات ميكانيكية وحركية وصوتية (أصوات، اهتزاز)',
        observationsHintEn: 'Kinetic, mechanical, and sound observations (noise, vibration)',
        errorCodeHintAr: 'رموز وأكواد الأعطال إن وجدت على الشاشة الرقمية',
        errorCodeHintEn: 'Fault codes and error messages if any on digital panel',
      );
    }
  }
}
