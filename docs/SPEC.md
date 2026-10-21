# SPEC: Atom (v1.0 · Đã thống nhất · 2026-10-22)

## Mục tiêu

App điện thoại giúp lập trình viên 0–2 năm kinh nghiệm ở Việt Nam **chứng minh skill bằng bằng chứng thật** (GitHub, bài viết, sản phẩm đã ship), chia sẻ hồ sơ qua link, biết mình thiếu gì so với job mục tiêu và tra lương ẩn danh.

## Phạm vi MVP (Must)

- Tài khoản: đăng nhập email/GitHub/Google/Apple (F-001), xóa tài khoản (F-002).
- Hồ sơ: hồ sơ mặc định riêng tư (F-003), GitHub repo công khai (F-004), link bằng chứng (F-005).
- AI: đồng ý dùng AI (F-006), trích skill có duyệt (F-007), phân tích khoảng cách skill (F-014), giới hạn dùng AI (F-018).
- Skill: tự khai (F-008), mức tin cậy (F-009), xác nhận bởi người khác (F-010).
- Chia sẻ và cộng đồng: link công khai (F-011), tìm/xem hồ sơ (F-012), báo cáo/chặn (F-013).
- Lương ẩn danh "góp để xem" (F-015).
- Chung: đọc khi mất mạng (F-016), tiếng Việt + tiếng Anh (F-017), khả năng tiếp cận cơ bản (F-019).

## Ngoài phạm vi

Mạng xã hội, phỏng vấn thử, thông báo đẩy (Should); Figma/Behance, đàm phán lương (Could); nhà tuyển dụng, designer, thanh toán, quảng cáo, bản web đầy đủ, tablet, repo riêng tư (Won't).

## Tiêu chí hoàn thành MVP

1. Mọi Must đạt tiêu chí chấp nhận.
2. `make check` và `make check-db` xanh.
3. Bản thử nghiệm kín cài được trên TestFlight và Google Play nội bộ.
4. Đã kiểm thử xóa tài khoản và đồng ý dùng AI.
5. Đã cấu hình trần chi phí AI.

## Tài liệu

- [IDEA.md](IDEA.md): vấn đề, người dùng, giá trị, chỉ số.
- [CONTEXT_OF_USE.md](CONTEXT_OF_USE.md): persona, kịch bản, thiết bị.
- [FEATURES.md](FEATURES.md): tính năng và tiêu chí chấp nhận.
- [REQUIREMENTS_AGREEMENT.md](REQUIREMENTS_AGREEMENT.md): quyết định, giả định, câu hỏi mở, rủi ro.
- [GLOSSARY.md](../GLOSSARY.md): thuật ngữ.
