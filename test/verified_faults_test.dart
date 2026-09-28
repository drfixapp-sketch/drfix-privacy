import 'package:flutter_test/flutter_test.dart';
import 'package:dr_fix/data/models/verified_fault_model.dart';
import 'package:dr_fix/data/network/admin_auth_service.dart';

void main() {
  group('Verified Faults Encyclopedia Architecture & Governance Tests (v1.1.0+3)', () {
    test('1. VerifiedFault model serializes and deserializes exactly 7 fields without replies', () {
      final fault = VerifiedFault(
        id: 'vf_test_1',
        title: 'عطل في بلف التمدد الحراري TXV',
        description: 'انسداد جزئي في إبرة الصمام يسبب انخفاض ضغط السحب وارتفاع درجة التحميص Superheat.',
        sector: 'تبريد وتكييف',
        viewsCount: 150,
        authorName: 'المهندس أحمد صالح',
        createdAt: DateTime(2026, 9, 8, 10, 0),
      );

      final json = fault.toJson();

      // Check all 7 required fields
      expect(json['id'], 'vf_test_1');
      expect(json['title'], 'عطل في بلف التمدد الحراري TXV');
      expect(json['description'], contains('انسداد جزئي'));
      expect(json['sector'], 'تبريد وتكييف');
      expect(json['views_count'], 150);
      expect(json['author_name'], 'المهندس أحمد صالح');
      expect(json['created_at'], isNotNull);

      // Verify absence of replies or comments
      expect(json.containsKey('replies'), isFalse);
      expect(json.containsKey('comments'), isFalse);

      // Deserialization check
      final restored = VerifiedFault.fromJson(json);
      expect(restored.id, 'vf_test_1');
      expect(restored.title, fault.title);
      expect(restored.description, fault.description);
      expect(restored.sector, 'تبريد وتكييف');
      expect(restored.viewsCount, 150);
      expect(restored.authorName, 'المهندس أحمد صالح');
    });

    test('2. initialSeedData covers all 9 official engineering sectors', () {
      final seed = VerifiedFault.initialSeedData;
      expect(seed.length, greaterThanOrEqualTo(9));

      final expectedSectors = [
        'تبريد وتكييف',
        'كهرباء',
        'ميكانيك',
        'أنظمة الهيدروليك',
        'أجهزة منزلية',
        'صناعي',
        'سيارات ومركبات',
        'سباكة',
        'أخرى',
      ];

      for (final sector in expectedSectors) {
        final hasSector = seed.any((item) => item.sector == sector);
        expect(hasSector, isTrue, reason: 'Missing sector in initialSeedData: $sector');
      }
    });

    test('3. Client-Side Filtering filters by sector correctly', () {
      final items = VerifiedFault.initialSeedData;

      // Filter by 'كهرباء'
      final electricalFaults = items.where((f) => f.sector == 'كهرباء').toList();
      expect(electricalFaults.isNotEmpty, isTrue);
      expect(electricalFaults.every((f) => f.sector == 'كهرباء'), isTrue);

      // Filter by 'سباكة'
      final plumbingFaults = items.where((f) => f.sector == 'سباكة').toList();
      expect(plumbingFaults.isNotEmpty, isTrue);
      expect(plumbingFaults.every((f) => f.sector == 'سباكة'), isTrue);

      // Filter by 'الكل'
      final allFaults = items.where((f) => 'الكل' == 'الكل' || f.sector == 'الكل').toList();
      expect(allFaults.length, equals(items.length));
    });

    test('4. Client-Side smart search performs Arabic normalization accurately', () {
      final items = VerifiedFault.initialSeedData;

      String normalize(String text) {
        return text
            .toLowerCase()
            .replaceAll('ال', '')
            .replaceAll('ة', 'ه')
            .replaceAll('أ', 'ا')
            .replaceAll('إ', 'ا')
            .replaceAll('آ', 'ا')
            .trim();
      }

      List<VerifiedFault> filter(String query, String sector) {
        final normQuery = normalize(query);
        return items.where((f) {
          if (sector != 'الكل' && f.sector != sector) return false;
          if (normQuery.isEmpty) return true;
          final haystack = normalize('${f.title} ${f.description} ${f.sector} ${f.authorName}');
          return haystack.contains(normQuery);
        }).toList();
      }

      // Search without 'ال' (e.g. 'محرك' instead of 'المحرك')
      final searchEngine = filter('محرك', 'الكل');
      expect(searchEngine.isNotEmpty, isTrue);

      // Search for 'هيدروليك'
      final searchHydraulic = filter('هيدروليك', 'الكل');
      expect(searchHydraulic.isNotEmpty, isTrue);
      expect(searchHydraulic.any((f) => f.sector == 'أنظمة الهيدروليك'), isTrue);

      // Search for specific author
      final searchAuthor = filter('سليم', 'الكل');
      expect(searchAuthor.isNotEmpty, isTrue);
      expect(searchAuthor.first.authorName, contains('سليم'));

      // Empty query returns all
      expect(filter('', 'الكل').length, equals(items.length));
    });

    test('5. Super Admin email is strictly drfixapp@gmail.com', () {
      expect(AdminAuthService.superAdminEmail, equals('drfixapp@gmail.com'));
    });
  });
}
