/// Gospel verses for the student dashboard.
///
/// Every entry is taken from one of the four Gospels (Matthew, Mark, Luke or
/// John) and carries both the Amharic and English text so the card can show a
/// bilingual reading regardless of the active locale.
library;

enum GospelBook {
  matthew('ማቴዎስ', 'Matthew'),
  mark('ማርቆስ', 'Mark'),
  luke('ሉቃስ', 'Luke'),
  john('ዮሐንስ', 'John');

  const GospelBook(this.amharicName, this.englishName);

  final String amharicName;
  final String englishName;

  String name(bool isAmharic) => isAmharic ? amharicName : englishName;
}

class GospelVerse {
  const GospelVerse({
    required this.book,
    required this.chapter,
    required this.verses,
    required this.amharic,
    required this.english,
  });

  final GospelBook book;
  final int chapter;

  /// Verse number or range, for example `16` or `29-30`.
  final String verses;

  final String amharic;
  final String english;

  String get referenceAm => '${book.amharicName} $chapter:$verses';
  String get referenceEn => '${book.englishName} $chapter:$verses';

  String reference(bool isAmharic) => isAmharic ? referenceAm : referenceEn;

  String text(bool isAmharic) => isAmharic ? amharic : english;
}

/// All verses are kept in canonical Gospel order.
const List<GospelVerse> gospelVerses = <GospelVerse>[
  // ── Matthew ──────────────────────────────────────────────────────────────
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 4,
    verses: '4',
    amharic: 'ሰው በእንጀራ ብቻ አይኖርም፥ ነገር ግን ከእግዚአብሔር አፍ በሚወጣ ቃል ሁሉ ይኖራል።',
    english:
        'Man shall not live by bread alone, but by every word that proceeds out of the mouth of God.',
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 5,
    verses: '9',
    amharic: 'የሰላም አድራጊዎች ደስ ይበላቸው፥ እነሱ የእግዚአብሔር ልጆች ይባላሉና።',
    english:
        'Blessed are the peacemakers, for they shall be called children of God.',
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 5,
    verses: '14',
    amharic: 'እናንተ የዓለም ብርሃን ናችሁ። በተራራ ላይ የተሠራች ከተማ ልትሰወር አትችልም።',
    english:
        "You are the light of the world. A city located on a hill can't be hidden.",
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 5,
    verses: '16',
    amharic:
        'እንዲሁም ብርሃናችሁ በሰው ፊት ይብራ፥ መልካም ሥራችሁን አይተው በሰማያት ያለውን አባታችሁን እንዲያከብሩ።',
    english:
        'Even so, let your light shine before men, that they may see your good works and glorify your Father who is in heaven.',
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 6,
    verses: '33',
    amharic: 'እናንተ ግን አስቀድማችሁ የእግዚአብሔርን መንግሥት እና ጽድቁን ፈልጉ፥ ይህም ሁሉ ይጨመርላችኋል።',
    english:
        "But seek first God's Kingdom and his righteousness; and all these things will be given to you as well.",
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 6,
    verses: '34',
    amharic: 'እንግዲህ ለነገ አትጨነቁ፥ ነገ ለራሱ ይጨነቃልና። ለዕለቱ ክፋት በቂ ነው።',
    english:
        "Therefore don't be anxious for tomorrow, for tomorrow will be anxious for itself. Each day's own evil is sufficient.",
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 7,
    verses: '7',
    amharic: 'ለምኑ ይሰጣችኋልም፤ ፈልጉ ታገኛላችሁም፤ መድቡ ይከፈትላችኋልም።',
    english:
        'Ask, and it will be given to you. Seek, and you will find. Knock, and it will be opened for you.',
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 11,
    verses: '28',
    amharic: 'ድካማችሁ ሁሉ የከበደባችሁ ሸክማችሁንም የተሸከማችሁ ወደ እኔ ኑ፥ እኔም አሳርፋችኋለሁ።',
    english:
        'Come to me, all you who labor and are heavily burdened, and I will give you rest.',
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 11,
    verses: '29-30',
    amharic:
        'ቀንበሬን በእናንተ ላይ ተሸከሙ፥ ከእኔም ተማሩ፥ እኔ በልቤ የዋህ እና ትሑት ነኝና፤ ለነፍሳችሁም ዕረፍት ታገኛላችሁ። ቀንበሬ ልዝብ ሸክሜም ቀላል ነው።',
    english:
        'Take my yoke upon you and learn from me, for I am gentle and humble in heart; and you will find rest for your souls. For my yoke is easy, and my burden is light.',
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 19,
    verses: '26',
    amharic: 'ይህ በሰው አይቻልም፥ በእግዚአብሔር ግን ሁሉ ይቻላል።',
    english:
        'With men this is impossible, but with God all things are possible.',
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 28,
    verses: '19',
    amharic: 'እንግዲህ ሂዱ፥ ሕዝቦችን ሁሉ በአብ፥ በወልድ፥ በመንፈስ ቅዱስም ስም አጥምቁ።',
    english:
        'Go and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit.',
  ),
  GospelVerse(
    book: GospelBook.matthew,
    chapter: 28,
    verses: '20',
    amharic: 'እነሆም፥ እኔ እስከ ዓለም ፍጻሜ ድረስ ሁልጊዜ ከእናንተ ጋር ነኝ።',
    english: 'Behold, I am with you always, even to the end of the age.',
  ),

  // ── Mark ─────────────────────────────────────────────────────────────────
  GospelVerse(
    book: GospelBook.mark,
    chapter: 9,
    verses: '23',
    amharic: 'እንዲህ ብትችል፥ ለሚያምን ሁሉ ይቻላል።',
    english: 'If you can believe, all things are possible to him who believes.',
  ),
  GospelVerse(
    book: GospelBook.mark,
    chapter: 10,
    verses: '27',
    amharic: 'በሰው አይቻልም፥ በእግዚአብሔር ግን አይደለም፤ በእግዚአብሔር ሁሉ ይቻላልና።',
    english:
        'With men it is impossible, but not with God, for all things are possible with God.',
  ),
  GospelVerse(
    book: GospelBook.mark,
    chapter: 10,
    verses: '45',
    amharic: 'የሰው ልጅ እንኳ ሊያገለግል እንጂ ሊያገለግሉት አልመጣም፥ ለብዙዎችም ቤዛ ሊሆን ሕይወቱን ሊሰጥ መጣ።',
    english:
        'For the Son of Man also came not to be served, but to serve, and to give his life as a ransom for many.',
  ),
  GospelVerse(
    book: GospelBook.mark,
    chapter: 11,
    verses: '24',
    amharic: 'ስለዚህ እላችኋለሁ፥ በጸሎት የምትለምኑትን ሁሉ ተቀብላችሁታል ብላችሁ አምኑ፥ ይሆንላችኋልም።',
    english:
        'Therefore I tell you, all things whatever you pray and ask for, believe that you have received them, and you shall have them.',
  ),
  GospelVerse(
    book: GospelBook.mark,
    chapter: 12,
    verses: '30',
    amharic: 'ጌታ አምላክህን በፍጹም ልብህ በፍጹም ነፍስህም በፍጹም አእምሮህም በፍጹም ኃይልህም ውደድ።',
    english:
        'You shall love the Lord your God with all your heart, with all your soul, with all your mind, and with all your strength.',
  ),
  GospelVerse(
    book: GospelBook.mark,
    chapter: 16,
    verses: '15',
    amharic: 'ወደ ዓለም ሁሉ ሂዱ፥ ወንጌልንም ለፍጥረት ሁሉ ስበኩ።',
    english:
        'Go into all the world and preach the Good News to the whole creation.',
  ),

  // ── Luke ─────────────────────────────────────────────────────────────────
  GospelVerse(
    book: GospelBook.luke,
    chapter: 1,
    verses: '37',
    amharic: 'በእግዚአብሔር ዘንድ የማይቻል ነገር የለምና።',
    english: 'For nothing spoken by God is impossible.',
  ),
  GospelVerse(
    book: GospelBook.luke,
    chapter: 2,
    verses: '14',
    amharic: 'ክብር በአርያም ለእግዚአብሔር ይሁን፥ በምድርም ሰላም፥ በሰዎች ዘንድ ሞገስ ይሁን።',
    english:
        'Glory to God in the highest, on earth peace, good will toward men.',
  ),
  GospelVerse(
    book: GospelBook.luke,
    chapter: 6,
    verses: '31',
    amharic: 'ሰዎች ወደ እናንተ እንዲያደርጉላችሁ የምትወዱትን ሁሉ እናንተም እንዲሁ አድርጉላቸው።',
    english:
        'As you would that men should do to you, do also to them likewise.',
  ),
  GospelVerse(
    book: GospelBook.luke,
    chapter: 6,
    verses: '38',
    amharic:
        'ስጡ፥ ይሰጣችኋልም። በጥሩ መስፈሪያ፥ በተንቀጠቀጠ፥ በተመላተመ፥ ከልብም በሚበዛ ይሰጡአችኋል፤ በምትሰፍሩበት መስፈሪያ ይሰፈርላችኋልና።',
    english:
        'Give, and it will be given to you: good measure, pressed down, shaken together, and running over, will be given to you. For with the same measure you measure it will be measured back to you.',
  ),
  GospelVerse(
    book: GospelBook.luke,
    chapter: 12,
    verses: '7',
    amharic: 'የራሳችሁ ጸጉር ሁሉ ተቆጥሯል፤ አትፍሩ፥ ከብዙ ወፎች ይበልጣላችኋል።',
    english:
        "But the very hairs of your head are all numbered. Therefore don't be afraid. You are of more value than many sparrows.",
  ),
  GospelVerse(
    book: GospelBook.luke,
    chapter: 12,
    verses: '32',
    amharic: 'አንተ ትንሽ መንጋ አትፍራ፥ አባታችሁ መንግሥቱን ሊሰጣችሁ ወደደና።',
    english:
        "Don't be afraid, little flock, for it is your Father's good pleasure to give you the Kingdom.",
  ),
  GospelVerse(
    book: GospelBook.luke,
    chapter: 18,
    verses: '27',
    amharic: 'የሰው የማይችለው በእግዚአብሔር ይቻላል።',
    english: 'The things which are impossible with men are possible with God.',
  ),
  GospelVerse(
    book: GospelBook.luke,
    chapter: 21,
    verses: '33',
    amharic: 'ሰማይና ምድር ያልፋሉ፥ ቃሌ ግን አይልፍም።',
    english:
        'Heaven and earth will pass away, but my words will not pass away.',
  ),

  // ── John ─────────────────────────────────────────────────────────────────
  GospelVerse(
    book: GospelBook.john,
    chapter: 1,
    verses: '5',
    amharic: 'ብርሃኑም በጨለማ ይበራል፥ ጨለማም አላሸነፈውም።',
    english:
        "The light shines in the darkness, and the darkness hasn't overcome it.",
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 3,
    verses: '16',
    amharic:
        'እግዚአብሔር ልጁን የሚያምን ሁሉ እንዳይጠፋ የዘላለም ሕይወት እንዲኖረው አንድያ ልጁን የሰጠ ያህል ዓለሙን ወደደ።',
    english:
        'For God so loved the world, that he gave his only born Son, that whoever believes in him should not perish, but have eternal life.',
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 6,
    verses: '35',
    amharic: 'እኔ የሕይወት እንጀራ ነኝ፤ ወደ እኔ የሚመጣ ከቶ አይራብም፥ በእኔም የሚያምን ከቶ አይጠማም።',
    english:
        'I am the bread of life. He who comes to me will not be hungry, and he who believes in me will never be thirsty.',
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 8,
    verses: '12',
    amharic: 'እኔ የዓለም ብርሃን ነኝ፤ የሚከተለኝ በጨለማ አይመላለስም፥ የሕይወት ብርሃን ይኖረዋል።',
    english:
        'I am the light of the world. He who follows me will not walk in darkness, but will have the light of life.',
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 10,
    verses: '10',
    amharic:
        'ሌባ ሊሰርቅና ሊገድል ሊያጠፋም እንጂ አይመጣም፤ እኔ ሕይወት እንዲኖራቸው በብዛትም እንዲኖራቸው መጣሁ።',
    english:
        'The thief only comes to steal, kill, and destroy. I came that they may have life, and may have it abundantly.',
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 11,
    verses: '25',
    amharic: 'እኔ ትንሣኤና ሕይወት ነኝ፤ የሚያምንብኝ ቢሞት እንኳ ይኖራል።',
    english:
        'I am the resurrection and the life. He who believes in me will still live, even if he dies.',
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 13,
    verses: '34',
    amharic: 'አዲስ ትእዛዝ እሰጣችኋለሁ፥ እኔ እንደ ወደድኋችሁ እናንተም እንዲሁ ተዋደዱ።',
    english:
        'A new commandment I give to you, that you love one another. Just as I have loved you, you also love one another.',
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 14,
    verses: '6',
    amharic: 'እኔ መንገድና እውነት ሕይወትም ነኝ፤ በእኔ ብቻ ካልሆነ ወደ አብ የሚመጣ የለም።',
    english:
        'I am the way, the truth, and the life. No one comes to the Father, except through me.',
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 14,
    verses: '27',
    amharic:
        'ሰላምን እተውላችኋለሁ፥ ሰላሜንም እሰጣችኋለሁ፤ ዓለም እንደሚሰጥ አይደለም እኔ እሰጣችኋለሁ። ልባችሁ አይታወክ፥ አይፍራም።',
    english:
        "Peace I leave with you. My peace I give to you; not as the world gives, I give to you. Don't let your heart be troubled, neither let it be fearful.",
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 15,
    verses: '5',
    amharic:
        'እኔ የወይን ግንድ ነኝ፥ እናንተ ቅርንጫፎች ናችሁ፤ በእኔ የሚኖር እኔም በእርሱ የሚኖር ብዙ ፍሬ ያፈራል፤ ያለእኔ ምንም ማድረግ አትችሉምና።',
    english:
        'I am the vine. You are the branches. He who remains in me and I in him bears much fruit, for apart from me you can do nothing.',
  ),
  GospelVerse(
    book: GospelBook.john,
    chapter: 16,
    verses: '33',
    amharic:
        'ይህን የነገርኋችሁ በእኔ ሰላም እንዲኖራችሁ ነው። በዓለም መከራ ታገኛላችሁ፥ ነገር ግን አደንቅብ፤ እኔ ዓለሙን አሸንፌዋለሁ።',
    english:
        'I have told you these things, that in me you may have peace. In the world you have trouble; but cheer up! I have overcome the world.',
  ),
];

/// Returns the Gospel verse appointed for [date].
///
/// The selection uses the number of whole days since 1 January 1970, so it is
/// deterministic for a given calendar day, changes at local midnight, and
/// cycles through the whole collection without any server call.
GospelVerse gospelVerseForDate(DateTime date) {
  final calendarDay = DateTime.utc(date.year, date.month, date.day);
  final daysSinceEpoch = calendarDay
      .difference(DateTime.utc(1970, 1, 1))
      .inDays;
  final index = daysSinceEpoch % gospelVerses.length;
  return gospelVerses[index];
}

/// Convenience accessor for the dashboard.
GospelVerse get todayGospelVerse => gospelVerseForDate(DateTime.now());
