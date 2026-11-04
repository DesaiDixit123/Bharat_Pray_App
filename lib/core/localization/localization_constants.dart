import 'package:flutter/material.dart';
import 'language_manager.dart';

class SpiritualTerms {
  static const Map<String, Map<String, String>> _terms = {
    // Nav Bar
    'nav_home': {'en': 'Home', 'hi': 'होम', 'gu': 'હોમ', 'mr': 'होम'},
    'nav_darshan': {'en': 'Darshan', 'hi': 'दर्शन', 'gu': 'દર્શન', 'mr': 'दर्शन'},
    'nav_jap': {'en': 'Jap', 'hi': 'जाप', 'gu': 'જાપ', 'mr': 'जाप'},
    'nav_yatra': {'en': 'Yatra', 'hi': 'यात्रा', 'gu': 'યાત્રા', 'mr': 'यात्रा'},
    'nav_profile': {'en': 'Profile', 'hi': 'प्रोफाइल', 'gu': 'પ્રોફાઇલ', 'mr': 'प्रोफाइल'},

    // Greetings
    'greeting_morning': {'en': 'Good Morning', 'hi': 'शुभ प्रभात', 'gu': 'શુભ પ્રભાત', 'mr': 'शुभ प्रभात'},
    'greeting_afternoon': {'en': 'Good Afternoon', 'hi': 'शुभ दोपहर', 'gu': 'શુભ બપોર', 'mr': 'शुभ दुपार'},
    'greeting_evening': {'en': 'Good Evening', 'hi': 'शुभ संध्या', 'gu': 'શુભ સાંજ', 'mr': 'शुभ संध्याकाळ'},
    'divine_salutation': {'en': 'Jai Shree Ram', 'hi': 'जय श्री राम', 'gu': 'જય શ્રી રામ', 'mr': 'जय श्री राम'},

    // Bhajan Module
    'trending_bhajans': {'en': 'Trending Bhajans', 'hi': 'ट्रेंडिंग भजन', 'gu': 'ટ્રેન્ડિંગ ભજન', 'mr': 'ट्रेंडिंग भजने'},
    'categories': {'en': 'Categories', 'hi': 'श्रेणियां', 'gu': 'શ્રેણીઓ', 'mr': 'श्रेण्या'},
    'quick_playlists': {'en': 'Quick Playlists', 'hi': 'क्विक प्लेलिस्ट्स', 'gu': 'ઝડપી પ્લેલિસ્ટ્સ', 'mr': 'द्रुत प्लेलिस्ट'},
    'downloads': {'en': 'Downloads', 'hi': 'डाउनलोड्स', 'gu': 'ડાઉનલોડ્સ', 'mr': 'डाउनलोड्स'},
    'all_bhajans': {'en': 'All Bhajans', 'hi': 'सभी भजन', 'gu': 'બધા ભજનો', 'mr': 'सर्व भजने'},
    'play_all': {'en': 'Play All', 'hi': 'सभी चलाएं', 'gu': 'બધા વગાડો', 'mr': 'सर्व प्ले करा'},
    'favorites': {'en': 'Favorites', 'hi': 'पसंदीदा', 'gu': 'મનપસંદ', 'mr': 'आवडते'},
    'offline_downloads': {'en': 'Offline Downloads', 'hi': 'ऑफ़लाइन डाउनलोड', 'gu': 'ઓફલાઇન ડાઉનલોડ', 'mr': 'ऑफलाइन डाउनलोड'},
    'no_downloads_yet': {'en': 'No downloads yet', 'hi': 'अभी कोई डाउनलोड नहीं है', 'gu': 'હજુ સુધી કોઈ ડાઉનલોડ નથી', 'mr': 'अद्याप कोणतेही डाउनलोड नाही'},
    'playing_now': {'en': 'Now Playing', 'hi': 'अभी चल रहा है', 'gu': 'હાલમાં વાગી રહ્યું છે', 'mr': 'आता प्ले होत आहे'},
    'explore_bhajans': {'en': 'Explore Divine Melodies', 'hi': 'पवित्र भजनों का आनंद लें', 'gu': 'પવિત્ર ભજનોનો આનંદ માણો', 'mr': 'पवित्र भजनांचा आनंद घ्या'},

    // Utsav Module
    'festivals': {'en': 'Festivals', 'hi': 'त्योहार एवं उत्सव', 'gu': 'તહેવારો અને મહોત્સવ', 'mr': 'सण व उत्सव'},
    'register_mandal': {'en': 'Register Mandal', 'hi': 'मंडल पंजीकृत करें', 'gu': 'મંડળ રજીસ્ટર કરો', 'mr': 'मंडळ नोंदणी करा'},
    'leaderboard': {'en': 'Leaderboard', 'hi': 'लीडरबोर्ड', 'gu': 'લીડરબોર્ડ', 'mr': 'લીડરબોર્ડ'},
    'mandal_status': {'en': 'Mandal Status', 'hi': 'मंडल स्थिति', 'gu': 'મંડળ સ્થિતિ', 'mr': 'मंडळ स्थिती'},

    // Jap Module
    'start_chanting': {'en': 'Start Chanting', 'hi': 'जाप शुरू करें', 'gu': 'જાપ શરૂ કરો', 'mr': 'जाप सुरू करा'},
    'completed_malas': {'en': 'Completed Malas', 'hi': 'पूर्ण मालाएं', 'gu': 'પૂર્ણ માળાઓ', 'mr': 'पूर्ण माळा'},
    'total_jap_count': {'en': 'Total Jap Count', 'hi': 'कुल जाप संख्या', 'gu': 'કુલ જાપ સંખ્યા', 'mr': 'एकूण जाप संख्या'},
    'daily_target': {'en': 'Daily Target', 'hi': 'दैनिक लक्ष्य', 'gu': 'દૈનિક લક્ષ્ય', 'mr': 'दैनिक उद्दिष्ट'},

    // Yatra Module
    'sacred_yatras': {'en': 'Sacred Yatras', 'hi': 'पवित्र यात्राएं', 'gu': 'પવિત્ર યાત્રાઓ', 'mr': 'पवित्र यात्रा'},
    'start_journey': {'en': 'Start Journey', 'hi': 'यात्रा प्रारंभ करें', 'gu': 'યાત્રા શરૂ કરો', 'mr': 'प्रवास सुरू करा'},
    'total_distance': {'en': 'Total Distance', 'hi': 'कुल दूरी', 'gu': 'કુલ અંતર', 'mr': 'एकूण अंतर'},
    'walking_steps': {'en': 'Walking Steps', 'hi': 'पैदल कदम', 'gu': 'ચાલવાના ડગલાં', 'mr': 'चालण्याची पावले'},

    // Common Actions
    'continue_button': {'en': 'Continue', 'hi': 'आगे बढ़ें', 'gu': 'આગળ વધો', 'mr': 'पुढे जा'},
    'view_all': {'en': 'View All', 'hi': 'सभी देखें', 'gu': 'બધું જુઓ', 'mr': 'सर्व पहा'},
    'search': {'en': 'Search', 'hi': 'खोजें', 'gu': 'શોધો', 'mr': 'शोधा'},
    'loading': {'en': 'Loading...', 'hi': 'लोड हो रहा है...', 'gu': 'લોડ થઈ રહ્યું છે...', 'mr': 'लोड होत आहे...'},
  };

  /// Get translation for a key with fallback priority: selected lang -> en -> hi -> raw key
  static String get(String key, {String? langCode, BuildContext? context}) {
    final code = langCode ??
        (context != null
            ? Localizations.localeOf(context).languageCode.toLowerCase()
            : LanguageManager.instance.currentLanguageCode.toLowerCase());

    final map = _terms[key];
    if (map == null) return key;

    return map[code] ?? map['en'] ?? map['hi'] ?? map.values.first;
  }
}
