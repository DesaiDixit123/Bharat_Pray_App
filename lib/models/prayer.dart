class Prayer {
  final String id;
  final String title;
  final String category;
  final String lyrics;
  final String translation;
  final String duration;
  final String audioUrl;
  final String imageUrl;

  const Prayer({
    required this.id,
    required this.title,
    required this.category,
    required this.lyrics,
    required this.translation,
    required this.duration,
    required this.audioUrl,
    required this.imageUrl,
  });

  static List<Prayer> get defaultPrayers => const [
        Prayer(
          id: '1',
          title: 'Gayatri Mantra',
          category: 'Mantra',
          lyrics: '''ॐ भूर्भुवः स्वः ।
तत्सवितुर्वरेण्यं ।
भर्गो देवस्य धीमहि ।
धियो यो नः प्रचोदयात् ॥''',
          translation: 'We meditate on the glory of that Creator; Who has created the Universe; Who is worthy of Worship; Who is the embodiment of Knowledge and Light; Who is the Remover of all Sin and Ignorance; May He enlighten our Intellect.',
          duration: '1:08',
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          imageUrl: 'https://images.unsplash.com/photo-1545128485-c400e7702796?w=500&auto=format&fit=crop&q=60',
        ),
        Prayer(
          id: '2',
          title: 'Hanuman Chalisa',
          category: 'Chalisa',
          lyrics: '''श्रीगुरु चरन सरोज रज, निज मनु मुकुरु सुधारि।
बरनउँ रघुबर बिमल जसु, जो दायകു फल चारि॥
बुद्धिहीन तनु जानिके, सुमिरौं पवन-कुमार।
बल बुधि बिद्या देहु मोहि, हरहु कलेस बिकार॥

जय हनुमान ज्ञान गुन सागर।
जय कपीस तिहुँ लोक उजागर॥
रामदूत अतुलित बल धामा।
अंजनि-पुत्र पवनसुत नामा॥
महाबीर बिक्रम बजरंगी।
कुमति निवार सुमति के संगी॥''',
          translation: 'Having cleansed the mirror of my mind with the dust of the lotus feet of Sri Guru, I sing the pure glory of Sri Ram, which bestows the four fruits of life (Dharma, Artha, Kama, Moksha). Knowing myself to be ignorant, I remember Hanuman, the son of Wind. Grant me strength, wisdom, and knowledge, and remove my miseries and flaws.',
          duration: '3:45',
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          imageUrl: 'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=500&auto=format&fit=crop&q=60',
        ),
        Prayer(
          id: '3',
          title: 'Maha Mrityunjaya Mantra',
          category: 'Mantra',
          lyrics: '''ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् ।
उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय माऽमृतात् ॥''',
          translation: 'We worship the three-eyed Lord (Shiva) who is fragrant and nourishes all beings. May He liberate us from death, for the sake of immortality, even as the cucumber is severed from its bondage to the vine.',
          duration: '1:15',
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          imageUrl: 'https://images.unsplash.com/photo-1561361058-c24cecae35ca?w=500&auto=format&fit=crop&q=60',
        ),
        Prayer(
          id: '4',
          title: 'Ganesh Aarti',
          category: 'Aarti',
          lyrics: '''जय गणेश, जय गणेश, जय गणेश देवा।
माता जाकी पारवती, पिता महादेवा॥
एकदंत, दयावन्त, चार भुजाधारी।
माथे पर तिलक सोहे, मूसे की सवारी॥

पान चढे, फूल चढे और चढे मेवा।
लड्डुअन का भोग लगे, सन्त करें सेवा॥
जय गणेश, जय गणेश, जय गणेश देवा।
माता जाकी पारवती, पिता महादेवा॥''',
          translation: 'Glory to Lord Ganesha! Whose mother is Goddess Parvati and father is Lord Shiva. He has a single tusk, is compassionate, has four arms, wears a sacred mark on His forehead, and rides a mouse. We offer flowers, betel leaves, dry fruits, and laddoos, while saints serve Him.',
          duration: '2:50',
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
          imageUrl: 'https://images.unsplash.com/photo-1568252542512-9fe8fe9c87bb?w=500&auto=format&fit=crop&q=60',
        ),
        Prayer(
          id: '5',
          title: 'Mere Ghar Ram Aay...',
          category: 'Bhajan',
          lyrics: '''मेरी झोपड़ी के भाग आज खुल जाएंगे, राम आएंगे।
राम आएंगे आएंगे राम आएंगे।
राम आएंगे तो अंगना सजाऊंगी,
दीप जलाके दिवाली मनाऊंगी॥

मेरे जन्मों के सारे पाप मिट जाएंगे, राम आएंगे।
मेरी झोपड़ी के भाग आज खुल जाएंगे, राम आएंगे॥''',
          translation: 'The fortune of my humble cottage will open today, for Lord Rama will arrive. When Rama arrives, I will decorate my courtyard, and light lamps to celebrate Diwali. All the sins of my births will be washed away when Rama arrives.',
          duration: '4:20',
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
          imageUrl: 'assets/images/ram_bhajan.png',
        ),
      ];
}
