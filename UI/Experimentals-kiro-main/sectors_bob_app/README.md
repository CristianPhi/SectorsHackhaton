# sectors_bob_app

BOB is an AI stock analysis app for Indonesian retail investors on the IDX
exchange. This repository is the mobile frontend only. The backend is not
available here, so the app runs against a mock service layer that can be
swapped for a real API later without touching the UI.

## What is in this app

The hero flow, end to end:

Splash to Onboarding to Auth (Login, Sign Up, Forgot Password) to Home to AI
Chat to Stock Detail, plus Profile and the Belajar tab.

Highlights:

- State management with Riverpod.
- Routing with go_router, including a three-tab bottom shell: Belajar, Beranda
  (the hero), and BOB AI.
- Chat responses come back as structured data and are rendered as clean cards
  with progressive disclosure, a thinking indicator, and a mandatory
  disclaimer.
- Design tokens taken from the client palette. Gold is for actions only, green
  and red are for data signals only.
- All primary copy is in Bahasa Indonesia.

### Home (Beranda)

- A top bar with a stock search field and the profile avatar to its right.
  Tapping the avatar opens Profile; tapping the search bar opens a full-screen
  stock search with live filtering by ticker or company name.
- A Tanya BOB card (ask field plus suggestion chips) that opens the chat.
- A Favorit / Discover toggle. Favorit lists favorited stocks with a friendly
  empty state; Discover lists local stocks and recent history.

### Favorites

- A heart toggle on every stock row and on the Stock Detail app bar. The heart
  uses the gold accent because favoriting is an action, not a data signal.
- Seeded favorites (BBCA and TLKM) always come back on a fresh launch, matching
  what a real backend would persist. Favorites the user adds during a session
  are kept in memory only and reset on a full restart. This split lives in the
  mock `StockService`; `FavoritesController` mirrors it as reactive state so
  every heart and the Favorit list update together.

### Profile

- Shows the signed-in user's name, email, and a Google badge when applicable.
- Settings: edit profile (updates the display name through
  `AuthService.updateProfile`), a dark/light theme toggle, a language picker,
  and sign out, with a version and DYOR footer.
- The theme and language controls are real, toggleable state but do not repaint
  the app yet. BOB is dark-first, so light mode carries an honest
  "Mode terang segera hadir" note rather than a fake switch.

### Belajar tab (replaces the old News tab)

- A single blended feed of educational videos and market news, following a
  news-app layout: a search field, a Top Kanal channel row, a featured video
  carousel (Sorotan), filter chips (Semua / Video / Berita), and a mixed
  vertical feed of compact video and article rows.
- Tapping a channel in Top Kanal scopes the feed to that channel or source;
  tapping again clears it. Search filters both videos and articles.
- Videos are backed by the mock `LearnService`. One entry is a genuine, verified
  public video from the official Indonesia Stock Exchange (IDX) YouTube channel
  and opens YouTube (via `url_launcher`, external application mode). The rest are
  illustrative placeholders labelled "Contoh" that do not open a link, so the
  tab is honest about what is real.
- Tapping an article opens an in-app reader (`ArticleDetailScreen`) with an
  image header, source badge, full body text, and an inert Comment / Like /
  Share row (display only, no backend).

### Forgot Password

- A link on the login screen opens the forgot-password screen. Entering an email
  and submitting calls the mock `AuthService.sendPasswordReset`, then shows a
  confirmation with a Resend action. No real email is sent by the mock.

## Mock service layer

The service layer is fully mocked and sits behind interfaces:

- `AuthService` (email and password, a Google button wired to the mock, plus
  password reset and profile update).
- `StockService` (local stocks, favorites with add/remove, recently searched,
  search, and full detail with chart points, technicals, fundamentals, and
  news).
- `ChatService` (send a message, receive a thinking state, then a structured
  analysis).
- `LearnService` (educational videos and market news for the Belajar tab).

Mock data covers four IDX blue chips: BBCA, BBRI, BMRI, and TLKM. The chat mock
emits a thinking message first, waits to simulate progressive analysis, then
emits the final structured result, so the streaming behaviour is real even
against mock data.

To connect a real backend, implement the interfaces under
`lib/services/interfaces` and override the providers in the root `ProviderScope`
inside `lib/main.dart`. Nothing in the UI changes. For example:

```dart
ProviderScope(
  overrides: <Override>[
    chatServiceProvider.overrideWithValue(HttpChatService(apiClient)),
    stockServiceProvider.overrideWithValue(HttpStockService(apiClient)),
    authServiceProvider.overrideWithValue(HttpAuthService(apiClient)),
  ],
  child: const BobApp(),
)
```

Because the chat AI returns structured data (not markdown), a real backend just
needs to produce the same JSON shape defined in
`lib/services/models/analysis_models.dart`. The cards render it as is.

## Tech stack

- Flutter (Material 3, dark-first: teal canvas with off-white surfaces).
- Riverpod for state management.
- go_router for navigation and the three-tab shell.
- google_fonts for Plus Jakarta Sans.
- intl for Rupiah and percent formatting in the id_ID locale.
- url_launcher to open Belajar videos on YouTube.

## Folder structure

```
lib/
  core/
    theme/      design tokens and the app theme
    router/     go_router route graph
  services/
    interfaces/ service contracts (Auth, Stocks, Chat)
    mock/       mock implementations and Indonesian mock data
    models/     data models with fromJson and toJson
    widgets/    shared UI widgets (buttons, badges, logo)
    format/     number formatters (Rupiah, percent)
  features/
    splash/       splash screen
    onboarding/   three onboarding slides
    auth/         login, sign up, and forgot password
    home/         Beranda hero screen (search, Tanya BOB, Favorit/Discover)
    search/       full-screen stock search
    favorites/    reactive favorites controller
    profile/      profile, edit profile, and settings
    chat/         AI chat with structured analysis cards
    stock_detail/ price block, sparkline chart, sections
    belajar/      Belajar tab: blended videos and news feed + in-app reader
  main.dart     app entry point
```

## Requirements

- Flutter stable SDK.
- Dart SDK 3.3.0 or newer, below 4.0.0.

The Plus Jakarta Sans font is fetched at runtime by the google_fonts package,
so no font files are bundled.

The sparkline chart uses `Color.withOpacity` for its gradient fill to stay
compatible with the 3.3.0 SDK floor, since `Color.withValues(alpha:)` only
exists on newer stable SDKs. On a recent SDK the analyzer may flag this as
deprecated. If you raise the SDK floor, switch those two calls in
`lib/features/stock_detail/widgets/sparkline_chart.dart` to `withValues(alpha:)`.

## How to run

```
flutter pub get
flutter run
```

## Notes

- The service layer is mocked. Prices, indicators, and news are illustrative
  sample data, not live market data.
- Nothing in the app is investment advice. Every analysis carries a disclaimer
  that reminds users to do their own research.
