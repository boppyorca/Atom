# 06: Kết nối GitHub + chọn repo làm bằng chứng

**What to build:** Ứng viên kết nối tài khoản GitHub (`linkIdentity`), thấy danh sách repo công khai (chọn sẵn tối đa 10 repo không phải fork), chọn tối đa 10 repo làm bằng chứng (S-06). Ngắt kết nối xóa các bằng chứng repo. Tên GitHub lấy phía server, không lấy từ app.

**Blocked by:** 05

**Cần chủ dự án trước:** bật `enable_manual_linking` + cấu hình GitHub OAuth local (đổi đăng nhập, AGENTS.md quy tắc 5); tự tạo token GitHub chỉ đọc dữ liệu công khai và tự đặt vào file env cục bộ; đồng ý cài Deno và thêm `make check-functions`.

**Status:** ready-for-agent

Thiết kế: F-019 (tiếp cận), F-004, S-06; DATA_MODEL `github_connections`, `evidence`; API_CONTRACT `connect_github`, `github-repos`; ADR-0005, ADR-0006.

- [ ] `connect_github` đọc `github_username` từ `auth.identities` (pgTAP)
- [ ] `github-repos` chỉ trả repo công khai, chọn sẵn ≤ 10 không fork, từ chối repo thứ 11 (`deno test`)
- [ ] Ngắt kết nối xóa bằng chứng loại repo, skill tính lại mức tin cậy (pgTAP)
- [ ] Lỗi mạng/GitHub hiện thông báo + Thử lại (test ViewModel)
- [ ] Ghi kết quả kiểm thủ công: màn đồng ý GitHub không xin quyền `repo` (xác minh [CHƯA XÁC MINH] khóa `user_name`, `avatar_url`)
- [ ] S-06 đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check`, `make check-db`, `make check-functions` xanh
