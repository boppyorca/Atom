# 16: So khoảng cách với job mục tiêu

**What to build:** Ứng viên dán mô tả job (S-10). Phân tích chạy nền, so với skill trên hồ sơ và trả: skill đã có, skill còn thiếu. Không nhận ra skill nào → báo "Chưa nhận ra skill nào trong mô tả job". Dùng chung hạn mức lượt với ticket 15.

**Blocked by:** 15

**Status:** claimed

## Comments

- 2026-10-28: So tin tuyển dụng bằng từ điển. Không lưu nội dung tin. 6 bài Deno đạt, gồm 5 mẫu ALG-09. Bài dữ liệu: không có skill thì từ chối, người khác không đọc được kết quả. App hiện đang chạy, xong, lỗi, hết lượt.

Thiết kế: F-019 (tiếp cận), F-014, F-018, S-10; API_CONTRACT `analyze-gap`, `get_ai_quota`; ALG-05, ALG-09.

- [ ] `analyze-gap` đạt 5 test mẫu ALG-09, gồm `no_known_skills` (`deno test`)
- [ ] Chỉ chủ đọc được kết quả job (pgTAP)
- [ ] Không log nội dung mô tả job (rà code + test nếu khả thi)
- [ ] S-10 hiện trạng thái chạy/xong/lỗi/hết lượt (test ViewModel)
- [ ] S-10 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check`, `make check-db`, `make check-functions` xanh
