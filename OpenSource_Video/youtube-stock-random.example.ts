import { getRandomStockLearningVideo, getRandomStockLearningVideos } from './youtube-stock-random';

async function demo() {
  const video = await getRandomStockLearningVideo();
  console.log('Random video:', video?.snippet?.title);
  console.log('Views:', video?.statistics?.viewCount);

  const videos = await getRandomStockLearningVideos(5);
  console.log('Random list:', videos.map((item) => item.snippet?.title));
}

demo().catch((error) => {
  console.error(error);
});
