# 09: Tìm hồ sơ theo skill + xem hồ sơ người khác

**What to build:** Ở tab Khám phá (S-11), người dùng tìm hồ sơ công khai theo skill và mở hồ sơ một người (S-12, đường dẫn `/u/:id`). Chỉ hồ sơ công khai, đang hoạt động, không phải của mình.

**Blocked by:** 08

**Status:** ready-for-agent

Thiết kế: F-019 (tiếp cận), F-012, S-11, S-12; API_CONTRACT `search_profiles`, `get_public_profile`; ALG-04.

- [ ] `search_profiles` đạt 5 test mẫu ALG-04 (pgTAP)
- [ ] Không trả hồ sơ riêng tư, bị gỡ hoặc của chính mình (pgTAP)
- [ ] S-11 có trạng thái trống ("không tìm thấy"), đang tải, lỗi (test ViewModel)
- [ ] Mở S-12 từ kết quả và từ đường dẫn `/u/:id` (test router)
- [ ] S-11, S-12 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
