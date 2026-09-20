# OpenSource_Video

## YouTube Video API Schema

Endpoint yang umum dipakai untuk mengambil detail video YouTube:

GET https://www.googleapis.com/youtube/v3/videos

Parameter utama:

- part=snippet,contentDetails,status,statistics
- id={VIDEO_ID}
- key={API_KEY}

Contoh:

https://www.googleapis.com/youtube/v3/videos?part=snippet,contentDetails,status,statistics&id=VIDEO_ID&key=API_KEY

File schema TypeScript yang tersedia:

- youtube-video.schema.ts

Skema ini cocok untuk menampung objek respons dari YouTube Data API v3 untuk resource video.
