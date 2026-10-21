# Bối cảnh sử dụng

> v1.0 (Đã thống nhất) · 2026-10-22 · Xem tổng quan tại [SPEC.md](SPEC.md)

## Persona

**Minh, sinh viên năm cuối ngành CNTT, TP.HCM** [GIẢ ĐỊNH: persona minh họa, chưa phỏng vấn người dùng thật]
- Có 6–10 repo GitHub công khai (đồ án, side project), vài bài viết kỹ thuật.
- Đang tìm vị trí intern/fresher; chưa biết mức lương hợp lý; dùng điện thoại là chính.

**Lan, junior developer 1,5 năm, Hà Nội** [GIẢ ĐỊNH: persona minh họa]
- Muốn chuyển việc lên middle, cần biết mình thiếu gì và lương thị trường ra sao.
- Code ở công ty nằm trong repo riêng tư nên chỉ có vài repo cá nhân công khai.

## Kịch bản sử dụng

### KB-1: Tạo hồ sơ có bằng chứng (F-001, F-003, F-004, F-005, F-006, F-007)
1. Minh cài app, đăng nhập bằng GitHub.
2. App hỏi đồng ý cho AI đọc repo công khai và link; Minh đồng ý.
3. Minh dán thêm 2 link bài viết và 1 link sản phẩm đã ship.
4. Bấm "Phân tích", thoát app đi làm việc khác.
5. Quay lại, thấy dấu báo "Có skill chờ duyệt"; Minh giữ 5 skill, bỏ 1 skill AI gán nhầm.
6. Các skill đã duyệt hiện mức "có bằng chứng", kèm nguồn.

### KB-2: Chia sẻ hồ sơ khi ứng tuyển (F-011)
1. Minh bật "Công khai hồ sơ".
2. Sao chép link hồ sơ, dán vào email ứng tuyển.
3. Nhà tuyển dụng mở link trên máy tính, không cần cài app hay đăng nhập, xem skill và bấm vào bằng chứng.
4. Minh đã bật mục liên hệ (email), nên nhà tuyển dụng liên hệ trực tiếp từ trang hồ sơ.

### KB-3: Xác nhận skill cho bạn (F-012, F-010)
1. Lan tìm hồ sơ của một đồng nghiệp cũ theo skill "Flutter".
2. Lan đã có "Flutter" ở mức "có bằng chứng" nên nút "Xác nhận" hiện ra; Lan bấm xác nhận.
3. Skill đó của đồng nghiệp chuyển lên mức "được xác nhận".

### KB-4: Phân tích khoảng cách với job mục tiêu (F-014)
1. Lan dán mô tả job "Middle Flutter Developer".
2. AI so với hồ sơ, liệt kê skill đã có, skill còn thiếu, gợi ý việc nên làm cho từng skill thiếu.
3. Kết quả chỉ Lan xem được.

### KB-5: Tra lương ẩn danh (F-015)
1. Lan mở mục Lương, app yêu cầu góp lương trước.
2. Lan khai lương hiện tại: vai trò, thành phố, cấp bậc, lương gộp mỗi tháng (VND).
3. Lan xem khoảng lương của "Flutter Developer, Hà Nội, middle"; nếu nhóm chưa đủ người, app ghi "chưa đủ dữ liệu".

## Thiết bị, mạng, ngôn ngữ

- Thiết bị: điện thoại iOS và Android, màn hình dọc. Tối thiểu iOS 15.0 và Android 7.0 (API 24), theo mặc định của Flutter 3.47.
- Trang hồ sơ công khai: mở được trên trình duyệt máy tính và điện thoại.
- Mạng: cần mạng cho hầu hết thao tác; khi mất mạng vẫn đọc được hồ sơ của mình và hồ sơ đã xem.
- Ngôn ngữ giao diện: tiếng Việt và tiếng Anh. Nội dung người dùng tự viết hiển thị nguyên văn, không tự dịch [GIẢ ĐỊNH].
- Tần suất: theo dịp (tìm việc, chuẩn bị phỏng vấn, vừa ship dự án), cộng thêm vài lần mỗi tuần.

## Ràng buộc môi trường

- Ngân sách gần như bằng 0; chi phí AI có trần mỗi tháng (20 USD/tháng khi thử nghiệm kín).
- Dữ liệu cá nhân theo Nghị định 13/2023/NĐ-CP [GIẢ ĐỊNH: là khung pháp lý áp dụng, cần kiểm chứng].
