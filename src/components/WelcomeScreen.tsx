import React, { useState } from 'react';
import { translations, Language } from '../utils/translations';
import { Globe, ShieldAlert, Cpu, Timer, ThumbsUp, MessageSquare } from 'lucide-react';

interface WelcomeScreenProps {
  lang: Language;
  setLang: (l: Language) => void;
  onAccept: () => void;
  onNavigateToForum: () => void;
}

export const WelcomeScreen: React.FC<WelcomeScreenProps> = ({
  lang,
  setLang,
  onAccept,
  onNavigateToForum
}) => {
  const t = translations[lang];
  const isRtl = lang === 'ar';
  const [acceptedDisclaimer, setAcceptedDisclaimer] = useState(false);
  const [showFullDisclaimer, setShowFullDisclaimer] = useState(false);

  const toggleLang = () => {
    setLang(lang === 'ar' ? 'en' : 'ar');
  };

  return (
    <div className="flex-1 flex flex-col items-center justify-center p-4 md:p-8 max-w-4xl mx-auto w-full">
      {/* Top Language Toggle */}
      <div className="w-full flex justify-end mb-6">
        <button
          id="toggle-lang-btn"
          onClick={toggleLang}
          className="flex items-center gap-2 px-4 py-2 bg-white rounded-xl shadow-sm border border-slate-100 text-slate-700 hover:bg-slate-50 transition cursor-pointer font-medium text-sm"
        >
          <Globe className="w-4 h-4 text-blue-600" />
          <span>{lang === 'ar' ? 'English' : 'العربية'}</span>
        </button>
      </div>

      {/* Main Brand Section */}
      <div className="text-center mb-8">
        <div className="inline-flex items-center justify-center w-20 h-20 bg-blue-600 rounded-3xl text-white shadow-lg shadow-blue-500/30 mb-4 animate-bounce-slow">
          <span className="text-4xl">👨‍🔧</span>
        </div>
        <h1 className="text-4xl md:text-5xl font-black tracking-tight text-slate-900 mb-2">
          {t.app_title}
        </h1>
        <p className="text-lg text-slate-600 max-w-xl mx-auto leading-relaxed">
          {t.app_tagline}
        </p>
      </div>

      {/* Stats Board */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 w-full mb-8">
        <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
            <Cpu className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-bold text-slate-900">{t.stat_diagnostics_val}</div>
            <div className="text-xs text-slate-500 font-medium">{t.stat_diagnostics_lbl}</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
            <Timer className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-bold text-slate-900">{t.stat_time_val}</div>
            <div className="text-xs text-slate-500 font-medium">{t.stat_time_lbl}</div>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-violet-50 text-violet-600 rounded-xl">
            <ThumbsUp className="w-6 h-6" />
          </div>
          <div>
            <div className="text-2xl font-bold text-slate-900">{t.stat_accuracy_val}</div>
            <div className="text-xs text-slate-500 font-medium">{t.stat_accuracy_lbl}</div>
          </div>
        </div>
      </div>

      {/* Trust & Geo Coverage */}
      <div className="flex flex-wrap items-center justify-center gap-3 w-full mb-8 py-3 px-4 bg-slate-100/60 rounded-xl text-slate-600 text-sm font-medium">
        <span className="bg-blue-100 text-blue-800 px-2.5 py-0.5 rounded text-xs">{t.trust_b1}</span>
        <span className="bg-emerald-100 text-emerald-800 px-2.5 py-0.5 rounded text-xs">{t.trust_b2}</span>
        <span className="bg-purple-100 text-purple-800 px-2.5 py-0.5 rounded text-xs">{t.trust_b3}</span>
        <span className="bg-amber-100 text-amber-800 px-2.5 py-0.5 rounded text-xs">{t.trust_b4}</span>
      </div>

      {/* Interactive Forum Invite card */}
      <div className="bg-gradient-to-r from-blue-900 to-indigo-950 text-white rounded-2xl p-6 w-full mb-8 shadow-md relative overflow-hidden">
        <div className="absolute top-0 right-0 w-48 h-48 bg-blue-500/10 rounded-full blur-2xl pointer-events-none"></div>
        <div className="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-2 text-blue-300 text-sm font-bold">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
              {t.forum_stats_online}
            </div>
            <h3 className="text-lg font-bold mb-1">{t.forum_card_title}</h3>
            <p className="text-sm text-slate-300 max-w-md">{t.forum_card_subtitle}</p>
          </div>
          <button
            id="go-to-forum-btn"
            onClick={onNavigateToForum}
            className="px-5 py-2.5 bg-blue-600 hover:bg-blue-500 rounded-xl text-sm font-bold transition flex items-center gap-2 shadow-lg shadow-blue-900/30 cursor-pointer text-white"
          >
            <MessageSquare className="w-4 h-4" />
            <span>{t.forum_card_btn}</span>
          </button>
        </div>
      </div>

      {/* Main Disclaimer Action Area */}
      <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-md w-full">
        <div className="flex items-start gap-3 mb-4">
          <ShieldAlert className="w-6 h-6 text-amber-500 shrink-0 mt-0.5" />
          <div>
            <h3 className="font-bold text-slate-900 text-base">{t.disclaimer_title}</h3>
            <p className="text-sm text-slate-500 mt-1 leading-relaxed">
              {showFullDisclaimer 
                ? t.disclaimer_body 
                : `${t.disclaimer_body.slice(0, 160)}...`}
              <button 
                onClick={() => setShowFullDisclaimer(!showFullDisclaimer)}
                className="text-blue-600 font-bold hover:underline ml-1 cursor-pointer focus:outline-none text-xs"
              >
                {showFullDisclaimer ? (isRtl ? 'عرض أقل' : 'Read Less') : (isRtl ? 'قراءة المزيد' : 'Read More')}
              </button>
            </p>
          </div>
        </div>

        {/* Disclaimer acceptance check */}
        <label className="flex items-start gap-3 p-3 bg-slate-50 rounded-xl border border-slate-100 mb-6 cursor-pointer hover:bg-slate-100/50 transition">
          <input
            id="accept-checkbox"
            type="checkbox"
            checked={acceptedDisclaimer}
            onChange={(e) => setAcceptedDisclaimer(e.target.checked)}
            className="mt-1 w-4.5 h-4.5 text-blue-600 border-slate-300 rounded focus:ring-blue-500"
          />
          <span className="text-sm font-medium text-slate-700 select-none">
            {isRtl 
              ? 'أوافق تماماً على شروط إخلاء المسؤولية الميدانية وأتعهد باتباع معايير السلامة المهنية.' 
              : 'I fully agree to the field disclaimer terms and commit to safety standards.'}
          </span>
        </label>

        {/* Enter Guest Button */}
        <button
          id="accept-and-enter-btn"
          disabled={!acceptedDisclaimer}
          onClick={onAccept}
          className={`w-full py-4 rounded-xl font-bold text-lg transition flex items-center justify-center gap-2 shadow-lg cursor-pointer ${
            acceptedDisclaimer 
              ? 'bg-blue-600 hover:bg-blue-500 text-white shadow-blue-500/20' 
              : 'bg-slate-200 text-slate-400 shadow-none cursor-not-allowed'
          }`}
        >
          <span>{t.accept_btn}</span>
        </button>

        <div className="mt-4 text-center">
          <span className="text-xs text-slate-400 font-medium">
            {t.privacy_hint}
          </span>
        </div>
      </div>
    </div>
  );
};
export default WelcomeScreen;
