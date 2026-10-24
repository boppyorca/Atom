# ADR-0013 · Công cụ kiểm tra Edge Function

- **Trạng thái:** Proposed (Draft). Chưa được chấp nhận. Không cài gì trong bản này.
- **Ngày:** 2026-10-23.
- **Người soạn:** Grok 4.7.

## Bối cảnh

Máy này không có lệnh `deno` (`command not found`, 2026-10-23). `supabase/config.toml` dòng 393 ghi `deno_version = 2` cho runtime local của Supabase CLI. Chưa có thư mục `supabase/functions/`. `[CHƯA XÁC MINH]` CLI đã kèm sẵn lệnh `deno test` hay chưa. Buổi này không chạy thử cài.

## Phương án

| | Việc làm | Đánh đổi |
|---|---|---|
| A. Cài Deno trên máy | Chạy `deno test` cho hàm | Thêm công cụ. Cần bạn đồng ý trước khi cài |
| B. Chỉ dùng Supabase CLI đã có (`supabase functions serve`) | Không cài thêm. Phần xác thực, hạn mức, parse, lỗi viết bằng test Dart với máy chủ giả, cộng pgTAP cho bảng hạn mức | Chưa chứng minh CLI chạy được bộ test kiểu Deno |
| C. Chưa viết hàm cho đến khi A hoặc B được duyệt | Không có bề mặt mới để lỗi | Chậm hơn nếu bạn đã muốn gọi mô hình |

## Khuyến nghị

C cho đến khi bạn chọn A hoặc B. Nếu chỉ tiếp tục bộ từ khóa, chưa cần A.

## Cổng

Bạn chọn A, B, hoặc C.
