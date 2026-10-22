# 08: Bật công khai + trang web hồ sơ

**What to build:** Ứng viên bật hồ sơ công khai và chép link chia sẻ (S-03). Người khác mở link trên trình duyệt thấy trang tĩnh W-01 với tên, giới thiệu, skill + mức tin cậy, bằng chứng; liên hệ chỉ hiện khi chủ bật. Tắt công khai → link không còn hiện hồ sơ.

**Blocked by:** 05

**Status:** ready-for-agent

Thiết kế: F-011, S-03, W-01; API_CONTRACT `get_public_profile`; ADR-0007; `PUBLIC_PROFILE_BASE_URL`.

- [ ] Bật công khai lần đầu ghi `first_public_at` (pgTAP)
- [ ] `get_public_profile` trả null khi riêng tư/bị gỡ/không tồn tại; ẩn liên hệ khi chưa bật; `anon` gọi được, không gọi được hàm khác (pgTAP)
- [ ] Nút chép link tạo đúng URL từ `PUBLIC_PROFILE_BASE_URL` (test ViewModel)
- [ ] Trang W-01 hiện đúng tiếng Việt / ngôn ngữ khác, có nút đổi; ghi kết quả thử thủ công trên máy tính + điện thoại
- [ ] Xác minh header khóa publishable cần cho W-01 trên Supabase local; ghi kết quả
- [ ] Chuỗi app đủ vi/en; đạt guideline tiếp cận
- [ ] `make check` và `make check-db` xanh
