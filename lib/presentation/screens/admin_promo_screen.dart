import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/presentation/widgets/forum_models_and_providers.dart';

class AdminPromoScreen extends ConsumerStatefulWidget {
  const AdminPromoScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminPromoScreen> createState() => _AdminPromoScreenState();
}

class _AdminPromoScreenState extends ConsumerState<AdminPromoScreen> {
  final _companyNameController = TextEditingController();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _codeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCodes = ref.watch(promoCodeProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("إدارة عروض وأكواد الشركات", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Tajawal')),
            backgroundColor: const Color(0xFF1E293B),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📥 إضافة تعاقد وكود ترويجي جديد:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC), fontFamily: 'Tajawal')),
                  const SizedBox(height: 12),
                  TextField(controller: _companyNameController, decoration: const InputDecoration(hintText: "اسم الشركة الصانعة أو المورد", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
                  const SizedBox(height: 8),
                  TextField(controller: _codeController, decoration: const InputDecoration(hintText: "كود الخصم (مثال: FORD10)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
                  const SizedBox(height: 8),
                  TextField(controller: _discountController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "نسبة الخصم بالأرقام فقط (مثال: 15)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                      icon: const Icon(Icons.add_business_outlined, size: 18),
                      label: const Text("تفعيل العرض ونشره حياً للمستخدمين", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      onPressed: () {
                        final String comp = _companyNameController.text.trim();
                        final String code = _codeController.text.trim();
                        final int? disc = int.tryParse(_discountController.text.trim());

                        if (comp.isNotEmpty && code.isNotEmpty && disc != null) {
                          ref.read(promoCodeProvider.notifier).addPromoCode(code, disc);
                          _companyNameController.clear();
                          _codeController.clear();
                          _discountController.clear();
                          FocusScope.of(context).unfocus();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم نشر تفعيل الكود بنجاح حياً في واجهة قطع الغيار!")));
                        }
                      },
                    ),
                  ),
                  const Divider(height: 32),
                  Text("الأكواد النشطة حالياً (${activeCodes.length}):", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Tajawal')),
                  const SizedBox(height: 8),
                  if (activeCodes.isEmpty)
                    const Center(child: Text("لا توجد أكواد مفعلة حالياً. الواجهة مخفية عن الفنيين.", style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Tajawal')))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeCodes.length,
                      itemBuilder: (context, index) {
                        final promo = activeCodes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text("الكود: ${promo.code}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontFamily: 'Tajawal')),
                            subtitle: Text("نسبة التوفير: ${promo.discountPercentage}%", style: const TextStyle(fontFamily: 'Tajawal')),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => ref.read(promoCodeProvider.notifier).removePromoCode(promo.code),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
