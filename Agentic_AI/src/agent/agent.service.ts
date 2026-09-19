import { Injectable } from '@nestjs/common';
import { SectorsService } from '../sectors/sectors.service';
import { GoogleGenAI, Type } from '@google/genai';

@Injectable()
export class AgentService {
  private ai: GoogleGenAI;

  constructor(private readonly sectorsService: SectorsService) {
    this.ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }

  async analyze(userPrompt: string): Promise<string | null> {
    const systemInstruction = 
    `Kamu adalah Senior Financial & Technical Analyst pasar saham IHSG. 
    Untuk setiap permintaan analisis saham, kamu WAJIB melakukan dua hal secara bersamaan:
    1. Panggil tool fundamental (seperti get_company_overview) untuk menilai kesehatan bisnis, valuasi (PER/PBV), dan profitabilitasnya.
    2. Panggil tool teknikal (get_technical_indicators) untuk mengecek momentum harga, area support/resistance, dan indikator teknikalnya.
    
    Gabungkan kedua analisis ini untuk memberikan kesimpulan yang komprehensif: apakah secara fundamental bagus DAN secara teknikal momentumnya mendukung untuk dibeli (Buy), ditahan (Hold), atau dijual (Sell) saat ini.`;

    const tools: any = [
      {
        functionDeclarations: [
          {
            name: 'screen_companies',
            description: 'Filter daftar saham IHSG berdasarkan kondisi kriteria tertentu.',
            parameters: {
              type: Type.OBJECT,
              properties: {
                where: { type: Type.STRING, description: 'Query SQL-like condition (contoh: pbv < 1.5 AND pe_ratio > 0)' },
                order_by: { type: Type.STRING, description: 'Urutan kriteria (contoh: -dividend_yield atau -market_cap)' },
              },
              required: ['where'],
            },
          },
          {
            name: 'get_company_overview',
            description: 'Mengambil laporan lengkap fundamental 1 kode saham spesifik.',
            parameters: {
              type: Type.OBJECT,
              properties: {
                symbol: { type: Type.STRING, description: 'Kode ticker saham IHSG, misal BBCA atau BMHS' },
              },
              required: ['symbol'],
            },
          },
          {
            name: 'get_technical_indicators',
            description: 'Mengambil data indikator teknikal saham (seperti Moving Average, RSI, tren harga) untuk analisis momentum dan timing.',
            parameters: {
              type: Type.OBJECT,
              properties: {
                symbol: { type: Type.STRING, description: 'Kode ticker saham IHSG, misal BBCA' },
              },
              required: ['symbol'],
            },
          },
        ],
      },
    ];

    const chat = this.ai.chats.create({
      model: 'gemini-3.5-flash-lite',
      config: {
        systemInstruction,
        tools,
      },
    });

    let response = await chat.sendMessage({ message: userPrompt });

    while (response.functionCalls && response.functionCalls.length > 0) {
      const functionCall = response.functionCalls[0];
      const { name, args } = functionCall;
      let toolResult = '';

      if (name === 'screen_companies') {
        const typedArgs = args as { where: string; order_by?: string };
        toolResult = await this.sectorsService.screenCompanies(typedArgs.where, typedArgs.order_by || '');
      } else if (name === 'get_company_overview') {
        const typedArgs = args as { symbol: string };
        toolResult = await this.sectorsService.getCompanyOverview(typedArgs.symbol);
      } else if (name === 'get_technical_indicators') {
        const typedArgs = args as { symbol: string };
        toolResult = await this.sectorsService.getTechnicalIndicators(typedArgs.symbol);
      }

      let parsedToolResult: any;
      try {
        parsedToolResult = typeof toolResult === 'string' ? JSON.parse(toolResult || '{}') : toolResult;
      } catch {
        parsedToolResult = { result: toolResult };
      }

      response = await chat.sendMessage({
        message: [
          {
            functionResponse: {
              name: name,
              response: { result: parsedToolResult },
            },
          },
        ],
      });
    }

    const finalResult = response.text;
    return typeof finalResult === 'string' ? finalResult : JSON.stringify(finalResult || '');
  }
}