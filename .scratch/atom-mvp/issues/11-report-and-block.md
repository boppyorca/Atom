# 11: Báo cáo và chặn

**What to build:** Trên hồ sơ người khác, người dùng báo cáo (S-13, chọn lý do) hoặc chặn. Hồ sơ bị chặn biến khỏi tìm kiếm, không mở được, không xác nhận được (theo cả hai chiều). Xem/bỏ chặn trong S-17. Admin gỡ hồ sơ trong Studio → ẩn mọi nơi và ghi `moderation_log`.

**Blocked by:** 09, 10

**Status:** claimed

## Comments

- 2026-10-25: Báo cáo không cho tự báo mình. Chặn làm hồ sơ biến khỏi tìm kiếm, khỏi xem trong app, và khỏi xác nhận, theo cả hai chiều. Gỡ hồ sơ ghi moderation_log. `report_block_test.sql` 8 passed. App: xác nhận trước rồi mới báo, chặn, bỏ chặn. Bài app 2 passed. Xác nhận skill đầy đủ vẫn thuộc ticket hoãn; hàm hiện chỉ chặn khi hai người đã chặn nhau.

Thiết kế: F-019 (tiếp cận), F-013, S-12, S-13, S-17; DATA_MODEL `reports`, `blocks`, `moderation_log`; ALG-02, ALG-04 (lọc chặn).

- [ ] Báo cáo lưu được; không tự báo cáo mình (pgTAP)
- [ ] Chặn ẩn hồ sơ khỏi `search_profiles`, `get_public_profile`, `endorse_skill` theo cả hai chiều (pgTAP; sửa hàm bằng migration mới)
- [ ] Đổi `moderation_status` ghi `moderation_log`; hồ sơ `removed` ẩn mọi nơi (pgTAP)
- [ ] Báo cáo/chặn/bỏ chặn có xác nhận trước và thông báo sau (test ViewModel)
- [ ] S-13, S-17 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
