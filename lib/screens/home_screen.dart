import '../core/localization/app_localization.dart';
import '../core/localization/language_manager.dart';
import '../core/localization/localized_api_helper.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'details/live_darshan_screen.dart';
import 'details/jap_counter_screen.dart';
import 'details/yatra_screen.dart';
import 'details/profile_screen.dart';
import 'details/bhajan_dashboard_screen.dart';
import 'details/bhajan_now_playing_screen.dart';
import 'details/granth_screen.dart';
import 'details/granth_chapter_list_screen.dart';
import 'details/granth_chapter_reader_screen.dart';
import 'details/yatra_live_sangha_screen.dart';
import 'details/yatra_completed_screen.dart';
import 'details/deity_detail_screen.dart';
import 'details/festival_detail_screen.dart';
import 'details/darshan_tab_content.dart';
import 'details/deity_temples_screen.dart';
import 'details/festivals_home_tab_content.dart';
import '../models/bhajan_track_item.dart';
import '../models/journey_models.dart';
import '../models/jap_models.dart';
import '../models/jap_theme_config.dart';
import '../services/jap_offline_repository.dart';
import '../services/api_service.dart';
import '../services/bhajan_audio_service.dart';
import '../services/bhajan_library_service.dart';
import '../services/yatra_group_socket_service.dart';
import '../services/socket_service.dart';
import '../widgets/bhajan/bhajan_mini_player_widget.dart';
import 'details/notification_screen.dart';
import 'details/messages_screen.dart';
import '../models/notification_model.dart';
import '../services/yatra_personal_chat_service.dart';
import '../widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Carousel state
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _carouselTimer;

  String _profileName = 'User';
  String _profilePic = '';
  int _currentTab = 0;
  int _notificationCount = 2;
  int _messageCount = 0;

  List<Map<String, dynamic>> _liveDarshanBanners = [];
  bool _isLoadingLiveDarshans = true;
  Set<String> _viewedDarshanIds = {};

  // Dynamic state for the 4 Home Devotional Cards (Yatra, Jap, Bhajan, Granth)
  String _yatraCardTitle = 'Somnath Temple';
  String _yatraCardImage = 'assets/images/h1.jpg';
  double _yatraCardProgress = 0.0;
  ContinueYatraModel? _continueYatraData;

  String _japCardTitle = 'Shree Krishna';
  String _japCardImage = 'assets/images/h2.jpg';
  double _japCardProgress = 0.0;
  JapConfig? _lastJapEntry;

  String _granthCardTitle = 'Shrimad Bhagava..';
  String _granthCardImage = 'assets/images/h4.jpg';
  double _granthCardProgress = 0.0;

  static const String _yatraCardIconSvg = '''<svg width="17" height="24" viewBox="0 0 17 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6.57375 14.662C6.28644 14.2277 5.91887 13.8458 5.6092 13.4248C5.39286 13.1281 5.15759 12.8238 5.03182 12.4846C4.63009 11.3966 4.82235 10.3843 5.58157 9.52134C5.95017 9.10321 6.38332 8.74435 6.79033 8.36245C7.36278 7.82704 7.73665 7.20082 7.76807 6.37602C7.80051 5.49814 7.36943 4.78112 6.58304 4.56581C6.18268 4.45654 5.34631 4.39647 5.34424 4.41435C4.14168 4.47374 2.98566 4.7246 1.92766 5.33305C0.962534 5.88772 0.270619 6.6756 0.0783506 7.82646C-0.0839944 8.79434 0.00612083 9.75947 0.347091 10.6716C0.651832 11.4882 1.03683 12.2718 1.3974 13.0669C1.82115 14.0003 2.10078 14.9693 2.12348 16.0053C2.12945 16.2726 2.13919 16.5429 2.19021 16.8032C2.35737 17.6787 2.76541 18.3838 3.58986 18.7678C4.08664 18.9989 4.61048 18.9521 5.12962 18.8774C6.10415 18.7371 6.74332 18.159 6.93846 17.2438C7.13371 16.3381 7.09553 15.4537 6.57375 14.662ZM7.9679 3.08257C8.32951 2.63784 8.47122 2.11424 8.48899 1.48389C8.47741 1.39171 8.46881 1.23682 8.43946 1.08422C8.41496 0.956628 8.37905 0.8315 8.33215 0.710342C8.04002 -0.0680199 7.31222 -0.232429 6.72716 0.34518C6.14393 0.921872 5.95395 2.18165 6.34067 2.91771C6.72039 3.64069 7.45094 3.71647 7.9679 3.08257ZM5.18694 3.02605C5.63236 2.5827 5.73532 1.69679 5.40294 1.15851C5.1076 0.679615 4.59133 0.652443 4.24268 1.10371C4.01579 1.39652 3.92292 1.73967 3.92567 2.11068C3.92223 2.43044 3.99733 2.70342 4.14592 2.92298C4.41695 3.32277 4.84735 3.36461 5.18694 3.02605ZM3.23387 3.31887C3.42098 3.08739 3.47751 2.81131 3.48977 2.52193C3.47613 2.22384 3.41754 1.94146 3.22172 1.70895C2.98222 1.42587 2.644 1.42794 2.40461 1.70895C2.06008 2.11424 2.05447 2.90796 2.39383 3.32059C2.63987 3.62154 2.99093 3.62154 3.23387 3.31887ZM1.94624 3.85222C2.1494 3.48786 2.02936 2.87001 1.70398 2.61136C1.45897 2.41622 1.16994 2.46965 1.03339 2.75341C0.971936 2.88434 0.952101 3.03442 0.912661 3.17613C0.944764 3.50151 1.03545 3.78527 1.28505 3.98946C1.52249 4.18425 1.79616 4.12176 1.94624 3.85222ZM0.871846 4.81746C0.964025 4.67369 1.00129 4.49277 1.06629 4.31621C1.00209 4.14768 0.965745 3.9804 0.880559 3.84534C0.739539 3.62154 0.482952 3.62303 0.312237 3.82757C0.102083 4.07751 0.0870638 4.55365 0.282199 4.81884C0.453028 5.04986 0.717527 5.06041 0.871846 4.81746ZM11.8014 9.66591C11.8034 9.64768 10.9817 9.48201 10.5657 9.48201C9.74957 9.47984 9.1449 10.0569 8.94255 10.911C8.75051 11.7146 8.94748 12.4176 9.35575 13.0864C9.64547 13.5632 9.96809 14.0248 10.2117 14.5273C10.7137 15.5592 10.632 16.5861 9.95411 17.528C9.74258 17.8217 9.43336 18.0521 9.14708 18.2819C8.73732 18.6072 8.2825 18.8753 7.88834 19.2187C7.17418 19.8422 6.90326 20.6848 6.84983 21.6112C6.79469 22.546 7.25581 23.2712 8.15811 23.6671C8.63941 23.8781 9.13092 24.0616 9.67126 23.9715C10.5683 23.8208 11.1505 23.2469 11.5436 22.451C11.6608 22.2129 11.7439 21.9547 11.82 21.6978C12.1174 20.7037 12.6445 19.8442 13.3022 19.0582C13.86 18.3879 14.4408 17.7346 14.9532 17.0303C15.5242 16.2407 15.8664 15.3351 15.9689 14.3592C16.0904 13.1982 15.631 12.2549 14.8513 11.4629C13.9899 10.5916 12.9442 10.0432 11.8014 9.66591ZM11.2414 7.95934C11.8089 7.35296 11.9612 6.08767 11.5521 5.37592C11.1437 4.66383 10.3994 4.62852 9.9087 5.30117C9.83326 5.40596 9.76207 5.51729 9.70486 5.63389C9.6371 5.7717 9.58688 5.91834 9.55123 6.00558C9.40115 6.61747 9.3984 7.16057 9.62873 7.68521C9.95686 8.43399 10.6808 8.55552 11.2414 7.95934ZM13.3546 8.5475C13.5571 8.37541 13.701 8.13212 13.7825 7.82279C13.8852 7.46531 13.8873 7.11001 13.7449 6.76618C13.5291 6.23947 13.0244 6.12849 12.6118 6.51177C12.1497 6.94285 12.0114 7.8236 12.3228 8.36876C12.5587 8.7862 12.986 8.85923 13.3546 8.5475ZM14.9373 9.39775C15.3743 9.09025 15.5801 8.32485 15.3554 7.84205C15.199 7.50659 14.8743 7.4151 14.5686 7.62388C14.3159 7.79562 14.186 8.05221 14.0932 8.33597C14.0289 8.61904 14.0101 8.89936 14.1282 9.17223C14.2825 9.52833 14.6182 9.62223 14.9373 9.39775ZM15.2263 10.0303C15.2997 10.3291 15.5474 10.462 15.8281 10.3385C16.1226 10.2075 16.286 9.95873 16.4026 9.65365C16.4026 9.50632 16.4243 9.35624 16.3985 9.21385C16.3433 8.90292 16.0795 8.77588 15.7904 8.89867C15.4078 9.06102 15.1264 9.62441 15.2263 10.0303ZM16.8083 10.4393C16.698 10.1975 16.4509 10.126 16.2561 10.3046C16.1381 10.4129 16.0592 10.5636 15.9517 10.7096C15.9672 10.8974 15.9559 11.0809 16.0056 11.2444C16.09 11.5194 16.3476 11.5794 16.5738 11.4022C16.832 11.1982 16.9431 10.7357 16.8083 10.4393Z" fill="white"/>
</svg>''';

  static const String _japCardIconSvg = '''<svg width="20" height="24" viewBox="0 0 20 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9.99208 4.02498C8.88029 4.02498 7.97959 3.12428 7.97959 2.01249C7.97959 0.900695 8.88029 0 9.99208 0C10.7098 0 11.3431 0.379981 11.709 0.956988C11.132 1.39326 10.7802 2.06878 10.7802 2.84282C10.7802 3.1665 10.8365 3.49019 10.9631 3.77166C10.6676 3.92647 10.3439 4.02498 9.99208 4.02498ZM9.99208 18.042C10.0624 17.7324 10.2032 17.5354 10.3298 17.3665C10.5128 17.1132 10.6957 16.8599 10.7098 16.2125C10.1891 16.114 9.75283 15.8325 9.44322 15.4244C9.93579 14.9881 10.2313 14.3548 10.2313 13.6652C10.2313 13.2571 10.1328 12.8912 9.96393 12.5534C10.2876 12.3423 10.6676 12.2157 11.0757 12.2157C12.1875 12.2157 13.0882 13.1304 13.0882 14.2422C13.0882 15.2133 12.3846 16.0295 11.4557 16.2125C11.4557 17.1132 11.1602 17.5073 10.935 17.8028C10.8787 17.9013 10.8224 17.9717 10.7943 18.042H11.2728C11.4839 18.042 11.6527 18.1968 11.6527 20.5612C11.6527 20.7723 11.4839 20.9411 11.2728 20.9411H9.42915C9.21805 20.9411 9.04917 20.7723 9.04917 20.5612V18.4079C9.04917 18.1968 9.21805 18.042 9.42915 18.042H9.99208ZM11.7513 23.9951H8.93658C8.82399 23.9951 8.72548 23.9388 8.65511 23.8684C8.58475 23.784 8.5566 23.6714 8.57067 23.5588L8.95065 21.1523C9.07731 21.2508 9.24619 21.3071 9.42915 21.3071H11.2728C11.4557 21.3071 11.6105 21.2508 11.7372 21.1523L12.1312 23.5588C12.1453 23.6714 12.1172 23.784 12.0327 23.8684C11.9624 23.9388 11.8638 23.9951 11.7513 23.9951ZM6.79743 4.74272C5.68564 4.74272 4.78494 3.84203 4.78494 2.73023C4.78494 1.61844 5.68564 0.717741 6.79743 0.717741C7.17741 0.717741 7.52924 0.830328 7.82478 0.999208C7.68405 1.30882 7.59961 1.64658 7.59961 2.01249C7.59961 2.7443 7.93737 3.40575 8.47216 3.8561C8.10625 4.39089 7.5011 4.74272 6.79743 4.74272ZM4.09535 6.6004C2.98355 6.6004 2.08286 5.69971 2.08286 4.58791C2.08286 3.47612 2.98355 2.57542 4.09535 2.57542C4.20793 2.57542 4.30645 2.57542 4.41903 2.5895C4.40496 2.64579 4.40496 2.68801 4.40496 2.73023C4.40496 3.79981 5.10863 4.7005 6.06562 5.01011C5.86859 5.91081 5.05233 6.6004 4.09535 6.6004ZM2.01249 9.11953C0.914768 9.11953 0 8.21884 0 7.10704C0 6.07969 0.774035 5.23529 1.75917 5.10863C1.99842 6.15006 2.91318 6.93816 4.02498 6.96631V7.10704C4.02498 8.20477 3.12428 9.11953 2.01249 9.11953ZM2.30803 12.3564C1.21031 12.3564 0.29554 11.4557 0.29554 10.3439C0.29554 9.87949 0.464421 9.45729 0.731814 9.10546C1.09772 9.34471 1.54807 9.48544 2.01249 9.48544C2.64579 9.48544 3.2228 9.24619 3.645 8.83807C4.0672 9.21805 4.33459 9.75283 4.33459 10.3439C4.33459 11.4557 3.41983 12.3564 2.30803 12.3564ZM4.78494 14.4956C3.74351 14.4956 2.88504 13.7074 2.78652 12.6942C3.84203 12.4831 4.64421 11.5824 4.7005 10.4846C4.72865 10.4846 4.75679 10.4706 4.78494 10.4706C5.89674 10.4706 6.79743 11.3853 6.79743 12.4971C6.79743 13.5949 5.89674 14.4956 4.78494 14.4956ZM7.83886 15.6777C7.05075 15.6777 6.36116 15.1992 6.0234 14.5237C6.71299 14.1156 7.17741 13.3556 7.17741 12.4971C7.17741 12.2438 7.14926 12.0186 7.0789 11.7935C7.31814 11.695 7.57146 11.6527 7.83886 11.6527C8.95065 11.6527 9.85135 12.5534 9.85135 13.6652C9.85135 14.7629 8.95065 15.6777 7.83886 15.6777ZM14.0311 14.8192C13.82 14.8192 13.6089 14.7911 13.4119 14.7207C13.4401 14.5659 13.4541 14.397 13.4541 14.2422C13.4682 13.2993 12.9334 12.4971 12.1453 12.1031C12.4268 11.3431 13.1727 10.7943 14.0311 10.7943C15.1429 10.7943 16.0436 11.695 16.0436 12.8068C16.0436 13.9185 15.1429 14.8192 14.0311 14.8192ZM14.2563 10.4284C14.2563 9.31656 15.1711 8.41586 16.2829 8.41586C17.3806 8.41586 18.2954 9.31656 18.2954 10.4284C18.2954 11.4979 17.451 12.3705 16.3955 12.4408C16.2266 11.3713 15.354 10.5409 14.2563 10.4284ZM15.5651 8.14847C15.4525 7.89515 15.3962 7.62776 15.3962 7.34629C15.3962 6.2345 16.2969 5.3338 17.4087 5.3338C18.5205 5.3338 19.4212 6.2345 19.4212 7.34629C19.4212 8.14847 18.9709 8.82399 18.2954 9.16175C17.8732 8.48623 17.1273 8.03588 16.2829 8.03588C16.0296 8.03588 15.7903 8.0781 15.5651 8.14847ZM15.2977 6.2345C14.5659 5.93896 14.0452 5.22121 14.0452 4.37681C14.0452 3.26502 14.9459 2.36432 16.0577 2.36432C17.1695 2.36432 18.0702 3.26502 18.0702 4.37681C18.0702 4.60199 18.028 4.82716 17.9576 5.02419C17.7887 4.98197 17.6058 4.96789 17.4087 4.96789C16.494 4.96789 15.7059 5.47453 15.2977 6.2345ZM13.1586 4.85531C12.0468 4.85531 11.1461 3.95461 11.1461 2.84282C11.1461 1.73102 12.0468 0.830328 13.1586 0.830328C14.0452 0.830328 14.7911 1.40734 15.0726 2.19544C14.2422 2.57542 13.6652 3.40575 13.6652 4.37681C13.6652 4.51755 13.6793 4.64421 13.6934 4.78494C13.5245 4.82716 13.3415 4.85531 13.1586 4.85531Z" fill-rule="evenodd" clip-rule="evenodd" fill="white"/>
</svg>''';

  static const String _bhajanCardIconSvg = '''<svg width="17" height="25" viewBox="0 0 17 25" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M15.6198 15.6045C16.3824 14.3284 16.8883 12.7146 16.9865 11.1177C17.0488 10.0927 16.8204 9.01676 16.3258 8.00501C15.55 6.41565 14.2174 5.52282 12.93 4.66019C11.9692 4.01652 11.0613 3.40871 10.4195 2.54042L10.3044 2.38564C9.92497 1.87599 9.49649 1.29838 9.42853 0.813271C9.36058 0.322496 8.91511 -0.0267086 8.42811 0.00160532C8.18986 0.0177226 7.96664 0.123794 7.80366 0.298333C7.64069 0.472872 7.55015 0.70283 7.55038 0.941627V17.7601C6.75948 17.2806 5.78548 16.9862 4.71899 16.9862C2.11788 16.9862 0 18.6794 0 20.7614C0 22.8434 2.11788 24.5366 4.71899 24.5366C7.32009 24.5366 9.43797 22.8434 9.43797 20.7614V9.76047C10.8556 10.3022 13.1754 11.682 13.8134 14.9042C13.6945 15.0797 13.5812 15.2685 13.4491 15.4195C13.1037 15.8102 13.1414 16.4067 13.5341 16.7502C13.9229 17.0975 14.5194 17.056 14.8648 16.6653C15.1177 16.3784 15.3424 16.0424 15.5576 15.6913C15.5802 15.6649 15.601 15.6366 15.6198 15.6045Z" fill="white"/>
</svg>''';

  static const String _granthCardIconSvg = '''<svg width="24" height="18" viewBox="0 0 24 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M22.9044 2.1814V14.1789C22.9044 14.7575 22.6746 15.3123 22.2655 15.7214C21.8564 16.1305 21.3015 16.3603 20.723 16.3603C18.9016 16.3603 15.335 16.3603 13.7753 17.451H22.9044C23.1936 17.451 23.4711 17.3361 23.6756 17.1315C23.8802 16.927 23.9951 16.6496 23.9951 16.3603V3.27208C23.9951 2.98281 23.8802 2.70539 23.6756 2.50085C23.4711 2.29631 23.1936 2.1814 22.9044 2.1814ZM1.09068 14.1789V2.1814C0.801417 2.1814 0.523997 2.29631 0.319454 2.50085C0.114911 2.70539 0 2.98281 0 3.27208V16.3603C0 16.6496 0.114911 16.927 0.319454 17.1315C0.523997 17.3361 0.801417 17.451 1.09068 17.451H10.2197C8.67094 16.3603 5.0935 16.3603 3.27205 16.3603C2.69352 16.3603 2.13868 16.1305 1.72959 15.7214C1.32051 15.3123 1.09068 14.7575 1.09068 14.1789Z" fill="white"/>
<path d="M3.27214 0C2.98287 0 2.70545 0.114911 2.50091 0.319454C2.29637 0.523998 2.18146 0.801417 2.18146 1.09069V14.1789C2.18146 14.4682 2.29637 14.7456 2.50091 14.9501C2.70545 15.1547 2.98287 15.2696 3.27214 15.2696C6.49512 15.2696 10.0289 15.4332 11.4523 17.1074V1.48333C9.5054 0.147243 6.26062 0 3.27214 0ZM21.8138 14.1789V1.09069C21.8138 0.801417 21.6989 0.523998 21.4943 0.319454C21.2898 0.114911 21.0124 0 20.7231 0C17.7346 0 14.4898 0.147243 12.543 1.48333V17.1074C13.9663 15.4332 17.5001 15.2696 20.7231 15.2696C21.0124 15.2696 21.2898 15.1547 21.4943 14.9501C21.6989 14.7456 21.8138 14.4682 21.8138 14.1789Z" fill="white"/>
</svg>''';

  static const String _radioSignalSvg = '''<svg width="20" height="14" viewBox="0 0 20 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M13.5399 10.9905C13.3432 10.9899 13.1511 10.9341 12.9875 10.83C12.824 10.726 12.6963 10.5784 12.6204 10.4056C12.5446 10.2328 12.5239 10.0425 12.5609 9.85856C12.598 9.67462 12.6912 9.50517 12.8289 9.37142C13.5789 8.65361 13.9999 7.68217 13.9999 6.66952C13.9999 5.65688 13.5789 4.68544 12.8289 3.96763C12.6475 3.78708 12.5479 3.54588 12.5515 3.29603C12.5551 3.04617 12.6617 2.80769 12.8483 2.63201C13.0349 2.45632 13.2865 2.35751 13.5488 2.35687C13.8112 2.35623 14.0633 2.45382 14.2509 2.62859C15.3712 3.70283 15.9999 5.15545 15.9999 6.66952C15.9999 8.18359 15.3712 9.63622 14.2509 10.7105C14.1576 10.7995 14.0468 10.8701 13.9248 10.9182C13.8027 10.9662 13.6719 10.9908 13.5399 10.9905ZM7.16288 10.7152C7.35142 10.5376 7.45818 10.296 7.45968 10.0435C7.46118 9.79093 7.3573 9.54816 7.17088 9.36856C6.42088 8.65076 5.99984 7.67931 5.99984 6.66667C5.99984 5.65402 6.42088 4.68258 7.17088 3.96478C7.26573 3.87638 7.34114 3.77088 7.39274 3.65444C7.44434 3.538 7.47109 3.41295 7.47143 3.28656C7.47177 3.16018 7.4457 3.03499 7.39472 2.9183C7.34375 2.80162 7.2689 2.69576 7.17453 2.60689C7.08017 2.51803 6.96817 2.44795 6.84508 2.40073C6.72199 2.3535 6.59026 2.33009 6.45757 2.33184C6.32488 2.33359 6.19388 2.36048 6.07221 2.41094C5.95054 2.4614 5.84063 2.53441 5.74889 2.62573C4.62858 3.69997 3.99983 5.1526 3.99983 6.66667C3.99983 8.18074 4.62858 9.63336 5.74889 10.7076C5.93536 10.8872 6.18907 10.9888 6.45423 10.9903C6.7194 10.9917 6.9743 10.8928 7.16288 10.7152ZM17.4318 13.02C19.0847 11.2783 19.9997 9.01428 19.9997 6.66667C19.9997 4.31906 19.0847 2.05504 17.4318 0.313363C17.2539 0.126071 17.0051 0.0137769 16.7402 0.00118524C16.4753 -0.0114064 16.216 0.0767356 16.0193 0.246221C15.8227 0.415706 15.7048 0.652651 15.6916 0.904931C15.6783 1.15721 15.7709 1.40416 15.9488 1.59145C17.2689 2.98289 17.9997 4.79141 17.9997 6.66667C17.9997 8.54192 17.2689 10.3504 15.9488 11.7419C15.7709 11.9292 15.6783 12.1761 15.6916 12.4284C15.7048 12.6807 15.8227 12.9176 16.0193 13.0871C16.216 13.2566 16.4753 13.3447 16.7402 13.3321C17.0051 13.3196 17.2539 13.2073 17.4318 13.02ZM3.9799 13.0866C4.17648 12.9172 4.29439 12.6804 4.30771 12.4283C4.32102 12.1761 4.22865 11.9292 4.0509 11.7419C2.73087 10.3504 2.00008 8.54192 2.00008 6.66667C2.00008 4.79141 2.73087 2.98289 4.0509 1.59145C4.13902 1.49871 4.20709 1.39036 4.25124 1.27256C4.29538 1.15477 4.31473 1.02985 4.30819 0.904931C4.30164 0.780015 4.26932 0.657549 4.21308 0.544528C4.15684 0.431506 4.07777 0.330141 3.9804 0.246221C3.88303 0.1623 3.76925 0.0974673 3.64556 0.0554241C3.52188 0.0133808 3.39071 -0.00504952 3.25955 0.00118524C2.99466 0.0137769 2.74587 0.126071 2.56791 0.313363C0.915082 2.05504 0 4.31906 0 6.66667C0 9.01428 0.915082 11.2783 2.56791 13.02C2.74591 13.2071 2.99464 13.3192 3.25941 13.3317C3.52419 13.3442 3.78334 13.256 3.9799 13.0866ZM9.99987 5.2381C9.7032 5.2381 9.41319 5.32189 9.16652 5.47886C8.91985 5.63583 8.72759 5.85894 8.61406 6.11998C8.50053 6.38102 8.47082 6.66825 8.5287 6.94537C8.58658 7.22248 8.72944 7.47703 8.93922 7.67681C9.14899 7.8766 9.41627 8.01266 9.70724 8.06778C9.99821 8.1229 10.2998 8.09461 10.5739 7.98649C10.848 7.87836 11.0822 7.69526 11.2471 7.46033C11.4119 7.22541 11.4999 6.94921 11.4999 6.66667C11.4999 6.28779 11.3418 5.92443 11.0605 5.65652C10.7792 5.38861 10.3977 5.2381 9.99987 5.2381Z" fill="white"/>
</svg>''';

  static const String _eyeIconSvg = '''<svg width="22" height="14" viewBox="0 0 22 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M21.8602 6.25978C21.6637 6.00412 16.9808 0 10.9999 0C5.01902 0 0.335926 6.00413 0.139602 6.25953C0.0488853 6.37771 0 6.52023 0 6.66654C0 6.81285 0.0488853 6.95538 0.139602 7.07356C0.335926 7.32921 5.01902 13.3333 10.9999 13.3333C16.9808 13.3333 21.6637 7.32917 21.8602 7.07376C21.951 6.95564 22 6.8131 22 6.66677C22 6.52044 21.951 6.3779 21.8602 6.25978ZM10.9999 11.954C6.59434 11.954 2.77866 7.96897 1.64914 6.6662C2.7772 5.36228 6.58489 1.3793 10.9999 1.3793C15.4052 1.3793 19.2207 5.36367 20.3507 6.66714C19.2226 7.97101 15.4149 11.954 10.9999 11.954Z" fill="white"/>
<path d="M10.9997 2.52869C8.60028 2.52869 6.64807 4.38501 6.64807 6.66664C6.64807 8.94826 8.60028 10.8046 10.9997 10.8046C13.3992 10.8046 15.3514 8.94826 15.3514 6.66664C15.3514 4.38501 13.3992 2.52869 10.9997 2.52869ZM10.9997 9.42524C9.40001 9.42524 8.09866 8.18776 8.09866 6.66664C8.09866 5.14551 9.40006 3.90803 10.9997 3.90803C12.5994 3.90803 13.9008 5.14551 13.9008 6.66664C13.9008 8.18776 12.5995 9.42524 10.9997 9.42524Z" fill="white"/>
</svg>''';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadProfileName();
    GlobalSocketService.instance.connect();
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('user_name') ?? '';
    final pic = prefs.getString('profile_pic') ?? '';
    final viewedList = prefs.getStringList('viewed_darshan_ids') ?? [];
    setState(() {
      _profileName = fullName.isNotEmpty ? fullName : 'User';
      _profilePic = pic;
      _viewedDarshanIds = viewedList.toSet();
    });
    _messageCount = YatraPersonalChatService().unreadMessageCount.value;
    YatraPersonalChatService().unreadMessageCount.addListener(_onUnreadMessagesChanged);
    YatraPersonalChatService().refreshUnreadCount();

    // Fetch live dashboard data from backend
    _fetchDashboardData();
    _loadHomeFourCardsProgress();
    _initYatraGroupSocket();
  }

  Future<void> _loadHomeFourCardsProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      await BhajanLibraryService.instance.init(token: token);

      // 1. Dynamic Last Jap from SharedPreferences
      String targetJapId = prefs.getString('last_active_jap_id') ?? prefs.getString('last_jap_id') ?? '';
      DateTime latestJapTime = DateTime.fromMillisecondsSinceEpoch(0);
      double resolvedJapProgress = 0.0;
      int resolvedJapCount = 0;
      int resolvedJapTarget = prefs.getInt('last_jap_target') ?? 108;

      for (final k in prefs.getKeys()) {
        if (k.startsWith('jap_session_v2_')) {
          final val = prefs.getString(k);
          if (val != null) {
            try {
              final m = jsonDecode(val) as Map<String, dynamic>;
              final rawId = (m['japId'] ?? k.replaceFirst('jap_session_v2_', '')).toString();
              final baseId = rawId.replaceAll(RegExp(r'_(jal|dhup|prakash|pushp)$'), '');
              final current = (m['currentCount'] as num?)?.toInt() ?? 0;
              final target = (m['targetCount'] as num?)?.toInt() ?? 108;
              final lastAt = DateTime.tryParse((m['lastJapAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              if (current > 0 && lastAt.isAfter(latestJapTime)) {
                latestJapTime = lastAt;
                targetJapId = baseId;
                resolvedJapCount = current;
                resolvedJapTarget = target > 0 ? target : 108;
                resolvedJapProgress = (current > 0 && current < resolvedJapTarget)
                    ? (current / resolvedJapTarget).clamp(0.05, 1.0)
                    : 0.0;
              }
            } catch (_) {}
          }
        }
      }

      if (targetJapId.isNotEmpty && resolvedJapCount == 0) {
        try {
          final sess = await JapOfflineRepository.getSession(
            targetJapId,
            defaultTarget: resolvedJapTarget,
          );
          resolvedJapCount = sess.currentCount;
          resolvedJapTarget = sess.targetCount > 0 ? sess.targetCount : 108;
          resolvedJapProgress = (resolvedJapCount > 0 && resolvedJapCount < resolvedJapTarget)
              ? (resolvedJapCount / resolvedJapTarget).clamp(0.05, 1.0)
              : 0.0;
        } catch (_) {}
      }

      String resolvedJapTitle = 'Shree Krishna';
      String resolvedJapImg = 'assets/images/h2.jpg';
      JapConfig? resolvedJapConfig;

      if (targetJapId.isNotEmpty) {
        final savedLastId = prefs.getString('last_jap_id') ?? '';
        final savedLastTitle = prefs.getString('last_jap_title') ?? '';
        final savedLastImg = prefs.getString('last_jap_image') ?? '';

        JapThemeConfig? matchedTheme;
        for (final t in JapThemeConfig.allThemes) {
          if (t.id.toLowerCase() == targetJapId.toLowerCase()) {
            matchedTheme = t;
            break;
          }
        }

        if (savedLastId == targetJapId && savedLastTitle.isNotEmpty) {
          resolvedJapTitle = savedLastTitle;
          resolvedJapImg = (savedLastTitle.toLowerCase().contains('krishna') &&
                  !(prefs.getBool('last_jap_custom') ?? false))
              ? 'assets/images/h2.jpg'
              : (savedLastImg.isNotEmpty ? savedLastImg : 'assets/images/h2.jpg');
          resolvedJapConfig = JapConfig(
            id: targetJapId,
            name: savedLastTitle,
            thumbnailUrl: savedLastImg.isNotEmpty ? savedLastImg : 'assets/images/h2.jpg',
            darshanImageUrl: savedLastImg.isNotEmpty ? savedLastImg : 'assets/images/h2.jpg',
            shlokText: prefs.getString('last_jap_shlok') ?? matchedTheme?.mantraText ?? 'कृष्ण',
            shlokAudioUrl: prefs.getString('last_jap_audio') ?? matchedTheme?.audioAsset,
            targetCount: resolvedJapTarget,
            progress: resolvedJapCount,
            effectPack: EffectPack.resolve(
              name: savedLastTitle,
              particleShape: prefs.getString('last_jap_shape'),
            ),
            particleShape: prefs.getString('last_jap_shape'),
            isCustom: prefs.getBool('last_jap_custom') ?? false,
          );
        } else if (matchedTheme != null) {
          resolvedJapTitle = matchedTheme.name;
          resolvedJapImg = matchedTheme.id == 'krishna'
              ? 'assets/images/h2.jpg'
              : matchedTheme.imageAsset;
          resolvedJapConfig = JapConfig(
            id: matchedTheme.id,
            name: matchedTheme.name,
            thumbnailUrl: matchedTheme.imageAsset,
            darshanImageUrl: matchedTheme.imageAsset,
            shlokText: matchedTheme.mantraText,
            shlokAudioUrl: matchedTheme.audioAsset,
            targetCount: resolvedJapTarget,
            progress: resolvedJapCount,
            effectPack: EffectPack.resolve(name: matchedTheme.name),
          );
        } else {
          final customList = await JapOfflineRepository.getCustomJaps();
          for (final raw in customList) {
            final cfg = JapConfig.fromJson(raw);
            if (cfg.id == targetJapId) {
              resolvedJapTitle = cfg.name;
              resolvedJapImg = cfg.thumbnailUrl.isNotEmpty ? cfg.thumbnailUrl : 'assets/images/h2.jpg';
              cfg.progress = resolvedJapCount;
              resolvedJapConfig = cfg;
              break;
            }
          }
        }
      }

      // 2. Dynamic Recent Granth & Progress from SharedPreferences (NO default half status bar)
      final savedGranthTitle = prefs.getString('recent_granth_title') ?? '';
      final savedGranthImg = prefs.getString('recent_granth_image') ?? '';
      final savedGranthProg = prefs.getDouble('recent_granth_progress') ?? 0.0;

      if (mounted) {
        setState(() {
          _japCardTitle = resolvedJapTitle;
          _japCardImage = resolvedJapImg;
          _japCardProgress = resolvedJapProgress;
          _lastJapEntry = resolvedJapConfig;

          if (savedGranthTitle.isNotEmpty) _granthCardTitle = savedGranthTitle;
          if (savedGranthImg.isNotEmpty && !savedGranthImg.endsWith('bhagavad_gita.png')) {
            _granthCardImage = savedGranthImg;
          }
          _granthCardProgress = savedGranthProg > 0 ? savedGranthProg.clamp(0.05, 1.0) : 0.0;
        });
      }

      // 3. Dynamic Pending / Continue Yatra from Backend
      if (token.isNotEmpty) {
        final continueRes = await ApiService.getContinueYatra(token: token);
        if (mounted) {
          if (continueRes.data != null) {
            final d = continueRes.data!;
            final pct = (d.progressPercent / 100.0).clamp(0.05, 1.0);
            setState(() {
              _continueYatraData = d;
              if (d.title.isNotEmpty) _yatraCardTitle = d.title;
              if (d.coverImage.isNotEmpty) _yatraCardImage = d.coverImage;
              _yatraCardProgress = pct;
            });
          } else {
            setState(() {
              _continueYatraData = null;
              _yatraCardProgress = 0.0;
            });
          }
        }
      }
    } catch (_) {}
  }

  void _onUnreadMessagesChanged() {
    if (mounted) {
      setState(() {
        _messageCount = YatraPersonalChatService().unreadMessageCount.value;
      });
    }
  }

  Future<void> _initYatraGroupSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty) {
        YatraGroupSocketService().init(token);
      }
    } catch (e) {
      debugPrint('YatraGroupSocket init error: $e');
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      debugPrint('🔑 Retrieved Auth Token from storage: $token');
      if (token.isNotEmpty) {
        final results = await Future.wait([
          ApiService.getDarshanHome(token).timeout(const Duration(seconds: 5)).catchError((e) {
            debugPrint('Error getDarshanHome: $e');
            return <String, dynamic>{};
          }),
          ApiService.getDarshansList(token: token, limit: 10).timeout(const Duration(seconds: 5)).catchError((e) {
            debugPrint('Error getDarshansList: $e');
            return <String, dynamic>{};
          }),
        ]);

        final homeData = results[0];
        final darshanListData = results[1];

        if (mounted) {
          if (homeData.isNotEmpty && homeData['user'] != null) {
            debugPrint('👤 Home Screen User Data (ID): ${homeData['user']}');
            setState(() {
              _profileName = homeData['user']['name'] ?? 'User';
              _profilePic = homeData['user']['profile_pic'] ?? '';
              _notificationCount = homeData['notificationCount'] ?? 2;
              _messageCount = YatraPersonalChatService().unreadMessageCount.value;
            });
          }

          _processLiveDarshans(darshanListData, homeData);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLiveDarshans = false;
            _liveDarshanBanners = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoadingLiveDarshans = false;
        });
      }
    }
  }

  void _processLiveDarshans(Map<String, dynamic> darshanListData, Map<String, dynamic> homeData) {
    final List<Map<String, dynamic>> banners = [];

    // 1. Process docs from /user/darshan/list
    final docs = darshanListData['docs'] as List<dynamic>? ?? [];
    for (final item in docs) {
      if (item is Map) {
        final bool isLive = (item['is_live_status'] == true) ||
            (item['live_darshan_info'] is Map && item['live_darshan_info']['is_live_status'] == true) ||
            (item['yt_info'] is Map && item['yt_info']['isLiveStatus'] == true);

        final String darshanId = (item['darshan_id'] ?? item['_id'])?.toString() ?? '';
        final String title = (item['name'] ?? item['temple']?['name'] ?? 'Sacred Darshan').toString();

        String desc = (item['short_desc'] ?? item['description'] ?? '').toString();
        if (desc.isEmpty && item['temple'] != null) {
          final city = item['temple']['city']?.toString() ?? '';
          final state = item['temple']['state']?.toString() ?? '';
          if (city.isNotEmpty || state.isNotEmpty) {
            desc = '${isLive ? "Live Aarti and divine blessings" : "Divine darshan and blessings"} from $city${city.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state.';
          }
        }
        if (desc.isEmpty) {
          desc = isLive ? 'Join live aarti and seek divine blessings.' : 'Daily darshan and sacred blessings.';
        }

        // Dynamic viewer calculation with unique user view check
        final dynamic liveInfo = item['live_darshan_info'];
        dynamic viewersRaw;
        if (liveInfo is Map) {
          viewersRaw = liveInfo['total_viewers'] ?? liveInfo['current_viewers'] ?? liveInfo['peak_viewers'];
        }
        viewersRaw ??= item['views'] ?? item['total_viewers'] ?? item['current_viewers'] ?? item['viewers'];

        int numericViews = _parseNumericViews(viewersRaw);
        final String viewsFormatted = _formatViewerCount(numericViews, darshanId: darshanId);

        // Dynamic temple banner image resolution
        String ytThumbnail = '';
        final dynamic ytObj = item['yt_info'] ?? item['youtube_darshan_details'];
        String ytId = (item['youtube_video_id'] ??
                (ytObj is Map ? ytObj['youtubeVideoId'] ?? ytObj['youtube_video_id'] : null) ??
                item['live_stream_url'] ??
                '')
            .toString();
        if (ytId.isNotEmpty) {
          if (ytId.contains('v=')) {
            ytId = ytId.split('v=').last.split('&').first;
          } else if (ytId.contains('youtu.be/')) {
            ytId = ytId.split('youtu.be/').last.split('?').first;
          }
          if (ytId.length == 11) {
            ytThumbnail = 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
          }
        }

        final String rawImg = (
          item['bannerImage'] ??
          item['banner_image'] ??
          item['temple']?['bannerImage'] ??
          item['temple']?['banner_image'] ??
          item['temple_id']?['bannerImage'] ??
          item['temple_id']?['banner_image'] ??
          item['image'] ??
          item['temple']?['thumbnailImage'] ??
          item['temple_id']?['thumbnailImage'] ??
          item['temple']?['image'] ??
          item['temple_id']?['image'] ??
          (ytThumbnail.isNotEmpty ? ytThumbnail : '')
        ).toString();
        final String resolvedImage = ApiService.resolveImageUrl(rawImg);

        banners.add({
          'id': darshanId,
          'title': title,
          'desc': desc,
          'views': viewsFormatted,
          'raw_views': numericViews,
          'image': resolvedImage,
          'isLive': isLive,
          'raw': item,
        });
      }
    }

    // 2. Also check featuredDarshans from /user/darshan/home
    if (homeData['featuredDarshans'] is List) {
      for (final item in homeData['featuredDarshans']) {
        if (item is Map) {
          final bool isLive = (item['is_live_status'] == true) ||
              (item['live_darshan_info'] is Map && item['live_darshan_info']['is_live_status'] == true) ||
              (item['yt_info'] is Map && item['yt_info']['isLiveStatus'] == true);

          final String darshanId = (item['darshan_id'] ?? item['_id'])?.toString() ?? '';
          final alreadyAdded = banners.any((b) => b['id'] == darshanId);
          if (!alreadyAdded) {
            final String title = (item['name'] ?? item['temple_id']?['name'] ?? 'Sacred Darshan').toString();
            String desc = (item['short_desc'] ?? item['description'] ?? '').toString();
            if (desc.isEmpty && item['temple_id'] != null) {
              final city = item['temple_id']['city']?.toString() ?? '';
              final state = item['temple_id']['state']?.toString() ?? '';
              if (city.isNotEmpty || state.isNotEmpty) {
                desc = '${isLive ? "Live Aarti and divine blessings" : "Divine darshan and blessings"} from $city${city.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state.';
              }
            }
            if (desc.isEmpty) {
              desc = isLive ? 'Join live aarti and seek divine blessings.' : 'Daily darshan and sacred blessings.';
            }
            int numericViews = _parseNumericViews(item['views'] ?? item['total_viewers'] ?? item['current_viewers']);
            final String viewsFormatted = _formatViewerCount(numericViews, darshanId: darshanId);

            final String rawImg = (
              item['bannerImage'] ??
              item['banner_image'] ??
              item['temple_id']?['bannerImage'] ??
              item['temple_id']?['banner_image'] ??
              item['image'] ??
              item['temple_id']?['thumbnailImage'] ??
              item['temple_id']?['image'] ??
              ''
            ).toString();
            final String resolvedImage = ApiService.resolveImageUrl(rawImg);

            banners.add({
              'id': darshanId,
              'title': title,
              'desc': desc,
              'views': viewsFormatted,
              'raw_views': numericViews,
              'image': resolvedImage,
              'isLive': isLive,
              'raw': item,
            });
          }
        }
      }
    }

    // Sort: Live streams appear first, followed by offline streams
    banners.sort((a, b) {
      final aLive = a['isLive'] == true ? 1 : 0;
      final bLive = b['isLive'] == true ? 1 : 0;
      return bLive.compareTo(aLive);
    });

    setState(() {
      _liveDarshanBanners = banners;
      _isLoadingLiveDarshans = false;
      _currentPage = 0;
    });

    if (banners.length > 1) {
      _startCarouselTimer();
    } else {
      _carouselTimer?.cancel();
    }
  }

  int _parseNumericViews(dynamic count) {
    if (count == null) return 0;
    if (count is num) return count.toInt();
    if (count is String) {
      final trimmed = count.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'live') return 0;
      return int.tryParse(trimmed) ?? 0;
    }
    return 0;
  }

  String _formatViewerCount(dynamic count, {String darshanId = ''}) {
    int viewsNum = _parseNumericViews(count);

    if (darshanId.isNotEmpty) {
      final isViewed = _viewedDarshanIds.contains(darshanId);
      if (isViewed && viewsNum < 1) {
        viewsNum = 1;
      }
    }

    return _formatNumber(viewsNum);
  }

  String _formatNumber(num number) {
    if (number >= 1000000) {
      final val = number / 1000000;
      return '${val.toStringAsFixed(val >= 10 ? 0 : 1).replaceAll('.0', '')}M';
    } else if (number >= 1000) {
      final val = number / 1000;
      return '${val.toStringAsFixed(val >= 10 ? 0 : 1).replaceAll('.0', '')}K';
    }
    return number.toInt().toString();
  }

  Future<void> _openLiveDarshan(Map<String, dynamic> banner) async {
    final darshanId = (banner['id'] ?? banner['darshan_id'] ?? '').toString();
    final title = banner['title']?.toString() ?? 'Live Darshan';
    final image = banner['image']?.toString() ?? '';

    final prefs = await SharedPreferences.getInstance();
    final viewedList = prefs.getStringList('viewed_darshan_ids') ?? [];

    // Track unique view: only increment if user enters for the first time!
    if (darshanId.isNotEmpty && !viewedList.contains(darshanId)) {
      viewedList.add(darshanId);
      await prefs.setStringList('viewed_darshan_ids', viewedList);

      final curViews = _parseNumericViews(banner['raw_views']);
      final newCount = curViews + 1;
      await prefs.setInt('darshan_views_$darshanId', newCount);

      if (mounted) {
        setState(() {
          _viewedDarshanIds.add(darshanId);
          banner['raw_views'] = newCount;
          banner['views'] = _formatViewerCount(newCount, darshanId: darshanId);
        });
      }

      // Record unique join/view to backend
      final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
      ApiService.recordDarshanView(token, darshanId);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveDarshanScreen(
          darshanId: darshanId,
          templeName: title,
          imageUrl: image,
        ),
      ),
    );

    // On return from Darshan screen: verify view count remains 1 and is NOT incremented again
    if (mounted && darshanId.isNotEmpty) {
      final savedCount = prefs.getInt('darshan_views_$darshanId');
      if (savedCount != null) {
        setState(() {
          banner['raw_views'] = savedCount;
          banner['views'] = _formatViewerCount(savedCount, darshanId: darshanId);
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final code = LanguageManager.instance.currentLanguageCode;
    if (hour < 12) {
      if (code == 'gu') return 'શુભ પ્રભાત';
      if (code == 'hi') return 'शुभ प्रभात';
      if (code == 'mr') return 'शुभ सकाळ';
      return 'Good Morning';
    } else if (hour < 17) {
      if (code == 'gu') return 'શુભ બપોર';
      if (code == 'hi') return 'शुभ दोपहर';
      if (code == 'mr') return 'शुभ दुपार';
      return 'Good Afternoon';
    } else {
      if (code == 'gu') return 'શુભ સંધ્યા';
      if (code == 'hi') return 'शुभ संध्या';
      if (code == 'mr') return 'शुभ संध्याकाळ';
      return 'Good Evening';
    }
  }

  String _getDivineSalutation() {
    final code = LanguageManager.instance.currentLanguageCode;
    if (code == 'gu') return 'જય શ્રી રામ';
    if (code == 'hi') return 'जय श्री राम';
    if (code == 'mr') return 'जय श्री राम';
    return 'Jai Shree Ram';
  }

  String _getNavLabel(int index) {
    switch (LanguageManager.instance.currentLanguageCode) {
      case 'gu':
        return ['હોમ', 'દર્શન', 'જાપ', 'યાત્રા', 'પ્રોફાઇલ'][index];
      case 'hi':
        return ['होम', 'दर्शन', 'जाप', 'यात्रा', 'प्रोफ़ाइल'][index];
      case 'mr':
        return ['होम', 'दर्शन', 'जाप', 'यात्रा', 'प्रोफाइल'][index];
      default:
        return ['Home', 'Darshan', 'Jap', 'Yatra', 'Profile'][index];
    }
  }

  String _getCategoryLabel(String key) {
    final code = LanguageManager.instance.currentLanguageCode;
    switch (key) {
      case 'bhajan':
        return code == 'gu' ? 'ભજન' : (code == 'hi' ? 'भजन' : (code == 'mr' ? 'भजन' : 'Bhajan'));
      case 'granth':
        return code == 'gu' ? 'ગ્રંથ' : (code == 'hi' ? 'ग्रंथ' : (code == 'mr' ? 'ग्रंथ' : 'Granth'));
      case 'utsav':
        return code == 'gu' ? 'ઉત્સવ' : (code == 'hi' ? 'उत्सव' : (code == 'mr' ? 'उत्सव' : 'Utsav Vibes'));
      default:
        return key;
    }
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 17) {
      return '☀️';
    } else {
      return '🌙';
    }
  }

  String _resolveProfilePic(String pic) {
    return ApiService.resolveImageUrl(pic);
  }

  String _getMailSvg(int count) {
    final fill = count > 0 ? '#FF0000' : 'none';
    return '''<svg width="26" height="24" viewBox="0 0 26 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6.01417 3.9978C3.80516 3.9978 2.01416 5.7888 2.01416 7.9978V15.9978C2.01416 18.2068 3.80516 19.9978 6.01417 19.9978H18.0142C20.2232 19.9978 22.0142 18.2068 22.0142 15.9978V7.9978C22.0142 5.7888 20.2232 3.9978 18.0142 3.9978H6.01417ZM6.01417 5.9978H18.0142C19.0222 5.9978 19.8552 6.73781 19.9932 7.70781C19.0352 8.60081 17.6112 9.6968 16.6702 10.3728C14.5052 11.9278 12.6002 12.9978 12.0142 12.9978C11.4282 12.9978 9.52317 11.9288 7.35816 10.3728C6.41716 9.6968 5.49217 8.9658 4.79517 8.3728C4.49817 8.1198 4.27816 7.9158 4.10816 7.7478C4.24616 6.7778 5.00616 5.9978 6.01417 5.9978ZM4.02417 10.3518C6.56218 12.4048 10.2812 14.9858 12.0142 14.9978C13.1432 15.0058 15.0742 13.9278 17.0442 12.5668C18.0632 11.8618 19.1972 11.0248 20.0152 10.3378L20.0142 15.9978C20.0142 17.1028 19.1192 17.9978 18.0142 17.9978H6.01417C4.90916 17.9978 4.01416 17.1028 4.01416 15.9978L4.02417 10.3518Z" fill="#6B4226"/>
<circle cx="22" cy="4.5" r="4" fill="$fill"/>
</svg>''';
  }

  String _getBellSvg(int count) {
    final fill = count > 0 ? '#FF0000' : 'none';
    return '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 6.43994V9.76994" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round"/>
<path d="M12.02 2C8.34002 2 5.36002 4.98 5.36002 8.66V10.76C5.36002 11.44 5.08002 12.46 4.73002 13.04L3.46002 15.16C2.68002 16.47 3.22002 17.93 4.66002 18.41C9.44002 20 14.61 20 19.39 18.41C20.74 17.96 21.32 16.38 20.59 15.16L19.32 13.04C18.97 12.46 18.69 11.43 18.69 10.76V8.66C18.68 5 15.68 2 12.02 2Z" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round"/>
<path d="M15.33 18.8199C15.33 20.6499 13.83 22.1499 12 22.1499C11.09 22.1499 10.25 21.7699 9.65004 21.1699C9.05004 20.5699 8.67004 19.7299 8.67004 18.8199" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10"/>
<circle cx="18" cy="4.5" r="4" fill="$fill"/>
</svg>''';
  }

  Widget _buildDynamicHeader() {
    final greeting = _getGreeting();
    final icon = _getGreetingIcon();
    final profilePicUrl = _resolveProfilePic(_profilePic);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Stack(
          children: [
            // Left side: User Avatar & Info
            Positioned(
              left: 20,
              top: 0,
              child: Row(
                children: [
                  UserAvatar(
                    profilePic: _profilePic,
                    userName: _profileName,
                    size: 48,
                    borderColor: const Color(0xFFFF7700).withValues(alpha: 0.2),
                    borderWidth: 1.5,
                  ),
                  const SizedBox(width: 12),
                  // User Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getDivineSalutation(),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E2A36),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('🙏', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$greeting, $_profileName $icon',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Mail Action Button
            Positioned(
              left: 317,
              top: 12,
              width: 24,
              height: 24,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MessagesScreen()),
                ).then((_) {
                  YatraPersonalChatService().refreshUnreadCount();
                  _fetchDashboardData();
                }),
                child: SvgPicture.string(
                  _getMailSvg(_messageCount),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            
            // Notification Bell Action Button
            Positioned(
              left: 349,
              top: 12,
              width: 24,
              height: 24,
              child: GestureDetector(
                onTap: () => _showNotificationPopup(context),
                child: SvgPicture.string(
                  _getBellSvg(_notificationCount),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    if (_liveDarshanBanners.length <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _pageController.hasClients && _liveDarshanBanners.isNotEmpty) {
        int nextPage = (_currentPage + 1) % _liveDarshanBanners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    YatraPersonalChatService().unreadMessageCount.removeListener(_onUnreadMessagesChanged);
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHomeTabBody() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDynamicHeader(),

            // 2. Search gods, temples bar (full width)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFEFE6DB),
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  style: GoogleFonts.outfit(color: const Color(0xFF2E2A36)),
                  decoration: InputDecoration(
                    hintText: LocalizedApiHelper.parse('Search gods, temples, bhajans...'),
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: SizedBox(
                height: 353,
                child: _buildHeroSection(),
              ),
            ),

            // 4. Categories Section (Bhajan, Granth, Utsav Vibes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSvgCategoryCard(
                      svgAsset: 'assets/images/cat_bhajan.svg',
                      label: _getCategoryLabel('bhajan'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BhajanDashboardScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSvgCategoryCard(
                      svgAsset: 'assets/images/cat_granth.svg',
                      label: _getCategoryLabel('granth'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GranthScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSvgCategoryCard(
                      svgAsset: 'assets/images/cat_utsav.svg',
                      label: _getCategoryLabel('utsav'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FestivalsHomeTabContent()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Devotional 4-Card Horizontal Slider (Yatra, Jap, Bhajan, Granth)
            SizedBox(
              height: 208,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  BhajanLibraryService.instance,
                  BhajanAudioService.instance.currentTrackNotifier,
                  BhajanAudioService.instance.positionNotifier,
                  BhajanAudioService.instance.durationNotifier,
                ]),
                builder: (context, _) {
                  final audio = BhajanAudioService.instance;
                  final lib = BhajanLibraryService.instance;
                  final recentBhajan = audio.currentTrack ??
                      (lib.recentTracks.isNotEmpty
                          ? lib.recentTracks.first
                          : (lib.downloadedTracks.isNotEmpty ? lib.downloadedTracks.first : null));

                  final String bhajanTitle = (recentBhajan != null && recentBhajan.title.trim().isNotEmpty)
                      ? recentBhajan.title
                      : 'Mere Ghar ram aay..';
                  final String rawBhajanImg = (recentBhajan != null && recentBhajan.imagePath.trim().isNotEmpty)
                      ? (lib.getLocalImagePath(recentBhajan.id) ?? recentBhajan.imagePath)
                      : '';
                  final bool useDefaultBhajanArt = rawBhajanImg.isEmpty ||
                      rawBhajanImg.startsWith('assets/') ||
                      bhajanTitle.toLowerCase().contains('mere ghar');
                  final String bhajanImage = useDefaultBhajanArt ? 'assets/images/h3.jpg' : rawBhajanImg;

                  double bhajanProgress = 0.0;
                  if (audio.currentTrack != null && audio.duration.inMilliseconds > 0) {
                    bhajanProgress = (audio.position.inMilliseconds / audio.duration.inMilliseconds).clamp(0.0, 1.0);
                  } else if (recentBhajan != null && recentBhajan.id.isNotEmpty) {
                    bhajanProgress = audio.getSavedProgressSync(recentBhajan.id);
                  }

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    children: [
                      // Card 1: Recent / Pending Yatra
                      _buildNotchedDevotionalCard(
                        title: LocalizedApiHelper.parse(_yatraCardTitle),
                        imageUrl: _yatraCardImage,
                        fallbackAsset: 'assets/images/h1.jpg',
                        imageAlignment: const Alignment(-0.18, 0.0),
                        imageScale: 1.0,
                        badgeSvg: _yatraCardIconSvg,
                        svgWidth: 17,
                        svgHeight: 24,
                        progress: _yatraCardProgress,
                        showProgressBar: _yatraCardProgress > 0,
                        onTap: _openRecentYatraFromHome,
                      ),
                      const SizedBox(width: 10),

                      // Card 2: Last Jap
                      _buildNotchedDevotionalCard(
                        title: LocalizedApiHelper.parse(_japCardTitle),
                        imageUrl: _japCardImage,
                        fallbackAsset: 'assets/images/h2.jpg',
                        imageAlignment: const Alignment(0.0, -0.05),
                        imageScale: 1.16,
                        badgeSvg: _japCardIconSvg,
                        svgWidth: 20,
                        svgHeight: 24,
                        progress: _japCardProgress,
                        showProgressBar: _japCardProgress > 0,
                        onTap: _openLastJapFromHome,
                      ),
                      const SizedBox(width: 10),

                      // Card 3: Bhajan (Recent Bhajan -> Opens BhajanNowPlayingScreen & Resumes)
                      _buildNotchedDevotionalCard(
                        title: LocalizedApiHelper.parse(bhajanTitle),
                        imageUrl: bhajanImage,
                        fallbackAsset: 'assets/images/h3.jpg',
                        imageAlignment: const Alignment(0.0, -0.10),
                        imageScale: 1.04,
                        badgeSvg: _bhajanCardIconSvg,
                        svgWidth: 17,
                        svgHeight: 24.54,
                        progress: bhajanProgress,
                        showProgressBar: bhajanProgress > 0,
                        onTap: _openRecentBhajanFromHome,
                      ),
                      const SizedBox(width: 10),

                      // Card 4: Recent Granth (No default half status bar)
                      _buildNotchedDevotionalCard(
                        title: LocalizedApiHelper.parse(_granthCardTitle),
                        imageUrl: _granthCardImage,
                        fallbackAsset: 'assets/images/h4.jpg',
                        imageAlignment: const Alignment(0.0, -0.52),
                        imageScale: 1.08,
                        badgeSvg: _granthCardIconSvg,
                        svgWidth: 24,
                        svgHeight: 18,
                        progress: _granthCardProgress,
                        showProgressBar: _granthCardProgress > 0,
                        onTap: _openRecentGranthFromHome,
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 6. Festivals Horizontal Slider (display-only, non-clickable)
            SizedBox(
              height: 300,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  SizedBox(
                    width: 208,
                    child: _buildFestivalCard(
                      title: 'Dhanterash',
                      dateText: 'Nov 07\nSAT',
                      imageUrl: 'assets/images/new_year_card.png',
                      height: 300,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 208,
                    child: _buildFestivalCard(
                      title: 'Diwali',
                      dateText: 'Nov 08\nSUN',
                      imageUrl: 'assets/images/diwali_card.png',
                      height: 300,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 208,
                    child: _buildFestivalCard(
                      title: 'Gujarati New Year',
                      dateText: 'Nov 10\nTUE',
                      imageUrl: 'assets/images/dhanteras_card.png',
                      height: 300,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 208,
                    child: _buildFestivalCard(
                      title: 'Bhaibeej',
                      dateText: 'Nov 11\nWED',
                      imageUrl: 'assets/images/bhaiduj_card.png',
                      height: 300,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 140 + MediaQuery.of(context).padding.bottom), // Extra clearance for floating Jap button
          ],
        ),
      ),
    );
  }

  Future<void> _openRecentYatraFromHome() async {
    if (_continueYatraData != null) {
      final d = _continueYatraData!;
      final img = d.coverImage.isNotEmpty ? d.coverImage : 'assets/images/h1.jpg';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YatraLiveSanghaScreen(
            journeyId: d.journeyId,
            title: d.title.isNotEmpty ? d.title : 'Somnath Temple',
            distance: d.totalDistanceKm,
            steps: '${d.accumulatedSteps} Steps',
            duration: '${d.estimatedDays} Days',
            sangha: '1 Sangha',
            imageAsset: img,
            completedScreen: YatraCompletedScreen(
              journeyId: d.journeyId,
              title: d.title.isNotEmpty ? d.title : 'Somnath Temple',
              distance: d.totalDistanceKm,
              steps: '${d.accumulatedSteps} Steps',
              duration: '${d.estimatedDays} Days',
              imageAsset: img,
            ),
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const YatraScreen(isTab: false),
        ),
      );
    }
    _loadHomeFourCardsProgress();
  }

  Future<void> _openLastJapFromHome() async {
    final entry = _lastJapEntry ??
        JapConfig(
          id: JapThemeConfig.krishna.id,
          name: 'Shree Krishna',
          thumbnailUrl: 'assets/images/h2.jpg',
          darshanImageUrl: JapThemeConfig.krishna.imageAsset,
          shlokText: JapThemeConfig.krishna.mantraText,
          shlokAudioUrl: JapThemeConfig.krishna.audioAsset,
          targetCount: 108,
          progress: 0,
          effectPack: EffectPack.resolve(name: 'Shri Krishna'),
        );

    final bool isCinematic = entry.name.toLowerCase().contains('ram') ||
        entry.shlokText.toLowerCase().contains('राम') ||
        entry.name.toLowerCase().contains('radha') ||
        entry.shlokText.toLowerCase().contains('राधे') ||
        entry.shlokText.toLowerCase().contains('राधा') ||
        entry.name.toLowerCase().contains('krishna') ||
        entry.shlokText.toLowerCase().contains('कृष्ण') ||
        entry.name.toLowerCase().contains('shiv') ||
        entry.shlokText.toLowerCase().contains('शिव') ||
        entry.name.toLowerCase().contains('mahadev');

    if (entry.progress >= entry.targetCount) {
      entry.progress = 0;
    }

    final Widget destination;
    if (entry.isCustom && entry.particleShape == 'dhup') {
      destination = DhupJapScreen(entry: entry);
    } else if (isCinematic || (entry.isCustom && entry.particleShape == 'ram')) {
      destination = CinematicJapScreen(entry: entry);
    } else {
      destination = JapDetailScreen(entry: entry);
    }

    final updatedProgress = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );

    if (updatedProgress != null) {
      await JapOfflineRepository.saveProgress(
        japId: entry.id,
        count: updatedProgress % entry.targetCount,
        completedMalas: updatedProgress ~/ entry.targetCount,
        targetCount: entry.targetCount,
      );
    }
    _loadHomeFourCardsProgress();
  }

  Future<void> _openRecentGranthFromHome() async {
    final prefs = await SharedPreferences.getInstance();
    final granthJsonStr = prefs.getString('recent_granth_json') ?? '';
    final chapterJsonStr = prefs.getString('recent_granth_chapter_json') ?? '';
    final categoryJsonStr = prefs.getString('recent_granth_category_json') ?? '';

    if (!mounted) return;

    if (granthJsonStr.isNotEmpty && chapterJsonStr.isNotEmpty) {
      try {
        final granthMap = Map<String, dynamic>.from(jsonDecode(granthJsonStr) as Map);
        final chapterMap = Map<String, dynamic>.from(jsonDecode(chapterJsonStr) as Map);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GranthChapterReaderScreen(
              granth: granthMap,
              chapter: chapterMap,
            ),
          ),
        );
        _loadHomeFourCardsProgress();
        return;
      } catch (_) {}
    }

    if (granthJsonStr.isNotEmpty) {
      try {
        final granthMap = Map<String, dynamic>.from(jsonDecode(granthJsonStr) as Map);
        final categoryMap = categoryJsonStr.isNotEmpty
            ? Map<String, dynamic>.from(jsonDecode(categoryJsonStr) as Map)
            : <String, dynamic>{'title': 'Granth'};
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GranthChapterListScreen(
              category: categoryMap,
              granth: granthMap,
            ),
          ),
        );
        _loadHomeFourCardsProgress();
        return;
      } catch (_) {}
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GranthScreen()),
    );
    _loadHomeFourCardsProgress();
  }

  Future<void> _openRecentBhajanFromHome() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    await BhajanLibraryService.instance.init(token: token);

    final audio = BhajanAudioService.instance;
    final lib = BhajanLibraryService.instance;

    BhajanTrackItem? targetTrack = audio.currentTrack ??
        (lib.recentTracks.isNotEmpty
            ? lib.recentTracks.first
            : (lib.downloadedTracks.isNotEmpty ? lib.downloadedTracks.first : null));

    List<BhajanTrackItem> queue = audio.queue.isNotEmpty
        ? audio.queue
        : (lib.recentTracks.isNotEmpty ? lib.recentTracks : lib.downloadedTracks);

    if (targetTrack == null && token.isNotEmpty) {
      try {
        final homeData = await ApiService.getBhajanHome(token);
        final rawList = [
          if (homeData['popular'] is List) ...(homeData['popular'] as List),
          if (homeData['recommended'] is List) ...(homeData['recommended'] as List),
          if (homeData['latest'] is List) ...(homeData['latest'] as List),
        ];
        final parsed = rawList
            .whereType<Map<String, dynamic>>()
            .map(BhajanTrackItem.fromJson)
            .where((t) => t.id.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) {
          targetTrack = parsed.first;
          queue = parsed;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (targetTrack == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BhajanDashboardScreen()),
      );
      return;
    }

    if (queue.isEmpty) {
      queue = [targetTrack];
    }

    audio.playTrack(
      targetTrack,
      queue: queue,
      token: token,
      resumeFromSavedPosition: true,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BhajanNowPlayingScreen(
          currentTrack: targetTrack!,
          queue: queue,
        ),
      ),
    );
  }

  Widget _buildDarshanTabBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDynamicHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: DarshanTabContent(
              onTabChanged: (index) {
                setState(() {
                  _currentTab = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget tabBody;
    switch (_currentTab) {
      case 0:
        tabBody = _buildHomeTabBody();
        break;
      case 1:
        tabBody = _buildDarshanTabBody();
        break;
      case 2:
        tabBody = const JapCounterScreen(isTab: true);
        break;
      case 3:
        tabBody = const YatraScreen(isTab: true);
        break;
      case 4:
        tabBody = const ProfileScreen(isTab: true);
        break;
      default:
        tabBody = _buildHomeTabBody();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFE8D6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFE8D6), // Warm peach cream theme background matched to mockup
        body: Stack(
          children: [
            tabBody,
            // Solid opaque blocker background container for system navigation bar (3 buttons/gesture area)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).padding.bottom,
              child: Container(
                color: const Color(0xFFFFE8D6),
              ),
            ),
            // Floating Bhajan Mini-Player (persistently visible across Home, Darshan, Jap, Yatra, Profile)
            Positioned(
              left: 0,
              right: 0,
              bottom: 114 + MediaQuery.of(context).padding.bottom,
              child: const BhajanMiniPlayerWidget(bottomMargin: 0),
            ),
            // 7. Custom Floating Arched Bottom Navigation Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
              child: _buildBottomNavigationBar(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Header IconButton with red badge dot
  Widget _buildHeaderIconButton({required IconData icon, bool hasBadge = false, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFEFE6DB),
          width: 1.0,
        ),
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(icon, color: const Color(0xFF2E2A36), size: 20),
            onPressed: onTap,
          ),
          if (hasBadge)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                height: 7,
                width: 7,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Hero Section (Dynamic Live Darshan Carousel & Offline Fallback) ───────

  Widget _buildHeroSection() {
    if (_isLoadingLiveDarshans) {
      return _buildHeroLoadingCard();
    }
    if (_liveDarshanBanners.isEmpty) {
      return _buildNoLiveDarshanCard();
    }
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
        _startCarouselTimer();
      },
      itemCount: _liveDarshanBanners.length,
      itemBuilder: (context, index) {
        final banner = _liveDarshanBanners[index];
        return _buildHeroCard(banner);
      },
    );
  }

  Widget _buildHeroLoadingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: 353,
        height: 353,
        decoration: BoxDecoration(
          color: const Color(0xFF2E241E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFFFF7700),
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 14),
              Text(
                'Checking Live Streams...',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Displayed when no live streams are currently running
  Widget _buildNoLiveDarshanCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: 353,
        height: 353,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/somnath_hero.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Deep spiritual gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Status Badges (Offline & Next Aarti Soon)
                Positioned(
                  top: 15,
                  right: 15,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Offline badge
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A).withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: const Color(0x66FFFFFF),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFA000),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Offline',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Aarti Soon badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(47),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4.6, sigmaY: 4.6),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A).withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(47),
                              border: Border.all(
                                color: const Color(0x66FFFFFF),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, color: Color(0xFFFF9B38), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Aarti Soon',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Content
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7700).withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF9B38).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.temple_hindu_rounded,
                            color: Color(0xFFFF9B38),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No Live Darshan Right Now',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'All temple streams are currently off-air. Live Darshan & Aarti will resume during scheduled prayer timings.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7A00),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.explore_rounded, size: 16),
                              label: Text(
                                'Explore Temples',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                setState(() => _currentTab = 1);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 38,
                            width: 38,
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.15),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(19),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                              onPressed: () {
                                setState(() => _isLoadingLiveDarshans = true);
                                _fetchDashboardData();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resolveDefaultTempleAsset(String title, String desc) {
    final lower = '${title.toLowerCase()} ${desc.toLowerCase()}';
    if (lower.contains('amba') || lower.contains('ambaji')) {
      return 'assets/images/deity_amba.png';
    } else if (lower.contains('dwarka') || lower.contains('dwarkadhish')) {
      return 'assets/images/dwarka_temple.jpg';
    } else if (lower.contains('ram') || lower.contains('ayodhya')) {
      return 'assets/images/lord_shri_ram_darshan.png';
    } else if (lower.contains('krishna') || lower.contains('radha') || lower.contains('iskcon')) {
      return 'assets/images/deity_krishna.png';
    } else if (lower.contains('hanuman') || lower.contains('salangpur') || lower.contains('kashtbhanjan')) {
      return 'assets/images/deity_hanuman.png';
    } else if (lower.contains('ganesh') || lower.contains('ganpati') || lower.contains('siddhivinayak')) {
      return 'assets/images/deity_ganesha.png';
    } else if (lower.contains('shiva') || lower.contains('mahadev') || lower.contains('kashi') || lower.contains('kedarnath')) {
      return 'assets/images/deity_shiva.png';
    }
    return 'assets/images/somnath_hero.png';
  }

  Widget _buildHeroBannerImage(String imagePath, {String title = '', String desc = ''}) {
    final defaultAsset = _resolveDefaultTempleAsset(title, desc);

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            defaultAsset,
            fit: BoxFit.cover,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF1E1712),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7700), strokeWidth: 2),
            ),
          );
        },
      );
    } else if (imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            defaultAsset,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      return Image.asset(
        defaultAsset,
        fit: BoxFit.cover,
      );
    }
  }

  // Helper: Swipable Hero Card for PageView
  Widget _buildHeroCard(Map<String, dynamic> banner) {
    final String title = LocalizedApiHelper.parse(
      banner['title'] ?? 'Somnath Temple Darshan',
      defaultValue: 'Somnath Temple Darshan',
    );
    final String desc = LocalizedApiHelper.parse(
      banner['desc'] ?? 'The first among the twelve sacred Aadi Jyotirlinga shrines of Lord Shiva.',
      defaultValue: 'The first among the twelve sacred Aadi Jyotirlinga shrines of Lord Shiva.',
    );
    final String darshanId = (banner['id'] ?? banner['darshan_id'] ?? '').toString();
    final String views = banner['views']?.toString() ?? _formatViewerCount(banner['raw_views'], darshanId: darshanId);
    final String image = banner['image']?.toString() ?? '';
    final bool isLive = banner['isLive'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: 353,
        height: 353,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: _buildHeroBannerImage(
                    image,
                    title: title,
                    desc: desc,
                  ),
                ),
                // Gradient shader to darken bottom for text contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top-right Badges (Live/Offline Status & Active Viewers)
                Positioned(
                  top: 15,
                  right: 15,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. LIVE / OFFLINE Status Badge
                      if (isLive)
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B42),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.string(
                                _radioSignalSvg,
                                width: 20,
                                height: 13.33,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                LocalizedApiHelper.parse('Live'),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(47),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4.6, sigmaY: 4.6),
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A).withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(47),
                                border: Border.all(
                                  color: const Color(0x66FFFFFF),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFBDBDBD),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    LocalizedApiHelper.parse('Offline'),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),

                      // 2. Active Viewers Badge
                      ClipRRect(
                        borderRadius: BorderRadius.circular(47),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4.6, sigmaY: 4.6),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A).withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(47),
                              border: Border.all(
                                color: const Color(0x66FFFFFF),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.string(
                                  _eyeIconSvg,
                                  width: 22,
                                  height: 13.33,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  views,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Text & Button details (Bottom)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 16 / 14,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Start Darshan Button
                      SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => _openLiveDarshan(banner),
                          child: Text(
                            LocalizedApiHelper.parse('Start Darshan'),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Category Pill Card
  Widget _buildCategoryCard({
    String? imageAsset,
    IconData? icon,
    String? title,
    required double width,
    required double height,
    double scale = 1.15,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Figma: radius = 12px
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFEFE6DB),
            width: 1.0, // Figma: border = 1px
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageAsset != null
              ? Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) Icon(icon, color: const Color(0xFFFF7700), size: 24),
                    const SizedBox(height: 8),
                    if (title != null)
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF7700),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  // Helper: SVG Category Card — icon 42x42 at top:21 centered, label below (Figma spec)
  Widget _buildSvgCategoryCard({
    required String svgAsset,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 111,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFC8A882),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 21), // top: 21px as per Figma
            SvgPicture.asset(
              svgAsset,
              width: 42,
              height: 42,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF7A00),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: 178x208 Notched Devotional Card (Yatra, Jap, Bhajan, Granth)
  Widget _buildNotchedDevotionalCard({
    required String title,
    required String imageUrl,
    required String fallbackAsset,
    Alignment imageAlignment = Alignment.center,
    double imageScale = 1.0,
    required String badgeSvg,
    required double svgWidth,
    required double svgHeight,
    required double progress,
    required bool showProgressBar,
    required VoidCallback onTap,
  }) {
    final double clampedProgress = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 178,
        height: 208,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Clipped Image + Gradient Shade + Title + Progress Bar
            Positioned.fill(
              child: ClipPath(
                clipper: const _HomeNotchedCardClipper(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Dynamic / Static Fallback Image with proper framing
                    _buildCardDynamicImage(
                      imageUrl,
                      fallbackAsset,
                      alignment: imageAlignment,
                      scale: imageScale,
                    ),

                    // 2. Gradient Layer: linear-gradient(0deg, rgba(0, 0, 0, 0.8) 0%, rgba(0, 0, 0, 0.2) 66.83%, rgba(0, 0, 0, 0) 100%)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.6683, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.80),
                            Colors.black.withValues(alpha: 0.20),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),

                    // 3. Title & Optional Progress Bar
                    Positioned(
                      left: 11,
                      right: showProgressBar ? 12 : 52,
                      bottom: showProgressBar ? 25 : 11,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),

                    if (showProgressBar)
                      Positioned(
                        left: 11,
                        right: 52,
                        bottom: 11,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: clampedProgress.clamp(0.06, 1.0),
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A00),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 4. 1px solid #C8A882 Border around the notched card
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HomeNotchedCardBorderPainter(),
                ),
              ),
            ),

            // 5. Bottom-Right Orange Icon Button inside the Notch Cutout (39.99177932739258 x 39.99177932739258)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 39.99177932739258,
                height: 39.99177932739258,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: SvgPicture.string(
                  badgeSvg,
                  width: svgWidth,
                  height: svgHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDynamicImage(
    String path,
    String fallbackAsset, {
    Alignment alignment = Alignment.center,
    double scale = 1.0,
  }) {
    final clean = path.trim();
    Widget img;
    if (clean.isEmpty) {
      img = Image.asset(fallbackAsset, fit: BoxFit.cover, alignment: alignment);
    } else if (clean.startsWith('assets/')) {
      img = Image.asset(
        clean,
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: BoxFit.cover, alignment: alignment),
      );
    } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
      img = Image.network(
        clean,
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: BoxFit.cover, alignment: alignment),
      );
    } else if (clean.startsWith('/uploads/') || clean.startsWith('uploads/')) {
      img = Image.network(
        ApiService.resolveImageUrl(clean),
        fit: BoxFit.cover,
        alignment: alignment,
        errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: BoxFit.cover, alignment: alignment),
      );
    } else {
      Widget? fileImg;
      try {
        final f = File(clean);
        if (f.existsSync()) {
          fileImg = Image.file(
            f,
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: BoxFit.cover, alignment: alignment),
          );
        }
      } catch (_) {}
      img = fileImg ?? Image.asset(fallbackAsset, fit: BoxFit.cover, alignment: alignment);
    }

    if (scale != 1.0) {
      return Transform.scale(
        scale: scale,
        alignment: alignment,
        child: img,
      );
    }
    return img;
  }

  // Helper: Deity Card for Raw Downloaded Images
  Widget _buildDeityCard({
    required String imageUrl,
    required double height,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Transform.scale(
          scale: 1.45, // Increased size even further to fill the space
          child: Image.asset(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Helper: Devotional Temple Card (Two-Column)
  Widget _buildTempleCard({
    required String title,
    required String imageUrl,
    required String badgeEmoji,
    required double progress,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 165,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Dark gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              // Title
              Positioned(
                left: 14,
                bottom: progress > 0 ? 24 : 14,
                right: 44,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Progress Bar (only if progress > 0)
              if (progress > 0)
                Positioned(
                  left: 14,
                  right: 52,
                  bottom: 10,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white24,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: const Color(0xFFFF7700),
                        ),
                      ),
                    ),
                  ),
                ),
              // Bottom Right Saffron Button with Emoji
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7700),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      badgeEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Festival Card
  Widget _buildFestivalCard({
    required String title,
    required String dateText,
    required String imageUrl,
    VoidCallback? onTap,
    double height = 130,
  }) {
    final dateParts = dateText.split(RegExp(r'[\s\n]+'));
    final month = dateParts.isNotEmpty ? dateParts[0] : 'Nov';
    final date = dateParts.length > 1 ? dateParts[1] : '07';
    final day = dateParts.length > 2 ? dateParts[2] : 'SAT';

    final String titleLower = title.toLowerCase();
    final Color themeColor;
    if (titleLower.contains('dhanteras')) {
      themeColor = const Color(0xFFA22E85); // Berry Magenta
    } else if (titleLower.contains('diwali')) {
      themeColor = const Color(0xFF4C45A5); // Indigo Purple
    } else if (titleLower.contains('new') || titleLower.contains('year') || titleLower.contains('gujarati')) {
      themeColor = const Color(0xFF1E539E); // Dark Royal Blue
    } else if (titleLower.contains('bhai') || titleLower.contains('beej') || titleLower.contains('duj')) {
      themeColor = const Color(0xFF439CA3); // Teal Light Blue
    } else {
      themeColor = const Color(0xFFFF7700); // Saffron Orange fallback
    }

    final Color badgeHeaderColor = themeColor;

    final calendarBadge = Container(
      width: 21,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: [
            // Top Month Header
            Container(
              width: double.infinity,
              height: 12,
              color: themeColor,
              alignment: Alignment.center,
              child: Text(
                month, // e.g. "Nov"
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            // Bottom Date/Day Body
            Expanded(
              child: Container(
                width: double.infinity,
                color: themeColor.withValues(alpha: 0.12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date, // e.g. "07"
                      style: GoogleFonts.outfit(
                        color: themeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 0.5),
                    Text(
                      day.toUpperCase(), // e.g. "SAT"
                      style: GoogleFonts.outfit(
                        color: themeColor.withValues(alpha: 0.5),
                        fontSize: 5.5,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEFE6DB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              // Colored bottom overlay gradient matching design
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeColor.withValues(alpha: 0.0),
                        themeColor.withValues(alpha: 0.9), // Rich solid color fade at the bottom
                      ],
                    ),
                  ),
                ),
              ),
              // Date stamp & title Row – anchored to bottom of card
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    calendarBadge,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // Helper: Custom Floating Arched Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return SizedBox(
      width: 353,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none, // Allows Jap button to float above bar
        children: [
          // Arched background container with shadow and beige border
          Positioned.fill(
            child: CustomPaint(
              painter: ArchedNavBarPainter(),
            ),
          ),
          
          // Home
          Positioned(
            left: 8,
            top: 31,
            width: 60,
            height: 48,
            child: _buildNavItem(
              iconAsset: 'assets/images/nav_home.svg',
              label: _getNavLabel(0),
              isActive: _currentTab == 0,
              onTap: () => setState(() => _currentTab = 0),
            ),
          ),
          
          // Darshan
          Positioned(
            left: 76,
            top: 31,
            width: 60,
            height: 48,
            child: _buildNavItem(
              iconAsset: 'assets/images/nav_darshan.svg',
              label: _getNavLabel(1),
              isActive: _currentTab == 1,
              onTap: () => setState(() => _currentTab = 1),
            ),
          ),
          
          // Jap (Floating Orange Circle with Highlighted Radial Gradient)
          Positioned(
            left: 147,
            top: -2,
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = 2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFAB5E), // Inner highlighted light orange
                      Color(0xFFFF7A00), // Outer deep orange
                    ],
                    center: Alignment.center,
                    radius: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 13), // Logo top: 13px as per Figma
                    SvgPicture.asset(
                      'assets/images/nav_jap.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 1), // Tightly aligned spacer
                    Text(
                      _getNavLabel(2),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Yatra
          Positioned(
            left: 218,
            top: 31,
            width: 60,
            height: 48,
            child: _buildNavItem(
              iconAsset: 'assets/images/nav_yatra.svg',
              label: _getNavLabel(3),
              isActive: _currentTab == 3,
              onTap: () => setState(() => _currentTab = 3),
            ),
          ),
          
          // Profile
          Positioned(
            left: 285,
            top: 31,
            width: 60,
            height: 48,
            child: _buildNavItem(
              iconAsset: 'assets/images/nav_profile.svg',
              label: _getNavLabel(4),
              isActive: _currentTab == 4,
              onTap: () => setState(() => _currentTab = 4),
            ),
          ),
        ],
      ),
    );
  }

  // Nav Item helper
  Widget _buildNavItem({
    required String iconAsset,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFFFF7A00);
    final inactiveColor = const Color(0xFFB59E83);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconAsset.endsWith('.svg')
              ? SvgPicture.asset(
                  iconAsset,
                  colorFilter: ColorFilter.mode(
                      isActive ? activeColor : inactiveColor,
                      BlendMode.srcIn),
                  width: 20, // Reduced from 24 to 20 for more vertical breathing room
                  height: 20,
                )
              : Image.asset(
                  iconAsset,
                  color: isActive ? activeColor : inactiveColor,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
          const SizedBox(height: 2),
          Text(
            label,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: GoogleFonts.outfit(
              color: isActive ? activeColor : inactiveColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 10, // Reduced from 11 to 10 for better space matching
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchNotificationsFuture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      return await ApiService.getNotifications(token, limit: 4);
    } catch (_) {
      return {};
    }
  }

  void _showNotificationPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchNotificationsFuture(),
            builder: (context, snapshot) {
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              final rawList = snapshot.data?['notifications'] as List? ?? [];
              final notifs = rawList
                  .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
                  .take(4)
                  .toList();
              final unread = snapshot.data?['unread_count'] is int
                  ? snapshot.data!['unread_count'] as int
                  : notifs.where((n) => !n.isRead).length;

              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF6EF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2A36).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Notifications",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E2A36),
                                ),
                              ),
                              if (unread > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7700),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unread New',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              if (unread > 0)
                                TextButton(
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final token = prefs.getString('auth_token') ?? '';
                                    await ApiService.markNotificationAsRead(token, markAll: true);
                                    if (mounted) {
                                      setState(() {
                                        _notificationCount = 0;
                                      });
                                    }
                                    setSheetState(() {});
                                  },
                                  child: Text(
                                    "Mark read",
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF7700),
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF2E2A36)),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFEFE6DB), height: 16),

                      // Notification items list or loading/empty
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36.0),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFFFF7700), strokeWidth: 2.5),
                          ),
                        )
                      else if (notifs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              const Icon(Icons.notifications_none_rounded, size: 36, color: Color(0xFFFF7700)),
                              const SizedBox(height: 8),
                              Text(
                                "No new notifications right now 🙏",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E2A36),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notifs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final n = notifs[index];
                            return InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                                ).then((_) => _fetchDashboardData());
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: n.isRead ? Colors.white : const Color(0xFFFFF9EE),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: n.isRead
                                        ? const Color(0xFFEFE6DB)
                                        : const Color(0xFFFF7700).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: n.iconBgColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(n.icon, size: 18, color: n.iconColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  n.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                                    color: const Color(0xFF2E2A36),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                n.timeAgo,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  color: const Color(0xFF2E2A36).withValues(alpha: 0.45),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            n.message,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11.5,
                                              color: const Color(0xFF2E2A36).withValues(alpha: 0.7),
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!n.isRead) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF7700),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),

                      // View All Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7700),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationScreen()),
                            ).then((_) => _fetchDashboardData());
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "View All Notifications",
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMailNotificationSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFE8D6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E2A36),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFFEFE6DB), height: 20),
            const SizedBox(height: 8),
            Text(
              content, style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF2E2A36).withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7700),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Mark as Read",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArchedNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0x59B46414) // Figma border: #B46414 with 59 (35%) opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Host rect (the white bar from y=30.5 to y=79.5)
    final hostRect = Rect.fromLTWH(0.5, 30.5, size.width - 1.0, 49);
    
    // Guest rect (the Jap circle from x=147, y=-2 with size 60x60)
    // We add a gap of 5.5px on all sides to create the perfect circular gap
    final guestRect = Rect.fromLTWH(147 - 5.5, -2 - 5.5, 60 + 11, 60 + 11);

    // Get the notched path using Flutter's built-in Material design notched path generator
    final notchedPath = CircularNotchedRectangle().getOuterPath(hostRect, guestRect);

    // Create the rounded rectangle path for the outer corners (radius 12.0)
    const radius = 12.0;
    final rrect = RRect.fromRectAndRadius(hostRect, const Radius.circular(radius));
    final roundedPath = Path()..addRRect(rrect);

    // Intersect the two paths to get the rounded outer corners with the smooth circular notch
    final finalPath = Path.combine(PathOperation.intersect, notchedPath, roundedPath);

    // Draw shadow first
    canvas.drawPath(finalPath.shift(const Offset(0, 4)), shadowPaint);

    // Draw white background
    canvas.drawPath(finalPath, paint);

    // Draw border
    canvas.drawPath(finalPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeNotchedCardClipper extends CustomClipper<Path> {
  const _HomeNotchedCardClipper();

  static Path buildNotchedCardPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    const double r = 14.0;
    // Orange box is 39.99 x 39.99 with borderRadius 10 at bottom-right.
    // Notch is 42.5 x 42.5 so there is a tight ~2.5px gap between the orange box and the #C8A882 border.
    const double notchW = 42.5;
    const double notchH = 42.5;
    const double cr = 6.5;
    const double ir = 12.5;

    final Path path = Path();
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h - notchH - cr);
    path.quadraticBezierTo(w, h - notchH, w - cr, h - notchH);
    path.lineTo(w - notchW + ir, h - notchH);
    // Curve concentrically around the top-left corner of the 39.99x39.99 orange box
    path.arcToPoint(
      Offset(w - notchW, h - notchH + ir),
      radius: const Radius.circular(ir),
      clockwise: false,
    );
    path.lineTo(w - notchW, h - cr);
    path.quadraticBezierTo(w - notchW, h, w - notchW - cr, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();
    return path;
  }

  @override
  Path getClip(Size size) => buildNotchedCardPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HomeNotchedCardBorderPainter extends CustomPainter {
  const _HomeNotchedCardBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _HomeNotchedCardClipper.buildNotchedCardPath(size);
    final borderPaint = Paint()
      ..color = const Color(0xFFC8A882)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
