import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GranthScreen extends StatefulWidget {
  const GranthScreen({super.key});

  @override
  State<GranthScreen> createState() => _GranthScreenState();
}

class _GranthScreenState extends State<GranthScreen> {
  bool _showingChapterDetail = false;
  final String _selectedGranth = "Bhagavad Gita";
  Map<String, dynamic>? _selectedChapter;

  final List<Map<String, dynamic>> _gitaChapters = [
    {
      'number': '1',
      'title': 'Arjuna Vishada Yoga',
      'translation': 'The Yoga of Arjuna\'s Grief',
      'versesCount': '46 Verses',
      'verses': [
        {
          'sanskrit': 'धर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः ।\nमामकाः पाण्डवाश्चैव किमकुर्वत सञ्जय ॥ १.१ ॥',
          'english': 'Dhritarashtra said: O Sanjay, assembled in the holy land of Kurukshetra and desiring to fight, what did my sons and the sons of Pandu do?',
        },
        {
          'sanskrit': 'दृष्ट्वा तु पाण्डवानीकं व्यूढं दुर्योधनस्तदा ।\nआचार्यमुपसङ्गम्य राजा वचनमब्रवीत् ॥ १.२ ॥',
          'english': 'Sanjaya said: King Duryodhana, having seen the army of the Pandavas drawn up in battle array, approached his teacher Drona and spoke these words.',
        }
      ]
    },
    {
      'number': '2',
      'title': 'Sankhya Yoga',
      'translation': 'The Yoga of Knowledge',
      'versesCount': '72 Verses',
      'verses': [
        {
          'sanskrit': 'क्लैब्यं मा स्म गमः पार्थ नैतत्त्वय्युपपद्यते ।\nक्षुद्रं हृदयदौर्बल्यं त्यक्त्वोत्तिष्ठ परन्तप ॥ २.३ ॥',
          'english': 'O Parth, yield not to unmanliness; it does not become you. Cast off this petty weakness of heart and arise, O scorcher of enemies!',
        },
        {
          'sanskrit': 'कर्मण्येवाधिकारस्ते मा फलेषु कदाचन ।\nमा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि ॥ २.४७ ॥',
          'english': 'You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions. Never consider yourself to be the cause of the results of your activities, and never be attached to not doing your duty.',
        }
      ]
    },
    {
      'number': '3',
      'title': 'Karma Yoga',
      'translation': 'The Yoga of Action',
      'versesCount': '43 Verses',
      'verses': [
        {
          'sanskrit': 'न कर्मणामनारम्भान्नैष्कर्म्यं पुरुषोऽश्नुते ।\nन च सन्न्यसनादेव सिद्धिं समधिगच्छति ॥ ३.४ ॥',
          'english': 'Not by abstaining from work can one achieve freedom from karmic reactions, nor by renunciation alone can one attain perfection.',
        }
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE8D6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E2A36)),
          onPressed: () {
            if (_showingChapterDetail) {
              setState(() {
                _showingChapterDetail = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _showingChapterDetail ? _selectedChapter!['title'] : 'Holy Granths',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2E2A36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _showingChapterDetail ? _buildChapterReader() : _buildGranthDashboard(),
      ),
    );
  }

  // Dashboard showing Granth selection and Chapter List
  Widget _buildGranthDashboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Granth Header Banner Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9933), Color(0xFFFF5500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7700).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 20,
                    bottom: -20,
                    child: Opacity(
                      opacity: 0.15,
                      child: Text(
                        "📖",
                        style: GoogleFonts.outfit(fontSize: 130),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedGranth,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"The eternal spiritual wisdom of ancient Bharat."',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Text(
              "Chapters (अध्याय)",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E2A36),
              ),
            ),
          ),

          // Chapter list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _gitaChapters.length,
            itemBuilder: (context, index) {
              final chapter = _gitaChapters[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEFE6DB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7700).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        chapter['number'],
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF7700),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    chapter['title'],
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E2A36),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    chapter['translation'],
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2E2A36).withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chapter['versesCount'],
                        style: GoogleFonts.outfit(color: const Color(0xFFFF7700), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedChapter = chapter;
                      _showingChapterDetail = true;
                    });
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Chapter Reader layout showing verses
  double _readerFontSize = 18.0;

  Widget _buildChapterReader() {
    final verses = _selectedChapter!['verses'] as List<Map<String, String>>;
    return Column(
      children: [
        // Sub-title bar with font resizing controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: const Color(0xFFFFEAD2).withValues(alpha: 0.4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chapter ${_selectedChapter!['number']}: ${_selectedChapter!['translation']}",
                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF2E2A36).withValues(alpha: 0.7), fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                    onPressed: () {
                      setState(() {
                        if (_readerFontSize > 14) _readerFontSize -= 2;
                      });
                    },
                  ),
                  Text(
                    "Aa",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    onPressed: () {
                      setState(() {
                        if (_readerFontSize < 28) _readerFontSize += 2;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Verses list
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEFE6DB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Sanskrit Sloka
                    SelectableText(
                      verse['sanskrit']!,
                      style: GoogleFonts.yatraOne(
                        fontSize: _readerFontSize,
                        color: const Color(0xFF2E2A36),
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Color(0xFFEFE6DB), height: 30),
                    // English translation
                    SelectableText(
                      verse['english']!,
                      style: GoogleFonts.outfit(
                        fontSize: _readerFontSize - 3,
                        color: const Color(0xFF2E2A36).withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
