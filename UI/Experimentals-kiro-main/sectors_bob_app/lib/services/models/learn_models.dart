/// Models for the Belajar tab: educational videos and market news, presented
/// together in one feed.
library;

/// A learning video. [youtubeId] is the 11-character YouTube video id used to
/// build the watch URL and the thumbnail. [isReal] flags whether this points at
/// a genuine, verified public video (opens YouTube) or is an illustrative mock
/// entry, so the UI can be honest about placeholders instead of showing dead
/// links.
class LearnVideo {
  const LearnVideo({
    required this.title,
    required this.channel,
    required this.youtubeId,
    required this.durationLabel,
    this.isReal = false,
  });

  final String title;
  final String channel;
  final String youtubeId;
  final String durationLabel;
  final bool isReal;

  /// The canonical watch URL for this video.
  String get watchUrl => 'https://www.youtube.com/watch?v=$youtubeId';

  /// The high-quality thumbnail URL served by YouTube for this video id.
  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';

  factory LearnVideo.fromJson(Map<String, dynamic> json) {
    return LearnVideo(
      title: json['title'] as String,
      channel: json['channel'] as String,
      youtubeId: json['youtubeId'] as String,
      durationLabel: json['durationLabel'] as String,
      isReal: json['isReal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'channel': channel,
      'youtubeId': youtubeId,
      'durationLabel': durationLabel,
      'isReal': isReal,
    };
  }
}

/// A market news article shown in the Belajar feed and opened in an in-app
/// reader. [body] holds the full paragraphs for the reader; [summary] is the
/// short teaser shown in the feed. [likes] is a static display count for the
/// inert Comment/Like/Share row (no backend).
class LearnArticle {
  const LearnArticle({
    required this.id,
    required this.title,
    required this.source,
    required this.timeAgo,
    required this.readTime,
    required this.summary,
    required this.body,
    required this.likes,
  });

  final String id;
  final String title;
  final String source;
  final String timeAgo;
  final String readTime;
  final String summary;
  final List<String> body;
  final String likes;

  factory LearnArticle.fromJson(Map<String, dynamic> json) {
    return LearnArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      source: json['source'] as String,
      timeAgo: json['timeAgo'] as String,
      readTime: json['readTime'] as String,
      summary: json['summary'] as String,
      body: (json['body'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      likes: json['likes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'source': source,
      'timeAgo': timeAgo,
      'readTime': readTime,
      'summary': summary,
      'body': body,
      'likes': likes,
    };
  }
}

/// A publisher or channel shown in the Top Kanal row. [isVideo] tells whether
/// tapping should scope the feed to videos from this channel or news from this
/// source.
class LearnChannel {
  const LearnChannel({
    required this.name,
    required this.isVideo,
  });

  final String name;
  final bool isVideo;

  /// Up to two initials for the avatar, derived from the name.
  String get initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final String p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}
