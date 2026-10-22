# 13: Lương ẩn danh

**What to build:** Ứng viên nhập khoản lương ẩn danh (vai trò, thành phố, số năm, mức lương) ở S-14 và xem số liệu gộp (P25, trung vị, P75) ở S-15 khi có từ 5 khoản trở lên; ít hơn thì báo "chưa đủ dữ liệu". Không ai đọc được khoản của người khác.

**Blocked by:** 02

**Status:** ready-for-agent

Thiết kế: F-015, S-14, S-15; DATA_MODEL `salary_entries`, `salary_roles`, `cities`; API_CONTRACT `get_salary_aggregate`; ALG-07.

- [ ] 4 trường bắt buộc; trùng khoản bị chặn; không đọc được khoản người khác (pgTAP)
- [ ] `get_salary_aggregate` đạt 5 test mẫu ALG-07, không trả số khoản, làm tròn (pgTAP)
- [ ] Danh sách vai trò/thành phố lấy từ seed (DATA_MODEL § 4.10)
- [ ] S-15 hiện "chưa đủ dữ liệu" khi < 5 khoản (test ViewModel)
- [ ] S-14, S-15 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
