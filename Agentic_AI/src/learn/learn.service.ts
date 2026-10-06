import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class LearnService {
  private readonly logger = new Logger(LearnService.name);
  private readonly youtubeApiKey = process.env.YOUTUBE_API_KEY;
  private readonly sectorsBaseUrl = 'https://api.sectors.app/v2';
  private readonly sectorsApiKey = process.env.SECTORS_API_KEY;
  private newsCache?: { data: unknown[]; expiresAt: number };
  private newsRequest?: Promise<unknown[]>;

  async getVideos() {
    if (!this.youtubeApiKey) {
      return [];
    }

    try {
      const searchResponse = await axios.get('https://www.googleapis.com/youtube/v3/search', {
        params: {
          part: 'snippet',
          q: 'belajar saham Indonesia',
          type: 'video',
          order: 'relevance',
          maxResults: 8,
          regionCode: 'ID',
          relevanceLanguage: 'id',
          key: this.youtubeApiKey,
        },
        timeout: 10000,
      });

      const searchItems = Array.isArray(searchResponse.data?.items)
        ? searchResponse.data.items
        : [];
      const videoIds = searchItems
        .map((item: any) => item?.id?.videoId)
        .filter((id: unknown): id is string => typeof id === 'string' && id.length > 0);

      if (!videoIds.length) {
        return [];
      }

      const detailsResponse = await axios.get('https://www.googleapis.com/youtube/v3/videos', {
        params: {
          part: 'contentDetails',
          id: videoIds.join(','),
          key: this.youtubeApiKey,
        },
        timeout: 10000,
      });
      const durationById = new Map<string, string>();
      for (const item of detailsResponse.data?.items ?? []) {
        const id = item?.id;
        if (typeof id === 'string') {
          durationById.set(id, this.formatDuration(item?.contentDetails?.duration));
        }
      }

      return searchItems.map((item: any) => {
        const youtubeId = item.id.videoId;
        return {
          title: item.snippet?.title ?? 'Video saham',
          channel: item.snippet?.channelTitle ?? 'YouTube',
          youtubeId,
          durationLabel: durationById.get(youtubeId) ?? 'Video',
          isReal: true,
        };
      });
    } catch (error) {
      this.logger.warn(`Video fetch failed: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }

  async getChannels() {
    const videos = await this.getVideos();
    return [...new Set(videos.map((video: any) => video.channel))].map((name) => ({
      name,
      isVideo: true,
    }));
  }

  async getNews(_symbol?: string) {
    if (!this.sectorsApiKey) {
      return [];
    }

    if (this.newsCache && this.newsCache.expiresAt > Date.now()) {
      return this.newsCache.data;
    }
    if (this.newsRequest) {
      return this.newsRequest;
    }

    this.newsRequest = this.fetchNews()
      .then((data) => {
        this.newsCache = { data, expiresAt: Date.now() + 30 * 60 * 1000 };
        return data;
      })
      .catch((error) => {
        this.logger.warn(`News fetch failed: ${error instanceof Error ? error.message : String(error)}`);
        return [];
      })
      .finally(() => {
        this.newsRequest = undefined;
      });
    return this.newsRequest;
  }

  private async fetchNews(): Promise<unknown[]> {
    const response = await axios.get(`${this.sectorsBaseUrl}/news/`, {
      headers: { Authorization: this.sectorsApiKey },
      params: { limit: 8, offset: 0 },
      timeout: 10000,
    });

    const items = Array.isArray(response.data?.results) ? response.data.results : Array.isArray(response.data) ? response.data : [];
    return items.slice(0, 6).map((item: any, index: number) => ({
      id: String(item?.id ?? `news-${index + 1}`),
      title: item?.title ?? 'Berita pasar',
      source: item?.source ?? item?.publisher ?? 'Sectors',
      timeAgo: item?.published_at ? new Date(item.published_at).toLocaleDateString('id-ID') : 'Baru',
      readTime: item?.reading_time ? `${item.reading_time} menit` : '4 menit',
      summary: item?.summary ?? item?.description ?? 'Ringkasan berita pasar.',
      body: item?.body ? [String(item.body)] : [item?.summary ?? 'Ringkasan berita pasar.'],
      likes: item?.likes ? String(item.likes) : '0',
    }));
  }

  private formatDuration(value?: string): string {
    const match = value?.match(/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);
    if (!match) {
      return 'Video';
    }
    const hours = Number(match[1] ?? 0);
    const minutes = Number(match[2] ?? 0);
    const seconds = Number(match[3] ?? 0);
    if (hours > 0) {
      return `${hours}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
    }
    return `${minutes}:${String(seconds).padStart(2, '0')}`;
  }
}
