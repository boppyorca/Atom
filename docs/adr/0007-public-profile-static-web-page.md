# ADR-0007 · Trang hồ sơ công khai: một trang web tĩnh gọi RPC

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 6b) · 2026-10-22
- **Truy vết:** F-011, F-013 (hồ sơ bị gỡ không xem được), F-002 (đã xóa → "không tồn tại"), F-017/D-033 (ngôn ngữ trang).

## Bối cảnh

Nhà tuyển dụng mở link trên trình duyệt, không cài app, không đăng nhập. Bản web đầy đủ là Won't.

## Phương án đã cân nhắc

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. Một trang HTML/CSS/JS thuần trên host tĩnh miễn phí, gọi RPC `get_public_profile` bằng khóa công khai** | Không build; chi phí 0; dùng chung RPC với app | Nội dung tải bằng JS (SEO kém, không cần cho MVP) |
| B. Edge Function trả HTML | Một chỗ | Supabase đổi phản hồi `text/html` của GET thành `text/plain` nếu không có tên miền riêng → không dùng được |
| C. Flutter Web | Dùng lại mã | Nặng, chậm mở trên điện thoại; gần với "bản web đầy đủ" (Won't) |

## Quyết định

Chọn **A**.
- Đường dẫn: `https://<host>/p/?id=<profile_id>` (tham số query vì host tĩnh không tự định tuyến `/u/:id`) [GIẢ ĐỊNH].
- Ngôn ngữ: `navigator.language` bắt đầu bằng `vi` → tiếng Việt, ngược lại tiếng Anh; có nút đổi Việt/Anh. Nội dung chủ hồ sơ viết hiển thị nguyên văn.
- RPC trả rỗng khi hồ sơ riêng tư, bị gỡ hoặc không tồn tại → trang hiện "Hồ sơ không tồn tại", không phân biệt ba trường hợp.
- Chặn (F-013) chỉ áp dụng trong app; trang web không biết ai đang xem.
- Mã trang nằm trong repo ở `web/public_profile/` [GIẢ ĐỊNH]; không thêm công cụ build.

## Hệ quả

- Host: **GitHub Pages** (chủ dự án chọn 2026-10-22). Tên miền gốc dạng `https://<tài khoản>.github.io/<repo>/` [GIẢ ĐỊNH: chưa dùng tên miền riêng]; app đọc tên miền gốc từ `--dart-define` `PUBLIC_PROFILE_BASE_URL`.
- Khóa công khai (publishable/anon) nằm trong trang là đúng thiết kế; an toàn nhờ RLS và RPC chỉ trả dữ liệu công khai. Không bao giờ đưa khóa service_role.

## Nguồn

- Supabase docs, Edge Functions "Limits" (giới hạn phản hồi HTML), Context7 `/websites/supabase`, tra ngày 2026-10-22.
