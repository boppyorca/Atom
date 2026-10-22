# 04: Tự khai skill + nhãn mức tin cậy

**What to build:** Ứng viên thêm/xóa skill trên hồ sơ (S-05). Mỗi skill hiện nhãn mức tin cậy (`ConfidenceBadge`); skill tự khai ở mức `selfClaimed`. Mức tin cậy do CSDL tính, app không ghi được.

**Blocked by:** 02

**Status:** ready-for-agent

Thiết kế: F-008, F-009 (phần `selfClaimed`), S-03, S-05; DATA_MODEL `skills`; ALG-01.

- [ ] Thêm, xóa skill; trùng tên trong cùng hồ sơ bị chặn
- [ ] Skill mới có `confidence = selfClaimed`; người dùng không ghi được `confidence` (pgTAP)
- [ ] RLS `skills`: chủ thêm/xóa; người khác không ghi được (pgTAP)
- [ ] `ConfidenceBadge` hiện đúng chữ + biểu tượng cho từng mức, không chỉ dựa vào màu (widget test)
- [ ] S-05 có trạng thái trống/lỗi; đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
