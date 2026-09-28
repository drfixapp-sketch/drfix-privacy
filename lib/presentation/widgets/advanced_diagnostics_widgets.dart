import 'package:flutter/material.dart';

// 🎛️ ويدجت عرض أجهزة القياس والحقول الرقمية (الاقتراحات 2 و 4)
class ToolsViewWidget extends StatelessWidget {
  final bool isAr;
  final bool hasMultimeter;
  final bool hasPressureGauge;
  final bool hasObdScanner;
  final ValueChanged<bool?> onMultimeterChanged;
  final ValueChanged<bool?> onPressureChanged;
  final ValueChanged<bool?> onObdChanged;
  final TextEditingController voltageController;
  final TextEditingController ampereController;
  final TextEditingController pressureController;
  final TextEditingController dtcCodeController;

  const ToolsViewWidget({
    Key? key,
    required this.isAr,
    required this.hasMultimeter,
    required this.hasPressureGauge,
    required this.hasObdScanner,
    required this.onMultimeterChanged,
    required this.onPressureChanged,
    required this.onObdChanged,
    required this.voltageController,
    required this.ampereController,
    required this.pressureController,
    required this.dtcCodeController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'حدّد أجهزة القياس المتوفرة لديك حالياً بالتحديد:' : 'Select available tools on hand:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
          child: Column(
            children: [
              CheckboxListTile(
                secondary: const Icon(Icons.electric_meter_rounded, color: Colors.amber),
                title: Text(isAr ? 'جهاز الملتيميتر / الفولتميتر (لقياس الكهرباء)' : 'Digital Multimeter'),
                value: hasMultimeter,
                activeColor: Colors.blue,
                onChanged: onMultimeterChanged,
              ),
              const Divider(height: 1),
              CheckboxListTile(
                secondary: const Icon(Icons.speed_rounded, color: Colors.teal),
                title: Text(isAr ? 'مقياس ضغط السوائل والغازات (للهيدروليك والتكييف)' : 'Pressure Gauge'),
                value: hasPressureGauge,
                activeColor: Colors.blue,
                onChanged: onPressureChanged,
              ),
              const Divider(height: 1),
              CheckboxListTile(
                secondary: const Icon(Icons.developer_board_rounded, color: Colors.red),
                title: Text(isAr ? 'جهاز فحص كمبيوتر المركبات (OBD2 Scanner)' : 'OBD2 Fault Scanner'),
                value: hasObdScanner,
                activeColor: Colors.blue,
                onChanged: onObdChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (hasMultimeter || hasPressureGauge || hasObdScanner) ...[
          Text(
            isAr ? 'أدخل القراءات المستخرجة من الأجهزة لرفع دقة محرك الـ AI:' : 'Enter logged parameters for AI accuracy:',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          if (hasMultimeter) ...[
            TextField(
              controller: voltageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isAr ? 'الجهد الكهربائي المقاس (Voltage V)' : 'Voltage V', border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ampereController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isAr ? 'شدة التيار المار إن وجد (Amperage A)' : 'Amperage A', border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
            ),
            const SizedBox(height: 12),
          ],
          if (hasPressureGauge) ...[
            TextField(
              controller: pressureController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isAr ? 'معدل ضغط الغاز أو الزيت الملاحظ (PSI / Bar)' : 'Pressure PSI / Bar', border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
            ),
            const SizedBox(height: 12),
          ],
          if (hasObdScanner) ...[
            TextField(
              controller: dtcCodeController,
              decoration: InputDecoration(labelText: isAr ? 'كود الخطأ المستخرج من فحص الكمبيوتر (مثل P0300)' : 'DTC Code (e.g. P0300)', border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
            ),
          ],
        ],
      ],
    );
  }
}

// 🔍 ويدجت دليل الإرشادات البصرية البديلة (الاقتراح 3)
class VisualTipsWidget extends StatelessWidget {
  final bool isAr;
  const VisualTipsWidget({Key? key, required this.isAr}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? '🔍 إرشادات الفحص البصري السريع (قم بها بعينك ويدك):' : '🔍 Guided Visual Inspection Steps:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.remove_red_eye_rounded, color: Colors.blue, size: 18)),
                  title: Text(
                    isAr ? 'تأكد بصرياً من سلامة التوصيلات الخارحية وعدم وجود كابلات مقطوعة أو مرتخية.' : 'Check external cables for cuts or loose ties.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.opacity_rounded, color: Colors.blue, size: 18)),
                  title: Text(
                    isAr ? 'افحص أسفل ومحيط النظام للتأكد من عدم وجود أي تهريب أو ترشيح سوائل (زيوت، مياه، فريون).' : 'Verify there are no liquid or fluid leaks underneath.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.touch_app_rounded, color: Colors.blue, size: 18)),
                  title: Text(
                    isAr ? 'تحسس الهيكل الخارجي للمعدة (بحذر شديد) للتأكد من عدم وجود سخونة مفاجئة أو مفرطة بالملفات.' : 'Carefully feel the shell to catch abnormal hot spots.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
