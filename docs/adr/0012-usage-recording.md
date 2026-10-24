# ADR-0012 · Ghi số lần dùng và hạn mức

- **Trạng thái:** Proposed (Draft). Chưa được chấp nhận.
- **Ngày:** 2026-10-23.
- **Người soạn:** Grok 4.7.

## Bối cảnh

Nếu có hạn mức theo người, hai lần bấm cùng lúc không được lọt cả hai. Cần một bước giữ chỗ. `service_role` bỏ qua RLS. Không đưa khóa đó vào app.

## Phương án

| | Cách ghi | Đánh đổi |
|---|---|---|
| A. Bảng thường, app tự cộng | Người dùng chỉ ghi dòng của mình nhờ RLS | Hai yêu cầu cùng lúc có thể cùng đọc “còn 1 lượt” rồi cùng ghi |
| B. Một hàm SQL `security definer`, `search_path` cố định, chỉ cộng cho `auth.uid()` | Một câu lệnh giữ chỗ. Hàm không dùng `service_role`. Edge Function gọi bằng JWT của người dùng | Phải viết hàm thật cẩn thận. Đây là thay đổi RLS, phải được bạn duyệt trước khi làm |
| C. Edge Function dùng `service_role` để ghi hộ | Viết tự do phía server | Khóa bỏ qua RLS nằm trong hàm. Chỉ đáng xét khi B không làm được bước giữ chỗ |

## Khuyến nghị

B, nếu bạn muốn hạn mức. Số lần mỗi tháng vẫn `[MỞ]`. Đường 0 đồng hiện tại có thể chưa cần bảng này.

## Cổng

Bạn chọn A, B, hoặc C, và con số lần mỗi tháng, trước ticket có migration.
