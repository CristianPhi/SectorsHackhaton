export interface YouTubeVideoResponse {
  kind: 'youtube#videoListResponse';
  etag: string;
  items: YouTubeVideoItem[];
  nextPageToken?: string;
  prevPageToken?: string;
  pageInfo?: {
    totalResults: number;
    resultsPerPage: number;
  };
}

export interface YouTubeVideoItem {
  kind: 'youtube#video';
  etag: string;
  id: string;
  snippet?: YouTubeVideoSnippet;
  contentDetails?: YouTubeVideoContentDetails;
  status?: YouTubeVideoStatus;
  statistics?: YouTubeVideoStatistics;
  player?: YouTubeVideoPlayer;
  topicDetails?: YouTubeVideoTopicDetails;
  recordingDetails?: {
    recordingDate?: string;
  };
  fileDetails?: YouTubeVideoFileDetails;
  processingDetails?: YouTubeVideoProcessingDetails;
  suggestions?: YouTubeVideoSuggestions;
  liveStreamingDetails?: YouTubeVideoLiveStreamingDetails;
  localizations?: Record<string, YouTubeVideoLocalized>;
}

export interface YouTubeVideoSnippet {
  publishedAt?: string;
  channelId?: string;
  title?: string;
  description?: string;
  thumbnails?: Record<string, YouTubeVideoThumbnail>;
  channelTitle?: string;
  tags?: string[];
  categoryId?: string;
  liveBroadcastContent?: string;
  defaultLanguage?: string;
  localized?: YouTubeVideoLocalized;
  defaultAudioLanguage?: string;
}

export interface YouTubeVideoLocalized {
  title: string;
  description: string;
}

export interface YouTubeVideoThumbnail {
  url: string;
  width: number;
  height: number;
}

export interface YouTubeVideoContentDetails {
  duration?: string;
  dimension?: string;
  definition?: string;
  caption?: string;
  licensedContent?: boolean;
  regionRestriction?: {
    allowed?: string[];
    blocked?: string[];
  };
  contentRating?: Record<string, string | string[]>;
  projection?: string;
  hasCustomThumbnail?: boolean;
}

export interface YouTubeVideoStatus {
  uploadStatus?: string;
  failureReason?: string;
  rejectionReason?: string;
  privacyStatus?: string;
  publishAt?: string;
  license?: string;
  embeddable?: boolean;
  publicStatsViewable?: boolean;
  madeForKids?: boolean;
  selfDeclaredMadeForKids?: boolean;
  containsSyntheticMedia?: boolean;
}

export interface YouTubeVideoStatistics {
  viewCount?: string;
  likeCount?: string;
  dislikeCount?: string;
  favoriteCount?: string;
  commentCount?: string;
}

export interface YouTubeVideoPlayer {
  embedHtml?: string;
  embedHeight?: number;
  embedWidth?: number;
}

export interface YouTubeVideoTopicDetails {
  topicIds?: string[];
  relevantTopicIds?: string[];
  topicCategories?: string[];
}

export interface YouTubeVideoFileDetails {
  fileName?: string;
  fileSize?: number;
  fileType?: string;
  container?: string;
  videoStreams?: Array<{
    widthPixels?: number;
    heightPixels?: number;
    frameRateFps?: number;
    aspectRatio?: number;
    codec?: string;
    bitrateBps?: number;
    rotation?: string;
    vendor?: string;
  }>;
  audioStreams?: Array<{
    channelCount?: number;
    codec?: string;
    bitrateBps?: number;
    vendor?: string;
  }>;
  durationMs?: number;
  bitrateBps?: number;
  creationTime?: string;
}

export interface YouTubeVideoProcessingDetails {
  processingStatus?: string;
  processingProgress?: {
    partsTotal?: number;
    partsProcessed?: number;
    timeLeftMs?: number;
  };
  processingFailureReason?: string;
  fileDetailsAvailability?: string;
  processingIssuesAvailability?: string;
  tagSuggestionsAvailability?: string;
  editorSuggestionsAvailability?: string;
  thumbnailsAvailability?: string;
}

export interface YouTubeVideoSuggestions {
  processingErrors?: string[];
  processingWarnings?: string[];
  processingHints?: string[];
  tagSuggestions?: Array<{
    tag: string;
    categoryRestricts?: string[];
  }>;
  editorSuggestions?: string[];
}

export interface YouTubeVideoLiveStreamingDetails {
  actualStartTime?: string;
  actualEndTime?: string;
  scheduledStartTime?: string;
  scheduledEndTime?: string;
  concurrentViewers?: number;
  activeLiveChatId?: string;
}

export type YouTubeVideoResource = YouTubeVideoResponse;
