import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'language_manager.dart';

class DynamicTranslationService extends ChangeNotifier {
  DynamicTranslationService._internal();
  static final DynamicTranslationService instance = DynamicTranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();

  // In-memory cache: targetLang -> (cleanKey -> translatedText)
  final Map<String, Map<String, String>> _cache = {
    'gu': {},
    'hi': {},
    'mr': {},
  };

  // Set of in-flight translation requests to avoid duplicate network calls
  final Set<String> _inFlightRequests = {};

  bool _isInitialized = false;
  Timer? _debounceSaveTimer;

  // Common high-frequency UI strings pre-seeded for instantaneous 0ms display
  static const Map<String, Map<String, String>> _seedUiDictionary = {
    'home': {'gu': 'હોમ', 'hi': 'होम', 'mr': 'होम'},
    'darshan': {'gu': 'દર્શન', 'hi': 'दर्शन', 'mr': 'दर्शन'},
    'live darshan': {'gu': 'લાઈવ દર્શન', 'hi': 'लाइव दर्शन', 'mr': 'थेट दर्शन'},
    'yatra': {'gu': 'યાત્રા', 'hi': 'यात्रा', 'mr': 'यात्रा'},
    'utsav': {'gu': 'ઉત્સવ', 'hi': 'उत्सव', 'mr': 'उत्सव'},
    'profile': {'gu': 'પ્રોફાઇલ', 'hi': 'प्रोफाइल', 'mr': 'प्रोफाइल'},
    'jap': {'gu': 'જપ', 'hi': 'जप', 'mr': 'जप'},
    'granth': {'gu': 'ગ્રંથ', 'hi': 'ग्रंथ', 'mr': 'ग्रंथ'},
    'bhajan': {'gu': 'ભજન', 'hi': 'भजन', 'mr': 'भजन'},
    'search': {'gu': 'શોધો', 'hi': 'खोजें', 'mr': 'शोधा'},
    'all': {'gu': 'બધા', 'hi': 'सभी', 'mr': 'सर्व'},
    'active': {'gu': 'સક્રિય', 'hi': 'सक्रिय', 'mr': 'સક્રિય'},
    'upcoming': {'gu': 'આગામી', 'hi': 'आगामी', 'mr': 'आगामी'},
    'register': {'gu': 'નોંધણી કરો', 'hi': 'रजिस्टर करें', 'mr': 'नोंदणी करा'},
    'register open': {'gu': 'રજિસ્ટ્રેશન ઓપન', 'hi': 'रजिस्ट्रेशन ओपन', 'mr': 'नोंदणी सुरू'},
    'register now': {'gu': 'હમણાં નોંધણી કરો', 'hi': 'अभी रजिस्टर करें', 'mr': 'आत्ता नोंदणी करा'},
    'top mandals': {'gu': 'ટોપ મંડળો', 'hi': 'टॉप मंडल', 'mr': 'अव्वल मंडळे'},
    'leaderboard': {'gu': 'લીડરબોર્ડ', 'hi': 'લીડરબોર્ડ', 'mr': 'લીડરબોર્ડ'},
    'status': {'gu': 'સ્ટેટસ', 'hi': 'स्थिति', 'mr': 'स्थिती'},
    'save': {'gu': 'સાચવો', 'hi': 'सहेजें', 'mr': 'जतन करा'},
    'cancel': {'gu': 'રદ કરો', 'hi': 'रद्द करें', 'mr': 'रद्द करा'},
    'close': {'gu': 'બંધ કરો', 'hi': 'बंद करें', 'mr': 'बंद करा'},
    'submit': {'gu': 'સબમિટ કરો', 'hi': 'सबमिट करें', 'mr': 'प्रस्तुत करा'},
    'settings': {'gu': 'સેટિંગ્સ', 'hi': 'सेटिंग्स', 'mr': 'सेटिंग्ज'},
    'help & support': {'gu': 'મદદ અને સપોર્ટ', 'hi': 'सहायता और समर्थन', 'mr': 'मदत आणि समर्थन'},
    'language': {'gu': 'ભાષા', 'hi': 'भाषा', 'mr': 'भाषा'},
    'choose language': {'gu': 'ભાષા પસંદ કરો', 'hi': 'भाषा चुनें', 'mr': 'भाषा निवडा'},
    'logout': {'gu': 'લૉગ આઉટ', 'hi': 'लॉग आउट', 'mr': 'लॉग आउट'},
    'share': {'gu': 'શેર કરો', 'hi': 'शेयर करें', 'mr': 'शेअर करा'},
    'view all': {'gu': 'બધા જુઓ', 'hi': 'सभी देखें', 'mr': 'सर्व पहा'},
    'temples': {'gu': 'મંદિરો', 'hi': 'मंदिर', 'mr': 'मंदिरे'},
    'festival': {'gu': 'ઉત્સવ', 'hi': 'त्योहार', 'mr': 'सण'},
    'festivals': {'gu': 'ઉત્સવો', 'hi': 'त्योहार', 'mr': 'સણ'},
    'devotees': {'gu': 'ભક્તો', 'hi': 'ભક્ત', 'mr': 'ભક્ત'},
    'aarti': {'gu': 'આરતી', 'hi': 'आरती', 'mr': 'आरती'},
    'morning aarti': {'gu': 'પ્રભાત આરતી', 'hi': 'प्रातः आरती', 'mr': 'सकाळची आरती'},
    'evening aarti': {'gu': 'સાંજની આરતી', 'hi': 'संध्या आरती', 'mr': 'संध्याकाळची आरती'},
    'popular': {'gu': 'લોકપ્રિય', 'hi': 'लोकप्रिय', 'mr': 'લોકપ્રિય'},
    'live': {'gu': 'લાઈવ', 'hi': 'लाइव', 'mr': 'थेट'},
    'offline': {'gu': 'ઓફલાઇન', 'hi': 'ऑफलाइन', 'mr': 'ऑफलाइन'},
    'verified': {'gu': 'ચકાસાયેલ', 'hi': 'सत्यापित', 'mr': 'सत्यापित'},
    // Darshan Filters & Location Bottom Sheet
    'filter by location': {'gu': 'સ્થળ મુજબ ફિલ્ટર કરો', 'hi': 'स्थान के अनुसार फ़िल्टर करें', 'mr': 'स्थानानुसार फिल्टर करा'},
    'choose state and city to explore temples': {'gu': 'મંદિરો જોવા માટે રાજ્ય અને શહેર પસંદ કરો', 'hi': 'मंदिर देखने के लिए राज्य और शहर चुनें', 'mr': 'मंदिरे पाहण्यासाठी राज्य आणि शहर निवडा'},
    'select state': {'gu': 'રાજ્ય પસંદ કરો', 'hi': 'राज्य चुनें', 'mr': 'राज्य निवडा'},
    'all states': {'gu': 'બધા રાજ્યો', 'hi': 'सभी राज्य', 'mr': 'सर्व राज्ये'},
    'select city / area': {'gu': 'શહેર / વિસ્તાર પસંદ કરો', 'hi': 'शहर / क्षेत्र चुनें', 'mr': 'शहर / भाग निवडा'},
    'select a state first to view cities': {'gu': 'શહેરો જોવા માટે પહેલા રાજ્ય પસંદ કરો', 'hi': 'शहर देखने के लिए पहले राज्य चुनें', 'mr': 'शहरे पाहण्यासाठी आधी राज्य निवडा'},
    'all cities': {'gu': 'બધા શહેરો', 'hi': 'सभी शहर', 'mr': 'सर्व शहरे'},
    'reset': {'gu': 'રીસેટ', 'hi': 'रीसेट', 'mr': 'रीसेट'},
    'apply filter': {'gu': 'ફિલ્ટર લાગુ કરો', 'hi': 'फ़िल्टर लागू करें', 'mr': 'फिल्टर लागू करा'},
    'start darshan': {'gu': 'દર્શન શરૂ કરો', 'hi': 'दर्शन शुरू करें', 'mr': 'दर्शन सुरू करा'},
    'recent searches': {'gu': 'તાજેતરની શોધો', 'hi': 'हाल की खोजें', 'mr': 'अलीकडील शोध'},
    'clear all': {'gu': 'બધું સાફ કરો', 'hi': 'सभी साफ करें', 'mr': 'सर्व साफ करा'},
    'clear filter': {'gu': 'ફિલ્ટર હટાવો', 'hi': 'फ़िल्टर हटाएं', 'mr': 'फिल्टर काढा'},
    'retry': {'gu': 'ફરી પ્રયાસ કરો', 'hi': 'पुनः प्रयास करें', 'mr': 'पुन्हा प्रयत्न करा'},
    'failed to load darshan slots.': {'gu': 'દર્શન સ્લોટ લોડ કરવામાં નિષ્ફળ.', 'hi': 'दर्शन स्लॉट लोड करने में विफल।', 'mr': 'दर्शन स्लॉट लोड करण्यात अयशस्वी.'},
    'no temples found in this location': {'gu': 'આ સ્થળે કોઈ મંદિર મળ્યું નથી', 'hi': 'इस स्थान पर कोई मंदिर नहीं मिला', 'mr': 'या ठिकाणी कोणतेही मंदिर आढळले नाही'},
    'there is not any temple in the selected state or city.': {'gu': 'પસંદ કરેલા રાજ્ય અથવા શહેરમાં કોઈ મંદિર નથી.', 'hi': 'चयनित राज्य या शहर में कोई मंदिर नहीं है।', 'mr': 'निवडलेल्या राज्यात किंवा शहरात कोणतेही मंदिर नाही.'},
    // Home Carousel & Stream States
    'checking live streams...': {'gu': 'લાઈવ સ્ટ્રીમ તપાસી રહ્યા છીએ...', 'hi': 'लाइव स्ट्रीम चेक कर रहे हैं...', 'mr': 'थेट प्रवाह तपासत आहे...'},
    'aarti soon': {'gu': 'આરતી ટૂંક સમયમાં', 'hi': 'आरती जल्द ही', 'mr': 'आरती लवकरच'},
    'no live darshan right now': {'gu': 'હાલમાં કોઈ લાઈવ દર્શન નથી', 'hi': 'अभी कोई लाइव दर्शन नहीं है', 'mr': 'आता थेट दर्शन उपलब्ध नाही'},
    'all temple streams are currently off-air. live streams will resume automatically.': {'gu': 'બધા મંદિરના પ્રસારણ હાલમાં બંધ છે. લાઈવ શરૂ થતાં જ આપમેળે દેખાશે.', 'hi': 'सभी मंदिर प्रसारण वर्तमान में बंद हैं। लाइव शुरू होते ही अपने आप दिखाई देगा।', 'mr': 'सर्व मंदिर प्रसारण सध्या बंद आहे. थेट सुरू होताच आपोआप दिसेल.'},
    'explore temples': {'gu': 'મંદિરો જુઓ', 'hi': 'मंदिर देखें', 'mr': 'मंदिरे पहा'},
    'search gods, temples, bhajans...': {'gu': 'ભગવાન, મંદિર, ભજન શોધો...', 'hi': 'भगवान, मंदिर, भजन खोजें...', 'mr': 'देव, मंदिर, भजने शोधा...'},
    'search gods, temples...': {'gu': 'ભગવાન, મંદિર શોધો...', 'hi': 'भगवान, मंदिर खोजें...', 'mr': 'देव, मंदिर शोधा...'},
    'search mandals, areas, cities...': {'gu': 'મંડળ, વિસ્તાર, શહેર શોધો...', 'hi': 'मंडल, क्षेत्र, शहर खोजें...', 'mr': 'मंडळ, भाग, शहर शोधा...'},
    'popular searches': {'gu': 'લોકપ્રિય શોધો', 'hi': 'लोकप्रिय खोजें', 'mr': 'लोकप्रिय शोध'},
    'searching temples, japs, yatras & bhajans...': {'gu': 'મંદિરો, જાપ, યાત્રાઓ અને ભજનો શોધી રહ્યા છીએ...', 'hi': 'मंदिर, जाप, यात्रा और भजन खोज रहे हैं...', 'mr': 'मंदिरे, जाप, यात्रा आणि भजने शोधत आहे...'},
    'no results found for': {'gu': 'માટે કોઈ પરિણામ મળ્યું નથી', 'hi': 'के लिए कोई परिणाम नहीं मिला', 'mr': 'साठी कोणतेही निकाल आढळले नाहीत'},
    'try searching with another temple, deity, or yatra': {'gu': 'અન્ય મંદિર, દેવતા અથવા યાત્રા શોધી જુઓ', 'hi': 'किसी अन्य मंदिर, देवता या यात्रा को खोजें', 'mr': 'इतर मंदिर, देव किंवा यात्रा शोधून पहा'},
    'clear search': {'gu': 'શોધ સાફ કરો', 'hi': 'खोज साफ करें', 'mr': 'शोध साफ करा'},
    'temple darshan': {'gu': 'મંદિર દર્શન', 'hi': 'मंदिर दर्शन', 'mr': 'मंदिर दर्शन'},
    'sacred darshan': {'gu': 'પવિત્ર દર્શન', 'hi': 'पवित्र दर्शन', 'mr': 'पवित्र दर्शन'},
    '108 jap': {'gu': '૧૦૮ જાપ', 'hi': '१०८ जाप', 'mr': '१०८ जाप'},
    'sacred walk': {'gu': 'પવિત્ર પદયાત્રા', 'hi': 'पवित्र पदयात्रा', 'mr': 'पवित्र पदयात्रा'},
    'pilgrimage': {'gu': 'તીર્થયાત્રા', 'hi': 'तीर्थयात्रा', 'mr': 'तीर्थयात्रा'},
    'notifications': {'gu': 'સૂચનાઓ', 'hi': 'सूचनाएं', 'mr': 'सूचना'},
    'mark read': {'gu': 'વાંચેલું માર્ક કરો', 'hi': 'पढ़ा हुआ चिह्नित करें', 'mr': 'वाचले म्हणून चिन्हांकित करा'},
    'mark as read': {'gu': 'વાંચેલું માર્ક કરો', 'hi': 'पढ़ा हुआ चिह्नित करें', 'mr': 'वाचले म्हणून चिन्हांकित करा'},
    'no new notifications right now 🙏': {'gu': 'હાલમાં કોઈ નવી સૂચના નથી 🙏', 'hi': 'अभी कोई नई सूचना नहीं है 🙏', 'mr': 'सध्या कोणतीही नवीन सूचना नाही 🙏'},
    'view all notifications': {'gu': 'બધી સૂચનાઓ જુઓ', 'hi': 'सभी सूचनाएं देखें', 'mr': 'सर्व सूचना पहा'},
    'good morning': {'gu': 'શુભ પ્રભાત', 'hi': 'शुभ प्रभात', 'mr': 'शुभ सकाळ'},
    'good afternoon': {'gu': 'શુભ બપોર', 'hi': 'शुभ दोपहर', 'mr': 'शुभ दुपार'},
    'good evening': {'gu': 'શુભ સાંજ', 'hi': 'शुभ संध्या', 'mr': 'शुभ संध्याकाळ'},
    'jai shree ram': {'gu': 'જય શ્રી રામ', 'hi': 'जय श्री राम', 'mr': 'जय श्री राम'},
    'dev diwali': {'gu': 'દેવ દિવાળી', 'hi': 'देव दिवाली', 'mr': 'देव दिवाळी'},
    'christmas': {'gu': 'ક્રિસમસ', 'hi': 'क्रिसमस', 'mr': 'ख्रिसमस'},
    'mandal approved': {'gu': 'મંડળ મંજૂર થયેલ', 'hi': 'मंडल स्वीकृत', 'mr': 'मंडळ मंजूर'},
    'registration rejected': {'gu': 'નોંધણી અસ્વીકૃત', 'hi': 'पंजीकरण अस्वीकृत', 'mr': 'नोंदणी नाकारली'},
    'verification in progress ⏳': {'gu': 'ચકાસણી ચાલુ છે ⏳', 'hi': 'सत्यापन जारी है ⏳', 'mr': 'पडताळणी सुरू आहे ⏳'},
    'registrations open': {'gu': 'નોંધણી શરૂ છે', 'hi': 'पंजीकरण खुला है', 'mr': 'नोंदणी सुरू आहे'},
    'registrations closed': {'gu': 'નોંધણી બંધ છે', 'hi': 'पंजीकरण बंद है', 'mr': 'नोंदणी बंद आहे'},
    'no active festivals today': {'gu': 'આજે કોઈ સક્રિય ઉત્સવ નથી', 'hi': 'आज कोई सक्रिय त्योहार नहीं है', 'mr': 'आज कोणताही सक्रिय उत्सव नाही'},
    'no registrations open currently': {'gu': 'હાલમાં કોઈ નોંધણી ઉપલબ્ધ નથી', 'hi': 'वर्तमान में कोई पंजीकरण खुला नहीं है', 'mr': 'सध्या कोणतीही नोंदणी खुली नाही'},
    'view register open festivals': {'gu': 'નોંધણી શરૂ હોય તેવા ઉત્સવો જુઓ', 'hi': 'पंजीकरण खुले त्योहार देखें', 'mr': 'नोंदणी सुरू असलेले उत्सव पहा'},
    'no top mandals yet': {'gu': 'હજુ સુધી કોઈ ટોપ મંડળ નથી', 'hi': 'अभी तक कोई शीर्ष मंडल नहीं है', 'mr': 'अद्याप कोणतेही अव्वल मंडळ नाही'},
    'top mandals will be featured when an active festival begins.': {'gu': 'સક્રિય ઉત્સવ શરૂ થતાં ટોપ મંડળો અહીં દર્શાવવામાં આવશે.', 'hi': 'सक्रिय त्योहार शुरू होने पर शीर्ष मंडलों को दिखाया जाएगा।', 'mr': 'सक्रिय उत्सव सुरू झाल्यावर अव्वल मंडळे येथे दिसतील.'},
    'new festival details will be available here soon.': {'gu': 'નવા ઉત્સવની વિગતો ટૂંક સમયમાં અહીં ઉપલબ્ધ થશે.', 'hi': 'नए त्योहार का विवरण जल्द ही यहां उपलब्ध होगा।', 'mr': 'नवीन उत्सवाचे तपशील लवकरच येथे उपलब्ध होतील.'},
    'new festival registrations will appear here when opened.': {'gu': 'નવા ઉત્સવનું રજિસ્ટ્રેશન શરૂ થતાં અહીં જોવા મળશે.', 'hi': 'नया पंजीकरण शुरू होने पर यहाँ दिखेगा।', 'mr': 'नवीन नोंदणी सुरू झाल्यावर येथे दिसेल.'},
    'there is not any temple': {'gu': 'કોઈ મંદિર નથી', 'hi': 'कोई मंदिर नहीं है', 'mr': 'कोणतेही मंदिर नाही'},
    'no darshans found': {'gu': 'કોઈ દર્શન મળ્યા નથી', 'hi': 'कोई दर्शन नहीं मिला', 'mr': 'कोणतेही दर्शन आढळले नाही'},
    'no temples found matching your selected location.': {'gu': 'પસંદ કરેલા સ્થળે કોઈ મંદિર મળ્યું નથી.', 'hi': 'आपके चयनित स्थान पर कोई मंदिर नहीं मिला।', 'mr': 'तुमच्या निवडलेल्या ठिकाणी कोणतेही मंदिर आढळले नाही.'},
    'no temple darshans currently available.': {'gu': 'હાલમાં કોઈ મંદિર દર્શન ઉપલબ્ધ નથી.', 'hi': 'वर्तमान में कोई मंदिर दर्शन उपलब्ध नहीं है।', 'mr': 'सध्या कोणतेही मंदिर दर्शन उपलब्ध नाही.'},
    'mantra': {'gu': 'મંત્ર', 'hi': 'मंत्र', 'mr': 'मंत्र'},
    'new': {'gu': 'નવી', 'hi': 'नई', 'mr': 'नवीन'},
    'all states (entire india)': {'gu': 'બધા રાજ્યો (સમગ્ર ભારત)', 'hi': 'सभी राज्य (संपूर्ण भारत)', 'mr': 'सर्व राज्ये (संपूर्ण भारत)'},
    'all cities in': {'gu': 'બધા શહેરો', 'hi': 'सभी शहर', 'mr': 'सर्व शहरे'},
    // Jap Terms
    'bharat pray jap': {'gu': 'ભારત પ્રે જાપ', 'hi': 'भारत प्रे जाप', 'mr': 'भारत प्रे जप'},
    'admin jap': {'gu': 'ભારત પ્રે જાપ', 'hi': 'भारत प्रे जाप', 'mr': 'भारत प्रे जप'},
    'your custom jap': {'gu': 'તમારા કસ્ટમ જાપ', 'hi': 'आपके कस्टम जाप', 'mr': 'तुमचे सानुकूल जप'},
    'create custom jap': {'gu': 'કસ્ટમ જાપ બનાવો', 'hi': 'कस्टम जाप बनाएं', 'mr': 'सानुकूल जप तयार करा'},
    'chant': {'gu': 'જાપ કરો', 'hi': 'जाप करें', 'mr': 'जप करा'},
    'effect': {'gu': 'ઇફેક્ટ', 'hi': 'इफेक्ट', 'mr': 'प्रभाव'},
    "reset today's jap": {'gu': 'આજનો જાપ રીસેટ કરો', 'hi': 'आज का जाप रीसेट करें', 'mr': 'आजचा जप रीसेट करा'},
    'search gods, temples, mantras...': {'gu': 'ભગવાન, મંદિર, મંત્ર શોધો...', 'hi': 'भगवान, मंदिर, मंत्र खोजें...', 'mr': 'देव, मंदिर, मंत्र शोधा...'},
    'no custom jap yet': {'gu': 'હજુ સુધી કોઈ કસ્ટમ જાપ નથી', 'hi': 'अभी तक कोई कस्टम जाप नहीं है', 'mr': 'अद्याप कोणताही सानुकूल जप नाही'},
    'no bharat pray jap available': {'gu': 'કોઈ ભારત પ્રે જાપ ઉપલબ્ધ નથી', 'hi': 'कोई भारत प्रे जाप उपलब्ध नहीं है', 'mr': 'कोणताही भारत प्रे जप उपलब्ध नाही'},
    'no admin jap available': {'gu': 'કોઈ ભારત પ્રે જાપ ઉપલબ્ધ નથી', 'hi': 'कोई भारत प्रे जाप उपलब्ध नहीं है', 'mr': 'कोणताही भारत प्रे जप उपलब्ध नाही'},
    'ram': {'gu': 'રામ', 'hi': 'राम', 'mr': 'राम'},
    'radha': {'gu': 'રાધા', 'hi': 'राधा', 'mr': 'राधा'},
    'krishna': {'gu': 'કૃષ્ણ', 'hi': 'कृष्ण', 'mr': 'कृष्ण'},
    // Yatra Terms
    'search your yatra destination': {'gu': 'તમારી યાત્રાનું સ્થળ શોધો', 'hi': 'अपनी यात्रा का गंतव्य खोजें', 'mr': 'तुमचे यात्रा गंतव्य शोधा'},
    'create group': {'gu': 'ગ્રુપ બનાવો', 'hi': 'ग्रुप बनाएं', 'mr': 'गट तयार करा'},
    'my groups': {'gu': 'મારા ગ્રુપ', 'hi': 'मेरे ग्रुप', 'mr': 'माझे गट'},
    'popular yatra': {'gu': 'લોકપ્રિય યાત્રા', 'hi': 'लोकप्रिय यात्रा', 'mr': 'लोकप्रिय यात्रा'},
    'continue yatra': {'gu': 'યાત્રા ચાલુ રાખો', 'hi': 'यात्रा जारी रखें', 'mr': 'यात्रा चालू ठेवा'},
    'start yatra': {'gu': 'યાત્રા શરૂ કરો', 'hi': 'यात्रा शुरू करें', 'mr': 'यात्रा सुरू करा'},
    'refresh': {'gu': 'રીફ્રેશ', 'hi': 'रिफ्रेश', 'mr': 'रिफ्रेश'},
    'progress': {'gu': 'પ્રગતિ', 'hi': 'प्रगति', 'mr': 'प्रगती'},
    'steps': {'gu': 'ડગલાં', 'hi': 'कदम', 'mr': 'पावले'},
    'days': {'gu': 'દિવસ', 'hi': 'दिन', 'mr': 'दिवस'},
    // Mandal Terms
    'admin approved': {'gu': 'એડમિન દ્વારા મંજૂર', 'hi': 'एडमिन द्वारा स्वीकृत', 'mr': 'अ‍ॅडमिन मान्यताप्राप्त'},
    'official spiritual organisation': {'gu': 'સત્તાવાર આધ્યાત્મિક સંસ્થા', 'hi': 'आधिकारिक आध्यात्मिक संगठन', 'mr': 'अधिकृत आध्यात्मिक संस्था'},
    'posts': {'gu': 'પોસ્ટ', 'hi': 'पोस्ट', 'mr': 'पोस्ट'},
    'reels': {'gu': 'રીલ્સ', 'hi': 'रील्स', 'mr': 'रील्स'},
    'lives': {'gu': 'લાઈવ', 'hi': 'लाइव', 'mr': 'लाईव्ह'},
    'add post': {'gu': 'પોસ્ટ ઉમેરો', 'hi': 'पोस्ट जोड़ें', 'mr': 'पोस्ट जोडा'},
    'add reel': {'gu': 'રીલ ઉમેરો', 'hi': 'रील जोड़ें', 'mr': 'रील जोडा'},
    'go live': {'gu': 'લાઈવ દર્શન', 'hi': 'लाइव जाएं', 'mr': 'लाईव्ह जा'},
    'share mandal': {'gu': 'મંડળ શેર કરો', 'hi': 'मंडल शेयर करें', 'mr': 'मंडळ शेअर करा'},
    'mandal info': {'gu': 'મંડળ માહિતી', 'hi': 'मंडल जानकारी', 'mr': 'मंडळ माहिती'},
    'no posts yet': {'gu': 'હજુ સુધી કોઈ પોસ્ટ નથી', 'hi': 'अभी तक कोई पोस्ट नहीं', 'mr': 'अद्याप कोणतीही पोस्ट नाही'},
    'no reels yet': {'gu': 'હજુ સુધી કોઈ રીલ નથી', 'hi': 'अभी तक कोई रील नहीं', 'mr': 'अद्याप कोणतीही रील नाही'},
    'no live streams yet': {'gu': 'હજુ સુધી કોઈ લાઈવ સ્ટ્રીમ નથી', 'hi': 'अभी तक कोई लाइव स्ट्रीम नहीं', 'mr': 'अद्याप कोणतेही लाईव्ह स्ट्रीम नाही'},
    'live stream broadcasts & history': {'gu': 'લાઈવ સ્ટ્રીમ પ્રસારણ અને ઇતિહાસ', 'hi': 'लाइव स्ट्रीम प्रसारण एवं इतिहास', 'mr': 'लाईव्ह स्ट्रीम प्रक्षेपण आणि इतिहास'},
    'official registration certificate': {'gu': 'સત્તાવાર નોંધણી પ્રમાણપત્ર', 'hi': 'आधिकारिक पंजीकरण प्रमाणपत्र', 'mr': 'अधिकृत नोंदणी प्रमाणपत्र'},
    'registration number:': {'gu': 'નોંધણી નંબર:', 'hi': 'पंजीकरण संख्या:', 'mr': 'नोंदणी क्रमांक:'},
    'status:': {'gu': 'સ્થિતિ:', 'hi': 'स्थिति:', 'mr': 'स्थिती:'},
    'approved date:': {'gu': 'મંજૂરી તારીખ:', 'hi': 'स्वीकृति तिथि:', 'mr': 'मंजूरी तारीख:'},
    'mandal president:': {'gu': 'મંડળ પ્રમુખ:', 'hi': 'मंडल अध्यक्ष:', 'mr': 'मंडळ अध्यक्ष:'},
    'official phone:': {'gu': 'સત્તાવાર ફોન:', 'hi': 'आधिकारिक फ़ोन:', 'mr': 'अधिकृत फोन:'},
    'location:': {'gu': 'સ્થળ:', 'hi': 'स्थान:', 'mr': 'स्थान:'},
    'approved by bharat pray admin ✅': {'gu': 'ભારત પ્રે એડમિન દ્વારા મંજૂર ✅', 'hi': 'भारत प्रे एडमिन द्वारा स्वीकृत ✅', 'mr': 'भारत प्रे अ‍ॅडमिन मान्यताप्राप्त ✅'},
    'pending verification ⏳': {'gu': 'ચકાસણી બાકી ⏳', 'hi': 'सत्यापन लंबित ⏳', 'mr': 'पडताळणी प्रलंबित ⏳'},
    'rejected by bharat pray admin ❌': {'gu': 'ભારત પ્રે એડમિન દ્વારા અસ્વીકાર ❌', 'hi': 'भारत प्रे एडमिन द्वारा अस्वीकृत ❌', 'mr': 'भारत प्रे अ‍ॅડમિન નાકારલે ❌'},
    'live broadcast options': {'gu': 'લાઈવ પ્રસારણ વિકલ્પો', 'hi': 'लाइव प्रसारण विकल्प', 'mr': 'लाईव्ह प्रक्षेपण पर्याय'},
    'instant live': {'gu': 'તાત્કાલિક લાઈવ', 'hi': 'तुरंत लाइव', 'mr': 'तात्काळ लाईव्ह'},
    'schedule live': {'gu': 'લાઈવ શેડ્યૂલ કરો', 'hi': 'लाइव शेड्यूल करें', 'mr': 'लाईव्ह शेड्युल करा'},
    'go live now': {'gu': 'હમણાં લાઈવ જાઓ', 'hi': 'अभी लाइव जाएं', 'mr': 'आत्ता लाईव्ह जा'},
    'set time & date': {'gu': 'સમય અને તારીખ સેટ કરો', 'hi': 'समय और तिथि सेट करें', 'mr': 'वेळ आणि तारीख सेट करा'},
    'instant live broadcast': {'gu': 'તાત્કાલિક લાઈવ પ્રસારણ', 'hi': 'तुरंत लाइव प्रसारण', 'mr': 'तात्काळ लाईव्ह प्रक्षेपण'},
    'schedule live broadcast': {'gu': 'લાઈવ પ્રસારણ શેડ્યૂલ કરો', 'hi': 'लाइव प्रसारण शेड्यूल करें', 'mr': 'लाईव्ह प्रक्षेपण शेड्युल करा'},
    'live stream / aarti name': {'gu': 'લાઈવ સ્ટ્રીમ / આરતીનું નામ', 'hi': 'लाइव स्ट्रीम / आरती का नाम', 'mr': 'लाईव्ह स्ट्रीम / आरतीचे नाव'},
    'live event / puja name': {'gu': 'લાઈવ કાર્યક્રમ / પૂજાનું નામ', 'hi': 'लाइव कार्यक्रम / पूजा का नाम', 'mr': 'लाईव्ह कार्यक्रम / पूजेचे नाव'},
    'start live camera now': {'gu': 'હમણાં લાઈવ કેમેરા શરૂ કરો', 'hi': 'अभी लाइव कैमरा शुरू करें', 'mr': 'आत्ता लाईव्ह कॅमेरा सुरू करा'},
    'event date': {'gu': 'કાર્યક્રમ તારીખ', 'hi': 'कार्यक्रम तिथि', 'mr': 'कार्यक्रम तारीख'},
    'event time': {'gu': 'કાર્યક્રમ સમય', 'hi': 'कार्यक्रम समय', 'mr': 'कार्यक्रम वेळ'},
    'schedule & notify devotees': {'gu': 'શેડ્યૂલ કરો અને ભક્તોને જાણ કરો', 'hi': 'शेड्यूल करें और भक्तों को सूचित करें', 'mr': 'शेड्युल करा आणि भक्तांना सूचित करा'},
    'festival not started yet ⏳': {'gu': 'ઉત્સવ હજુ શરૂ થયો નથી ⏳', 'hi': 'उत्सव अभी शुरू नहीं हुआ ⏳', 'mr': 'उत्सव अद्याप सुरू झाला नाही ⏳'},
    'understood': {'gu': 'સમજાયું', 'hi': 'समझ गया', 'mr': 'समजले'},
    'no posts available': {'gu': 'કોઈ પોસ્ટ ઉપલબ્ધ નથી', 'hi': 'कोई पोस्ट उपलब्ध नहीं है', 'mr': 'कोणतीही पोस्ट उपलब्ध नाही'},
    'mandal profile': {'gu': 'મંડળ પ્રોફાઇલ', 'hi': 'मंडल प्रोफ़ाइल', 'mr': 'मंडळ प्रोफाइल'},
    'approved': {'gu': 'મંજૂર', 'hi': 'स्वीकृत', 'mr': 'मान्यताप्राप्त'},
    // States and Cities
    'gujarat': {'gu': 'ગુજરાત', 'hi': 'गुजरात', 'mr': 'गुजरात'},
    'maharashtra': {'gu': 'મહારાષ્ટ્ર', 'hi': 'महाराष्ट्र', 'mr': 'महाराष्ट्र'},
    'uttar pradesh': {'gu': 'ઉત્તર પ્રદેશ', 'hi': 'उत्तर प्रदेश', 'mr': 'उत्तर प्रदेश'},
    'rajasthan': {'gu': 'રાજસ્થાન', 'hi': 'राजस्थान', 'mr': 'राजस्थान'},
    'madhya pradesh': {'gu': 'મધ્ય પ્રદેશ', 'hi': 'मध्य प्रदेश', 'mr': 'मध्य प्रदेश'},
    'uttarakhand': {'gu': 'ઉત્તરાખંડ', 'hi': 'उत्तराखंड', 'mr': 'उत्तराखंड'},
    'ahmedabad': {'gu': 'અમદાવાદ', 'hi': 'अहमदाबाद', 'mr': 'अहमदाबाद'},
    'surat': {'gu': 'સુરત', 'hi': 'सूरत', 'mr': 'सूरत'},
    'vadodara': {'gu': 'વડોદરા', 'hi': 'वडोदरा', 'mr': 'वडोदरा'},
    'rajkot': {'gu': 'રાજકોટ', 'hi': 'राजकोट', 'mr': 'राजकोट'},
    'mumbai': {'gu': 'મુંબઈ', 'hi': 'मुंबई', 'mr': 'मुंबई'},
    'pune': {'gu': 'પુણે', 'hi': 'पुणे', 'mr': 'पुणे'},
    'varanasi': {'gu': 'વારાણસી', 'hi': 'वाराणसी', 'mr': 'वाराणसी'},
    'ayodhya': {'gu': 'અયોધ્યા', 'hi': 'अयोध्या', 'mr': 'अयोध्या'},
    'mathura': {'gu': 'મથુરા', 'hi': 'मथुरा', 'mr': 'मथुरा'},
    'vrindavan': {'gu': 'વૃંદાવન', 'hi': 'वृंदावन', 'mr': 'वृंदावन'},
    'dwarka': {'gu': 'દ્વારકા', 'hi': 'द्वारका', 'mr': 'द्वारका'},
    'somnath': {'gu': 'સોમનાથ', 'hi': 'સોમનાથ', 'mr': 'સોમનાથ'},
    'ujjain': {'gu': 'ઉજ્જૈન', 'hi': 'ઉજ્જૈન', 'mr': 'ઉજ્જૈન'},
    'haridwar': {'gu': 'હરિદ્વાર', 'hi': 'હરિદ્વાર', 'mr': 'હરિદ્વાર'},
    'rishikesh': {'gu': 'ઋષિકેશ', 'hi': 'ઋષિકેશ', 'mr': 'ઋષિકેશ'},
    'puri': {'gu': 'પુરી', 'hi': 'પુરી', 'mr': 'પુરી'},
    'tirupati': {'gu': 'તિરુપતિ', 'hi': 'તિરુપતિ', 'mr': 'તિરુપતી'},
    'shirdi': {'gu': 'શિરડી', 'hi': 'શિરડી', 'mr': 'શિર્ડી'},
    'kedarnath': {'gu': 'કેદારનાથ', 'hi': 'કેદારનાથ', 'mr': 'કેદારનાથ'},
    'badrinath': {'gu': 'બદ્રીનાથ', 'hi': 'બદ્રીનાથ', 'mr': 'બદ્રીનાથ'},
    'salangpur': {'gu': 'સાળંગપુર', 'hi': 'સાણંગપુર', 'mr': 'સાળંગપૂર'},
    'ambaji': {'gu': 'અંબાજી', 'hi': 'અંબાજી', 'mr': 'અંબાજી'},
    'palitana': {'gu': 'પાલીતાણા', 'hi': 'પાલીતાના', 'mr': 'પાલીતાણા'},
    'pavagadh': {'gu': 'પાવાગઢ', 'hi': 'પાવાગઢ', 'mr': 'પાવાગઢ'},
    'khodaldham': {'gu': 'ખોડલધામ', 'hi': 'ખોડલધામ', 'mr': 'ખોડલધામ'},
    'gaya': {'gu': 'ગયા', 'hi': 'गया', 'mr': 'गया'},
    'bihar': {'gu': 'બિહાર', 'hi': 'बिहार', 'mr': 'बिहार'},
    'kolkata': {'gu': 'કોલકાતા', 'hi': 'कोलकाता', 'mr': 'कोलकाता'},
    'west bengal': {'gu': 'પશ્ચિમ બંગાળ', 'hi': 'पश्चिम बंगाल', 'mr': 'पश्चिम बंगाल'},
    'bhatkal': {'gu': 'ભટકલ', 'hi': 'भटकल', 'mr': 'भटकळ'},
    'karnataka': {'gu': 'કર્ણાટક', 'hi': 'कर्नाटक', 'mr': 'कर्नाटक'},
    'guruvayur': {'gu': 'ગુરુવાયુર', 'hi': 'गुरूवायूर', 'mr': 'गुरुवायूर'},
    'kerala': {'gu': 'કેરળ', 'hi': 'केरल', 'mr': 'केरळ'},
    'tamil nadu': {'gu': 'તમિલનાડુ', 'hi': 'तमिलनाडु', 'mr': 'तमिळनाडू'},
    'andhra pradesh': {'gu': 'આંધ્ર પ્રદેશ', 'hi': 'आंध्र प्रदेश', 'mr': 'आंध्र प्रदेश'},
    'telangana': {'gu': 'તેલંગાણા', 'hi': 'तेलंगाना', 'mr': 'तेलंगणा'},
    'odisha': {'gu': 'ઓડિશા', 'hi': 'ओडिशा', 'mr': 'ओडिशा'},
    'punjab': {'gu': 'પંજાબ', 'hi': 'पंजाब', 'mr': 'पंजाब'},
    'haryana': {'gu': 'હરિયાણા', 'hi': 'हरियाणा', 'mr': 'हरियाणा'},
    'himachal pradesh': {'gu': 'હિમાચલ પ્રદેશ', 'hi': 'हिमाचल प्रदेश', 'mr': 'हिमाचल प्रदेश'},
    'delhi': {'gu': 'દિલ્હી', 'hi': 'दिल्ली', 'mr': 'दिल्ली'},
    'dixit desai': {'gu': 'દીક્ષિત દેસાઈ', 'hi': 'दीक्षित देसाई', 'mr': 'दीक्षित देसाई'},
    'dixit': {'gu': 'દીક્ષિત', 'hi': 'दीक्षित', 'mr': 'दीक्षित'},
    'desai': {'gu': 'દેસાઈ', 'hi': 'देसाई', 'mr': 'देसाई'},
    // Days and Months
    'jan': {'gu': 'જાન્યુ', 'hi': 'જન', 'mr': 'જાને'},
    'feb': {'gu': 'ફેબ્રુ', 'hi': 'ફ઼ર', 'mr': 'ફેબ્રુ'},
    'mar': {'gu': 'માર્ચ', 'hi': 'માર્ચ', 'mr': 'માર્ચ'},
    'apr': {'gu': 'એપ્રિલ', 'hi': 'અપ્રૈલ', 'mr': 'એપ્રિલ'},
    'may': {'gu': 'મે', 'hi': 'મઈ', 'mr': 'મે'},
    'jun': {'gu': 'જૂન', 'hi': 'જૂન', 'mr': 'જૂન'},
    'jul': {'gu': 'જુલાઈ', 'hi': 'જુલાઈ', 'mr': 'જુલાઈ'},
    'aug': {'gu': 'ઓગસ્ટ', 'hi': 'અગસ્ત', 'mr': 'ઓગસ્ટ'},
    'sep': {'gu': 'સપ્ટે', 'hi': 'સિત', 'mr': 'સપ્ટેં'},
    'oct': {'gu': 'ઓક્ટો', 'hi': 'અક્તૂ', 'mr': 'ઓક્ટો'},
    'nov': {'gu': 'નવે', 'hi': 'નવ', 'mr': 'નોવ્હેં'},
    'dec': {'gu': 'ડિસે', 'hi': 'દિસ', 'mr': 'ડિસેં'},
    'mon': {'gu': 'સોમ', 'hi': 'સોમ', 'mr': 'સોમ'},
    'tue': {'gu': 'મંગળ', 'hi': 'મંગલ', 'mr': 'મંગળ'},
    'wed': {'gu': 'બુધ', 'hi': 'બુધ', 'mr': 'બુધ'},
    'thu': {'gu': 'ગુરુ', 'hi': 'ગુરુ', 'mr': 'ગુરુ'},
    'fri': {'gu': 'શુક્ર', 'hi': 'શુક્ર', 'mr': 'શુક્ર'},
    'sat': {'gu': 'શનિ', 'hi': 'શનિ', 'mr': 'શનિ'},
    'sun': {'gu': 'રવિ', 'hi': 'રવિ', 'mr': 'રવિ'},
  };

  /// Initialize persistent storage and load cache on application launch
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final lang in ['gu', 'hi', 'mr']) {
        _cache[lang] ??= {};
        
        // 1. Seed dictionary
        for (final entry in _seedUiDictionary.entries) {
          final trans = entry.value[lang];
          if (trans != null) {
            _cache[lang]![entry.key.toLowerCase()] = trans;
          }
        }

        // 2. Load disk cache
        final savedJson = prefs.getString('dynamic_trans_cache_$lang');
        if (savedJson != null && savedJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
            for (final e in decoded.entries) {
              if (e.value != null && e.value.toString().isNotEmpty) {
                _cache[lang]![e.key.toLowerCase()] = e.value.toString();
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[DynamicTranslationService] Init error: $e');
    } finally {
      _isInitialized = true;
    }
  }

  /// Pre-warm language cache and ensure all seed translations are populated
  Future<void> prewarmLanguage(String targetLang) async {
    final lang = targetLang.toLowerCase();
    if (lang == 'en') return;
    _cache[lang] ??= {};
    for (final entry in _seedUiDictionary.entries) {
      final trans = entry.value[lang];
      if (trans != null) {
        _cache[lang]![entry.key.toLowerCase()] = trans;
      }
    }
    notifyListeners();
  }

  /// Get cached translation if available; if not, triggers background translation
  String translateSync(String text, {String? targetLang}) {
    final lang = (targetLang ?? LanguageManager.instance.currentLanguageCode).toLowerCase();
    if (lang == 'en') return text;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    final cleanKey = trimmed.toLowerCase();
    final langCache = _cache[lang];

    if (langCache != null && langCache.containsKey(cleanKey)) {
      return langCache[cleanKey]!;
    }

    // Check seed dictionary directly
    final seedMatch = _seedUiDictionary[cleanKey]?[lang];
    if (seedMatch != null && seedMatch.isNotEmpty) {
      _cache[lang] ??= {};
      _cache[lang]![cleanKey] = seedMatch;
      return seedMatch;
    }

    // Not yet in cache -> trigger async background translation
    _queueTranslation(trimmed, lang);

    return trimmed;
  }

  /// Asynchronous translation with Google Translator engine and persistent caching
  Future<String> translateAsync(String text, {String? targetLang}) async {
    final lang = (targetLang ?? LanguageManager.instance.currentLanguageCode).toLowerCase();
    if (lang == 'en') return text;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    final cleanKey = trimmed.toLowerCase();
    final langCache = _cache[lang];

    if (langCache != null && langCache.containsKey(cleanKey)) {
      return langCache[cleanKey]!;
    }

    final seedMatch = _seedUiDictionary[cleanKey]?[lang];
    if (seedMatch != null && seedMatch.isNotEmpty) {
      _cache[lang] ??= {};
      _cache[lang]![cleanKey] = seedMatch;
      return seedMatch;
    }

    try {
      final translation = await _translator.translate(trimmed, from: 'en', to: lang);
      final result = translation.text;

      _cache[lang] ??= {};
      _cache[lang]![cleanKey] = result;
      _scheduleSave(lang);
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('[DynamicTranslationService] Translation error for "$trimmed" -> $lang: $e');
      return trimmed;
    }
  }

  /// Queue a translation request without blocking the UI thread
  void _queueTranslation(String text, String targetLang) {
    final requestKey = '${targetLang}_$text';
    if (_inFlightRequests.contains(requestKey)) return;

    _inFlightRequests.add(requestKey);

    Future.microtask(() async {
      try {
        final translation = await _translator.translate(text, from: 'en', to: targetLang);
        final result = translation.text;

        _cache[targetLang] ??= {};
        _cache[targetLang]![text.trim().toLowerCase()] = result;
        _scheduleSave(targetLang);
        notifyListeners();
      } catch (e) {
        // Silently handle translation timeout or network dip
      } finally {
        _inFlightRequests.remove(requestKey);
      }
    });
  }

  /// Batch translate multiple texts (e.g. from an API response)
  Future<void> translateBatch(List<String> texts, {String? targetLang}) async {
    final lang = (targetLang ?? LanguageManager.instance.currentLanguageCode).toLowerCase();
    if (lang == 'en') return;

    final List<String> toTranslate = [];
    for (final t in texts) {
      final clean = t.trim();
      if (clean.isEmpty) continue;
      final key = clean.toLowerCase();
      if (!(_cache[lang]?.containsKey(key) ?? false)) {
        toTranslate.add(clean);
      }
    }

    if (toTranslate.isEmpty) return;

    // Concurrently translate items in chunks of 5 to avoid overloading
    const chunkSize = 5;
    for (int i = 0; i < toTranslate.length; i += chunkSize) {
      final chunk = toTranslate.skip(i).take(chunkSize);
      await Future.wait(chunk.map((item) async {
        try {
          final res = await _translator.translate(item, from: 'en', to: lang);
          _cache[lang] ??= {};
          _cache[lang]![item.toLowerCase()] = res.text;
        } catch (_) {}
      }));
    }

    _scheduleSave(lang);
    notifyListeners();
  }

  /// Debounced disk persistence to prevent excessive writes
  void _scheduleSave(String lang) {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(milliseconds: 1500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final map = _cache[lang];
        if (map != null) {
          await prefs.setString('dynamic_trans_cache_$lang', jsonEncode(map));
        }
      } catch (e) {
        debugPrint('[DynamicTranslationService] Cache save error: $e');
      }
    });
  }

  /// Called when language changes in LanguageManager
  void onLanguageChanged(String langCode) {
    notifyListeners();
  }
}
