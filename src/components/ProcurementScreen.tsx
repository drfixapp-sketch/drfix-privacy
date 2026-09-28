import React, { useState, useEffect } from 'react';
import { translations, Language } from '../utils/translations';
import { PromoCode } from '../types';
import { getCurrencyBasedOnLocation } from '../utils/geo';
import { ArrowRight, MapPin, Tag, Phone, ShieldCheck, HelpCircle } from 'lucide-react';

interface ProcurementScreenProps {
  lang: Language;
  onBack: () => void;
  promoCodes: PromoCode[];
}

interface Vendor {
  id: string;
  nameAr: string;
  nameEn: string;
  phone: string;
  addressAr: string;
  addressEn: string;
  specialtyAr: string;
  specialtyEn: string;
  x: number; // custom SVG map coordinates
  y: number;
}

export const ProcurementScreen: React.FC<ProcurementScreenProps> = ({
  lang,
  onBack,
  promoCodes
}) => {
  const t = translations[lang];
  const isRtl = lang === 'ar';

  const [currency, setCurrency] = useState(isRtl ? 'ريال سعودي' : 'SAR');
  const [locationName, setLocationName] = useState(isRtl ? 'الخليج العربي (افتراضي)' : 'Arabian Gulf (Default)');
  const [loadingGeo, setLoadingGeo] = useState(true);
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);

  // Load geolocated currency on mount
  useEffect(() => {
    async function detectGeo() {
      setLoadingGeo(true);
      const res = await getCurrencyBasedOnLocation(isRtl);
      setCurrency(res.currency);
      setLocationName(res.locationName);
      setLoadingGeo(false);
    }
    detectGeo();
  }, [isRtl]);

  // Seed sample local vendors with coordinates for our custom interactive SVG map
  const vendors: Vendor[] = [
    {
      id: 'v1',
      nameAr: 'شركة الهدد لقطع غيار التبريد والتكييف',
      nameEn: 'Al-Haddad HVAC & Cooling Parts Co.',
      phone: '+962 7 9123 4567',
      addressAr: 'وسط البلد، عمان، الأردن',
      addressEn: 'Downtown, Amman, Jordan',
      specialtyAr: 'مكثفات، ضواغط، غاز فريون',
      specialtyEn: 'Capacitors, Compressors, Refrigerant Gas',
      x: 35,
      y: 45
    },
    {
      id: 'v2',
      nameAr: 'مركز تكنولوجيا الهيدروليك والميكانيك',
      nameEn: 'Hydraulics & Mechanics Tech Center',
      phone: '+966 50 123 4567',
      addressAr: 'المنطقة الصناعية، الرياض، السعودية',
      addressEn: 'Industrial Area, Riyadh, KSA',
      specialtyAr: 'مضخات، صمامات، خراطيم ضغط عالي',
      specialtyEn: 'Pumps, Valves, High Pressure Hoses',
      x: 65,
      y: 55
    },
    {
      id: 'v3',
      nameAr: 'مستودع الشرق للأجهزة والقطع الكهربائية',
      nameEn: 'Al-Sharq Electrical Spare Parts Depot',
      phone: '+962 6 551 2345',
      addressAr: 'شارع مكة، عمان، الأردن',
      addressEn: 'Mecca Street, Amman, Jordan',
      specialtyAr: 'ريليهات، فيوزات، لوحات تحكم ذكية',
      specialtyEn: 'Relays, Fuses, Smart Control Boards',
      x: 42,
      y: 35
    }
  ];

  return (
    <div className="flex-1 p-4 md:p-8 max-w-4xl mx-auto w-full space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center bg-white p-4 rounded-2xl border border-slate-100 shadow-sm">
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-slate-700 hover:text-slate-900 font-bold cursor-pointer text-sm"
        >
          <ArrowRight className={`w-4 h-4 ${isRtl ? '' : 'rotate-180'}`} />
          <span>{t.back_btn}</span>
        </button>

        <span className="text-xs font-bold text-blue-600 bg-blue-50 px-3 py-1.5 rounded-xl">
          🌐 {t.procurement_title}
        </span>
      </div>

      {/* Geolocation currency and coordinate detection badge */}
      <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
            <MapPin className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider block">
              {isRtl ? 'الموقع الجغرافي النشط للأسعار' : 'Active Location Pricing'}
            </span>
            <span className="font-extrabold text-slate-900 text-sm">
              {loadingGeo ? (isRtl ? 'جاري تحديد الموقع وتعديل الأسعار...' : 'Detecting location...') : locationName}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2 bg-emerald-50 text-emerald-800 px-4 py-2 rounded-xl text-xs font-bold border border-emerald-100">
          <span>{isRtl ? 'العملة الحالية:' : 'Active Currency:'}</span>
          <span>{currency}</span>
        </div>
      </div>

      {/* Interactive Map Visual Directory */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Map panel (2 Cols) */}
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
          <h3 className="font-bold text-slate-900 border-b border-slate-100 pb-3 text-sm flex items-center gap-2">
            <span>🗺️</span>
            <span>{t.map_section_title}</span>
          </h3>

          {/* Interactive Styled vector map of Jordan/GCC region */}
          <div className="relative bg-slate-950 rounded-2xl aspect-[16/10] overflow-hidden border border-slate-800 flex items-center justify-center">
            {/* Ambient grid background overlay */}
            <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.03)_1px,transparent_1px)] bg-[size:20px_20px]"></div>

            {/* Simulated Geography Outlines */}
            <svg className="absolute inset-0 w-full h-full opacity-30 stroke-slate-700 stroke-[1.5]" viewBox="0 0 100 100" fill="none">
              <path d="M20 30 Q35 25 45 40 T65 45 T85 55" />
              <path d="M15 60 Q30 70 45 60 T75 75" />
              <path d="M30 10 L45 30 L55 25 Z" />
            </svg>

            {/* Clickable Map Pins */}
            {vendors.map((vendor) => {
              const isActive = selectedVendor?.id === vendor.id;
              return (
                <button
                  key={vendor.id}
                  onClick={() => setSelectedVendor(vendor)}
                  className="absolute group transition duration-300"
                  style={{ left: `${vendor.x}%`, top: `${vendor.y}%` }}
                >
                  {/* Pin Circle effect */}
                  <div className="relative flex items-center justify-center">
                    <span className={`absolute inline-flex h-8 w-8 rounded-full opacity-75 animate-ping ${isActive ? 'bg-blue-400' : 'bg-amber-400'}`}></span>
                    <span className={`relative inline-flex rounded-full h-4.5 w-4.5 shadow-md border-2 border-white ${isActive ? 'bg-blue-600' : 'bg-amber-500'}`}></span>
                  </div>

                  {/* Tiny Label Tooltip */}
                  <div className="absolute top-6 left-1/2 transform -translate-x-1/2 bg-slate-900 text-white text-[10px] font-bold px-2 py-0.5 rounded shadow opacity-0 group-hover:opacity-100 transition whitespace-nowrap z-30">
                    {isRtl ? vendor.nameAr : vendor.nameEn}
                  </div>
                </button>
              );
            })}

            {/* Instruction overlay */}
            <div className="absolute bottom-3 left-3 bg-slate-900/80 backdrop-blur text-[10px] text-slate-300 px-2.5 py-1 rounded-lg border border-slate-700 font-bold">
              📍 {isRtl ? 'اضغط على النقاط النشطة لاستعراض هواتف ومواقع المحلات' : 'Tap on map points to view vendor contacts'}
            </div>
          </div>

          {/* Selected Vendor Detail Drawer */}
          {selectedVendor ? (
            <div className="p-4 bg-blue-50/50 border border-blue-100 rounded-xl space-y-3 animate-fade-in">
              <div className="flex justify-between items-start">
                <div>
                  <h4 className="font-extrabold text-sm text-slate-900">
                    {isRtl ? selectedVendor.nameAr : selectedVendor.nameEn}
                  </h4>
                  <p className="text-xs text-slate-500 font-semibold mt-0.5">
                    ⚙️ {isRtl ? 'التخصص:' : 'Specialty:'} {isRtl ? selectedVendor.specialtyAr : selectedVendor.specialtyEn}
                  </p>
                </div>
                <button
                  onClick={() => setSelectedVendor(null)}
                  className="text-xs text-slate-400 hover:text-slate-600 font-bold"
                >
                  ✕
                </button>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2 border-t border-slate-100 text-xs font-semibold text-slate-700">
                <div className="flex items-center gap-2">
                  <MapPin className="w-4 h-4 text-blue-600" />
                  <span>{isRtl ? selectedVendor.addressAr : selectedVendor.addressEn}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="w-4 h-4 text-blue-600" />
                  <span>{selectedVendor.phone}</span>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-4 bg-slate-50 rounded-xl border border-dashed border-slate-200">
              <span className="text-xs text-slate-400 font-semibold">
                {isRtl ? 'اختر متجراً من الخريطة لاستعراض البيانات المعتمدة' : 'Select a store from the map to view verified specs'}
              </span>
            </div>
          )}
        </div>

        {/* Right Panel: Verified Partner discount codes (1 Col) */}
        <div className="space-y-6">
          {/* Discount cards */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
            <h3 className="font-bold text-slate-900 border-b border-slate-100 pb-3 text-sm flex items-center gap-2">
              <Tag className="w-4.5 h-4.5 text-blue-600" />
              <span>{t.discount_section_title}</span>
            </h3>

            {/* Dynamic discount cards from context */}
            {promoCodes.length > 0 ? (
              <div className="space-y-3">
                {promoCodes.map((promo, idx) => (
                  <div
                    key={idx}
                    className="p-4 bg-gradient-to-br from-emerald-500/5 to-teal-500/10 border-2 border-emerald-100 border-dashed rounded-xl flex justify-between items-center"
                  >
                    <div>
                      <span className="text-xs font-extrabold text-slate-900 block">{promo.companyName}</span>
                      <span className="text-xs font-semibold text-emerald-700">
                        {isRtl ? `خصم بقيمة ${promo.discountPercentage}%` : `${promo.discountPercentage}% Discount`}
                      </span>
                    </div>

                    <div className="bg-white px-3 py-1.5 rounded-lg border border-emerald-200 text-center shadow-sm">
                      <span className="text-xs font-mono font-black text-emerald-800 tracking-wider block">{promo.code}</span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-8">
                <Tag className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                <p className="text-xs text-slate-400 font-bold">{t.no_promo_active}</p>
                <p className="text-[10px] text-slate-400 mt-1">
                  {isRtl ? 'يمكن تفعيل أكواد شركاء قطع الغيار من لوحة الإدارة.' : 'Partner deals can be added by administrator from dashboard.'}
                </p>
              </div>
            )}
          </div>

          {/* Trust shield certification */}
          <div className="bg-gradient-to-br from-blue-900 to-indigo-950 text-white p-5 rounded-2xl space-y-2 shadow-sm relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/10 rounded-full blur-2xl pointer-events-none"></div>
            <div className="flex items-center gap-2 mb-1">
              <ShieldCheck className="w-5 h-5 text-emerald-400 shrink-0" />
              <h4 className="font-extrabold text-xs text-white uppercase tracking-wider">{isRtl ? 'أمان وجودة الصيانة' : 'Technical Quality Pledge'}</h4>
            </div>
            <p className="text-[10px] text-slate-300 leading-relaxed font-semibold">
              {isRtl
                ? 'جميع الشركات ومزودي القطع في التطبيق تم مراجعة تراخيصها التجارية وجودة منتجاتها فحصاً ميدانياً دورياً للحفاظ على جودة الأداء الصناعي بالأردن والخليج.'
                : 'All listed parts suppliers undergo quarterly license audits and product durability checks to guarantee reliability and compliance in Jordan and GCC markets.'}
            </p>
          </div>
        </div>
      </div>

      {/* Dynamic Legal Disclaimer Bar */}
      <div className="bg-slate-50 border border-slate-200 text-slate-600 rounded-2xl p-5 text-right font-semibold">
        <h4 className="font-extrabold text-xs text-slate-800 mb-1 flex items-center justify-end gap-1.5">
          <HelpCircle className="w-4 h-4 text-slate-500" />
          <span>{t.disclaimer_proc_title}</span>
        </h4>
        <p className="text-[10px] text-slate-500 leading-relaxed">
          {t.disclaimer_proc_text}
        </p>
      </div>
    </div>
  );
};
export default ProcurementScreen;
