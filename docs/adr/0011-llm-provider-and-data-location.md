# ADR-0011 · Nhà cung cấp mô hình và nơi xử lý dữ liệu

- **Trạng thái:** Proposed (Draft). Chưa được chấp nhận. Không thay ADR-0010.
- **Ngày:** 2026-10-23.
- **Người soạn:** Grok 4.7.

## Bối cảnh

ADR-0010 (Accepted, 2026-10-22) chọn bộ từ khóa, 0 đồng, không gửi dữ liệu cho hãng AI. Buổi hỏi 2026-10-23 chọn cùng hướng cho việc tìm skill. Bối cảnh nghiên cứu sau đó hỏi độ sẵn sàng của một đường khác: app gọi Supabase Edge Function, hàm gọi API mô hình, khóa chỉ ở server.

Hai đường mâu thuẫn ở chỗ chữ trên màn đồng ý hiện nói không gửi cho công ty AI.

## Phương án

| | Việc xảy ra | Đánh đổi |
|---|---|---|
| A. Giữ ADR-0010 | Server đọc GitHub, so từ khóa. Không khóa hãng AI | Không tốn tiền theo token. Không gửi nội dung cho hãng AI. Chất lượng phụ thuộc danh sách dấu hiệu |
| B. API một hãng, khóa trên server | Điện thoại không giữ khóa. Nội dung đã chọn rời tới hãng đó | Phải sửa màn đồng ý, khai báo store, trả tiền, viết ADR chấp nhận thay một phần ADR-0010 |
| C. Chạy mô hình mở trên máy bạn hoặc máy bạn thuê | Nội dung không tới hãng mô hình | Máy phải đủ mạnh hoặc có hóa đơn GPU. Giá GPU `[CHƯA XÁC MINH]` |

## Bổ sung 2026-10-25

Bạn muốn thêm ô chat, 8.000 token mỗi lần, chữ ở lại máy, ưu tiên 0 đồng, và kể còn token Gemini hoặc ZCode. “zihu” chưa khớp một sản phẩm đã đọc. ZCode trên [zcode.z.ai](https://zcode.z.ai/en/docs/usage-stats) đọc hạn mức từ Z.ai, tức chữ đi tới máy chủ của họ. Gemini API miễn phí, theo [điều khoản](https://ai.google.dev/gemini-api/terms), Google được dùng nội dung bạn gửi để cải thiện sản phẩm, và người duyệt có thể đọc. Đó không phải “ở lại máy”.

## Khuyến nghị

Tìm skill: giữ A. Ô chat: chưa chọn. Ba cách nằm trong [AI_SPEC.md](../ai/AI_SPEC.md). Khuyến nghị cách tách: chat chỉ chạy trên máy hoặc hoãn. Không gắn token Gemini/ZCode vào app chừng nào “ở lại máy” còn là yêu cầu.

## Cổng

Bạn duyệt A, B, hoặc C. Chưa duyệt thì không làm ticket gọi API mô hình.
