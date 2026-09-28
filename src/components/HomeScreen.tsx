import React, { useState } from 'react';
import { translations, Language } from '../utils/translations';
import { EngineeringCategory } from '../types';
import * as LucideIcons from 'lucide-react';

interface HomeScreenProps {
  lang: Language;
  onSelectCategory: (catId: string) => void;
  onNavigateToForum: () => void;
  onNavigateToProcurement: () => void;
  onNavigateToAdmin: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({
  lang,
  onSelectCategory,
  onNavigateToForum,
  onNavigateToProcurement,
  onNavigateToAdmin
}) => {
  const t = translations[lang];
  const isRtl = lang === 'ar';
  const [searchQuery, setSearchQuery] = useState('');

  // Define categories list with IDs and icon mappings
  const categories: EngineeringCategory[] = [
    { id: 'industrial', titleAr: 'أنظمة صناعية', titleEn: 'Industrial Systems', icon: 'Cpu', themeColor: 'indigo' },
    { id: 'electrical', titleAr: 'كهرباء', titleEn: 'Electrical', icon: 'Zap', themeColor: 'amber' },
    { id: 'mechanical', titleAr: 'ميكانيك', titleEn: 'Mechanics', icon: 'Settings', themeColor: 'slate' },
    { id: 'hydraulic', titleAr: 'أنظمة هيدروليك', titleEn: 'Hydraulics', icon: 'Droplet', themeColor: 'blue' },
    { id: 'appliances', titleAr: 'أجهزة منزلية', titleEn: 'Home Appliances', icon: 'Tv', themeColor: 'pink' },
    { id: 'hvac', titleAr: 'تكييف وتبريد', titleEn: 'HVAC & Cooling', icon: 'Wind', themeColor: 'cyan' },
    { id: 'automotive', titleAr: 'سيارات ومركبات', titleEn: 'Automotive / Cars', icon: 'Car', themeColor: 'red' },
    { id: 'plumbing', titleAr: 'سباكة', titleEn: 'Plumbing', icon: 'Wrench', themeColor: 'emerald' },
    { id: 'other', titleAr: 'أخرى', titleEn: 'Other', icon: 'Hammer', themeColor: 'teal' }
  ];

  // Search logic matching Arabic or English titles
  const filteredCategories = categories.filter(cat => {
    const q = searchQuery.toLowerCase().trim();
    if (!q) return true;
    return cat.titleAr.toLowerCase().includes(q) || cat.titleEn.toLowerCase().includes(q);
  });

  // Dynamically resolve lucide icons
  const renderIcon = (iconName: string, colorClass: string) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const IconComponent = (LucideIcons as any)[iconName];
    if (IconComponent) {
      return <IconComponent className={`w-8 h-8 ${colorClass}`} />;
    }
    return <LucideIcons.Hammer className={`w-8 h-8 ${colorClass}`} />;
  };

  const getColorClasses = (color: string) => {
    switch (color) {
      case 'indigo': return { bg: 'bg-indigo-50 hover:bg-indigo-100/80', border: 'border-indigo-100', text: 'text-indigo-600' };
      case 'amber': return { bg: 'bg-amber-50 hover:bg-amber-100/80', border: 'border-amber-100', text: 'text-amber-600' };
      case 'slate': return { bg: 'bg-slate-100 hover:bg-slate-200/80', border: 'border-slate-200', text: 'text-slate-700' };
      case 'blue': return { bg: 'bg-blue-50 hover:bg-blue-100/80', border: 'border-blue-100', text: 'text-blue-600' };
      case 'pink': return { bg: 'bg-pink-50 hover:bg-pink-100/80', border: 'border-pink-100', text: 'text-pink-600' };
      case 'cyan': return { bg: 'bg-cyan-50 hover:bg-cyan-100/80', border: 'border-cyan-100', text: 'text-cyan-600' };
      case 'red': return { bg: 'bg-red-50 hover:bg-red-100/80', border: 'border-red-100', text: 'text-red-600' };
      case 'emerald': return { bg: 'bg-emerald-50 hover:bg-emerald-100/80', border: 'border-emerald-100', text: 'text-emerald-600' };
      default: return { bg: 'bg-teal-50 hover:bg-teal-100/80', border: 'border-teal-100', text: 'text-teal-600' };
    }
  };

  return (
    <div className="flex-1 flex flex-col p-4 md:p-8 max-w-5xl mx-auto w-full">
      {/* Title */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
          <span>🛠️</span>
          <span>{t.home_title}</span>
        </h2>
      </div>

      {/* Live Search Input */}
      <div className="relative mb-8 shadow-sm rounded-2xl">
        <div className={`absolute inset-y-0 ${isRtl ? 'right-4' : 'left-4'} flex items-center pointer-events-none`}>
          <LucideIcons.Search className="h-5 w-5 text-slate-400" />
        </div>
        <input
          id="category-search-input"
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder={t.search_hint}
          className={`w-full py-4 ${isRtl ? 'pr-12 pl-4 text-right' : 'pl-12 pr-4 text-left'} bg-white border border-slate-200 rounded-2xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-slate-800 font-medium transition`}
        />
        {searchQuery && (
          <button
            onClick={() => setSearchQuery('')}
            className={`absolute inset-y-0 ${isRtl ? 'left-4' : 'right-4'} flex items-center text-slate-400 hover:text-slate-600`}
          >
            <LucideIcons.X className="w-5 h-5" />
          </button>
        )}
      </div>

      {/* Grid of Categories */}
      {filteredCategories.length > 0 ? (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 md:gap-6 mb-10">
          {filteredCategories.map((cat) => {
            const colors = getColorClasses(cat.themeColor);
            return (
              <button
                key={cat.id}
                id={`cat-card-${cat.id}`}
                onClick={() => onSelectCategory(cat.id)}
                className={`flex flex-col items-center justify-center p-6 bg-white border ${colors.border} rounded-2xl shadow-sm transition duration-300 hover:shadow-md ${colors.bg} cursor-pointer text-center group`}
              >
                <div className="p-4 bg-white rounded-2xl shadow-sm group-hover:scale-105 transition mb-3">
                  {renderIcon(cat.icon, colors.text)}
                </div>
                <span className="font-bold text-slate-800 text-sm md:text-base leading-tight">
                  {isRtl ? cat.titleAr : cat.titleEn}
                </span>
              </button>
            );
          })}
        </div>
      ) : (
        <div className="text-center py-12 bg-white rounded-2xl border border-slate-100 shadow-sm mb-10">
          <LucideIcons.Hammer className="w-12 h-12 text-slate-300 mx-auto mb-3" />
          <p className="text-slate-500 font-medium">{t.no_results}</p>
        </div>
      )}

      {/* Quick Community & Admin Navigation Shortcut */}
      <div className="bg-slate-100 p-4 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4 mt-auto">
        <div className="flex items-center gap-2 text-slate-600 text-sm font-medium">
          <LucideIcons.Sparkles className="w-4 h-4 text-amber-500" />
          <span>
            {isRtl 
              ? 'هل تبحث عن أسعار القطع أو تود تصفح منتدى الفنيين مباشرة؟' 
              : 'Looking for parts or want to browse the community forum directly?'}
          </span>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            onClick={onNavigateToProcurement}
            className="px-4 py-2 bg-white text-slate-700 border border-slate-200 text-xs font-bold rounded-xl hover:bg-slate-50 transition cursor-pointer"
          >
            🗺️ {isRtl ? 'مستكشف القطع والمحلات' : 'Parts Explorer'}
          </button>
          <button
            onClick={onNavigateToForum}
            className="px-4 py-2 bg-blue-600 text-white text-xs font-bold rounded-xl hover:bg-blue-500 transition cursor-pointer shadow-sm shadow-blue-500/10"
          >
            💬 {isRtl ? 'منتدى الفنيين' : 'Forum Community'}
          </button>
          <button
            onClick={onNavigateToAdmin}
            className="px-4 py-2 bg-slate-800 text-slate-300 text-xs font-bold rounded-xl hover:bg-slate-700 transition cursor-pointer"
          >
            ⚙️ {isRtl ? 'الأدمن' : 'Admin'}
          </button>
        </div>
      </div>
    </div>
  );
};
export default HomeScreen;
