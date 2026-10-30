# ADR-0012 · Chatbot hỏi đáp tri thức công khai

- **Trạng thái:** Đề xuất
- **Ticket:** [20](../../.scratch/atom-mvp/issues/20-doc-chat.md)
- **Bổ sung cho:** [ADR-0010](0010-in-house-rule-based-skill-extraction.md), [ADR-0011](0011-confidence-from-signal-strength.md). Không thay đổi quyết định nào của hai ADR đó.

## Bối cảnh

Atom là bản thử, khoảng 10–20 người, ngân sách 0 đồng. Máy chủ là Mac M2 8GB. Supabase local chạy trên Docker Desktop.

Ô chat cũ giữ nguyên: máy nhà, rồi Groq, rồi Z.ai, hạn mức 30 câu mỗi tháng. Cần một chatbot mới trả lời từ tài liệu công khai, chạy trên máy này.

## Quyết định

1. Phạm vi v1 là hướng dẫn dùng Atom, lộ trình học 6 ngách (Frontend, Backend, Mobile, QA, Data/AI, DevOps) cộng trang "Chọn ngách", lộ trình Flutter, nền tảng web với JS/TS/React, Java với Spring Boot, .NET, Git và SQL. Ngoài phạm vi: chương trình môn học đại học, hồ sơ riêng của người dùng, con số lương cụ thể, kiến thức web ngoài kho, ngách hoặc framework chưa được viết.
2. Chỉ tiếng Việt.
3. App và chatbot dùng Supabase trên web, mã dự án `quphatkscppfwxzfkrnx`. Hàm `ask-atom` chạy trên dự án đó. Model vẫn là Ollama trên macOS, không phải model trên mây. Bộ tìm là pgvector trong Postgres của dự án web. Không thêm chương trình Python. Không mở cổng máy này ra internet.
4. Một câu hỏi, một câu trả lời. Không nhớ hội thoại. Không công cụ. Không duyệt web. Câu trả lời về Atom và lộ trình học lấy từ tài liệu. Chào và cảm ơn dùng câu mẫu, không để model nói tự do.
5. Code chạy trước model. Chào hoặc cảm ơn thì trả câu mẫu. Câu về dữ liệu cá nhân, hoặc câu đòi bỏ hướng dẫn và in tài liệu, thì trả câu từ chối mẫu. Câu quá mơ hồ thì hỏi lại bằng câu mẫu. Danh sách mẫu là hàng rào phụ. Còn prompt, ngưỡng tìm tài liệu, và bộ câu đánh giá.
6. Chưa chọn cách hiện câu trả lời. Chờ kết quả lần thử S1. Hai phương án:
   - A: không chạy chữ dần. Chờ cả câu, mục tiêu dưới 10 giây.
   - B: tìm đoạn tài liệu trước. `grounded` lấy từ ngưỡng điểm. Không đủ điểm thì trả câu cố định và không gọi model. Đủ điểm thì mới chạy chữ dần.
7. Bot mới không bao giờ chuyển sang Groq, Z.ai, hay dịch vụ trên mây. Ollama không chạy thì trả `AI_UNAVAILABLE`.
8. Cần câu đồng ý riêng `doc_chat` trước lần hỏi đầu. Câu hỏi được xử lý bởi mô hình chạy trên máy của tác giả.
9. Câu hỏi dài từ 1 đến 300 ký tự. Mỗi người một yêu cầu tại một thời điểm. Toàn hệ thống một yêu cầu AI tại một thời điểm, khóa có hạn. Trần số câu mỗi giờ cho mỗi người chốt sau khi đo. Hạn mức 30 câu mỗi tháng của ô chat cũ không đổi.
10. Chỉ ghi thời điểm, mã lỗi, `grounded`, độ trễ, và `request_id`. Không ghi nội dung câu hỏi hay câu trả lời, trừ khi người dùng tự gửi câu đó cho tác giả (F-027). Tắt nhật ký chat và telemetry của bộ tìm. Nút thích hoặc không thích chỉ lưu kết quả. "Gửi câu hỏi này cho tác giả" mặc định tắt. Nội dung chỉ gửi khi người dùng chọn câu đó, lưu trên máy, xóa sau đồ án. Nơi lưu siêu dữ liệu là câu hỏi mở ở cuối file.
11. Tri thức nằm trong repo, thư mục `knowledge/`, file Markdown có ngày và trạng thái. Chỉ file `status: reviewed` mới được đồng bộ. Lệnh kiểm tra đối tên skill với bảng `skill_catalog`. Kho tìm lại được dựng từ repo, không cần bản sao riêng.
12. Chất lượng đo bằng bộ câu tự động và tác giả tự chấm, cộng một tập do người không xem tài liệu viết. Ngưỡng: đúng nguồn từ 80% trở lên, đúng lời từ 80% trở lên, từ chối đúng từ 90% trở lên, câu tấn công lọt bằng 0. Mẫu nhỏ nên thực chất phải đúng gần hết. Ngưỡng này chỉnh lại sau khi đo.
13. Chưa chọn phương án A hay B ở mục 6. Chờ số đo của S1. Nếu S1 chậm hơn mục tiêu của phương án được chọn thì dừng để bàn.
14. Giai đoạn này chỉ tác giả, điện thoại và Mac cùng Wi-Fi. Cho người khác thử từ xa cần một quyết định riêng về đường hầm. Chỗ đặt màn hình, cạnh ô chat cũ hay mục riêng, để sau.

## Phương án đã loại

Chương trình Python riêng, vì thêm một chỗ giữ chìa khóa. Open WebUI, vì là một cửa chat đứng riêng, không gắn vào app. AnythingLLM bản cài trên máy, vì khó cho điện thoại gọi tới. Mô hình trên mây cho bot mới, vì trái mục tiêu riêng tư, và ô chat cũ đã có đường đó.

## Câu hỏi mở

Siêu dữ liệu của `ask-atom` (thời điểm, mã lỗi, `grounded`, độ trễ, `request_id`) cần một bảng mới và một migration. Chưa chọn tên bảng và chưa chọn cột. Không ghi nội dung câu hỏi hay câu trả lời vào bảng đó, trừ khi người dùng tự gửi theo F-027.

## Hệ quả

Chất lượng phụ thuộc tài liệu tác giả viết. Ngách chưa viết thì bot từ chối. Database nằm trên Supabase web. Câu trả lời của bot vẫn cần Mac bật, vì model Ollama ở trên Mac.

Chưa làm trong file này: hàm `ask-atom`, bảng khóa và câu đồng ý, Docker nếu chọn AnythingLLM, và gói Flutter mới nếu cần. Mỗi việc đó vẫn cần một lượt làm riêng.
