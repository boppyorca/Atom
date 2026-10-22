# 04: Tự khai skill + nhãn mức tin cậy

**What to build:** Ứng viên thêm/xóa skill trên hồ sơ (S-05). Mỗi skill hiện nhãn mức tin cậy (`ConfidenceBadge`); skill tự khai ở mức `selfClaimed`. Mức tin cậy do CSDL tính, app không ghi được.

**Blocked by:** 02

**Status:** resolved

Thiết kế: F-019 (tiếp cận), F-008, F-009 (phần `selfClaimed`), S-03, S-05; DATA_MODEL `skills`; ALG-01.

- [x] Thêm, xóa skill; trùng tên trong cùng hồ sơ bị chặn
- [x] Skill mới có `confidence = selfClaimed`; người dùng không ghi được `confidence` (pgTAP)
- [x] RLS `skills`: chủ thêm/xóa; người khác không ghi được (pgTAP)
- [x] `ConfidenceBadge` hiện đúng chữ + biểu tượng cho từng mức, không chỉ dựa vào màu (widget test)
- [x] S-05 có trạng thái trống/lỗi; đạt guideline tiếp cận; chuỗi đủ vi/en
- [x] `make check` và `make check-db` xanh

## Comments

- 2026-10-23: Ứng viên thêm và xóa skill trên màn Skill. Skill mới luôn là "Tự khai". Cơ sở dữ liệu không cho người dùng ghi mức tin cậy, không cho trùng tên, không cho người khác sửa, và chặn quá 50 skill.
- Đỏ rồi xanh: test cơ sở dữ liệu lần đầu đỏ vì quyền mặc định còn quá rộng và câu lệnh đếm 51 skill bị lỗi dấu nháy. Sau khi thu quyền và sửa câu lệnh thì xanh.
- `make check`: No issues found (30.8s); 02:33 +63 All tests passed. `make check-db`: 58 tests PASS. `make docs-check`: ok.
- Rà soát: không có lỗi phải sửa. Chưa chạy trên máy ảo.
- Chủ dự án cho gộp khi kiểm thử sạch, không chờ review riêng.
