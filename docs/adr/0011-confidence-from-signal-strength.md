# ADR-0011 · Mức tin cậy do tín hiệu quyết định

- **Trạng thái:** Đã duyệt · 2026-10-29
- **Bổ sung cho:** [ADR-0010](0010-in-house-rule-based-skill-extraction.md). Không thay thế ADR-0010.

## Bối cảnh

Mức `evidenced` trước đây chỉ cần một dòng trong `skill_evidence`. Chữ trong README hoặc topic, rồi bấm Nhận, là đủ. Không có kiểm tra commit, quy mô hay thời gian. Danh mục skill nằm trong file JSON.

## Quyết định

1. Mức tin cậy do hàm trong cơ sở dữ liệu tính từ tín hiệu. Không mô hình ngôn ngữ nào, và không thao tác Nhận nào, tự đặt mức.
2. Tín hiệu mạnh là `commit_activity`. Tín hiệu bổ trợ là `manifest_dependency`. README, mô tả repo, topic, mô tả tin, ngôn ngữ cả repo, link bài viết và ghi chú tay là yếu và không đủ để đạt `evidenced`.
3. `evidenced` khi có ít nhất một tín hiệu mạnh đủ ngưỡng và một tín hiệu độc lập. Tín hiệu độc lập là khai báo thư viện ở repo đã có ít nhất một commit hợp lệ, hoặc tín hiệu mạnh ở một repo khác.
4. Ngưỡng nằm trong `evidence_policy`, một dòng đang hoạt động. Giá trị đầu: 5 commit, 200 dòng, 14 ngày. Giới hạn 3 commit mỗi ngày và việc loại commit rỗng thuộc ticket đọc commit, chưa nằm trong hàm này.
5. Danh mục skill chuyển vào Postgres là việc sau. Lúc đó skill ngoài danh mục chỉ là `new_skill` và không thể `evidenced`.
6. Chữ trên giao diện, khi làm màn hình, nói "có hoạt động mã nguồn đáng kể", không nói "thành thạo".
7. Không lưu token GitHub của từng người. Repo công khai đọc bằng token chỉ-đọc của máy chủ. Login đã lưu khi nối GitHub.
8. Mô hình ngoài, nếu dùng sau này, chỉ nhận tín hiệu đã phân loại, không nhận README thô, và chỉ khi người dùng đã đồng ý gửi cho bên thứ ba. Đường mặc định vẫn là quy tắc trong app.

Gắn link bài viết không tự nâng mức. Hàm không ghi đè dòng đang là `endorsed`.

## Hệ quả

Migration mới `20261029180000_evidence_strength.sql`. Không sửa các migration cũ. Chưa áp dụng lên database local trong lượt viết file này.
