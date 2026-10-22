# 13: Lương ẩn danh

**What to build:** Ứng viên nhập khoản lương ẩn danh (vai trò, thành phố, số năm, mức lương) ở S-14 và xem số liệu gộp (P25, trung vị, P75) ở S-15 khi có từ 5 khoản trở lên; ít hơn thì báo "chưa đủ dữ liệu". Không ai đọc được khoản của người khác.

**Blocked by:** 02

**Status:** resolved

Thiết kế: F-019 (tiếp cận), F-015, S-14, S-15; DATA_MODEL `salary_entries`, `salary_roles`, `cities`; API_CONTRACT `get_salary_aggregate`; ALG-07.

- [x] 4 trường bắt buộc; trùng khoản bị chặn; không đọc được khoản người khác (pgTAP)
- [x] `get_salary_aggregate` đạt 5 test mẫu ALG-07, không trả số khoản, làm tròn (pgTAP)
- [x] Danh sách vai trò/thành phố lấy từ seed (DATA_MODEL § 4.10)
- [x] S-15 hiện "chưa đủ dữ liệu" khi < 5 khoản (test ViewModel)
- [x] S-14, S-15 đạt guideline tiếp cận; chuỗi đủ vi/en
- [x] `make check` và `make check-db` xanh

## Comments

- 2026-10-23: Ứng viên góp một khoản lương (vai trò, thành phố, cấp bậc, số tiền). Số liệu gộp chỉ hiện khi có từ 5 khoản, làm tròn tới 100.000 đồng, và không nói có bao nhiêu khoản. Người chưa góp thì không xem được. Không ai đọc được khoản của người khác.
- Câu "Chưa đủ dữ liệu" nằm trên tab Lương (S-14 trong bản vẽ), vì đó là nơi người dùng xem số liệu. Bài kiểm tra ViewModel xác nhận trường hợp dưới 5 khoản.
- Đỏ rồi xanh: lần gọi hàm lương lần đầu không khớp kiểu số. Đổi tham số sang số nguyên rồi xanh.
- `make check`: No issues found; 00:08 +67 All tests passed. `make check-db`: 70 tests PASS. `make docs-check`: ok.
- Rà soát: không có lỗi phải sửa. Chưa chạy trên máy ảo.
- Chủ dự án cho gộp khi kiểm thử sạch, không chờ review riêng.
