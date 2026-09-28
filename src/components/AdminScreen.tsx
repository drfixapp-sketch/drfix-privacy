import React, { useState } from 'react';
import { translations, Language } from '../utils/translations';
import { ForumPost, PromoCode } from '../types';
import { ArrowRight, Trash2, Key, Tag, ShieldAlert } from 'lucide-react';

interface AdminScreenProps {
  lang: Language;
  onBack: () => void;
  forumPosts: ForumPost[];
  promoCodes: PromoCode[];
  onApprovePost: (postId: string) => void;
  onRejectPost: (postId: string) => void;
  onApproveReply: (postId: string, replyId: string) => void;
  onRejectReply: (postId: string, replyId: string) => void;
  onAddPromo: (promo: PromoCode) => void;
  onDeletePromo: (code: string) => void;
}

export const AdminScreen: React.FC<AdminScreenProps> = ({
  lang,
  onBack,
  forumPosts,
  promoCodes,
  onApprovePost,
  onRejectPost,
  onApproveReply,
  onRejectReply,
  onAddPromo,
  onDeletePromo
}) => {
  const t = translations[lang];
  const isRtl = lang === 'ar';

  const [pin, setPin] = useState('');
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [pinError, setPinError] = useState(false);

  // Dashboard Tabs
  const [activeTab, setActiveTab] = useState<'moderation' | 'promos'>('moderation');

  // New Promo Code Form States
  const [companyName, setCompanyName] = useState('');
  const [promoCodeValue, setPromoCodeValue] = useState('');
  const [discountPercent, setDiscountPercent] = useState('');

  const handlePinSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (pin === '2026') {
      setIsAuthenticated(true);
      setPinError(false);
    } else {
      setPinError(true);
    }
  };

  const handleCreatePromoSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!companyName.trim() || !promoCodeValue.trim() || !discountPercent.trim()) return;

    onAddPromo({
      companyName: companyName.trim(),
      code: promoCodeValue.trim().toUpperCase(),
      discountPercentage: parseInt(discountPercent) || 10
    });

    // Reset Form
    setCompanyName('');
    setPromoCodeValue('');
    setDiscountPercent('');
  };

  // Find all pending posts (isApproved === false)
  const pendingPosts = forumPosts.filter(p => !p.isApproved);

  // Find all pending replies across all posts
  const pendingReplies: { postId: string; postTitle: string; replyId: string; author: string; content: string; specialty: string }[] = [];
  forumPosts.forEach(post => {
    post.replies.forEach(reply => {
      if (!reply.isApproved) {
        pendingReplies.push({
          postId: post.id,
          postTitle: post.title,
          replyId: reply.id,
          author: reply.author,
          content: reply.content,
          specialty: reply.specialty
        });
      }
    });
  });

  if (!isAuthenticated) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-4 md:p-8 max-w-md mx-auto w-full">
        {/* Back */}
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-slate-600 hover:text-slate-900 mb-6 font-bold cursor-pointer self-start bg-white px-4 py-2 rounded-xl shadow-sm border border-slate-100"
        >
          <ArrowRight className={`w-4 h-4 ${isRtl ? '' : 'rotate-180'}`} />
          <span>{t.back_btn}</span>
        </button>

        {/* PIN Entry Box */}
        <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-lg w-full space-y-4">
          <div className="text-center">
            <div className="inline-flex p-3 bg-blue-50 text-blue-600 rounded-2xl mb-2">
              <Key className="w-6 h-6 animate-pulse" />
            </div>
            <h3 className="text-lg font-black text-slate-900">{isRtl ? 'بوابة دخول الإدارة الفنية' : 'Admin Security Access'}</h3>
            <p className="text-xs text-slate-400 font-bold mt-1">
              {isRtl ? 'يرجى إدخال الرمز السري الفني للمطابقة (الرمز: 2026)' : 'Enter PIN code to proceed (PIN: 2026)'}
            </p>
          </div>

          {pinError && (
            <div className="p-3 bg-red-50 border border-red-200 text-red-900 text-xs font-semibold rounded-xl flex items-center gap-2">
              <ShieldAlert className="w-4.5 h-4.5 text-red-600 shrink-0" />
              <span>{t.admin_pin_error}</span>
            </div>
          )}

          <form onSubmit={handlePinSubmit} className="space-y-4">
            <input
              id="admin-pin-field"
              type="password"
              required
              value={pin}
              onChange={(e) => setPin(e.target.value)}
              placeholder="••••"
              className="w-full text-center py-4 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 font-bold text-2xl tracking-widest text-slate-800"
            />

            <button
              id="admin-login-btn"
              type="submit"
              className="w-full py-3.5 bg-slate-900 hover:bg-slate-800 text-white font-extrabold text-sm rounded-xl transition cursor-pointer shadow-md"
            >
              {isRtl ? 'المطابقة والعبور' : 'Authenticate'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 p-4 md:p-8 max-w-4xl mx-auto w-full space-y-6">
      {/* Top Controls */}
      <div className="flex justify-between items-center bg-white p-4 rounded-2xl border border-slate-100 shadow-sm">
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-slate-700 hover:text-slate-900 font-bold cursor-pointer text-sm"
        >
          <ArrowRight className={`w-4 h-4 ${isRtl ? '' : 'rotate-180'}`} />
          <span>{t.back_btn}</span>
        </button>

        <span className="text-xs font-bold text-slate-600 bg-slate-100 px-3 py-1.5 rounded-xl">
          🛠️ {t.admin_title} (Passcode OK)
        </span>
      </div>

      {/* Admin Tabs */}
      <div className="flex border-b border-slate-200">
        <button
          onClick={() => setActiveTab('moderation')}
          className={`flex-1 py-3 font-bold text-sm text-center border-b-2 cursor-pointer transition ${
            activeTab === 'moderation' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          📝 {isRtl ? 'قائمة مراجعة المشاركات المعلقة' : 'Moderate Posts Queue'} ({pendingPosts.length + pendingReplies.length})
        </button>
        <button
          onClick={() => setActiveTab('promos')}
          className={`flex-1 py-3 font-bold text-sm text-center border-b-2 cursor-pointer transition ${
            activeTab === 'promos' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          🎟️ {t.admin_promo_title} ({promoCodes.length})
        </button>
      </div>

      {/* Tab Content: Moderation */}
      {activeTab === 'moderation' && (
        <div className="space-y-6">
          {/* Pending Posts */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
            <h3 className="font-extrabold text-slate-900 border-b border-slate-100 pb-2 text-sm">
              📋 {t.tab_pending_posts} ({pendingPosts.length})
            </h3>

            <div className="space-y-4">
              {pendingPosts.map((post) => (
                <div key={post.id} className="p-4 bg-slate-50 rounded-xl border border-slate-100 space-y-3">
                  <div className="flex justify-between text-xs font-semibold">
                    <span className="text-blue-600">👤 {post.author} ({post.specialty})</span>
                    <span className="text-slate-400">Category: {post.category.toUpperCase()}</span>
                  </div>
                  <h4 className="font-bold text-slate-900 text-sm">{post.title}</h4>
                  <p className="text-xs text-slate-600 leading-relaxed">{post.description}</p>

                  <div className="flex gap-2 pt-2">
                    <button
                      onClick={() => onApprovePost(post.id)}
                      className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-extrabold text-xs rounded-lg transition cursor-pointer"
                    >
                      {t.btn_approve}
                    </button>
                    <button
                      onClick={() => onRejectPost(post.id)}
                      className="px-4 py-2 bg-red-100 hover:bg-red-200 text-red-700 font-extrabold text-xs rounded-lg transition cursor-pointer"
                    >
                      {t.btn_reject}
                    </button>
                  </div>
                </div>
              ))}

              {pendingPosts.length === 0 && (
                <p className="text-xs text-slate-400 font-bold text-center py-4">{t.no_pending_posts}</p>
              )}
            </div>
          </div>

          {/* Pending Replies */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
            <h3 className="font-extrabold text-slate-900 border-b border-slate-100 pb-2 text-sm">
              💬 {t.tab_pending_replies} ({pendingReplies.length})
            </h3>

            <div className="space-y-4">
              {pendingReplies.map((reply) => (
                <div key={reply.replyId} className="p-4 bg-slate-50 rounded-xl border border-slate-100 space-y-3">
                  <div className="flex justify-between text-xs font-semibold">
                    <span className="text-indigo-600">👤 {reply.author} ({reply.specialty})</span>
                    <span className="text-slate-400 truncate max-w-xs">Thread: {reply.postTitle}</span>
                  </div>
                  <p className="text-xs text-slate-700 leading-relaxed">{reply.content}</p>

                  <div className="flex gap-2 pt-2">
                    <button
                      onClick={() => onApproveReply(reply.postId, reply.replyId)}
                      className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-extrabold text-xs rounded-lg transition cursor-pointer"
                    >
                      {t.btn_approve}
                    </button>
                    <button
                      onClick={() => onRejectReply(reply.postId, reply.replyId)}
                      className="px-4 py-2 bg-red-100 hover:bg-red-200 text-red-700 font-extrabold text-xs rounded-lg transition cursor-pointer"
                    >
                      {t.btn_reject}
                    </button>
                  </div>
                </div>
              ))}

              {pendingReplies.length === 0 && (
                <p className="text-xs text-slate-400 font-bold text-center py-4">{t.no_pending_replies}</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Tab Content: Promo codes */}
      {activeTab === 'promos' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Promo form */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
            <h3 className="font-extrabold text-slate-900 border-b border-slate-100 pb-2 text-sm flex items-center gap-2">
              <Tag className="w-4.5 h-4.5 text-blue-600" />
              <span>{isRtl ? 'إضافة وتثبيت كود خصم جديد' : 'Deploy New Partner Coupon'}</span>
            </h3>

            <form onSubmit={handleCreatePromoSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-600 mb-1">{t.promo_company} *</label>
                <input
                  type="text"
                  required
                  value={companyName}
                  onChange={(e) => setCompanyName(e.target.value)}
                  placeholder="مثال: محلات الصالح لقطع الغيار"
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-600 mb-1">{t.promo_code} *</label>
                  <input
                    type="text"
                    required
                    value={promoCodeValue}
                    onChange={(e) => setPromoCodeValue(e.target.value)}
                    placeholder="CARRIER15"
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs uppercase focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-600 mb-1">{t.promo_percent} *</label>
                  <input
                    type="number"
                    required
                    min={5}
                    max={95}
                    value={discountPercent}
                    onChange={(e) => setDiscountPercent(e.target.value)}
                    placeholder="15"
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none"
                  />
                </div>
              </div>

              <button
                id="submit-promo-btn"
                type="submit"
                className="w-full py-3 bg-blue-600 hover:bg-blue-500 text-white font-extrabold text-xs rounded-xl transition cursor-pointer shadow-md"
              >
                {t.btn_promo_submit}
              </button>
            </form>
          </div>

          {/* Active Promos list */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
            <h3 className="font-extrabold text-slate-900 border-b border-slate-100 pb-2 text-sm">
              🎫 {t.promo_active_lbl} ({promoCodes.length})
            </h3>

            <div className="space-y-3 max-h-[300px] overflow-y-auto pr-1">
              {promoCodes.map((promo, i) => (
                <div key={i} className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex justify-between items-center text-xs">
                  <div>
                    <span className="font-bold text-slate-800 block">{promo.companyName}</span>
                    <span className="text-emerald-700 font-semibold">{isRtl ? `خصم بقيمة ${promo.discountPercentage}%` : `${promo.discountPercentage}% discount`}</span>
                  </div>

                  <div className="flex items-center gap-3">
                    <span className="font-mono bg-white px-2 py-1 border border-slate-200 text-slate-700 font-bold rounded">
                      {promo.code}
                    </span>
                    <button
                      onClick={() => onDeletePromo(promo.code)}
                      className="p-1.5 text-red-500 hover:text-red-700 rounded-lg hover:bg-red-50 transition cursor-pointer"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}

              {promoCodes.length === 0 && (
                <p className="text-xs text-slate-400 font-bold text-center py-6">{t.promo_no_codes}</p>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
export default AdminScreen;
