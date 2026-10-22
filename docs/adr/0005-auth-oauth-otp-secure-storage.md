# ADR-0005 · Đăng nhập: OAuth qua trình duyệt, mã email 6 số, phiên lưu trong Keychain/Keystore

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 5a + 5b) · 2026-10-22
- **Truy vết:** F-001, F-004 (nối GitHub cho người không đăng nhập bằng GitHub), F-002; NFR bảo mật (lưu token).

## Bối cảnh

F-001 cần 4 cách đăng nhập: email (mã 6 số, D-041), GitHub, Google, Apple (iOS). Phiên đăng nhập (access/refresh token) phải lưu an toàn trên máy.

## Phương án đã cân nhắc (5a: cách đăng nhập)

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. Mọi nhà cung cấp ngoài qua `signInWithOAuth` (mở trình duyệt); email qua `signInWithOtp` + `verifyOTP(type: OtpType.email)`** | Một luồng chung; không thêm SDK Google/Apple | Trải nghiệm Apple/Google kém "native" hơn |
| B. Google/Apple native (`signInWithIdToken`) + GitHub OAuth | Trải nghiệm tốt hơn | Thêm 2 package và cấu hình riêng từng nền tảng |

## Phương án đã cân nhắc (5b: nơi lưu phiên)

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. `flutter_secure_storage` qua `LocalStorage` tùy biến** | Token nằm trong Keychain (iOS) / Keystore (Android) | Thêm 1 package |
| B. Mặc định của `supabase_flutter` (`shared_preferences`) | Không thêm gì | Token nằm ở vùng lưu thường |

## Quyết định

Chọn **5a-A** và **5b-A**.
- Nối GitHub cho người đăng nhập bằng email/Google/Apple: `linkIdentity(OAuthProvider.github)`. Cần bật `enable_manual_linking = true` trong `supabase/config.toml` khi triển khai; đây là thay đổi cấu hình đăng nhập nên **phải hỏi chủ dự án trước** (AGENTS.md quy tắc 5).
- GitHub chỉ dùng để xác định tên người dùng GitHub; không dùng token GitHub của người dùng để đọc repo, nên không xin quyền `repo` (F-004). Đọc repo công khai do Edge Function làm (ADR-0006).
- Deep link quay về app: dạng `[SCHEME]://[HOST]` (ví dụ `com.example.harnessapp://login-callback` [GIẢ ĐỊNH]), khai báo trong Additional Redirect URLs. `supabase_flutter` tự xử lý deep link bằng `app_links` có sẵn bên trong, không cần thêm package.
- Lưu phiên: lớp `SecureSessionStorage extends LocalStorage` dùng `FlutterSecureStorage`, truyền vào `FlutterAuthClientOptions(localStorage: …)`. Đây là API của `supabase_flutter` **2.x**; bản 3.0 (đang prerelease) đổi sang `AuthAsyncStorage`. Ta dùng bản ổn định 2.18.3 (xem DEPENDENCIES.md).
- Đăng xuất: `signOut()`; sau đó xóa cache hồ sơ (ADR-0004).

## Hệ quả và điểm chưa chắc

- **Đã đối chiếu (2026-10-22)** App Review Guidelines 4.8 "Login Services" hiện hành: app có đăng nhập bên thứ ba phải có thêm **một dịch vụ đăng nhập tương đương** chỉ thu tên và email, cho phép ẩn email, không thu tương tác để quảng cáo khi chưa đồng ý. Văn bản không yêu cầu đăng nhập phải "native", nên Sign in with Apple qua trình duyệt đáp ứng. Rủi ro còn lại là đánh giá của người duyệt (R-005); nếu bị từ chối, chuyển riêng Apple sang native (5a-B) bằng ADR mới. Ghi chú: A-002 viết "bắt buộc Sign in with Apple"; thực tế là "bắt buộc một lựa chọn tương đương" mà Sign in with Apple đáp ứng.
- Quyền (scope) mặc định Supabase xin khi đăng nhập GitHub: tài liệu Supabase không ghi rõ. App **không** dùng token GitHub của người dùng; quyền đọc repo riêng tư (`repo`) chỉ có khi được xin rõ ràng. Tiêu chí F-004 được kiểm bằng bước thủ công: xem màn hình đồng ý của GitHub ở môi trường thử, không được có quyền `repo` (TRACEABILITY, F-004). Nếu có, truyền `scopes` tối thiểu khi gọi `signInWithOAuth`.
- Trình duyệt không tự đóng sau đăng nhập (gói tùy chọn `supabase_flutter_web_auth` mới làm được việc này); chấp nhận ở MVP.

## Nguồn

- pub.dev `supabase_flutter` 2.18.3: "Custom LocalStorage", deep link config, `signInWithOAuth`, tra ngày 2026-10-22.
- Context7 `/supabase/supabase-flutter`: `signInWithOtp`, `verifyOTP`, `linkIdentity`; README `supabase_flutter_web_auth` (tùy chọn). Lưu ý: Context7 lấy từ nhánh `main` (gần bản 3.0) nên phần lưu phiên (`AuthAsyncStorage`) **không** khớp bản 2.18.3; đã ưu tiên trang pub.dev chính thức.
- `flutter_secure_storage` 11.2.0, pub.dev (Android tối thiểu SDK 23), tra ngày 2026-10-22.
- `supabase/config.toml` local: `otp_length = 6`, `otp_expiry = 3600`, `enable_manual_linking = false`.
