# Kế hoạch chấm — Bản nháp

**Trạng thái: Draft.** Ngày 2026-10-23. Người soạn: Grok 4.7.

Chưa tạo thư mục `evals/`. Chưa thêm lệnh `make eval`. Cần bạn duyệt trước.

## Bộ ví dụ

20–50 repo thật lúc đầu. Bạn gắn nhãn tay. Không giao hết cho một chương trình khác.

Mỗi ví dụ, đề xuất:

- tên repo công khai đã chọn
- skill nào phải xuất hiện
- skill nào không được xuất hiện
- ghi chú lỗi khi đọc kết quả (thiếu, thừa, nhầm nguồn)

`[MỞ]` Bạn có sẵn repo mẫu nào không.

Định dạng file: `[MỞ]`. Khuyến nghị một file chữ cho mỗi ví dụ, dễ đọc, không cần công cụ mới. Chưa tạo file.

## Lệnh chấm

`make eval` đứng riêng. Không đưa vào `make check`. `make check` chạy mỗi lần sửa app và không được tốn tiền hay chờ mạng.

Luật: không sửa ví dụ và không sửa đáp án mong đợi để lần chấm trở thành đạt. Sửa sản phẩm hoặc thêm ví dụ mới thì được. Ví dụ mới phải do người đọc lỗi quyết định, không phải để né một ca đang đỏ.

## Cách chấm đường hiện tại

Đường bộ từ khóa: so danh sách gợi ý với nhãn của bạn.

- Thiếu skill bạn đã ghi là đúng.
- Thừa skill bạn đã ghi là sai.
- Không cần một mô hình thứ hai để chấm. `[GIẢ ĐỊNH]` khuyến nghị. Nếu sau này dùng mô hình làm giám khảo, phải đối chiếu với nhãn của bạn trước. Chưa làm.

## Mỗi tuần

Đọc các lần người dùng bỏ gợi ý, hoặc chấp nhận rồi thấy nhầm. Ghi thành ví dụ mới. Chạy lại `make eval` trước khi tin một lần sửa danh sách dấu hiệu.

Nếu sau này đổi mô hình, chạy lại cả bộ trước khi tin. Kể cả đổi sang một bản rẻ hơn.

## Khi nào nâng mức

- Lỗi chủ yếu là “danh sách dấu hiệu không có skill này”: sửa từ khóa, ở lại workflow.
- Lỗi chủ yếu là “thiếu chữ không nằm trong repo đã chọn”: khi đó mới xét RAG. `[MỞ]` ngưỡng.
- Lỗi chủ yếu là “sai thứ tự nhiều bước không viết cứng được”: khi đó mới xét agent. Bạn hiện đang cấm hướng này.

Điểm “không tệ hơn đường cơ sở” là tiêu chí của ticket sau. Đường cơ sở đề xuất là bộ từ khóa, không phải một mô hình mạnh của hãng. `[MỞ]` cho đến khi bạn duyệt.
