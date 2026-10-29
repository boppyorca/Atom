# 17: Xóa tài khoản

**What to build:** Trong cài đặt (S-18), ứng viên xóa tài khoản sau khi xác nhận. Mọi dữ liệu của họ bị xóa thật (không xóa mềm), mức tin cậy skill của người khác và số liệu lương gộp được tính lại, bản lưu trên máy bị xóa, app về S-01.

**Blocked by:** 11, 13, 16

**Status:** claimed

## Comments

- 2026-10-25: Xóa user thì hồ sơ, skill, link và lương biến mất. `delete_account_test.sql` 4 passed. Hàm xóa lấy id từ người đang đăng nhập, không lấy id app gửi. App: xóa lỗi thì vẫn đăng nhập; xóa xong thì đăng xuất. Bài app 4 passed. Chưa có bảng xác nhận skill nên chưa kiểm mức tin cậy của người khác. Chưa bấm xóa trên điện thoại.

Thiết kế: F-019 (tiếp cận), F-002, S-18; API_CONTRACT `delete-account`; DATA_MODEL § 6 (cascade); ALG-01; NFR-11.

- [ ] Sau khi xóa: 0 dòng chứa id đó trong mọi bảng `public`, trừ cột đã `set null` (pgTAP NFR-11)
- [ ] Xác nhận skill người đó đã cho bị gỡ, mức tin cậy người khác tính lại (pgTAP)
- [ ] `delete-account` lấy id từ JWT, không nhận id từ app (`deno test`)
- [ ] App xóa bản lưu + phiên rồi về S-01; lỗi mạng không xóa nửa chừng phía app (test ViewModel)
- [ ] S-18 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check`, `make check-db`, `make check-functions` xanh
