# ADR-0009 · Danh sách package và module gọi AI

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 8a + 8b) · 2026-10-22. **Phần 8b bị thay thế bởi [ADR-0010](0010-in-house-rule-based-skill-extraction.md)**; phần 8a còn hiệu lực.
- **Truy vết:** 8a: toàn bộ app; 8b: F-006, F-007, F-014, F-018.

## Bối cảnh

Nguyên tắc: đơn giản nhất cho MVP, không thêm thư viện "phòng khi cần". Nhà cung cấp AI chưa chọn.

## Quyết định 8a · Package

Chỉ dùng: `supabase_flutter`, `provider`, `go_router`, `flutter_secure_storage`, `path_provider`, `shared_preferences`, `flutter_localizations` (SDK) + `intl`, `url_launcher`. Phiên bản, lý do và phương án bị loại ở [DEPENDENCIES.md](../design/DEPENDENCIES.md).

Không thêm: package mock, `connectivity_plus`, `share_plus` (dùng `Clipboard` để chép link), analytics, package sinh mã. `flutter_web_auth_2` / `supabase_flutter_web_auth` chỉ thêm nếu bắt buộc; hiện **không** bắt buộc (ADR-0005).

Việc thêm package vào `pubspec.yaml` vẫn phải hỏi chủ dự án ở thời điểm triển khai (AGENTS.md quy tắc 5).

## Quyết định 8b · Module gọi AI

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. Chưa chọn nhà cung cấp; một module `supabase/functions/_shared/ai_client.ts` gọi bằng `fetch`, yêu cầu trả JSON có cấu trúc, ghi số token để tính chi phí** | Đổi nhà cung cấp chỉ sửa một file; không SDK | Tự viết phần parse/kiểm JSON |
| B. Chọn ngay một nhà cung cấp + SDK | Nhanh | Khóa sớm khi chưa so giá |

Chọn **A**. `ai_client.ts` lộ ra một hàm duy nhất `generateJson({ system, user, schema, timeoutMs })` trả `{ data, inputTokens, outputTokens }`. Giá theo token lưu ở `app_settings` để tính chi phí (F-018).

## Kết quả

- Ngày 2026-10-22 chủ dự án chọn **không dùng nhà cung cấp AI**; thay bằng bộ quy tắc tự xây (ADR-0010). Module `ai_client.ts` không còn trong thiết kế.

## Nguồn

- pub.dev từng package (xem DEPENDENCIES.md), tra ngày 2026-10-22.
