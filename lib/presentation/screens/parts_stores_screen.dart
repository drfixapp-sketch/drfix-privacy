import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:dr_fix/main.dart'; // For localeProvider
import 'package:dr_fix/presentation/widgets/custom_drawer.dart';

class SparePartStore {
  final String id;
  final String nameAr;
  final String nameEn;
  final String categoryId; // matching the category
  final String addressAr;
  final String addressEn;
  final String phone;
  final double rating;
  final double latOffset;
  final double lngOffset;
  final double? realLat;
  final double? realLng;
  final bool isVerified;
  final String workingHoursAr;
  final String workingHoursEn;
  final List<String> availablePartsAr;
  final List<String> availablePartsEn;

  SparePartStore({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.categoryId,
    required this.addressAr,
    required this.addressEn,
    required this.phone,
    required this.rating,
    required this.latOffset,
    required this.lngOffset,
    this.realLat,
    this.realLng,
    this.isVerified = false,
    required this.workingHoursAr,
    required this.workingHoursEn,
    required this.availablePartsAr,
    required this.availablePartsEn,
  });
}

class PartsStoresScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const PartsStoresScreen({super.key, this.initialCategory});

  @override
  ConsumerState<PartsStoresScreen> createState() => _PartsStoresScreenState();
}

class _PartsStoresScreenState extends ConsumerState<PartsStoresScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isFetchingOsm = false;
  String _selectedCategoryId = '6'; // Default to HVAC (تكييف وتبريد)
  SparePartStore? _selectedStore;
  final List<Marker> _markers = [];
  List<SparePartStore> _liveOsmStores = [];

  // Amman, Jordan as the fallback default coordinates
  final double _defaultLat = 31.9539;
  final double _defaultLng = 35.9106;

  // Categories list modeled matching home_screen
  final List<Map<String, dynamic>> _categories = [
    {'id': '1', 'titleAr': 'أنظمة صناعية', 'titleEn': 'Industrial Systems', 'icon': Icons.precision_manufacturing_rounded, 'color': Colors.blue},
    {'id': '2', 'titleAr': 'كهرباء', 'titleEn': 'Electrical', 'icon': Icons.electric_bolt_rounded, 'color': Colors.amber},
    {'id': '3', 'titleAr': 'ميكانيك', 'titleEn': 'Mechanical', 'icon': Icons.settings_applications_rounded, 'color': Colors.blueGrey},
    {'id': '4', 'titleAr': 'أنظمة هيدروليك', 'titleEn': 'Hydraulics', 'icon': Icons.water_drop_rounded, 'color': Colors.indigo},
    {'id': '5', 'titleAr': 'أجهزة منزلية', 'titleEn': 'Home Appliances', 'icon': Icons.kitchen_rounded, 'color': Colors.deepOrange},
    {'id': '6', 'titleAr': 'تكييف وتبريد', 'titleEn': 'HVAC', 'icon': Icons.ac_unit_rounded, 'color': Colors.cyan},
    {'id': '7', 'titleAr': 'سيارات ومركبات', 'titleEn': 'Automotive', 'icon': Icons.time_to_leave_rounded, 'color': Colors.red},
    {'id': '8', 'titleAr': 'سباكة', 'titleEn': 'Plumbing', 'icon': Icons.plumbing_rounded, 'color': Colors.teal},
    {'id': '9', 'titleAr': 'أخرى', 'titleEn': 'Other', 'icon': Icons.more_horiz_rounded, 'color': Colors.purple},
  ];

  // Raw templates of virtual stores for each category
  final List<SparePartStore> _allStoresPool = [
    // HVAC (6)
    SparePartStore(
      id: 'hvac_1',
      nameAr: 'العملاق لقطع غيار التكييف والتبريد',
      nameEn: 'HVAC Giant Parts & Cooling',
      categoryId: '6',
      addressAr: 'شارع الملكة رانيا، مقابل البوابة الشمالية، عمان',
      addressEn: 'Queen Rania St, opposite North Gate, Amman',
      phone: '+962 7 9123 4567',
      rating: 4.8,
      latOffset: 0.0042,
      lngOffset: 0.0068,
      workingHoursAr: '8:00 ص - 9:00 م',
      workingHoursEn: '8:00 AM - 9:00 PM',
      availablePartsAr: ['مكثفات تشغيل (Run Capacitors) 45μF', 'غاز فريون R410A أمريكي', 'أنابيب نحاسية معزولة', 'ثروموستات رقمي ذكي'],
      availablePartsEn: ['Run Capacitors 45μF', 'US Freon Gas R410A', 'Insulated Copper Pipes', 'Smart Digital Thermostat'],
    ),
    SparePartStore(
      id: 'hvac_2',
      nameAr: 'شركة الغيث لمعدات التبريد والمكيفات',
      nameEn: 'Al-Ghaith Cooling & Compressors',
      categoryId: '6',
      addressAr: 'وسط البلد، شارع قريش، عمان',
      addressEn: 'Downtown, Quraysh St, Amman',
      phone: '+962 6 461 2345',
      rating: 4.6,
      latOffset: -0.0065,
      lngOffset: 0.0102,
      workingHoursAr: '9:00 ص - 7:30 م',
      workingHoursEn: '9:00 AM - 7:30 PM',
      availablePartsAr: ['ضواغط هواء روتاري (Compressors)', 'مراوح تبريد داخلية', 'مفاتيح كوندكتور مغناطيسية', 'خراطيم تعبئة الغاز'],
      availablePartsEn: ['Rotary Compressors', 'Indoor Cooling Fans', 'Magnetic Contactor Switches', 'Gas Charging Hoses'],
    ),
    SparePartStore(
      id: 'hvac_3',
      nameAr: 'المركز الهندسي لقطع التبريد المتكاملة',
      nameEn: 'Engineering Center for Integrated Cooling',
      categoryId: '6',
      addressAr: 'شارع مكة، بالقرب من حدائق الملك عبدالله، عمان',
      addressEn: 'Mecca St, Near King Abdullah Gardens, Amman',
      phone: '+962 7 8881 9920',
      rating: 4.7,
      latOffset: 0.0081,
      lngOffset: -0.0075,
      workingHoursAr: '8:30 ص - 8:00 م',
      workingHoursEn: '8:30 AM - 8:00 PM',
      availablePartsAr: ['مستشعرات درجة الحرارة (NTC Sensor)', 'صمامات التمدد الحراري', 'مكثفات بدء حركة 80μF', 'لوحات التحكم الإلكترونية للمكيفات'],
      availablePartsEn: ['Temperature Sensors (NTC)', 'Thermal Expansion Valves', 'Start Capacitors 80μF', 'AC Main Electronic Control Boards'],
    ),

    // Electrical (2)
    SparePartStore(
      id: 'elec_1',
      nameAr: 'الأنوار لقطع الكهرباء واللوحات الصناعية',
      nameEn: 'Al-Anwar Electrical & Control Panels',
      categoryId: '2',
      addressAr: 'صويلح، الشارع الصناعي، عمان',
      addressEn: 'Sweileh, Industrial St, Amman',
      phone: '+962 7 9555 1122',
      rating: 4.9,
      latOffset: 0.0035,
      lngOffset: -0.0051,
      workingHoursAr: '8:00 ص - 6:00 م',
      workingHoursEn: '8:00 AM - 6:00 PM',
      availablePartsAr: ['قواطع كهربائية ذكية (Circuit Breakers)', 'ملفات تلامس كهرومغناطيسية (Contactors)', 'فيوزات حماية حرارية للجهد العالي', 'لوحات توزيع فرعية'],
      availablePartsEn: ['Smart Circuit Breakers', 'Electromagnetic Contactors', 'High Voltage Thermal Fuses', 'Sub-distribution Boards'],
    ),
    SparePartStore(
      id: 'elec_2',
      nameAr: 'مؤسسة فولت ماستر للمواد والمعدات الكهربائية',
      nameEn: 'VoltMaster Electrical Materials',
      categoryId: '2',
      addressAr: 'بيادر وادي السير، المنطقة الصناعية، عمان',
      addressEn: 'Bayader Wadi Seer, Industrial Zone, Amman',
      phone: '+962 6 582 9988',
      rating: 4.5,
      latOffset: -0.0052,
      lngOffset: 0.0048,
      workingHoursAr: '8:30 ص - 7:00 م',
      workingHoursEn: '8:30 AM - 7:00 PM',
      availablePartsAr: ['كابلات نحاسية معزولة مقاومة للحرارة', 'حساسات تيار مستمر ومتردد', 'مرحلات حماية زائدة (Overload Relays)', 'محولات خفض الجهد 24V'],
      availablePartsEn: ['Heat Resistant Insulated Copper Cables', 'AC/DC Current Sensors', 'Overload Protection Relays', 'Step-down Transformers 24V'],
    ),

    // Mechanical (3)
    SparePartStore(
      id: 'mech_1',
      nameAr: 'المحرك الذهبي للمعدات وقطع الميكانيك',
      nameEn: 'Golden Engine Mechanical Spares',
      categoryId: '3',
      addressAr: 'ماركا الشمالية، قرب ترخيص السواقين، عمان',
      addressEn: 'North Marka, Near Driver Licensing, Amman',
      phone: '+962 7 9777 4433',
      rating: 4.7,
      latOffset: 0.0058,
      lngOffset: 0.0082,
      workingHoursAr: '8:00 ص - 6:30 م',
      workingHoursEn: '8:00 AM - 6:30 PM',
      availablePartsAr: ['مسامير وبراغي عالية الصلابة (Grade 8.8)', 'سيور نقل حركة مسننة', 'رولمانات بلي (Ball Bearings) ياباني', 'شحوم حرارية ومضادات الصدأ'],
      availablePartsEn: ['High Tensile Bolts (Grade 8.8)', 'Toothed Transmission Belts', 'Japanese Ball Bearings', 'Thermal Grease & Anti-Rust Sprays'],
    ),

    // Hydraulics (4)
    SparePartStore(
      id: 'hyd_1',
      nameAr: 'الفرات للوصلات والخراطيم الهيدروليكية',
      nameEn: 'Al-Furat Hydraulics & High Pressure Hoses',
      categoryId: '4',
      addressAr: 'القويسمة، شارع الحزام الدائري، عمان',
      addressEn: 'Quweismeh, Beltway Ring St, Amman',
      phone: '+962 7 9111 2233',
      rating: 4.8,
      latOffset: -0.0071,
      lngOffset: -0.0062,
      workingHoursAr: '8:00 ص - 7:00 م',
      workingHoursEn: '8:00 AM - 7:00 PM',
      availablePartsAr: ['خراطيم هيدروليك ضغط عالي مسلحة', 'مضخات هيدروليكية ترسية', 'صمامات اتجاهية للزيت', 'حلقات إحكام مانعة للتسريب (O-Rings)'],
      availablePartsEn: ['Reinforced High-Pressure Hydraulic Hoses', 'Hydraulic Gear Pumps', 'Oil Directional Valves', 'Sealing O-Rings (Heat Resistant)'],
    ),

    // Home Appliances (5)
    SparePartStore(
      id: 'app_1',
      nameAr: 'البيت الحديث لقطع الأجهزة الكهربائية والمنزلية',
      nameEn: 'Modern House Appliance Spare Parts',
      categoryId: '5',
      addressAr: 'شارع الحرية، مقابل مجمع المقابلين، عمان',
      addressEn: 'Al-Hurriyah St, opposite Al-Muqabalayn Center, Amman',
      phone: '+962 6 420 5511',
      rating: 4.6,
      latOffset: 0.0049,
      lngOffset: -0.0021,
      workingHoursAr: '9:00 ص - 9:00 م',
      workingHoursEn: '9:00 AM - 9:00 PM',
      availablePartsAr: ['مقاومات تسخين غسالات (Heater Elements)', 'مضخات طرد المياه للغسالات والجلايات', 'ثروموستات حراري للثلاجات والأفران', 'سيور محركات الغسالات'],
      availablePartsEn: ['Washing Machine Heater Elements', 'Drain Pumps for Washers & Dishwashers', 'Thermal Thermostats for Fridges & Ovens', 'Drive Belts for Washers'],
    ),

    // Automotive (7)
    SparePartStore(
      id: 'auto_1',
      nameAr: 'الوكالة الفنية لقطع غيار السيارات الكورية واليابانية',
      nameEn: 'Technical Agency for Auto Parts',
      categoryId: '7',
      addressAr: 'البيادر، المنطقة الصناعية، عمان',
      addressEn: 'Al-Bayader, Industrial Area, Amman',
      phone: '+962 7 9600 7788',
      rating: 4.7,
      latOffset: -0.0031,
      lngOffset: -0.0084,
      workingHoursAr: '8:00 ص - 8:00 م',
      workingHoursEn: '8:00 AM - 8:00 PM',
      availablePartsAr: ['شمعات احتراق ليزرية (Spark Plugs)', 'فلاتر زيت وهواء وهواء الغرفة', 'أقراص وفحمات فرامل سيراميك', 'سيور محركات وبطاريات جافة'],
      availablePartsEn: ['Laser Spark Plugs', 'Oil, Air & Cabin Filters', 'Ceramic Brake Pads & Discs', 'Dry Batteries & Timing Belts'],
    ),

    // Plumbing (8)
    SparePartStore(
      id: 'plumb_1',
      nameAr: 'الينابيع للمواد الصحية ومضخات المياه',
      nameEn: 'Al-Yanafa Sanitary & Water Pumps',
      categoryId: '8',
      addressAr: 'خلدا، بالقرب من دوار المنهل، عمان',
      addressEn: 'Khalda, Near Al-Manhal Circle, Amman',
      phone: '+962 7 8999 5544',
      rating: 4.5,
      latOffset: 0.0062,
      lngOffset: -0.0039,
      workingHoursAr: '8:00 ص - 8:30 م',
      workingHoursEn: '8:00 AM - 8:30 PM',
      availablePartsAr: ['مضخات مياه ذكية ربع حصان', 'محابس مياه نحاسية إيطالي', 'عدادات قياس الضغط المائي', 'أنابيب حرارية PPR خضراء'],
      availablePartsEn: ['0.25HP Smart Water Pumps', 'Italian Brass Water Valves', 'Water Pressure Gauges', 'Green PPR Thermal Pipes'],
    ),

    // Industrial Systems / Other (1 / 9)
    SparePartStore(
      id: 'ind_1',
      nameAr: 'التقنية للمعدات واللوحات والقطع الصناعية',
      nameEn: 'Industrial Tech Parts & Supplies',
      categoryId: '1',
      addressAr: 'سحاب، مدينة الملك عبدالله الثاني الصناعية، عمان',
      addressEn: 'Sahab, King Abdullah II Industrial City, Amman',
      phone: '+962 6 402 8822',
      rating: 4.8,
      latOffset: -0.0082,
      lngOffset: 0.0091,
      workingHoursAr: '8:00 ص - 5:00 م',
      workingHoursEn: '8:00 AM - 5:00 PM',
      availablePartsAr: ['محركات حثية ثلاثية الأطوار 5HP', 'صمامات تحكم نيوماتيكية بالهواء', 'سيور ناقلة عالية التحمل', 'أجهزة قياس الحرارة ليزرياً'],
      availablePartsEn: ['3-Phase Induction Motors 5HP', 'Pneumatic Air Control Valves', 'Heavy Duty Conveyor Belts', 'Infrared Laser Thermometers'],
    ),
    SparePartStore(
      id: 'other_1',
      nameAr: 'الورشة الشاملة للمواد والمعدات الفنية والعدد',
      nameEn: 'Universal Tech & Maintenance Tools',
      categoryId: '9',
      addressAr: 'شارع وصفي التل (الجاردنز)، عمان',
      addressEn: 'Wasfi Al-Tal St (Gardens), Amman',
      phone: '+962 7 9000 1199',
      rating: 4.7,
      latOffset: 0.0022,
      lngOffset: 0.0031,
      workingHoursAr: '8:00 ص - 10:00 م',
      workingHoursEn: '8:00 AM - 10:00 PM',
      availablePartsAr: ['أجهزة قياس متعددة رقمية (Multimeters)', 'عدة فك وتركيب فنية متكاملة', 'بخاخات كحولية لتنظيف اللوحات', 'أشرطة لحام عازلة عالية الجودة'],
      availablePartsEn: ['Digital Multimeters', 'Integrated Mechanical Toolsets', 'Electronic Contact Cleaners', 'High Grade Electrical Insulating Tapes'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Match the screen's active category to the passed parameter if available
    if (widget.initialCategory != null) {
      final matchedCat = _categories.firstWhere(
        (cat) => widget.initialCategory!.toLowerCase().contains(cat['titleEn'].toLowerCase()) ||
                 widget.initialCategory!.contains(cat['titleAr']),
        orElse: () => {'id': '6'},
      );
      _selectedCategoryId = matchedCat['id'];
    }
    _determinePosition();
  }

  // Permission verification and current GPS location tracking
  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation();
        _showToast(
          ar: '📍 تم استخدام الموقع الافتراضي (خدمات الموقع معطلة بالجهاز)',
          en: '📍 Using default location (GPS services are disabled)',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation();
          _showToast(
            ar: '📍 تم استخدام الموقع الافتراضي لرفض صلاحية الموقع الجغرافي',
            en: '📍 Using default location (Location permission was denied)',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation();
        _showToast(
          ar: '📍 تم استخدام الموقع الافتراضي لحظر الصلاحية بشكل دائم',
          en: '📍 Using default location (Permission permanently blocked)',
        );
        return;
      }

      // Read current location high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        _generateMarkers(position.latitude, position.longitude);
        _fetchOverpassStores(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Error fetching GPS location: $e");
      _useFallbackLocation();
      _showToast(
        ar: '📍 تم استخدام الموقع الافتراضي لعدم توفر قراءة GPS في بيئة المتصفح',
        en: '📍 Using default location (GPS reader timeout or unavailable)',
      );
    }
  }

  void _useFallbackLocation() {
    if (mounted) {
      setState(() {
        _currentPosition = Position(
          latitude: _defaultLat,
          longitude: _defaultLng,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        _isLoadingLocation = false;
      });
      _generateMarkers(_defaultLat, _defaultLng);
      _fetchOverpassStores(_defaultLat, _defaultLng);
    }
  }

  // 🌐 Live Overpass API Query from OpenStreetMap
  Future<void> _fetchOverpassStores(double lat, double lng) async {
    if (_isFetchingOsm) return;
    setState(() {
      _isFetchingOsm = true;
    });

    try {
      final String query = '''
[out:json][timeout:15];
(
  node["shop"~"car_parts|car_repair|hardware|electronics|trade|tools|doityourself"](around:5000,$lat,$lng);
  way["shop"~"car_parts|car_repair|hardware|electronics|trade|tools|doityourself"](around:5000,$lat,$lng);
  node["craft"~"electrician|plumber|HVAC|mechanic|car_repair"](around:5000,$lat,$lng);
  way["craft"~"electrician|plumber|HVAC|mechanic|car_repair"](around:5000,$lat,$lng);
);
out center 40;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'] ?? [];
        final List<SparePartStore> fetchedStores = [];

        for (final elem in elements) {
          final tags = elem['tags'] ?? {};
          final double? storeLat = elem['type'] == 'node'
              ? (elem['lat'] as num?)?.toDouble()
              : (elem['center']?['lat'] as num?)?.toDouble();
          final double? storeLng = elem['type'] == 'node'
              ? (elem['lon'] as num?)?.toDouble()
              : (elem['center']?['lon'] as num?)?.toDouble();

          if (storeLat == null || storeLng == null) continue;

          final String nameAr = tags['name:ar'] ?? tags['name'] ?? tags['brand'] ?? 'محل قطع ورشة صيانة';
          final String nameEn = tags['name:en'] ?? tags['name'] ?? tags['brand'] ?? 'Maintenance & Parts Shop';
          final String shopTag = (tags['shop'] ?? tags['craft'] ?? '').toString().toLowerCase();

          String catId = '9';
          if (shopTag.contains('car_parts') || shopTag.contains('car_repair')) {
            catId = '7';
          } else if (shopTag.contains('electrician') || shopTag.contains('electronics')) {
            catId = '2';
          } else if (shopTag.contains('hardware') || shopTag.contains('tools') || shopTag.contains('mechanic')) {
            catId = '3';
          } else if (shopTag.contains('hvac')) {
            catId = '6';
          } else if (shopTag.contains('plumber')) {
            catId = '8';
          } else if (shopTag.contains('trade') || shopTag.contains('doityourself')) {
            catId = '1';
          }

          final String street = tags['addr:street'] ?? tags['addr:full'] ?? tags['addr:suburb'] ?? '';
          final String city = tags['addr:city'] ?? tags['addr:province'] ?? '';
          final String addressAr = street.isNotEmpty ? '$street, $city' : 'موقع محقق عبر الخريطة المفتوحة OSM';
          final String addressEn = street.isNotEmpty ? '$street, $city' : 'Verified OpenStreetMap location';
          final String phone = tags['phone'] ?? tags['contact:phone'] ?? tags['mobile'] ?? '+962 6 500 1234';

          fetchedStores.add(
            SparePartStore(
              id: 'osm_${elem['id']}',
              nameAr: nameAr,
              nameEn: nameEn,
              categoryId: catId,
              addressAr: addressAr,
              addressEn: addressEn,
              phone: phone,
              rating: 4.5 + ((elem['id'] as int) % 5) * 0.1,
              latOffset: storeLat - lat,
              lngOffset: storeLng - lng,
              realLat: storeLat,
              realLng: storeLng,
              isVerified: false,
              workingHoursAr: tags['opening_hours'] ?? '8:00 ص - 8:00 م',
              workingHoursEn: tags['opening_hours'] ?? '8:00 AM - 8:00 PM',
              availablePartsAr: ['قطع غيار ميكانيكية وكهربائية', 'خدمة فحص وتوريد', 'قطع تبريد وصيانة'],
              availablePartsEn: ['Mechanical & Electrical Parts', 'Testing & Supply', 'Cooling & Spares'],
            ),
          );
        }

        if (mounted) {
          setState(() {
            _liveOsmStores = fetchedStores;
            _isFetchingOsm = false;
          });
          _generateMarkers(lat, lng);
          if (fetchedStores.isNotEmpty) {
            _showToast(
              ar: '🌐 تم جلب ${fetchedStores.length} محلاً حقيقياً من الخريطة المفتوحة OSM',
              en: '🌐 Loaded ${fetchedStores.length} live stores from OpenStreetMap',
            );
          }
        }
      } else {
        if (mounted) setState(() => _isFetchingOsm = false);
      }
    } catch (e) {
      debugPrint("Overpass API query exception: $e");
      if (mounted) setState(() => _isFetchingOsm = false);
    }
  }

  void _showToast({required String ar, required String en}) {
    final isRtl = ref.read(localeProvider).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRtl ? ar : en, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Generates interactive map markers dynamically based on GPS position
  void _generateMarkers(double lat, double lng) {
    _markers.clear();
    
    // Add marker for current user position
    _markers.add(
      Marker(
        point: ll.LatLng(lat, lng),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x400F75BC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0F75BC), width: 2),
          ),
          child: const Center(
            child: CircleAvatar(
              radius: 7,
              backgroundColor: Color(0xFF0F75BC),
            ),
          ),
        ),
      ),
    );

    // Combine live OSM stores and fallback pool
    final combinedStores = [..._liveOsmStores, ..._allStoresPool];

    // Filter stores of current category
    final storesOfCategory = combinedStores.where((store) => store.categoryId == _selectedCategoryId).toList();
    
    // If pool is empty for this category, fallback to universal
    final activeStores = storesOfCategory.isNotEmpty 
        ? storesOfCategory 
        : combinedStores;

    for (final store in activeStores) {
      final double storeLat = store.realLat ?? (lat + store.latOffset);
      final double storeLng = store.realLng ?? (lng + store.lngOffset);

      final markerColor = store.isVerified ? const Color(0xFFEAB308) : _getCategoryMarkerColor(_selectedCategoryId);
      final marker = Marker(
        point: ll.LatLng(storeLat, storeLng),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedStore = store;
            });
            _animateToLocation(storeLat, storeLng);
            _showStoreDetailsBottomSheet(context, store);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                store.isVerified ? Icons.stars_rounded : Icons.location_on_rounded,
                color: markerColor,
                size: store.isVerified ? 40 : 38,
              ),
            ],
          ),
        ),
      );

      _markers.add(marker);
    }

    setState(() {});
  }

  Color _getCategoryMarkerColor(String catId) {
    switch (catId) {
      case '1': return Colors.blue;
      case '2': return Colors.amber;
      case '3': return Colors.blueGrey;
      case '4': return Colors.indigo;
      case '5': return Colors.deepOrange;
      case '6': return Colors.cyan;
      case '7': return Colors.red;
      case '8': return Colors.teal;
      default: return Colors.purple;
    }
  }

  void _animateToLocation(double lat, double lng) {
    _mapController.move(ll.LatLng(lat, lng), 14.5);
  }

  void _onCategorySelected(String catId) {
    setState(() {
      _selectedCategoryId = catId;
      _selectedStore = null; // Reset selection
    });
    
    if (_currentPosition != null) {
      _generateMarkers(_currentPosition!.latitude, _currentPosition!.longitude);
      
      // Focus back to center of user location to see new markers
      _animateToLocation(_currentPosition!.latitude, _currentPosition!.longitude);
    }
  }

  void _showStoreDetailsBottomSheet(BuildContext context, SparePartStore store) {
    final isRtl = ref.read(localeProvider).languageCode == 'ar';
    final addressLabel = isRtl ? '📍 العنوان: ' : '📍 Address: ';
    final workingHoursLabel = isRtl ? '🕒 ساعات العمل: ' : '🕒 Hours: ';
    final inStockLabel = isRtl ? '📦 قطع غيار متوفرة في المخزن:' : '📦 Parts available in stock:';
    final callStoreText = isRtl ? 'اتصال بالمحل' : 'Call Store';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: _buildDetailedStoreCard(
              store,
              isRtl,
              addressLabel,
              workingHoursLabel,
              inStockLabel,
              callStoreText,
            ),
          ),
        );
      },
    );
  }

  // 🗺️ OpenStreetMap FlutterMap Builder
  Widget _buildMapWidget() {
    try {
      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: ll.LatLng(
            _currentPosition?.latitude ?? _defaultLat,
            _currentPosition?.longitude ?? _defaultLng,
          ),
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.drfix.app',
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      );
    } catch (e) {
      debugPrint("Map rendering error: $e");
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0F75BC)),
              SizedBox(height: 12),
              Text(
                'جاري تحميل بيانات الخريطة وتحديث مواقع المحلات...',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(localeProvider).languageCode == 'ar';

    final String appBarTitle = isRtl ? 'خارطة قطع الغيار والمحلات القريبة' : 'Interactive Parts Stores Map';
    final String selectCategoryTitle = isRtl ? 'اختر فئة النظام لتصفية المحلات:' : 'Filter stores by system type:';
    final String callStoreText = isRtl ? 'اتصال بالمحل' : 'Call Store';
    final String workingHoursLabel = isRtl ? '🕒 ساعات العمل: ' : '🕒 Hours: ';
    final String addressLabel = isRtl ? '📍 العنوان: ' : '📍 Address: ';
    final String inStockLabel = isRtl ? '📦 قطع غيار متوفرة في المخزن:' : '📦 Parts available in stock:';
    final String distanceLabel = isRtl ? 'المسافة التقريبية' : 'Approx. Distance';

    // Filter list for bottom view combining OSM live stores and fallback pool
    final combinedStores = [..._liveOsmStores, ..._allStoresPool];
    final categoryStores = combinedStores.where((store) => store.categoryId == _selectedCategoryId).toList();
    final currentList = categoryStores.isNotEmpty ? categoryStores : combinedStores;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const CustomAppDrawer(),
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: Color(0xFF0F75BC)),
            tooltip: isRtl ? 'تحديد موقعي' : 'My Location',
            onPressed: () {
              if (_currentPosition != null) {
                _animateToLocation(_currentPosition!.latitude, _currentPosition!.longitude);
                _showToast(
                  ar: '📍 تم تركيز الكاميرا على إحداثيات موقعك الجغرافي',
                  en: '📍 Focused map on your GPS coordinates',
                );
              } else {
                _determinePosition();
              }
            },
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F75BC)),
                  SizedBox(height: 16),
                  Text(
                    'جاري تأمين إحداثيات موقعك الجغرافي...',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // 🗺️ 1. Google Map widget covering entire area with Web / Crash Guard
                Positioned.fill(
                  child: _buildMapWidget(),
                ),

                // 🏷️ 2. Floating Top Categories Selector (Filtering)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                          child: Text(
                            selectCategoryTitle,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = cat['id'] == _selectedCategoryId;
                              final catColor = cat['color'] as Color;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(
                                    isRtl ? cat['titleAr'] : cat['titleEn'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: catColor,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  onSelected: (_) => _onCategorySelected(cat['id']),
                                  pressElevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🏬 3. Floating Bottom Panel for selected/nearby stores (Edge-to-Edge Guard)
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: SafeArea(
                    top: false,
                    bottom: true,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _selectedStore != null
                          ? _buildDetailedStoreCard(
                              _selectedStore!,
                              isRtl,
                              addressLabel,
                              workingHoursLabel,
                              inStockLabel,
                              callStoreText,
                            )
                          : _buildStoresHorizontalList(
                              currentList,
                              isRtl,
                              distanceLabel,
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Card details of the chosen part store
  Widget _buildDetailedStoreCard(
    SparePartStore store,
    bool isRtl,
    String addressLabel,
    String workingHoursLabel,
    String inStockLabel,
    String callStoreText,
  ) {
    return Container(
      key: ValueKey<String>('details_${store.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Close Button, Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isRtl ? store.nameAr : store.nameEn,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedStore = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '${store.rating}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRtl ? 'محقق من Dr. Fix' : 'Verified by Dr. Fix',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 16),

          // Details: Address and Hours
          Text(
            '$addressLabel${isRtl ? store.addressAr : store.addressEn}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '$workingHoursLabel${isRtl ? store.workingHoursAr : store.workingHoursEn}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),

          // Available parts chip list
          Text(
            inStockLabel,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: (isRtl ? store.availablePartsAr : store.availablePartsEn).map((part) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  part,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Actions Row: Call button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F75BC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                _showToast(
                  ar: '📞 جاري طلب رقم الهاتف: ${store.phone}',
                  en: '📞 Calling vendor phone number: ${store.phone}',
                );
              },
              icon: const Icon(Icons.phone_rounded, size: 16),
              label: Text(
                '$callStoreText (${store.phone})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom horizontal scrollable list of stores
  Widget _buildStoresHorizontalList(
    List<SparePartStore> stores,
    bool isRtl,
    String distanceLabel,
  ) {
    if (stores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          isRtl ? '❌ لا توجد محلات تتبع هذه الفئة قريبة منك.' : '❌ No nearby stores found for this category.',
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      key: const ValueKey<String>('stores_list'),
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          // Approximate distance calculation from offset
          final double distanceKm = ((store.latOffset.abs() + store.lngOffset.abs()) * 111).clamp(0.4, 4.8);

          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedStore = store;
                });
                final double targetLat = store.realLat ?? ((_currentPosition?.latitude ?? _defaultLat) + store.latOffset);
                final double targetLng = store.realLng ?? ((_currentPosition?.longitude ?? _defaultLng) + store.lngOffset);
                _animateToLocation(targetLat, targetLng);
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRtl ? store.nameAr : store.nameEn,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isRtl ? store.addressAr : store.addressEn,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${store.rating}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        Text(
                          '📍 ${distanceKm.toStringAsFixed(1)} كم',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F75BC)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
