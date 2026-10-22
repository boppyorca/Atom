# 14: Đồng ý phân tích tự động

**What to build:** Trước lần phân tích tự động đầu tiên, ứng viên thấy màn đồng ý (S-08) nói rõ dữ liệu nào được đọc. Đồng ý hoặc từ chối; đổi lại được trong S-16. Từ chối vẫn tự khai skill bình thường.

**Blocked by:** 03

**Status:** ready-for-agent

Thiết kế: F-019 (tiếp cận), F-006, S-08, S-16; DATA_MODEL `ai_consents`; ADR-0010 (chữ trên giao diện: "phân tích tự động").

- [ ] RLS `ai_consents`: chỉ chủ đọc/ghi (pgTAP)
- [ ] Từ chối → nút phân tích dẫn tới S-08, tự khai skill vẫn dùng được (test ViewModel)
- [ ] Rút đồng ý trong S-16 có hiệu lực ngay
- [ ] S-08 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
