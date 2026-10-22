# 15: Phân tích tự động gợi ý skill + duyệt + giới hạn lượt

**What to build:** Ứng viên đã đồng ý bấm "Phân tích" (S-09). Việc chạy nền đọc repo GitHub đã chọn và link bằng chứng, dùng từ điển skill để gợi ý skill. App hiện trạng thái (đang chạy / xong / lỗi / hết giờ), có Thử lại. Ứng viên chấp nhận hoặc bỏ từng gợi ý; chấp nhận → skill lên hồ sơ kèm bằng chứng. Mỗi tháng có hạn mức lượt; hết lượt báo ngày làm mới.

**Blocked by:** 06, 14

**Cần chủ dự án trước:** duyệt từ điển skill ban đầu (ADR-0010). Có thể chia đôi khi bắt đầu (ví dụ: chạy job + hạn mức / duyệt gợi ý).

**Status:** ready-for-agent

Thiết kế: F-019 (tiếp cận), F-007, F-018, S-03, S-09; DATA_MODEL `ai_jobs`, `skill_suggestions`, `app_settings`; API_CONTRACT `extract-skills`, `review_suggestion`, `get_ai_quota`; ALG-03, ALG-05, ALG-08; NFR-02, NFR-07, NFR-09.

- [ ] `extract-skills` từ chối khi chưa đồng ý (403) hoặc hết lượt (429) (`deno test`)
- [ ] ALG-08 đạt 5 test mẫu; từ điển skill hợp lệ (`deno test`)
- [ ] Đầu vào phân tích không có lương/email/liên hệ/tên; chỉ gọi `api.github.com` và URL link người dùng (`deno test`)
- [ ] ALG-05 đạt 5 test mẫu: lượt lỗi/hết giờ không tính, đổi `app_settings` có hiệu lực ngay (pgTAP + `deno test`)
- [ ] `review_suggestion` chấp nhận/bỏ đúng, không duyệt lại được (pgTAP)
- [ ] App hiện `timed_out` khi quá `deadline_at`; dấu báo kết quả mới theo `seen_at` (test ViewModel)
- [ ] S-09 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check`, `make check-db`, `make check-functions` xanh
