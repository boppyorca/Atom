# Thuật ngữ

| Tên tiếng Việt | Tên trong code | Định nghĩa |
|---|---|---|
| Ứng viên | `Candidate` | Người dùng là lập trình viên, chủ của một hồ sơ |
| Hồ sơ | `Profile` | Thông tin, skill và bằng chứng của một ứng viên |
| Hồ sơ công khai | `PublicProfile` | Hồ sơ đã bật công khai: tìm thấy trong app và mở được qua link |
| Chế độ hiển thị hồ sơ | `ProfileVisibility` (`private`, `public`) | Mặc định `private` |
| Mục liên hệ | `ContactLink` (`email`, `linkedin`) | Cách liên hệ tùy chọn, chỉ hiện trên hồ sơ công khai khi chủ hồ sơ bật |
| Skill | `Skill` | Một kỹ năng gắn với hồ sơ |
| Mức tin cậy | `SkillConfidence` (`selfClaimed`, `evidenced`, `endorsed`) | Tự khai / có bằng chứng / được xác nhận |
| Bằng chứng | `Evidence` | Nguồn chứng minh skill: repo GitHub công khai hoặc link |
| Link bằng chứng | `EvidenceLink` (`article`, `product`) | Link bài viết hoặc sản phẩm đã ship do người dùng dán |
| Kết nối GitHub | `GitHubConnection` | Liên kết tài khoản GitHub, chỉ đọc repo công khai |
| Skill đề xuất | `SkillSuggestion` | Skill do AI trích ra, chờ người dùng duyệt |
| Duyệt skill | `reviewSuggestion` | Người dùng giữ hoặc bỏ skill đề xuất |
| Xác nhận skill | `Endorsement` | Một người dùng xác nhận skill của người khác |
| Đồng ý dùng AI | `AiConsent` | Sự đồng ý riêng trước khi gửi dữ liệu cho AI. Loại `doc_chat` là câu đồng ý riêng cho chatbot hỏi tài liệu, chưa có cột trong bảng |
| Tài liệu tri thức | `KnowledgeDoc` | Một file Markdown trong thư mục `knowledge/`. Chỉ bản đã duyệt mới được đưa vào kho tìm |
| Có nguồn | `Grounded` | Câu trả lời đủ đoạn tài liệu đã duyệt. Sai thì người dùng chỉ thấy câu từ chối cố định |
| Phân tích khoảng cách skill | `SkillGapAnalysis` | So hồ sơ với mô tả job mục tiêu |
| Mô tả job | `JobDescription` | Văn bản job mục tiêu người dùng dán vào |
| Khoản lương | `SalaryEntry` | Một khoản lương ẩn danh do người dùng góp |
| Số liệu lương gộp | `SalaryAggregate` | Khoảng lương, trung vị của một nhóm vai trò + thành phố + cấp bậc |
| Cấp bậc | `SeniorityLevel` (`intern`, `fresher`, `junior`, `middle`) | Cấp bậc khai kèm khoản lương |
| Lương gộp | `grossMonthlySalaryVnd` | Lương trước thuế và bảo hiểm, mỗi tháng, bằng VND |
| Ngưỡng tối thiểu | `minSampleSize` | Số khoản tối thiểu để hiện số liệu gộp (giá trị: 5) |
| Góp để xem | `giveToGet` | Phải góp lương mới được xem số liệu lương |
| Báo cáo | `Report` | Người dùng báo một hồ sơ vi phạm |
| Chặn | `Block` | Người dùng chặn người khác |
| Quản trị viên | `Admin` | Người xử lý báo cáo và gỡ hồ sơ |
| Giới hạn dùng AI | `AiUsageLimit` | Hạn mức lượt AI mỗi người và trần chi phí tháng |
| Tỷ lệ kích hoạt | `activationRate` | Tỷ lệ người dùng đã nối GitHub, duyệt ≥ 1 skill có bằng chứng và bật công khai hồ sơ |
