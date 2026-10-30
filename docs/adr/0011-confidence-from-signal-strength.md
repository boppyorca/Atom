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

## Bổ sung 2026-10-29

Một lượt đọc commit lấy trang danh sách tối đa 100 commit của login đã lưu. Ngày và số trên trang đó là cửa sổ đã xem, không phải tổng đời repo. Cờ `scan_truncated` ghi khi trang đầy, khi dừng sớm, hoặc khi chưa mở hết commit. Giao diện không hiện các số đó như tổng số commit.

Commit cũ nhất thêm hơn 1000 dòng chỉ bị bỏ khi lần quét chạm gốc lịch sử. Quét bị cắt thì commit cũ nhất nhìn thấy chưa chắc là commit đầu, nên không bỏ.

Một lượt chạy tối đa 10 repo và 240 lời gọi. Hết ngân sách, hoặc GitHub trả về hết hạn mức, là lỗi `RATE_LIMITED`. Lỗi đó khác với GitHub không trả lời.

Chỉ đọc file khai báo ở thư mục gốc, và chỉ hai file có tên gói trong 13 quy tắc: `pubspec.yaml` (Flutter, Provider) và `package.json` (React). File được đọc như dữ liệu, chỉ lấy tên gói, tối đa 200 KB, hết giờ sau 8 giây. Thư mục con không được đọc. Các file `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`, `*.csproj` không được mở vì 13 quy tắc không có tên gói tương ứng.

Gợi ý đối với danh mục bằng khóa `catalog_id`, không bằng chữ hiển thị. Thiếu khóa thì lượt quét báo lỗi, không gắn nhầm `new_skill`. Tên và tên gọi khác, sau khi chuẩn hóa, không được trùng nhau. Go, C, R, Java với JavaScript, React với React Native đã được soát: mỗi khóa chỉ thuộc một skill.

Cột `verifiability` nói skill kiểm được bằng file, bằng gói, hay không kiểm được bằng mã nguồn. Hơn 100 tên trong danh mục không kiểm được bằng commit. Điều đó được hiện trên màn gợi ý.

## Hệ quả

Migration mới `20261029180000_evidence_strength.sql` và `20261029220000_catalog_resolve.sql`. Không sửa các migration cũ.
