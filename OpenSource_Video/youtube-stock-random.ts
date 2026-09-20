import dotenv from 'dotenv';

dotenv.config({ path: '.env' });

type YouTubeSearchItem = {
  id: { videoId?: string };
  snippet?: {
    title?: string;
    description?: string;
    thumbnails?: {
      default?: { url?: string };
      medium?: { url?: string };
      high?: { url?: string };
    };
  };
};

type YouTubeVideoItem = {
  id: string;
  snippet?: {
    title?: string;
    description?: string;
    channelTitle?: string;
    thumbnails?: {
      default?: { url?: string };
      medium?: { url?: string };
      high?: { url?: string };
    };
  };
  statistics?: {
    viewCount?: string;
  };
  status?: {
    privacyStatus?: string;
  };
};

const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY;
const MIN_VIEWS = 500000;

const SEARCH_QUERIES = [
  'belajar saham indonesia',
  'belajar saham bahasa indonesia',
  'stock market investing',
  'learn stock market',
  'saham untuk pemula',
  'investing for beginners',
];

async function youtubeFetch<T>(url: string): Promise<T> {
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`YouTube API request failed: ${response.status} ${response.statusText}`);
  }

  return (await response.json()) as T;
}

async function getVideoIdsByQuery(query: string): Promise<string[]> {
  const url = new URL('https://www.googleapis.com/youtube/v3/search');
  url.searchParams.set('part', 'snippet');
  url.searchParams.set('q', query);
  url.searchParams.set('type', 'video');
  url.searchParams.set('videoEmbeddable', 'true');
  url.searchParams.set('safeSearch', 'moderate');
  url.searchParams.set('order', 'viewCount');
  url.searchParams.set('maxResults', '10');
  url.searchParams.set('regionCode', 'ID');
  url.searchParams.set('key', YOUTUBE_API_KEY ?? '');

  const data = await youtubeFetch<{ items?: YouTubeSearchItem[] }>(url.toString());

  return (data.items ?? [])
    .map((item) => item.id?.videoId)
    .filter((id): id is string => Boolean(id));
}

async function getVideoDetails(videoIds: string[]): Promise<YouTubeVideoItem[]> {
  if (!videoIds.length) return [];

  const url = new URL('https://www.googleapis.com/youtube/v3/videos');
  url.searchParams.set('part', 'snippet,statistics,status');
  url.searchParams.set('id', videoIds.join(','));
  url.searchParams.set('key', YOUTUBE_API_KEY ?? '');

  const data = await youtubeFetch<{ items?: YouTubeVideoItem[] }>(url.toString());
  return data.items ?? [];
}

export async function getRandomStockLearningVideo() {
  if (!YOUTUBE_API_KEY) {
    throw new Error('YOUTUBE_API_KEY belum diatur di .env');
  }

  const uniqueVideoIds = new Set<string>();

  for (const query of SEARCH_QUERIES) {
    const ids = await getVideoIdsByQuery(query);
    ids.forEach((id) => uniqueVideoIds.add(id));
  }

  const videos = await getVideoDetails(Array.from(uniqueVideoIds));

  const eligibleVideos = videos.filter((video) => {
    const views = Number(video.statistics?.viewCount ?? 0);
    const isPublic = video.status?.privacyStatus === 'public';
    return isPublic && views >= MIN_VIEWS;
  });

  if (!eligibleVideos.length) {
    throw new Error('Tidak ada video yang memenuhi minimal view 500k');
  }

  const randomIndex = Math.floor(Math.random() * eligibleVideos.length);
  return eligibleVideos[randomIndex];
}

export async function getRandomStockLearningVideos(limit = 5) {
  if (!YOUTUBE_API_KEY) {
    throw new Error('YOUTUBE_API_KEY belum diatur di .env');
  }

  const uniqueVideoIds = new Set<string>();

  for (const query of SEARCH_QUERIES) {
    const ids = await getVideoIdsByQuery(query);
    ids.forEach((id) => uniqueVideoIds.add(id));
  }

  const videos = await getVideoDetails(Array.from(uniqueVideoIds));

  const eligibleVideos = videos.filter((video) => {
    const views = Number(video.statistics?.viewCount ?? 0);
    return video.status?.privacyStatus === 'public' && views >= MIN_VIEWS;
  });

  const shuffled = [...eligibleVideos].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, Math.min(limit, shuffled.length));
}
