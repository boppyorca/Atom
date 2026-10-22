# 12: Xem hồ sơ khi mất mạng

**What to build:** Hồ sơ của mình và 50 hồ sơ mở gần nhất vẫn xem được khi mất mạng, kèm băng "Đang xem bản lưu lúc …" và nút Thử lại. Quá 50 → bỏ bản mở lâu nhất. Đăng xuất xóa bản lưu.

**Blocked by:** 09

**Status:** ready-for-agent

Thiết kế: F-016, S-03, S-12; ADR-0004; ALG-06; NFR-01, NFR-03.

- [ ] Repository đạt 5 test mẫu ALG-06 (unit test với fake file service)
- [ ] Không có bản lưu + mất mạng → trạng thái `offline` + Thử lại
- [ ] `OfflineBanner` hiện thời điểm lưu (widget test)
- [ ] Đăng xuất xóa hết file bản lưu (unit test)
- [ ] Widget test NFR-01: đang chờ mạng vẫn cuộn/bấm được
- [ ] Chuỗi đủ vi/en; `make check` xanh
