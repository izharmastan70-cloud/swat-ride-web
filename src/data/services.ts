import { ServiceItem } from '@/types';

export const SWAT_SERVICES: ServiceItem[] = [
  {
    id: 'ride',
    slug: 'ride',
    title: {
      en: 'Normal Ride',
      ur: 'نارمل رائیڈ',
      ps: 'عادي سفر',
    },
    shortDescription: {
      en: 'Reliable, comfortable daily city rides across Mingora, Saidu Sharif, and all Swat valleys with upfront fare estimates.',
      ur: 'مینگورہ، سیدو شریف اور سوات کی تمام وادیوں میں پیشگی کرایہ کے اندازے کے ساتھ روزانہ کا آرام دہ اور محفوظ سفر۔',
      ps: 'په مینګوره، سیدو شریف او د سوات په ټولو درو کې د کرایې له مخکې اندازې سره د باور وړ او آرام ورځنی سفر.',
    },
    fullDescription: {
      en: 'SWAT RIDE Normal Ride connects passengers in Swat with verified local drivers. Experience transparent upfront fare estimates, real-time GPS tracking, cash and digital payment flexibility, and 24/7 SOS safety monitoring.',
      ur: 'سوات رائیڈ نارمل رائیڈ سوات کے مسافروں کو تصدیق شدہ مقامی ڈرائیوروں سے جوڑتی ہے۔ شفاف پیشگی کرایہ، ریئل ٹائم GPS ٹریکنگ، کیش اور ڈیجیٹل ادائیگیوں کی سہولت، اور 24/7 ہنگامی SOS کیمرانی کا تجربہ کریں۔',
      ps: 'سوات رایډ عادي سفر د سوات مسافر د سیمه ایزو تایید شویو چلوونکو سره نښلوي. شفاف کرایه، ریښتیني وخت GPS تعقیب، او د 24/7 SOS خوندیتوب څارنې تجربه وکړئ.',
    },
    iconName: 'Car',
    badge: {
      en: 'Most Popular',
      ur: 'سب سے مقبول',
      ps: 'ترټولو مشهور',
    },
    themeColor: '#10B981', // Emerald
    features: [
      {
        en: 'Upfront Fare Estimate before booking',
        ur: 'بکنگ سے پہلے شفاف کرایہ کا اندازہ',
        ps: 'د بکینګ څخه مخکې د کرایې اټکل',
      },
      {
        en: 'Verified local Swat drivers with background checks',
        ur: 'سوات کے تصدیق شدہ اور بااعتماد مقامی ڈرائیورز',
        ps: 'د سوات تصدیق شوي او باوري چلوونکي',
      },
      {
        en: 'Real-time GPS ride tracking & trip sharing',
        ur: 'لائیو GPS ٹریکنگ اور سفر شیئر کرنے کی سہولت',
        ps: 'د ژوندۍ GPS تعقیب او د سفر شریکولو اسانتیا',
      },
      {
        en: 'Dedicated SOS Emergency assistance button',
        ur: 'ہنگامی امداد کے لیے مخصوص SOS بٹن',
        ps: 'د بېړنۍ مرستې لپاره ځانګړی SOS تڼۍ',
      },
    ],
    howItWorks: [
      {
        stepNumber: 1,
        title: { en: 'Set Pickup & Destination', ur: 'پک اپ اور منزل منتخب کریں', ps: 'د پورته کولو او د منزل ځای وټاکئ' },
        description: { en: 'Enter your Swat location to view instant upfront fare estimates.', ur: 'اپنا مقام درج کریں اور فوری کرایہ کا اندازہ دیکھیں۔', ps: 'خپل ځای دننه کړئ او د کرایې اټکل وګورئ.' },
      },
      {
        stepNumber: 2,
        title: { en: 'Match with a Verified Driver', ur: 'تصدیق شدہ ڈرائیور سے رابطہ', ps: 'له تایید شوي چلوونکي سره نښلول' },
        description: { en: 'We connect you with the nearest approved vehicle in seconds.', ur: 'ہم آپ کو سیکنڈوں میں قریبی تصدیق شدہ گاڑی سے جوڑتے ہیں۔', ps: 'موږ تاسو په ثانیو کې له نږدې موټر سره نښلوو.' },
      },
      {
        stepNumber: 3,
        title: { en: 'Track & Ride Comfortably', ur: 'ٹریک کریں اور آرام سے سفر کریں', ps: 'تعقیب کړئ او په آرامۍ سره سفر وکړئ' },
        description: { en: 'Share your trip status with family and arrive safely at your destination.', ur: 'اپنے خاندان کے ساتھ سفر کی معلومات شیئر کریں اور خیریت سے منزل پر پہنچیں۔', ps: 'خپل سفر له کورنۍ سره شریک کړئ او په خوندیتوب ورسیږئ.' },
      },
    ],
    ctaText: { en: 'Book a Ride in App', ur: 'ایپ میں رائیڈ بک کریں', ps: 'په ایپ کې سفر بک کړئ' },
    ctaLink: '/download',
    secondaryCtaText: { en: 'Become a Driver', ur: 'ڈرائیور بنیں', ps: 'چلوونکی شئ' },
    secondaryCtaLink: '/driver',
    safetyNote: {
      en: 'All rides include verified SOS capabilities and optional trip sharing with trusted contacts.',
      ur: 'تمام سفروں میں ہنگامی SOS سہولت اور قابل اعتماد رابطوں کے ساتھ سفر شیئر کرنے کا نظام شامل ہے۔',
      ps: 'په ټولو سفرونو کې د بېړنۍ SOS مرستې او د سفر شریکولو اسانتیا شامله ده.',
    },
  },
  {
    id: 'food',
    slug: 'food',
    title: {
      en: 'Food Delivery',
      ur: 'فوڈ ڈیلیوری',
      ps: 'خواړه رسول',
    },
    shortDescription: {
      en: 'Hot, delicious local Swati specialties and international favorites delivered fast from trusted restaurants.',
      ur: 'سوات کے بہترین مقامی پکوان اور مشہور ریسٹورانٹ سے گرم اور لذیذ کھانے کی تیز ترین ڈیلیوری۔',
      ps: 'د سوات غوره محلي خواړه او مشهور رستورانتونو څخه د تودو او خوندورو خوړو ګړندی رسول.',
    },
    fullDescription: {
      en: 'Discover authentic Swati cuisine, trout specialties, kebabs, and family favorites from Mingora, Saidu Sharif, and Fiza Gat. Real-time order preparation tracking and dedicated food delivery riders.',
      ur: 'مینگورہ، سیدو شریف اور فضاگٹ کے بہترین ریسٹورانٹ سے سواتی پکوان، ٹراؤٹ مچھلی، کباب اور دیگر لذیذ کھانوں کی ڈیلیوری کا تجربہ کریں۔',
      ps: 'د مینګورې، سیدو شریف او فضا ګاټ له غوره رستورانتونو څخه د سواتي خوړو، کباب او نورو خوندورو خوړو رسول تجربه کړئ.',
    },
    iconName: 'Utensils',
    badge: {
      en: 'Fresh & Fast',
      ur: 'تازہ اور تیز',
      ps: 'تازه او ګړندی',
    },
    themeColor: '#F59E0B', // Amber Gold
    features: [
      {
        en: 'Curated menu from verified Swat restaurant partners',
        ur: 'سوات کے تصدیق شدہ ریسٹورانٹ پارٹنرز کا بہترین مینیو',
        ps: 'د سوات د تایید شویو رستورانتونو غوره مینیو',
      },
      {
        en: 'Real-time kitchen preparation & rider tracking',
        ur: 'کچن میں تیاری اور رائیڈر کا لائیو ٹریکنگ نظام',
        ps: 'د پخلنځي چمتووالي او رایډر ژوندۍ څارنه',
      },
      {
        en: 'Thermal-insulated delivery bags for hot meals',
        ur: 'گرم کھانوں کے لیے خصوصی تھرمل انسلٹڈ ڈیلیوری بیگز',
        ps: 'د تودو خوړو لپاره ځانګړي حرارتي کڅوړې',
      },
      {
        en: 'Flexible cash on delivery and wallet payment options',
        ur: 'کیش آن ڈیلیوری اور والٹ ادائیگی کے آسان اختیارات',
        ps: 'د تحویل پر مهال د پیسو ورکولو او والټ اختیارونه',
      },
    ],
    howItWorks: [
      {
        stepNumber: 1,
        title: { en: 'Browse Restaurants', ur: 'ریسٹورانٹ منتخب کریں', ps: 'رستورانتونه وپلټئ' },
        description: { en: 'Explore authentic Swat eateries and filter by cuisine or location.', ur: 'سوات کے بہترین ریسٹورانٹ دیکھیں اور اپنی پسند کا کھانا چنیں۔', ps: 'د سوات غوره رستورانتونه وګورئ او خواړه وټاکئ.' },
      },
      {
        stepNumber: 2,
        title: { en: 'Restaurant Prepares Order', ur: 'ریسٹورانٹ کی تیاری', ps: 'رستورانت خواړه چمتو کوي' },
        description: { en: 'Your meal is freshly cooked and packed hygienically.', ur: 'آپ کا کھانا تازہ تیار کیا جاتا ہے اور صفائی سے پیک ہوتا ہے۔', ps: 'ستاسو خواړه تازه پخیږي او په پاکوالي بسته کیږي.' },
      },
      {
        stepNumber: 3,
        title: { en: 'Fast Rider Delivery', ur: 'رائیڈر کے ذریعے تیز ڈیلیوری', ps: 'د رایډر لخوا ګړندی رسول' },
        description: { en: 'Track your rider on the map as they deliver straight to your door.', ur: 'اپنے رائیڈر کو میپ پر ٹریک کریں جو سیدھا آپ کے دروازے پر پہنچے گا۔', ps: 'خپل رایډر په نقشه کې تعقیب کړئ چې مستقیم ستاسو دروازې ته راځي.' },
      },
    ],
    ctaText: { en: 'Order Food in App', ur: 'ایپ سے کھانا منگوائیں', ps: 'په ایپ کې خواړه وپلورئ' },
    ctaLink: '/download',
    secondaryCtaText: { en: 'Partner Your Restaurant', ur: 'ریسٹورانٹ رجسٹر کریں', ps: 'خپل رستورانت ثبت کړئ' },
    secondaryCtaLink: '/restaurant-partner',
  },
  {
    id: 'cargo',
    slug: 'cargo',
    title: {
      en: 'Cargo & Logistics',
      ur: 'کارگو اور لاجسٹکس',
      ps: 'کارګو او لوژستیک',
    },
    shortDescription: {
      en: 'Dependable goods transport, parcel delivery, and commercial load movement across Swat with vehicle tier options.',
      ur: 'سوات بھر میں سامان کی ترسیل، پارسل ڈیلیوری اور تجارتی لوڈ کے لیے قابل اعتماد کارگو سروس۔',
      ps: 'په ټول سوات کې د توکو لیږد، پارسل رسولو او سوداګریز بار لپاره د باور وړ کارګو خدمت.',
    },
    fullDescription: {
      en: 'From documents and retail parcels to heavy commercial equipment, SWAT RIDE Cargo offers specialized vehicle tiers (Express, Economy, Heavy, Documents, Fragile, and Buy-For-Me concierge where available) with secure chain-of-custody tracking.',
      ur: 'اہم دستاویزات سے لے کر تجارتی سامان تک، سوات رائیڈ کارگو مختلف گاڑیوں کے اختیارات اور محفوظ ٹریکنگ کے ساتھ سامان کی ترسیل فراہم کرتا ہے۔',
      ps: 'له مهمو اسنادو څخه تر سوداګریزو توکو پورې، سوات رایډ کارګو د مختلفو موټرو او خوندي تعقیب سره د توکو لیږد چمتو کوي.',
    },
    iconName: 'Truck',
    badge: {
      en: 'Express & Heavy Tiered',
      ur: 'ایکسپریس اور ہیوی لوڈ',
      ps: 'ایکسپریس او دروند بار',
    },
    themeColor: '#38BDF8', // Sky Blue
    features: [
      {
        en: 'Multiple vehicle tiers: Express, Economy & Heavy Cargo',
        ur: 'مختلف گاڑیوں کی کیٹگریز: ایکسپریس، اکانومی، اور ہیوی کارگو',
        ps: 'د موټرو مختلف کټګورۍ: ایکسپریس، اکانومي، او دروند کارګو',
      },
      {
        en: 'Specialized handling for fragile & commercial goods',
        ur: 'نازک اور تجارتی سامان کی حفاظت کے ساتھ ترسیل',
        ps: 'د نازکو او سوداګریزو توکو د خوندیتوب سره لیږد',
      },
      {
        en: 'Transparent weight and distance pricing',
        ur: 'وزن اور فاصلے کے حساب سے شفاف نرخ',
        ps: 'د وزن او واټن له مخې شفاف نرخونه',
      },
      {
        en: 'Digital pickup & delivery proof verification',
        ur: 'سامان اٹھانے اور ڈیلیور کرنے کی ڈیجیٹل تصدیق',
        ps: 'د توکو پورته کولو او رسولو ډیجیټل تصدیق',
      },
    ],
    howItWorks: [
      {
        stepNumber: 1,
        title: { en: 'Select Cargo Category', ur: 'کارگو کی قسم چنیں', ps: 'د کارګو ډول وټاکئ' },
        description: { en: 'Choose between Express parcel, Fragile, or Heavy commercial transport.', ur: 'ایکسپریس پارسل، نازک سامان یا ہیوی کارگو کا انتخاب کریں۔', ps: 'ایکسپریس پارسل، نازک توکي یا دروند کارګو وټاکئ.' },
      },
      {
        stepNumber: 2,
        title: { en: 'Driver Assignment & Loading', ur: 'ڈرائیور کا تعین اور لوڈنگ', ps: 'د چلوونکي ټاکنه او بارول' },
        description: { en: 'An appropriate cargo vehicle arrives to inspect and safely load your goods.', ur: 'موزوں کارگو گاڑی آپ کا سامان محفوظ طریقے سے لوڈ کرنے پہنچتی ہے۔', ps: 'مناسب کارګو موټر ستاسو توکي په خوندي ډول بارولو لپاره راځي.' },
      },
      {
        stepNumber: 3,
        title: { en: 'Verified Drop-off', ur: 'تصدیق شدہ ڈیلیوری', ps: 'تایید شوی تحویلي' },
        description: { en: 'Recipient confirms delivery via OTP or authorized signature.', ur: 'وصول کنندہ OTP یا دستخط کے ذریعے سامان کی تصدیق کرتا ہے۔', ps: 'ترلاسه کونکی د OTP یا لاسلیک له لارې د توکو تصدیق کوي.' },
      },
    ],
    ctaText: { en: 'Book Cargo in App', ur: 'ایپ سے کارگو بک کریں', ps: 'په ایپ کې کارګو بک کړئ' },
    ctaLink: '/download',
    secondaryCtaText: { en: 'Become a Cargo Driver', ur: 'کارگو ڈرائیور بنیں', ps: 'د کارګو چلوونکی شئ' },
    secondaryCtaLink: '/cargo-driver',
  },
  {
    id: 'student-ride',
    slug: 'student-ride',
    title: {
      en: 'Student Ride & School Transport',
      ur: 'اسٹوڈنٹ رائیڈ اور اسکول ٹرانسپورٹ',
      ps: 'د زده کونکو سفر او د ښوونځي ټرانسپورټ',
    },
    shortDescription: {
      en: 'Trust-first monthly school transport with background-checked drivers, authorized guardian handovers, and real-time attendance alerts.',
      ur: 'تصدیق شدہ ڈرائیورز، سرپرستوں کے حوالے کرنے کے نظام، اور ریئل ٹائم حاضری الرٹس کے ساتھ بااعتماد ماہانہ اسکول ٹرانسپورٹ۔',
      ps: 'د تایید شویو چلوونکو، د سرپرست د تحویلي سیسټم، او ژوندۍ خبرتیاو سره د باور وړ میاشتنی ښوونځي ټرانسپورټ.',
    },
    fullDescription: {
      en: 'SWAT RIDE Student Ride is engineered for maximum parental peace of mind in Swat. Offering monthly recurring packages, rigorous driver vetting, daily home-to-school-to-home attendance checks, authorized guardian handover protocols, and immediate SOS safety alerts.',
      ur: 'سوات رائیڈ اسٹوڈنٹ رائیڈ والدین کے مکمل اطمینان کے لیے تیار کیا گیا ہے۔ ماہانہ پیکیج، تصدیق شدہ ڈرائیورز، گھر سے اسکول اور واپسی کے حاضری الرٹس، اور سرپرستوں کے حوالے کرنے کا محفوظ نظام۔',
      ps: 'سوات رایډ د زده کونکو سفر د میندو او پلرونو د بشپړ ډاډ لپاره ډیزاین شوی دی. میاشتني کڅوړې، د چلوونکي دقیق تصدیق، او د سرپرست د تحویلي خوندي سیسټم.',
    },
    iconName: 'GraduationCap',
    badge: {
      en: 'Trusted & Verified',
      ur: 'تصدیق شدہ اور محفوظ',
      ps: 'تایید شوی او خوندي',
    },
    themeColor: '#059669', // Deep Emerald
    features: [
      {
        en: 'Dedicated monthly packages with fixed reliable drivers',
        ur: 'مستقل اور تصدیق شدہ ڈرائیورز کے ساتھ ماہانہ پیکیج',
        ps: 'د ثابت او تایید شویو چلوونکو سره میاشتني کڅوړې',
      },
      {
        en: 'Strict authorized guardian handover protocol',
        ur: 'صرف مجاز سرپرست کے حوالے کرنے کا سخت حفاظتی اصول',
        ps: 'یوازې مجاز سرپرست ته د تحویلولو سخت امنیتي اصول',
      },
      {
        en: 'Live attendance notifications for pickup and school arrival',
        ur: 'گھر سے روانگی اور اسکول پہنچنے کے لائیو حاضری الرٹس',
        ps: 'له کور څخه د تګ او ښوونځي ته د رسیدو ژوندۍ خبرتیاوې',
      },
      {
        en: 'Direct SOS emergency link to parent and SWAT RIDE support',
        ur: 'والدین اور سوات رائیڈ سپورٹ کے لیے فوری SOS رابطہ',
        ps: 'د میندو او پلرونو او سوات رایډ ملاتړ لپاره فوری SOS اړیکه',
      },
    ],
    howItWorks: [
      {
        stepNumber: 1,
        title: { en: 'Register Child & Guardians', ur: 'بچے اور سرپرست کو رجسٹر کریں', ps: 'ماشوم او سرپرست ثبت کړئ' },
        description: { en: 'Add school timings, home address, and authorized guardian photos.', ur: 'اسکول کے اوقات، گھر کا پتہ، اور مجاز سرپرستوں کی معلومات درج کریں۔', ps: 'د ښوونځي وختونه، د کور پته، او د مجاز سرپرستانو معلومات دننه کړئ.' },
      },
      {
        stepNumber: 2,
        title: { en: 'Assign Vetted Student Driver', ur: 'تصدیق شدہ ڈرائیور کا تعین', ps: 'د تایید شوي چلوونکي ټاکنه' },
        description: { en: 'We assign an experienced driver who passes strict background checks.', ur: 'ہم ایک تجربہ کار ڈرائیور مقرر کرتے ہیں جس کی مکمل سیکیورٹی تصدیق کی جاتی ہے۔', ps: 'موږ یو تجربه لرونکی چلوونکی ټاکو چې بشپړ امنیتي تصدیق یې شوی وي.' },
      },
      {
        stepNumber: 3,
        title: { en: 'Daily Safe Transit & Alerts', ur: 'روزانہ محفوظ سفر اور الرٹس', ps: 'ورځنی خوندي سفر او خبرتیاوې' },
        description: { en: 'Receive instant alerts when your child boards, arrives at school, and returns home safely.', ur: 'بچے کے سوار ہونے، اسکول پہنچنے اور خیریت سے گھر واپسی پر فوری الرٹس حاصل کریں۔', ps: 'د ماشوم سواری، ښوونځي ته رسیدو او په خوندیتوب د راستنیدو فوری خبرتیاوې ترلاسه کړئ.' },
      },
    ],
    ctaText: { en: 'Enroll Student in App', ur: 'ایپ میں اندراج کریں', ps: 'په ایپ کې ثبت شئ' },
    ctaLink: '/download',
    secondaryCtaText: { en: 'Parent / Guardian Guide', ur: 'والدین اور سرپرست گائیڈ', ps: 'د میندو او پلرونو لارښود' },
    secondaryCtaLink: '/parents',
    safetyNote: {
      en: 'Student drivers undergo extra verification including neighborhood reference checks and strict route discipline.',
      ur: 'اسٹوڈنٹ ڈرائیورز کی اضافی تصدیق کی جاتی ہے جس میں مقامی رہائشی تصدیق اور راستے کی پابندی شامل ہے۔',
      ps: 'د زده کونکو چلوونکو اضافي تصدیق کیږي، پشمول د سیمې د اوسیدونکو تایید او د لارې تعقیب.',
    },
  },
  {
    id: 'hotels',
    slug: 'hotels',
    title: {
      en: 'Swat Hotels & Stays',
      ur: 'سوات ہوٹلز اور قیام',
      ps: 'د سوات هوټلونه او د پاتې کیدو ځایونه',
    },
    shortDescription: {
      en: 'Discover and book verified hotels, guest houses, and resorts in Mingora, Malam Jabba, Bahrain, and Kalam.',
      ur: 'مینگورہ، مالم جبہ، بحرین اور کالام میں تصدیق شدہ ہوٹلز، گیسٹ ہاؤسز اور ریزورٹس کی تلاش اور بکنگ۔',
      ps: 'په مینګوره، مالم جبه، بحرین او کالام کې د تایید شویو هوټلونو، میلمستونونو او ریزورټونو موندنه او بکینګ.',
    },
    fullDescription: {
      en: 'SWAT RIDE Hotels connects visitors with verified hospitality partners across Swat Valley. Filter by location, amenities, room types, and family-friendly environments with transparent prices and zero hidden booking fees.',
      ur: 'سوات رائیڈ ہوٹلز سیاحوں کو وادی سوات کے تصدیق شدہ ہوٹلوں سے جوڑتا ہے۔ مقام، سہولیات، کمروں کی اقسام اور شفاف قیمتوں کے ساتھ بہترین رہائش منتخب کریں۔',
      ps: 'سوات رایډ هوټلونه سیلانیان د سوات درې له تایید شویو هوټلونو سره نښلوي. د ځای، اسانتیاو او شفافو نرخونو سره غوره پاتې کیدو ځای وټاکئ.',
    },
    iconName: 'Hotel',
    badge: {
      en: 'Verified Stays',
      ur: 'تصدیق شدہ ہوٹلز',
      ps: 'تایید شوي هوټلونه',
    },
    themeColor: '#047857', // Forest
    features: [
      {
        en: 'Verified hotel partners in Mingora, Kalam & Malam Jabba',
        ur: 'مینگورہ، کالام اور مالم جبہ میں تصدیق شدہ ہوٹل پارٹنرز',
        ps: 'په مینګوره، کالام او مالم جبه کې تایید شوي هوټل ملګري',
      },
      {
        en: 'Transparent pricing with room amenities & photo galleries',
        ur: 'کمروں کی سہولیات اور تصاویر کے ساتھ شفاف قیمتیں',
        ps: 'د خونو د اسانتیاو او عکسونو سره شفاف نرخونه',
      },
      {
        en: 'Seamless integration with SWAT RIDE transport to hotel',
        ur: 'ہوٹل تک سوات رائیڈ گاڑیوں کی آسان بکنگ کی سہولت',
        ps: 'هوټل ته د سوات رایډ موټرو د اسانه بکینګ اسانتیا',
      },
      {
        en: 'Clear cancellation & refund policy guidance',
        ur: 'بکنگ کینسل اور رقم کی واپسی کی واضح پالیسی',
        ps: 'د بکینګ لغوه کولو او د پیسو بیرته ورکولو روښانه پالیسي',
      },
    ],
    howItWorks: [
      {
        stepNumber: 1,
        title: { en: 'Choose Destination & Dates', ur: 'مقام اور تاریخیں منتخب کریں', ps: 'ځای او نیټې وټاکئ' },
        description: { en: 'Search across Mingora, Bahrain, Kalam, or Malam Jabba resorts.', ur: 'مینگورہ، بحرین، کالام یا مالم جبہ میں رہائش تلاش کریں۔', ps: 'په مینګوره، بحرین، کالام یا مالم جبه کې د پاتې کیدو ځای وپلټئ.' },
      },
      {
        stepNumber: 2,
        title: { en: 'Select Verified Room', ur: 'تصدیق شدہ کمرہ چنیں', ps: 'تایید شوې خونه وټاکئ' },
        description: { en: 'Review genuine amenities, beds, and transparent rates.', ur: 'حقیقی سہولیات، بیڈز، اور شفاف کرایوں کا جائزہ لیں۔', ps: 'رښتینې اسانتیاوې، بسترونه، او شفاف نرخونه وګورئ.' },
      },
      {
        stepNumber: 3,
        title: { en: 'Instant Confirmation & Transit', ur: 'فوری تصدیق اور سفر', ps: 'فوري تایید او سفر' },
        description: { en: 'Receive your booking voucher and optionally add a direct airport or city transfer.', ur: 'بکنگ واؤچر حاصل کریں اور ساتھ ہی ہوٹل کے لیے سوات رائیڈ گاڑی بک کریں۔', ps: 'د بکینګ واؤچر ترلاسه کړئ او ورسره د هوټل لپاره موټر بک کړئ.' },
      },
    ],
    ctaText: { en: 'Book Hotels in App', ur: 'ایپ سے ہوٹل بک کریں', ps: 'په ایپ کې هوټل بک کړئ' },
    ctaLink: '/download',
    secondaryCtaText: { en: 'Partner Your Hotel', ur: 'ہوٹل رجسٹر کریں', ps: 'خپل هوټل ثبت کړئ' },
    secondaryCtaLink: '/hotel-partner',
  },
  {
    id: 'tours',
    slug: 'tours',
    title: {
      en: 'Tours & Swat Tourism',
      ur: 'ٹورز اور سوات سیاحت',
      ps: 'سیاحت او د سوات چکرونه',
    },
    shortDescription: {
      en: 'Curated mountain tours, 4x4 Kalam expeditions, Mahodand Lake adventures, and expert local Swat guides.',
      ur: 'سوات کے خوبصورت مقامات، کالام، مہوڈنڈ جھیل کے سفری پیکیجز، اور تجربہ کار مقامی گائیڈز۔',
      ps: 'د سوات د ښکلو ځایونو، کالام، مهوډنډ جهیل د سفر کڅوړې، او تجربه لرونکي محلي لارښودان.',
    },
    fullDescription: {
      en: 'SWAT RIDE Tours opens the majestic beauty of Swat Valley to travelers worldwide. Explore customized itineraries, rugged 4x4 mountain vehicles for Kalam and Mahodand Lake, family sightseeing tours, and certified multilingual local guides who know every trail and historical landmark.',
      ur: 'سوات رائیڈ ٹورز وادی سوات کے دلکش مناظر کو دنیا کے سامنے پیش کرتا ہے۔ کسٹم سفری پیکیج، کالام اور مہوڈنڈ جھیل کے لیے 4x4 گاڑیاں، اور سوات کی تاریخ اور راستوں سے واقف مقامی گائیڈز۔',
      ps: 'سوات رایډ سیاحت د سوات درې ښکلي منظرې نړۍ ته وړاندې کوي. د کالام او مهوډنډ جهیل لپاره 4x4 موټرونه، او د سوات د تاریخ پوه محلي لارښودان.',
    },
    iconName: 'Mountain',
    badge: {
      en: 'Explore KPK',
      ur: 'سوات کی سیر',
      ps: 'د سوات چکر',
    },
    themeColor: '#10B981', // Bright Emerald
    features: [
      {
        en: 'Custom family & group tourism packages across Swat',
        ur: 'فیملی اور گروپس کے لیے سوات کے کسٹم سیاحتی پیکیجز',
        ps: 'د کورنۍ او ډلو لپاره د سوات ځانګړي سیاحتي کڅوړې',
      },
      {
        en: 'Rugged 4x4 mountain vehicles for Kalam, Ushu & Mahodand',
        ur: 'کالام، اوشو اور مہوڈنڈ جھیل کے لیے مضبوط 4x4 گاڑیاں',
        ps: 'د کالام، اوشو او مهوډنډ جهیل لپاره پیاوړي 4x4 موټرونه',
      },
      {
        en: 'Certified local Swat guides fluent in English, Urdu & Pashto',
        ur: 'انگریزی، اردو اور پشتو بولنے والے تصدیق شدہ مقامی گائیڈز',
        ps: 'انګلیسي، اردو او پښتو ویونکي تایید شوي محلي لارښودان',
      },
      {
        en: 'Transparent pricing with emergency mountain support',
        ur: 'شفاف نرخ اور پہاڑی راستوں پر ہنگامی امداد کا نظام',
        ps: 'شفاف نرخونه او په غره ییزو لارو کې د بېړنۍ مرستې سیسټم',
      },
    ],
    howItWorks: [
      {
        stepNumber: 1,
        title: { en: 'Pick a Scenic Itinerary', ur: 'سفری پیکیج منتخب کریں', ps: 'د سفر کڅوړه وټاکئ' },
        description: { en: 'Select from day trips to Malam Jabba or multi-day Kalam and Mahodand expeditions.', ur: 'مالم جبہ، کالام یا مہوڈنڈ جھیل کے سفری پیکیجز کا انتخاب کریں۔', ps: 'د مالم جبه، کالام یا مهوډنډ جهیل د سفر کڅوړه وټاکئ.' },
      },
      {
        stepNumber: 2,
        title: { en: 'Match Vehicle & Local Guide', ur: 'گاڑی اور مقامی گائیڈ کا انتخاب', ps: 'د موټر او محلي لارښود ټاکنه' },
        description: { en: 'We reserve the right vehicle tier and assign an experienced local tour guide.', ur: 'ہم موزوں ترین گاڑی اور سوات کا ماہر مقامی گائیڈ فراہم کرتے ہیں۔', ps: 'موږ مناسب موټر او د سوات د مسلکي لارښود چمتو کوو.' },
      },
      {
        stepNumber: 3,
        title: { en: 'Experience Majestic Swat', ur: 'خوبصورت سوات کا تجربہ کریں', ps: 'د ښکلي سوات تجربه وکړئ' },
        description: { en: 'Enjoy breathtaking valleys with complete safety and local hospitality.', ur: 'مکمل حفاظت اور مہمان نوازی کے ساتھ سوات کی وادیوں سے لطف اندوز ہوں۔', ps: 'د بشپړ خوندیتوب او میلمه پالنې سره د سوات له درو خوند واخلئ.' },
      },
    ],
    ctaText: { en: 'Explore Swat Tours in App', ur: 'ایپ میں ٹورز دیکھیں', ps: 'په ایپ کې چکرونه وګورئ' },
    ctaLink: '/download',
    secondaryCtaText: { en: 'Become a Tour Guide', ur: 'ٹور گائیڈ بنیں', ps: 'د سیاحت لارښود شئ' },
    secondaryCtaLink: '/tour-guide',
  },
];
