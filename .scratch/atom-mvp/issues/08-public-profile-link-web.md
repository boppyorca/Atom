# 08: Bật công khai + trang web hồ sơ

**What to build:** Ứng viên bật hồ sơ công khai và chép link chia sẻ (S-03). Người khác mở link trên trình duyệt thấy trang tĩnh W-01 với tên, giới thiệu, skill + mức tin cậy, bằng chứng; liên hệ chỉ hiện khi chủ bật. Tắt công khai → link không còn hiện hồ sơ.

**Blocked by:** 05

**Status:** claimed

Thiết kế: F-019 (tiếp cận), F-011, S-03, W-01; API_CONTRACT `get_public_profile`; ADR-0007; `PUBLIC_PROFILE_BASE_URL`.

- [x] Bật công khai lần đầu ghi `first_public_at` (pgTAP)
- [x] `get_public_profile` trả null khi riêng tư/bị gỡ/không tồn tại; ẩn liên hệ khi chưa bật; `anon` gọi được, không gọi được hàm khác (pgTAP)
- [x] Nút chép link tạo đúng URL từ `PUBLIC_PROFILE_BASE_URL` (test ViewModel)
- [ ] Trang W-01 hiện đúng tiếng Việt / ngôn ngữ khác, có nút đổi; ghi kết quả thử thủ công trên máy tính + điện thoại
- [ ] Xác minh header khóa publishable cần cho W-01 trên Supabase local; ghi kết quả
- [x] Chuỗi app đủ vi/en; đạt guideline tiếp cận
- [ ] `make check` và `make check-db` xanh

## Comments

- 2026-10-25: Bật công khai ghi `first_public_at`. `get_public_profile` trả null khi riêng tư hoặc bị gỡ, ẩn liên hệ khi chưa bật. `anon` gọi được và không gọi được `get_ai_quota`. `public_profile_test.sql` 6 passed. Link chép từ `PUBLIC_PROFILE_BASE_URL`. Trang `web/public_profile/index.html` có nút Việt/Anh. Chưa thử trang trên trình duyệt với khóa thật. Chặn người xem chưa có bảng, nên link công khai chưa biết ai đang xem.
