# ADR-0008 · Model dữ liệu: Dart viết tay, TypeScript sinh từ schema

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 7) · 2026-10-22
- **Truy vết:** mọi bảng/RPC trong DATA_MODEL.md và API_CONTRACT.md; NFR khả năng kiểm thử.

## Bối cảnh

Khoảng 15 bảng và 7 RPC. Supabase CLI sinh kiểu cho `typescript | go | swift | python`, **không** có Dart.

## Phương án đã cân nhắc

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. Dart viết tay, bất biến (`final`, `const` constructor, `fromJson`/`toJson`) + test bằng file JSON mẫu** | Không sinh mã, không thêm package | Phải tự giữ khớp với schema |
| B. `freezed` + `json_serializable` | Ít mã tay, có `copyWith` | Thêm package và `build_runner` |
| C. Dùng `Map<String, dynamic>` trực tiếp | Nhanh lúc đầu | Lỗi kiểu khi chạy; trái `strict-casts` |

## Quyết định

Chọn **A**.
- Model ở `lib/domain/models/`; enum Dart khớp enum Postgres (ví dụ `SkillConfidence.selfClaimed` ↔ `'self_claimed'`).
- Mỗi model có test đọc file `test/fixtures/<model>.json` (lấy từ phản hồi thật của Supabase local) và so `toJson` ngược lại.
- Edge Functions dùng `supabase gen types --lang typescript --local` → `supabase/functions/_shared/database.types.ts`.

## Hệ quả

- Khi đổi migration phải cập nhật model + fixture cùng commit; test fixture bắt lệch.

## Nguồn

- Supabase CLI reference `gen types` (Context7 `/websites/supabase`), tra ngày 2026-10-22.
