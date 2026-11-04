import 'package:flutter/material.dart';
import 'language_manager.dart';

class LocalizedApiHelper {
  static const Map<String, Map<String, String>> _spiritualCanonicalMap = {
    // Temples & Places
    'somnath temple': {'en': 'Somnath Temple', 'hi': 'सोमनाथ मंदिर', 'gu': 'સોમનાથ મંદિર', 'mr': 'सोमनाथ मंदिर'},
    'somnath': {'en': 'Somnath', 'hi': 'सोमनाथ', 'gu': 'સોમનાથ', 'mr': 'सोमनाथ'},
    'dwarkadhish temple': {'en': 'Dwarkadhish Temple', 'hi': 'द्वारकाधीश मंदिर', 'gu': 'દ્વારકાધીશ મંદિર', 'mr': 'द्वारकाधीश मंदिर'},
    'dwarkadhish': {'en': 'Dwarkadhish', 'hi': 'द्वारकाधीश', 'gu': 'દ્વારકાધીશ', 'mr': 'द्वारकाधीश'},
    'dwarka temple': {'en': 'Dwarka Temple', 'hi': 'द्वारका मंदिर', 'gu': 'દ્વારકા મંદિર', 'mr': 'द्वारका मंदिर'},
    'dwarka': {'en': 'Dwarka', 'hi': 'द्वारका', 'gu': 'દ્વારકા', 'mr': 'द्वारका'},
    'ambaji temple': {'en': 'Ambaji Temple', 'hi': 'अंबाजी मंदिर', 'gu': 'અંબાજી મંદિર', 'mr': 'अंबाजी मंदिर'},
    'ambaji': {'en': 'Ambaji', 'hi': 'अंबाजी', 'gu': 'અંબાજી', 'mr': 'अंबाजी'},
    'mahakaleshwar temple': {'en': 'Mahakaleshwar Temple', 'hi': 'महाकालेश्वर मंदिर', 'gu': 'મહાકાલેશ્વર મંદિર', 'mr': 'महाकालेश्वर मंदिर'},
    'mahakaleshwar': {'en': 'Mahakaleshwar', 'hi': 'महाकालेश्वर', 'gu': 'મહાકાલેશ્વર', 'mr': 'महाकालेश्वर'},
    'kashi vishwanath': {'en': 'Kashi Vishwanath', 'hi': 'काशी विश्वनाथ', 'gu': 'કાશી વિશ્વનાથ', 'mr': 'काशी विश्वनाथ'},
    'akshardham temple': {'en': 'Akshardham Temple', 'hi': 'अक्षरधाम मंदिर', 'gu': 'અક્ષરધામ મંદિર', 'mr': 'अक्षरधाम मंदिर'},
    'akshardham': {'en': 'Akshardham', 'hi': 'अक्षरधाम', 'gu': 'અક્ષરધામ', 'mr': 'अक्षरधाम'},
    'shirdi sai baba': {'en': 'Shirdi Sai Baba', 'hi': 'शिरडी साईं बाबा', 'gu': 'શિરડી સાંઈ બાબા', 'mr': 'शिर्डी साई बाबा'},
    'siddhivinayak temple': {'en': 'Siddhivinayak Temple', 'hi': 'सिद्धिविनायक मंदिर', 'gu': 'સિદ્ધિવિનાયક મંદિર', 'mr': 'सिद्धिविनायक मंदिर'},
    'badrinath': {'en': 'Badrinath', 'hi': 'बद्रीनाथ', 'gu': 'બદ્રીનાથ', 'mr': 'बद्रीनाथ'},
    'kedarnath': {'en': 'Kedarnath', 'hi': 'केदारनाथ', 'gu': 'કેદારનાથ', 'mr': 'केदारनाथ'},
    'ayodhya ram mandir': {'en': 'Ayodhya Ram Mandir', 'hi': 'अयोध्या राम मंदिर', 'gu': 'અયોધ્યા રામ મંદિર', 'mr': 'अयोध्या राम मंदिर'},
    'tirupati balaji': {'en': 'Tirupati Balaji', 'hi': 'तिरुपति बालाजी', 'gu': 'તિરુપતિ બાલાજી', 'mr': 'तिरुपती बालाजी'},
    'khodaldham temple': {'en': 'Khodaldham Temple', 'hi': 'खोडलधाम मंदिर', 'gu': 'ખોડલધામ મંદિર', 'mr': 'ખોડલધામ મંદિર'},
    'khodaldham': {'en': 'Khodaldham', 'hi': 'खोडलधाम', 'gu': 'ખોડલધામ', 'mr': 'ખોડલધામ'},
    'salangpur hanuman': {'en': 'Salangpur Hanuman', 'hi': 'साळंगपुर हनुमान', 'gu': 'સાળંગપુર હનુમાન', 'mr': 'साळंगपूर हनुमान'},
    'salangpur': {'en': 'Salangpur', 'hi': 'साळंगपुर', 'gu': 'સાળંગપુર', 'mr': 'साळંગपूर'},

    // Deities
    'lord shiva': {'en': 'Lord Shiva', 'hi': 'भगवान शिव', 'gu': 'ભગવાન શિવ', 'mr': 'भगवान शिव'},
    'shiva': {'en': 'Shiva', 'hi': 'शिव', 'gu': 'શિવ', 'mr': 'शिव'},
    'lord krishna': {'en': 'Lord Krishna', 'hi': 'भगवान कृष्ण', 'gu': 'ભગવાન કૃષ્ણ', 'mr': 'भगवान कृष्ण'},
    'krishna': {'en': 'Krishna', 'hi': 'कृष्ण', 'gu': 'કૃષ્ણ', 'mr': 'कृष्ण'},
    'radha krishna': {'en': 'Radha Krishna', 'hi': 'राधा कृष्ण', 'gu': 'રાધા કૃષ્ણ', 'mr': 'રાધા કૃષ્ણ'},
    'ganesha': {'en': 'Lord Ganesha', 'hi': 'भगवान गणेश', 'gu': 'ભગવાન ગણેશ', 'mr': 'भगवान गणेश'},
    'lord ganesha': {'en': 'Lord Ganesha', 'hi': 'भगवान गणेश', 'gu': 'ભગવાન ગણેશ', 'mr': 'भगवान गणेश'},
    'hanuman': {'en': 'Lord Hanuman', 'hi': 'भगवान हनुमान', 'gu': 'ભગવાન હનુમાન', 'mr': 'भगवान हनुमान'},
    'lord hanuman': {'en': 'Lord Hanuman', 'hi': 'भगवान हनुमान', 'gu': 'ભગવાન હનુમાન', 'mr': 'भगवान हनुमान'},
    'lord ram': {'en': 'Lord Ram', 'hi': 'भगवान राम', 'gu': 'ભગવાન રામ', 'mr': 'भगवान राम'},
    'shri ram': {'en': 'Shri Ram', 'hi': 'श्री राम', 'gu': 'શ્રી રામ', 'mr': 'श्री राम'},
    'maa durga': {'en': 'Maa Durga', 'hi': 'माँ दुर्गा', 'gu': 'માઁ દુર્ગા', 'mr': 'आई दुर्गा'},
    'durga': {'en': 'Durga', 'hi': 'दुर्गा', 'gu': 'દુર્ગા', 'mr': 'दुर्गा'},
    'maa amba': {'en': 'Maa Amba', 'hi': 'माँ अम्बा', 'gu': 'માઁ અંબા', 'mr': 'आई अंबा'},
    'amba': {'en': 'Amba', 'hi': 'अम्बा', 'gu': 'અંબા', 'mr': 'अंबा'},
    'khodiyar mata': {'en': 'Khodiyar Mata', 'hi': 'खोड़ियार माता', 'gu': 'ખોડિયાર માતા', 'mr': 'ખોડિયાર માતા'},
    'lakshmi': {'en': 'Maa Lakshmi', 'hi': 'माँ लक्ष्मी', 'gu': 'માઁ લક્ષ્મી', 'mr': 'आई लक्ष्मी'},
    'saraswati': {'en': 'Maa Saraswati', 'hi': 'माँ सरस्वती', 'gu': 'માઁ સરસ્વતી', 'mr': 'आई सरस्वती'},
    'surya': {'en': 'Surya Dev', 'hi': 'सूर्य देव', 'gu': 'સૂર્ય દેવ', 'mr': 'सूर्य देव'},
    'ayyappa': {'en': 'Lord Ayyappa', 'hi': 'भगवान अय्यप्पा', 'gu': 'ભગવાન અય્યપ્પા', 'mr': 'भगवान अय्यप्पा'},

    // Yatras
    'somnath yatra': {'en': 'Somnath Yatra', 'hi': 'सोमनाथ यात्रा', 'gu': 'સોમનાથ યાત્રા', 'mr': 'सोमनाथ यात्रा'},
    'dwarka yatra': {'en': 'Dwarka Yatra', 'hi': 'द्वारका यात्रा', 'gu': 'દ્વારકા યાત્રા', 'mr': 'द्वारका यात्रा'},
    'char dham yatra': {'en': 'Char Dham Yatra', 'hi': 'चार धाम यात्रा', 'gu': 'ચાર ધામ યાત્રા', 'mr': 'चार धाम यात्रा'},
    'jyotirlinga yatra': {'en': '12 Jyotirlinga Yatra', 'hi': '१२ ज्योतिर्लिंग यात्रा', 'gu': '૧૨ જ્યોતિર્લિંગ યાત્રા', 'mr': '१२ ज्योतिर्लिंग यात्रा'},
    'panch dwarika yatra': {'en': 'Panch Dwarika Yatra', 'hi': 'पंच द्वारिका यात्रा', 'gu': 'પંચ દ્વારિકા યાત્રા', 'mr': 'पंच द्वारिका यात्रा'},

    // Festivals
    'pre navratri': {'en': 'Pre Navratri', 'hi': 'प्री नवरात्रि', 'gu': 'પ્રી નવરાત્રી', 'mr': 'प्री नवरात्री'},
    'maha navratri': {'en': 'Maha Navratri', 'hi': 'महा नवरात्रि', 'gu': 'મહા નવરાત્રી', 'mr': 'महा नवरात्री'},
    'navratri': {'en': 'Navratri', 'hi': 'नवरात्रि', 'gu': 'નવરાત્રી', 'mr': 'नवरात्री'},
    'diwali': {'en': 'Diwali', 'hi': 'दीपावली', 'gu': 'દિવાળી', 'mr': 'दिवाळी'},
    'dhanteras': {'en': 'Dhanteras', 'hi': 'धनतेरस', 'gu': 'ધનતેરસ', 'mr': 'ધનતેરસ'},
    'ganesh chaturthi': {'en': 'Ganesh Chaturthi', 'hi': 'गणेश चतुर्थी', 'gu': 'ગણેશ ચતુર્થી', 'mr': 'गणेश चतुर्थी'},
    'maha shivratri': {'en': 'Maha Shivratri', 'hi': 'महाशिवरात्रि', 'gu': 'મહાશિવરાત્રી', 'mr': 'महाशिवरात्री'},
    'janmashtami': {'en': 'Janmashtami', 'hi': 'जन्माष्टमी', 'gu': 'જન્માષ્ટમી', 'mr': 'जन्माष्टमी'},
    'hanuman jayanti': {'en': 'Hanuman Jayanti', 'hi': 'हनुमान जयंती', 'gu': 'હનુમાન જયંતી', 'mr': 'हनुमान जयंती'},
    'ram navami': {'en': 'Ram Navami', 'hi': 'राम नवमी', 'gu': 'રામ નવમી', 'mr': 'राम नवमी'},

    // Devotional / Categories
    'aarti': {'en': 'Aarti', 'hi': 'आरती', 'gu': 'આરતી', 'mr': 'आरती'},
    'chalisa': {'en': 'Chalisa', 'hi': 'चालीसा', 'gu': 'ચાલીસા', 'mr': 'चालीसा'},
    'mantra': {'en': 'Mantra', 'hi': 'मंत्र', 'gu': 'મંત્ર', 'mr': 'मंत्र'},
    'stotram': {'en': 'Stotram', 'hi': 'स्तोत्र', 'gu': 'સ્તોત્રમ', 'mr': 'स्तोत्र'},
    'dhun': {'en': 'Dhun', 'hi': 'धुन', 'gu': 'ધૂન', 'mr': 'धून'},
    'bhajan': {'en': 'Bhajan', 'hi': 'भजन', 'gu': 'ભજન', 'mr': 'भजन'},
    'katha': {'en': 'Katha', 'hi': 'कथा', 'gu': 'કથા', 'mr': 'कथा'},
    'granth': {'en': 'Granth', 'hi': 'ग्रंथ', 'gu': 'ગ્રંથ', 'mr': 'ग्रंथ'},
    'darshan': {'en': 'Darshan', 'hi': 'दर्शन', 'gu': 'દર્શન', 'mr': 'दर्शन'},
    'puja': {'en': 'Puja', 'hi': 'पूजा', 'gu': 'પૂજા', 'mr': 'पूजा'},
    'daily darshan': {'en': 'Daily Darshan', 'hi': 'दैनिक दर्शन', 'gu': 'દૈનિક દર્શન', 'mr': 'दैनिक दर्शन'},
    'live darshan': {'en': 'Live Darshan', 'hi': 'लाइव दर्शन', 'gu': 'લાઈવ દર્શન', 'mr': 'लाइव्ह दर्शन'},
    'somnath temple darshan': {'en': 'Somnath Temple Darshan', 'hi': 'सोमनाथ मंदिर दर्शन', 'gu': 'સોમનાથ મંદિર દર્શન', 'mr': 'सोमनाथ मंदिर दर्शन'},
    'dwarkadhish temple darshan': {'en': 'Dwarkadhish Temple Darshan', 'hi': 'द्वारकाधीश मंदिर दर्शन', 'gu': 'દ્વારકાધીશ મંદિર દર્શન', 'mr': 'द्वारकाधीश मंदिर दर्शन'},
    'mahakaleshwar temple darshan': {'en': 'Mahakaleshwar Temple Darshan', 'hi': 'महाकालेश्वर मंदिर दर्शन', 'gu': 'મહાકાલેશ્વર મંદિર દર્શન', 'mr': 'महाकालेश्वर मंदिर दर्शन'},
    'ambaji temple darshan': {'en': 'Ambaji Temple Darshan', 'hi': 'अंबाजी मंदिर दर्शन', 'gu': 'અંબાજી મંદિર દર્શન', 'mr': 'अंबाजी मंदिर दर्शन'},
    'salangpur hanuman darshan': {'en': 'Salangpur Hanuman Darshan', 'hi': 'साळंगपुर हनुमान दर्शन', 'gu': 'સાળંગપુર હનુમાન દર્શન', 'mr': 'साळंगपूर हनुमान दर्शन'},
    'khodaldham temple darshan': {'en': 'Khodaldham Temple Darshan', 'hi': 'खोडलधाम मंदिर दर्शन', 'gu': 'ખોડલધામ મંદિર દર્શન', 'mr': 'ખોડલધામ મંદિર દર્શન'},

    // Descriptions & Sentence Localizations
    'the first among the twelve sacred aadi jyotirlinga shrines of lord shiva.': {
      'en': 'The first among the twelve sacred Aadi Jyotirlinga shrines of Lord Shiva.',
      'hi': 'भगवान शिव के बारह पवित्र आदि ज्योतिर्लिंगों में प्रथम तीर्थधाम।',
      'gu': 'ભગવાન શિવના બાર પવિત્ર આદિ જ્યોતિર્લિંગોમાં પ્રથમ તીર્થધામ.',
      'mr': 'भगवान शिवांच्या बारा पवित्र आदि ज्योतिर्लिंगांपैकी प्रथम तीर्थक्षेत्र.'
    },
    'seek divine blessings.': {
      'en': 'Seek divine blessings.',
      'hi': 'दिव्य आशीर्वाद प्राप्त करें।',
      'gu': 'દૈવી આશીર્વાદ પ્રાપ્ત કરો.',
      'mr': 'दिव्य आशीर्वाद मिळवा.'
    },
    'the ancient sacred shrine of lord shiva located on the western coast of gujarat.': {
      'en': 'The ancient sacred shrine of Lord Shiva located on the western coast of Gujarat.',
      'hi': 'गुजरात के पश्चिमी तट पर स्थित भगवान शिव का प्राचीन पवित्र तीर्थधाम।',
      'gu': 'ગુજરાતના પશ્ચિમ સમુદ્રકાંઠે આવેલું ભગવાન શિવનું પ્રાચીન પવિત્ર તીર્થધામ.',
      'mr': 'गुजरातच्या पश्चिम किनारपट्टीवर असलेले भगवान शिवांचे प्राचीन पवित्र तीर्थक्षेत्र.'
    },

    // UI & Action Buttons
    'start darshan': {'en': 'Start Darshan', 'hi': 'दर्शन शुरू करें', 'gu': 'દર્શન શરૂ કરો', 'mr': 'दर्शन सुरू करा'},
    'live': {'en': 'Live', 'hi': 'लाइव', 'gu': 'લાઇવ', 'mr': 'लाइव्ह'},
    'offline': {'en': 'Offline', 'hi': 'ऑफ़लाइन', 'gu': 'ઓફલાઇન', 'mr': 'ऑफलाइन'},
    'devotee': {'en': 'Devotee', 'hi': 'भक्त', 'gu': 'ભક્ત', 'mr': 'भक्त'},
    'search gods, temples, bhajans...': {
      'en': 'Search gods, temples, bhajans...',
      'hi': 'भगवान, मंदिर या भजन खोजें...',
      'gu': 'ભગવાન, મંદિર અથવા ભજન શોધો...',
      'mr': 'देव, मंदिरे किंवा भजने शोधा...'
    },

    // Profile & Settings
    'my profile': {'en': 'My Profile', 'hi': 'मेरी प्रोफाइल', 'gu': 'મારી પ્રોફાઇલ', 'mr': 'माझी प्रोफाइल'},
    'total jap': {'en': 'Total Jap', 'hi': 'कुल जाप', 'gu': 'કુલ જાપ', 'mr': 'एकूण जाप'},
    'bhajans': {'en': 'Bhajans', 'hi': 'भजन', 'gu': 'ભજનો', 'mr': 'भजने'},
    'streak': {'en': 'Streak', 'hi': 'स्ट्रीक', 'gu': 'સ્ટ્રીક', 'mr': 'स्ट्रीक'},
    'yatras': {'en': 'Yatras', 'hi': 'यात्राएं', 'gu': 'યાત્રાઓ', 'mr': 'यात्रा'},
    'day': {'en': 'Day', 'hi': 'दिन', 'gu': 'દિવસ', 'mr': 'दिवस'},
    'days': {'en': 'Days', 'hi': 'दिन', 'gu': 'દિવસ', 'mr': 'दिवસ'},
    'tour': {'en': 'Tour', 'hi': 'यात्रा', 'gu': 'યાત્રા', 'mr': 'यात्रा'},
    'tours': {'en': 'Tours', 'hi': 'यात्राएं', 'gu': 'યાત્રાઓ', 'mr': 'यात्रा'},
    'mandal profile': {'en': 'Mandal Profile', 'hi': 'मंडल प्रोफाइल', 'gu': 'મંડળ પ્રોફાઇલ', 'mr': 'मंडळ प्रोफाइल'},
    'approved': {'en': 'Approved', 'hi': 'स्वीकृत', 'gu': 'મંજૂર', 'mr': 'मंजूर'},
    'pending': {'en': 'Pending', 'hi': 'लंबित', 'gu': 'બાકી', 'mr': 'प्रलंबित'},
    'add posts': {'en': 'Add Posts', 'hi': 'पोस्ट जोड़ें', 'gu': 'પોસ્ટ ઉમેરો', 'mr': 'पोस्ट जोडा'},
    'add reels': {'en': 'Add Reels', 'hi': 'रील्स जोड़ें', 'gu': 'રીલ ઉમેરો', 'mr': 'રીલ્સ जोडा'},
    'go live': {'en': 'Go Live', 'hi': 'लाइव जाएं', 'gu': 'લાઇવ દર્શન', 'mr': 'लाइव्ह जा'},
    'account settings': {'en': 'Account Settings', 'hi': 'खाता सेटिंग्स', 'gu': 'ખાતાના સેટિંગ્સ', 'mr': 'खाते सेटिंग्ज'},
    'edit profile': {'en': 'Edit Profile', 'hi': 'प्रोफ़ाइल संपादित करें', 'gu': 'પ્રોફાઇલ સંપાદિત કરો', 'mr': 'प्रोफाइल संपादित करा'},
    'update name, photo & spiritual bio': {
      'en': 'Update name, photo & spiritual bio',
      'hi': 'नाम, फोटो और आध्यात्मिक परिचय अपडेट करें',
      'gu': 'નામ, ફોટો અને આધ્યાત્મિક પરિચય અપડેટ કરો',
      'mr': 'नाव, फोटो आणि आध्यात्मिक परिचय अपडेट करा'
    },
    'favourite bhajans': {'en': 'Favourite Bhajans', 'hi': 'पसंदीदा भजन', 'gu': 'મનપસંદ ભજનો', 'mr': 'आवडती भजने'},
    'view liked & saved devotional bhajans': {
      'en': 'View liked & saved devotional bhajans',
      'hi': 'पसंद किए गए और सहेजे गए भक्ति भजन देखें',
      'gu': 'પસંદ કરેલા અને સાચવેલા પવિત્ર ભજનો જુઓ',
      'mr': 'आवडलेली आणि सेव्ह केलेली भक्ती भजने पहा'
    },
    'saved library & items': {'en': 'Saved Library & Items', 'hi': 'सहेजी गई लाइब्रेरी और वस्तुएं', 'gu': 'સાચવેલ સંગ્રહ અને પુસ્તકો', 'mr': 'जतन केलेले ग्रंथ आणि साहित्य'},
    'view bookmarked granths & chapters': {
      'en': 'View bookmarked Granths & Chapters',
      'hi': 'बुकमार्क किए गए ग्रंथ और अध्याय देखें',
      'gu': 'બુકમાર્ક કરેલા ગ્રંથો અને અધ્યાયો જુઓ',
      'mr': 'बुकमार्क केलेले ग्रंथ आणि अध्याय पहा'
    },
    'change password': {'en': 'Change Password', 'hi': 'पासवर्ड बदलें', 'gu': 'પાસવર્ડ બદલો', 'mr': 'पासवर्ड बदला'},
    'security & login credentials': {
      'en': 'Security & login credentials',
      'hi': 'सुरक्षा एवं लॉगिन विवरण',
      'gu': 'સુરક્ષા અને લૉગિન વિગતો',
      'mr': 'सुरक्षा आणि लॉगिन तपशील'
    },
    'app preferences': {'en': 'App Preferences', 'hi': 'ऐप प्राथमिकताएं', 'gu': 'એપ પસંદગીઓ', 'mr': 'अ‍ॅप पसंती'},
    'push notifications': {'en': 'Push Notifications', 'hi': 'पुश नोटिफिकेशन', 'gu': 'સૂચનાઓ (નોટિફિકેશન)', 'mr': 'पुश सूचना'},
    'alerts for daily darshan & live aartis': {
      'en': 'Alerts for daily darshan & live aartis',
      'hi': 'दैनिक दर्शन और लाइव आरती के अलर्ट',
      'gu': 'દૈનિક દર્શન અને લાઈવ આરતીના એલર્ટ',
      'mr': 'दैनिक दर्शन आणि लाइव्ह आरतीचे अलर्ट'
    },
    'daily jap reminder': {'en': 'Daily Jap Reminder', 'hi': 'दैनिक जाप रिमाइंडर', 'gu': 'દૈનિક જાપ રીમાઇન્ડર', 'mr': 'दैनिक जाप स्मरणपत्र'},
    'reminds you to complete 108 counts': {
      'en': 'Reminds you to complete 108 counts',
      'hi': 'रोजाना १०८ जाप पूरा करने की याद दिलाता है',
      'gu': 'દરરોજ ૧૦૮ જાપ પૂર્ણ કરવાની યાદ અપાવે છે',
      'mr': 'दररोज १०८ जाप पूर्ण करण्याची आठवण करून देते'
    },
    'beads sound effects': {'en': 'Beads Sound Effects', 'hi': 'माला ध्वनि प्रभाव', 'gu': 'માળાના મણકાનો અવાજ', 'mr': 'माळा मणी ध्वनी'},
    'plays haptic click sound on jap tap': {
      'en': 'Plays haptic click sound on Jap tap',
      'hi': 'जाप करते समय ध्वनि प्रभाव बजाता है',
      'gu': 'જાપ ગણતી વખતે પવિત્ર અવાજ',
      'mr': 'जाप करताना ध्वनी प्रभाव वाजवतो'
    },
    'spiritual language': {'en': 'Spiritual Language', 'hi': 'आध्यात्मिक भाषा', 'gu': 'આધ્યાત્મિક ભાષા', 'mr': 'आध्यात्मिक भाषा'},
    'legal & help': {'en': 'Legal & Help', 'hi': 'कानूनी एवं सहायता', 'gu': 'નિયમો અને સહાય', 'mr': 'कायदेशीर आणि मदत'},
    'terms & conditions': {'en': 'Terms & Conditions', 'hi': 'नियम और शर्तें', 'gu': 'નિયમો અને શરતો', 'mr': 'नियम आणि अटी'},
    'app rules & spiritual guidelines': {
      'en': 'App rules & spiritual guidelines',
      'hi': 'ऐप नियम और आध्यात्मिक दिशानिर्देश',
      'gu': 'એપ નિયમો અને પવિત્ર માર્ગદર્શિકા',
      'mr': 'अ‍ॅप नियम आणि आध्यात्मिक मार्गदर्शक तत्त्वे'
    },
    'privacy policy': {'en': 'Privacy Policy', 'hi': 'गोपनीयता नीति', 'gu': 'ગોપનીયતા નીતિ', 'mr': 'गोपनीयता धोरण'},
    'data protection & privacy details': {
      'en': 'Data protection & privacy details',
      'hi': 'डेटा सुरक्षा और गोपनीयता विवरण',
      'gu': 'ડેટા સુરક્ષા અને પ્રાઇવસી વિગતો',
      'mr': 'डेटा सुरक्षा आणि गोपनीयता तपशील'
    },
    'help & support': {'en': 'Help & Support', 'hi': 'सहायता और संपर्क', 'gu': 'સહાય અને સંપર્ક', 'mr': 'मदत आणि पाठिंबा'},
    'faqs, contact support & app info': {
      'en': 'FAQs, contact support & app info',
      'hi': 'अक्सर पूछे जाने वाले प्रश्न और सहायता',
      'gu': 'વારંવાર પૂછાતા પ્રશ્નો અને સપોર્ટ',
      'mr': 'सतत विचारले जाणारे प्रश्न आणि मदत'
    },
    'log out from account': {'en': 'Log Out from Account', 'hi': 'अकाउंट से लॉग आउट करें', 'gu': 'ખાતામાંથી લૉગ આઉટ કરો', 'mr': 'खात्यातून लॉग आउट करा'},

    // Sacred Granth & Scriptures
    'shrimad bhagavad gita': {'en': 'Shrimad Bhagavad Gita', 'hi': 'श्रीमद्भगवद्गीता', 'gu': 'શ્રીમદ્ ભગવદ્ ગીતા', 'mr': 'श्रीमद्भगवद्गीता'},
    'bhagavad gita': {'en': 'Bhagavad Gita', 'hi': 'भगवद्गीता', 'gu': 'ભગવદ્ ગીતા', 'mr': 'भगवद्गीता'},
    'gita': {'en': 'Gita', 'hi': 'गीता', 'gu': 'ગીતા', 'mr': 'गीता'},
    'ramayan': {'en': 'Ramayana', 'hi': 'रामायण', 'gu': 'રામાયણ', 'mr': 'रामायण'},
    'ramayana': {'en': 'Ramayana', 'hi': 'रामायण', 'gu': 'રામાયણ', 'mr': 'रामायण'},
    'ramcharitmanas': {'en': 'Ramcharitmanas', 'hi': 'रामचरितमानस', 'gu': 'રામચરિતમાનસ', 'mr': 'रामचरितमानस'},
    'shri ramcharitmanas': {'en': 'Shri Ramcharitmanas', 'hi': 'श्री रामचरितमानस', 'gu': 'શ્રી રામચરિતમાનસ', 'mr': 'श्री रामचरितमानस'},
    'mahabharat': {'en': 'Mahabharata', 'hi': 'महाभारत', 'gu': 'મહાભારત', 'mr': 'महाभारत'},
    'mahabharata': {'en': 'Mahabharata', 'hi': 'महाभारत', 'gu': 'મહાભારત', 'mr': 'महाभारत'},
    'hanuman chalisa': {'en': 'Hanuman Chalisa', 'hi': 'हनुमान चालीसा', 'gu': 'હનુમાન ચાલીસા', 'mr': 'हनुमान चालीसा'},
    'sundarkand': {'en': 'Sundarkand', 'hi': 'सुंदरकाण्ड', 'gu': 'સુંદરકાંડ', 'mr': 'सुंदरकाण्ड'},
    'shiv puran': {'en': 'Shiv Puran', 'hi': 'शिव पुराण', 'gu': 'શિવ પુરાણ', 'mr': 'शिव पुराण'},
    'shiva purana': {'en': 'Shiva Purana', 'hi': 'शिव पुराण', 'gu': 'શિવ પુરાણ', 'mr': 'शिव पुराण'},
    'vishnu puran': {'en': 'Vishnu Puran', 'hi': 'विष्णु पुराण', 'gu': 'વિષ્ણુ પુરાણ', 'mr': 'विष्णु पुराण'},
    'garuda puran': {'en': 'Garuda Puran', 'hi': 'गरुड़ पुराण', 'gu': 'ગરુડ પુરાણ', 'mr': 'गरुड पुराण'},
    'garud puran': {'en': 'Garuda Puran', 'hi': 'गरुड़ पुराण', 'gu': 'ગરુડ પુરાણ', 'mr': 'गरुड पुराण'},
    'vedas': {'en': 'Vedas', 'hi': 'वेद', 'gu': 'વેદ', 'mr': 'वेद'},
    'upanishads': {'en': 'Upanishads', 'hi': 'उपनिषद', 'gu': 'ઉપનિષદ', 'mr': 'उपनिषद'},

    // Bhajan Dashboard, Hub & Playlists
    'divine bhajans': {'en': 'Divine Bhajans', 'hi': 'दिव्य भजन', 'gu': 'દિવ્ય ભજન', 'mr': 'दिव्य भजने'},
    'spiritual melodies & sacred hymns': {
      'en': 'Spiritual melodies & sacred hymns',
      'hi': 'आध्यात्मिक धुनें और पवित्र स्तोत्र',
      'gu': 'આધ્યાત્મિક સૂરો અને પવિત્ર સ્તોત્રો',
      'mr': 'आध्यात्मिक धून आणि पवित्र स्तोत्रे'
    },
    'my library': {'en': 'My Library', 'hi': 'मेरा संग्रह', 'gu': 'મારો સંગ્રહ', 'mr': 'माझा संग्रह'},
    'my bhajan library': {'en': 'My Bhajan Library', 'hi': 'मेरा भजन संग्रह', 'gu': 'મારો ભજન સંગ્રહ', 'mr': 'माझा भजन संग्रह'},
    'devotional collection': {'en': 'Devotional Collection', 'hi': 'भक्ति संग्रह', 'gu': 'ભક્તિ સંગ્રહ', 'mr': 'भक्ती संग्रह'},
    'liked bhajans, playlists & saved audio': {
      'en': 'Liked bhajans, playlists & saved audio',
      'hi': 'पसंदीदा भजन, प्लेलिस्ट और सहेजे गए ऑडियो',
      'gu': 'પસંદ કરેલા ભજનો, પ્લેલિસ્ટ અને સાચવેલ ઓડિયો',
      'mr': 'आवडती भजने, प्लेलिस्ट आणि सेव्ह केलेले ऑडिओ'
    },
    'liked': {'en': 'Liked', 'hi': 'पसंदीदा', 'gu': 'પસંદ કરેલ', 'mr': 'आवडलेले'},
    'liked bhajans': {'en': 'Liked Bhajans', 'hi': 'पसंदीदा भजन', 'gu': 'પસંદ કરેલા ભજનો', 'mr': 'आवडती भजने'},
    'playlists': {'en': 'Playlists', 'hi': 'प्लेलिस्ट', 'gu': 'પ્લેલિસ્ટ', 'mr': 'प्लेलिस्ट'},
    'my playlists': {'en': 'My Playlists', 'hi': 'मेरी प्लेलिस्ट', 'gu': 'મારા પ્લેલિસ્ટ', 'mr': 'माझ्या प्लेलिस्ट'},
    'listen later': {'en': 'Listen Later', 'hi': 'बाद में सुनें', 'gu': 'પછી સાંભળો', 'mr': 'नंतर ऐका'},
    'downloads': {'en': 'Downloads', 'hi': 'डाउनलोड', 'gu': 'ડાઉનલોડ્સ', 'mr': 'डाउनलोड'},
    'offline downloads': {'en': 'Offline Downloads', 'hi': 'ऑफलाइन डाउनलोड', 'gu': 'ઓફલાઇન ડાઉનલોડ્સ', 'mr': 'ऑफलाइन डाउनलोड'},
    'app offline storage': {'en': 'App Offline Storage', 'hi': 'ऐप ऑफलाइन स्टोरेज', 'gu': 'એપ ઓફલાઇન સ્ટોરેજ', 'mr': 'ॲप ऑफलाइन स्टोरेज'},
    'listen offline anytime even when internet is off': {
      'en': 'Listen offline anytime even when internet is off',
      'hi': 'इंटरनेट बंद होने पर भी कभी भी ऑफलाइन सुनें',
      'gu': 'ઇન્ટરનેટ બંધ હોય ત્યારે પણ ગમે ત્યારે ઓફલાઇન સાંભળો',
      'mr': 'इंटरनेट बंद असतानाही कधीही ऑफलाइन ऐका'
    },
    'recent': {'en': 'Recent', 'hi': 'हालिया', 'gu': 'તાજેતરના', 'mr': 'अलीकडील'},
    'recent plays': {'en': 'Recent Plays', 'hi': 'हाल ही में सुने गए', 'gu': 'તાજેતરમાં સાંભળેલા', 'mr': 'अलीकडेच ऐकलेले'},
    'last played': {'en': 'Last Played', 'hi': 'अंतिम सुना गया', 'gu': 'છેલ્લે સાંભળેલું', 'mr': 'शेवटचे ऐकलेले'},
    'recently played': {'en': 'Recently Played', 'hi': 'हाल ही में सुने गए', 'gu': 'તાજેતરમાં સાંભળેલા', 'mr': 'अलीकडेच ऐकलेले'},
    'add to playlist': {'en': 'Add to Playlist', 'hi': 'प्लेलिस्ट में जोड़ें', 'gu': 'પ્લેલિસ્ટમાં ઉમેરો', 'mr': 'प्लेलिस्टमध्ये जोडा'},
    'create new playlist': {'en': 'Create New Playlist', 'hi': 'नई प्लेलिस्ट बनाएं', 'gu': 'નવું પ્લેલિસ્ટ બનાવો', 'mr': 'नवीन प्लेलिस्ट तयार करा'},
    'new playlist': {'en': 'New Playlist', 'hi': 'नई प्लेलिस्ट', 'gu': 'નવું પ્લેલિસ્ટ', 'mr': 'नवीन प्लेलिस्ट'},
    'enter playlist name...': {
      'en': 'Enter playlist name...',
      'hi': 'प्लेलिस्ट का नाम लिखें...',
      'gu': 'પ્લેલિસ્ટનું નામ લખો...',
      'mr': 'प्लेलिस्टचे नाव लिहा...'
    },
    'create': {'en': 'Create', 'hi': 'बनाएं', 'gu': 'બનાવો', 'mr': 'तयार करा'},
    'cancel': {'en': 'Cancel', 'hi': 'रद्द करें', 'gu': 'રદ કરો', 'mr': 'रद्द करा'},
    'play all': {'en': 'Play All', 'hi': 'सभी चलाएं', 'gu': 'બધા વગાડો', 'mr': 'सर्व वाजवा'},
    'download': {'en': 'Download', 'hi': 'डाउनलोड करें', 'gu': 'ડાઉનલોડ કરો', 'mr': 'डाउनलोड करा'},
    'downloaded': {'en': 'Downloaded', 'hi': 'डाउनलोड किया गया', 'gu': 'ડાઉનલોડ થયેલ', 'mr': 'डाउनलोड केलेले'},
    'remove download': {'en': 'Remove from Downloads', 'hi': 'डाउनलोड से हटाएं', 'gu': 'ડાઉનલોડ્સમાંથી કાઢી નાખો', 'mr': 'डाउनलोडमधून काढा'},
    'remove from downloads': {'en': 'Remove from Downloads', 'hi': 'डाउनलोड से हटाएं', 'gu': 'ડાઉનલોડ્સમાંથી કાઢી નાખો', 'mr': 'डाउनलोडमधून काढा'},
    'removed from downloads': {'en': 'Removed from Downloads', 'hi': 'डाउनलोड से हटाया गया', 'gu': 'ડાઉનલોડ્સમાંથી કાઢી નાખ્યું', 'mr': 'डाउनलोडमधून काढले'},
    'share': {'en': 'Share', 'hi': 'शेयर करें', 'gu': 'શેર કરો', 'mr': 'शेअर करा'},
    'listen now': {'en': 'Listen Now', 'hi': 'अभी सुनें', 'gu': 'અત્યારે સાંભળો', 'mr': 'आता ऐका'},
    'featured bhajan': {'en': 'FEATURED BHAJAN', 'hi': 'विशेष भजन', 'gu': 'વિશેષ ભજન', 'mr': 'विशेष भजन'},
    'most played': {'en': 'Most Played', 'hi': 'सर्वाधिक सुने गए', 'gu': 'સૌથી વધુ સાંભળેલા', 'mr': 'सर्वाधिक ऐकलेले'},
    'sacred devotions': {'en': 'Sacred Devotions', 'hi': 'पवित्र भक्ति', 'gu': 'પવિત્ર ભક્તિ', 'mr': 'पवित्र भक्ती'},
    'search bhajans, deities, singers...': {
      'en': 'Search bhajans, deities, singers...',
      'hi': 'भजन, देवता, गायक खोजें...',
      'gu': 'ભજન, દેવી-દેવતા, ગાયક શોધો...',
      'mr': 'भजन, देवता, गायक शोधा...'
    },
    'view all': {'en': 'View All', 'hi': 'सभी देखें', 'gu': 'બધા જુઓ', 'mr': 'सर्व पहा'},
  };

  static List<MapEntry<String, Map<String, String>>>? _cachedSortedEntries;
  static List<MapEntry<String, Map<String, String>>> get _sortedCanonicalEntries {
    if (_cachedSortedEntries != null) return _cachedSortedEntries!;
    final list = _spiritualCanonicalMap.entries.toList();
    list.sort((a, b) => b.key.length.compareTo(a.key.length));
    _cachedSortedEntries = list;
    return list;
  }

  /// Extract localized string from dynamic API response.
  /// Handles:
  /// 1. Multilingual Map format: {"en": "...", "hi": "...", "gu": "...", "mr": "..."}
  /// 2. Raw String format: looks up canonical spiritual terms dictionary, or performs sub-phrase translation
  /// 3. Fallback priority: current selected language -> English -> Hindi -> first non-empty -> defaultValue
  static String parse(
    dynamic value, {
    String defaultValue = '',
    BuildContext? context,
  }) {
    if (value == null) return defaultValue;

    final currentCode = context != null
        ? Localizations.localeOf(context).languageCode.toLowerCase()
        : LanguageManager.instance.currentLanguageCode.toLowerCase();

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return defaultValue;

      if (currentCode != 'en') {
        final lower = trimmed.toLowerCase();
        final match = _spiritualCanonicalMap[lower];
        if (match != null && match.containsKey(currentCode)) {
          return match[currentCode]!;
        }

        // Deep Dynamic Translation (Sentence / Phrase token substitution)
        String translated = trimmed;
        bool hasReplacements = false;
        for (final entry in _sortedCanonicalEntries) {
          final target = entry.key;
          if (target.length < 3) continue; // Skip single characters to avoid false matches
          if (translated.toLowerCase().contains(target)) {
            final locVal = entry.value[currentCode];
            if (locVal != null && locVal.isNotEmpty) {
              final regExp = RegExp(RegExp.escape(target), caseSensitive: false);
              translated = translated.replaceAll(regExp, locVal);
              hasReplacements = true;
            }
          }
        }
        if (hasReplacements) {
          return translated;
        }
      }
      return trimmed;
    }

    if (value is Map) {
      // 1. Direct match with selected language code
      if (value.containsKey(currentCode)) {
        final val = value[currentCode]?.toString().trim() ?? '';
        if (val.isNotEmpty) return val;
      }

      // Also check full locale match (e.g., 'en_US', 'hi_IN')
      for (final entry in value.entries) {
        if (entry.key.toString().toLowerCase().startsWith(currentCode)) {
          final val = entry.value?.toString().trim() ?? '';
          if (val.isNotEmpty) return val;
        }
      }

      // 2. Fallback to English
      if (value.containsKey('en')) {
        final val = value['en']?.toString().trim() ?? '';
        if (val.isNotEmpty) return val;
      }

      // 3. Fallback to Hindi
      if (value.containsKey('hi')) {
        final val = value['hi']?.toString().trim() ?? '';
        if (val.isNotEmpty) return val;
      }

      // 4. Fallback to any non-empty string in the map
      for (final val in value.values) {
        if (val != null) {
          final str = val.toString().trim();
          if (str.isNotEmpty) return str;
        }
      }
    }

    // Numbers or other primitive types
    final str = value.toString().trim();
    return str.isNotEmpty ? str : defaultValue;
  }

  /// Parses a field from a JSON map, inspecting:
  /// 1. json['${baseField}_${currentLang}'] (e.g. name_gu)
  /// 2. json[baseField] (which may be a localized map or scalar)
  /// 3. json['${baseField}_en']
  /// 4. json['${baseField}_hi']
  /// 5. defaultValue
  static String parseField(
    Map<String, dynamic>? json,
    String baseField, {
    String defaultValue = '',
    BuildContext? context,
  }) {
    if (json == null) return defaultValue;

    final currentCode = context != null
        ? Localizations.localeOf(context).languageCode.toLowerCase()
        : LanguageManager.instance.currentLanguageCode.toLowerCase();

    // 1. Check for direct language suffixed keys (e.g. name_gu, name_hi, name_mr)
    final suffixedKey = '${baseField}_$currentCode';
    if (json.containsKey(suffixedKey) && json[suffixedKey] != null) {
      final str = json[suffixedKey].toString().trim();
      if (str.isNotEmpty) return str;
    }

    // 2. Check base field with standard parse
    if (json.containsKey(baseField) && json[baseField] != null) {
      final parsed = parse(json[baseField], context: context);
      if (parsed.isNotEmpty) return parsed;
    }

    // 3. Check English suffixed key
    final enKey = '${baseField}_en';
    if (json.containsKey(enKey) && json[enKey] != null) {
      final str = json[enKey].toString().trim();
      if (str.isNotEmpty) return str;
    }

    // 4. Check Hindi suffixed key
    final hiKey = '${baseField}_hi';
    if (json.containsKey(hiKey) && json[hiKey] != null) {
      final str = json[hiKey].toString().trim();
      if (str.isNotEmpty) return str;
    }

    return defaultValue;
  }

  /// Helper to convert a plain string into a multilingual Map if required for updates
  static Map<String, String> createMultilingualMap({
    required String text,
    String? currentLangCode,
  }) {
    final code = currentLangCode ?? LanguageManager.instance.currentLanguageCode;
    return {
      'en': text,
      code: text,
    };
  }
}
