import { Controller, Get, Query } from '@nestjs/common';
import { LearnService } from './learn.service.js';

@Controller('learn')
export class LearnController {
  constructor(private readonly learnService: LearnService) {}

  @Get('videos')
  async getVideos() {
    return this.learnService.getVideos();
  }

  @Get('channels')
  async getChannels() {
    return this.learnService.getChannels();
  }
}

@Controller('api')
export class ApiNewsController {
  constructor(private readonly learnService: LearnService) {}

  @Get('news')
  async getNews(@Query('symbol') symbol?: string) {
    return this.learnService.getNews(symbol);
  }
}
