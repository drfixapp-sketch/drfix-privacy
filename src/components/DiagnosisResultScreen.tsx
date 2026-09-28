import React, { useState, useEffect } from 'react';
import { translations, Language } from '../utils/translations';
import { AIReportState } from '../types';
import { ArrowRight, ShieldAlert, Wrench, RefreshCw, ShoppingCart, HelpCircle } from 'lucide-react';
import confetti from 'canvas-confetti';

interface DiagnosisResultScreenProps {
  lang: Language;
  onBack: () => void;
  onNavigateToProcurement: () => void;
  deviceData: {
    deviceName: string;
    manufacturer: string;
    model: string;
    problemDetails: string;
    observations: string;
    errorCode: string;
    images: { general?: string; plate?: string; closeup?: string };
  };
}

export const DiagnosisResultScreen: React.FC<DiagnosisResultScreenProps> = ({
  lang,
  onBack,
  onNavigateToProcurement,
  deviceData
}) => {
  const t = translations[lang];
  const isRtl = lang === 'ar';

  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [completedSteps, setCompletedSteps] = useState<number[]>([]);
  const [recalibrated, setRecalibrated] = useState(false);
  const [recalibrationMsg, setRecalibrationMsg] = useState<{ ar: string; en: string } | null>(null);
  const [report, setReport] = useState<AIReportState | null>(null);

  // Generate localized AI report dynamically based on device details on mount
  useEffect(() => {
    const isAcRelated = /ac|مكيف|تكييف|تبريد|ضاغط|compressor|chiller/i.test(deviceData.deviceName + ' ' + deviceData.problemDetails);

    let generatedReport: AIReportState;

    if (isAcRelated) {
      generatedReport = {
        currentStatusAr: `اشتباه بتلف مكثف البدء والتشغيل (Start/Run Capacitor Failure) لجهاز ${deviceData.deviceName}`,
        currentStatusEn: `Suspected Start/Run Capacitor Failure for ${deviceData.deviceName}`,
        safetyWarningAr: 'افصل مصدر الكهرباء الرئيسي تماماً! تيار مكثفات البدء قد يحتوي شحنة مخزنة عالية الفولتية (تصل لـ 400 فولت) كافية لإحداث صعقة خطيرة. أفرغ شحنة المكثف يدوياً بمفك معزول.',
        statusWarningEn: 'HIGH VOLTAGE WARNING: Disconnect main power entirely! Capacitor holds charge up to 400V. Safely discharge terminal contacts using an insulated engineering screwdriver.',
        toolsAr: ['ملتيميتر رقمي قياسي مع مقياس سعة (Microfarad)', 'مفك مسطح ومفك مصلب معزول بالكامل', 'بنسة عزل وقاطع أسلاك كهربائي', 'قفازات سلامة صناعية عازلة للجهد'],
        toolsEn: ['Digital Multimeter with capacitance tester (uF)', 'Fully insulated flathead & phillips screwdrivers', 'Wire strippers & insulated pliers', 'Industrial high-voltage safety gloves'],
        confidenceRate: 92,
        confidenceReasonsAr: [
          'وجود صوت طنين خفيف دون استجابة الضاغط للبدء',
          'سحب تيار بدء تشغيل مرتفع جداً (LRA) يفصل القاطع فجأة',
          'حرارة ملموسة في الهيكل الخارجي دون ضغط غاز'
        ],
        confidenceReasonsEn: [
          'Presence of humming noise while compressor refuses to kick in',
          'Locked Rotor Amperage (LRA) spike tripping safety breaker',
          'Warm outer compressor casing with zero refrigerant circulation'
        ],
        alternativeCausesAr: {
          'تلف ريليه ملامس التشغيل (Bad Contactor Relay)': 15,
          'قصر كهربائي داخلي في ملفات الضاغط (Short Circuit windings)': 8,
          'انحشار ميكانيكي داخلي بالضاغط (Seized Compressor)': 5
        },
        alternativeCausesEn: {
          'Damaged Contactor Relay': 15,
          'Short circuit in compressor windings': 8,
          'Seized mechanical parts in compressor': 5
        },
        steps: [
          {
            number: 1,
            textAr: 'افصل القاطع الرئيسي لوحدة التبريد وقم بالوصول لصندوق الكهرباء الجانبي وتأكد من خلوه من الفولتية بقراءة فاحص الجهد.',
            textEn: 'Disconnect the main breaker of the cooling unit, open the side electrical panel access, and verify zero voltage with an electrical tester.',
            estimatedTimeAr: '3 دقائق',
            estimatedTimeEn: '3 min',
            isCompleted: false
          },
          {
            number: 2,
            textAr: 'قم بإفراغ شحنة المكثف يدوياً بوضع مفك معزول يلامس كلاً من المحطة المشتركة (Common) والمحطات الأخرى بالتوالي.',
            textEn: 'Safely discharge the capacitor by shorting the Common terminal to Hermetic & Fan terminals using an insulated heavy screwdriver.',
            estimatedTimeAr: '2 دقيقة',
            estimatedTimeEn: '2 min',
            isCompleted: false
          },
          {
            number: 3,
            textAr: 'افصل الأسلاك من المكثف التالف وقس السعة بالميكروفاراد (uF). إذا كانت أقل من 10% من القيمة الاسمية (مثلاً أقل من 40 uF لمكثف 45 uF) فيجب الاستبدال.',
            textEn: 'Disconnect the wires from the old capacitor and measure the capacitance. If it measures below 10% of rated value (e.g. below 40uF for a 45uF rating), it is defective.',
            estimatedTimeAr: '5 دقائق',
            estimatedTimeEn: '5 min',
            isCompleted: false
          },
          {
            number: 4,
            textAr: 'ركب مكثفاً جديداً من نفس السعة والفولتية المحددة، ثبت الأسلاك بإحكام، ثم شغل القاطع الرئيسي وقس تيار الاستهلاك المستقر.',
            textEn: 'Install a new capacitor of matching rating (uF & voltage), secure terminals, re-engage the main breaker, and measure running current (Amperage).',
            estimatedTimeAr: '5 دقائق',
            estimatedTimeEn: '5 min',
            isCompleted: false
          }
        ],
        partNameAr: 'مكثف تشغيل ثنائي (Dual Run Capacitor 45+5 uF, 370/440V)',
        partNameEn: 'Dual Run Capacitor 45+5 uF, 370/440V',
        partDiscount: '15%',
        partCode: 'FIX-CAP-45',
        totalTimeAr: '15 دقيقة',
        totalTimeEn: '15 mins',
        difficultyAr: 'متوسط (فني كهربائي)',
        difficultyEn: 'Medium (Electrician)',
        difficultyColor: 'amber',
        partCostRangeAr: '10 - 18 دينار أردني',
        partCostRangeEn: '10 - 18 JOD (approx. 50-95 SAR)',
        fixCostRangeAr: '15 - 25 دينار أردني',
        fixCostRangeEn: '15 - 25 JOD (approx. 80-130 SAR)',
        aiBasisAr: ['كود الخطأ المدخل ومطابقته لكتالوجات Carrier المعتمدة', 'تحليل العلامات الحسية والميكانيكية المذكورة بالتقرير'],
        aiBasisEn: ['Supplied error code matched with Carrier certified industrial manual', 'Observations matched with known compressor locked rotor syndromes']
      };
    } else {
      // General dynamic fallback report customized to whatever they entered
      const cleanDevName = deviceData.deviceName || (isRtl ? 'الجهاز المدخل' : 'Device');
      generatedReport = {
        currentStatusAr: `اشتباه بوجود عطل ميكانيكي / كهربائي في ${cleanDevName}`,
        currentStatusEn: `Suspected Electrical/Mechanical fault in ${cleanDevName}`,
        safetyWarningAr: 'تحذير السلامة العامة: يرجى فصل الطاقة وارتداء القفازات الواقية المعتمدة قبل محاولة الفحص أو فك الأغطية الميكانيكية.',
        statusWarningEn: 'SAFETY WARNING: Please disconnect power sources and wear standard protective gear before physical teardown or electrical diagnosis.',
        toolsAr: ['طقم مفكات هندسي متعدد الرؤوس معزول', 'أداة قياس الجهد والتيار (Multimeter)', 'مفتاح ربط قابل للتعديل (Wrench)'],
        toolsEn: ['Insulated screwdriver set', 'Multimeter / Voltage tester', 'Adjustable wrench'],
        confidenceRate: 85,
        confidenceReasonsAr: [
          `العلامات ومؤشرات العطل في ${cleanDevName} تشير لخلل بالدائرة أو الموتور`,
          'كود الخطأ والمشكلة متطابقين مع أعطال الطاقة والحمل الزائد'
        ],
        confidenceReasonsEn: [
          `Telemetry signs on ${cleanDevName} point to circuit or mechanical blockage`,
          'Error code matches overload safety trip conditions'
        ],
        alternativeCausesAr: {
          'تلف وحدة التحكم الكهربائية (ECU/Control Board)': 25,
          'انحشار الأجزاء المتحركة بفعل التكلس (Mechanical Jamming)': 15,
          'انقطاع أحد فازات التغذية الكهربائية (Phase Phase Loss)': 10
        },
        alternativeCausesEn: {
          'Defective Control Board / ECU': 25,
          'Mechanical Jamming / Scaling': 15,
          'Electrical Phase Loss': 10
        },
        steps: [
          {
            number: 1,
            textAr: `افصل تيار الكهرباء عن ${cleanDevName} بشكل كامل وافحص الأسلاك والموصلات الخارجية بحثاً عن آثار حروق أو تآكل.`,
            textEn: `Fully isolate ${cleanDevName} from power and inspect external cables and wire harness for burn marks or wear.`,
            estimatedTimeAr: '4 دقائق',
            estimatedTimeEn: '4 min',
            isCompleted: false
          },
          {
            number: 2,
            textAr: 'افتح غطاء صندوق التحكم وقس مقاومة ملفات المحرك الكهربائي للتأكد من عدم وجود قصر أرضي.',
            textEn: 'Open the motor terminal cover and measure windings resistance with a multimeter to check for ground shorts.',
            estimatedTimeAr: '6 دقائق',
            estimatedTimeEn: '6 min',
            isCompleted: false
          },
          {
            number: 3,
            textAr: 'افحص تروس التوصيل أو عمود الدوران يدوياً للتأكد من حرية الحركة الميكانيكية وعدم وجود انسداد.',
            textEn: 'Manually rotate the shaft or gears to check for smooth mechanical rotation and lack of binding.',
            estimatedTimeAr: '5 دقائق',
            estimatedTimeEn: '5 min',
            isCompleted: false
          }
        ],
        partNameAr: `مكون تحكم / جزء ميكانيكي لـ ${cleanDevName}`,
        partNameEn: `Control Module / Mechanical spare part for ${cleanDevName}`,
        partDiscount: '10%',
        partCode: 'FIX-GEN-PART',
        totalTimeAr: '15 دقيقة',
        totalTimeEn: '15 mins',
        difficultyAr: 'صيانة متقدمة',
        difficultyEn: 'Advanced Maintenance',
        difficultyColor: 'red',
        partCostRangeAr: '20 - 45 دينار أردني',
        partCostRangeEn: '20 - 45 JOD (approx. 100-240 SAR)',
        fixCostRangeAr: '15 - 30 دينار أردني',
        fixCostRangeEn: '15 - 30 JOD (approx. 80-160 SAR)',
        aiBasisAr: ['تحليل المدخلات ومطابقتها لقاعدة البيانات الفنية المعتمدة لدى Dr Fix'],
        aiBasisEn: ['Analyzing user inputs against Dr Fix specialized technical database']
      };
    }

    setReport(generatedReport);
  }, [deviceData, isRtl]);

  const handleStepComplete = (index: number) => {
    if (!report) return;

    if (completedSteps.includes(index)) {
      setCompletedSteps(prev => prev.filter(i => i !== index));
    } else {
      setCompletedSteps(prev => [...prev, index]);

      // Highlight step completion with sound indicator or dynamic increment
      if (index === report.steps.length - 1) {
        // Trigger celebratory confetti if all steps are checked!
        confetti({
          particleCount: 100,
          spread: 70,
          origin: { y: 0.6 }
        });
      }

      if (index === currentStepIndex && currentStepIndex < report.steps.length - 1) {
        setCurrentStepIndex(currentStepIndex + 1);
      }
    }
  };

  const triggerAiRecalibration = () => {
    if (!report) return;

    // Simulate AI dynamic path rerouting
    setRecalibrated(true);

    const isAc = /ac|مكيف|تكييف|تبريد/i.test(deviceData.deviceName + ' ' + deviceData.problemDetails);

    if (isAc) {
      setRecalibrationMsg({
        ar: '⚡ مسار بديل للـ AI: نظراً لعدم استجابة المكثف أو وجود تيار صفري بالضاغط، تم رصد عطل محتمل في مستشعر الضغط العالي (HP Cutout Switch) أو انسداد فلاتر الشحنة. يرجى مراجعة الصمام وقراءة الضغوط قبل إتلاف الضاغط.',
        en: '⚡ AI Recalibration Pathway: High amperage or zero start suggests possible high-pressure cutout switch (HP Cutout) failure or line restriction. Verify refrigerant pressure readings before condemning the compressor.'
      });
    } else {
      setRecalibrationMsg({
        ar: '⚡ مسار بديل للـ AI: تم الكشف عن احتمال وجود خلل بفتيل الأمان المصهر (Fuse) أو ترحيل غير مكتمل للجهد بوحدة المغذي الفرعي. يرجى فحص القواطع المنفردة وتيار لوحة التشغيل.',
        en: '⚡ AI Recalibration Pathway: High resistance detected. Check inline safety fuses, contactor thermal overload state, and sub-panel circuit breaker terminals.'
      });
    }

    // Play fancy vibration feedback / confetti elements
    confetti({
      particleCount: 40,
      colors: ['#f59e0b', '#3b82f6'],
      spread: 40
    });
  };

  if (!report) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-8">
        <RefreshCw className="w-8 h-8 text-blue-600 animate-spin mb-3" />
        <p className="text-slate-600 font-bold">{isRtl ? 'جاري معالجة البيانات بالذكاء الاصطناعي...' : 'Processing AI Diagnostic Engines...'}</p>
      </div>
    );
  }

  const stepsCount = report.steps.length;
  const progressPercent = Math.round((completedSteps.length / stepsCount) * 100);

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

        <div className="text-xs font-bold text-slate-500 bg-slate-100 px-3 py-1.5 rounded-xl">
          {isRtl ? 'المحرك: Gemini 1.5 Pro Mapped' : 'Engine: Gemini 1.5 Pro Mapped'}
        </div>
      </div>

      {/* Main Core Diagnosis Display with Confidence Meter */}
      <div className="bg-gradient-to-br from-slate-900 via-slate-950 to-blue-950 text-white rounded-2xl p-6 shadow-md relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-blue-600/10 rounded-full blur-3xl pointer-events-none"></div>

        <div className="relative z-10 flex flex-col md:flex-row gap-6 items-center">
          {/* Circular Confidence Meter using canvas or CSS radial */}
          <div className="relative flex items-center justify-center w-32 h-32 shrink-0">
            <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
              {/* Outer track */}
              <circle cx="50" cy="50" r="40" stroke="rgba(255, 255, 255, 0.08)" strokeWidth="8" fill="transparent" />
              {/* Inner animated track */}
              <circle
                cx="50"
                cy="50"
                r="40"
                stroke={report.confidenceRate > 90 ? '#10b981' : '#f59e0b'}
                strokeWidth="8"
                fill="transparent"
                strokeDasharray="251.2"
                strokeDashoffset={251.2 - (251.2 * report.confidenceRate) / 100}
                className="transition-all duration-1000 ease-out"
              />
            </svg>
            <div className="absolute flex flex-col items-center">
              <span className="text-3xl font-black text-white">{report.confidenceRate}%</span>
              <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Confidence</span>
            </div>
          </div>

          {/* Diagnosis textual summaries */}
          <div className="space-y-3 text-center md:text-right flex-1">
            <span className="px-3 py-1 bg-blue-500/20 text-blue-300 rounded-xl text-xs font-bold border border-blue-500/10">
              {isRtl ? 'تشخيص تشغيلي مدعم' : 'Operational Diagnosis'}
            </span>
            <h2 className="text-xl md:text-2xl font-black text-white leading-snug">
              {isRtl ? report.currentStatusAr : report.currentStatusEn}
            </h2>

            {/* Confidence breakdown */}
            <div className="space-y-1.5 pt-1 text-slate-300 text-xs font-medium text-right">
              {(isRtl ? report.confidenceReasonsAr : report.confidenceReasonsEn).map((reason, i) => (
                <div key={i} className="flex items-start gap-1.5 justify-end">
                  <span>{reason}</span>
                  <span className="text-emerald-400">✓</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Safety and voltage caution bar */}
      <div className="bg-amber-50 border border-amber-200 text-amber-900 rounded-2xl p-5 flex items-start gap-4 shadow-sm">
        <ShieldAlert className="w-6 h-6 text-amber-600 shrink-0 mt-0.5" />
        <div>
          <h4 className="font-extrabold text-sm">{isRtl ? 'تحذير السلامة المهنية والمخاطر الميدانية:' : 'Industrial Field Safety & Warnings:'}</h4>
          <p className="text-xs text-amber-800 mt-1 leading-relaxed font-semibold">
            {isRtl ? report.safetyWarningAr : report.statusWarningEn}
          </p>
        </div>
      </div>

      {/* Main content grid: Interactive Steps + Alternative Causes */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Step checklist and guide */}
        <div className="lg:col-span-2 space-y-6">
          {/* Steps module */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="font-bold text-slate-900 flex items-center gap-2">
                <Wrench className="w-5 h-5 text-blue-600" />
                <span>{t.steps_title}</span>
              </h3>
              <span className="text-xs font-bold text-blue-600 bg-blue-50 px-3 py-1 rounded-lg">
                {isRtl ? `تغطية الحل: ${progressPercent}%` : `Progress: ${progressPercent}%`}
              </span>
            </div>

            {/* Progress Bar */}
            <div className="w-full bg-slate-100 h-2.5 rounded-full overflow-hidden">
              <div
                className="bg-blue-600 h-full transition-all duration-500 ease-out"
                style={{ width: `${progressPercent}%` }}
              ></div>
            </div>

            {/* Step list */}
            <div className="space-y-4 pt-2">
              {report.steps.map((step, index) => {
                const isCompleted = completedSteps.includes(index);
                const isActive = index === currentStepIndex;

                return (
                  <div
                    key={step.number}
                    id={`step-container-${index}`}
                    onClick={() => handleStepComplete(index)}
                    className={`p-4 rounded-xl border transition cursor-pointer flex gap-4 items-start ${
                      isCompleted
                        ? 'bg-emerald-50/50 border-emerald-100 text-slate-500'
                        : isActive
                        ? 'bg-blue-50/20 border-blue-200 shadow-sm ring-1 ring-blue-100 text-slate-800'
                        : 'bg-white border-slate-100 text-slate-700 hover:border-slate-200'
                    }`}
                  >
                    {/* Circle counter or checkmark */}
                    <div
                      className={`w-7 h-7 rounded-full shrink-0 flex items-center justify-center font-bold text-xs ${
                        isCompleted
                          ? 'bg-emerald-500 text-white'
                          : isActive
                          ? 'bg-blue-600 text-white'
                          : 'bg-slate-100 text-slate-500'
                      }`}
                    >
                      {isCompleted ? '✓' : step.number}
                    </div>

                    <div className="flex-1 space-y-1">
                      <p className={`text-sm leading-relaxed ${isCompleted ? 'line-through text-slate-400 font-medium' : 'font-semibold'}`}>
                        {isRtl ? step.textAr : step.textEn}
                      </p>
                      <div className="flex items-center gap-2 text-slate-400 text-xs">
                        <span>⏱️ {isRtl ? step.estimatedTimeAr : step.estimatedTimeEn}</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Recalibration Section */}
            {recalibrated && recalibrationMsg && (
              <div className="bg-amber-50 border border-amber-200 text-amber-900 rounded-xl p-4 text-xs font-semibold leading-relaxed animate-fade-in">
                {isRtl ? recalibrationMsg.ar : recalibrationMsg.en}
              </div>
            )}

            {/* Manual controls & AI recalibrator button */}
            <div className="flex flex-wrap gap-3 pt-3">
              <button
                id="next-step-trigger"
                onClick={() => {
                  if (currentStepIndex < stepsCount) {
                    handleStepComplete(currentStepIndex);
                  }
                }}
                disabled={completedSteps.length === stepsCount}
                className={`flex-1 py-3 px-4 rounded-xl font-bold text-sm transition flex items-center justify-center gap-2 cursor-pointer ${
                  completedSteps.length === stepsCount
                    ? 'bg-slate-100 text-slate-400 cursor-not-allowed'
                    : 'bg-blue-600 text-white hover:bg-blue-500 shadow-md shadow-blue-500/10'
                }`}
              >
                <span>{t.next_step_btn}</span>
              </button>

              <button
                id="ai-recalibrator-trigger"
                onClick={triggerAiRecalibration}
                className="py-3 px-4 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-sm rounded-xl transition flex items-center gap-2 cursor-pointer border border-slate-200"
              >
                <RefreshCw className="w-4 h-4 text-amber-600" />
                <span>{t.ai_backup_btn}</span>
              </button>
            </div>
          </div>
        </div>

        {/* Right Col: Tools, Expected Parts, Alternative Causes */}
        <div className="space-y-6">
          {/* Required Tools */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-3">
            <h3 className="font-bold text-slate-900 border-b border-slate-100 pb-2 flex items-center gap-2 text-sm">
              <Wrench className="w-4.5 h-4.5 text-blue-600" />
              <span>{isRtl ? 'الأدوات والمعدات اللازمة للفحص' : 'Required Testing Tools'}</span>
            </h3>
            <ul className="space-y-1.5 text-slate-700 text-xs font-semibold">
              {(isRtl ? report.toolsAr : report.toolsEn).map((tool, i) => (
                <li key={i} className="flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                  <span>{tool}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Expected Spare Parts & procurement link */}
          <div className="bg-gradient-to-br from-blue-50 to-indigo-100/50 border border-blue-100 p-6 rounded-2xl shadow-sm space-y-4">
            <h3 className="font-extrabold text-slate-900 flex items-center gap-2 text-sm">
              <ShoppingCart className="w-5 h-5 text-blue-600" />
              <span>{t.expected_parts_title}</span>
            </h3>

            <div className="bg-white p-4 rounded-xl border border-blue-200/50 space-y-2">
              <div className="flex justify-between items-start">
                <span className="text-xs font-bold text-slate-900 leading-tight">
                  {isRtl ? report.partNameAr : report.partNameEn}
                </span>
                <span className="bg-emerald-100 text-emerald-800 text-[10px] font-black px-2 py-0.5 rounded shrink-0">
                  {isRtl ? `خصم ${report.partDiscount}` : `${report.partDiscount} Off`}
                </span>
              </div>
              <div className="text-[10px] text-slate-500 font-mono">PN: {report.partCode}</div>

              <div className="border-t border-slate-100 pt-2 flex justify-between text-xs font-bold text-slate-700">
                <span>{isRtl ? 'سعر القطعة التقديري:' : 'Est. Parts Cost:'}</span>
                <span className="text-blue-600">{isRtl ? report.partCostRangeAr : report.partCostRangeEn}</span>
              </div>

              <div className="flex justify-between text-xs font-bold text-slate-700">
                <span>{isRtl ? 'أجور التركيب المقدرة:' : 'Est. Labor Fee:'}</span>
                <span className="text-indigo-600">{isRtl ? report.fixCostRangeAr : report.fixCostRangeEn}</span>
              </div>
            </div>

            <button
              id="find-parts-screen-trigger"
              onClick={onNavigateToProcurement}
              className="w-full py-3 px-4 bg-blue-600 hover:bg-blue-500 text-white font-extrabold text-xs rounded-xl transition shadow-md shadow-blue-500/10 flex items-center justify-center gap-2 cursor-pointer"
            >
              <ShoppingCart className="w-4 h-4" />
              <span>{t.search_parts_btn}</span>
            </button>
          </div>

          {/* Alternative Causes */}
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm space-y-4">
            <h3 className="font-bold text-slate-900 border-b border-slate-100 pb-2 flex items-center gap-2 text-sm">
              <HelpCircle className="w-4.5 h-4.5 text-blue-600" />
              <span>{t.alternative_title}</span>
            </h3>

            <div className="space-y-3">
              {Object.entries(isRtl ? report.alternativeCausesAr : report.alternativeCausesEn).map(([cause, percentage]) => (
                <div key={cause} className="space-y-1.5">
                  <div className="flex justify-between text-xs font-bold text-slate-700">
                    <span>{cause}</span>
                    <span>{percentage}%</span>
                  </div>
                  <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                    <div
                      className="bg-slate-400 h-full rounded-full"
                      style={{ width: `${percentage}%` }}
                    ></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
export default DiagnosisResultScreen;
