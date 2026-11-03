// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'BharatPray';

  @override
  String get om => 'ॐ';

  @override
  String get chooseLanguage => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get selectLanguageSubtitle => 'आगे बढ़ने के लिए अपनी भाषा का चयन करें';

  @override
  String get continueButton => 'आगे बढ़ें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get apply => 'लागू करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get view => 'देखें';

  @override
  String get close => 'बंद करें';

  @override
  String get back => 'वापस जाएं';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करें...';

  @override
  String get success => 'सफल';

  @override
  String get error => 'त्रुटि';

  @override
  String get search => 'खोजें';

  @override
  String get searchPlaceholder => 'मंदिर, यात्रा, भजन खोजें...';

  @override
  String get noResults => 'कोई परिणाम नहीं मिला';

  @override
  String get noDataAvailable => 'कोई डेटा उपलब्ध नहीं है';

  @override
  String get login => 'लॉगिन';

  @override
  String get register => 'पंजीकरण करें';

  @override
  String get welcomeBack => 'भक्तजन, आपका पुनः स्वागत है';

  @override
  String get enterPhoneNumber => 'अपना 10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get enterEmail => 'अपना ईमेल पता दर्ज करें';

  @override
  String get sendOtp => 'पवित्र OTP भेजें';

  @override
  String get orContinueWith => 'या इसके साथ आगे बढ़ें';

  @override
  String get googleSignIn => 'गूगल के साथ आगे बढ़ें';

  @override
  String get phoneLogin => 'मोबाइल नंबर से लॉगिन';

  @override
  String get emailLogin => 'ईमेल से लॉगिन';

  @override
  String get dontHaveAccount => 'क्या आपका खाता नहीं है?';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get signUpNow => 'अभी पंजीकरण करें';

  @override
  String get loginNow => 'अभी लॉगिन करें';

  @override
  String get verifyOtp => 'OTP सत्यापित करें';

  @override
  String enterOtpSentTo(String contact) {
    return '$contact पर भेजा गया 6 अंकों का OTP दर्ज करें';
  }

  @override
  String get verifyAndProceed => 'सत्यापित करें और आगे बढ़ें';

  @override
  String get resendOtp => 'OTP पुनः भेजें';

  @override
  String resendIn(int seconds) {
    return '$seconds सेकंड में पुनः भेजें';
  }

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get enterFullName => 'अपना पूरा नाम दर्ज करें';

  @override
  String get phoneNumber => 'मोबाइल नंबर';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get city => 'शहर';

  @override
  String get state => 'राज्य';

  @override
  String get country => 'देश';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get myProfile => 'मेरी भक्ति प्रोफ़ाइल';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा (Language)';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get helpAndSupport => 'सहायता और संपर्क';

  @override
  String get termsAndConditions => 'नियम और शर्तें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get logoutConfirmation =>
      'क्या आप सचमुच अपने खाते से बाहर निकलना चाहते हैं?';

  @override
  String get home => 'होम';

  @override
  String get temple => 'मंदिर';

  @override
  String get darshan => 'लाइव दर्शन';

  @override
  String get yatra => 'यात्रा';

  @override
  String get jap => 'जाप';

  @override
  String get bhajan => 'भजन';

  @override
  String get granth => 'ग्रंथ';

  @override
  String get utsav => 'उत्सव';

  @override
  String get community => 'सत्संग';

  @override
  String get featuredTemples => 'प्रमुख मंदिर';

  @override
  String get popularYatras => 'पवित्र तीर्थ यात्राएं';

  @override
  String get todaysDarshan => 'आज के दिव्य दर्शन';

  @override
  String get dailyJapGoal => 'दैनिक जाप लक्ष्य';

  @override
  String get completedJaps => 'पूर्ण जाप';

  @override
  String get startJap => 'जाप आरंभ करें';

  @override
  String get malaCounter => '१०८ माला गणक';

  @override
  String get chantingSpeed => 'जाप की गति';

  @override
  String get resetCounter => 'गणक रीसेट करें';

  @override
  String get beadsChanted => 'जापे गए मनके';

  @override
  String get totalMalas => 'कुल मालाएं';

  @override
  String get groupYatra => 'समूह यात्रा';

  @override
  String get createGroup => 'यात्रा समूह बनाएं';

  @override
  String get joinGroup => 'समूह में शामिल हों';

  @override
  String get groupChat => 'समूह सत्संग चैट';

  @override
  String get members => 'सदस्य';

  @override
  String get liveLocation => 'लाइव तीर्थ स्थान ट्रैकिंग';

  @override
  String get routeSummary => 'यात्रा मार्ग सारांश';

  @override
  String get nowPlaying => 'वर्तमान में चल रहा है';

  @override
  String get playlist => 'भजन संग्रह';

  @override
  String get lyrics => 'आरती / स्तोत्र बोल';

  @override
  String get audioPlayer => 'भक्ति संगीत';

  @override
  String get fieldRequired => 'यह फ़ील्ड आवश्यक है';

  @override
  String get invalidPhone => 'कृपया वैध 10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get invalidEmail => 'कृपया वैध ईमेल पता दर्ज करें';

  @override
  String get networkError =>
      'नेटवर्क कनेक्शन में समस्या है। कृपया इंटरनेट जांचें।';

  @override
  String get somethingWentWrong =>
      'कुछ गलत हो गया। कृपया कुछ समय बाद पुनः प्रयास करें।';
}
