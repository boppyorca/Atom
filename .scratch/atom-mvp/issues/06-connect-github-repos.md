# 06: Kết nối GitHub + chọn repo làm bằng chứng

**What to build:** Ứng viên kết nối tài khoản GitHub (`linkIdentity`), thấy danh sách repo công khai (chọn sẵn tối đa 10 repo không phải fork), chọn tối đa 10 repo làm bằng chứng (S-06). Ngắt kết nối xóa các bằng chứng repo. Tên GitHub lấy phía server, không lấy từ app.

**Blocked by:** none. Ticket 05 no longer blocks this. The owner still has to create the GitHub app and the read-only token.

**Cần chủ dự án trước:** cấu hình GitHub OAuth local (client id và secret do chủ dự án tạo, không dán vào chat); tự đặt token GitHub chỉ đọc dữ liệu công khai vào env cục bộ; đồng ý cài Deno để chạy `deno test`. `enable_manual_linking` đã bật.

**Status:** claimed

Thiết kế: F-019 (tiếp cận), F-004, S-06; DATA_MODEL `github_connections`, `evidence`; API_CONTRACT `connect_github`, `github-repos`; ADR-0005, ADR-0006.

- [ ] `connect_github` đọc `github_username` từ `auth.identities` (pgTAP)
- [ ] `github-repos` chỉ trả repo công khai, chọn sẵn ≤ 10 không fork, từ chối repo thứ 11 (`deno test`)
- [ ] Ngắt kết nối xóa bằng chứng loại repo, skill tính lại mức tin cậy (pgTAP)
- [ ] Lỗi mạng/GitHub hiện thông báo + Thử lại (test ViewModel)
- [ ] Ghi kết quả kiểm thủ công: màn đồng ý GitHub không xin quyền `repo` (xác minh [CHƯA XÁC MINH] khóa `user_name`, `avatar_url`)
- [ ] S-06 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check`, `make check-db`, `make check-functions` xanh

## Comments

- 2026-10-25: Rà soát sau kiểm thử. Lỗi phải sửa: nút Kết nối ghi nhận GitHub ngay khi trình duyệt vừa mở, trước khi người dùng đăng nhập xong. Đã tách: mở trang GitHub trước, chỉ ghi nhận khi đăng nhập xong và app được mở lại. Kiểm lại: 4 bài màn GitHub đạt; `supabase test db` Files=10, Tests=83, Result PASS. Việc còn lại, không chặn: GitHub chỉ trả trang đầu 100 repo. Chưa bấm thử trên máy ảo, chưa xem màn đồng ý GitHub có xin quyền repo riêng tư hay không.
