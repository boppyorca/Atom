# 02: Sửa hồ sơ, mặc định riêng tư

**What to build:** Ứng viên xem hồ sơ của mình (S-03) và sửa tên hiển thị, giới thiệu, thành phố, mục liên hệ (S-04). Hồ sơ mới luôn riêng tư. Ô giới thiệu đếm ký tự còn lại, chặn quá 300.

**Blocked by:** 01

**Status:** ready-for-agent

Thiết kế: F-019 (tiếp cận), F-003, S-03, S-04; DATA_MODEL `profiles`, `cities`; ADR-0008. Ticket dùng để đo ponytail (`.scratch/ponytail-trial.md`).

- [ ] Sửa và lưu được tên, giới thiệu, thành phố (chọn từ `cities` seed), liên hệ; mở lại thấy giá trị mới
- [ ] Giới thiệu > 300 ký tự bị chặn ở app (đếm còn lại) và ở CSDL (`check`)
- [ ] Người dùng không ghi được `moderation_status`, `avatar_url`, `first_public_at` (pgTAP quyền cột)
- [ ] Người khác không đọc được hồ sơ riêng tư (pgTAP)
- [ ] Model `Profile` đọc/ghi JSON đúng với fixture (unit test)
- [ ] Trạng thái tải/lỗi/mất mạng của S-03, S-04 có widget test; đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
