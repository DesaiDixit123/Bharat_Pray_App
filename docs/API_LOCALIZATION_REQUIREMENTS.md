# BharatPray API Localization Requirements & Specifications

**Document Version**: 1.0.0  
**Target Systems**: BharatPray Node.js/Express Backend (`BharatPray_Backend`) & Flutter Mobile Client (`Bharat_Pray_App 2`)  
**Supported Locales**: `en` (English), `hi` (Hindi), `gu` (Gujarati), `mr` (Marathi)

---

## 1. Executive Problem Statement & Backend Reality

An in-depth audit of the existing Node.js backend codebase (`BharatPray_Backend/models/`, `controllers/`, and `routes/`) revealed that:
1. **No Multilingual Database Schema**: Current Mongoose models (`temple.model.js`, `bhajan.model.js`, `yatra.model.js`, `god_category.model.js`, `festival.model.js`) store user-facing fields as single unilingual `String` attributes.
2. **No `Accept-Language` Middleware**: Express routers do not currently inspect incoming `Accept-Language` headers or language query parameters (`?lang=gu`).
3. **No Automatic Translation Pipeline**: Dynamic database rows currently contain only the language entered during admin seeding (primarily English or Hindi transliteration).

To achieve genuine dynamic localization across the BharatPray ecosystem without hardcoding translations into the Flutter app or creating fake mock data, this document defines the **Standardized Backend API Localization Contract**.

---

## 2. API Communication Contract

### 2.1 Request Headers
Every HTTP request initiated by the BharatPray Flutter app must include:
```http
Accept-Language: <language_code>
```
Valid language codes:
- `en` (English – Default fallback)
- `hi` (Hindi)
- `gu` (Gujarati)
- `mr` (Marathi)

### 2.2 Query Parameter Fallback (Optional)
Where header manipulation is constrained (e.g. streaming URLs, media downloads, direct browser previews), the backend must support:
```http
GET /api/v1/temple?lang=gu
```
Priority: Query Parameter `?lang=` > Header `Accept-Language` > Default (`en`).

---

## 3. Recommended Backend Implementation Architecture

### 3.1 Multilingual Mongoose Schema Pattern
Backend models should support internationalization using either of the two industry-standard patterns:

#### Pattern A: Embedded Localization Map (Recommended for High Read Performance)
```javascript
const LocalizedStringSchema = {
    en: { type: String, default: '' },
    hi: { type: String, default: '' },
    gu: { type: String, default: '' },
    mr: { type: String, default: '' }
};

// Example in temple.model.js:
const templeSchema = new mongoose.Schema({
    name: {
        en: { type: String, required: true },
        hi: { type: String, default: '' },
        gu: { type: String, default: '' },
        mr: { type: String, default: '' }
    },
    shortDescription: LocalizedStringSchema,
    description: LocalizedStringSchema,
    address: LocalizedStringSchema,
    city: LocalizedStringSchema,
    state: LocalizedStringSchema,
    // ... Non-localized attributes remain unchanged
    bannerImage: { type: String, default: '' },
    latitude: { type: Number, default: 0 },
    longitude: { type: Number, default: 0 }
}, { timestamps: true });
```

#### Pattern B: Backward-Compatible Hybrid Resolution (Recommended for Immediate Migration)
If keeping single string attributes for legacy admin panels:
```javascript
const templeSchema = new mongoose.Schema({
    name: { type: String, default: '' },
    translations: {
        hi: { name: String, description: String, address: String },
        gu: { name: String, description: String, address: String },
        mr: { name: String, description: String, address: String }
    }
});
```

### 3.2 Express.js Localization Middleware
Create a reusable middleware in `BharatPray_Backend/helpers/localization.middleware.js`:
```javascript
const supportedLanguages = ['en', 'hi', 'gu', 'mr'];

module.exports = (req, res, next) => {
    let lang = req.query.lang || req.headers['accept-language'] || 'en';
    
    // Normalize language code (e.g. 'gu-IN', 'gu_IN' -> 'gu')
    lang = lang.toLowerCase().split(/[-_]/)[0].trim();
    
    if (!supportedLanguages.includes(lang)) {
        lang = 'en';
    }
    
    req.locale = lang;
    next();
};
```

### 3.3 Dynamic Response Transformer
In the controller layer or a Mongoose plugin, transform the localized object before returning:
```javascript
function resolveLocalization(doc, locale) {
    if (!doc) return doc;
    const obj = doc.toObject ? doc.toObject() : { ...doc };
    
    const localizedKeys = ['name', 'title', 'description', 'shortDescription', 'address', 'mantra', 'slogan'];
    
    for (const key of localizedKeys) {
        if (obj[key] && typeof obj[key] === 'object') {
            obj[key] = obj[key][locale] || obj[key]['en'] || obj[key]['hi'] || Object.values(obj[key])[0] || '';
        }
    }
    return obj;
}
```

---

## 4. Endpoints Requiring Localization Support

The following existing BharatPray backend endpoints require localization integration:

| # | Endpoint | Module | Localized Fields Required |
|---|---|---|---|
| 1 | `GET /api/v1/temple` | Darshan / Temples | `name`, `shortDescription`, `description`, `city`, `state`, `address` |
| 2 | `GET /api/v1/temple/:id` | Darshan / Temples | `name`, `shortDescription`, `description`, `city`, `state`, `address` |
| 3 | `GET /api/v1/bhajan` | Bhajans | `title`, `artist`, `description` |
| 4 | `GET /api/v1/bhajan/:id` | Bhajans | `title`, `artist`, `description` |
| 5 | `GET /api/v1/god-category` | God Categories | `name`, `mantra`, `description` |
| 6 | `GET /api/v1/yatra` | Yatras | `title`, `description`, `routeTemples.name`, `checkpoints.instruction` |
| 7 | `GET /api/v1/yatra/:id` | Yatras | `title`, `description`, `routeTemples.name`, `checkpoints.instruction` |
| 8 | `GET /api/v1/festival` | Utsav / Festivals | `name`, `slogan`, `description`, `timing`, `rewards.*` |
| 9 | `GET /api/v1/festival/:id` | Utsav / Festivals | `name`, `slogan`, `description`, `timing`, `rewards.*` |
| 10 | `GET /api/v1/granth` | Grantha | `name`, `description`, `author` |
| 11 | `GET /api/v1/granth/category` | Grantha | `name`, `description` |
| 12 | `GET /api/v1/jap/list` | Jap | `title`, `mantra`, `significance` |
| 13 | `GET /api/v1/notification` | Notifications | `title`, `message` |

---

## 5. Sample Request & Response Contract Examples

### 5.1 Temple Endpoint (`GET /api/v1/temple`)
#### Request:
```http
GET /api/v1/temple?page=1&limit=10 HTTP/1.1
Host: 192.168.29.209:3020
Authorization: Bearer <token>
Accept-Language: gu
```

#### Response (When Backend Returns Localized Fields Directly):
```json
{
  "IsSuccess": true,
  "Message": "Temples retrieved successfully.",
  "Data": {
    "docs": [
      {
        "_id": "64e0a7f12345678901234567",
        "name": "સોમનાથ મહાદેવ મંદિર",
        "shortDescription": "પ્રથમ જ્યોતિર્લિંગ સોમનાથ પાટણ",
        "description": "પ્રભાસ પાટણ, સૌરાષ્ટ્રમાં આવેલું ભગવાન શિવનું પવિત્ર પ્રથમ જ્યોતિર્લિંગ તીર્થધામ.",
        "city": "વેરાવળ",
        "state": "ગુજરાત",
        "country": "ભારત",
        "address": "પ્રભાસ પાટણ, વેરાવળ, ગુજરાત",
        "bannerImage": "uploads/temple/somnath.jpg",
        "latitude": 20.8880,
        "longitude": 70.4012,
        "status": true
      }
    ],
    "totalDocs": 1,
    "page": 1
  }
}
```

#### Response (When Backend Returns Multilingual Object Format):
```json
{
  "IsSuccess": true,
  "Message": "Temples retrieved successfully.",
  "Data": {
    "docs": [
      {
        "_id": "64e0a7f12345678901234567",
        "name": {
          "en": "Somnath Mahadev Temple",
          "hi": "सोमनाथ महादेव मंदिर",
          "gu": "સોમનાથ મહાદેવ મંદિર",
          "mr": "सोमनाथ महादेव मंदिर"
        },
        "description": {
          "en": "First among the twelve Aadi Jyotirlingas of Lord Shiva.",
          "hi": "भगवान शिव के बारह ज्योतिर्लिंगों में से प्रथम ज्योतिर्लिंग।",
          "gu": "ભગવાન શિવના બાર જ્યોતિર્લિંગોમાં પ્રથમ જ્યોતિર્લિંગ.",
          "mr": "भगवान शिवांच्या बारा ज्योतिर्लिंगांपैकी पहिले ज्योतिर्लिंग."
        },
        "city": "Veraval",
        "state": "Gujarat",
        "bannerImage": "uploads/temple/somnath.jpg"
      }
    ]
  }
}
```
*Note: The Flutter client's `LocalizedApiHelper.parse()` is engineered to seamlessly parse **both** of the above structures without failure.*

---

## 6. Client Fallback & Fault-Tolerance Strategy

Even before backend multilingual data is fully populated, the Flutter application must uphold:
1. **Zero-Blank Policy**: Content must never render as blank text or null.
2. **Defensive Fallback Priority**:
   ```
   1. Exact Match: value[currentLanguageCode] (e.g. 'gu')
   2. Fallback Language 1: value['en']
   3. Fallback Language 2: value['hi']
   4. First Available Non-Empty String in response map
   5. Raw String value (if backend returns single scalar string)
   6. Fallback Default (e.g. 'Devotional Yatra', 'Bhajan')
   ```
3. **Graceful Handling of Mixed Payloads**: If a temple has a Gujarati title but English description, the client parses the Gujarati title and smoothly falls back to the English description without error.
