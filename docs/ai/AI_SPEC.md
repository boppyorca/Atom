# Đặc tả phần phân tích

**Trạng thái:** Chủ dự án duyệt ngày 2026-10-25. Không thay ADR-0010.

Người soạn: Grok 4.7.

## Đang làm

- Một dịch vụ, hai cửa trong bản đầu.
- Cửa soát repo: gợi ý skill từ repo công khai đã chọn. Người dùng bấm Nhận hoặc Bỏ.
- Cửa so tin: dán một tin tuyển dụng, chỉ ra chỗ hồ sơ còn thiếu. Bấm Tự khai thì skill mới lên hồ sơ.
- Dành cho người đang làm hồ sơ xin việc trên Atom.
- 0 đồng. Không gửi chữ cho một hãng AI. Lương, email và phần liên hệ không đưa vào.
- Máy chỉ đề xuất. Hỏng thì một câu và nút Thử lại.

## Không làm trong bản đầu

- Ô chat, Gemini, ZCode.
- Tự ghi skill, gửi tin, nộp hồ sơ, mở trang lạ.

Ô chat vẫn là cửa thứ ba của dịch vụ, để sau. Token còn dư chưa dùng.

## Cách làm

Một danh sách skill dùng cho cả hai cửa. Mỗi skill có dấu hiệu: ngôn ngữ, tên thư viện, từ khóa.

Cửa soát repo đọc repo công khai đã chọn, tối đa 10. Thấy dấu thì đưa vào danh sách gợi ý. Cửa so tin tìm trong tin những skill có trong cùng danh sách, rồi so với hồ sơ. So tin chạy trên điện thoại. Chữ tin không sang server và không sang hãng AI.

## Cửa soát repo

Trên hồ sơ có nút **Tìm skill**. Việc chạy nền. Người dùng được rời màn hình. Mục tiêu dưới 2 phút.

Mỗi dòng gợi ý có một lý do ngắn: ngôn ngữ, tên thư viện, hoặc từ khóa, kèm repo tiêu biểu. **Nhận** thì skill lên hồ sơ, nhãn có bằng chứng. **Bỏ** thì dòng biến mất và không hiện lại cho đến khi bộ repo đã chọn đổi.

Không có gợi ý mới thì một câu: chưa thấy skill mới. GitHub không trả lời, repo mất, hoặc quá 2 phút thì một câu lỗi và **Thử lại**. Skill đã nhận từ trước vẫn giữ.

Chưa chọn repo thì không chạy. Một câu nói hãy chọn repo trước. Mất mạng thì “Không có kết nối” và Thử lại.

Skill đã có, đang tự khai, mà repo chỉ ra đúng skill đó: nút là **Gắn bằng chứng**. Bấm xong, nhãn đổi thành có bằng chứng. Không tạo dòng thứ hai.

## Cửa so tin

Một ô, một tin. Bấm **So**. Hai nhóm:

- Tin cần, hồ sơ đã có. Không có nút Tự khai.
- Tin cần, hồ sơ chưa có. **Tự khai** từng dòng. Nhãn là tự khai, không phải có bằng chứng.

Hồ sơ trống thì mọi skill nhận ra nằm ở nhóm chưa có. Không thấy skill nào trong tin thì một câu: chưa nhận ra skill trong tin này. Ô trống thì không so. Tin quá dài thì bảo rút ngắn. `[GIẢ ĐỊNH]` trần khoảng 8.000 chữ, không phải token.

Dán tin mới thì tin cũ bị thay. Không lưu kho tin. Mất mạng vẫn so được.

## Phần chung

Hai nhãn không trộn. Đủ 50 skill thì Nhận hoặc Tự khai không thêm được. Một câu nói đã đầy. Skill cũ không bị xóa.

`[GIẢ ĐỊNH]` Danh sách skill ban đầu khoảng 150 mục, lấy từ thiết kế cũ, chủ dự án chưa chốt lại con số. Danh sách nằm trên máy để cửa tin so được khi mất mạng.

`[GIẢ ĐỊNH]` Bỏ nhớ theo từng người và theo bộ repo đang chọn. Chưa chọn nhớ bao lâu nếu gỡ app.

`[CHƯA XÁC MINH]` Đọc 10 repo có kịp dưới 2 phút hay không. Chưa đo.

## Cách kiểm

Bộ ví dụ riêng, khoảng 20 đến 50 repo và tin. Chủ dự án tự ghi skill nào phải có và skill nào không được có. Lệnh chấm đứng riêng, không trộn vào lệnh kiểm tra app hàng ngày. Không sửa ví dụ hoặc đáp án để lần chấm trở thành đạt.

Cửa repo phải đúng: thấy skill vì thư viện hoặc ngôn ngữ, không thấy skill chỉ vì một câu lệnh lạ trong repo, repo không đọc được thì không có skill mới.

Cửa tin phải đúng: đã có và chưa có đúng nhóm, Tự khai thì nhãn tự khai.

Trên app phải có bài kiểm: chưa chọn repo, mất mạng, Bỏ rồi không hiện lại, đủ 50 skill, người khác không ghi skill hộ.

`[GIẢ ĐỊNH]` Bộ ví dụ do chủ dự án gắn nhãn trước khi coi cửa nào là xong. Chưa có repo mẫu.

## Nhật ký quyết định

- 2026-10-25: Bản đầu có hai cửa. Ô chat để sau. Token Gemini và ZCode chưa dùng. Bạn xác nhận “đúng”.
- 2026-10-25: Cách A. Một danh sách skill cho cả hai cửa. Bạn chọn.
- 2026-10-25: Cửa soát repo, bạn bảo ổn.
- 2026-10-25: Cửa so tin, bạn bảo ổn, kể cả nút Tự khai.
- 2026-10-25: Phần chung, bạn bảo ổn.
- 2026-10-25: Các tình huống dễ vỡ, bạn bảo ổn, kể cả ẩn sau khi Bỏ.
- 2026-10-25: Cách kiểm, bạn bảo ổn và chốt bản thiết kế.
- 2026-10-25: Bạn duyệt trang mô tả. Chưa bảo làm trong app.
