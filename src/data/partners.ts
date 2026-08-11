import { PartnerRole } from '@/types';

export const PARTNER_ROLES: PartnerRole[] = [
  {
    id: 'driver',
    slug: 'driver',
    title: {
      en: 'Become a Normal Ride Driver',
      ur: 'نارمل رائیڈ ڈرائیور بنیں',
      ps: 'د عادي سفر چلوونکی شئ',
    },
    subtitle: {
      en: 'Drive with Swat’s trusted mobility platform. Enjoy flexible hours, fair commissions, and transparent weekly withdrawals.',
      ur: 'سوات کے اپنے بااعتماد سفری پلیٹ فارم کے ساتھ گاڑی چلائیں۔ اپنے وقت کے مطابق کام کریں، مناسب کمیشن اور شفاف ہفتہ وار ادائیگی حاصل کریں۔',
      ps: 'د سوات د باور وړ پلیټ فارم سره موټر وچلوئ. د خپل وخت مطابق کار وکړئ، مناسب کمیشن او شفاف تادیات ترلاسه کړئ.',
    },
    category: 'driver',
    iconName: 'Car',
    benefits: [
      {
        title: { en: 'Flexible Working Hours', ur: 'کام کے اوقات کی مکمل آزادی', ps: 'د کار د وخت بشپړه آزادي' },
        description: { en: 'Go online when it suits you—morning, afternoon, or weekend shifts.', ur: 'اپنی سہولت کے مطابق آن لائن آئیں اور کام کریں۔', ps: 'د خپلې اسانتیا سره سم آنلاین شئ او کار وکړئ.' },
        icon: 'Clock',
      },
      {
        title: { en: 'Transparent Earnings & Withdrawals', ur: 'شفاف آمدنی اور ادائیگیاں', ps: 'شفاف عاید او تادیات' },
        description: { en: 'Track every trip fare in-app with clear commission breakdowns and prompt settlements.', ur: 'ہر رائیڈ کا کرایہ اور کمیشن ایپ میں شفاف انداز میں دیکھیں اور وقت پر ادائیگی حاصل کریں۔', ps: 'د هر سفر کرایه او کمیشن په ایپ کې وګورئ او پر وخت تادیه ترلاسه کړئ.' },
        icon: 'Wallet',
      },
      {
        title: { en: '24/7 SOS & Driver Safety', ur: '24/7 SOS اور ڈرائیور کی حفاظت', ps: '24/7 SOS او د چلوونکي خوندیتوب' },
        description: { en: 'Verified riders, GPS trip monitoring, and an emergency SOS button for driver security.', ur: 'تصدیق شدہ مسافر، لائیو GPS نگرانی، اور ڈرائیور کی حفاظت کے لیے SOS بٹن۔', ps: 'تایید شوي مسافر، د GPS څارنه، او د چلوونکي د خوندیتوب لپاره SOS تڼۍ.' },
        icon: 'ShieldCheck',
      },
    ],
    requirements: [
      { en: 'Valid Pakistani CNIC & Khyber Pakhtunkhwa Driving License', ur: 'اصل قومی شناختی کارڈ (CNIC) اور خیبر پختونخوا کا ڈرائیونگ لائسنس', ps: 'اصلي پېژندپاڼه (CNIC) او د خیبر پختونخوا د موټر چلولو جواز' },
      { en: 'Vehicle Registration Books & clear recent photographs of vehicle', ur: 'گاڑی کے اصل رجسٹریشن کاغذات اور گاڑی کی واضح تازہ تصاویر', ps: 'د موټر د ثبتولو اصلي اسناد او د موټر روښانه نوي عکسونه' },
      { en: 'Police Character Certificate / clean security background verification', ur: 'پولیس کریکٹر سرٹیفکیٹ اور سیکیورٹی کلیئرنس', ps: 'د پولیسو کریکټر سند او امنیتي تصدیق' },
      { en: 'Android smartphone with GPS & mobile internet connectivity', ur: 'اینڈرائیڈ اسمارٹ فون اور موبائل انٹرنیٹ کی سہولت', ps: 'انډرایډ ځیرک موبایل او د انټرنیټ اسانتیا' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Submit Online Application', ur: 'آن لائن درخواست جمع کروائیں', ps: 'آنلاین غوښتنلیک وسپارئ' }, detail: { en: 'Upload your CNIC, driving license, and vehicle registration photos in the app.', ur: 'ایپ میں اپنا شناختی کارڈ، لائسنس اور گاڑی کے کاغذات اپ لوڈ کریں۔', ps: 'په ایپ کې خپله پیژندپاڼه، جواز او د موټر اسناد اپلوډ کړئ.' } },
      { step: 2, title: { en: 'Admin Verification & Vehicle Inspection', ur: 'ایڈمن تصدیق اور گاڑی کا معائنہ', ps: 'د اډمین تصدیق او د موټر تفتیش' }, detail: { en: 'Our Mingora support office inspects documents and checks vehicle standards.', ur: 'ہمارا مینگورہ آفس دستاویزات اور گاڑی کے معیار کی تصدیق کرتا ہے۔', ps: 'زموږ د مینګورې دفتر اسناد او د موټر کیفیت تاییدوي.' } },
      { step: 3, title: { en: 'Go Online & Accept Rides', ur: 'آن لائن آئیں اور رائیڈز لیں', ps: 'آنلاین شئ او سفرونه واخلئ' }, detail: { en: 'Once approved, activate your driver profile and start accepting ride requests in Swat.', ur: 'تصدیق کے بعد اپنا پروفائل آن کریں اور سوات میں رائیڈز لینا شروع کریں۔', ps: 'له تایید وروسته خپل پروفایل چالان کړئ او په سوات کې سفرونه واخلئ.' } },
    ],
    earningsDisclaimer: {
      en: 'Disclaimer: Earnings vary based on hours driven, trip distance, demand, and season. SWAT RIDE does not guarantee fixed earnings.',
      ur: 'وضاحت: آمدنی کا انحصار کام کے گھنٹوں، سفر کے فاصلے اور سیزن کی ڈیمانڈ پر ہے۔ سوات رائیڈ کسی مقررہ آمدنی کی ضمانت نہیں دیتا۔',
      ps: 'وضاحت: عاید د کار په ساعتونو، واټن او د فصل په غوښتنې پورې اړه لري. سوات رایډ د کوم ثابت عاید تضمین نه کوي.',
    },
    applyUrl: '/download',
  },
  {
    id: 'restaurant-partner',
    slug: 'restaurant-partner',
    title: {
      en: 'Partner Your Restaurant with SWAT RIDE',
      ur: 'اپنے ریسٹورانٹ کو سوات رائیڈ کے ساتھ رجسٹر کریں',
      ps: 'خپل رستورانت د سوات رایډ سره ثبت کړئ',
    },
    subtitle: {
      en: 'Reach thousands of food lovers across Mingora, Saidu Sharif, and Swat valleys. Manage your menu, prices, and orders with full transparency.',
      ur: 'مینگورہ، سیدو شریف اور سوات بھر کے ہزاروں گاہکوں تک رسائی حاصل کریں۔ اپنے مینیو، نرخ اور آرڈرز کو باآسانی مینج کریں۔',
      ps: 'د مینګورې، سیدو شریف او ټول سوات په زرګونو پیرودونکو ته ورسیږئ. خپل مینیو، نرخونه او فرمایشونه په اسانۍ اداره کړئ.',
    },
    category: 'merchant',
    iconName: 'Store',
    benefits: [
      {
        title: { en: 'Expand Local Order Volume', ur: 'مقامی آرڈرز میں اضافہ', ps: 'په محلي فرمایشونو کې زیاتوالی' },
        description: { en: 'Connect your kitchen with hungry customers throughout Swat without building a separate delivery fleet.', ur: 'اپنی ڈیلیوری ٹیم بنائے بغیر سوات بھر کے گاہکوں تک اپنا کھانا پہنچائیں۔', ps: 'د خپل تحویلي ټیم پرته د ټول سوات پیرودونکو ته خپل خواړه ورسوئ.' },
        icon: 'TrendingUp',
      },
      {
        title: { en: 'Full Menu & Price Control', ur: 'مینیو اور قیمتوں کا مکمل کنٹرول', ps: 'د مینیو او نرخونو بشپړ کنټرول' },
        description: { en: 'Update item availability, seasonal specials, and opening hours instantly via partner dashboard.', ur: 'پارٹنر ڈیش بورڈ کے ذریعے اپنے کھانوں کی دستیابی اور اوقات کو فوری اپ ڈیٹ کریں۔', ps: 'د پارټنر ډشبورډ له لارې د خپلو خوړو شتون او وختونه سمدستي تازه کړئ.' },
        icon: 'Sliders',
      },
      {
        title: { en: 'Reliable Delivery & Settlement', ur: 'قابل اعتماد ڈیلیوری اور مالی ادائیگیاں', ps: 'د باور وړ تحویلي او مالي تادیات' },
        description: { en: 'Dedicated SWAT RIDE food riders pick up and deliver hot meals with timely financial settlements.', ur: 'سوات رائیڈ کے مخصوص رائیڈرز کھانا وقت پر پہنچاتے ہیں اور مالی ادائیگیاں شفاف ہوتی ہیں۔', ps: 'د سوات رایډ ځانګړي رایډران خواړه پر وخت رسوي او مالي تادیات شفاف وي.' },
        icon: 'CheckCircle2',
      },
    ],
    requirements: [
      { en: 'Registered food business / restaurant in Swat or Mingora', ur: 'سوات یا مینگورہ میں رجسٹرڈ فوڈ بزنس یا ریسٹورانٹ', ps: 'په سوات یا مینګوره کې ثبت شوی د خوړو سوداګري یا رستورانت' },
      { en: 'CNIC of business owner & valid bank/wallet details for settlement', ur: 'کاروبار کے مالک کا شناختی کارڈ اور ادائیگی کے لیے بینک/والٹ کی تفصیلات', ps: 'د سوداګرۍ مالک پیژندپاڼه او د تادیې لپاره د بانک/والټ معلومات' },
      { en: 'High-quality menu items with accurate descriptions & hygiene standards', ur: 'صفائی کے بہترین انتظام کے ساتھ کھانوں کی واضح فہرست اور تصاویر', ps: 'د پاکوالي د غوره مدیریت سره د خوړو روښانه لیست او عکسونه' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Register Online', ur: 'آن لائن رجسٹریشن کریں', ps: 'آنلاین ثبت نام وکړئ' }, detail: { en: 'Submit your restaurant profile, location, and owner contact details.', ur: 'اپنے ریسٹورانٹ کا نام، مقام، اور رابطہ نمبر درج کریں۔', ps: 'د خپل رستورانت نوم، ځای او د اړیکې شمیره دننه کړئ.' } },
      { step: 2, title: { en: 'Upload Menu & Photos', ur: 'مینیو اور تصاویر اپ لوڈ کریں', ps: 'مینیو او عکسونه اپلوډ کړئ' }, detail: { en: 'Add your best-selling dishes, prices, and high-resolution food images.', ur: 'اپنے بہترین کھانوں کی تصاویر اور قیمتیں درج کریں۔', ps: 'د خپلو غوره خوړو عکسونه او نرخونه دننه کړئ.' } },
      { step: 3, title: { en: 'Go Live for Orders', ur: 'آرڈرز کے لیے لائیو آئیں', ps: 'د فرمایشونو لپاره ژوندی شئ' }, detail: { en: 'Start receiving and preparing orders from SWAT RIDE customers.', ur: 'سوات رائیڈ کے گاہکوں سے آرڈرز وصول کرنا اور تیار کرنا شروع کریں۔', ps: 'د سوات رایډ پیرودونکو څخه فرمایشونه ترلاسه کول پیل کړئ.' } },
    ],
    earningsDisclaimer: {
      en: 'Disclaimer: Sales volume depends on restaurant quality, pricing, customer reviews, and local demand.',
      ur: 'وضاحت: آرڈرز کا انحصار کھانے کے معیار، مناسب نرخ، اور گاہکوں کی پسند پر ہے۔',
      ps: 'وضاحت: د فرمایشونو کچه د خوړو په کیفیت، مناسبو نرخونو او د پیرودونکو په خوښې پورې اړه لري.',
    },
    applyUrl: '/download',
  },
  {
    id: 'food-rider',
    slug: 'food-rider',
    title: {
      en: 'Become a Food Delivery Rider',
      ur: 'فوڈ ڈیلیوری رائیڈر بنیں',
      ps: 'د خوړو رسولو رایډر شئ',
    },
    subtitle: {
      en: 'Deliver hot meals across Mingora and Swat valleys. Earn competitive fees on every order with flexible schedules.',
      ur: 'مینگورہ اور سوات میں گرم کھانا ڈیلیور کریں۔ اپنے وقت کے مطابق کام کریں اور ہر آرڈر پر مناسب معاوضہ کمائیں۔',
      ps: 'په مینګوره او سوات کې خواړه تحویل کړئ. د خپل وخت سره سم کار وکړئ او په هر فرمایش مناسب عاید ترلاسه کړئ.',
    },
    category: 'driver',
    iconName: 'Bike',
    benefits: [
      {
        title: { en: 'Short-Distance Deliveries', ur: 'کم فاصلے کی ڈیلیوریز', ps: 'د کم واټن تحویلي' },
        description: { en: 'Most food orders are localized within commercial zones in Mingora and Saidu Sharif.', ur: 'زیادہ تر آرڈرز مینگورہ اور سیدو شریف کے قریبی علاقوں میں ہوتے ہیں۔', ps: 'ډیری فرمایشونه د مینګورې او سیدو شریف په نږدې سیمو کې وي.' },
        icon: 'MapPin',
      },
      {
        title: { en: 'Weekly Payouts & Commission Tracking', ur: 'ہفتہ وار ادائیگی اور کمیشن ٹریکنگ', ps: 'اوونیزې تادیې او د کمیشن څارنه' },
        description: { en: 'See exact earnings per delivery and withdraw your balance weekly.', ur: 'ہر ڈیلیوری کی آمدنی دیکھیں اور ہفتہ وار اپنی رقم وصول کریں۔', ps: 'د هر تحویلي عاید وګورئ او اوونیز خپلې پیسې ترلاسه کړئ.' },
        icon: 'DollarSign',
      },
      {
        title: { en: 'Insulated Gear & Safety Support', ur: 'تھرمل بیگ اور حفاظتی سپورٹ', ps: 'حرارتي کڅوړه او د خوندیتوب ملاتړ' },
        description: { en: 'We provide specialized food bags and continuous SOS safety support while you ride.', ur: 'ہم خصوصی فوڈ بیگز اور سفر کے دوران SOS حفاظتی مدد فراہم کرتے ہیں۔', ps: 'موږ ځانګړي فوډ بیګونه او د سفر پر مهال د SOS امنیتي مرسته چمتو کوو.' },
        icon: 'Shield',
      },
    ],
    requirements: [
      { en: 'Valid Pakistani CNIC & motorcycle driving license', ur: 'اصل شناختی کارڈ اور موٹرسائیکل کا ڈرائیونگ لائسنس', ps: 'اصلي پیژندپاڼه او د موټر سایکل د چلولو جواز' },
      { en: 'Registered motorcycle in good working condition', ur: 'اچھی حالت میں رجسٹرڈ موٹرسائیکل', ps: 'په ښه حالت کې ثبت شوی موټرسایکل' },
      { en: 'Android smartphone with active internet and GPS', ur: 'اینڈرائیڈ اسمارٹ فون اور انٹرنیٹ کی سہولت', ps: 'انډرایډ ځیرک موبایل او د انټرنیټ اسانتیا' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Apply Online', ur: 'آن لائن درخواست دیں', ps: 'آنلاین غوښتنلیک وسپارئ' }, detail: { en: 'Fill out your rider registration form in the SWAT RIDE app.', ur: 'سوات رائیڈ ایپ میں رائیڈر کا فارم پُر کریں۔', ps: 'په سوات رایډ ایپ کې د رایډر فارم ډک کړئ.' } },
      { step: 2, title: { en: 'Document & Motorcycle Check', ur: 'دستاویزات اور موٹرسائیکل کا معائنہ', ps: 'د اسنادو او موټرسایکل تفتیش' }, detail: { en: 'Verify your CNIC and license at our local Mingora hub.', ur: 'ہمارے مینگورہ آفس میں اپنے کاغذات کی تصدیق کروائیں۔', ps: 'زموږ د مینګورې دفتر کې خپل اسناد تایید کړئ.' } },
      { step: 3, title: { en: 'Start Delivering', ur: 'ڈیلیوری شروع کریں', ps: 'تحویلي پیل کړئ' }, detail: { en: 'Receive thermal bag, activate rider status, and deliver food orders.', ur: 'تھرمل بیگ وصول کریں، ایپ آن کریں اور کھانے پہنچانا شروع کریں۔', ps: 'حرارتي کڅوړه ترلاسه کړئ، ایپ چالان کړئ او خواړه رسول پیل کړئ.' } },
    ],
    earningsDisclaimer: {
      en: 'Disclaimer: Earnings depend on completed delivery volume, online hours, and weather/seasonal demand.',
      ur: 'وضاحت: آمدنی کا انحصار مکمل کی گئی ڈیلیوریز اور کام کے گھنٹوں پر ہے۔',
      ps: 'وضاحت: عاید د بشپړ شویو تحویلیو او د کار په ساعتونو پورې اړه لري.',
    },
    applyUrl: '/download',
  },
  {
    id: 'cargo-driver',
    slug: 'cargo-driver',
    title: {
      en: 'Become a Cargo & Logistics Driver',
      ur: 'کارگو اور لاجسٹکس ڈرائیور بنیں',
      ps: 'د کارګو او لوژستیک چلوونکی شئ',
    },
    subtitle: {
      en: 'Own a Suzuki pickup, loader, van, or heavy commercial truck in Swat? Accept dependable goods transport jobs with fair pricing.',
      ur: 'کیا آپ کے پاس سوزوکی پک اپ، لوڈر، وین یا بڑا ٹرک ہے؟ سوات بھر میں سامان کی ترسیل کے آرڈرز لیں اور بہترین منافع کمائیں۔',
      ps: 'ایا تاسو د سوزوکي پک اپ، لوډر، وین یا لوی ټرک لرئ؟ په ټول سوات کې د توکو لیږد فرمایشونه واخلئ او ښه ګټه ترلاسه کړئ.',
    },
    category: 'driver',
    iconName: 'Truck',
    benefits: [
      {
        title: { en: 'Higher Ticket Fares', ur: 'زیادہ کرائے والے آرڈرز', ps: 'د لوړې کرایې فرمایشونه' },
        description: { en: 'Commercial cargo and heavy freight trips generate higher revenue per job.', ur: 'تجارتی کارگو اور سامان کی ترسیل کے آرڈرز پر زیادہ معاوضہ ملتا ہے۔', ps: 'د سوداګریز کارګو او د توکو لیږد په فرمایشونو ډیر عاید ترلاسه کیږي.' },
        icon: 'TrendingUp',
      },
      {
        title: { en: 'Tier-Matched Job Assignments', ur: 'گاڑی کی کیٹگری کے مطابق آرڈرز', ps: 'د موټر د کټګورۍ مطابق فرمایشونه' },
        description: { en: 'Receive bookings matched precisely to your Express, Economy, or Heavy cargo vehicle capacity.', ur: 'اپنی گاڑی کی گنجائش کے مطابق ایکسپریس یا ہیوی کارگو آرڈرز حاصل کریں۔', ps: 'د خپل موټر د وړتیا مطابق ایکسپریس یا درانه کارګو فرمایشونه ترلاسه کړئ.' },
        icon: 'CheckCircle',
      },
      {
        title: { en: 'Secure Trip Verifications', ur: 'محفوظ تصدیقی نظام', ps: 'خوندي تصدیقي سیسټم' },
        description: { en: 'Digital proof of pickup and OTP drop-off protect you against false claims.', ur: 'سامان اٹھانے اور ڈیلیور کرنے کے ڈیجیٹل ثبوت آپ کو ہر قسم کے تنازعے سے محفوظ رکھتے ہیں۔', ps: 'د توکو پورته کولو او رسولو ډیجیټل ثبوت تاسو د شخړو څخه ساتي.' },
        icon: 'ShieldAlert',
      },
    ],
    requirements: [
      { en: 'Valid Pakistani CNIC & commercial/appropriate driving license', ur: 'اصل شناختی کارڈ اور کمرشل ڈرائیونگ لائسنس', ps: 'اصلي پیژندپاڼه او سوداګریز د چلولو جواز' },
      { en: 'Registered cargo vehicle (pickup, loader, van, truck) in sound condition', ur: 'رجسٹرڈ کارگو گاڑی (پک اپ، لوڈر، ٹرک) بہترین مکینیکل حالت میں', ps: 'ثبت شوی کارګو موټر (پک اپ، لوډر، ټرک) په ښه حالت کې' },
      { en: 'Clear police background security check', ur: 'پولیس سیکیورٹی کلیئرنس اور کریکٹر سرٹیفکیٹ', ps: 'د پولیسو امنیتي تصدیق او کریکټر سند' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Register Cargo Vehicle', ur: 'کارگو گاڑی رجسٹر کریں', ps: 'کارګو موټر ثبت کړئ' }, detail: { en: 'Enter your vehicle dimensions, load capacity, and registration photos.', ur: 'گاڑی کا سائز، وزن اٹھانے کی گنجائش، اور کاغذات اپ لوڈ کریں۔', ps: 'د موټر کچه، د وزن وړتیا او اسناد اپلوډ کړئ.' } },
      { step: 2, title: { en: 'Inspection & Tier Approval', ur: 'معائنہ اور کیٹگری کی منظوری', ps: 'تفتیش او د کټګورۍ تایید' }, detail: { en: 'We verify vehicle safety standards and assign your Express or Heavy tier.', ur: 'ہم گاڑی کا معائنہ کر کے اسے ایکسپریس یا ہیوی کارگو کیٹگری میں شامل کرتے ہیں۔', ps: 'موږ د موټر تفتیش کوو او هغه په ایکسپریس یا درانه کارګو کټګورۍ کې شاملوو.' } },
      { step: 3, title: { en: 'Accept Goods Transport Jobs', ur: 'کارگو آرڈرز لینا شروع کریں', ps: 'د کارګو فرمایشونه پیل کړئ' }, detail: { en: 'Activate your driver profile to accept commercial and residential logistics trips.', ur: 'پروفائل آن کریں اور سوات بھر میں کارگو اور لاجسٹکس کے آرڈرز لیں۔', ps: 'پروفایل چالان کړئ او په ټول سوات کې د کارګو فرمایشونه واخلئ.' } },
    ],
    earningsDisclaimer: {
      en: 'Disclaimer: Earnings depend on commercial demand, vehicle capacity, load type, and distance driven.',
      ur: 'وضاحت: آمدنی کا انحصار گاڑی کی گنجائش، سامان کی قسم، اور فاصلے پر ہے۔',
      ps: 'وضاحت: عاید د موټر وړتیا، د توکو ډول او واټن پورې اړه لري.',
    },
    applyUrl: '/download',
  },
  {
    id: 'parents',
    slug: 'parents',
    title: {
      en: 'Parent & Guardian Student Ride Portal',
      ur: 'والدین اور سرپرست - اسٹوڈنٹ رائیڈ پورٹل',
      ps: 'د میندو او پلرونو او سرپرستانو پورټل',
    },
    subtitle: {
      en: 'Your child’s safety is our supreme obligation. Setup monthly transport, authorize guardians, and receive real-time attendance notifications.',
      ur: 'آپ کے بچے کی حفاظت ہماری اولین ذمہ داری ہے۔ ماہانہ اسکول ٹرانسپورٹ، تصدیق شدہ سرپرست، اور لائیو حاضری الرٹس کا محفوظ نظام۔',
      ps: 'ستاسو د ماشوم خوندیتوب زموږ لومړنی مسؤلیت دی. میاشتنی د ښوونځي ټرانسپورټ، تایید شوي سرپرستان او ژوندۍ خبرتیاوې.',
    },
    category: 'guardian',
    iconName: 'Shield',
    benefits: [
      {
        title: { en: 'Fixed Vetted Student Driver', ur: 'مستقل اور تصدیق شدہ ڈرائیور', ps: 'ثابت او تایید شوی چلوونکی' },
        description: { en: 'Your child travels with the same background-checked driver every day for consistency.', ur: 'آپ کا بچہ روزانہ ایک ہی تصدیق شدہ اور بااعتماد ڈرائیور کے ساتھ سفر کرتا ہے۔', ps: 'ستاسو ماشوم هره ورځ د یو ثابت او تایید شوي چلوونکي سره سفر کوي.' },
        icon: 'UserCheck',
      },
      {
        title: { en: 'Authorized Guardian Handover', ur: 'صرف مجاز سرپرست کے حوالے کرنا', ps: 'یوازې مجاز سرپرست ته تحویلول' },
        description: { en: 'Drivers only release students to authorized guardians registered in the app with photo ID.', ur: 'ڈرائیور بچے کو صرف ایپ میں رجسٹرڈ تصدیق شدہ سرپرست کے حوالے کرتا ہے۔', ps: 'چلوونکی ماشوم یوازې په ایپ کې ثبت شوي تایید شوي سرپرست ته تحویلوي.' },
        icon: 'Lock',
      },
      {
        title: { en: 'Live Transit & Attendance Alerts', ur: 'لائیو حاضری اور سفر کے الرٹس', ps: 'ژوندۍ حاضري او د سفر خبرتیاوې' },
        description: { en: 'Get instant notifications when your child enters the car, reaches school, and returns home.', ur: 'بچے کے گاڑی میں بیٹھنے، اسکول پہنچنے اور گھر واپسی کے لائیو الرٹس اپنے فون پر حاصل کریں۔', ps: 'د ماشوم په موټر کې کیناستو، ښوونځي ته رسیدو او کور ته راستنیدو ژوندۍ خبرتیاوې ترلاسه کړئ.' },
        icon: 'Bell',
      },
    ],
    requirements: [
      { en: 'Active SWAT RIDE parent account with verified contact details', ur: 'سوات رائیڈ پر تصدیق شدہ رابطہ نمبر کے ساتھ والدین کا اکاؤنٹ', ps: 'په سوات رایډ کې د تایید شوې اړیکې شمیرې سره د والدین حساب' },
      { en: 'Photo and contact ID of all authorized drop-off guardians', ur: 'بچے کو وصول کرنے والے تمام مجاز سرپرستوں کی تصاویر اور تفصیلات', ps: 'ماشوم ترلاسه کونکو ټولو مجاز سرپرستانو عکسونه او معلومات' },
      { en: 'Accurate school address and daily opening/closing timetable', ur: 'اسکول کا درست پتہ اور روزانہ کے اوقات کار کی تفصیل', ps: 'د ښوونځي دقیق پته او د ورځني کاري وختونو معلومات' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Add Child Profile', ur: 'بچے کا پروفائل بنائیں', ps: 'د ماشوم پروفایل جوړ کړئ' }, detail: { en: 'Enter your child’s name, school name, and daily schedule.', ur: 'بچے کا نام، اسکول کا نام اور روزانہ کے اوقات درج کریں۔', ps: 'د ماشوم نوم، د ښوونځي نوم او ورځني وختونه دننه کړئ.' } },
      { step: 2, title: { en: 'Register Authorized Guardians', ur: 'مجاز سرپرست رجسٹر کریں', ps: 'مجاز سرپرستان ثبت کړئ' }, detail: { en: 'Upload photos of grandparents, siblings, or parents authorized to receive the child.', ur: 'بچے کو وصول کرنے کے مجاز افراد کی تصاویر اور معلومات درج کریں۔', ps: 'د ماشوم ترلاسه کولو مجاز کسانو عکسونه او معلومات دننه کړئ.' } },
      { step: 3, title: { en: 'Activate Monthly Package', ur: 'ماہانہ پیکیج آن کریں', ps: 'میاشتنۍ کڅوړه چالان کړئ' }, detail: { en: 'Match with an approved student driver and monitor daily transit.', ur: 'تصدیق شدہ ڈرائیور منتخب کریں اور روزانہ محفوظ سفر کی نگرانی کریں۔', ps: 'تایید شوی چلوونکی وټاکئ او هره ورځ د خوندي سفر څارنه وکړئ.' } },
    ],
    earningsDisclaimer: {
      en: 'Note: Student Ride subscriptions are billed monthly with transparent pricing and no hidden safety surcharges.',
      ur: 'نوٹ: اسٹوڈنٹ رائیڈ کی فیس ماہانہ بنیاد پر شفاف انداز میں لی جاتی ہے۔',
      ps: 'یادونه: د زده کونکو د سفر فیس د میاشتې په اساس په شفاف ډول اخیستل کیږي.',
    },
    applyUrl: '/download',
  },
  {
    id: 'student-driver',
    slug: 'student-driver',
    title: {
      en: 'Become an Authorized Student Ride Driver',
      ur: 'تصدیق شدہ اسٹوڈنٹ رائیڈ ڈرائیور بنیں',
      ps: 'د زده کونکو د سفر تایید شوی چلوونکی شئ',
    },
    subtitle: {
      en: 'Join Swat’s most respected school transport network. Earn steady, predictable monthly income with fixed daily school routes.',
      ur: 'سوات کے معتبر ترین اسکول ٹرانسپورٹ نیٹ ورک کا حصہ بنیں۔ روزانہ کے مستقل اسکول روٹس کے ساتھ پائیدار ماہانہ آمدنی حاصل کریں۔',
      ps: 'د سوات ترټولو معتبر ښوونځي ټرانسپورټ شبکې سره یوځای شئ. د ورځني ثابت روټونو سره ثابته میاشتنۍ عاید ترلاسه کړئ.',
    },
    category: 'driver',
    iconName: 'Award',
    benefits: [
      {
        title: { en: 'Predictable Monthly Revenue', ur: 'مستقل ماہانہ آمدنی', ps: 'ثابته میاشتنۍ عاید' },
        description: { en: 'School transport packages offer steady recurring monthly earnings with dedicated routes.', ur: 'اسکول ٹرانسپورٹ پیکیجز آپ کو مستقل اور پائیدار ماہانہ آمدنی فراہم کرتے ہیں۔', ps: 'د ښوونځي ټرانسپورټ کڅوړې تاسو ته ثابته او دوامداره میاشتنۍ عاید درکوي.' },
        icon: 'Calendar',
      },
      {
        title: { en: 'Fixed Daily Timings', ur: 'مقررہ اور مستقل اوقات', ps: 'ټاکلي او ثابت وختونه' },
        description: { en: 'Work structured morning pickup and afternoon return shifts, leaving your evenings free.', ur: 'صبح اسکول جانے اور دوپہر واپسی کے مقررہ اوقات میں کام کریں، شام کا وقت آپ کا اپنا۔', ps: 'سهار ښوونځي ته د تګ او غرمې د راستنیدو په ټاکلو وختونو کې کار وکړئ.' },
        icon: 'Clock',
      },
      {
        title: { en: 'High Community Respect & Trust', ur: 'معاشرے میں عزت اور اعتماد', ps: 'په ټولنه کې درناوی او باور' },
        description: { en: 'Serve local Swat families with pride as an officially verified student transport provider.', ur: 'سوات کے خاندانوں کو ایک بااعتماد اور تصدیق شدہ اسکول ڈرائیور کے طور پر سروس فراہم کریں۔', ps: 'د سوات کورنیو ته د باور وړ او تایید شوي چلوونکي په توګه خدمت وکړئ.' },
        icon: 'Heart',
      },
    ],
    requirements: [
      { en: 'Clean Pakistani CNIC & valid driving license with 3+ years experience', ur: 'اصل شناختی کارڈ، ڈرائیونگ لائسنس اور کم از کم 3 سال کا تجربہ', ps: 'اصلي پیژندپاڼه، د چلولو جواز او لږ تر لږه 3 کاله تجربه' },
      { en: 'Immaculate security check including local police & community character verification', ur: 'پولیس اور مقامی علاقہ معززین کی طرف سے کریکٹر سرٹیفکیٹ اور سیکیورٹی کلیئرنس', ps: 'د پولیسو او محلي معززینو لخوا د کریکټر سند او امنیتي تصدیق' },
      { en: 'Safe, well-maintained 4-door vehicle or certified school van', ur: 'بہترین حالت میں 4 دروازوں والی گاڑی یا تصدیق شدہ اسکول وین', ps: 'په غوره حالت کې 4 دروازې لرونکی موټر یا تایید شوی د ښوونځي وین' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Submit Specialized Application', ur: 'خصوصی درخواست جمع کروائیں', ps: 'ځانګړی غوښتنلیک وسپارئ' }, detail: { en: 'Apply for the Student Driver badge in-app and provide experience references.', ur: 'ایپ میں اسٹوڈنٹ ڈرائیور بیج کے لیے درخواست دیں اور اپنے تجربے کی تفصیل درج کریں۔', ps: 'په ایپ کې د زده کونکي چلوونکي بیج لپاره غوښتنلیک وسپارئ.' } },
      { step: 2, title: { en: 'In-Person Security & Vehicle Audit', ur: 'ذاتی معائنہ اور سیکیورٹی انٹرویو', ps: 'شخصي تفتیش او امنیتي مرکه' }, detail: { en: 'Our safety team conducts an in-depth interview and vehicle safety inspection.', ur: 'ہماری سیفٹی ٹیم انٹرویو اور گاڑی کی مکمل حفاظتی جانچ کرتی ہے۔', ps: 'زموږ امنیتي ټیم مرکه او د موټر بشپړ امنیتي تفتیش کوي.' } },
      { step: 3, title: { en: 'Route Assignment', ur: 'روٹ کا تعین', ps: 'د روټ ټاکنه' }, detail: { en: 'Get assigned to local Swat families and commence monthly school routes.', ur: 'سوات کے خاندانوں کے ساتھ روٹ حاصل کریں اور ماہانہ اسکول سروس شروع کریں۔', ps: 'د سوات کورنیو سره روټ ترلاسه کړئ او میاشتنی ښوونځي خدمت پیل کړئ.' } },
    ],
    earningsDisclaimer: {
      en: 'Disclaimer: Monthly earnings depend on the number of students assigned and route length.',
      ur: 'وضاحت: ماہانہ آمدنی کا انحصار روٹ پر موجود طلباء کی تعداد اور فاصلے پر ہے۔',
      ps: 'وضاحت: میاشتنی عاید په روټ کې د زده کونکو شمیر او واټن پورې اړه لري.',
    },
    applyUrl: '/download',
  },
  {
    id: 'hotel-partner',
    slug: 'hotel-partner',
    title: {
      en: 'Partner Your Hotel or Resort with SWAT RIDE',
      ur: 'اپنے ہوٹل یا ریزورٹ کو سوات رائیڈ کے ساتھ رجسٹر کریں',
      ps: 'خپل هوټل یا ریزورټ د سوات رایډ سره ثبت کړئ',
    },
    subtitle: {
      en: 'Showcase your rooms in Mingora, Malam Jabba, Bahrain, and Kalam to travelers worldwide. Receive verified digital bookings and direct guest transfers.',
      ur: 'مینگورہ، مالم جبہ، بحرین اور کالام میں اپنے ہوٹل کے کمرے سیاحوں کے سامنے پیش کریں۔ تصدیق شدہ بکنگز اور مہمانوں کی ڈائریکٹ ٹرانسپورٹ حاصل کریں۔',
      ps: 'په مینګوره، مالم جبه، بحرین او کالام کې د خپل هوټل خونې سیلانیانو ته وښایاست. تایید شوي بکینګونه او د میلمنو مستقیم ټرانسپورټ ترلاسه کړئ.',
    },
    category: 'merchant',
    iconName: 'Hotel',
    benefits: [
      {
        title: { en: 'Direct Tourism Exposure', ur: 'سیاحوں تک براہ راست رسائی', ps: 'سیلانیانو ته مستقیم لاسرسی' },
        description: { en: 'Your hotel is featured to every traveler booking rides and tours in Swat Valley.', ur: 'آپ کا ہوٹل سوات آنے والے تمام سیاحوں کو ایپ میں نمایاں طور پر دکھایا جاتا ہے۔', ps: 'ستاسو هوټل سوات ته راتلونکو ټولو سیلانیانو ته په ایپ کې ښودل کیږي.' },
        icon: 'Globe',
      },
      {
        title: { en: 'Integrated Transport to Stay', ur: 'رہائش اور گاڑی کی مشترکہ بکنگ', ps: 'د پاتې کیدو او موټر ګډ بکینګ' },
        description: { en: 'Guests can book a normal ride or 4x4 mountain transit directly to your hotel doorstep.', ur: 'مہمان آپ کے ہوٹل تک پہنچنے کے لیے براہ راست سوات رائیڈ گاڑی بک کر سکتے ہیں۔', ps: 'میلمانه ستاسو هوټل ته د رسیدو لپاره مستقیم سوات رایډ موټر بک کولی شي.' },
        icon: 'Navigation',
      },
      {
        title: { en: 'Transparent Financial Reports', ur: 'شفاف مالیاتی رپورٹس', ps: 'شفاف مالي راپورونه' },
        description: { en: 'Track room occupancy, bookings, and commission settlements with weekly financial reporting.', ur: 'کمروں کی بکنگ، آمدنی، اور کمیشن کی تفصیلات شفاف مالیاتی رپورٹ میں دیکھیں۔', ps: 'د خونو بکینګ، عاید او د کمیشن تفصیلات په شفاف مالي راپور کې وګورئ.' },
        icon: 'BarChart3',
      },
    ],
    requirements: [
      { en: 'Registered hospitality business in Swat Valley (hotel, guest house, resort)', ur: 'سوات میں رجسٹرڈ ہوٹل، گیسٹ ہاؤس یا ریزورٹ کا قانونی ثبوت', ps: 'په سوات کې د ثبت شوي هوټل، میلمستون یا ریزورټ قانوني ثبوت' },
      { en: 'True, verified photographs of rooms, bathrooms, and amenities', ur: 'کمروں، باتھ رومز اور سہولیات کی حقیقی اور تصدیق شدہ تصاویر', ps: 'د خونو، تشنابونو او اسانتیاو رښتیني او تایید شوي عکسونه' },
      { en: 'Clear published cancellation and check-in/check-out policies', ur: 'چیک ان، چیک آؤٹ اور بکنگ کینسل کرنے کی واضح پالیسی', ps: 'د چیک ان، چیک آوټ او د بکینګ لغوه کولو روښانه پالیسي' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Submit Hotel Property Profile', ur: 'ہوٹل کا پروفائل جمع کروائیں', ps: 'د هوټل پروفایل وسپارئ' }, detail: { en: 'Enter property address, room categories, and pricing details.', ur: 'ہوٹل کا پتہ، کمروں کی اقسام، اور قیمتوں کی تفصیل درج کریں۔', ps: 'د هوټل پته، د خونو ډولونه او د نرخونو تفصیل دننه کړئ.' } },
      { step: 2, title: { en: 'Verification & Quality Review', ur: 'تصدیق اور معیار کا جائزہ', ps: 'تصدیق او د کیفیت څیړنه' }, detail: { en: 'Our Swat hospitality team verifies property amenities and standards.', ur: 'ہماری سوات ہاسپٹلٹی ٹیم سہولیات اور معیار کی تصدیق کرتی ہے۔', ps: 'زموږ د سوات هاسپټلټي ټیم د اسانتیاو او کیفیت تصدیق کوي.' } },
      { step: 3, title: { en: 'Receive Room Bookings', ur: 'کمروں کی بکنگز حاصل کریں', ps: 'د خونو بکینګونه ترلاسه کړئ' }, detail: { en: 'Go live on the SWAT RIDE Hotels directory and welcome visitors.', ur: 'سوات رائیڈ ہوٹلز کی فہرست میں شامل ہوں اور سیاحوں کا استقبال کریں۔', ps: 'د سوات رایډ هوټلونو په لیست کې شامل شئ او د سیلانیانو هرکلی وکړئ.' } },
    ],
    earningsDisclaimer: {
      en: 'Disclaimer: Room bookings depend on seasonal tourism demand, property reviews, and competitive pricing.',
      ur: 'وضاحت: بکنگز کا انحصار سیاحتی سیزن، ہوٹل کے معیار اور مناسب نرخوں پر ہے۔',
      ps: 'وضاحت: بکینګونه د سیاحتي فصل، د هوټل په کیفیت او مناسبو نرخونو پورې اړه لري.',
    },
    applyUrl: '/download',
  },
  {
    id: 'tourism-driver',
    slug: 'tourism-driver',
    title: {
      en: 'Become a Tourism & Expedition Driver',
      ur: 'ٹورزم اور سوات مہم جوئی کے ڈرائیور بنیں',
      ps: 'د سیاحت او د سوات چکرونو چلوونکی شئ',
    },
    subtitle: {
      en: 'Drive 4x4 vehicles, Prado, Surf, Jeep, or comfortable tourist vans. Take visitors to Kalam, Ushu Forest, and Mahodand Lake safely.',
      ur: 'کیا آپ کے پاس 4x4 جیپ، پراڈو، سرف یا ٹورسٹ وین ہے؟ سیاحوں کو کالام، اوشو اور مہوڈنڈ جھیل کی سیر کروائیں اور بہترین آمدنی حاصل کریں۔',
      ps: 'ایا تاسو 4x4 جیپ، پراډو، سرف یا د سیاحت وین لرئ؟ سیلانیان کالام، اوشو او مهوډنډ جهیل ته بوزئ او ښه عاید ترلاسه کړئ.',
    },
    category: 'driver',
    iconName: 'Mountain',
    benefits: [
      {
        title: { en: 'Premium Expedition Rates', ur: 'پریمیئم سیاحتی کرائے', ps: 'د سیاحت غوره کرایې' },
        description: { en: 'Mountain tourism trips and full-day Kalam itineraries yield higher daily earnings.', ur: 'پہاڑی علاقوں اور کالام کے مکمل دن کے ٹورز پر بہترین یومیہ آمدنی ملتی ہے۔', ps: 'په غره ییزو سیمو او د کالام د بشپړې ورځې په چکرونو غوره ورځنی عاید ترلاسه کیږي.' },
        icon: 'TrendingUp',
      },
      {
        title: { en: 'Specialized 4x4 Fleet Recognition', ur: '4x4 اور پہاڑی گاڑیوں کی خصوصی پہچان', ps: 'د 4x4 او غره ییزو موټرو ځانګړی پیژندنه' },
        description: { en: 'Your 4x4 vehicle is showcased specifically for high-altitude scenic trails.', ur: 'آپ کی 4x4 گاڑی کو پہاڑی مقامات کے سفر کے لیے خصوصی ترجیح دی جاتی ہے۔', ps: 'ستاسو 4x4 موټر ته د غره ییزو ځایونو د سفر لپاره ځانګړی لومړیتوب ورکول کیږي.' },
        icon: 'Award',
      },
      {
        title: { en: 'Safety & Mountain Support', ur: 'پہاڑی راستوں پر حفاظتی سپورٹ', ps: 'په غره ییزو لارو کې امنیتي ملاتړ' },
        description: { en: 'We maintain safety protocols and SOS tracking across challenging mountain routes.', ur: 'ہم دشوار گزار پہاڑی راستوں پر بھی حفاظتی اصول اور SOS نگرانی قائم رکھتے ہیں۔', ps: 'موږ په ستونزو ډکو غره ییزو لارو کې هم امنیتي اصول او د SOS څارنه ساتو.' },
        icon: 'ShieldCheck',
      },
    ],
    requirements: [
      { en: 'Valid Pakistani CNIC & driving license with proven mountain driving experience', ur: 'اصل شناختی کارڈ اور پہاڑی راستوں پر ڈرائیونگ کے تجربے کا ثبوت', ps: 'اصلي پیژندپاڼه او په غره ییزو لارو د موټر چلولو د تجربې ثبوت' },
      { en: '4x4 vehicle (Jeep, Prado, Surf) or well-maintained tourist van/car', ur: '4x4 گاڑی (جیپ، پراڈو، سرف) یا بہترین حالت میں سیاحتی وین/کار', ps: '4x4 موټر (جیپ، پراډو، سرف) یا په ښه حالت کې د سیاحت وین/کار' },
      { en: 'Sound knowledge of Swat valley routes, Kalam, Bahrain & Malam Jabba', ur: 'سوات کے راستوں، کالام، بحرین اور مالم جبہ سے مکمل واقفیت', ps: 'د سوات له لارو، کالام، بحرین او مالم جبه سره بشپړتیا' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Register Vehicle & Experience', ur: 'گاڑی اور تجربہ رجسٹر کریں', ps: 'موټر او تجربه ثبت کړئ' }, detail: { en: 'Enter your 4x4 vehicle specifications and mountain driving history.', ur: 'اپنی 4x4 گاڑی کی تفصیلات اور پہاڑی ڈرائیونگ کا تجربہ درج کریں۔', ps: 'د خپل 4x4 موټر تفصیلات او د غره ییز موټر چلولو تجربه دننه کړئ.' } },
      { step: 2, title: { en: 'Mountain Readiness Inspection', ur: 'پہاڑی راستوں کی مناسبت سے گاڑی کا معائنہ', ps: 'د غره ییزو لارو لپاره د موټر تفتیش' }, detail: { en: 'Our technical team inspects brakes, tires, and 4x4 drivetrain safety.', ur: 'ہماری ٹیکنیکل ٹیم بریک، ٹائر اور 4x4 سسٹم کی جانچ کرتی ہے۔', ps: 'زموږ تخنیکي ټیم بریک، ټایرونه او د 4x4 سیسټم تفتیش کوي.' } },
      { step: 3, title: { en: 'Accept Tourism Expeditions', ur: 'سیاحتی ٹورز کے آرڈرز لیں', ps: 'د سیاحتي چکرونو فرمایشونه واخلئ' }, detail: { en: 'Start accepting single-day and multi-day tourism bookings across Swat.', ur: 'سوات بھر میں ایک دن یا کئی دنوں کے سیاحتی ٹورز لینا شروع کریں۔', ps: 'په ټول سوات کې د یوې ورځې یا څو ورځو سیاحتي چکرونه پیل کړئ.' } },
    ],
    earningsDisclaimer: {
      en: 'Disclaimer: Earnings depend on tourism peak seasons, vehicle capability, and tour duration.',
      ur: 'وضاحت: آمدنی کا انحصار سیاحتی سیزن، گاڑی کی گنجائش اور ٹور کے دنوں پر ہے۔',
      ps: 'وضاحت: عاید د سیاحتي فصل، د موټر وړتیا او د سفر په ورځو پورې اړه لري.',
    },
    applyUrl: '/download',
  },
  {
    id: 'tour-guide',
    slug: 'tour-guide',
    title: {
      en: 'Become a Certified Local Swat Tour Guide',
      ur: 'سوات کے تصدیق شدہ مقامی ٹور گائیڈ بنیں',
      ps: 'د سوات تایید شوی محلي لارښود شئ',
    },
    subtitle: {
      en: 'Share Swat’s rich Gandhara history, alpine trails, and local culture with visitors. Earn professional guide fees while promoting KPK tourism.',
      ur: 'سوات کی تاریخی وادیوں، گندھارا تہذیب اور ثقافت سے سیاحوں کو متعارف کروائیں۔ ایک معزز ٹور گائیڈ کے طور پر باوقار آمدنی حاصل کریں۔',
      ps: 'د سوات تاریخي درې، د ګندهارا تمدن او کلتور سیلانیانو ته وپیژنئ. د یو محترم لارښود په توګه ښه عاید ترلاسه کړئ.',
    },
    category: 'guide',
    iconName: 'Compass',
    benefits: [
      {
        title: { en: 'Showcase Local Heritage', ur: 'مقامی تاریخ اور ثقافت کا تعارف', ps: 'د محلي تاریخ او کلتور پیژندنه' },
        description: { en: 'Guide tourists through Mingora archaeological sites, White Palace, Malam Jabba, and Kalam.', ur: 'مینگورہ کے تاریخی مقامات، وائیٹ پیلس، مالم جبہ اور کالام کی سیر کروائیں۔', ps: 'د مینګورې تاریخي ځایونه، وایټ پیلس، مالم جبه او کالام وښایاست.' },
        icon: 'BookOpen',
      },
      {
        title: { en: 'Flexible Tourism Bookings', ur: 'اپنی مرضی کے سیاحتی ٹورز', ps: 'د خپلې خوښې سیاحتي چکرونه' },
        description: { en: 'Accept half-day sightseeing or multi-day mountain trekking guide assignments.', ur: 'آدھے دن کی سیر یا کئی دنوں کے مہم جوئی ٹورز کی بکنگ اپنی مرضی سے لیں۔', ps: 'د نیمې ورځې یا څو ورځو د چکرونو بکینګ د خپلې خوښې سره واخلئ.' },
        icon: 'Calendar',
      },
      {
        title: { en: 'Multilingual Profile Badges', ur: 'زبانوں کی مہارت کے بیجز', ps: 'د ژبو د وړتیا بیجونه' },
        description: { en: 'Highlight your proficiency in English, Urdu, Pashto, or international languages.', ur: 'انگریزی، اردو، پشتو یا دیگر زبانوں کی مہارت کو اپنے پروفائل پر نمایاں کریں۔', ps: 'انګلیسي، اردو، پښتو یا نورو ژبو کې خپله وړتیا په پروفایل کې وښایاست.' },
        icon: 'Languages',
      },
    ],
    requirements: [
      { en: 'Valid Pakistani CNIC and verified resident of Khyber Pakhtunkhwa', ur: 'اصل شناختی کارڈ اور خیبر پختونخوا کے رہائشی ہونے کا ثبوت', ps: 'اصلي پیژندپاڼه او د خیبر پختونخوا د اوسیدونکي ثبوت' },
      { en: 'Fluency in Pashto, Urdu, and conversational English', ur: 'پشتو، اردو اور انگریزی زبان میں گفتگو کی مہارت', ps: 'په پښتو، اردو او انګلیسي ژبه د خبرو کولو وړتیا' },
      { en: 'Deep knowledge of Swat history, trails, safety rules & local traditions', ur: 'سوات کی تاریخ، راستوں، حفاظتی اصولوں اور روایات کا وسیع علم', ps: 'د سوات د تاریخ، لارو، امنیتي اصولو او دودونو پراخه پوهه' },
    ],
    onboardingSteps: [
      { step: 1, title: { en: 'Submit Guide Profile', ur: 'گائیڈ کا پروفائل جمع کروائیں', ps: 'د لارښود پروفایل وسپارئ' }, detail: { en: 'Detail your language skills, historical knowledge, and trekking expertise.', ur: 'اپنی زبانوں، تاریخی معلومات، اور مہم جوئی کے تجربے کی تفصیل درج کریں۔', ps: 'د خپلو ژبو، تاریخي معلوماتو او تجربې تفصیل دننه کړئ.' } },
      { step: 2, title: { en: 'Interview & Safety Assessment', ur: 'انٹرویو اور حفاظتی جانچ', ps: 'مرکه او امنیتي ازموینه' }, detail: { en: 'Our tourism team evaluates your communication and guest safety knowledge.', ur: 'ہماری سیاحتی ٹیم آپ کے اخلاق اور حفاظتی معلومات کا جائزہ لیتی ہے۔', ps: 'زموږ د سیاحت ټیم ستاسو د اخلاقو او امنیتي پوهې څیړنه کوي.' } },
      { step: 3, title: { en: 'Accept Tour Guide Bookings', ur: 'ٹور گائیڈ کی بکنگز لیں', ps: 'د لارښود بکینګونه واخلئ' }, detail: { en: 'Connect with tourists and lead unforgettable experiences in Swat Valley.', ur: 'سیاحوں کی رہنمائی کریں اور انہیں سوات کی خوبصورتی سے متعارف کروائیں۔', ps: 'د سیلانیانو لارښودي وکړئ او هغوی د سوات له ښکلا سره وپیژنئ.' }, },
    ],
    earningsDisclaimer: {
      en: 'Disclaimer: Tour guide bookings vary by tourism season and traveler feedback ratings.',
      ur: 'وضاحت: ٹور گائیڈ کی بکنگز کا انحصار سیاحتی سیزن اور مہمانوں کے فیڈ بیک پر ہے۔',
      ps: 'وضاحت: د لارښود بکینګونه د سیاحتي فصل او د میلمنو په فیډبیک پورې اړه لري.',
    },
    applyUrl: '/download',
  },
];
