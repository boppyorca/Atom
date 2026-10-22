# 03: Đổi ngôn ngữ Việt/Anh

**What to build:** Màn cài đặt (S-16) có lựa chọn ngôn ngữ Tiếng Việt / English. Đổi là cả app đổi ngay; mở lại app vẫn giữ lựa chọn. Lần đầu theo ngôn ngữ máy, mặc định tiếng Việt nếu không hỗ trợ.

**Blocked by:** 01

**Status:** ready-for-agent

Thiết kế: F-017, S-16; ADR-0004 (`shared_preferences`); NFR-04.

- [ ] Đổi ngôn ngữ cập nhật mọi chuỗi đang hiện, không cần khởi động lại
- [ ] Lựa chọn được nhớ sau khi mở lại app (test với fake preferences)
- [ ] Test so khóa: `app_vi.arb` và `app_en.arb` có cùng tập khóa
- [ ] `untranslated-messages-file` sinh ra rỗng
- [ ] S-16 đạt guideline tiếp cận
- [ ] `make check` xanh
