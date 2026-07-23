import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_yatra_group_screen.dart';


class YatraItem {
  final String title;
  final String distance;
  final String steps;
  final String duration;
  final String groupSize;
  final String image;
  final String tag;
  final double progress;

  const YatraItem({
    required this.title,
    required this.distance,
    required this.steps,
    required this.duration,
    required this.groupSize,
    required this.image,
    required this.tag,
    required this.progress,
  });
}

class YatraScreen extends StatefulWidget {
  final bool isTab;
  const YatraScreen({super.key, this.isTab = false});

  @override
  State<YatraScreen> createState() => _YatraScreenState();
}

class _YatraScreenState extends State<YatraScreen> {
  String _profileName = 'Shiv';

  static const String _pinSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_279_1650)">
<path d="M12 0C7.038 0 3 4.066 3 9.065C3 16.168 11.154 23.502 11.501 23.81C11.6382 23.9328 11.8157 24.0007 11.9998 24.0009C12.1839 24.0011 12.3616 23.9335 12.499 23.811C12.846 23.502 21 16.168 21 9.065C21 4.066 16.962 0 12 0ZM12 14C9.243 14 7 11.757 7 9C7 6.243 9.243 4 12 4C14.757 4 17 6.243 17 9C17 11.757 14.757 14 12 14Z" fill="#C8A882"/>
</g>
<defs>
<clipPath id="clip0_279_1650">
<rect width="24" height="24" rx="12" fill="white"/>
</clipPath>
</defs>
</svg>''';

  static const String _footprintsSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M10.1404 14.665C9.85304 14.2307 9.4854 13.8487 9.17566 13.4276C8.95927 13.1308 8.72396 12.8265 8.59816 12.4872C8.19634 11.3989 8.38865 10.3864 9.14802 9.5233C9.5167 9.10508 9.94994 8.74615 10.357 8.36417C10.9296 7.82865 11.3036 7.2023 11.335 6.37733C11.3674 5.49927 10.9363 4.7821 10.1497 4.56674C9.74926 4.45746 8.91271 4.39737 8.91065 4.41526C7.70783 4.47466 6.55158 4.72557 5.49337 5.33414C4.52804 5.88893 3.83598 6.67697 3.64367 7.82807C3.4813 8.79615 3.57143 9.76147 3.91247 10.6738C4.21727 11.4905 4.60235 12.2743 4.963 13.0696C5.38683 14.0031 5.66652 14.9724 5.68923 16.0086C5.69519 16.276 5.70494 16.5463 5.75597 16.8067C5.92316 17.6824 6.33129 18.3876 7.15591 18.7716C7.65279 19.0028 8.17674 18.956 8.69598 18.8813C9.67071 18.7409 10.31 18.1627 10.5052 17.2474C10.7005 16.3415 10.6623 15.4569 10.1404 14.665ZM11.5348 3.08321C11.8965 2.63839 12.0383 2.11467 12.056 1.48419C12.0445 1.392 12.0359 1.23707 12.0065 1.08444C11.982 0.956825 11.9461 0.831671 11.8992 0.710488C11.607 -0.0680339 10.879 -0.232476 10.2938 0.345251C9.7105 0.922061 9.52048 2.1821 9.90728 2.91831C10.2871 3.64144 11.0178 3.71724 11.5348 3.08321ZM8.75332 3.02667C9.19882 2.58323 9.3018 1.69714 8.96936 1.15875C8.67396 0.679755 8.15759 0.652577 7.80886 1.10393C7.58192 1.39681 7.48904 1.74003 7.49179 2.11112C7.48835 2.43094 7.56346 2.70398 7.71208 2.92358C7.98317 3.32345 8.41365 3.3653 8.75332 3.02667ZM6.79985 3.31955C6.98699 3.08802 7.04353 2.81189 7.0558 2.52245C7.04215 2.2243 6.98355 1.94186 6.78769 1.7093C6.54814 1.42617 6.20985 1.42823 5.97041 1.7093C5.62581 2.11467 5.62019 2.90856 5.95963 3.32127C6.20572 3.62229 6.55685 3.62229 6.79985 3.31955ZM5.51194 3.85301C5.71515 3.48858 5.59508 2.8706 5.26964 2.6119C5.02458 2.41672 4.73549 2.47016 4.59891 2.75398C4.53744 2.88494 4.5176 3.03504 4.47816 3.17678C4.51027 3.50223 4.60097 3.78604 4.85062 3.99028C5.08811 4.18511 5.36183 4.12261 5.51194 3.85301ZM4.43733 4.81845C4.52953 4.67465 4.5668 4.4937 4.63182 4.3171C4.5676 4.14853 4.53125 3.98122 4.44605 3.84613C4.305 3.62229 4.04836 3.62378 3.87761 3.82836C3.66741 4.07835 3.65239 4.55459 3.84756 4.81983C4.01843 5.0509 4.28298 5.06145 4.43733 4.81845ZM15.3691 9.6679C15.3712 9.64967 14.5493 9.48396 14.1331 9.48396C13.3169 9.48178 12.7121 10.0589 12.5097 10.9133C12.3176 11.717 12.5146 12.4202 12.923 13.0891C13.2128 13.566 13.5354 14.0277 13.7791 14.5303C14.2812 15.5624 14.1995 16.5895 13.5215 17.5316C13.3099 17.8253 13.0006 18.0558 12.7143 18.2857C12.3044 18.611 11.8495 18.8792 11.4553 19.2227C10.741 19.8462 10.47 20.6891 10.4165 21.6157C10.3614 22.5506 10.8226 23.276 11.7251 23.672C12.2065 23.883 12.6981 24.0666 13.2386 23.9765C14.1358 23.8257 14.7181 23.2517 15.1113 22.4557C15.2285 22.2175 15.3116 21.9592 15.3878 21.7022C15.6852 20.7079 16.2124 19.8483 16.8703 19.0621C17.4282 18.3917 18.0091 17.7382 18.5216 17.0338C19.0927 16.244 19.435 15.3383 19.5375 14.3622C19.659 13.2009 19.1995 12.2575 18.4196 11.4653C17.5581 10.5938 16.5122 10.0453 15.3691 9.6679ZM14.809 7.96098C15.3767 7.35447 15.5289 6.08893 15.1198 5.37703C14.7113 4.66479 13.9669 4.62947 13.476 5.30226C13.4006 5.40707 13.3294 5.51842 13.2722 5.63505C13.2044 5.77288 13.1542 5.91955 13.1185 6.00682C12.9684 6.61883 12.9656 7.16205 13.196 7.68679C13.5242 8.43573 14.2483 8.55728 14.809 7.96098ZM16.9227 8.54926C17.1252 8.37713 17.2691 8.13379 17.3507 7.8244C17.4534 7.46685 17.4555 7.11147 17.313 6.76757C17.0972 6.24075 16.5924 6.12975 16.1797 6.51311C15.7175 6.94428 15.5792 7.82521 15.8906 8.37048C16.1266 8.78801 16.554 8.86106 16.9227 8.54926ZM18.5057 9.39968C18.9428 9.09212 19.1486 8.32656 18.9239 7.84367C18.7675 7.50813 18.4427 7.41662 18.1369 7.62544C17.8841 7.79722 17.7542 8.05386 17.6614 8.33768C17.5971 8.62081 17.5783 8.90119 17.6964 9.17411C17.8507 9.53029 18.1865 9.62421 18.5057 9.39968ZM18.7947 10.0323C18.8681 10.3312 19.1159 10.4642 19.3967 10.3406C19.6913 10.2096 19.8547 9.96078 19.9713 9.65563C19.9713 9.50827 19.993 9.35817 19.9672 9.21574C19.912 8.90475 19.6481 8.77769 19.3589 8.9005C18.9763 9.06288 18.6949 9.62639 18.7947 10.0323ZM20.377 10.4415C20.2667 10.1996 20.0196 10.1281 19.8247 10.3067C19.7067 10.415 19.6278 10.5658 19.5203 10.7118C19.5358 10.8996 19.5245 11.0832 19.5742 11.2467C19.6586 11.5217 19.9163 11.5818 20.1425 11.4045C20.4008 11.2005 20.5119 10.7379 20.377 10.4415Z" fill="#C8A882"/>
</svg>''';

  static const String _clockSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 1C9.82441 1 7.69767 1.64514 5.88873 2.85383C4.07979 4.06253 2.66989 5.78049 1.83733 7.79048C1.00477 9.80047 0.786929 12.0122 1.21137 14.146C1.6358 16.2798 2.68345 18.2398 4.22183 19.7782C5.76021 21.3166 7.72022 22.3642 9.85401 22.7886C11.9878 23.2131 14.1995 22.9952 16.2095 22.1627C18.2195 21.3301 19.9375 19.9202 21.1462 18.1113C22.3549 16.3023 23 14.1756 23 12C22.9966 9.08367 21.8365 6.28778 19.7744 4.22563C17.7122 2.16347 14.9163 1.00344 12 1ZM15.707 15.707C15.5195 15.8945 15.2652 15.9998 15 15.9998C14.7348 15.9998 14.4805 15.8945 14.293 15.707L11.293 12.707C11.1055 12.5195 11.0001 12.2652 11 12V6C11 5.73478 11.1054 5.48043 11.2929 5.29289C11.4804 5.10536 11.7348 5 12 5C12.2652 5 12.5196 5.10536 12.7071 5.29289C12.8946 5.48043 13 5.73478 13 6V11.586L15.707 14.293C15.8945 14.4805 15.9998 14.7348 15.9998 15C15.9998 15.2652 15.8945 15.5195 15.707 15.707Z" fill="#C8A882"/>
</svg>''';

  static const String _peopleSvg = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M4 9C5.65685 9 7 7.65685 7 6C7 4.34315 5.65685 3 4 3C2.34315 3 1 4.34315 1 6C1 7.65685 2.34315 9 4 9Z" fill="#C8A882"/>
<path d="M7.29 11.07C6.2835 11.6981 5.45339 12.5719 4.87782 13.6094C4.30226 14.6468 4.00017 15.8136 4 17H2C1.47005 16.9984 0.962265 16.7872 0.587535 16.4125C0.212805 16.0377 0.00158273 15.5299 0 15L0 13C0.00237409 12.2051 0.319207 11.4434 0.881302 10.8813C1.4434 10.3192 2.20508 10.0024 3 10H5C5.43657 10.001 5.86767 10.0972 6.26319 10.2821C6.65872 10.4669 7.00914 10.7358 7.29 11.07Z" fill="#C8A882"/>
<path d="M20 9C21.6569 9 23 7.65685 23 6C23 4.34315 21.6569 3 20 3C18.3431 3 17 4.34315 17 6C17 7.65685 18.3431 9 20 9Z" fill="#C8A882"/>
<path d="M24 13V15C23.9984 15.5299 23.7872 16.0377 23.4124 16.4125C23.0377 16.7872 22.5299 16.9984 22 17H20C19.9998 15.8136 19.6977 14.6468 19.1221 13.6094C18.5466 12.5719 17.7165 11.6981 16.71 11.07C16.9908 10.7358 17.3412 10.4669 17.7368 10.2821C18.1323 10.0972 18.5634 10.001 19 10H21C21.7949 10.0024 22.5566 10.3192 23.1187 10.8813C23.6808 11.4434 23.9976 12.2051 24 13Z" fill="#C8A882"/>
<path d="M12 11C14.2091 11 16 9.20914 16 7C16 4.79086 14.2091 3 12 3C9.79086 3 8 4.79086 8 7C8 9.20914 9.79086 11 12 11Z" fill="#C8A882"/>
<path d="M18 17V18C17.9976 18.7949 17.6808 19.5566 17.1187 20.1187C16.5566 20.6808 15.7949 20.9976 15 21H9C8.20508 20.9976 7.4434 20.6808 6.8813 20.1187C6.31921 19.5566 6.00237 18.7949 6 18V17C6 15.6739 6.52678 14.4021 7.46447 13.4645C8.40215 12.5268 9.67392 12 11 12H13C14.3261 12 15.5979 12.5268 16.5355 13.4645C17.4732 14.4021 18 15.6739 18 17Z" fill="#C8A882"/>
</svg>''';

  final List<YatraItem> _popularYatras = const [
    YatraItem(
      title: "Somnath Temple",
      distance: "450 KM",
      steps: "108k Steps",
      duration: "5 Days",
      groupSize: "12.5 k",
      image: "assets/images/somnath_temple_new.png",
      tag: "Popular Yatra",
      progress: 0.0,
    ),
    YatraItem(
      title: "Dwarkadhish Temple",
      distance: "220 KM",
      steps: "80k Steps",
      duration: "4 Days",
      groupSize: "8.2 k",
      image: "assets/images/dwarka_temple.jpg",
      tag: "Popular Yatra",
      progress: 0.0,
    ),
  ];

  final List<YatraItem> _continueYatras = const [
    YatraItem(
      title: "Somnath Temple",
      distance: "112 KM",
      steps: "54k Steps",
      duration: "2.5 Days",
      groupSize: "2.5 k",
      image: "assets/images/somnath_temple_new.png",
      tag: "Popular Yatra",
      progress: 0.35,
    ),
    YatraItem(
      title: "Dwarkadhish Temple",
      distance: "140 KM",
      steps: "45k Steps",
      duration: "2.0 Days",
      groupSize: "3.1 k",
      image: "assets/images/dwarka_temple.jpg",
      tag: "Popular Yatra",
      progress: 0.65,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    String fullName = prefs.getString('user_name') ?? 'Shivangi Patel (Shiv)';
    String firstName = fullName.split(' ')[0];
    if (mounted) {
      setState(() {
        _profileName = firstName;
      });
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF7A00).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&auto=format&fit=crop&q=60',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Jai Shree Ram',
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
                  'Good Morning, $_profileName ☀️',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF2E2A36).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Mail Action Icon
          GestureDetector(
            onTap: () {},
            child: SvgPicture.string(
              '''<svg width="26" height="24" viewBox="0 0 26 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6.01417 3.9978C3.80516 3.9978 2.01416 5.7888 2.01416 7.9978V15.9978C2.01416 18.2068 3.80516 19.9978 6.01417 19.9978H18.0142C20.2232 19.9978 22.0142 18.2068 22.0142 15.9978V7.9978C22.0142 5.7888 20.2232 3.9978 18.0142 3.9978H6.01417ZM6.01417 5.9978H18.0142C19.0222 5.9978 19.8552 6.73781 19.9932 7.70781C19.0352 8.60081 17.6112 9.6968 16.6702 10.3728C14.5052 11.9278 12.6002 12.9978 12.0142 12.9978C11.4282 12.9978 9.52317 11.9288 7.35816 10.3728C6.41716 9.6968 5.49217 8.9658 4.79517 8.3728C4.49817 8.1198 4.27816 7.9158 4.10816 7.7478C4.24616 6.7778 5.00616 5.9978 6.01417 5.9978ZM4.02417 10.3518C6.56218 12.4048 10.2812 14.9858 12.0142 14.9978C13.1432 15.0058 15.0742 13.9278 17.0442 12.5668C18.0632 11.8618 19.1972 11.0248 20.0152 10.3378L20.0142 15.9978C20.0142 17.1028 19.1192 17.9978 18.0142 17.9978H6.01417C4.90916 17.9978 4.01416 17.1028 4.01416 15.9978L4.02417 10.3518Z" fill="#6B4226"/>
<circle cx="22" cy="4.5" r="4" fill="#FF0000"/>
</svg>''',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 8),
          
          // Bell Action Icon
          GestureDetector(
            onTap: () {},
            child: SvgPicture.string(
              '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 6.43994V9.76994" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round"/>
<path d="M12.02 2C8.34002 2 5.36002 4.98 5.36002 8.66V10.76C5.36002 11.44 5.08002 12.46 4.73002 13.04L3.46002 15.16C2.68002 16.47 3.22002 17.93 4.66002 18.41C9.44002 20 14.61 20 19.39 18.41C20.74 17.96 21.32 16.38 20.59 15.16L19.32 13.04C18.97 12.46 18.69 11.43 18.69 10.76V8.66C18.68 5 15.68 2 12.02 2Z" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round"/>
<path d="M15.33 18.8199C15.33 20.6499 13.83 22.1499 12 22.1499C11.09 22.1499 10.25 21.7699 9.65004 21.1699C9.05004 20.5699 8.67004 19.7299 8.67004 18.8199" stroke="#6B4226" stroke-width="1.5" stroke-miterlimit="10"/>
<circle cx="18" cy="4.5" r="4" fill="#FF0000"/>
</svg>''',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndBackRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
              ),
              child: Center(
                child: SvgPicture.string(
                  '''<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.87301 8.24994L8.56917 13.9461L7.49996 14.9999L0 7.49996L7.49996 0L8.56917 1.05382L2.87301 6.74998H14.9999V8.24994H2.87301Z" fill="#C8A882"/>
</svg>''',
                  width: 15,
                  height: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Search bar
          Expanded(
            child: Container(
              height: 43,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(89),
                border: Border.all(color: const Color(0xFFC8A882), width: 1.0),
              ),
              child: TextField(
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF2E2A36),
                ),
                decoration: InputDecoration(
                  hintText: 'Search your yatra destination',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFFC8A882).withOpacity(0.6),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.string(
                      '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M11 19C15.4183 19 19 15.4183 19 11C19 6.58172 15.4183 3 11 3C6.58172 3 3 6.58172 3 11C3 15.4183 6.58172 19 11 19Z" stroke="#C8A882" stroke-width="1.33333"/>
<path d="M21 20.9999L16.65 16.6499" stroke="#C8A882" stroke-width="1.33333"/>
</svg>''',
                      width: 18,
                      height: 18,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateGroupButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateYatraGroupScreen(),
            ),
          );
        },
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7A00).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                'Create Yatra Group',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularYatraSection() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Yatra',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF994700),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF7A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // gap: 16px
          
          // Horizontal scrolling area
          SizedBox(
            height: 305, // Scroll area matches card widget height (305)
            width: double.infinity,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 10, right: 20), // left: 10px, right: 20px
              itemCount: _popularYatras.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _popularYatras.length - 1 ? 0 : 16, // gap: 16px between cards
                  ),
                  child: _buildYatraCard(_popularYatras[index], isPopular: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueYatraSection() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continue Yatra',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF994700),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF7A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // gap: 16px
          
          // Horizontal scrolling area
          SizedBox(
            height: 305, // Scroll area matches card widget height (305)
            width: double.infinity,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 10, right: 20), // left: 10px, right: 20px
              itemCount: _continueYatras.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _continueYatras.length - 1 ? 0 : 16, // gap: 16px between cards
                  ),
                  child: _buildYatraCard(_continueYatras[index], isPopular: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYatraCard(YatraItem item, {required bool isPopular}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. The Card Container (333 x 265)
        Container(
          width: 333,
          height: 265,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            border: Border.all(color: const Color(0xFFEFE6DB), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Section (333 x 200)
                Stack(
                  children: [
                    SizedBox(
                      width: 333,
                      height: 200,
                      child: Image.asset(
                        item.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Dark bottom gradient overlay (Figma Match)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xFF000000),
                              Color(0x00000000),
                              Color(0x00000000),
                            ],
                            stops: [0.0, 0.6337, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // "Popular Yatra" Tag
                    Positioned(
                      top: 20,
                      left: 237,
                      width: 76,
                      height: 20,
                      child: Container(
                        padding: const EdgeInsets.only(top: 4, right: 10, bottom: 4, left: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00).withOpacity(0.08), // var(--color-orange-50) translucent background
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: const Color(0xFFFF7A00), width: 1.0),
                        ),
                        alignment: Alignment.center,
                        child: Center(
                          child: Text(
                            item.tag,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFF7A00),
                              fontSize: 8,
                              fontWeight: FontWeight.w600, // SemiBold
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Title on bottom left
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Text(
                        item.title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Bottom Details Section (65px remaining height)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(_pinSvg, item.distance),
                        _buildStatColumn(_footprintsSvg, item.steps),
                        _buildStatColumn(_clockSvg, item.duration),
                        _buildStatColumn(_peopleSvg, item.groupSize),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12), // Spacing: 12px
        
        // 2. Below-card progress & action button row (height 28)
        SizedBox(
          width: 333,
          height: 28,
          child: Row(
            children: [
              // Progress Bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 6,
                    color: const Color(0xFFEFE6DB),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: item.progress,
                      child: Container(
                        color: const Color(0xFFFF7A00),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Button
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A00),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A00).withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    isPopular ? 'Start Yatra' : 'Continue Yatra',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String svgString, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.string(
          svgString,
          width: 24,
          height: 24,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: const Color(0xFFC8A882),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (User profile row)
              _buildHeader(),
              
              const SizedBox(height: 8),

              // 2. Search & Back Button Row
              _buildSearchAndBackRow(),

              const SizedBox(height: 14),

              // 3. "+ Create Yatra Group" button
              _buildCreateGroupButton(),

              const SizedBox(height: 14),

              // 4. Popular Yatra Section
              _buildPopularYatraSection(),

              const SizedBox(height: 14), // Spacing: 14px (sums to 319px total height from top of cards)

              // 5. Continue Yatra Section
              _buildContinueYatraSection(),
              
              // Spacing at bottom
              SizedBox(height: widget.isTab ? 140.0 : 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
