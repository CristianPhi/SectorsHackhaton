import { Test, TestingModule } from '@nestjs/testing';
import { ApiNewsController, LearnController } from './learn.controller';
import { LearnService } from './learn.service';

describe('LearnController', () => {
  let learnController: LearnController;
  let newsController: ApiNewsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [LearnController, ApiNewsController],
      providers: [
        {
          provide: LearnService,
          useValue: {
            getVideos: jest.fn().mockResolvedValue([
              {
                title: 'Belajar Saham untuk Pemula',
                channel: 'IDX Channel',
                youtubeId: 'abc123def45',
                durationLabel: '12:30',
                isReal: true,
              },
            ]),
            getChannels: jest.fn().mockResolvedValue([
              { name: 'IDX Channel', isVideo: true },
            ]),
            getNews: jest.fn().mockResolvedValue([
              {
                id: '1',
                title: 'Pasar saham bergerak positif',
                source: 'Kontan',
                timeAgo: '2 jam lalu',
                readTime: '4 menit',
                summary: 'Ringkasan pasar',
                body: ['Paragraf 1'],
                likes: '1.2k',
              },
            ]),
          },
        },
      ],
    }).compile();

    learnController = module.get<LearnController>(LearnController);
    newsController = module.get<ApiNewsController>(ApiNewsController);
  });

  it('returns no mock learning content and only real market news when available', async () => {
    await expect(learnController.getVideos()).resolves.toEqual([]);
    await expect(learnController.getChannels()).resolves.toEqual([]);
    await expect(newsController.getNews('BBCA')).resolves.toHaveLength(1);
  });
});
