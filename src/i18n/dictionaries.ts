import { Locale, LocalizedText } from '@/types';

export const UI_DICTIONARY: Record<string, Record<Locale, string>> = {
  // Brand & Slogans
  brandName: {
    en: 'SWAT RIDE',
    ur: 'سوات رائیڈ',
    ps: 'سوات رایډ',
  },
  tagline: {
    en: 'Your Trusted Premium Mobility & Ecosystem in Swat, KPK',
    ur: 'سوات، خیبر پختونخوا میں آپ کا قابل اعتماد پریمیئم سفری اور سفری نظام',
    ps: 'په سوات، خیبر پختونخوا کې ستاسو د باور وړ پریمیم سفر او خدماتو سیسټم',
  },
  // Global CTAs
  downloadApp: {
    en: 'Download App',
    ur: 'ایپ ڈاؤنلوڈ کریں',
    ps: 'ایپ ډاونلوډ کړئ',
  },
  exploreServices: {
    en: 'Explore Services',
    ur: 'ہماری خدمات دیکھیں',
    ps: 'خدمتونه وپلټئ',
  },
  becomePartner: {
    en: 'Partner With Us',
    ur: 'ہمارے پارٹنر بنیں',
    ps: 'زموږ سره ملګري شئ',
  },
  learnMore: {
    en: 'Learn More',
    ur: 'مزید جانیں',
    ps: 'نور معلومات',
  },
  viewAll: {
    en: 'View All',
    ur: 'سب دیکھیں',
    ps: 'ټول وګورئ',
  },
  emergencySOS: {
    en: 'Safety & Emergency SOS',
    ur: 'حفاظت اور ہنگامی مدد (SOS)',
    ps: 'خونديتوب او بېړنۍ مرسته (SOS)',
  },
  searchPlaceholder: {
    en: 'Search services, help articles, or locations in Swat...',
    ur: 'سوات میں خدمات، مدد کے مضامین، یا مقامات تلاش کریں...',
    ps: 'په سوات کې خدمتونه، د مرستې مقالې، یا ځایونه وپلټئ...',
  },
  backToHome: {
    en: 'Back to Home',
    ur: 'ہوم پیج پر واپس جائیں',
    ps: 'کور پاڼې ته بیرته تګ',
  },
  // Navigation Headers
  navHome: {
    en: 'Home',
    ur: 'ہوم',
    ps: 'کور',
  },
  navRide: {
    en: 'Ride',
    ur: 'رائیڈ',
    ps: 'سفر',
  },
  navFood: {
    en: 'Food Delivery',
    ur: 'فوڈ ڈیلیوری',
    ps: 'خواړه رسول',
  },
  navCargo: {
    en: 'Cargo & Logistics',
    ur: 'کارگو اور لاجسٹکس',
    ps: 'کارګو او لوژستیک',
  },
  navStudent: {
    en: 'Student Ride',
    ur: 'اسٹوڈنٹ رائیڈ',
    ps: 'د زده کونکو سفر',
  },
  navHotels: {
    en: 'Hotels',
    ur: 'ہوٹلز',
    ps: 'هوټلونه',
  },
  navTours: {
    en: 'Tours & Tourism',
    ur: 'ٹورز اور سیاحت',
    ps: 'سیاحت او چکرونه',
  },
  navPartners: {
    en: 'Partners',
    ur: 'پارٹنرز',
    ps: 'ملګري',
  },
  navSafety: {
    en: 'Safety & SOS',
    ur: 'حفاظت اور SOS',
    ps: 'خونديتوب او SOS',
  },
  navRewards: {
    en: 'Rewards & Offers',
    ur: 'ریوارڈز اور آفرز',
    ps: 'جایزې او وړاندیزونه',
  },
  navHelp: {
    en: 'Help & Video Tutorials',
    ur: 'مدد اور ویڈیو ٹیوٹوریلز',
    ps: 'مرسته او ویډیو ښوونې',
  },
  navBlog: {
    en: 'Blog & Swat Guides',
    ur: 'بلاگ اور سوات گائیڈز',
    ps: 'بلاګ او د سوات لارښودونه',
  },
  // Safety Disclaimer Notice
  safetyDisclaimer: {
    en: 'SWAT RIDE prioritizes verified safety protocols including emergency SOS contacts and trip sharing. We do not secret-monitor camera or microphone data without lawful authority.',
    ur: 'سوات رائیڈ تصدیق شدہ حفاظتی اصولوں کو ترجیح دیتا ہے جن میں ہنگامی SOS رابطے اور سفر کی معلومات کا اشتراک شامل ہے۔ ہم قانونی اجازت کے بغیر خفیہ کیمرہ یا مائیکروفون مانیٹرنگ نہیں کرتے۔',
    ps: 'سوات رایډ تایید شوي امنیتي اصولو ته لومړیتوب ورکوي، پشمول د بېړنیو SOS اړیکو او د سفر شریکول. موږ د قانوني اجازې پرته کیمره یا مایکروفون نه څارو.',
  },
  // Legal Human Review Notice
  legalHumanReviewNotice: {
    en: 'Note: Official legal terms are reviewed by certified legal counsel in Khyber Pakhtunkhwa, Pakistan.',
    ur: 'نوٹ: سرکاری قانونی شرائط کا جائزہ خیبر پختونخوا، پاکستان کے تصدیق شدہ قانونی مشیروں کے ذریعے لیا جاتا ہے۔',
    ps: 'یادونه: رسمي قانوني شرایط د خیبر پختونخوا، پاکستان د تصدیق شويو حقوقي پوهانو لخوا څیړل کیږي.',
  },
};

export function getUIText(key: keyof typeof UI_DICTIONARY, locale: Locale = 'en'): string {
  const entry = UI_DICTIONARY[key];
  if (!entry) return key;
  return entry[locale] || entry['en'];
}

export function translateText(textObj: LocalizedText, locale: Locale = 'en'): string {
  if (!textObj) return '';
  return textObj[locale] || textObj['en'] || '';
}
