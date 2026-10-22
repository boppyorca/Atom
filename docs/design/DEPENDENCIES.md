# Phụ thuộc (DEPENDENCIES)

> v1.0 · Đã thống nhất · 2026-10-22 · Danh sách **dự kiến**; chưa thêm gì vào `pubspec.yaml`. Thêm package phải hỏi chủ dự án lúc triển khai (AGENTS.md quy tắc 5). Quyết định: [ADR-0009](../adr/0009-packages-and-ai-client.md).

Phiên bản ghi là bản ổn định mới nhất tại ngày tra; khi thêm vào `pubspec.yaml` dùng ràng buộc `^<phiên bản>`.

## 1. Package Dart/Flutter

| Package | Phiên bản | Lý do (truy vết) | Phương án bị loại | Nguồn (tra 2026-10-22) |
|---|---|---|---|---|
| `supabase_flutter` | 2.18.3 (ổn định) | Auth, REST, RPC, Edge Functions; tự xử lý deep link bằng `app_links` bên trong (F-001…F-018, ADR-0005/0006) | **3.0.0-dev.12** (prerelease, đổi API lưu phiên sang `AuthAsyncStorage`) — không dùng prerelease cho MVP; gọi HTTP tay — quá nhiều việc | pub.dev/packages/supabase_flutter; Context7 `/supabase/supabase-flutter` (xem ghi chú 3.1) |
| `provider` | 6.1.5+1 | Tiêm phụ thuộc cho ViewModel (ADR-0001) | Riverpod, BLoC, `get_it` | pub.dev/packages/provider; Context7 `/flutter/website` |
| `go_router` | 18.1.1 | Route, `redirect` chặn đăng nhập, tab giữ trạng thái (ADR-0002) | `go_router_builder` (sinh mã), `Navigator` thuần | pub.dev/packages/go_router (publisher flutter.dev); Context7 `/flutter/packages` |
| `flutter_secure_storage` | 11.2.0 | Lưu phiên trong Keychain/Keystore (ADR-0005, NFR-06); Android tối thiểu SDK 23 (dự án dùng 24) | Lưu phiên mặc định bằng `shared_preferences` | pub.dev/packages/flutter_secure_storage |
| `path_provider` | 2.1.6 | Thư mục lưu bản hồ sơ khi mất mạng (ADR-0004, F-016); Android SDK 24+, iOS 13.0+ | `sqflite`/`drift` (quá mức nhu cầu) | pub.dev/packages/path_provider |
| `shared_preferences` | 2.5.6 (Dart tối thiểu 3.11) | Lưu ngôn ngữ đã chọn (F-017). Dùng API `SharedPreferencesAsync`/`SharedPreferencesWithCache` vì API cũ `SharedPreferences` sắp ngưng; không lưu dữ liệu quan trọng | Lưu ngôn ngữ trong file tự viết | pub.dev/packages/shared_preferences, trang versions |
| `flutter_localizations` | theo Flutter SDK 3.47.7 | Bản dịch vi/en, `gen-l10n` (F-017) | — | Context7 `/flutter/website` (internationalization) |
| `intl` | ràng buộc do `flutter_localizations` quyết (khai báo `intl: any` theo hướng dẫn i18n của Flutter [CHƯA XÁC MINH: kiểm lại câu chữ trong tài liệu lúc thêm]); bản mới nhất 0.20.3 | Định dạng số tiền VND, ngày giờ (F-015, F-017) | Tự định dạng | pub.dev/packages/intl (publisher dart.dev) |
| `url_launcher` | 6.3.3 | Mở link bằng chứng, LinkedIn, `mailto:` (F-011, F-012); Android SDK 24+, iOS 13+ | — | pub.dev/packages/url_launcher |

**Phụ thuộc dev:** giữ `flutter_test` (SDK) và `flutter_lints` có sẵn từ `flutter create`; không thêm gì.

**Không thêm (đã cân nhắc):** `mockito`/`mocktail` (dùng fake viết tay), `connectivity_plus` (lỗi mạng = mất mạng), `share_plus` (dùng `Clipboard`), analytics/crash reporting, `freezed`/`json_serializable`/`build_runner`, `go_router_builder`, `flutter_web_auth_2`/`supabase_flutter_web_auth` (không bắt buộc; chỉ giúp tự đóng trình duyệt sau OAuth), SDK Google/Apple sign-in native (ADR-0005).

## 2. Công cụ và nền tảng

| Thành phần | Phiên bản | Ghi chú | Nguồn |
|---|---|---|---|
| Flutter | 3.47.7 stable | đã cài bằng Homebrew cask | `flutter --version` (Nhiệm vụ 1) |
| Dart | 3.13.5 | kèm Flutter | như trên |
| Supabase CLI | 2.121.0 | `supabase start/db reset/test db/gen types` chỉ local | `supabase --version` (Nhiệm vụ 1) |
| Postgres | 17 | `major_version = 17` trong `supabase/config.toml` | config.toml |
| pgTAP | đi kèm `supabase test db` | test CSDL | Supabase docs "Testing" |
| Edge Runtime | Deno 2 (`deno_version = 2` trong config.toml) | giới hạn: 150 giây (gói miễn phí), CPU 2 giây/yêu cầu, bộ nhớ 256 MB; việc nền bằng `EdgeRuntime.waitUntil` | Supabase docs "Edge Functions › Limits", "Background Tasks" (Context7 `/websites/supabase`) |
| Deno CLI (test Edge Functions) | chưa cài; cài bản ổn định mới nhất khi viết Edge Function đầu tiên (chủ dự án đồng ý 2026-10-22) | `deno test` theo Supabase docs "Unit test"; ghi phiên bản thật vào đây lúc cài | Supabase docs "functions/unit-test" |
| Docker | 29.2.1 | chạy Supabase local | Nhiệm vụ 1 |

## 3. Dịch vụ bên ngoài

| Dịch vụ | Dùng cho | Ghi chú | Nguồn |
|---|---|---|---|
| GitHub REST API | Danh sách repo công khai, ngôn ngữ, chủ đề, cây thư mục gốc, file khai báo thư viện, README (F-004, F-007, ALG-08) | Không xác thực: 60 lượt/giờ theo IP → dùng token server chỉ đọc dữ liệu công khai [GIẢ ĐỊNH]; `GET /users/{username}/repos` | GitHub docs "Rate limits for the REST API" (Context7 `/websites/github_en_rest`) |
| Host web tĩnh | W-01 (F-011) | **GitHub Pages** (ADR-0007) | — |

**Không dùng nhà cung cấp AI** (ADR-0010). Đã so sánh ngày 2026-10-22, giá mỗi triệu token gửi vào/nhận ra: Claude Haiku 5.5 0,10/0,50 USD; OpenAI gpt-6-luna 0,10/0,50 USD; Gemini 3.5 Flash-Lite bản trả phí 0,30/2,50 USD (bản miễn phí dùng dữ liệu để cải thiện sản phẩm). Tinh chỉnh model trên OpenAI không còn mở cho tài khoản mới; tự host trên Hugging Face Inference Endpoints từ 0,033 USD/giờ (CPU) hoặc 0,5 USD/giờ (GPU). Nguồn: trang giá chính thức của từng bên, Anthropic Privacy Center, OpenAI "Your data".

### 3.1 Ghi chú về độ lệch tài liệu

- Context7 `/supabase/supabase-flutter` lấy từ nhánh `main` của repo, trong đó có `MIGRATION.md` mô tả API **3.0** (`AuthAsyncStorage`, `asyncStorage:`). README của bản ổn định **2.18.3** trên pub.dev dùng `publishableKey:` và `LocalStorage` tùy biến với `FlutterAuthClientOptions(localStorage: …)`. Thiết kế theo **pub.dev 2.18.3** (tài liệu chính thức của bản sẽ dùng).
- `publishableKey` và khóa `anon` cũ: cùng vai trò khóa công khai; README 2.18.3 dùng tên tham số `publishableKey`.

## 4. Lịch sử

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| 0.1 | 2026-10-22 | Bản nháp đầu |
| 1.0 | 2026-10-22 | Đã thống nhất v1.0 |
