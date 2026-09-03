import { NavItem } from '@/types';

export const PRIMARY_NAV_ITEMS: NavItem[] = [
  { label: { en: 'Home', ur: 'ہوم', ps: 'کور' }, href: '/' },
  { label: { en: 'Ride', ur: 'رائیڈ', ps: 'سفر' }, href: '/ride' },
  { label: { en: 'Food', ur: 'فوڈ', ps: 'خواړه' }, href: '/food' },
  { label: { en: 'Cargo', ur: 'کارگو', ps: 'کارګو' }, href: '/cargo' },
  { label: { en: 'Student Ride', ur: 'اسٹوڈنٹ رائیڈ', ps: 'د زده کونکو سفر' }, href: '/student-ride' },
  { label: { en: 'Hotels', ur: 'ہوٹلز', ps: 'هوټلونه' }, href: '/hotels' },
  { label: { en: 'Tours', ur: 'ٹورز', ps: 'سیاحت' }, href: '/tours' },
  {
    label: { en: 'Partners', ur: 'پارٹنرز', ps: 'ملګري' },
    href: '/driver',
    children: [
      { label: { en: 'Normal Ride Driver', ur: 'نارمل رائیڈ ڈرائیور', ps: 'عادي چلوونکی' }, href: '/driver', description: { en: 'Drive cars in Mingora & Swat', ur: 'مینگورہ اور سوات میں گاڑی چلائیں', ps: 'په مینګوره او سوات کې موټر وچلوئ' }, iconName: 'Car' },
      { label: { en: 'Restaurant Partner', ur: 'ریسٹورانٹ پارٹنر', ps: 'رستورانت ملګری' }, href: '/restaurant-partner', description: { en: 'List your Swat restaurant', ur: 'اپنا ریسٹورانٹ شامل کریں', ps: 'خپل رستورانت ثبت کړئ' }, iconName: 'Store' },
      { label: { en: 'Food Delivery Rider', ur: 'فوڈ ڈیلیوری رائیڈر', ps: 'د خوړو رایډر' }, href: '/food-rider', description: { en: 'Deliver hot meals on bike', ur: 'بائیک پر کھانا ڈیلیور کریں', ps: 'په موټرسایکل خواړه ورسوئ' }, iconName: 'Bike' },
      { label: { en: 'Cargo Driver', ur: 'کارگو ڈرائیور', ps: 'کارګو چلوونکی' }, href: '/cargo-driver', description: { en: 'Transport goods & parcels', ur: 'سامان اور پارسل کی ترسیل', ps: 'د توکو او پارسل لیږد' }, iconName: 'Truck' },
      { label: { en: 'Student Ride Driver', ur: 'اسٹوڈنٹ رائیڈ ڈرائیور', ps: 'د زده کونکي چلوونکی' }, href: '/student-driver', description: { en: 'Monthly school transport', ur: 'ماہانہ اسکول ٹرانسپورٹ', ps: 'میاشتنی ښوونځي ټرانسپورټ' }, iconName: 'GraduationCap' },
      { label: { en: 'Parent / Guardian', ur: 'والدین / سرپرست پورٹل', ps: 'د میندو او پلرونو پورټل' }, href: '/parents', description: { en: 'Manage child school transit', ur: 'بچے کا اسکول سفر مینج کریں', ps: 'د ماشوم سفر اداره کړئ' }, iconName: 'ShieldCheck' },
      { label: { en: 'Hotel Partner', ur: 'ہوٹل پارٹنر', ps: 'هوټل ملګری' }, href: '/hotel-partner', description: { en: 'List Swat rooms & resorts', ur: 'اپنے ہوٹل کے کمرے شامل کریں', ps: 'د هوټل خونې ثبت کړئ' }, iconName: 'Hotel' },
      { label: { en: 'Tourism Driver', ur: 'ٹورزم ڈرائیور', ps: 'د سیاحت چلوونکی' }, href: '/tourism-driver', description: { en: '4x4 expeditions to Kalam', ur: 'کالام کے لیے 4x4 ٹورز', ps: 'د کالام لپاره 4x4 چکرونه' }, iconName: 'Mountain' },
      { label: { en: 'Tour Guide', ur: 'ٹور گائیڈ', ps: 'سیاحتي لارښود' }, href: '/tour-guide', description: { en: 'Share Swat history & trails', ur: 'سوات کی تاریخ اور رہنمائی', ps: 'د سوات تاریخ او لارښوونه' }, iconName: 'Compass' },
    ],
  },
  { label: { en: 'Safety', ur: 'حفاظت', ps: 'خونديتوب' }, href: '/safety' },
  { label: { en: 'Rewards', ur: 'ریوارڈز', ps: 'جایزې' }, href: '/rewards' },
  { label: { en: 'Help', ur: 'مدد', ps: 'مرسته' }, href: '/help' },
  { label: { en: 'Blog', ur: 'بلاگ', ps: 'بلاګ' }, href: '/blog' },
];

export const FOOTER_LINKS = {
  services: [
    { label: { en: 'Normal Ride', ur: 'نارمل رائیڈ', ps: 'عادي سفر' }, href: '/ride' },
    { label: { en: 'Food Delivery', ur: 'فوڈ ڈیلیوری', ps: 'خواړه رسول' }, href: '/food' },
    { label: { en: 'Cargo & Logistics', ur: 'کارگو اور لاجسٹکس', ps: 'کارګو او لوژستیک' }, href: '/cargo' },
    { label: { en: 'Student Ride', ur: 'اسٹوڈنٹ رائیڈ', ps: 'د زده کونکو سفر' }, href: '/student-ride' },
    { label: { en: 'Hotels', ur: 'ہوٹلز', ps: 'هوټلونه' }, href: '/hotels' },
    { label: { en: 'Tours & Tourism', ur: 'ٹورز اور سیاحت', ps: 'سیاحت او چکرونه' }, href: '/tours' },
  ],
  partners: [
    { label: { en: 'Normal Ride Driver', ur: 'نارمل رائیڈ ڈرائیور', ps: 'عادي چلوونکی' }, href: '/driver' },
    { label: { en: 'Restaurant Partner', ur: 'ریسٹورانٹ پارٹنر', ps: 'رستورانت ملګری' }, href: '/restaurant-partner' },
    { label: { en: 'Food Rider', ur: 'فوڈ رائیڈر', ps: 'د خوړو رایډر' }, href: '/food-rider' },
    { label: { en: 'Cargo Driver', ur: 'کارگو ڈرائیور', ps: 'کارګو چلوونکی' }, href: '/cargo-driver' },
    { label: { en: 'Student Driver', ur: 'اسٹوڈنٹ ڈرائیور', ps: 'د زده کونکي چلوونکی' }, href: '/student-driver' },
    { label: { en: 'Parent Portal', ur: 'والدین پورٹل', ps: 'د میندو او پلرونو پورټل' }, href: '/parents' },
    { label: { en: 'Hotel Partner', ur: 'ہوٹل پارٹنر', ps: 'هوټل ملګری' }, href: '/hotel-partner' },
    { label: { en: 'Tourism Driver', ur: 'ٹورزم ڈرائیور', ps: 'د سیاحت چلوونکی' }, href: '/tourism-driver' },
    { label: { en: 'Tour Guide', ur: 'ٹور گائیڈ', ps: 'سیاحتي لارښود' }, href: '/tour-guide' },
  ],
  supportAndSafety: [
    { label: { en: 'Safety & SOS Center', ur: 'حفاظت اور SOS سینٹر', ps: 'خونديتوب او SOS مرکز' }, href: '/safety' },
    { label: { en: 'Help & FAQ Center', ur: 'مدد اور سوالات', ps: 'مرسته او پوښتنې' }, href: '/help' },
    { label: { en: 'Video Tutorials', ur: 'ویڈیو ٹیوٹوریلز', ps: 'ویډیو ښوونې' }, href: '/help/videos' },
    { label: { en: 'Feedback & Support', ur: 'شکایات اور فیڈ بیک', ps: 'شکایت او فیډبیک' }, href: '/contact' },
    { label: { en: 'Rewards & Offers', ur: 'ریوارڈز اور آفرز', ps: 'جایزې او وړاندیزونه' }, href: '/rewards' },
    { label: { en: 'Promo Codes', ur: 'پرومو کوڈز', ps: 'پرومو کوډونه' }, href: '/offers' },
  ],
  legalAndCompany: [
    { label: { en: 'About SWAT RIDE', ur: 'سوات رائیڈ کا تعارف', ps: 'د سوات رایډ پیژندنه' }, href: '/about' },
    { label: { en: 'Careers in Mingora', ur: 'ملازمت کے مواقع', ps: 'د دندې فرصتونه' }, href: '/careers' },
    { label: { en: 'Privacy Policy', ur: 'پرائیویسی پالیسی', ps: 'د پرائیویسی پالیسي' }, href: '/privacy' },
    { label: { en: 'Terms of Service', ur: 'شرائط و ضوابط', ps: 'شرایط او قوانین' }, href: '/terms' },
    { label: { en: 'Refund Policy', ur: 'رقم کی واپسی کی پالیسی', ps: 'د پیسو بیرته ورکولو پالیسي' }, href: '/refund-policy' },
    { label: { en: 'Cancellation Policy', ur: 'کینسلیشن پالیسی', ps: 'د لغوه کولو پالیسي' }, href: '/cancellation-policy' },
    { label: { en: 'Community Guidelines', ur: 'کمیونٹی گائیڈلائنز', ps: 'د ټولنې لارښوونې' }, href: '/community-guidelines' },
  ],
};
