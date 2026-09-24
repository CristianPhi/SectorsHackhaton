import 'package:flutter_test/flutter_test.dart';
import 'package:sectors_bob_app/services/mock/mock_learn_service.dart';
import 'package:sectors_bob_app/services/models/learn_models.dart';

void main() {
  group('MockLearnService', () {
    final MockLearnService service = MockLearnService();

    test('returns videos including exactly one real, verified video', () async {
      final List<LearnVideo> videos = await service.videos();
      expect(videos, isNotEmpty);

      final List<LearnVideo> real =
          videos.where((LearnVideo v) => v.isReal).toList();
      expect(real, hasLength(1));

      // The single real video is the verified IDX one.
      expect(real.single.youtubeId, 'GbhUcCavPvo');
      expect(real.single.channel, contains('IDX'));
    });

    test('every video exposes a watch URL and a thumbnail URL', () async {
      final List<LearnVideo> videos = await service.videos();
      for (final LearnVideo v in videos) {
        expect(v.watchUrl, contains(v.youtubeId));
        expect(v.thumbnailUrl, contains(v.youtubeId));
      }
    });

    test('returns market news articles with reader body and unique ids',
        () async {
      final List<LearnArticle> articles = await service.articles();
      expect(articles, isNotEmpty);

      final Set<String> ids = <String>{};
      for (final LearnArticle a in articles) {
        expect(a.title, isNotEmpty);
        expect(a.source, isNotEmpty);
        expect(a.id, isNotEmpty);
        expect(a.body, isNotEmpty, reason: 'reader needs body paragraphs');
        expect(a.readTime, isNotEmpty);
        ids.add(a.id);
      }
      expect(ids, hasLength(articles.length), reason: 'ids must be unique');
    });

    test('returns channels for both videos and news', () async {
      final List<LearnChannel> channels = await service.channels();
      expect(channels, isNotEmpty);
      expect(channels.any((LearnChannel c) => c.isVideo), isTrue);
      expect(channels.any((LearnChannel c) => !c.isVideo), isTrue);
      // Initials are derived and never empty.
      for (final LearnChannel c in channels) {
        expect(c.initials, isNotEmpty);
      }
    });
  });
}
