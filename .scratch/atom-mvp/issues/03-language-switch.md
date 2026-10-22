# 03: Đổi ngôn ngữ Việt/Anh

**What to build:** Màn cài đặt (S-16) có lựa chọn ngôn ngữ Tiếng Việt / English. Đổi là cả app đổi ngay; mở lại app vẫn giữ lựa chọn. Lần đầu theo ngôn ngữ máy, mặc định tiếng Việt nếu không hỗ trợ.

**Blocked by:** 01

**Status:** resolved

Thiết kế: F-019 (tiếp cận), F-017, S-16; ADR-0004 (`shared_preferences`); NFR-04.

- [x] Đổi ngôn ngữ cập nhật mọi chuỗi đang hiện, không cần khởi động lại
- [x] Lựa chọn được nhớ sau khi mở lại app (test với fake preferences)
- [x] Test so khóa: `app_vi.arb` và `app_en.arb` có cùng tập khóa
- [x] `untranslated-messages-file` sinh ra rỗng
- [x] S-16 đạt guideline tiếp cận
- [x] `make check` xanh

## Comments

- 2026-10-23: Màn Cài đặt có Tiếng Việt / English. Đổi là cả app đổi ngay. Lần đầu theo ngôn ngữ máy, máy không hỗ trợ thì tiếng Việt. Nhớ bằng `shared_preferences` (chủ dự án duyệt thêm thư viện). `make check`: No issues found, 50 test passed. Chưa chạy trên điện thoại ảo.
