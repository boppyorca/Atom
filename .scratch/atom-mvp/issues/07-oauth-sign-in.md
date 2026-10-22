# 07: Đăng nhập GitHub / Google / Apple

**What to build:** S-01 có thêm nút đăng nhập GitHub, Google (cả hai máy) và Apple (iOS) qua OAuth trên trình duyệt, quay lại app bằng deep link. Ảnh đại diện lấy từ GitHub/Google nếu có.

**Blocked by:** 01

**Cần chủ dự án trước:** cấu hình ba nhà cung cấp OAuth cho Supabase local (client id/secret là bí mật, chủ dự án tự điền); đồng ý thay đổi đăng nhập (AGENTS.md quy tắc 5).

**Status:** ready-for-agent

Thiết kế: F-001, S-01; ADR-0005 (PKCE, deep link); TECH_DESIGN § 5.1.

- [ ] Nút Apple chỉ hiện trên iOS (widget test theo nền tảng)
- [ ] Hủy giữa chừng quay về S-01 không lỗi (test ViewModel)
- [ ] Trigger tạo `profiles` điền `avatar_url` từ metadata GitHub/Google; email/Apple → null (pgTAP)
- [ ] Xác minh luồng PKCE là mặc định ở `supabase_flutter` đang dùng; ghi kết quả vào ticket
- [ ] Ghi kết quả thử thủ công từng nhà cung cấp trên iOS + Android
- [ ] Nút có nhãn tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
