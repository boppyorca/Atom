# 17: Xóa tài khoản

**What to build:** Trong cài đặt (S-18), ứng viên xóa tài khoản sau khi xác nhận. Mọi dữ liệu của họ bị xóa thật (không xóa mềm), mức tin cậy skill của người khác và số liệu lương gộp được tính lại, bản lưu trên máy bị xóa, app về S-01.

**Blocked by:** 11, 13, 16

**Status:** ready-for-agent

Thiết kế: F-019 (tiếp cận), F-002, S-18; API_CONTRACT `delete-account`; DATA_MODEL § 6 (cascade); ALG-01; NFR-11.

- [ ] Sau khi xóa: 0 dòng chứa id đó trong mọi bảng `public`, trừ cột đã `set null` (pgTAP NFR-11)
- [ ] Xác nhận skill người đó đã cho bị gỡ, mức tin cậy người khác tính lại (pgTAP)
- [ ] `delete-account` lấy id từ JWT, không nhận id từ app (`deno test`)
- [ ] App xóa bản lưu + phiên rồi về S-01; lỗi mạng không xóa nửa chừng phía app (test ViewModel)
- [ ] S-18 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check`, `make check-db`, `make check-functions` xanh
