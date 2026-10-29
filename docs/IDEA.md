# Ý tưởng sản phẩm: Atom

> v1.0 (Đã thống nhất) · 2026-10-22 · Xem tổng quan tại [SPEC.md](SPEC.md)

## Vấn đề

Lập trình viên mới vào nghề có năng lực nhưng **không chứng minh được**. CV và LinkedIn chỉ là lời tự khai, còn bằng chứng thật (repo GitHub, bài viết, sản phẩm đã ship) nằm rải rác, nhà tuyển dụng không có thời gian tự đối chiếu.

## Người dùng mục tiêu

- Ứng viên là lập trình viên: sinh viên, fresher, junior (0–2 năm kinh nghiệm).
- Thị trường Việt Nam.
- Không phục vụ trong bản đầu: nhà tuyển dụng (chỉ xem qua link công khai, không có tài khoản), designer.

## Giá trị

1. **Hồ sơ dựa trên bằng chứng (Evidence-based profile):** gắn GitHub (repo công khai) và link bài viết/sản phẩm; AI đề xuất skill từ chính các nguồn đó, người dùng duyệt.
2. **Độ tin cậy của skill (Skill confidence):** tự khai → có bằng chứng → được người khác xác nhận.
3. **Chia sẻ được:** link hồ sơ công khai mở trên trình duyệt, gửi kèm đơn ứng tuyển.
4. **Phân tích khoảng cách skill (Skill gap analysis)** so với mô tả job mục tiêu.
5. **Lương ẩn danh (Anonymous salary)** theo vai trò, thành phố và cấp bậc, kiểu "góp để xem".

## Chỉ số thành công

- Chỉ số chính: **tỷ lệ kích hoạt (activation rate)**, là tỷ lệ người dùng thử nghiệm kín đã kết nối GitHub, duyệt ≥ 1 skill mức "có bằng chứng" và bật công khai hồ sơ.
- Mục tiêu thử nghiệm kín: ≥ 50% người tham gia (10/20) đạt kích hoạt trong 7 ngày đầu sau khi cài.

## App KHÔNG làm (bản đầu)

- Không có phía nhà tuyển dụng, không đăng tin tuyển dụng, không nộp đơn trong app.
- Không phục vụ designer; chưa gắn Figma/Behance.
- Không có feed, đăng bài, bình luận, thả tim (để bản sau).
- Không đọc repo GitHub riêng tư.
- Không thu tiền, không quảng cáo.
- Không có bản web đầy đủ hay bố cục riêng cho máy tính bảng.

## Bổ sung nháp: ô chat với agent (chờ xác nhận, 2026-10-28)

Ô chat là một cửa riêng, chưa nằm trong bản đã chốt ngày 22/10. Tìm skill và so với tin tuyển dụng vẫn dùng danh sách skill có sẵn trong app, chi phí 0 đồng, không gửi chữ ra ngoài.

Ô chat để người dùng hỏi về hồ sơ của mình. Agent được đọc câu hỏi, tên skill, mô tả tin người dùng vừa dán, và phần chữ công khai của repo đã chọn. Agent chỉ đề xuất. Người dùng bấm Nhận hoặc Bỏ. Agent không tự sửa hồ sơ.

Thứ tự hỏi: model trên máy nhà (Ollama) trước. Máy nhà không trả lời thì hỏi Groq, gói miễn phí. Groq không trả lời thì hỏi Z.ai, chỉ model miễn phí GLM-4.7-Flash. Cả ba đều không trả lời thì hiện một câu và nút Thử lại.

Chữ gửi cho Groq hoặc Z.ai có thể được hai bên dùng để cải thiện sản phẩm của họ. Chữ do Ollama trả lời thì ở trên máy nhà. Lương, email và cách liên hệ không gửi cho agent.
