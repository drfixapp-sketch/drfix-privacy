import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dr_fix/main.dart';
import 'package:dr_fix/presentation/providers/auth_provider.dart';
import 'package:dr_fix/presentation/screens/contact_support_screen.dart';
import 'package:dr_fix/presentation/screens/forum_screen.dart';
import 'package:dr_fix/presentation/screens/history_screen.dart';
import 'package:dr_fix/presentation/screens/home_screen.dart';
import 'package:dr_fix/presentation/screens/login_screen.dart';
import 'package:dr_fix/presentation/screens/community_dashboard_screen.dart';
import 'package:dr_fix/data/services/history_service.dart';

class CustomAppDrawer extends ConsumerWidget {
  const CustomAppDrawer({Key? key}) : super(key: key);

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final bool isRtl = localeState.languageCode == 'ar';
    final authState = ref.watch(authProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F75BC), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(
                  child: authState.user?.photoUrl != null
                      ? Image.network(
                          authState.user!.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.engineering_rounded,
                            size: 36,
                            color: Color(0xFF0F75BC),
                          ),
                        )
                      : const Icon(Icons.engineering_rounded, size: 36, color: Color(0xFF0F75BC)),
                ),
              ),
              accountName: Text(
                authState.user?.displayName ?? (isRtl ? 'فني Dr Fix' : 'Dr Fix Technician'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              accountEmail: Text(
                authState.user?.email ?? 'guest@drfix.app',
                style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
              ),
            ),
            Expanded(
                            child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 1️⃣ الرئيسية والتشخيص
                  ListTile(
                    leading: const Icon(Icons.home_repair_service_rounded, color: Color(0xFF0F75BC)),
                    title: Text(
                      isRtl ? 'الرئيسية والتشخيص' : 'Home & Diagnostics',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                    },
                  ),
                  
                  // 2️⃣ مجتمع تبادل الخبرات
                  ListTile(
                    leading: const Icon(Icons.forum_rounded, color: Colors.orange),
                    title: Text(
                      isRtl ? 'مجتمع تبادل الخبرات' : 'Community Forum',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ForumScreen()));
                    },
                  ),

                  // 📚 3️⃣ موسوعة الأعطال الموثقة
                  ListTile(
                    leading: const Icon(Icons.auto_stories_rounded, color: Colors.amber), 
                    title: Text(
                      isRtl ? 'موسوعة الأعطال الموثقة' : 'Certified Faults Encyclopedia',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityDashboardScreen()));
                    },
                  ),

                  // 4️⃣ الدعم الفني والملاحظات
                  ListTile(
                    leading: const Icon(Icons.support_agent_rounded, color: Colors.green),
                    title: Text(
                      isRtl ? 'الدعم الفني والملاحظات' : 'Contact Support & Feedback',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _openScreen(context, const ContactSupportScreen()),
                  ),
                  
                  // 5️⃣ سجل الفحوصات السابقة
                  ListTile(
                    leading: const Icon(Icons.history_rounded, color: Colors.purple),
                    title: Text(
                      isRtl ? 'سجل الفحوصات السابقة' : 'Diagnostics History',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _openScreen(context, const HistoryScreen()),
                  ),
                  
                  const Divider(color: Color(0xFFE2E8F0)),
                  
                  // 6️⃣ تحويل اللغة
                  ListTile(
                    leading: const Icon(Icons.translate_rounded, color: Colors.teal),
                    title: Text(
                      isRtl ? 'English Language' : 'اللغة العربية',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(localeProvider.notifier).state = isRtl ? const Locale('en') : const Locale('ar');
                    },
                  ),
                                    // 🔒 تم تشفير وإخفاء مسارات المشرفين تماماً لضمان الخصوصية ومنع الفضول
                  const Divider(color: Color(0xFFE2E8F0)),
                  const Divider(color: Color(0xFFE2E8F0)),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.blueGrey),
                    title: Text(
                      isRtl ? 'تسجيل الخروج' : 'Sign Out',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      }
                    },
                  ),
                  if (authState.user != null && !authState.user!.isGuest) ...[
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      title: Text(
                        isRtl ? 'حذف الحساب والبيانات' : 'Delete Account & Data',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: Text(
                              isRtl ? 'حذف الحساب نهائياً' : 'Delete Account Permanently',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              isRtl
                                  ? 'هل أنت متأكد؟ سيتم حذف جميع سجلاتك التشخيصية وقوائمك السحابية نهائياً للامتثال لسياسة حماية البيانات. لا يمكن التراجع عن هذا الإجراء.'
                                  : 'Are you sure? This will permanently delete all your cloud diagnostic records and profile to comply with Apple/Google data privacy policies. This cannot be undone.',
                              style: const TextStyle(fontSize: 12),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('حذف الحساب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final uid = ref.read(authProvider).user?.uid;
                          if (uid != null) {
                            final success = await ref.read(authProvider.notifier).deleteAccount();
                            if (success) {
                              await HistorySyncService.purgeUserDataAndCloudHistory(uid);
                              if (context.mounted) {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                              }
                            } else {
                              if (context.mounted) {
                                final authState = ref.read(authProvider);
                                showDialog(
                                  context: context,
                                  builder: (alertCtx) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.security_rounded, color: Colors.amber.shade800, size: 24),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            isRtl ? 'تأكيد أمني مطلوب' : 'Security Verification',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      authState.errorMessage ??
                                          (isRtl
                                              ? 'لحماية بياناتك، يرجى تسجيل الخروج ثم الدخول مجدداً لتأكيد هويتك قبل حذف الحساب نهائياً.'
                                              : 'For your security, please sign in again to verify your identity before deleting your account.'),
                                      style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF334155)),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(alertCtx),
                                        child: Text(isRtl ? 'حسناً، فهمت' : 'OK', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                isRtl ? 'نسخة v1.0.0 • صيانة آمنة' : 'Version v1.0.0 • Safe Repair',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
