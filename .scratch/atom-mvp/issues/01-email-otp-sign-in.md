# 01: Đăng nhập bằng email OTP và vào app

**What to build:** Người dùng mở app, nhập email, nhận mã OTP, nhập mã và vào app có thanh 4 tab (màn hồ sơ còn trống). Đăng xuất được. Mở lại app vẫn còn phiên. Đây là tracer bullet đầu tiên: dựng khung app (env, Supabase init, router có `redirect`, theme, l10n vi/en) và bảng `profiles` tối thiểu được tạo tự động khi đăng ký.

**Blocked by:** None (can start immediately)

**Cần chủ dự án trước:** đồng ý thêm package theo DEPENDENCIES.md (AGENTS.md quy tắc 5).

**Status:** resolved

Thiết kế: F-019 (tiếp cận), F-001, S-01, S-02, S-16 (đăng xuất); ADR-0001…0005; TECH_DESIGN § 2–4; DATA_MODEL `profiles`.

- [x] Chưa đăng nhập → luôn về S-01; đã đăng nhập → vào tab Hồ sơ (test `redirect`)
- [x] Mã OTP sai/hết hạn hiện lỗi rõ ràng, không khóa giao diện (test ViewModel)
- [x] Phiên lưu trong Keychain/Keystore qua `SecureSessionStorage` (test với fake)
- [x] Đăng ký mới tự tạo một dòng `profiles` riêng tư; RLS: chỉ chủ đọc/sửa (pgTAP)
- [x] Test chung: mọi bảng `public` bật RLS (pgTAP)
- [x] Mọi chuỗi có trong cả `app_vi.arb` và `app_en.arb`; S-01, S-02 đạt guideline tiếp cận
- [x] `make check` và `make check-db` xanh
- [x] Email đăng nhập thật sự chứa mã 6 số (kiểm trên Supabase local qua Mailpit)
- [ ] Chạy thử trên Simulator/máy ảo: nhập email → nhập mã → vào tab Hồ sơ → đăng xuất về S-01 (chủ dự án bỏ qua, xem Comments)

## Comments

- 2026-10-22: Rà soát sau khi báo xong. Thử luồng thật qua API local: mẫu email mặc định chỉ gửi link (`type=magiclink`), **không có mã 6 số**, nên S-02 không dùng được. Cần mẫu email `magic_link` có `{{ .Token }}` trong `supabase/config.toml` (đổi cấu hình đăng nhập → chờ chủ dự án đồng ý). Máy chưa có Xcode/Android SDK nên chưa chạy Simulator. Hàm trigger `handle_new_user` còn quyền EXECUTE cho `anon`/`authenticated` → đã gỡ bằng migration mới + test. Nút gửi lại mã chưa chờ 60 giây → ticket 18.
- 2026-10-22: Chủ dự án đồng ý đổi mẫu email. Thêm `supabase/templates/otp.html` (`{{ .Token }}`) cho `magic_link` và `confirmation`. Kiểm qua API local + Mailpit: email có mã 6 số, không có link; đúng mã → 200, sai mã → 403, dùng lại mã → 403; hồ sơ tự tạo, `private`. Khi tạo dự án Supabase thật phải chép cùng mẫu này. Còn chờ: Simulator (chủ dự án đang cài Xcode), repo GitHub để mở PR.
- 2026-10-22: CI xanh trên PR #1. Simulator iOS 18.5 treo khi cài/mở app (máy bận nạp ổ đĩa ảo); chủ dự án quyết định bỏ qua và merge. Luồng UI trên thiết bị thật **chưa được kiểm**: chạy lại khi làm ticket kế tiếp có màn hình.
