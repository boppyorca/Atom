# 14: Đồng ý phân tích tự động

**What to build:** Trước lần phân tích tự động đầu tiên, ứng viên thấy màn đồng ý (S-08) nói rõ dữ liệu nào được đọc. Đồng ý hoặc từ chối; đổi lại được trong S-16. Từ chối vẫn tự khai skill bình thường.

**Blocked by:** 03

**Status:** resolved

Thiết kế: F-019 (tiếp cận), F-006, S-08, S-16; DATA_MODEL `ai_consents`; ADR-0010 (chữ trên giao diện: "phân tích tự động").

- [x] RLS `ai_consents`: chỉ chủ đọc/ghi (pgTAP)
- [x] Từ chối → nút phân tích dẫn tới S-08, tự khai skill vẫn dùng được (test ViewModel)
- [x] Rút đồng ý trong S-16 có hiệu lực ngay
- [x] S-08 đạt guideline tiếp cận; chuỗi đủ vi/en
- [x] `make check` và `make check-db` xanh

## Comments

- 2026-10-23: Trước khi phân tích, app hỏi dữ liệu nào được đọc. Đồng ý hoặc từ chối. Công tắc trong Cài đặt đổi ngay. Từ chối vẫn thêm skill được. Chỉ chủ hồ sơ đọc và sửa dòng đồng ý.
- Nút "Tìm skill tự động" mở màn đồng ý khi chưa đồng ý. Phần phân tích thật là ticket sau, nên sau khi đồng ý nút chưa chạy phân tích.
- Đỏ rồi xanh: test chưa biên dịch vì chưa có màn đồng ý. Test "lần đọc chậm không ghi đè lựa chọn" đỏ khi bỏ chốt, xanh sau khi chốt lại.
- `make check`: No issues found; 00:11 +71 All tests passed. `make check-db`: 77 tests PASS. `make docs-check`: ok.
- Rà soát: không có lỗi phải sửa. Chưa chạy trên máy ảo.
- Chủ dự án cho gộp khi kiểm thử sạch, không chờ review riêng.
