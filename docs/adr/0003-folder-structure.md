# ADR-0003 · Cấu trúc thư mục theo case study Flutter (rút gọn)

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 3) · 2026-10-22
- **Truy vết:** mọi F-xxx (mỗi tính năng có thư mục `ui/<feature>/`); NFR khả năng kiểm thử.

## Bối cảnh

Cần cấu trúc mà agent và người đều đoán được file nằm đâu, khớp ADR-0001.

## Phương án đã cân nhắc

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. Theo case study chính thức, rút gọn: `ui/` theo tính năng, `data/` theo lớp, không có lớp use-case** | Khớp tài liệu Flutter; ít tầng | Repository có thể to dần |
| B. Clean Architecture đủ tầng (domain/use-case/data) | Tách bạch | Nhiều file khuôn mẫu, chưa cần |
| C. Mọi thứ theo tính năng (`features/x/{data,ui}`) | Gọn từng tính năng | Repository dùng chung (hồ sơ, skill) không rõ chỗ |

## Quyết định

Chọn **A**. Cây thư mục chi tiết ở [TECH_DESIGN.md § Cấu trúc thư mục](../design/TECH_DESIGN.md#3-cấu-trúc-thư-mục-dự-kiến).
- Một điểm vào: `lib/main.dart`.
- `lib/config/`: đọc `SUPABASE_URL` và khóa công khai qua `--dart-define`.
- `lib/data/services/`: bọc Supabase, file cache, `shared_preferences`; `lib/data/repositories/`: logic dữ liệu cho ViewModel.
- `lib/ui/<feature>/`: `<feature>_screen.dart` + `<feature>_view_model.dart`.
- `test/` soi gương `lib/`, cộng `test/fakes/` và `test/fixtures/`.
- `supabase/functions/`: Edge Functions; `supabase/migrations/`, `supabase/tests/` giữ như harness.

## Hệ quả

- Thêm lớp use-case chỉ khi một logic được ≥ 2 ViewModel dùng lại và repository không phải nơi hợp lý; ghi bằng ADR mới.

## Nguồn

- Flutter docs, "Architecture case study" (Context7 `/flutter/website`), tra ngày 2026-10-22.
