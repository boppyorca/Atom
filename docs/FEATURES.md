# Danh sách tính năng

> v1.0 (Đã thống nhất) · 2026-10-22 · Xem tổng quan tại [SPEC.md](SPEC.md) · Thuật ngữ tại [GLOSSARY.md](../GLOSSARY.md)

Ưu tiên theo MoSCoW. Tính năng Must đã chốt (**Agreed**) theo biên bản v1.0; Should và Could còn **Draft** vì chưa có tiêu chí chấp nhận.

## Must

### F-001 · Đăng nhập (Authentication)
- **User story:** Là ứng viên, tôi muốn đăng nhập bằng email, GitHub hoặc Google (và Apple trên iOS), để dùng app bằng tài khoản tôi đã có.
- **Tiêu chí chấp nhận:**
  - [ ] Đăng nhập thành công bằng từng cách: email, GitHub, Google trên cả iOS và Android.
  - [ ] Trên iOS có Sign in with Apple và đăng nhập thành công.
  - [ ] Đăng nhập email: nhập email → nhận mã 6 số → nhập đúng mã thì vào app; mã sai hoặc hết hạn bị từ chối kèm thông báo; không có mật khẩu (D-041).
  - [ ] Thời hạn hiệu lực của mã: theo mặc định của dịch vụ xác thực [GIẢ ĐỊNH].
  - [ ] Đăng xuất xong, mở lại app thì phải đăng nhập lại.
- **Phụ thuộc:** —
- **Trạng thái:** Agreed

### F-002 · Xóa tài khoản (Account deletion)
- **User story:** Là người dùng, tôi muốn tự xóa tài khoản trong app, để dữ liệu của tôi không còn trên hệ thống.
- **Tiêu chí chấp nhận:**
  - Given người dùng đã đăng nhập, When chọn xóa tài khoản và xác nhận, Then hồ sơ, skill, bằng chứng, kết quả phân tích, khoản lương, lượt xác nhận đã cho đều bị xóa.
  - [ ] Sau khi xóa, link hồ sơ công khai trả về "không tồn tại".
  - [ ] Skill của người khác mất lượt xác nhận do người này cho; mức tin cậy được tính lại.
  - [ ] Số liệu lương gộp được tính lại không còn khoản của người này.
- **Phụ thuộc:** F-001
- **Trạng thái:** Agreed

### F-003 · Hồ sơ ứng viên (Candidate profile)
- **User story:** Là ứng viên, tôi muốn có một hồ sơ gồm thông tin cơ bản, skill và bằng chứng, để thể hiện năng lực thật.
- **Tiêu chí chấp nhận:**
  - [ ] Hồ sơ mới tạo ở trạng thái riêng tư: không xuất hiện khi tìm kiếm, link công khai không mở được.
  - [ ] Người dùng bật/tắt "Công khai hồ sơ"; thay đổi có hiệu lực ngay khi tải lại.
  - [ ] Trường cơ bản (D-042): tên hiển thị (bắt buộc), giới thiệu ngắn, thành phố, cấp bậc (cùng danh sách với F-015), mục liên hệ tùy chọn (email hoặc link LinkedIn).
  - [ ] Ảnh đại diện lấy từ tài khoản GitHub/Google; không có chức năng tự tải ảnh lên. Đăng nhập bằng email hoặc Apple thì dùng ảnh mặc định [GIẢ ĐỊNH].
  - [ ] Mục liên hệ chỉ hiện trên hồ sơ công khai khi người dùng bật; mặc định ẩn [GIẢ ĐỊNH].
  - [ ] Giới thiệu ngắn tối đa 300 ký tự (D-044); nhập quá thì không lưu được và hiện số ký tự còn lại.
- **Phụ thuộc:** F-001
- **Trạng thái:** Agreed

### F-004 · Kết nối GitHub (GitHub connection)
- **User story:** Là ứng viên, tôi muốn kết nối GitHub, để repo công khai của tôi làm bằng chứng skill.
- **Tiêu chí chấp nhận:**
  - [ ] Quyền xin GitHub chỉ đủ đọc repo công khai; không xin quyền repo riêng tư.
  - [ ] Repo riêng tư không bao giờ xuất hiện trong danh sách nguồn hay được gửi cho AI.
  - [ ] Người dùng chọn tối đa 10 repo làm bằng chứng (D-045); mặc định chọn sẵn 10 repo công khai cập nhật gần nhất, không tính repo fork; người dùng tự thêm repo fork được.
  - [ ] Chọn repo thứ 11 bị từ chối kèm thông báo; AI chỉ đọc các repo đã chọn.
  - [ ] Người dùng ngắt kết nối được; bằng chứng từ GitHub bị gỡ khỏi hồ sơ.
- **Phụ thuộc:** F-001, F-003
- **Trạng thái:** Agreed

### F-005 · Link bằng chứng (Evidence links)
- **User story:** Là ứng viên, tôi muốn dán link bài viết và sản phẩm đã ship, để chúng cũng là bằng chứng.
- **Tiêu chí chấp nhận:**
  - [ ] Thêm, sửa, xóa link; link không hợp lệ (sai định dạng URL) bị từ chối kèm thông báo.
  - [ ] Mỗi link có loại: bài viết hoặc sản phẩm.
  - [ ] Tối đa 10 link mỗi hồ sơ (D-043); thêm link thứ 11 bị từ chối kèm thông báo.
- **Phụ thuộc:** F-003
- **Trạng thái:** Agreed

### F-006 · Đồng ý dùng AI (AI consent)
- **User story:** Là người dùng, tôi muốn biết rõ AI sẽ đọc gì và đồng ý trước, để kiểm soát dữ liệu của mình.
- **Tiêu chí chấp nhận:**
  - Given chưa đồng ý, When dùng tính năng AI lần đầu, Then hiện màn hình nêu rõ dữ liệu gửi đi (repo công khai, link, mô tả job) và hai nút Đồng ý / Từ chối.
  - [ ] Từ chối: không có dữ liệu nào gửi cho AI; người dùng vẫn tự khai skill được (F-008).
  - [ ] Dữ liệu lương, email, thông tin liên lạc không bao giờ có trong yêu cầu gửi AI (kiểm bằng log yêu cầu ở môi trường thử).
  - [ ] Người dùng rút lại đồng ý được trong cài đặt.
- **Phụ thuộc:** F-001
- **Trạng thái:** Agreed

### F-007 · AI trích skill (AI skill extraction)
- **User story:** Là ứng viên, tôi muốn AI đọc bằng chứng và đề xuất skill, để không phải tự liệt kê.
- **Tiêu chí chấp nhận:**
  - [ ] Phân tích chạy nền: người dùng thoát màn hình/app, khi quay lại vẫn thấy trạng thái đúng (đang chạy / xong / lỗi).
  - [ ] Xong: có dấu báo trong app và danh sách skill đề xuất, mỗi skill kèm nguồn bằng chứng.
  - [ ] Skill đề xuất không hiện trên hồ sơ cho tới khi người dùng duyệt; skill bị bỏ không hiện.
  - [ ] Lỗi (AI hỏng, link không đọc được): hiện thông báo và nút thử lại.
  - [ ] Phân tích có giới hạn thời gian chờ (giá trị cấu hình được, không cần sửa code); quá giới hạn thì chuyển sang trạng thái lỗi kèm nút thử lại, không treo mãi ở "đang chạy" (D-035).
  - [ ] Con số thời gian mục tiêu chốt sau khi đo trong thử nghiệm kín (D-035).
- **Phụ thuộc:** F-004, F-005, F-006, F-018
- **Trạng thái:** Agreed

### F-008 · Tự khai skill (Self-claimed skill)
- **User story:** Là ứng viên, tôi muốn tự thêm skill, để ghi nhận cả những skill chưa có bằng chứng.
- **Tiêu chí chấp nhận:**
  - [ ] Thêm/xóa skill thủ công; skill tự khai hiện mức "tự khai".
  - [ ] Gắn link bài viết hoặc ghi chú vào skill không tự nâng mức. Mức "có bằng chứng" chỉ đến từ tín hiệu commit đủ ngưỡng và một tín hiệu độc lập.
- **Phụ thuộc:** F-003
- **Trạng thái:** Agreed

### F-009 · Mức tin cậy của skill (Skill confidence level)
- **User story:** Là người xem hồ sơ, tôi muốn biết mỗi skill đáng tin tới đâu, để đánh giá đúng ứng viên.
- **Tiêu chí chấp nhận:**
  - [ ] Mỗi skill hiển thị đúng một mức: tự khai, có bằng chứng, được xác nhận.
  - [ ] Có bằng chứng = có hoạt động mã nguồn đáng kể cho skill đó: tín hiệu commit đủ ngưỡng và một tín hiệu độc lập. Không có nghĩa là thành thạo. Link và chữ trong README không đủ.
  - [ ] Mức được tính lại khi bằng chứng hoặc lượt xác nhận thay đổi.
- **Phụ thuộc:** F-007, F-008, F-010
- **Trạng thái:** Agreed

### F-010 · Xác nhận skill (Skill endorsement)
- **User story:** Là người dùng có skill X đã có bằng chứng, tôi muốn xác nhận skill X cho người khác, để tăng độ tin cậy hồ sơ của họ.
- **Tiêu chí chấp nhận:**
  - [ ] Chỉ người có skill X ở mức "có bằng chứng" trở lên mới thấy và dùng được nút xác nhận skill X [GIẢ ĐỊNH].
  - [ ] Không tự xác nhận skill của chính mình; mỗi người xác nhận một skill của một người tối đa 1 lần [GIẢ ĐỊNH].
  - [ ] Mỗi người tối đa 10 lượt xác nhận mỗi tháng (D-031); lượt thứ 11 bị từ chối kèm thông báo. Tính theo tháng dương lịch [GIẢ ĐỊNH].
  - [ ] Người bị chặn (F-013) không xác nhận được.
  - [ ] Người xác nhận rút lại được.
- **Phụ thuộc:** F-009, F-012
- **Trạng thái:** Agreed

### F-011 · Link hồ sơ công khai (Public profile link)
- **User story:** Là ứng viên, tôi muốn gửi link hồ sơ cho nhà tuyển dụng, để họ xem mà không cần cài app.
- **Tiêu chí chấp nhận:**
  - [ ] Hồ sơ công khai mở được trên trình duyệt máy tính và điện thoại, không cần đăng nhập.
  - [ ] Trang hiển thị thông tin cơ bản (F-003), skill, mức tin cậy, link tới bằng chứng, và mục liên hệ nếu chủ hồ sơ đã bật.
  - [ ] Hồ sơ riêng tư hoặc đã xóa: trang báo "không tồn tại", không lộ thông tin.
  - [ ] Trình duyệt đặt tiếng Việt thì trang hiện tiếng Việt; ngôn ngữ khác thì hiện tiếng Anh [GIẢ ĐỊNH: tiếng Anh là mặc định dự phòng]; có nút đổi Việt/Anh (D-033).
  - [ ] Nội dung do chủ hồ sơ viết hiển thị nguyên văn ở cả hai ngôn ngữ.
- **Phụ thuộc:** F-003, F-009
- **Trạng thái:** Agreed

### F-012 · Tìm và xem hồ sơ (Profile discovery)
- **User story:** Là người dùng, tôi muốn tìm hồ sơ công khai theo skill, để tham khảo và xác nhận cho người quen.
- **Tiêu chí chấp nhận:**
  - [ ] Tìm theo tên skill trả về chỉ các hồ sơ công khai có skill đó.
  - [ ] Hồ sơ riêng tư và hồ sơ của người đã chặn mình không xuất hiện.
- **Phụ thuộc:** F-003, F-009
- **Trạng thái:** Agreed

### F-013 · Báo cáo và chặn (Report & block)
- **User story:** Là người dùng, tôi muốn báo cáo hồ sơ vi phạm và chặn người khác, để an toàn khi dùng app.
- **Tiêu chí chấp nhận:**
  - [ ] Báo cáo một hồ sơ kèm lý do; báo cáo được lưu cho quản trị viên.
  - [ ] Chặn: người bị chặn không tìm thấy, không xem được hồ sơ của mình trong app, không xác nhận skill cho mình.
  - [ ] Quản trị viên xem danh sách báo cáo và gỡ hồ sơ qua Supabase Studio, không có màn hình quản trị riêng (D-034).
  - [ ] Hồ sơ bị gỡ không còn xem được ở mọi nơi: tìm kiếm, link công khai, bản lưu khi mất mạng.
- **Phụ thuộc:** F-003, F-012
- **Trạng thái:** Agreed

### F-014 · Phân tích khoảng cách skill (Skill gap analysis)
- **User story:** Là ứng viên, tôi muốn dán mô tả job mục tiêu và biết mình thiếu gì, để biết cần học gì tiếp.
- **Tiêu chí chấp nhận:**
  - Given hồ sơ có skill và người dùng đã đồng ý AI, When dán mô tả job và chạy phân tích, Then nhận danh sách: skill đã có, skill còn thiếu, gợi ý việc nên làm cho mỗi skill thiếu.
  - [ ] Kết quả chỉ chủ tài khoản xem được.
  - [ ] Chạy nền, có thử lại khi lỗi (như F-007).
- **Phụ thuộc:** F-006, F-009, F-018
- **Trạng thái:** Agreed

### F-015 · Lương ẩn danh (Anonymous salary)
- **User story:** Là ứng viên, tôi muốn xem lương theo vai trò, thành phố và cấp bậc, để biết mình đáng được trả bao nhiêu.
- **Tiêu chí chấp nhận:**
  - [ ] Chưa góp lương thì không xem được số liệu lương.
  - [ ] Góp lương gồm đủ 4 trường bắt buộc: vai trò, thành phố, cấp bậc (intern/fresher/junior/middle), lương gộp mỗi tháng bằng VND (D-032); thiếu trường nào thì không lưu được.
  - [ ] Mỗi người một khoản cho mỗi công việc [GIẢ ĐỊNH]; sửa và xóa được khoản của mình.
  - [ ] Một nhóm vai trò + thành phố + cấp bậc chỉ hiện số liệu khi đủ 5 khoản (D-030). Chưa đủ thì hiện "chưa đủ dữ liệu".
  - [ ] Chỉ hiện số liệu gộp (khoảng, trung vị); không ai thấy khoản riêng lẻ hay người khai qua app.
- **Phụ thuộc:** F-001
- **Trạng thái:** Agreed

### F-016 · Đọc khi mất mạng (Offline reading)
- **User story:** Là người dùng, tôi muốn xem lại hồ sơ đã mở khi mất mạng, để không bị gián đoạn.
- **Tiêu chí chấp nhận:**
  - Given đã mở hồ sơ của mình hoặc người khác khi có mạng, When tắt mạng và mở lại, Then vẫn xem được nội dung lần tải gần nhất.
  - [ ] Thao tác cần mạng (lưu, phân tích, góp lương) hiện "không có kết nối" và nút thử lại.
  - [ ] Mọi thao tác chờ mạng hoặc AI hiện trạng thái "đang xử lý"; giao diện vẫn cuộn và bấm được trong lúc chờ (D-035).
  - [ ] Hồ sơ đã bị chuyển riêng tư/gỡ thì bị xóa khỏi bản lưu khi có mạng lại [GIẢ ĐỊNH].
- **Phụ thuộc:** F-003, F-012
- **Trạng thái:** Agreed

### F-017 · Hai ngôn ngữ (Localization)
- **User story:** Là người dùng, tôi muốn dùng app bằng tiếng Việt hoặc tiếng Anh.
- **Tiêu chí chấp nhận:**
  - [ ] Mọi chữ trên giao diện có bản tiếng Việt và tiếng Anh; không còn chuỗi chưa dịch.
  - [ ] Mặc định theo ngôn ngữ máy, đổi được trong cài đặt [GIẢ ĐỊNH].
  - [ ] Nội dung do người dùng viết không bị dịch.
- **Phụ thuộc:** —
- **Trạng thái:** Agreed

### F-018 · Giới hạn dùng AI (AI usage limits)
- **User story:** Là chủ dự án, tôi muốn giới hạn lượt AI mỗi người và tổng chi phí AI mỗi tháng, để không vượt ngân sách.
- **Tiêu chí chấp nhận:**
  - [ ] Mặc định mỗi người mỗi tháng: 3 lượt trích skill (F-007), 10 lượt phân tích khoảng cách (F-014) (D-036).
  - [ ] Hạn mức đổi được từ phía hệ thống, không cần phát hành bản app mới.
  - [ ] Hết lượt: người dùng thấy thông báo và thời điểm có lượt lại; lượt chạy lỗi do hệ thống không bị trừ [GIẢ ĐỊNH].
  - [ ] Chạm trần chi phí tháng: mọi tính năng AI tạm dừng có thông báo, phần còn lại của app vẫn chạy. Trần giai đoạn thử nghiệm kín: 20 USD/tháng (D-037).
  - [ ] Chủ dự án nhận cảnh báo khi chi phí tháng đạt 80% trần (D-037).
- **Phụ thuộc:** —
- **Trạng thái:** Agreed

### F-019 · Khả năng tiếp cận cơ bản (Accessibility baseline)
- **User story:** Là người dùng gặp khó khăn khi nhìn, tôi muốn dùng được app với trình đọc màn hình và chữ lớn.
- **Tiêu chí chấp nhận:**
  - [ ] Mọi nút và ảnh có nhãn đọc được bằng VoiceOver/TalkBack.
  - [ ] Cỡ chữ hệ thống lớn nhất không làm chữ bị cắt hay chồng nhau ở các màn hình Must.
  - [ ] Tương phản chữ/nền ≥ 4.5:1; vùng bấm ≥ 48×48 dp [GIẢ ĐỊNH: lấy theo WCAG và hướng dẫn Material].
- **Phụ thuộc:** —
- **Trạng thái:** Agreed

## Should

### F-020 · Mạng xã hội (Social feed)
- **User story:** Là người dùng, tôi muốn đăng bài, bình luận, thả tim, để giao lưu với cộng đồng.
- **Tiêu chí chấp nhận:** chưa viết, sẽ bổ sung khi đưa vào phạm vi. Bắt buộc kèm báo cáo và chặn nội dung.
- **Phụ thuộc:** F-013
- **Trạng thái:** Draft

### F-021 · Phỏng vấn thử (Mock interview)
- **User story:** Là ứng viên, tôi muốn luyện phỏng vấn với AI theo job mục tiêu, để tự tin hơn.
- **Tiêu chí chấp nhận:** chưa viết.
- **Phụ thuộc:** F-006, F-014, F-018
- **Trạng thái:** Draft

### F-022 · Thông báo đẩy (Push notifications)
- **User story:** Là người dùng, tôi muốn được báo khi có người xác nhận skill hoặc AI phân tích xong.
- **Tiêu chí chấp nhận:** chưa viết.
- **Phụ thuộc:** F-007, F-010
- **Trạng thái:** Draft

## Could

### F-023 · Kết nối Figma và Behance (Figma/Behance connection)
- **User story:** Là ứng viên, tôi muốn gắn Figma/Behance làm bằng chứng.
- **Tiêu chí chấp nhận:** chưa viết.
- **Phụ thuộc:** F-007
- **Trạng thái:** Draft

### F-024 · Gợi ý đàm phán lương (Salary negotiation tips)
- **User story:** Là ứng viên, tôi muốn được gợi ý cách đàm phán lương dựa trên dữ liệu lương.
- **Tiêu chí chấp nhận:** chưa viết.
- **Phụ thuộc:** F-015, F-006
- **Trạng thái:** Draft

## Nháp chờ xác nhận (2026-10-28)

Chưa thuộc bản đã chốt. Chỉ có hiệu lực sau khi chủ dự án xác nhận mục 11 của biên bản yêu cầu.

### F-025 · Ô chat với agent
- **User story:** Là ứng viên, tôi muốn hỏi một agent về skill và tin tuyển dụng của mình, để nhận đề xuất rồi tự quyết định nhận hay bỏ.
- **Tiêu chí chấp nhận:**
  - [ ] Chưa đồng ý phân tích tự động thì không gửi được câu hỏi. Màn đồng ý nói rõ: máy nhà trả lời thì chữ ở trên máy; máy nhà không trả lời thì chữ có thể sang Groq hoặc Z.ai.
  - [ ] Thứ tự hỏi: Ollama trên cùng máy với server, rồi Groq gói miễn phí, rồi Z.ai chỉ model GLM-4.7-Flash. Không gọi model mất phí. Không gọi Together AI.
  - [ ] Gửi đi chỉ có: câu người dùng gõ, tên skill trên hồ sơ, đoạn tin tuyển dụng người dùng dán trong ô chat, tên repo đã chọn, tên file, tên thư viện, và đoạn đầu file giới thiệu công khai. Không gửi lương, email, cách liên hệ.
  - [ ] Agent chỉ tạo đề xuất. Hồ sơ đổi khi người dùng bấm Nhận. Bấm Bỏ thì hồ sơ không đổi. Không bấm hai lần cho cùng một đề xuất.
  - [ ] Cuộc trò chuyện lưu trong tài khoản. Chỉ chủ tài khoản đọc được. Xóa tài khoản thì xóa cuộc trò chuyện.
  - [ ] Mỗi lần Nhận hoặc Bỏ được lưu lại để dùng sau. Bản này không train model.
  - [ ] Cả ba bên không trả lời: một câu và nút Thử lại. Lượt lỗi không bị tính.
  - [ ] Khóa Groq và Z.ai chỉ nằm trong file môi trường trên máy chủ dự án, không nằm trong app, không ghi vào git.
- **Phụ thuộc:** F-001, F-006, F-007, F-014
- **Trạng thái:** Draft, chờ xác nhận

## Chatbot hỏi tài liệu (ADR-0012, đề xuất 2026-10-30)

Không thay F-025. Ô chat cũ vẫn lưu hội thoại và vẫn có thể sang Groq hoặc Z.ai. Bot này chỉ trả lời từ tài liệu trên máy của tác giả.

### F-026 · Hỏi đáp tri thức công khai
- **User story:** Là người dùng, tôi muốn hỏi cách dùng Atom và lộ trình học, để được trả lời từ tài liệu đã duyệt, không từ hồ sơ của tôi.
- **Tiêu chí chấp nhận:**
  - [ ] Một câu hỏi, một câu trả lời. Bot không nhớ câu trước.
  - [ ] Câu trả lời về Atom và lộ trình học lấy từ tài liệu. Không có nguồn thì chỉ thấy câu cố định "chưa có thông tin". Chữ không hiện trước khi biết đã có nguồn.
  - [ ] Không trả lời hồ sơ riêng, lương cụ thể, môn đại học, hay kiến thức ngoài kho.
  - [ ] Không công cụ, không duyệt web, không chuyển sang Groq hay Z.ai. Máy không chạy thì một câu lỗi và thử lại.
  - [ ] Câu trả lời bằng tiếng Việt. Chữ nút trên màn hình, khi có màn hình, vẫn có cả tiếng Việt và tiếng Anh.
- **Phụ thuộc:** F-001, F-028
- **Trạng thái:** Agreed. Chưa có màn hình, chưa có hàm.

### F-027 · Phản hồi câu trả lời
- **User story:** Là người dùng, tôi muốn đánh dấu câu trả lời có ích hay không, và chỉ khi tôi chọn thì mới gửi câu đó cho tác giả.
- **Tiêu chí chấp nhận:**
  - [ ] Nút thích hoặc không thích chỉ lưu kết quả, không lưu nội dung câu hỏi.
  - [ ] "Gửi câu hỏi này cho tác giả" mặc định tắt. Nội dung chỉ đi khi người dùng bật cho đúng câu đó.
  - [ ] Mỗi câu trả lời chỉ gửi phản hồi một lần, và chỉ chủ câu hỏi gửi được.
- **Phụ thuộc:** F-026
- **Trạng thái:** Agreed. Chưa có bảng, chưa có hàm.

### F-028 · Đồng ý hỏi tài liệu
- **User story:** Là người dùng, tôi muốn được hỏi trước khi câu hỏi của tôi vào mô hình chạy trên máy của tác giả.
- **Tiêu chí chấp nhận:**
  - [ ] Chưa đồng ý `doc_chat` thì không hỏi được.
  - [ ] Câu đồng ý nói rõ: câu hỏi được xử lý trên máy của tác giả, không gửi lên dịch vụ chat trên mây.
  - [ ] Đồng ý này không thay câu đồng ý của ô chat cũ và của việc trích skill.
- **Phụ thuộc:** F-001
- **Trạng thái:** Agreed. Chưa có chỗ lưu loại đồng ý này.
