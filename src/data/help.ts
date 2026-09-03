import { HelpCategory, HelpArticle } from '@/types';

export const HELP_CATEGORIES: HelpCategory[] = [
  { id: 'account', slug: 'account', title: { en: 'Account & Profile', ur: 'اکاؤنٹ اور پروفائل', ps: 'حساب او پروفایل' }, description: { en: 'Manage phone number, language, and password.', ur: 'فون نمبر، زبان اور پاسورڈ تبدیل کریں۔', ps: 'د تلیفون شمیره، ژبه او پاسورډ بدل کړئ.' }, iconName: 'User', articleCount: 4 },
  { id: 'ride', slug: 'ride', title: { en: 'Normal Ride Booking', ur: 'نارمل رائیڈ بکنگ', ps: 'د عادي سفر بکینګ' }, description: { en: 'Upfront fares, pickup points, and cancellations.', ur: 'پیشگی کرایہ، پک اپ مقام، اور کینسلیشن۔', ps: 'د کرایې اټکل، د پورته کولو ځای او لغوه کول.' }, iconName: 'Car', articleCount: 5 },
  { id: 'driver', slug: 'driver', title: { en: 'Driver Support', ur: 'ڈرائیور سپورٹ', ps: 'د چلوونکي ملاتړ' }, description: { en: 'Documents, going online, and earnings breakdown.', ur: 'دستاویزات، آن لائن آنا، اور کمیشن کی تفصیل۔', ps: 'اسناد، آنلاین کیدل او د کمیشن تفصیل.' }, iconName: 'SteeringWheel', articleCount: 6 },
  { id: 'food', slug: 'food', title: { en: 'Food Ordering', ur: 'فوڈ آرڈرنگ', ps: 'د خوړو فرمایش' }, description: { en: 'Order tracking, delivery times, and missing items.', ur: 'آرڈر ٹریکنگ، ڈیلیوری کا وقت، اور شکایت۔', ps: 'د فرمایش څارنه، د رسولو وخت او شکایت.' }, iconName: 'Utensils', articleCount: 4 },
  { id: 'restaurant', slug: 'restaurant', title: { en: 'Restaurant Partner', ur: 'ریسٹورانٹ پارٹنر', ps: 'رستورانت ملګری' }, description: { en: 'Menu updates, order acceptance, and payouts.', ur: 'مینیو اپ ڈیٹ، آرڈر وصولی، اور ادائیگیاں۔', ps: 'د مینیو تازه کول، د فرمایش منل او تادیات.' }, iconName: 'Store', articleCount: 5 },
  { id: 'food-rider', slug: 'food-rider', title: { en: 'Food Rider', ur: 'فوڈ رائیڈر', ps: 'د خوړو رایډر' }, description: { en: 'Thermal bags, navigation, and delivery payments.', ur: 'تھرمل بیگ، نیویگیشن، اور ڈیلیوری کی رقم۔', ps: 'حرارتي کڅوړه، نیویګیشن او د تحویلي پیسې.' }, iconName: 'Bike', articleCount: 4 },
  { id: 'cargo', slug: 'cargo', title: { en: 'Cargo & Logistics', ur: 'کارگو اور لاجسٹکس', ps: 'کارګو او لوژستیک' }, description: { en: 'Express vs Heavy tiers, sizing, and pricing.', ur: 'ایکسپریس اور ہیوی کیٹگری، وزن، اور نرخ۔', ps: 'ایکسپریس او دروند کارګو، وزن او نرخونه.' }, iconName: 'Truck', articleCount: 4 },
  { id: 'student-ride', slug: 'student-ride', title: { en: 'Student Ride Transport', ur: 'اسٹوڈنٹ رائیڈ ٹرانسپورٹ', ps: 'د زده کونکو ټرانسپورټ' }, description: { en: 'Monthly subscriptions, drivers, and safety.', ur: 'ماہانہ پیکیج، ڈرائیورز، اور حفاظت۔', ps: 'میاشتنۍ کڅوړې، چلوونکي او خوندیتوب.' }, iconName: 'GraduationCap', articleCount: 5 },
  { id: 'parent', slug: 'parent', title: { en: 'Parent & Guardian Portal', ur: 'والدین اور سرپرست پورٹل', ps: 'د میندو او پلرونو پورټل' }, description: { en: 'Attendance alerts, guardian handover, and SOS.', ur: 'حاضری الرٹس، سرپرست تصدیق، اور SOS۔', ps: 'د حاضری خبرتیاوې، د سرپرست تایید او SOS.' }, iconName: 'ShieldCheck', articleCount: 4 },
  { id: 'hotels', slug: 'hotels', title: { en: 'Hotel Reservations', ur: 'ہوٹل ریزرویشنز', ps: 'د هوټل بکینګونه' }, description: { en: 'Room amenities, check-in rules, and vouchers.', ur: 'کمروں کی سہولیات، چیک ان قوانین، اور واؤچر۔', ps: 'د خونو اسانتیاوې، د چیک ان قوانین او واؤچر.' }, iconName: 'Hotel', articleCount: 4 },
  { id: 'tourism', slug: 'tourism', title: { en: 'Tours & Tourism', ur: 'ٹورز اور سیاحت', ps: 'سیاحت او چکرونه' }, description: { en: '4x4 expeditions, Malam Jabba & Kalam packages.', ur: '4x4 گاڑیاں، مالم جبہ اور کالام پیکیجز۔', ps: '4x4 موټرونه، مالم جبه او کالام کڅوړې.' }, iconName: 'Mountain', articleCount: 4 },
  { id: 'tour-guide', slug: 'tour-guide', title: { en: 'Tour Guide Services', ur: 'ٹور گائیڈ سروسز', ps: 'د لارښود خدمتونه' }, description: { en: 'Hiring a guide, languages, and heritage tours.', ur: 'گائیڈ کی بکنگ، زبانیں، اور تاریخی سیر۔', ps: 'د لارښود بکینګ، ژبې او تاریخي چکرونه.' }, iconName: 'Compass', articleCount: 3 },
  { id: 'payments', slug: 'payments', title: { en: 'Payments & Fares', ur: 'ادائیگیاں اور کرایے', ps: 'تادیات او کرایې' }, description: { en: 'Cash on delivery, upfront estimates, and receipts.', ur: 'کیش ادائیگی، کرایہ کا اندازہ، اور رسیدیں،', ps: 'نغدي تادیه، د کرایې اټکل او رسیدونه.' }, iconName: 'CreditCard', articleCount: 5 },
  { id: 'wallet', slug: 'wallet', title: { en: 'SWAT RIDE Wallet', ur: 'سوات رائیڈ والٹ', ps: 'سوات رایډ والټ' }, description: { en: 'Topping up balance, credits, and refunds.', ur: 'رقم شامل کرنا، کریڈٹس، اور ریفنڈ۔', ps: 'پیسې زیاتول، کریډیټ او ریفینډ.' }, iconName: 'Wallet', articleCount: 4 },
  { id: 'rewards', slug: 'rewards', title: { en: 'Rewards & Loyalty', ur: 'ریوارڈز اور لائلٹی', ps: 'جایزې او وفاداري' }, description: { en: 'Earning Swat points and redeeming rewards.', ur: 'پوائنٹس حاصل کرنا اور انعام وصول کرنا۔', ps: 'پواینټونه ترلاسه کول او انعام اخیستل.' }, iconName: 'Gift', articleCount: 3 },
  { id: 'promo', slug: 'promo', title: { en: 'Promo Codes & Offers', ur: 'پرومو کوڈز اور آفرز', ps: 'پرومو کوډونه او وړاندیزونه' }, description: { en: 'Applying promo codes and seasonal discounts.', ur: 'پرومو کوڈ استعمال کرنا اور خصوصی ڈسکاؤنٹ۔', ps: 'د پرومو کوډ کارول او ځانګړي تخفیفونه.' }, iconName: 'Tag', articleCount: 3 },
  { id: 'safety', slug: 'safety', title: { en: 'Safety & SOS Center', ur: 'حفاظت اور SOS سینٹر', ps: 'خونديتوب او SOS مرکز' }, description: { en: 'Verified emergency SOS, trusted contacts, and privacy.', ur: 'ہنگامی SOS، قابل اعتماد رابطے، اور پرائیویسی۔', ps: 'بېړنی SOS، باوري اړیکې او پرائیویسی.' }, iconName: 'ShieldAlert', articleCount: 6 },
  { id: 'refunds', slug: 'refunds', title: { en: 'Refunds & Cancellations', ur: 'رقم کی واپسی اور کینسلیشن', ps: 'د پیسو بیرته ورکول او لغوه کول' }, description: { en: 'Refund timelines and ride/order cancellation rules.', ur: 'رقم کی واپسی کا وقت اور کینسلیشن کی شرائط۔', ps: 'د پیسو بیرته ورکولو وخت او د لغوه کولو شرایط.' }, iconName: 'RefreshCw', articleCount: 4 },
];

export const HELP_ARTICLES: HelpArticle[] = [
  {
    id: 'sos-how-it-works',
    slug: 'sos-how-it-works',
    categoryId: 'safety',
    title: {
      en: 'How does the Emergency SOS & Trusted Contacts system work?',
      ur: 'ہنگامی SOS اور قابل اعتماد رابطوں کا نظام کیسے کام کرتا ہے؟',
      ps: 'د بېړنۍ SOS او باوري اړیکو سیسټم څنګه کار کوي؟',
    },
    summary: {
      en: 'Learn how our verified emergency SOS button connects you to local responders and trusted family contacts.',
      ur: 'جانیں کہ ہمارا SOS بٹن آپ کو کیسے فوری طور پر خاندان اور امدادی ٹیموں سے جوڑتا ہے۔',
      ps: 'وګورئ چې زموږ د SOS تڼۍ څنګه تاسو له کورنۍ او مرستندویه ټیمونو سره نښلوي.',
    },
    content: {
      en: 'When you press the SOS button in the SWAT RIDE app during an active ride, your GPS coordinates and trip details are immediately shared with your pre-configured Trusted Contacts and our 24/7 Mingora Safety Command Desk. Note: SWAT RIDE strictly adheres to privacy laws and never activates cameras or microphones without explicit legal authority.',
      ur: 'جب آپ سفر کے دوران سوات رائیڈ ایپ میں SOS بٹن دباتے ہیں، تو آپ کا لائیو مقام اور سفر کی تفصیلات فوراً آپ کے منتخب کردہ قابل اعتماد رابطوں اور ہمارے مینگورہ سیفٹی ڈیسک کو ارسال کر دی جاتی ہیں۔ سوات رائیڈ پرائیویسی قوانین کی مکمل پابندی کرتا ہے۔',
      ps: 'کله چې تاسو د سفر پر مهال په سوات رایډ ایپ کې د SOS تڼۍ کیکاږئ، ستاسو ژوندی ځای او د سفر تفصیلات سمدستي ستاسو باوري اړیکو او زموږ د مینګورې امنیتي مرکز ته استول کیږي.',
    },
    lastUpdated: '2026-08-01',
    isPopular: true,
  },
  {
    id: 'upfront-fare-estimate',
    slug: 'upfront-fare-estimate',
    categoryId: 'ride',
    title: {
      en: 'How is the Upfront Fare Estimate calculated in Swat?',
      ur: 'سوات میں پیشگی کرایہ کا اندازہ کیسے لگایا جاتا ہے؟',
      ps: 'په سوات کې د کرایې اټکل څنګه کیږي؟',
    },
    summary: {
      en: 'Understand how distance, road conditions, and transparent pricing shape your ride estimate.',
      ur: 'جانیں کہ فاصلہ، راستے اور شفاف نرخ کرائے کے اندازے کو کیسے تشکیل دیتے ہیں۔',
      ps: 'وګورئ چې واټن او شفاف نرخونه څنګه د کرایې اټکل جوړوي.',
    },
    content: {
      en: 'Upfront Fare Estimates are calculated using the shortest accessible distance between your pickup point in Swat and your destination, combined with standard regional pricing. You see the estimated fare before confirming your booking, ensuring zero surprises.',
      ur: 'پیشگی کرائے کا اندازہ آپ کے پک اپ پوائنٹ اور منزل کے درمیان کم ترین فاصلے اور معیاری نرخوں کو مدنظر رکھ کر لگایا جاتا ہے۔ بکنگ سے پہلے کرایہ دکھا دیا جاتا ہے تاکہ کوئی پوشیدہ چارجز نہ ہوں۔',
      ps: 'د کرایې مخکینۍ اټکل ستاسو د ځای او منزل ترمنځ د لنډ واټن او معیاري نرخونو په اساس کیږي. تاسو د بکینګ څخه مخکې کرایه ګورئ.',
    },
    lastUpdated: '2026-07-28',
    isPopular: true,
  },
  {
    id: 'student-ride-safety-handover',
    slug: 'student-ride-safety-handover',
    categoryId: 'student-ride',
    title: {
      en: 'What is the Authorized Guardian Handover protocol for Student Rides?',
      ur: 'اسٹوڈنٹ رائیڈز کے لیے مجاز سرپرست کے حوالے کرنے کا کیا قانون ہے؟',
      ps: 'د زده کونکو د سفر لپاره د مجاز سرپرست ته د تحویلي قانون څه دی؟',
    },
    summary: {
      en: 'We never release school children to unauthorized individuals. Read about our verified drop-off safety check.',
      ur: 'ہم اسکول کے بچوں کو کبھی کسی غیر تصدیق شدہ شخص کے حوالے نہیں کرتے۔ ہمارے حفاظتی اصول پڑھیں۔',
      ps: 'موږ د ښوونځي ماشومان هیڅکله غیر تایید شوي شخص ته نه سپارو. زموږ د خوندیتوب اصول ولولئ.',
    },
    content: {
      en: 'In our Student Ride package, parents upload photos and names of up to three authorized drop-off guardians. Upon reaching the home destination, the student driver verifies the guardian before completing the trip. If an authorized guardian is not present, the driver immediately contacts the parent and our safety desk.',
      ur: 'ہمارے اسٹوڈنٹ رائیڈ پیکیج میں والدین تین مجاز سرپرستوں کی تصاویر اور نام درج کر سکتے ہیں۔ گھر پہنچنے پر ڈرائیور سرپرست کی تصدیق کرنے کے بعد ہی بچے کو حوالے کرتا ہے۔',
      ps: 'زموږ د زده کونکو په کڅوړه کې، میندې او پلرونه د دریو مجاز سرپرستانو عکسونه او نومونه ثبتوي. کور ته په رسیدو سره، چلوونکی د سرپرست تصدیق کوي.',
    },
    lastUpdated: '2026-08-05',
    isPopular: true,
  },
  {
    id: 'driver-document-verification',
    slug: 'driver-document-verification',
    categoryId: 'driver',
    title: {
      en: 'What documents are required to become a SWAT RIDE Driver?',
      ur: 'سوات رائیڈ ڈرائیور بننے کے لیے کون سی دستاویزات درکار ہیں؟',
      ps: 'د سوات رایډ چلوونکي کیدو لپاره کوم اسناد پکار دي؟',
    },
    summary: {
      en: 'CNIC, driving license, vehicle registration, and clean background verification requirements.',
      ur: 'شناختی کارڈ، ڈرائیونگ لائسنس، گاڑی کی رجسٹریشن اور سیکیورٹی کلیئرنس کی تفصیلات۔',
      ps: 'پیژندپاڼه، د چلولو جواز، د موټر ثبت او امنیتي تصدیق معلومات.',
    },
    content: {
      en: 'To ensure passenger safety in Swat, all prospective drivers must submit: (1) Original Pakistani CNIC, (2) Valid KPK Driving License, (3) Official Vehicle Registration Book, and (4) Background check verification. Our Mingora verification desk inspects all documents prior to profile approval.',
      ur: 'سوات میں مسافروں کی حفاظت کو یقینی بنانے کے لیے تمام ڈرائیوروں کو درج ذیل دستاویزات جمع کروانا ضروری ہیں: (1) اصل شناختی کارڈ، (2) خیبر پختونخوا کا ڈرائیونگ لائسنس، (3) گاڑی کی اصل رجسٹریشن، اور (4) پولیس کریکٹر سرٹیفکیٹ۔',
      ps: 'په سوات کې د مسافرینو د خوندیتوب لپاره، ټول چلوونکي باید دا اسناد وسپاري: (1) اصلي پیژندپاڼه، (2) د خیبر پختونخوا د چلولو جواز، (3) د موټر اصلي اسناد، او (4) د پولیسو کریکټر سند.',
    },
    lastUpdated: '2026-08-02',
    isPopular: true,
  },
  {
    id: 'food-delivery-thermal-bags',
    slug: 'food-delivery-thermal-bags',
    categoryId: 'food',
    title: {
      en: 'How do food delivery riders keep meals hot during transit?',
      ur: 'فوڈ ڈیلیوری رائیڈرز سفر کے دوران کھانے کو گرم کیسے رکھتے ہیں؟',
      ps: 'د خوړو رسولو رایډران د سفر پر مهال خواړه توده څنګه ساتي؟',
    },
    summary: {
      en: 'All SWAT RIDE food riders are equipped with specialized thermal-insulated food bags.',
      ur: 'تمام سوات رائیڈ فوڈ رائیڈرز کو خصوصی تھرمل انسلٹڈ فوڈ بیگز فراہم کیے جاتے ہیں۔',
      ps: 'ټول سوات رایډ فوڈ رایډران ځانګړي حرارتي کڅوړې لري.',
    },
    content: {
      en: 'SWAT RIDE provides insulated thermal delivery bags to every registered food rider in Mingora and Saidu Sharif. These bags maintain meal temperature and hygiene from the restaurant kitchen directly to your doorstep.',
      ur: 'سوات رائیڈ مینگورہ اور سیدو شریف کے ہر رجسٹرڈ فوڈ رائیڈر کو تھرمل انسلٹڈ بیگز فراہم کرتا ہے جو ریسٹورانٹ کے کچن سے لے کر آپ کے گھر تک کھانے کو گرم اور محفوظ رکھتے ہیں۔',
      ps: 'سوات رایډ د مینګورې او سیدو شریف هر ثبت شوي رایډر ته حرارتي کڅوړې ورکوي چې خواړه د رستورانت له پخلنځي څخه ستاسو کور ته توده او پاکه ساتي.',
    },
    lastUpdated: '2026-07-30',
  },
  {
    id: 'kalam-4x4-expedition-booking',
    slug: 'kalam-4x4-expedition-booking',
    categoryId: 'tourism',
    title: {
      en: 'Can I book a 4x4 Jeep for Kalam and Mahodand Lake via SWAT RIDE?',
      ur: 'کیا میں سوات رائیڈ کے ذریعے کالام اور مہوڈنڈ جھیل کے لیے 4x4 جیپ بک کر سکتا ہوں؟',
      ps: 'ایا زه د سوات رایډ له لارې د کالام او مهوډنډ جهیل لپاره 4x4 جیپ بک کولی شم؟',
    },
    summary: {
      en: 'Yes, explore our Tours section for rugged 4x4 vehicle bookings and local tour guides.',
      ur: 'جی ہاں، ہمارے ٹورز سیکشن سے 4x4 گاڑیوں اور مقامی گائیڈز کی بکنگ کریں۔',
      ps: 'هو، زموږ د سیاحت په برخه کې د 4x4 موټرو او محلي لارښودانو بکینګ وکړئ.',
    },
    content: {
      en: 'Yes. In the Tours & Tourism section of SWAT RIDE, you can book specialized 4x4 mountain Jeeps, Prados, or Surfs with experienced mountain drivers who are familiar with high-altitude tracks leading to Kalam, Ushu Forest, and Mahodand Lake.',
      ur: 'جی ہاں۔ سوات رائیڈ کے ٹورز اور سیاحت کے سیکشن میں آپ کالام، اوشو فارسٹ اور مہوڈنڈ جھیل کے پہاڑی راستوں کے ماہر ڈرائیوروں کے ساتھ 4x4 جیپ، پراڈو یا سرف باآسانی بک کر سکتے ہیں۔',
      ps: 'هو. د سوات رایډ د سیاحت په برخه کې تاسو د کالام، اوشو ځنګل او مهوډنډ جهیل لپاره د 4x4 جیپ، پراډو یا سرف بکینګ د مسلکي چلوونکو سره کولی شئ.',
    },
    lastUpdated: '2026-08-08',
    isPopular: true,
  },
];
