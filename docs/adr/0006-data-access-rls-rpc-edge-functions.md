# ADR-0006 · Truy cập dữ liệu: REST + RLS, RPC và Edge Functions

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 6) · 2026-10-22
- **Truy vết:** F-002, F-003, F-004, F-005, F-006, F-007, F-008, F-010, F-011, F-012, F-013, F-014, F-015, F-018.

## Bối cảnh

Phần lớn thao tác là sửa dữ liệu của chính mình. Một số quy tắc không được để app tự kiểm: ngưỡng lương 5 khoản, giới hạn 10 lượt xác nhận/tháng, chỉ hiện hồ sơ công khai, hạn mức AI, xóa tài khoản (cần khóa service_role).

## Phương án đã cân nhắc

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. Lai: REST tự sinh + RLS cho dữ liệu của mình; RPC (hàm Postgres) cho quy tắc chéo người dùng; Edge Functions cho việc cần bí mật/gọi ra ngoài** | Ít mã server; quy tắc nằm ở CSDL, test bằng pgTAP | Ba kiểu gọi khác nhau |
| B. Mọi thứ qua Edge Functions | Một kiểu gọi | Nhiều mã server; khó test hơn |
| C. Mọi thứ qua REST + RLS | Ít khái niệm | Không làm được ngưỡng lương, hạn mức, xóa tài khoản an toàn |

## Quyết định

Chọn **A**. Hợp đồng chi tiết ở [API_CONTRACT.md](../design/API_CONTRACT.md), bảng và RLS ở [DATA_MODEL.md](../design/DATA_MODEL.md).
- **REST + RLS** (chỉ dữ liệu của chính mình): hồ sơ, link bằng chứng, skill tự khai, gắn bằng chứng vào skill, đồng ý AI, khoản lương, báo cáo, chặn, đọc trạng thái lượt AI.
- **RPC:** `get_public_profile`, `search_profiles`, `endorse_skill`, `get_salary_aggregate`, `connect_github`, `review_suggestion`, `get_ai_quota`.
- **Edge Functions:** `github-repos`, `extract-skills`, `analyze-gap`, `delete-account`. Hạn mức lượt được kiểm **bên trong** `extract-skills` và `analyze-gap` (xử lý bằng bộ quy tắc tự xây, ADR-0010).
- Người khác không bao giờ đọc thẳng bảng của mình; mọi thao tác đọc chéo người dùng đi qua RPC `security definer` có lọc.

## Hệ quả và điểm chưa chắc

- Test RLS và RPC bằng pgTAP trong `make check-db`.
- Test Edge Functions: tài liệu Supabase dùng `deno test`; máy hiện chưa có Deno. **Chủ dự án đã đồng ý (2026-10-22)** cài Deno và thêm `make check-functions` khi bắt đầu viết Edge Function đầu tiên (không làm trước).
- GitHub giới hạn 60 lượt/giờ cho truy vấn không xác thực, tính theo IP; Edge Functions chạy trên IP dùng chung → cần một token GitHub phía server chỉ đọc dữ liệu công khai, lưu dạng secret của Edge Function, không bao giờ đưa vào repo [GIẢ ĐỊNH].

## Nguồn

- Supabase docs: Database Functions, RLS, Edge Functions "Limits", "Background Tasks", "Unit test" (Context7 `/websites/supabase`), tra ngày 2026-10-22.
- GitHub docs "Rate limits for the REST API" (Context7 `/websites/github_en_rest`), tra ngày 2026-10-22.
