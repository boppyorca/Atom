# 10: Xác nhận skill cho người khác

**What to build:** Trên hồ sơ người khác (S-12), người dùng bấm xác nhận một skill hoặc rút lại. Skill đủ xác nhận lên mức `endorsed`. Có giới hạn số lần xác nhận theo `app_settings`.

**Blocked by:** 09

**Status:** ready-for-agent

Thiết kế: F-010, F-009, S-12; DATA_MODEL `endorsements`; API_CONTRACT `endorse_skill`; ALG-02, ALG-01.

- [ ] `endorse_skill` đạt 5 test mẫu ALG-02, gồm rút lại và tự xác nhận mình bị từ chối (pgTAP)
- [ ] Mức tin cậy tính lại sau xác nhận/rút lại (pgTAP theo ALG-01)
- [ ] Nút xác nhận đổi trạng thái ngay, có chỉ báo đang xử lý, lỗi thì quay lại (test ViewModel)
- [ ] Đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
