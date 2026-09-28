import React, { useState, useRef } from 'react';
import { translations, Language } from '../utils/translations';
import { Mic, ArrowRight, Camera, Upload, Trash2, CheckCircle2 } from 'lucide-react';

interface DeviceInfoScreenProps {
  lang: Language;
  selectedCategory: string;
  onBack: () => void;
  onSubmit: (data: {
    deviceName: string;
    manufacturer: string;
    model: string;
    problemDetails: string;
    observations: string;
    errorCode: string;
    images: { general?: string; plate?: string; closeup?: string };
  }) => void;
}

export const DeviceInfoScreen: React.FC<DeviceInfoScreenProps> = ({
  lang,
  selectedCategory,
  onBack,
  onSubmit
}) => {
  const t = translations[lang];
  const isRtl = lang === 'ar';

  // State fields
  const [deviceName, setDeviceName] = useState('');
  const [manufacturer, setManufacturer] = useState('');
  const [model, setModel] = useState('');
  const [problemDetails, setProblemDetails] = useState('');
  const [observations, setObservations] = useState('');
  const [errorCode, setErrorCode] = useState('');

  // Image Upload State
  const [images, setImages] = useState<{ general?: string; plate?: string; closeup?: string }>({});

  // Audio Dictation State
  const [listeningField, setListeningField] = useState<string | null>(null);

  // Hidden file inputs refs
  const fileInputGeneral = useRef<HTMLInputElement>(null);
  const fileInputPlate = useRef<HTMLInputElement>(null);
  const fileInputCloseup = useRef<HTMLInputElement>(null);

  // Simulated Voice Dictations
  const voiceMocks: Record<string, { ar: string; en: string }> = {
    problemDetails: {
      ar: 'المكيف يفصل فجأة عند بدء التشغيل مع صدور صوت طنين خفيف، المروحة الخارجية تدور لكن الضاغط لا يعمل.',
      en: 'The AC shuts down suddenly on startup with a low humming noise. The condenser fan runs, but the compressor fails to start.'
    },
    observations: {
      ar: 'ارتفاع حاد في قراءة الأمبير ليصل إلى 45 أمبير قبل الفصل مباشرة، وصوت طقطقة عند ريليه التلامس.',
      en: 'Sharp spike in startup current reaching 45A right before tripping, with a clicking sound near the contactor relay.'
    }
  };

  const startVoiceDictation = (fieldName: string) => {
    setListeningField(fieldName);
    setTimeout(() => {
      const mockText = voiceMocks[fieldName]?.[lang] || '';
      if (fieldName === 'problemDetails') {
        setProblemDetails(mockText);
      } else if (fieldName === 'observations') {
        setObservations(mockText);
      }
      setListeningField(null);
    }, 1200);
  };

  const handleImageChange = (key: 'general' | 'plate' | 'closeup', e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const url = URL.createObjectURL(file);
      setImages(prev => ({ ...prev, [key]: url }));
    }
  };

  const removeImage = (key: 'general' | 'plate' | 'closeup', e: React.MouseEvent) => {
    e.stopPropagation();
    setImages(prev => {
      const updated = { ...prev };
      delete updated[key];
      return updated;
    });
  };

  const handleFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Provide nice fallbacks if empty so the diagnosis runs smoothly
    onSubmit({
      deviceName: deviceName.trim() || (isRtl ? 'ضاغط هواء أو مكيف' : 'Compressor or Air Conditioner'),
      manufacturer: manufacturer.trim() || 'Carrier / Universal',
      model: model.trim() || 'CAR-3000-X',
      problemDetails: problemDetails.trim() || (isRtl ? 'المكثف معطل والكمبروسر يفصل تيار زائد' : 'Capacitor failure causing high amperage compressor trip'),
      observations: observations.trim() || (isRtl ? 'صوت طنين وحرارة ضاغط ملموسة' : 'Humming noise and warm compressor casing'),
      errorCode: errorCode.trim() || 'E11',
      images
    });
  };

  return (
    <div className="flex-1 p-4 md:p-8 max-w-3xl mx-auto w-full">
      {/* Back button */}
      <button
        onClick={onBack}
        className="flex items-center gap-2 text-slate-600 hover:text-slate-900 mb-6 font-bold cursor-pointer bg-white px-4 py-2 rounded-xl shadow-sm border border-slate-100 transition self-start"
      >
        <ArrowRight className={`w-4 h-4 ${isRtl ? '' : 'rotate-180'}`} />
        <span>{t.back_btn}</span>
      </button>

      {/* Screen Title */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-slate-900">
          {t.device_info_title}
        </h2>
        <p className="text-sm text-slate-500 mt-1">
          {isRtl 
            ? `القسم الحالي: ${selectedCategory.toUpperCase()}` 
            : `Active Section: ${selectedCategory.toUpperCase()}`}
        </p>
      </div>

      <form onSubmit={handleFormSubmit} className="space-y-6">
        {/* Basic Device Metadata */}
        <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
          <h3 className="font-bold text-slate-900 border-b border-slate-100 pb-2 flex items-center gap-2">
            <span className="text-blue-600">⚙️</span>
            <span>{t.label_main_device}</span>
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-600 mb-1.5">{t.hint_device_name} *</label>
              <input
                id="input-device-name"
                type="text"
                required
                value={deviceName}
                onChange={(e) => setDeviceName(e.target.value)}
                placeholder="مثال: Chiller 5-Ton"
                className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-600 mb-1.5">{t.hint_manufacturer}</label>
              <input
                id="input-manufacturer"
                type="text"
                value={manufacturer}
                onChange={(e) => setManufacturer(e.target.value)}
                placeholder="مثال: Carrier"
                className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-600 mb-1.5">{t.hint_model}</label>
              <input
                id="input-model"
                type="text"
                value={model}
                onChange={(e) => setModel(e.target.value)}
                placeholder="مثال: CRT-450-DX"
                className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
            </div>
          </div>
        </div>

        {/* Problem description + observations with simulated voice recording */}
        <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
          {/* Problem description */}
          <div>
            <div className="flex justify-between items-center mb-1.5">
              <label className="block text-xs font-bold text-slate-600">{t.label_describe_problem} *</label>
              <button
                id="mic-problem-details"
                type="button"
                onClick={() => startVoiceDictation('problemDetails')}
                className={`flex items-center gap-1.5 px-2.5 py-1 text-xs font-bold rounded-lg transition border cursor-pointer ${
                  listeningField === 'problemDetails'
                    ? 'bg-red-50 text-red-600 border-red-200 animate-pulse'
                    : 'bg-blue-50 text-blue-600 border-blue-100 hover:bg-blue-100/60'
                }`}
              >
                <Mic className="w-3.5 h-3.5" />
                <span>{listeningField === 'problemDetails' ? t.mic_listening : t.mic_idle}</span>
              </button>
            </div>
            <textarea
              id="input-problem-details"
              required
              rows={3}
              value={problemDetails}
              onChange={(e) => setProblemDetails(e.target.value)}
              placeholder={t.hint_problem_details}
              className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            ></textarea>
          </div>

          {/* Observations */}
          <div>
            <div className="flex justify-between items-center mb-1.5">
              <label className="block text-xs font-bold text-slate-600">{t.label_observations}</label>
              <button
                id="mic-observations"
                type="button"
                onClick={() => startVoiceDictation('observations')}
                className={`flex items-center gap-1.5 px-2.5 py-1 text-xs font-bold rounded-lg transition border cursor-pointer ${
                  listeningField === 'observations'
                    ? 'bg-red-50 text-red-600 border-red-200 animate-pulse'
                    : 'bg-blue-50 text-blue-600 border-blue-100 hover:bg-blue-100/60'
                }`}
              >
                <Mic className="w-3.5 h-3.5" />
                <span>{listeningField === 'observations' ? t.mic_listening : t.mic_idle}</span>
              </button>
            </div>
            <textarea
              id="input-observations"
              rows={2}
              value={observations}
              onChange={(e) => setObservations(e.target.value)}
              placeholder={t.hint_observations}
              className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            ></textarea>
          </div>

          {/* Error Codes */}
          <div>
            <label className="block text-xs font-bold text-slate-600 mb-1.5">{t.label_error_codes}</label>
            <input
              id="input-error-code"
              type="text"
              value={errorCode}
              onChange={(e) => setErrorCode(e.target.value)}
              placeholder="مثال: E11 / Error code 4"
              className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            />
          </div>
        </div>

        {/* Visual AI photo uploading block */}
        <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
          <h3 className="font-bold text-slate-900 border-b border-slate-100 pb-2 flex items-center gap-2 text-sm">
            <Camera className="w-5 h-5 text-blue-600" />
            <span>{t.label_visual_ai}</span>
          </h3>

          <div className="grid grid-cols-3 gap-3">
            {/* General view photo card */}
            <div
              id="upload-general-card"
              onClick={() => fileInputGeneral.current?.click()}
              className="aspect-square border-2 border-dashed border-slate-200 rounded-2xl hover:border-blue-400 hover:bg-blue-50/20 transition cursor-pointer flex flex-col items-center justify-center p-2 text-center relative group overflow-hidden"
            >
              <input
                type="file"
                ref={fileInputGeneral}
                accept="image/*"
                onChange={(e) => handleImageChange('general', e)}
                className="hidden"
              />
              {images.general ? (
                <>
                  <img src={images.general} alt="General" className="absolute inset-0 w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition flex items-center justify-center gap-2">
                    <button
                      type="button"
                      onClick={(e) => removeImage('general', e)}
                      className="p-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg transition cursor-pointer"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                  <CheckCircle2 className="w-5 h-5 text-emerald-500 absolute top-2 right-2 drop-shadow-md" />
                </>
              ) : (
                <>
                  <Upload className="w-6 h-6 text-slate-400 group-hover:text-blue-500 transition mb-1" />
                  <span className="text-[10px] font-bold text-slate-500">{t.title_img_general}</span>
                </>
              )}
            </div>

            {/* Nameplate photo card */}
            <div
              id="upload-plate-card"
              onClick={() => fileInputPlate.current?.click()}
              className="aspect-square border-2 border-dashed border-slate-200 rounded-2xl hover:border-blue-400 hover:bg-blue-50/20 transition cursor-pointer flex flex-col items-center justify-center p-2 text-center relative group overflow-hidden"
            >
              <input
                type="file"
                ref={fileInputPlate}
                accept="image/*"
                onChange={(e) => handleImageChange('plate', e)}
                className="hidden"
              />
              {images.plate ? (
                <>
                  <img src={images.plate} alt="Plate" className="absolute inset-0 w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition flex items-center justify-center gap-2">
                    <button
                      type="button"
                      onClick={(e) => removeImage('plate', e)}
                      className="p-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg transition cursor-pointer"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                  <CheckCircle2 className="w-5 h-5 text-emerald-500 absolute top-2 right-2 drop-shadow-md" />
                </>
              ) : (
                <>
                  <Upload className="w-6 h-6 text-slate-400 group-hover:text-blue-500 transition mb-1" />
                  <span className="text-[10px] font-bold text-slate-500">{t.title_img_plate}</span>
                </>
              )}
            </div>

            {/* Closeup photo card */}
            <div
              id="upload-closeup-card"
              onClick={() => fileInputCloseup.current?.click()}
              className="aspect-square border-2 border-dashed border-slate-200 rounded-2xl hover:border-blue-400 hover:bg-blue-50/20 transition cursor-pointer flex flex-col items-center justify-center p-2 text-center relative group overflow-hidden"
            >
              <input
                type="file"
                ref={fileInputCloseup}
                accept="image/*"
                onChange={(e) => handleImageChange('closeup', e)}
                className="hidden"
              />
              {images.closeup ? (
                <>
                  <img src={images.closeup} alt="Closeup" className="absolute inset-0 w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition flex items-center justify-center gap-2">
                    <button
                      type="button"
                      onClick={(e) => removeImage('closeup', e)}
                      className="p-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg transition cursor-pointer"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                  <CheckCircle2 className="w-5 h-5 text-emerald-500 absolute top-2 right-2 drop-shadow-md" />
                </>
              ) : (
                <>
                  <Upload className="w-6 h-6 text-slate-400 group-hover:text-blue-500 transition mb-1" />
                  <span className="text-[10px] font-bold text-slate-500">{t.title_img_close_up}</span>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Submit to AI button */}
        <button
          id="submit-info-btn"
          type="submit"
          className="w-full py-4 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold text-base transition flex items-center justify-center gap-2 shadow-lg shadow-blue-500/20 cursor-pointer"
        >
          <span>{t.submit_button_text}</span>
        </button>
      </form>
    </div>
  );
};
export default DeviceInfoScreen;
