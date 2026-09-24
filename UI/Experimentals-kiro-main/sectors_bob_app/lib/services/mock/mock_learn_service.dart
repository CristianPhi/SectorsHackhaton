import '../interfaces/learn_service.dart';
import '../models/learn_models.dart';

/// In-memory mock content for the Belajar tab.
///
/// One video is a genuine, verified public video from the official Indonesia
/// Stock Exchange (IDX) channel and opens YouTube when tapped. The rest are
/// illustrative placeholders (isReal: false) so the tab looks complete without
/// linking to videos that may not exist; the UI labels these as "Contoh" and
/// does not attempt to open them. Articles carry full body text for the in-app
/// reader. Comment/like/share counts are static display values (no backend).
class MockLearnService implements LearnService {
  MockLearnService();

  static const Duration _latency = Duration(milliseconds: 400);

  @override
  Future<List<LearnVideo>> videos() async {
    await Future<void>.delayed(_latency);
    return const <LearnVideo>[
      // Verified live via YouTube oEmbed: title "Buat pemula mau belajar
      // investasi!" on the "Indonesia Stock Exchange (IDX)" channel.
      LearnVideo(
        title: 'Buat pemula mau belajar investasi!',
        channel: 'Indonesia Stock Exchange (IDX)',
        youtubeId: 'GbhUcCavPvo',
        durationLabel: '3 mnt',
        isReal: true,
      ),
      LearnVideo(
        title: 'Mengenal analisis teknikal: RSI, MACD, dan moving average',
        channel: 'BOB Academy',
        youtubeId: 'mockTeknikal',
        durationLabel: '8 mnt',
      ),
      LearnVideo(
        title: 'Membaca laporan keuangan untuk investor pemula',
        channel: 'BOB Academy',
        youtubeId: 'mockFundamental',
        durationLabel: '12 mnt',
      ),
      LearnVideo(
        title: 'Apa itu P/E ratio dan cara menggunakannya',
        channel: 'BOB Academy',
        youtubeId: 'mockValuasi',
        durationLabel: '6 mnt',
      ),
      LearnVideo(
        title: 'Diversifikasi dan manajemen risiko portofolio',
        channel: 'BOB Academy',
        youtubeId: 'mockRisiko',
        durationLabel: '10 mnt',
      ),
      LearnVideo(
        title: 'Psikologi investor: menghindari keputusan emosional',
        channel: 'BOB Academy',
        youtubeId: 'mockPsikologi',
        durationLabel: '9 mnt',
      ),
    ];
  }

  @override
  Future<List<LearnArticle>> articles() async {
    await Future<void>.delayed(_latency);
    return const <LearnArticle>[
      LearnArticle(
        id: 'art-ihsg',
        title: 'IHSG ditutup menguat tipis ditopang saham perbankan',
        source: 'Kontan',
        timeAgo: '2 jam lalu',
        readTime: '3 mnt baca',
        likes: '1,2 rb',
        summary:
            'Indeks harga saham gabungan naik tipis pada penutupan, didorong '
            'penguatan saham-saham bank berkapitalisasi besar.',
        body: <String>[
          'Indeks Harga Saham Gabungan (IHSG) ditutup menguat tipis pada '
              'perdagangan hari ini, ditopang oleh penguatan saham-saham '
              'perbankan berkapitalisasi besar yang menjadi motor utama indeks.',
          'Sejumlah analis menilai penguatan ini masih tergolong terbatas dan '
              'sangat bergantung pada arus dana asing serta sentimen terhadap '
              'arah suku bunga acuan dalam beberapa pekan ke depan.',
          'Investor ritel disarankan tetap mencermati fundamental emiten dan '
              'tidak semata mengikuti pergerakan harga jangka pendek. Analisis '
              'ini bukan rekomendasi beli atau jual.',
        ],
      ),
      LearnArticle(
        id: 'art-inflasi',
        title: 'Investor mencermati rilis data inflasi bulan ini',
        source: 'Bisnis Indonesia',
        timeAgo: '5 jam lalu',
        readTime: '4 mnt baca',
        likes: '860',
        summary:
            'Pelaku pasar menanti data inflasi terbaru yang dapat memengaruhi '
            'arah kebijakan suku bunga acuan.',
        body: <String>[
          'Pelaku pasar sedang menanti rilis data inflasi terbaru yang '
              'dijadwalkan diumumkan pekan ini. Angka inflasi menjadi salah '
              'satu acuan penting bagi bank sentral dalam menentukan arah '
              'kebijakan suku bunga.',
          'Inflasi yang lebih tinggi dari perkiraan berpotensi menahan '
              'penurunan suku bunga, sementara inflasi yang terkendali dapat '
              'membuka ruang pelonggaran yang biasanya disambut positif oleh '
              'pasar saham.',
          'Bagi investor pemula, memahami hubungan antara inflasi, suku bunga, '
              'dan harga saham adalah dasar penting sebelum mengambil keputusan.',
        ],
      ),
      LearnArticle(
        id: 'art-rupiah',
        title: 'Tekanan nilai tukar rupiah membayangi sesi perdagangan',
        source: 'CNBC Indonesia',
        timeAgo: '1 hari lalu',
        readTime: '3 mnt baca',
        likes: '540',
        summary:
            'Pergerakan nilai tukar rupiah terhadap dolar AS menjadi perhatian '
            'karena berpotensi memengaruhi arus modal asing.',
        body: <String>[
          'Pergerakan nilai tukar rupiah terhadap dolar Amerika Serikat kembali '
              'menjadi perhatian pelaku pasar pada sesi perdagangan terakhir.',
          'Pelemahan rupiah dapat memicu keluarnya arus modal asing dari pasar '
              'saham domestik, terutama pada emiten dengan eksposur utang dalam '
              'mata uang asing.',
          'Sebaliknya, sejumlah emiten berorientasi ekspor justru dapat '
              'diuntungkan. Diversifikasi tetap menjadi kunci mengelola risiko.',
        ],
      ),
      LearnArticle(
        id: 'art-telko',
        title: 'Sektor telekomunikasi berinvestasi besar di infrastruktur data',
        source: 'Investor Daily',
        timeAgo: '2 hari lalu',
        readTime: '5 mnt baca',
        likes: '712',
        summary:
            'Belanja modal untuk pusat data dan jaringan digital diperkirakan '
            'menopang pertumbuhan jangka panjang emiten telekomunikasi.',
        body: <String>[
          'Emiten sektor telekomunikasi meningkatkan belanja modal untuk '
              'membangun pusat data dan memperkuat jaringan digital, seiring '
              'melonjaknya kebutuhan layanan data di dalam negeri.',
          'Investasi jangka panjang ini diperkirakan menekan arus kas dalam '
              'jangka pendek, namun berpotensi menopang pertumbuhan pendapatan '
              'di masa depan.',
          'Investor perlu menimbang antara potensi pertumbuhan dan tekanan '
              'margin sebelum menilai valuasi emiten di sektor ini.',
        ],
      ),
    ];
  }

  @override
  Future<List<LearnChannel>> channels() async {
    await Future<void>.delayed(_latency);
    return const <LearnChannel>[
      LearnChannel(name: 'Indonesia Stock Exchange (IDX)', isVideo: true),
      LearnChannel(name: 'BOB Academy', isVideo: true),
      LearnChannel(name: 'Kontan', isVideo: false),
      LearnChannel(name: 'Bisnis Indonesia', isVideo: false),
      LearnChannel(name: 'CNBC Indonesia', isVideo: false),
      LearnChannel(name: 'Investor Daily', isVideo: false),
    ];
  }
}
