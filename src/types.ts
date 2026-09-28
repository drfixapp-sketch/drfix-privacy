export interface ForumReply {
  id: string;
  author: string;
  specialty: string;
  content: string;
  createdAt: string;
  isApproved: boolean;
}

export interface ForumPost {
  id: string;
  author: string;
  specialty: string;
  title: string;
  description: string;
  category: string;
  localImagePath?: string;
  upvotes: number;
  downvotes: number;
  views: number;
  replies: ForumReply[];
  isApproved: boolean;
}

export interface PromoCode {
  code: string;
  companyName: string;
  discountPercentage: number;
}

export interface EngineeringCategory {
  id: string;
  titleAr: string;
  titleEn: string;
  icon: string; // lucide icon name
  themeColor: string; // Tailwind color class suffix (e.g. 'blue', 'amber')
}

export interface DiagnosticStep {
  number: number;
  textAr: string;
  textEn: string;
  estimatedTimeAr: string;
  estimatedTimeEn: string;
  isCompleted: boolean;
}

export interface AIReportState {
  currentStatusAr: string;
  currentStatusEn: string;
  safetyWarningAr: string;
  statusWarningEn: string;
  toolsAr: string[];
  toolsEn: string[];
  steps: DiagnosticStep[];
  partNameAr: string;
  partNameEn: string;
  partDiscount: string;
  partCode: string;
  currentStepIndex?: number;
  confidenceRate: number;
  confidenceReasonsAr: string[];
  confidenceReasonsEn: string[];
  alternativeCausesAr: Record<string, number>;
  alternativeCausesEn: Record<string, number>;
  totalTimeAr: string;
  totalTimeEn: string;
  difficultyAr: string;
  difficultyEn: string;
  difficultyColor: string; // e.g. 'amber', 'red'
  partCostRangeAr: string;
  partCostRangeEn: string;
  fixCostRangeAr: string;
  fixCostRangeEn: string;
  aiBasisAr: string[];
  aiBasisEn: string[];
}
