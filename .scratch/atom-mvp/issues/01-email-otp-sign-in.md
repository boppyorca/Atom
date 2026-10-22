# 01: Đăng nhập bằng email OTP và vào app

**What to build:** Người dùng mở app, nhập email, nhận mã OTP, nhập mã và vào app có thanh 4 tab (màn hồ sơ còn trống). Đăng xuất được. Mở lại app vẫn còn phiên. Đây là tracer bullet đầu tiên: dựng khung app (env, Supabase init, router có `redirect`, theme, l10n vi/en) và bảng `profiles` tối thiểu được tạo tự động khi đăng ký.

**Blocked by:** None (can start immediately)

**Cần chủ dự án trước:** đồng ý thêm package theo DEPENDENCIES.md (AGENTS.md quy tắc 5).

**Status:** ready-for-human

Thiết kế: F-001, S-01, S-02, S-16 (đăng xuất); ADR-0001…0005; TECH_DESIGN § 2–4; DATA_MODEL `profiles`.

- [x] Chưa đăng nhập → luôn về S-01; đã đăng nhập → vào tab Hồ sơ (test `redirect`)
- [x] Mã OTP sai/hết hạn hiện lỗi rõ ràng, không khóa giao diện (test ViewModel)
- [x] Phiên lưu trong Keychain/Keystore qua `SecureSessionStorage` (test với fake)
- [x] Đăng ký mới tự tạo một dòng `profiles` riêng tư; RLS: chỉ chủ đọc/sửa (pgTAP)
- [x] Test chung: mọi bảng `public` bật RLS (pgTAP)
- [x] Mọi chuỗi có trong cả `app_vi.arb` và `app_en.arb`; S-01, S-02 đạt guideline tiếp cận
- [x] `make check` và `make check-db` xanh
