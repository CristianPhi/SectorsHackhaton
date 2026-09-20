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

## Key

```env
SECTORS_API_KEY=a896c0fe5d1d378c437af8cea7870ae34221f90342bdf551a9dec959ec02df7e
```

## Struktur data utama

- transaction.types.ts: definisi tipe data transaksi saham
- transaction.service.ts: fungsi fetch dan normalisasi data

## Contoh penggunaan

```ts
import { getTransactionScreener, getTransactionDetailPage } from './transaction.service';

const stocks = await getTransactionScreener('bank');
console.log(stocks);

const detail = await getTransactionDetailPage('BBCA');
console.log(detail.transactionCount);
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
