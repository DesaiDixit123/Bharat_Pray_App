// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'BharatPray';

  @override
  String get om => 'ॐ';

  @override
  String get chooseLanguage => 'तुमची पसंतीची भाषा निवडा';

  @override
  String get selectLanguageSubtitle => 'पुढे जाण्यासाठी तुमची भाषा निवडा';

  @override
  String get continueButton => 'पुढे जा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get save => 'जतन करा';

  @override
  String get apply => 'लागू करा';

  @override
  String get confirm => 'पुष्टी करा';

  @override
  String get delete => 'हटवा';

  @override
  String get edit => 'संपादित करा';

  @override
  String get view => 'पहा';

  @override
  String get close => 'बंद करा';

  @override
  String get back => 'मागे जा';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get loading => 'लोड होत आहे...';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करा...';

  @override
  String get success => 'यशस्वी';

  @override
  String get error => 'त्रुटी';

  @override
  String get search => 'शोधा';

  @override
  String get searchPlaceholder => 'मंदिरे, यात्रा, भजने शोधा...';

  @override
  String get noResults => 'कोणतेही निकाल आढळले नाहीत';

  @override
  String get noDataAvailable => 'कोणतीही माहिती उपलब्ध नाही';

  @override
  String get login => 'लॉगिन';

  @override
  String get register => 'नोंदणी करा';

  @override
  String get welcomeBack => 'भक्तजन, आपले सहर्ष स्वागत आहे';

  @override
  String get enterPhoneNumber => 'तुमचा १० अंकी मोबाइल नंबर प्रविष्ट करा';

  @override
  String get enterEmail => 'तुमचा ईमेल पत्ता प्रविष्ट करा';

  @override
  String get sendOtp => 'पवित्र OTP पाठवा';

  @override
  String get orContinueWith => 'किंवा यासह पुढे जा';

  @override
  String get googleSignIn => 'Google सह पुढे जा';

  @override
  String get phoneLogin => 'मोबाइल नंबरने लॉगिन';

  @override
  String get emailLogin => 'ईमेलने लॉगिन';

  @override
  String get dontHaveAccount => 'खाते नाही का?';

  @override
  String get alreadyHaveAccount => 'आधीच खाते आहे का?';

  @override
  String get signUpNow => 'आता नोंदणी करा';

  @override
  String get loginNow => 'आता लॉगिन करा';

  @override
  String get verifyOtp => 'OTP सत्यापित करा';

  @override
  String enterOtpSentTo(String contact) {
    return '$contact वर पाठवलेला ६ अंकी OTP प्रविष्ट करा';
  }

  @override
  String get verifyAndProceed => 'सत्यापित करा आणि पुढे जा';

  @override
  String get resendOtp => 'OTP पुन्हा पाठवा';

  @override
  String resendIn(int seconds) {
    return '$seconds सेकंदात पुन्हा पाठवा';
  }

  @override
  String get fullName => 'पूर्ण नाव';

  @override
  String get enterFullName => 'तुमचे पूर्ण नाव प्रविष्ट करा';

  @override
  String get phoneNumber => 'मोबाइल नंबर';

  @override
  String get emailAddress => 'ईमेल पत्ता';

  @override
  String get city => 'शहर';

  @override
  String get state => 'राज्य';

  @override
  String get country => 'देश';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get myProfile => 'माझी भक्ती प्रोफाइल';

  @override
  String get editProfile => 'प्रोफाइल संपादित करा';

  @override
  String get changePassword => 'पासवर्ड बदला';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा (Language)';

  @override
  String get notifications => 'सूचना';

  @override
  String get helpAndSupport => 'मदत आणि संपर्क';

  @override
  String get termsAndConditions => 'नियम आणि अटी';

  @override
  String get privacyPolicy => 'गोपनीयता धोरण';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get logoutConfirmation =>
      'तुम्हाला नक्की तुमच्या खात्यातून बाहेर पडायचे आहे का?';

  @override
  String get home => 'मुख्यपृष्ठ';

  @override
  String get temple => 'मंदिरे';

  @override
  String get darshan => 'थेट दर्शन';

  @override
  String get yatra => 'तीर्थयात्रा';

  @override
  String get jap => 'जप';

  @override
  String get bhajan => 'भजन';

  @override
  String get granth => 'पवित्र ग्रंथ';

  @override
  String get utsav => 'उत्सव';

  @override
  String get community => 'सत्संग';

  @override
  String get featuredTemples => 'प्रमुख मंदिरे';

  @override
  String get popularYatras => 'पवित्र तीर्थयात्रा';

  @override
  String get todaysDarshan => 'आजचे दिव्य दर्शन';

  @override
  String get dailyJapGoal => 'दैनिक जप उद्दिष्ट';

  @override
  String get completedJaps => 'पूर्ण झालेले जप';

  @override
  String get startJap => 'जप सुरू करा';

  @override
  String get malaCounter => '१०८ माळ गणक';

  @override
  String get chantingSpeed => 'जपाचा वेग';

  @override
  String get resetCounter => 'गणक रीसेट करा';

  @override
  String get beadsChanted => 'जपलेले मणी';

  @override
  String get totalMalas => 'एकूण माळा';

  @override
  String get groupYatra => 'समूह यात्रा';

  @override
  String get createGroup => 'तीर्थयात्रा गट तयार करा';

  @override
  String get joinGroup => 'गटात सामील व्हा';

  @override
  String get groupChat => 'सत्संग चर्चा';

  @override
  String get members => 'सदस्य';

  @override
  String get liveLocation => 'थेट यात्रा ट्रॅकिंग';

  @override
  String get routeSummary => 'मार्ग सारांश';

  @override
  String get nowPlaying => 'आता वाजत आहे';

  @override
  String get playlist => 'भजन संग्रह';

  @override
  String get lyrics => 'आरती / स्तोत्र बोल';

  @override
  String get audioPlayer => 'भक्ती संगीत';

  @override
  String get fieldRequired => 'ही माहिती आवश्यक आहे';

  @override
  String get invalidPhone => 'कृपया वैध १० अंकी मोबाइल नंबर टाका';

  @override
  String get invalidEmail => 'कृपया वैध ईमेल पत्ता टाका';

  @override
  String get networkError => 'इंटरनेट कनेक्शनमध्ये समस्या आहे. कृपया तपासा.';

  @override
  String get somethingWentWrong =>
      'काहीतरी चूक झाली. कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.';
}
