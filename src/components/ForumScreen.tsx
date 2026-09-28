import React, { useState } from 'react';
import { translations, Language } from '../utils/translations';
import { ForumPost } from '../types';
import { ArrowRight, MessageSquare, ThumbsUp, ThumbsDown, Eye, Send, Filter, AlertTriangle, CheckCircle, PlusCircle } from 'lucide-react';

interface ForumScreenProps {
  lang: Language;
  onBack: () => void;
  forumPosts: ForumPost[];
  onAddPost: (post: Omit<ForumPost, 'id' | 'replies' | 'upvotes' | 'downvotes' | 'views' | 'isApproved'>) => void;
  onVotePost: (postId: string, direction: 'up' | 'down') => void;
  onAddReply: (postId: string, replyContent: string, authorName: string, authorBadge: string) => void;
}

export const ForumScreen: React.FC<ForumScreenProps> = ({
  lang,
  onBack,
  forumPosts,
  onAddPost,
  onVotePost,
  onAddReply
}) => {
  const t = translations[lang];
  const isRtl = lang === 'ar';

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [sortBy, setSortBy] = useState<'newest' | 'views' | 'votes'>('newest');

  // Dialog state for adding a post
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newDesc, setNewDesc] = useState('');
  const [newName, setNewName] = useState('');
  const [newBadge, setNewBadge] = useState('');
  const [newCategory, setNewCategory] = useState('hvac');
  const [profanityError, setProfanityError] = useState(false);
  const [showSuccessToast, setShowSuccessToast] = useState(false);

  // Detail view state
  const [activePost, setActivePost] = useState<ForumPost | null>(null);
  const [replyInput, setReplyInput] = useState('');
  const [replyNameInput, setReplyNameInput] = useState('');
  const [replyBadgeInput, setReplyBadgeInput] = useState('');

  // Localized Categories
  const categories = [
    { id: 'All', titleAr: 'الكل', titleEn: 'All' },
    { id: 'hvac', titleAr: 'تكييف وتبريد', titleEn: 'HVAC' },
    { id: 'electrical', titleAr: 'كهرباء', titleEn: 'Electrical' },
    { id: 'mechanical', titleAr: 'ميكانيك', titleEn: 'Mechanics' },
    { id: 'hydraulic', titleAr: 'هيدروليك', titleEn: 'Hydraulics' },
    { id: 'appliances', titleAr: 'أجهزة منزلية', titleEn: 'Home Appliances' }
  ];

  // Profanity/Policy Block words
  const blockedKeywords = [
    'سياسة', 'حزب', 'انتخابات', 'سقوط', 'politics', 'policy', 'abuse', 'cheat', 'تزوير', 'رشوة', 'احتيال', 'سرقة', 'إباحي'
  ];

  const handleCreatePost = (e: React.FormEvent) => {
    e.preventDefault();
    setProfanityError(false);

    // Filter check
    const combinedText = (newTitle + ' ' + newDesc).toLowerCase();
    const hasProfanity = blockedKeywords.some(word => combinedText.includes(word));

    if (hasProfanity) {
      setProfanityError(true);
      return;
    }

    onAddPost({
      title: newTitle.trim(),
      description: newDesc.trim(),
      author: newName.trim() || (isRtl ? 'فني مجهول' : 'Anonymous Tech'),
      specialty: newBadge.trim() || (isRtl ? 'فني صيانة عامة' : 'General Maintenance Tech'),
      category: newCategory
    });

    // Clear dialog state
    setNewTitle('');
    setNewDesc('');
    setNewName('');
    setNewBadge('');
    setShowAddDialog(false);

    // Show pending approval success toast
    setShowSuccessToast(true);
    setTimeout(() => {
      setShowSuccessToast(false);
    }, 4500);
  };

  const handlePostReplySubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!activePost || !replyInput.trim()) return;

    onAddReply(
      activePost.id,
      replyInput.trim(),
      replyNameInput.trim() || (isRtl ? 'فني مساعد' : 'Helping Hand'),
      replyBadgeInput.trim() || (isRtl ? 'فني معتمد' : 'Certified Tech')
    );

    setReplyInput('');
    setReplyNameInput('');
    setReplyBadgeInput('');

    // Re-sync active post to display reply immediately if approved (or message about pending)
    const updatedPost = forumPosts.find(p => p.id === activePost.id);
    if (updatedPost) {
      setActivePost(updatedPost);
    }
  };

  // Filter and Sort public posts (Only showing approved ones)
  const approvedPosts = forumPosts.filter(p => p.isApproved);

  const filteredPosts = approvedPosts.filter(post => {
    // Category filter
    if (selectedCategory !== 'All' && post.category !== selectedCategory) {
      return false;
    }
    // Search query filter
    const query = searchQuery.toLowerCase().trim();
    if (!query) return true;
    return (
      post.title.toLowerCase().includes(query) ||
      post.description.toLowerCase().includes(query) ||
      post.author.toLowerCase().includes(query)
    );
  });

  // Sorting
  const sortedPosts = [...filteredPosts].sort((a, b) => {
    if (sortBy === 'newest') {
      return b.id.localeCompare(a.id);
    } else if (sortBy === 'views') {
      return b.views - a.views;
    } else {
      return b.upvotes - b.downvotes - (a.upvotes - a.downvotes);
    }
  });

  return (
    <div className="flex-1 p-4 md:p-8 max-w-5xl mx-auto w-full space-y-6">
      {/* Top Header */}
      <div className="flex justify-between items-center bg-white p-4 rounded-2xl border border-slate-100 shadow-sm">
        <button
          onClick={activePost ? () => setActivePost(null) : onBack}
          className="flex items-center gap-2 text-slate-700 hover:text-slate-900 font-bold cursor-pointer text-sm"
        >
          <ArrowRight className={`w-4 h-4 ${isRtl ? '' : 'rotate-180'}`} />
          <span>{t.back_btn}</span>
        </button>

        <span className="text-xs font-bold text-blue-600 bg-blue-50 px-3 py-1.5 rounded-xl">
          💬 {isRtl ? 'المنتدى الميداني العام' : 'Public Field Forum'}
        </span>
      </div>

      {/* Success notification for pending post */}
      {showSuccessToast && (
        <div className="bg-emerald-50 border border-emerald-200 text-emerald-900 p-4 rounded-xl flex items-center gap-3 shadow-md animate-bounce">
          <CheckCircle className="w-5 h-5 text-emerald-600 shrink-0" />
          <p className="text-xs font-bold leading-relaxed">
            {isRtl 
              ? '🎉 تم استلام منشورك بنجاح! تم وضعه في قائمة المراجعة اليدوية للأدمن للتأكد من المحتوى الفني قبل عرضه للعامة.' 
              : '🎉 Post submitted successfully! It has been placed in the Admin manual review queue to ensure technical content.'}
          </p>
        </div>
      )}

      {/* Detailed Thread View */}
      {activePost ? (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main post description & replies (2 Cols) */}
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
              {/* Post Metadata */}
              <div className="flex justify-between items-center text-xs">
                <span className="px-2.5 py-1 bg-blue-50 text-blue-600 rounded-lg font-bold">
                  {categories.find(c => c.id === activePost.category)?.titleAr || activePost.category.toUpperCase()}
                </span>
                <div className="text-slate-400 font-semibold flex items-center gap-2">
                  <span>👤 {activePost.author}</span>
                  <span className="bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded text-[10px]">{activePost.specialty}</span>
                </div>
              </div>

              {/* Title & Body */}
              <h3 className="text-lg font-black text-slate-900 leading-snug">{activePost.title}</h3>
              <p className="text-sm text-slate-700 leading-relaxed font-medium bg-slate-50 p-4 rounded-xl">
                {activePost.description}
              </p>

              {/* AI Summarization Overlay inside thread details */}
              <div className="bg-gradient-to-br from-indigo-50 to-blue-50 border border-blue-100 rounded-xl p-4 flex gap-3 text-xs leading-relaxed text-blue-900 font-bold">
                <span className="text-base shrink-0">💡</span>
                <div>
                  <h4 className="text-blue-950 font-black mb-0.5">{isRtl ? 'ملخص ميكانيكي آلي (Dr Fix AI):' : 'Automated Diagnostic Summary (Dr Fix AI):'}</h4>
                  <p className="text-slate-600">
                    {isRtl 
                      ? 'بناءً على التوصيف: يوصى بقياس ضغوط الشحن (Piston pressure) ومراجعة ريليه البدء الكهربائي قبل استدعاء مهندس صيانة خارجي.'
                      : 'Based on observations: We advise checking start relay terminal contacts and verifying pressure ratings before calling an external vendor.'}
                  </p>
                </div>
              </div>

              {/* Interaction Row */}
              <div className="flex justify-between items-center border-t border-slate-100 pt-3">
                <div className="flex gap-4">
                  <button
                    onClick={() => onVotePost(activePost.id, 'up')}
                    className="flex items-center gap-1.5 text-slate-500 hover:text-blue-600 text-xs font-bold cursor-pointer"
                  >
                    <ThumbsUp className="w-4 h-4" />
                    <span>{activePost.upvotes}</span>
                  </button>

                  <button
                    onClick={() => onVotePost(activePost.id, 'down')}
                    className="flex items-center gap-1.5 text-slate-500 hover:text-red-600 text-xs font-bold cursor-pointer"
                  >
                    <ThumbsDown className="w-4 h-4" />
                    <span>{activePost.downvotes}</span>
                  </button>
                </div>

                <div className="flex items-center gap-1.5 text-slate-400 text-xs font-semibold">
                  <Eye className="w-4 h-4" />
                  <span>{activePost.views} {isRtl ? 'مشاهدة' : 'Views'}</span>
                </div>
              </div>
            </div>

            {/* Replies section */}
            <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
              <h4 className="font-bold text-slate-900 border-b border-slate-100 pb-2 flex items-center gap-2 text-sm">
                <MessageSquare className="w-4.5 h-4.5 text-blue-600" />
                <span>{t.comments_lbl} ({activePost.replies.filter(r => r.isApproved).length})</span>
              </h4>

              <div className="space-y-4">
                {activePost.replies.filter(r => r.isApproved).map((reply) => (
                  <div key={reply.id} className="p-4 bg-slate-50 rounded-xl space-y-2 border border-slate-100">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-bold text-slate-800">{reply.author}</span>
                      <span className="bg-slate-200/80 text-slate-600 px-2 py-0.5 rounded text-[10px] font-semibold">{reply.specialty}</span>
                    </div>
                    <p className="text-xs text-slate-700 leading-relaxed font-medium">{reply.content}</p>
                  </div>
                ))}

                {activePost.replies.filter(r => r.isApproved).length === 0 && (
                  <div className="text-center py-6">
                    <MessageSquare className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                    <p className="text-xs text-slate-400 font-bold">{isRtl ? 'لا توجد ردود فنية معتمدة حتى الآن. كن أول من يجيب!' : 'No verified responses yet. Be the first to reply!'}</p>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Reply form (1 Col) */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4 self-start">
            <h4 className="font-bold text-slate-900 text-sm border-b border-slate-100 pb-2">
              {isRtl ? 'أضف خبرتك ومساعدتك الفنية' : 'Add Your Technical Solution'}
            </h4>

            <form onSubmit={handlePostReplySubmit} className="space-y-4">
              <div>
                <label className="block text-[10px] font-bold text-slate-600 mb-1">{t.pop_name_h} *</label>
                <input
                  type="text"
                  required
                  value={replyNameInput}
                  onChange={(e) => setReplyNameInput(e.target.value)}
                  placeholder="مثال: المهندس يوسف"
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-600 mb-1">{t.pop_badge_h} *</label>
                <input
                  type="text"
                  required
                  value={replyBadgeInput}
                  onChange={(e) => setReplyBadgeInput(e.target.value)}
                  placeholder="مثال: خبير تبريد وتكييف"
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-600 mb-1">{t.add_comment_placeholder} *</label>
                <textarea
                  required
                  rows={4}
                  value={replyInput}
                  onChange={(e) => setReplyInput(e.target.value)}
                  placeholder="اكتب ردك وملاحظاتك الهندسية هنا..."
                  className="w-full p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
                ></textarea>
              </div>

              <button
                type="submit"
                className="w-full py-2.5 bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold rounded-xl transition flex items-center justify-center gap-2 shadow-md shadow-blue-500/10 cursor-pointer"
              >
                <Send className="w-3.5 h-3.5" />
                <span>{isRtl ? 'إرسال الرد للمراجعة' : 'Send Response'}</span>
              </button>
            </form>
          </div>
        </div>
      ) : (
        /* Forum Thread List Workspace */
        <div className="space-y-6">
          {/* Forum Sub-Banner Stats */}
          <div className="bg-gradient-to-r from-blue-900 to-indigo-950 text-white p-4 rounded-2xl flex flex-wrap items-center justify-around gap-4 text-center">
            <div className="text-xs font-bold text-slate-300">👥 {t.forum_stats_online}</div>
            <div className="text-xs font-bold text-slate-300">⚡ {t.forum_stats_posts}</div>
            <div className="text-xs font-bold text-slate-300">👁️ {t.forum_stats_views}</div>
          </div>

          {/* Filter, Search & Sort Bar */}
          <div className="bg-white p-4 rounded-2xl border border-slate-100 shadow-sm flex flex-col md:flex-row items-center gap-4">
            {/* Search */}
            <div className="relative flex-1 w-full">
              <input
                id="forum-search-box"
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder={t.search_forum}
                className={`w-full p-2.5 ${isRtl ? 'text-right' : 'text-left'} bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-blue-500 text-xs font-semibold`}
              />
            </div>

            {/* Category Filter */}
            <div className="flex gap-1.5 overflow-x-auto w-full md:w-auto pb-1 md:pb-0 scrollbar-none">
              {categories.map((cat) => {
                const isActive = selectedCategory === cat.id;
                return (
                  <button
                    key={cat.id}
                    onClick={() => setSelectedCategory(cat.id)}
                    className={`px-3 py-1.5 rounded-lg text-[11px] font-bold transition shrink-0 cursor-pointer ${
                      isActive 
                        ? 'bg-blue-600 text-white shadow-sm' 
                        : 'bg-slate-50 text-slate-600 border border-slate-200 hover:bg-slate-100'
                    }`}
                  >
                    {isRtl ? cat.titleAr : cat.titleEn}
                  </button>
                );
              })}
            </div>

            {/* Sort Filter dropdown */}
            <div className="flex items-center gap-1.5 shrink-0">
              <Filter className="w-4 h-4 text-slate-400" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as 'newest' | 'views' | 'votes')}
                className="p-1.5 bg-slate-50 border border-slate-200 rounded-lg text-[11px] font-bold focus:outline-none text-slate-700"
              >
                <option value="newest">{t.sort_newest}</option>
                <option value="views">{t.sort_views}</option>
                <option value="votes">{t.sort_votes}</option>
              </select>
            </div>
          </div>

          {/* Quick FAQ / Search Suggestions */}
          <div className="flex flex-wrap items-center gap-2 bg-blue-50/50 p-3 rounded-xl border border-blue-50">
            <span className="text-[10px] font-black text-blue-800 shrink-0">{t.suggest_lbl}:</span>
            <button
              onClick={() => setSearchQuery('Carrier')}
              className="px-2.5 py-1 bg-white hover:bg-slate-50 text-[10px] font-bold text-slate-600 rounded-lg border border-slate-200 cursor-pointer transition"
            >
              Chiller Carrier
            </button>
            <button
              onClick={() => setSearchQuery('E11')}
              className="px-2.5 py-1 bg-white hover:bg-slate-50 text-[10px] font-bold text-slate-600 rounded-lg border border-slate-200 cursor-pointer transition"
            >
              Error E11
            </button>
            <button
              onClick={() => setSearchQuery('ضاغط')}
              className="px-2.5 py-1 bg-white hover:bg-slate-50 text-[10px] font-bold text-slate-600 rounded-lg border border-slate-200 cursor-pointer transition"
            >
              {isRtl ? 'ضاغط هواء' : 'Compressor'}
            </button>
          </div>

          {/* List of active threads */}
          <div className="space-y-4">
            {sortedPosts.map((post) => (
              <div
                key={post.id}
                id={`forum-post-${post.id}`}
                onClick={() => setActivePost(post)}
                className="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm hover:shadow-md transition duration-300 cursor-pointer space-y-3"
              >
                <div className="flex justify-between items-center text-xs">
                  <span className="px-2 py-0.5 bg-blue-50 text-blue-600 rounded-lg font-bold">
                    {categories.find(c => c.id === post.category)?.titleAr || post.category.toUpperCase()}
                  </span>
                  <div className="text-slate-400 font-semibold flex items-center gap-1">
                    <span>👤 {post.author}</span>
                    <span className="bg-slate-100 text-slate-600 px-1 py-0.5 rounded text-[9px]">{post.specialty}</span>
                  </div>
                </div>

                <h4 className="font-extrabold text-slate-900 text-sm md:text-base leading-snug">{post.title}</h4>
                <p className="text-xs text-slate-500 line-clamp-2 leading-relaxed font-semibold">
                  {post.description}
                </p>

                {/* AI Summary Badge inside list cards */}
                <div className="py-2 px-3 bg-indigo-50/50 rounded-xl text-[11px] font-bold text-indigo-900 border border-indigo-50/20 leading-relaxed">
                  💡 {t.ai_summary_prefix}
                </div>

                {/* Interaction Row */}
                <div className="flex justify-between items-center border-t border-slate-100 pt-3">
                  <div className="flex gap-4">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onVotePost(post.id, 'up');
                      }}
                      className="flex items-center gap-1 text-slate-500 hover:text-blue-600 text-xs font-bold cursor-pointer"
                    >
                      <ThumbsUp className="w-3.5 h-3.5" />
                      <span>{post.upvotes}</span>
                    </button>

                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onVotePost(post.id, 'down');
                      }}
                      className="flex items-center gap-1 text-slate-500 hover:text-red-600 text-xs font-bold cursor-pointer"
                    >
                      <ThumbsDown className="w-3.5 h-3.5" />
                      <span>{post.downvotes}</span>
                    </button>
                  </div>

                  <div className="flex items-center gap-3 text-slate-400 text-xs font-semibold">
                    <span className="flex items-center gap-1">
                      <MessageSquare className="w-3.5 h-3.5" />
                      <span>{post.replies.filter(r => r.isApproved).length}</span>
                    </span>
                    <span className="flex items-center gap-1">
                      <Eye className="w-3.5 h-3.5" />
                      <span>{post.views}</span>
                    </span>
                  </div>
                </div>
              </div>
            ))}

            {sortedPosts.length === 0 && (
              <div className="text-center py-12 bg-white rounded-2xl border border-slate-100 shadow-sm">
                <MessageSquare className="w-12 h-12 text-slate-300 mx-auto mb-3" />
                <p className="text-slate-500 font-bold">{isRtl ? 'لا توجد مشاركات مطابقة لبحثك في القسم النشط.' : 'No posts match your query in the selected category.'}</p>
              </div>
            )}
          </div>

          {/* Floating Action Button to post new fault */}
          <button
            id="fab-add-post"
            onClick={() => setShowAddDialog(true)}
            className="fixed bottom-6 left-6 md:left-12 px-5 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-full shadow-lg shadow-blue-500/30 hover:scale-105 transition-all duration-300 flex items-center gap-2 cursor-pointer z-40 font-bold text-sm"
          >
            <PlusCircle className="w-5 h-5" />
            <span>{t.fab_lbl}</span>
          </button>
        </div>
      )}

      {/* Add Post Pop-up modal */}
      {showAddDialog && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white p-6 rounded-2xl max-w-lg w-full border border-slate-100 shadow-xl space-y-4 animate-fade-in relative max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center border-b border-slate-100 pb-2">
              <h3 className="font-extrabold text-slate-900 text-base">{t.pop_title}</h3>
              <button
                onClick={() => {
                  setShowAddDialog(false);
                  setProfanityError(false);
                }}
                className="text-slate-400 hover:text-slate-600 font-bold text-lg focus:outline-none"
              >
                ✕
              </button>
            </div>

            {profanityError && (
              <div className="p-3 bg-red-50 border border-red-200 text-red-900 rounded-xl flex items-center gap-2 text-xs font-semibold">
                <AlertTriangle className="w-4.5 h-4.5 text-red-600 shrink-0" />
                <span>{t.profanity_warning}</span>
              </div>
            )}

            <form onSubmit={handleCreatePost} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-600 mb-1">{t.pop_name_h} *</label>
                  <input
                    type="text"
                    required
                    value={newName}
                    onChange={(e) => setNewName(e.target.value)}
                    placeholder="مثال: المهندس حمزة"
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-600 mb-1">{t.pop_badge_h} *</label>
                  <input
                    type="text"
                    required
                    value={newBadge}
                    onChange={(e) => setNewBadge(e.target.value)}
                    placeholder="مثال: فني محركات صناعية"
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-600 mb-1">القسم الهندسي الملائم</label>
                <select
                  value={newCategory}
                  onChange={(e) => setNewCategory(e.target.value)}
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none"
                >
                  <option value="hvac">تكييف وتبريد / HVAC</option>
                  <option value="electrical">كهرباء / Electrical</option>
                  <option value="mechanical">ميكانيك / Mechanics</option>
                  <option value="hydraulic">هيدروليك / Hydraulics</option>
                  <option value="appliances">أجهزة منزلية / Appliances</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-600 mb-1">{t.pop_topic_h} *</label>
                <input
                  type="text"
                  required
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="مثال: فصل ضاغط مكيف انفرتر Carrier عند رطوبة عالية"
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-600 mb-1">{t.pop_desc_h} *</label>
                <textarea
                  required
                  rows={4}
                  value={newDesc}
                  onChange={(e) => setNewDesc(e.target.value)}
                  placeholder="أوصف المشكلة وعينات القراءات للفحص..."
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
                ></textarea>
              </div>

              <button
                type="submit"
                className="w-full py-3.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold text-xs transition flex items-center justify-center gap-2 shadow-md shadow-blue-500/10 cursor-pointer"
              >
                <span>{t.pop_submit}</span>
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
export default ForumScreen;
