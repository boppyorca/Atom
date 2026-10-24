# Mối nguy — Bản nháp

**Trạng thái: Draft.** Ngày 2026-10-23. Người soạn: Grok 4.7. Không phải tư vấn pháp lý.

“Có” = được phép. “Không” = không được phép.

| Năng lực | Có / Không | Giảm thiểu |
|---|---|---|
| Dữ liệu riêng: lương, email, liên hệ vào bước đọc | Không | Không nằm trong đầu vào đã chốt. |
| Tên hiển thị vào bước đọc | [MỞ] | [GIẢ ĐỊNH] Không đưa. |
| Nội dung không tin cậy: chữ trong repo công khai | Có, chỉ để so dấu hiệu | Không coi chữ đó là lệnh. `[CHƯA XÁC MINH]` Chưa có bài thử. |
| Giao tiếp ra ngoài: đọc repo đã chọn trên GitHub | Có | Chỉ repo công khai đã chọn, tối đa 10. |
| Giao tiếp ra ngoài: gửi chữ cho một hãng AI | Không, theo lựa chọn hiện tại | ADR-0010 đang chấp nhận bộ từ khóa, 0 đồng. Muốn bật phải có ADR mới và câu đồng ý mới. |
| Gọi địa chỉ web tìm thấy trong repo | Không | `[CHƯA XÁC MINH]` Chưa có hàm đọc. |
| Tự ghi hồ sơ, gửi tin, mở trang lạ | Không | Chỉ ghi skill sau khi người dùng bấm chấp nhận. |
| Prompt injection (câu lệnh lừa nằm trong repo) | Không được làm theo | Ba lớp ở mục dưới. Lớp “chặn 95%” không thay được việc tách ba năng lực. |
| Lạm dụng chi phí | Không tiêu tiền ở đường hiện tại | Nếu sau này gọi API tính token: trần lần bấm, một bước giữ chỗ, ghi số token. `[MỞ]` con số. |
| Rò khóa API | Không có khóa hãng AI trong app hôm nay | Nếu có sau này: chỉ trong secret trên server, tên không bắt đầu bằng `SUPABASE_`. Không đưa vào app. `.cursorignore` hiện chưa có — xem READINESS. |
| Đầu vào quá lớn | [MỞ] trần | `[GIẢ ĐỊNH]` Cần trần độ dài trước khi gọi. Chưa chọn số. |

## Ba thứ không được đứng cùng nhau

1. Dữ liệu riêng.
2. Chữ không đáng tin.
3. Đường gọi hoặc ghi ra ngoài.

Đường tìm skill hiện tách chúng: dữ liệu riêng không vào bước đọc; chữ repo không phải lệnh; đường ra ngoài chỉ là GitHub để đọc repo đã chọn; không tự ghi skill.

Nếu bật gọi hãng AI mà vẫn đọc repo và vẫn giữ lương trong cùng một phiên, ba thứ gặp lại nhau. Khi đó phải bỏ tổ hợp đó, hoặc người dùng xác nhận từng hành động ghi. `[GIẢ ĐỊNH]` khuyến nghị: không bật tổ hợp đó.

`[CHƯA XÁC MINH]` Chưa có bài thử repo cố tình viết câu lệnh lừa, vì hàm đọc chưa tồn tại.
