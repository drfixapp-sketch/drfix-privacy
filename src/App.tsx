import React, { useState, useEffect } from 'react';
import { Language, translations } from './utils/translations';
import { ForumPost, PromoCode, ForumReply } from './types';

// Component Imports
import WelcomeScreen from './components/WelcomeScreen';
import HomeScreen from './components/HomeScreen';
import DeviceInfoScreen from './components/DeviceInfoScreen';
import DiagnosisResultScreen from './components/DiagnosisResultScreen';
import ProcurementScreen from './components/ProcurementScreen';
import ForumScreen from './components/ForumScreen';
import AdminScreen from './components/AdminScreen';

import { ShieldCheck, MessageSquare, Wrench, ShoppingCart } from 'lucide-react';

export const App: React.FC = () => {
  // Lang state (defaults to Arabic)
  const [lang, setLang] = useState<Language>('ar');
  const t = translations[lang];
  const isRtl = lang === 'ar';

  // Navigation / View states
  const [currentView, setCurrentView] = useState<'welcome' | 'home' | 'device_info' | 'diagnosis' | 'procurement' | 'forum' | 'admin'>('welcome');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  // Active diagnostic data
  const [activeDeviceData, setActiveDeviceData] = useState<{
    deviceName: string;
    manufacturer: string;
    model: string;
    problemDetails: string;
    observations: string;
    errorCode: string;
    images: { general?: string; plate?: string; closeup?: string };
  } | null>(null);

  // Database States: Forum posts & Promo codes (with client persistent localStorage syncing)
  const [forumPosts, setForumPosts] = useState<ForumPost[]>([]);
  const [promoCodes, setPromoCodes] = useState<PromoCode[]>([]);

  // Toggle dynamic class for document layout direction on change
  useEffect(() => {
    document.documentElement.dir = isRtl ? 'rtl' : 'ltr';
    document.documentElement.lang = lang;
  }, [lang, isRtl]);

  // Seed default dataset on first launch
  useEffect(() => {
    const savedPosts = localStorage.getItem('drfix_forum_posts');
    if (savedPosts) {
      setForumPosts(JSON.parse(savedPosts));
    } else {
      const defaultPosts: ForumPost[] = [
        {
          id: 'post-1',
          author: isRtl ? 'المهندس أحمد صالح' : 'Eng. Ahmad Saleh',
          specialty: isRtl ? 'خبير تكييف مركزي' : 'Chiller Specialist',
          title: isRtl ? 'عطل متكرر في كمبروسر Chiller من نوع Carrier' : 'Recurrent Compressor Trip on Carrier Chiller Unit',
          description: isRtl 
            ? 'يحدث فصل مفاجئ بسبب ارتفاع درجة حرارة الموتور (Overheating) بعد تشغيله بـ 20 دقيقة متواصلة. تم فحص الفريون وضغوط التشغيل طبيعية تماماً. هل من الممكن أن تكون ملفات البدء تالفة؟' 
            : 'Sudden thermal trip (Overheating) after 20 minutes of continuous running. Checked refrigerant pressures and they are perfectly nominal. Could it be start winding fatigue?',
          category: 'hvac',
          upvotes: 14,
          downvotes: 1,
          views: 182,
          isApproved: true,
          replies: [
            {
              id: 'reply-1',
              author: isRtl ? 'فني تبريد خبير' : 'Expert Refrigeration Tech',
              specialty: isRtl ? 'تبريد صناعي ورشات' : 'Industrial Cooling Workshop',
              content: isRtl 
                ? 'تحقق من قراءة تيار التشغيل (Amperage) فور البدء. من المرجح جداً أن مكثف التشغيل (Run Capacitor) قد فقد سعته أو تآكلت أقطابه، مما يرفع مقاومة ملفات البدء ويسخن محرك الكمبروسر حتى يتدخل قاطع الأمان الحراري.' 
                : 'Measure run amperage right at start. It is highly probable that the Dual Run Capacitor has degraded or lost microfarads, forcing higher winding resistance and overheating the compressor casing.',
              createdAt: new Date().toISOString(),
              isApproved: true
            }
          ]
        },
        {
          id: 'post-2',
          author: isRtl ? 'أبو يوسف الكهربائي' : 'Abu Yousef Electrician',
          specialty: isRtl ? 'صيانة لوحات ومحركات' : 'Industrial Control Boards',
          title: isRtl ? 'مضخة غاطسة ثلاثية الطور تفصل بعد ثوانٍ من التشغيل' : 'Three-Phase Submersible Pump Trips Instantly on Start',
          description: isRtl 
            ? 'مضخة غاطسة بقوة 15 حصان تسحب تياراً زائداً فوراً وتفصل قاطع الحماية المغناطيسي الحراري (M.C.B) بالرغم من فك التروس وتنظيفها يدوياً.' 
            : 'Submersible 15HP pump trips thermal-magnetic breaker instantly. Impellers are fully clear and rotated manually. Suggestions?',
          category: 'hydraulic',
          upvotes: 8,
          downvotes: 0,
          views: 94,
          isApproved: true,
          replies: []
        }
      ];
      setForumPosts(defaultPosts);
      localStorage.setItem('drfix_forum_posts', JSON.stringify(defaultPosts));
    }

    const savedPromos = localStorage.getItem('drfix_promos');
    if (savedPromos) {
      setPromoCodes(JSON.parse(savedPromos));
    } else {
      const defaultPromos: PromoCode[] = [
        { code: 'JORDAN15', companyName: isRtl ? 'مستودعات الخليج لقطع الغيار' : 'Gulf Spare Parts Warehouses', discountPercentage: 15 },
        { code: 'FIX2026', companyName: isRtl ? 'شركة الهدد لمعدات الصيانة' : 'Al-Haddad Maintenance Equipments', discountPercentage: 10 }
      ];
      setPromoCodes(defaultPromos);
      localStorage.setItem('drfix_promos', JSON.stringify(defaultPromos));
    }
  }, [isRtl]);

  // Sync to localStorage on update helper
  const syncPostsToStorage = (posts: ForumPost[]) => {
    setForumPosts(posts);
    localStorage.setItem('drfix_forum_posts', JSON.stringify(posts));
  };

  const syncPromosToStorage = (promos: PromoCode[]) => {
    setPromoCodes(promos);
    localStorage.setItem('drfix_promos', JSON.stringify(promos));
  };

  // Actions
  const handleSelectCategory = (catId: string) => {
    setSelectedCategory(catId);
    setCurrentView('device_info');
  };

  const handleDeviceFormSubmit = (data: typeof activeDeviceData) => {
    setActiveDeviceData(data);
    setCurrentView('diagnosis');
  };

  // Vote post
  const handleVotePost = (postId: string, direction: 'up' | 'down') => {
    const updated = forumPosts.map(post => {
      if (post.id === postId) {
        return {
          ...post,
          upvotes: direction === 'up' ? post.upvotes + 1 : post.upvotes,
          downvotes: direction === 'down' ? post.downvotes + 1 : post.downvotes
        };
      }
      return post;
    });
    syncPostsToStorage(updated);
  };

  // Add a post (starts as pending review: isApproved = false)
  const handleAddPost = (newPostData: { title: string; description: string; author: string; specialty: string; category: string }) => {
    const newPost: ForumPost = {
      id: `post-${Date.now()}`,
      title: newPostData.title,
      description: newPostData.description,
      author: newPostData.author,
      specialty: newPostData.specialty,
      category: newPostData.category,
      upvotes: 0,
      downvotes: 0,
      views: 12,
      isApproved: false, // Moderated by default!
      replies: []
    };
    syncPostsToStorage([newPost, ...forumPosts]);
  };

  // Add comment/reply (starts as pending review: isApproved = false)
  const handleAddReply = (postId: string, content: string, author: string, specialty: string) => {
    const updated = forumPosts.map(post => {
      if (post.id === postId) {
        const newReply: ForumReply = {
          id: `reply-${Date.now()}`,
          author,
          specialty,
          content,
          createdAt: new Date().toISOString(),
          isApproved: false // Moderated by default!
        };
        return {
          ...post,
          replies: [...post.replies, newReply]
        };
      }
      return post;
    });
    syncPostsToStorage(updated);
  };

  // Admin approval workflows
  const handleApprovePost = (postId: string) => {
    const updated = forumPosts.map(post => {
      if (post.id === postId) {
        return { ...post, isApproved: true };
      }
      return post;
    });
    syncPostsToStorage(updated);
  };

  const handleRejectPost = (postId: string) => {
    const updated = forumPosts.filter(p => p.id !== postId);
    syncPostsToStorage(updated);
  };

  const handleApproveReply = (postId: string, replyId: string) => {
    const updated = forumPosts.map(post => {
      if (post.id === postId) {
        return {
          ...post,
          replies: post.replies.map(reply => {
            if (reply.id === replyId) {
              return { ...reply, isApproved: true };
            }
            return reply;
          })
        };
      }
      return post;
    });
    syncPostsToStorage(updated);
  };

  const handleRejectReply = (postId: string, replyId: string) => {
    const updated = forumPosts.map(post => {
      if (post.id === postId) {
        return {
          ...post,
          replies: post.replies.filter(reply => reply.id !== replyId)
        };
      }
      return post;
    });
    syncPostsToStorage(updated);
  };

  // Admin Promos
  const handleAddPromo = (promo: PromoCode) => {
    syncPromosToStorage([promo, ...promoCodes]);
  };

  const handleDeletePromo = (code: string) => {
    syncPromosToStorage(promoCodes.filter(p => p.code !== code));
  };

  return (
    <div className="flex-1 flex flex-col bg-slate-50 min-h-screen">
      {/* Top Banner Navigation Header */}
      <header className="bg-white border-b border-slate-100 shadow-sm sticky top-0 z-30">
        <div className="max-w-5xl mx-auto px-4 py-3 flex items-center justify-between">
          <button
            onClick={() => setCurrentView('welcome')}
            className="flex items-center gap-2 cursor-pointer font-black text-xl text-slate-900 focus:outline-none"
          >
            <span className="text-2xl">👨‍🔧</span>
            <span>{t.app_title}</span>
          </button>

          {/* Quick Stats or language toggle on header */}
          <div className="flex items-center gap-3">
            {currentView !== 'welcome' && (
              <button
                onClick={() => setLang(lang === 'ar' ? 'en' : 'ar')}
                className="px-3 py-1.5 bg-slate-100 rounded-xl font-bold text-xs hover:bg-slate-200 transition cursor-pointer text-slate-700"
              >
                {lang === 'ar' ? 'English' : 'العربية'}
              </button>
            )}

            {currentView !== 'welcome' && (
              <button
                onClick={() => setCurrentView('admin')}
                className="px-3 py-1.5 bg-slate-800 text-slate-300 rounded-xl font-bold text-xs hover:bg-slate-700 transition cursor-pointer"
              >
                ⚙️ {t.admin_btn}
              </button>
            )}
          </div>
        </div>
      </header>

      {/* Primary Workspace View Switcher */}
      <main className="flex-1 flex flex-col">
        {currentView === 'welcome' && (
          <WelcomeScreen
            lang={lang}
            setLang={setLang}
            onAccept={() => setCurrentView('home')}
            onNavigateToForum={() => setCurrentView('forum')}
          />
        )}

        {currentView === 'home' && (
          <HomeScreen
            lang={lang}
            onSelectCategory={handleSelectCategory}
            onNavigateToForum={() => setCurrentView('forum')}
            onNavigateToProcurement={() => setCurrentView('procurement')}
            onNavigateToAdmin={() => setCurrentView('admin')}
          />
        )}

        {currentView === 'device_info' && selectedCategory && (
          <DeviceInfoScreen
            lang={lang}
            selectedCategory={selectedCategory}
            onBack={() => setCurrentView('home')}
            onSubmit={handleDeviceFormSubmit}
          />
        )}

        {currentView === 'diagnosis' && activeDeviceData && (
          <DiagnosisResultScreen
            lang={lang}
            deviceData={activeDeviceData}
            onBack={() => setCurrentView('device_info')}
            onNavigateToProcurement={() => setCurrentView('procurement')}
          />
        )}

        {currentView === 'procurement' && (
          <ProcurementScreen
            lang={lang}
            promoCodes={promoCodes}
            onBack={() => setCurrentView('home')}
          />
        )}

        {currentView === 'forum' && (
          <ForumScreen
            lang={lang}
            forumPosts={forumPosts}
            onBack={() => setCurrentView('home')}
            onAddPost={handleAddPost}
            onVotePost={handleVotePost}
            onAddReply={handleAddReply}
          />
        )}

        {currentView === 'admin' && (
          <AdminScreen
            lang={lang}
            onBack={() => setCurrentView('home')}
            forumPosts={forumPosts}
            promoCodes={promoCodes}
            onApprovePost={handleApprovePost}
            onRejectPost={handleRejectPost}
            onApproveReply={handleApproveReply}
            onRejectReply={handleRejectReply}
            onAddPromo={handleAddPromo}
            onDeletePromo={handleDeletePromo}
          />
        )}
      </main>

      {/* Floating global footer navigation workspace */}
      {currentView !== 'welcome' && (
        <footer className="bg-white border-t border-slate-200/80 sticky bottom-0 z-30 shadow-inner">
          <div className="max-w-2xl mx-auto px-4 py-2 flex items-center justify-around">
            <button
              onClick={() => setCurrentView('home')}
              className={`flex flex-col items-center gap-1 p-2 text-center cursor-pointer group ${
                currentView === 'home' || currentView === 'device_info' || currentView === 'diagnosis' ? 'text-blue-600' : 'text-slate-400 hover:text-slate-600'
              }`}
            >
              <Wrench className="w-5 h-5" />
              <span className="text-[10px] font-black">{isRtl ? 'المساعد الذكي' : 'AI Assistant'}</span>
            </button>

            <button
              id="forum-nav-tab"
              onClick={() => setCurrentView('forum')}
              className={`flex flex-col items-center gap-1 p-2 text-center cursor-pointer group ${
                currentView === 'forum' ? 'text-blue-600' : 'text-slate-400 hover:text-slate-600'
              }`}
            >
              <MessageSquare className="w-5 h-5" />
              <span className="text-[10px] font-black">{isRtl ? 'المنتدى الميداني' : 'Community Forum'}</span>
            </button>

            <button
              id="parts-nav-tab"
              onClick={() => setCurrentView('procurement')}
              className={`flex flex-col items-center gap-1 p-2 text-center cursor-pointer group ${
                currentView === 'procurement' ? 'text-blue-600' : 'text-slate-400 hover:text-slate-600'
              }`}
            >
              <ShoppingCart className="w-5 h-5" />
              <span className="text-[10px] font-black">{isRtl ? 'البحث عن قطع' : 'Find Spare Parts'}</span>
            </button>

            <button
              id="admin-nav-tab"
              onClick={() => setCurrentView('admin')}
              className={`flex flex-col items-center gap-1 p-2 text-center cursor-pointer group ${
                currentView === 'admin' ? 'text-blue-600' : 'text-slate-400 hover:text-slate-600'
              }`}
            >
              <ShieldCheck className="w-5 h-5" />
              <span className="text-[10px] font-black">{isRtl ? 'المراجعة والتحكم' : 'Moderator Portal'}</span>
            </button>
          </div>
        </footer>
      )}
    </div>
  );
};

export default App;
