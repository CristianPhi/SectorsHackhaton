import { Injectable } from '@nestjs/common';
import { SectorsService } from '../sectors/sectors.service';
import { GoogleGenAI, Type } from '@google/genai';
import { BrokerService } from '../../../broker/broker.service';

@Injectable()
export class AgentService {
  private ai: GoogleGenAI;

  constructor(
    private readonly sectorsService: SectorsService,
    private readonly brokerService: BrokerService,
  ) {
    this.ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }

  private extractSymbol(prompt: string, requestedTicker?: string): string {
    const explicitTicker = (requestedTicker ?? '')
      .trim()
      .toUpperCase()
      .replace(/\.JK$/, '');
    if (/^[A-Z0-9]{1,5}$/.test(explicitTicker)) {
      return explicitTicker;
    }

    const upper = prompt.toUpperCase();
    const contextualMatch = upper.match(
      /\b(?:SAHAM|TICKER|EMITEN)\s+([A-Z0-9]{1,5})(?:\.JK)?\b/,
    );
    if (contextualMatch) {
      return contextualMatch[1];
    }

    const known = [
      'BBCA',
      'BBRI',
      'BMRI',
      'TLKM',
      'GOTO',
      'BRIS',
      'ASII',
      'SMGR',
    ];
    const match = known.find((symbol) =>
      new RegExp(`\\b${symbol}\\b`).test(upper),
    );
    return match ?? 'BBCA';
  }

  private isUnavailable(value: unknown): boolean {
    const text = String(value ?? '').trim();
    return (
      !text || /^(n\/?a|not available|unknown|null|undefined|-+)$/i.test(text)
    );
  }

  private buildTechnicalFallback(detail: any): any[] {
    const price = Number(detail?.stock?.price ?? 0);
    const changePercent = Number(detail?.stock?.changePercent);
    const sparkline = Array.isArray(detail?.sparkline)
      ? detail.sparkline.map(Number).filter(Number.isFinite)
      : [];
    const high =
      Number(detail?.dayHigh ?? 0) ||
      (sparkline.length ? Math.max(...sparkline) : 0);
    const low =
      Number(detail?.dayLow ?? 0) ||
      (sparkline.length ? Math.min(...sparkline) : 0);
    const hasPrice = Number.isFinite(price) && price > 0;
    const hasChange = Number.isFinite(changePercent);
    const trend =
      hasPrice && hasChange
        ? changePercent >= 0
          ? 'Uptrend'
          : 'Downtrend'
        : 'Data belum tersedia';
    const priceText = hasPrice
      ? `Rp ${new Intl.NumberFormat('id-ID').format(price)}`
      : 'Data belum tersedia';

    return [
      {
        name: 'Trend',
        value: trend,
        interpretation:
          hasPrice && hasChange
            ? `Perubahan harga terakhir ${changePercent.toFixed(2)}%.`
            : 'Data perubahan harga harian belum tersedia.',
        signal:
          hasPrice && hasChange
            ? changePercent >= 0
              ? 'bullish'
              : 'bearish'
            : 'netral',
      },
      {
        name: 'Range',
        value:
          high > 0 && low > 0
            ? `${low.toFixed(0)} - ${high.toFixed(0)}`
            : 'Data belum tersedia',
        interpretation:
          high > 0 && low > 0
            ? 'Rentang harga dihitung dari data harian yang tersedia.'
            : 'Riwayat harga belum cukup untuk menghitung rentang.',
        signal: 'netral',
      },
      {
        name: 'Momentum',
        value: priceText,
        interpretation: hasPrice
          ? 'Menggunakan harga penutupan terbaru dari data harian.'
          : 'Harga penutupan terbaru belum tersedia.',
        signal:
          hasPrice && hasChange
            ? changePercent >= 0
              ? 'bullish'
              : 'bearish'
            : 'netral',
      },
    ];
  }

  private normalizeTechnicalRows(rows: unknown, detail: any): any[] {
    const fallback = this.buildTechnicalFallback(detail);
    if (!Array.isArray(rows) || rows.length === 0) {
      return fallback;
    }

    return rows.slice(0, 5).map((row: any, index: number) => {
      const name = String(
        row?.name ??
          row?.indicator ??
          row?.metric ??
          row?.label ??
          `Indikator ${index + 1}`,
      );
      const nameLower = name.toLowerCase();
      const fallbackRow = nameLower.includes('trend')
        ? fallback[0]
        : nameLower.includes('range')
          ? fallback[1]
          : nameLower.includes('momentum')
            ? fallback[2]
            : undefined;
      const rawValue =
        row?.value ?? row?.result ?? row?.current_value ?? row?.latest;
      const rawInterpretation = row?.interpretation ?? row?.description;
      const value = this.isUnavailable(rawValue)
        ? (fallbackRow?.value ?? 'Data belum tersedia')
        : String(rawValue);
      const interpretation = this.isUnavailable(rawInterpretation)
        ? (fallbackRow?.interpretation ??
          `Data ${name} belum tersedia dari provider.`)
        : String(rawInterpretation);

      return {
        name,
        value,
        interpretation,
        signal: this.normalizeSignal(row?.signal ?? fallbackRow?.signal),
      };
    });
  }

  private cleanSummary(text: string): string {
    const withoutFence = text.replace(/```json|```/gi, '').trim();
    return withoutFence
      .replace(/##+/g, '')
      .replace(/\*\*(.*?)\*\*/g, '$1')
      .replace(/\*(.*?)\*/g, '$1')
      .replace(/\n+/g, ' ')
      .replace(/\s{2,}/g, ' ')
      .trim();
  }

  private parseJsonSafely(raw: unknown): any {
    if (!raw) return null;
    if (typeof raw === 'string') {
      const trimmed = raw.trim();
      if (!trimmed) return null;
      try {
        return JSON.parse(trimmed);
      } catch {
        const match = trimmed.match(/\{[\s\S]*\}/);
        if (match) {
          try {
            return JSON.parse(match[0]);
          } catch {
            return null;
          }
        }
        return null;
      }
    }
    return raw;
  }

  private normalizeSignal(value?: string): 'bullish' | 'netral' | 'bearish' {
    const text = String(value ?? '').toLowerCase();
    if (text.includes('bear') || text.includes('sell')) return 'bearish';
    if (
      text.includes('bull') ||
      text.includes('buy') ||
      text.includes('strong')
    )
      return 'bullish';
    return 'netral';
  }

  private isGeminiUnavailable(error: unknown): boolean {
    const message =
      error instanceof Error ? error.message : String(error ?? '');
    const details = JSON.stringify(error ?? {});
    return /SUBSCRIPTION_DOES_NOT_ALLOW|401|UNAUTH|UNAUTHORIZED|forbidden|not allow|API key|quota/i.test(
      `${message} ${details}`,
    );
  }

  private buildLocalAnalysis(symbol: string, detail: any, brokerNews: any[]) {
    const topTech = this.normalizeTechnicalRows(detail.teknikal, detail).slice(
      0,
      3,
    );
    const topFund = (detail.fundamental ?? []).slice(0, 3).map((item: any) => ({
      name: item?.name ?? 'Metric',
      value: item?.value ?? 'N/A',
      interpretation: item?.interpretation ?? 'Belum ada informasi detail.',
      signal: this.normalizeSignal(item?.signal ?? item?.interpretation),
    }));
    const bullishCount =
      topTech.filter((i: any) => i.signal === 'bullish').length +
      topFund.filter((i: any) => i.signal === 'bullish').length;
    const bearishCount =
      topTech.filter((i: any) => i.signal === 'bearish').length +
      topFund.filter((i: any) => i.signal === 'bearish').length;
    const conclusion =
      bullishCount >= bearishCount
        ? `${symbol} menunjukkan kombinasi fundamental dan teknikal yang masih cukup menarik untuk dipantau lebih lanjut.`
        : `${symbol} masih perlu kehati-hatian karena sinyal teknikal dan fundamental cenderung tertekan.`;

    return {
      ticker: symbol,
      title: `Analisis ${symbol}`,
      summary: `Secara teknikal, ${symbol} menunjukkan kondisi ${topTech[0]?.signal ?? 'netral'} dengan momentum yang perlu dimonitor secara ketat. Secara fundamental, prospek emiten masih dapat diterima bila didukung data pendukung yang konsisten. ${conclusion}`,
      teknikal: topTech,
      fundamental: topFund,
      berita: brokerNews.length
        ? brokerNews
        : (detail.berita ?? []).slice(0, 3),
      brokerSummary: brokerNews,
      conclusion,
      disclaimer:
        'Analisis ini bukan rekomendasi beli atau jual. Lakukan riset mandiri sebelum berinvestasi.',
    };
  }

  private async mapBrokerNews(symbol: string): Promise<any[]> {
    try {
      const payload = await this.brokerService.getBrokerSummary(symbol);

      const rawRows = Array.isArray(payload)
        ? payload
        : Array.isArray(payload?.data)
          ? payload.data.flatMap((day: any) =>
              Array.isArray(day?.summary) ? day.summary : [],
            )
          : Array.isArray(payload?.results)
            ? payload.results
            : [];

      return rawRows.slice(0, 4).map((row: any, index: number) => {
        const brokerName =
          row?.broker_name ??
          row?.broker ??
          row?.broker_code ??
          row?.brokerCode ??
          `Broker ${index + 1}`;
        const netFlow = Number(
          row?.net_flow ?? row?.netFlow ?? row?.nlot ?? row?.nval ?? 0,
        );
        const normalizedFlow = Number.isFinite(netFlow) ? netFlow : 0;
        const title =
          normalizedFlow >= 0
            ? `${brokerName} mencatat net buy ${normalizedFlow > 0 ? 'positif' : 'netral'} untuk ${symbol}`
            : `${brokerName} mencatat tekanan jual di ${symbol}`;
        return {
          title,
          source: brokerName,
          sentiment: normalizedFlow >= 0 ? 'positif' : 'netral',
        };
      });
    } catch {
      return [];
    }
  }

  async analyze(userPrompt: string, requestedTicker?: string): Promise<any> {
    const symbol = this.extractSymbol(userPrompt, requestedTicker);
    const detail = await this.sectorsService.getStockDetail(symbol);
    const brokerNews = await this.mapBrokerNews(symbol);

    if (!process.env.GEMINI_API_KEY) {
      return this.buildLocalAnalysis(symbol, detail, brokerNews);
    }

    const systemInstruction = `Kamu adalah Senior Financial Analyst yang ahli di saham Indonesia. Tugas utama: analisis saham berdasarkan data teknikal, fundamental, berita, dan broker flow. Balas dalam bahasa Indonesia. Kembalikan hanya JSON valid tanpa markdown dan tanpa teks tambahan. Format wajib: {"ticker":"...","title":"...","summary":"...","teknikal":[{"name":"...","value":"...","interpretation":"...","signal":"bullish|netral|bearish"}],"fundamental":[{"name":"...","value":"...","interpretation":"...","signal":"bullish|netral|bearish"}],"berita":[{"title":"...","source":"...","sentiment":"positif|netral|negatif"}],"brokerSummary":[{"broker":"...","net_flow":123,"title":"...","sentiment":"positif|netral|negatif"}],"conclusion":"...","disclaimer":"..."}. Pastikan summary dan conclusion singkat, jelas, dan berbasis fakta.`;

    const technicalContext = this.normalizeTechnicalRows(
      detail.teknikal,
      detail,
    ).slice(0, 5);
    const fundamentalContext = Array.isArray(detail.fundamental)
      ? detail.fundamental.slice(0, 5)
      : [];
    const newsContext = Array.isArray(detail.berita)
      ? detail.berita.slice(0, 3)
      : [];
    const brokerContext = brokerNews.slice(0, 4);

    const modelCandidates = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
    ];
    let parsed: any = null;

    for (const modelName of modelCandidates) {
      try {
        const chat = this.ai.chats.create({
          model: modelName,
          config: { systemInstruction },
        });
        const contextPrompt = `Analisa saham ${symbol}. User request: ${userPrompt}. Data teknikal: ${JSON.stringify(technicalContext)}. Data fundamental: ${JSON.stringify(fundamentalContext)}. Berita: ${JSON.stringify(newsContext)}. Broker summary: ${JSON.stringify(brokerContext)}.`;
        const response = await chat.sendMessage({ message: contextPrompt });
        parsed = this.parseJsonSafely(response.text);
        if (parsed && typeof parsed === 'object') {
          break;
        }
      } catch (error) {
        const isUnavailable = this.isGeminiUnavailable(error);
        console.warn(
          `AI model ${modelName} gagal dipakai, fallback ke model berikutnya:`,
          error instanceof Error ? error.message : String(error),
        );
        if (isUnavailable) {
          return this.buildLocalAnalysis(symbol, detail, brokerNews);
        }
      }
    }

    const rawPayload = parsed && typeof parsed === 'object' ? parsed : {};
    const technicalSource =
      Array.isArray(detail.teknikal) && detail.teknikal.length > 0
        ? detail.teknikal
        : rawPayload.teknikal;
    const teknikal = this.normalizeTechnicalRows(technicalSource, detail);

    const fundamental =
      Array.isArray(rawPayload.fundamental) && rawPayload.fundamental.length > 0
        ? rawPayload.fundamental
        : (detail.fundamental ?? []).slice(0, 3).map((item: any) => ({
            name: item?.name ?? 'Metric',
            value: item?.value ?? 'N/A',
            interpretation:
              item?.interpretation ?? 'Belum ada informasi detail.',
            signal: this.normalizeSignal(item?.signal ?? item?.interpretation),
          }));

    const berita =
      Array.isArray(rawPayload.berita) && rawPayload.berita.length > 0
        ? rawPayload.berita
        : brokerNews.length
          ? brokerNews
          : (detail.berita ?? []).slice(0, 3);

    const summary = this.cleanSummary(
      String(
        rawPayload.summary ??
          `Secara teknikal, ${symbol} mencerminkan kondisi ${teknikal[0]?.signal ?? 'netral'}, sementara secara fundamental prospek masih masuk akal untuk dipantau. ${rawPayload.conclusion ?? 'Kesimpulan: tetap perhatikan sentimen pasar dan data terbaru.'}`,
      ),
    );
    const conclusion = String(
      rawPayload.conclusion ??
        `Kondisi ${symbol} saat ini masih perlu diikuti secara ketat karena gabungan sinyal teknikal dan fundamental belum sepenuhnya konsisten.`,
    );

    return {
      ticker: symbol,
      title: `Analisis ${symbol}`,
      summary,
      teknikal,
      fundamental,
      berita,
      brokerSummary: Array.isArray(rawPayload.brokerSummary)
        ? rawPayload.brokerSummary
        : brokerNews,
      conclusion,
      disclaimer: String(
        rawPayload.disclaimer ??
          'Analisis ini bukan rekomendasi beli atau jual. Lakukan riset mandiri sebelum berinvestasi.',
      ),
    };
  }
}
