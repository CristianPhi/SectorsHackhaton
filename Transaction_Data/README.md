# Transaction Data

Folder ini dibuat untuk menyiapkan data transaksi saham yang nantinya dipakai di halaman search page dan stock detail.

## Tujuan

- menampilkan daftar saham yang bisa dicari/di-filter berdasarkan transaction data
- menampilkan jumlah transaksi saham per saham
- menghubungkan hasil screener ke halaman detail saham

## API yang dipakai

Koneksi ke Sectors API:

- GET https://api.sectors.app/v2/close/?limit=20
- GET https://api.sectors.app/v2/daily/{symbol}/
- GET https://api.sectors.app/v2/idx-total/
- GET https://api.sectors.app/v2/index-daily/
- GET https://api.sectors.app/v2/index-daily/{index_code}/

## Environment variable

Buat file `.env` di aplikasi pemanggil dan isi API key secara lokal:

```env
SECTORS_API_KEY=your-sectors-api-key
```

## Struktur data utama

- daily-full-universe-close.ts: GET `/close/?limit=20`
- daily-transaction-data.ts: GET `/daily/{symbol}/`
- idx-market-summary.ts: GET `/idx-total/`
- daily-full-universe-index-close.ts: GET `/index-daily/`
- index-daily-transaction-data.ts: GET `/index-daily/{index_code}/`
- transaction.types.ts: definisi tipe data transaksi saham
- transaction.service.ts: client API dan helper normalisasi data

## Contoh penggunaan

```ts
import { getDailyFullUniverseClose } from "./daily-full-universe-close";
import { getDailyTransactionData } from "./daily-transaction-data";
import { getIdxMarketSummary } from "./idx-market-summary";
import { getDailyFullUniverseIndexClose } from "./daily-full-universe-index-close";
import { getIndexDailyTransactionData } from "./index-daily-transaction-data";
import {
  getTransactionScreener,
  getTransactionDetailPage,
} from "./transaction.service";

const stocks = await getTransactionScreener("bank");
console.log(stocks);

const detail = await getTransactionDetailPage("BBCA");
const close = await getDailyFullUniverseClose();
const daily = await getDailyTransactionData("BBCA");
const market = await getIdxMarketSummary();
const indexClose = await getDailyFullUniverseIndexClose();
const indexDaily = await getIndexDailyTransactionData("COMPOSITE");
console.log({ close, daily, market, indexClose, indexDaily, stocks, detail });
```

## Catatan

Karena field transaksi di API bisa bervariasi tergantung payload, helper di service akan mencoba membaca field seperti:

- totalTransaction
- totalTransactions
- transaction
- trades
- totalTrades
- volume

sehingga data tetap bisa ditampilkan secara konsisten di search page dan stock detail.
