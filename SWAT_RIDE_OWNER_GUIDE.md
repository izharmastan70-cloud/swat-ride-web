# SWAT RIDE — ALL-IN-ONE OWNER & CUSTOMIZATION GUIDE
**"Khud Change Karne Ka Tarika — Complete Easy Guide"**  
**Target Region:** Swat, Khyber Pakhtunkhwa (KPK), Pakistan

یہ گائیڈ آپ کے لیے خصوصی طور پر تیار کی گئی ہے تاکہ آپ مستقبل میں کسی بھی وقت **خود سے (Yourself)** ویب سائٹ میں کوئی بھی نیا شہر (جیسے چارباغ، مالم جبہ، کالام)، نئی گاڑی، نیا سلائیڈ، نئی تصویر، نیا سوال یا نئی سروس شامل اور تبدیل کر سکیں۔

---

## 1. آپ کی ویب سائٹ کا "All-In-One" سینٹرل ڈیٹا سسٹم

ویب سائٹ کو اس طرح ڈیزائن کیا گیا ہے کہ آپ کو پورے کوڈ کو چھیڑنے کی ضرورت نہیں! صرف **ایک فائل** میں چند الفاظ لکھنے سے پوری ویب سائٹ (ہوم پیج، مینیو، سروس پیج، اور SEO) خودکار طور پر اپڈیٹ ہو جاتی ہے:

| آپ کیا تبدیل یا شامل کرنا چاہتے ہیں؟ | کس فائل کو کھولنا ہے؟ | کیسے کام کرتا ہے؟ |
| :--- | :--- | :--- |
| **1. 3-Second Auto-Slider کی 25 تصاویر اور سلائیڈز** | `/src/components/3d/Hero3DCanvas.tsx` | اس فائل میں `SWAT_ECOSYSTEM_SLIDES` کے نام سے لسٹ ہے۔ آپ کسی بھی سلائیڈ کا نام، اردو عنوان، یا تصویر کا پاتھ باآسانی بدل سکتے ہیں۔ |
| **2. سوات کے شہر اور علاقے (Charbagh, Mingora, Kalam وغیرہ)** | `/src/data/locations.ts` | اس فائل میں `SWAT_LOCATIONS` کی لسٹ ہے۔ ہم نے **چارباغ (Charbagh)** سب سے اوپر ایڈ کر دیا ہے۔ آپ یہاں کوئی بھی نیا علاقہ (جیسے مٹہ، کبل، خوازہ خیلہ) شامل کر سکتے ہیں۔ |
| **3. 6 بنیادی سروسز (Ride, Food, Cargo, Student, Hotels, Tours)** | `/src/data/services.ts` | ہر سروس کی خصوصیات، کرایہ کا طریقہ کار، اور بٹن کے لنکس یہاں سے تبدیل ہوتے ہیں۔ |
| **4. 9 پارٹنر اور ڈرائیور رولز (Driver, Restaurant, Tour Guide...)** | `/src/data/partners.ts` | ڈرائیور کی شرائط، کمیشن کا طریقہ اور آن بورڈنگ کے مراحل یہاں درج ہیں۔ |
| **5. سوالات اور جوابات (Help Center & FAQ — 18 Categories)** | `/src/data/help.ts` | نئے سوالات یا ان کے جوابات (اردو، پشتو، انگریزی) یہاں شامل کریں۔ |
| **6. ویڈیو ٹیوٹوریلز (How-To Video Center — 19 Videos)** | `/src/data/videos.ts` | کسی بھی ویڈیو کا یوٹیوب یا MP4 لنک، عنوان اور ٹرانسکرپٹ یہاں سے بدلیں۔ |
| **7. بلاگ اور سفری گائیڈز (Travel & Safety Blog)** | `/src/data/blog.ts` | نئے مضامین یا سفری معلومات یہاں ایڈ کریں۔ |
| **8. گوگل پلے ڈاؤنلوڈ لنک اور رابطہ نمبر** | `.env.local` اور `/src/data/navigation.ts` | اپنا پلے اسٹور لنک، سپورٹ فون نمبر، اور ای میل یہاں سے اپڈیٹ کریں۔ |

---

## 2. نیا شہر یا علاقہ کیسے شامل کریں؟ (مثال: Charbagh, Swat)

ہم نے آپ کے کہنے پر **چارباغ (Charbagh)** کا مکمل پیج ایڈ کر دیا ہے۔ اگر آپ مستقبل میں کوئی اور علاقہ شامل کرنا چاہیں تو صرف `/src/data/locations.ts` میں یہ چھوٹا سا بلاک لکھیں:

```ts
  {
    id: 'charbagh',
    slug: 'charbagh',
    name: 'Charbagh',
    urduName: 'چارباغ',
    tagline: 'The Orchard Valley & Educational Hub of Upper Swat',
    description: 'Charbagh is a historic tehsil in Swat District...',
    altitude: '3,450 ft (1,051 m)',
    distanceFromMingora: '15 km north of Mingora',
    bestSeason: 'Year-Round',
    highlights: [
      'Famous Charbagh fruit orchards (peaches, apples)',
      'Gateway connecting Mingora to Malam Jabba and Bahrain',
    ],
    recommendedTransport: 'Normal Ride & Student Ride',
    availableServices: ['ride', 'food', 'cargo', 'student-ride', 'hotels', 'tours'],
    imageUrl: 'https://images.unsplash.com/...',
  },
```
**اس کا فائدہ:** جیسے ہی آپ یہ لکھیں گے، ویب سائٹ پر `https://swatride.pk/swat/charbagh` کا پیج خودکار طور پر بن جائے گا!

---

## 3. ہوم پیج کے 3-Second Auto-Slider میں کوئی نئی سلائیڈ کیسے ڈالیں؟

اگر آپ کوئی نئی گاڑی یا سروس سلائیڈ میں ڈالنا چاہتے ہیں تو `/src/components/3d/Hero3DCanvas.tsx` فائل کھولیں اور `SWAT_ECOSYSTEM_SLIDES` میں یہ لکھیں:

```ts
  {
    id: 'my-new-slide',
    titleEn: 'My New Vehicle or Service Title',
    titleUr: 'آپ کا اردو عنوان یہاں لکھیں',
    tag: 'NEW TAG',
    category: 'Category Name',
    image: '/images/your-image-name.jpg',
    color: '#10B981', // رنگ کا کوڈ
  },
```

---

## 4. تصویر (Image / Logo / Driver Photo) کیسے تبدیل کریں؟

1. **لوگو (Logo):** آپ کی دی ہوئی تصویر `/public/logo.jpg` کے نام سے محفوظ ہے۔ اگر کبھی نیا لوگو لگانا ہو تو بس اسی نام سے `/public/logo.jpg` فائل ریپلیس کر دیں۔
2. **ڈرائیور اور گائیڈ کی تصویر (Driver Profile):** آپ کا اپ لوڈ کردہ ڈرائیور فوٹو `/public/driver-profile.jpg` اور `/public/swat-guide.jpg` کے نام سے محفوظ ہے۔ یہ 4x4 پراڈو سلائیڈ، ٹورز پیج، ڈرائیور اور ٹورزم ڈرائیور پیجز پر لائیو نظر آ رہا ہے۔
3. **گاڑیوں کی تصاویر:** تمام 10 گاڑیاں اور ڈرون ویو `/public/images/` کے اندر موجود ہیں (جیسے `swat-corolla-fielder.jpg`, `swat-4x4-jeep.jpg`, `swat-student-van.jpg` وغیرہ)۔ آپ کسی بھی وقت اپنی اصلی تصویر اسی نام سے وہاں رکھ سکتے ہیں۔

---

## 5. بلڈ اور لائیو ٹیسٹنگ کیسے کریں؟

جب بھی آپ کوئی تبدیلی کریں تو ٹرمینل میں یہ کمانڈ چلائیں:
* **لائیو پریویو دیکھنے کے لیے:** `npm run dev`
* **پروڈکشن بلڈ چیک کرنے کے لیے:** `npm run build`

---

## 6. پوری ویب سائٹ کو لائیو (Deploy) کرنے کا مکمل اور آسان طریقہ

### سوال 1: کیا ویب سائٹ لائیو کرنا اور ڈومین (Domain) مفت ہوگا؟
* **ہوسٹنگ (Hosting) — 100% بالکل مفت (Lifetime Free):** آپ اس ویب سائٹ کو دنیا کی بہترین کلاؤڈ ہوسٹنگ [Vercel.com](https://vercel.com) پر لائیو کر سکتے ہیں جس کا **کوئی ماہانہ یا سالانہ بل نہیں ہوتا**۔
* **مفت ڈومین لنک (Free Subdomain):** Vercel آپ کو ویب سائٹ لائیو کرتے ہی ایک **بالکل مفت ڈومین لنک** دیتا ہے (مثلاً `https://swat-ride.vercel.app`) جو فوراً پوری دنیا میں کھلتا ہے اور سیکیور (HTTPS) ہوتا ہے۔
* **اپنا ڈومین (`swatride.pk` یا `swatride.com`):** اپنا ذاتی بزنس ڈومین خریدنا اختیاری (Optional) ہوتا ہے۔ `.pk` ڈومین پاکستان میں آفیشل ادارہ [PKNIC (pknic.net.pk)](https://pknic.net.pk) سالانہ تقریباً 3,000 روپے میں دیتا ہے۔ آپ شروع میں **مفت Vercel لنک** استعمال کر سکتے ہیں اور بعد میں جب چاہیں اپنا خریدا ہوا ڈومین جوڑ سکتے ہیں!

---

### سوال 2: 3 منٹ میں لائیو کرنے کا آسان ترین طریقہ کیا ہے؟ (Step-by-Step with Links)

#### پہلا قدم (Step 1): GitHub پر مفت اکاؤنٹ بنائیں
1. اس لنک پر جائیں: **[https://github.com/signup](https://github.com/signup)**
2. اپنا مفت اکاؤنٹ بنائیں اور **"New Repository"** پر کلک کر کے اپنے زِپ کیے ہوئے فولڈر کی فائلیں اپ لوڈ کر دیں۔

#### دوسرا قدم (Step 2): Vercel ہوسٹنگ پر مفت اکاؤنٹ بنائیں
1. اس لنک پر جائیں: **[https://vercel.com/signup](https://vercel.com/signup)**
2. وہاں **"Continue with GitHub"** پر کلک کر کے اپنے GitHub اکاؤنٹ سے لاگ ان کریں۔

#### تیسرا قدم (Step 3): 1 کلک میں Deploy (لائیو) کریں
1. Vercel ڈیش بورڈ میں **"Add New Project"** پر کلک کریں۔
2. آپ کا SWAT RIDE پراجیکٹ سامنے آئے گا، اس کے آگے **"Import"** پر کلک کریں۔
3. بس نیچے نیلے رنگ کا **"Deploy"** بٹن دبا دیں!
4. **مبارک ہو!** 1 منٹ کے اندر آپ کی ویب سائٹ **`https://swat-ride.vercel.app`** پر لائیو ہو جائے گی!

---

### سوال 3: زِپ فائل ڈاؤنلوڈ کیسے کریں؟ (`swat-ride-website.zip`)
1. اپنی سکرین پر بائیں جانب موجود **فائل لسٹ (Workspace File Explorer)** کو دیکھیں۔
2. وہاں **`swat-ride-website.zip`** پر کلک کریں اور اوپر یا سائیڈ پر موجود **Download** کے آئیکن پر کلک کر دیں۔
3. یہ زِپ فائل (**4.3 MB**) سیکنڈوں میں آپ کے فون یا کمپیوٹر میں سیو ہو جائے گی!
