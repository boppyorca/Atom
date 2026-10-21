# Biên bản thống nhất yêu cầu

| | |
|---|---|
| **Tên dự án** | Atom (tên kỹ thuật của project: `harness_app`) |
| **Phiên bản** | 1.0 |
| **Ngày** | 2026-10-22 |
| **Các bên** | Chủ dự án: KUN; Trợ lý: Cursor agent (model Claude Opus 5.5) |
| **Trạng thái** | Đã thống nhất |

## 1. Mục tiêu và phạm vi MVP đã chốt

Mục tiêu: giúp lập trình viên 0–2 năm kinh nghiệm ở Việt Nam chứng minh skill bằng bằng chứng thật. Chi tiết: [IDEA.md](IDEA.md), [FEATURES.md](FEATURES.md).

Tính năng Must: F-001, F-002, F-003, F-004, F-005, F-006, F-007, F-008, F-009, F-010, F-011, F-012, F-013, F-014, F-015, F-016, F-017, F-018, F-019.

## 2. Ngoài phạm vi

- **Should (bản sau):** F-020 Mạng xã hội, F-021 Phỏng vấn thử, F-022 Thông báo đẩy.
- **Could (bản sau):** F-023 Figma/Behance, F-024 Gợi ý đàm phán lương.
- **Won't (bản đầu):** phía nhà tuyển dụng; người dùng là designer; thanh toán; quảng cáo; bản web đầy đủ; bố cục riêng cho máy tính bảng; AI đọc repo riêng tư; xác nhận skill bằng bài kiểm tra.

## 3. Quyết định đã chốt

| Mã | Nội dung | Lý do | Ngày |
|---|---|---|---|
| D-001 | Người dùng chỉ là ứng viên lập trình viên | Tránh bài toán hai phía lúc mới ra mắt | 2026-10-22 |
| D-002 | Vấn đề số một: chứng minh skill bằng bằng chứng | Điểm khác biệt chính; các tính năng khác dựa vào dữ liệu skill | 2026-10-22 |
| D-003 | Nhóm chính: sinh viên, fresher, junior (0–2 năm) | Thiếu kinh nghiệm đi làm, cần bằng chứng nhất | 2026-10-22 |
| D-004 | Hồ sơ dùng để chia sẻ link ra ngoài và hiển thị trong cộng đồng | Có ích ngay khi chưa có nhà tuyển dụng trong app | 2026-10-22 |
| D-005 | Mạng xã hội đầy đủ hạ xuống Should; cộng đồng bản đầu = tìm/xem hồ sơ + xác nhận skill | Giảm phạm vi, bỏ khối kiểm duyệt bài viết | 2026-10-22 |
| D-006 | Thị trường Việt Nam, giao diện tiếng Việt và tiếng Anh | Theo lựa chọn của chủ dự án | 2026-10-22 |
| D-007 | Tần suất bản đầu: theo dịp, vài lần mỗi tuần; mục tiêu hằng ngày khi có mạng xã hội (thay câu trả lời trước là "hằng ngày") | Không có feed thì không có lý do mở hằng ngày | 2026-10-22 |
| D-008 | Đọc được hồ sơ đã xem khi mất mạng | Theo lựa chọn của chủ dự án | 2026-10-22 |
| D-009 | Chỉ điện thoại, màn hình dọc; có trang web xem hồ sơ công khai | Giảm công thiết kế; link phải mở được trên trình duyệt | 2026-10-22 |
| D-010 | Nguồn bằng chứng: GitHub + link tự do; Figma/Behance là Could | Nguồn chính của lập trình viên | 2026-10-22 |
| D-011 | AI đọc GitHub và link, đề xuất skill, người dùng duyệt trước khi hiện | Tránh AI gán nhầm skill | 2026-10-22 |
| D-012 | Mức "được xác nhận" do người dùng khác xác nhận, có điều kiện chống lạm dụng | Hợp với tính cộng đồng | 2026-10-22 |
| D-013 | Copilot: phân tích khoảng cách Must, phỏng vấn thử Should, đàm phán lương Could | Dùng ngay dữ liệu skill sẵn có | 2026-10-22 |
| D-014 | Lương ẩn danh Must, "góp để xem", có ngưỡng tối thiểu | Giải bài toán thiếu dữ liệu và bảo vệ ẩn danh | 2026-10-22 |
| D-015 | Đăng nhập: email, GitHub, Google; thêm Sign in with Apple trên iOS | Linh hoạt; đáp ứng quy định App Store | 2026-10-22 |
| D-016 | Hồ sơ mặc định riêng tư | Tránh lộ dữ liệu chưa duyệt | 2026-10-22 |
| D-017 | AI chỉ đọc repo công khai | Quyền tối thiểu; người xem kiểm chứng được bằng chứng | 2026-10-22 |
| D-018 | Lương gắn tài khoản ở phía hệ thống, chỉ hiện số liệu gộp, người dùng xóa được | Cần để áp dụng "góp để xem" | 2026-10-22 |
| D-019 | Xóa tài khoản xóa toàn bộ dữ liệu, kể cả lương và lượt xác nhận đã cho | Rõ ràng cho người dùng | 2026-10-22 |
| D-020 | Hỏi đồng ý riêng trước khi dùng AI; không gửi lương/liên lạc cho AI | Minh bạch, quyền riêng tư | 2026-10-22 |
| D-021 | AI chạy nền, có dấu báo trong app và nút thử lại | Phân tích có thể lâu | 2026-10-22 |
| D-022 | Khả năng tiếp cận mức cơ bản | Rẻ nếu làm từ đầu | 2026-10-22 |
| D-023 | Có báo cáo hồ sơ, chặn người dùng, quản trị viên gỡ hồ sơ | Nội dung do người dùng tạo; quy định store | 2026-10-22 |
| D-024 | Thử nghiệm kín iOS + Android, rồi phát hành công khai ở Việt Nam | Phát hiện lỗi và kiểm chứng giả định sớm | 2026-10-22 |
| D-025 | Miễn phí hoàn toàn, có giới hạn lượt AI mỗi người | Ưu tiên người dùng; kiểm soát chi phí | 2026-10-22 |
| D-026 | Một người + AI agent, khoảng 3 tháng; giữ nguyên toàn bộ Must, chấp nhận rủi ro | Theo lựa chọn của chủ dự án | 2026-10-22 |
| D-027 | Ngân sách gần như 0, có trần chi phí AI mỗi tháng | Theo lựa chọn của chủ dự án | 2026-10-22 |
| D-028 | Chỉ số chính: tỷ lệ kích hoạt | Đo trực tiếp vấn đề số một | 2026-10-22 |
| D-029 | Tiêu chí hoàn thành MVP theo mục 7 | Kiểm chứng được, không phụ thuộc hành vi người dùng | 2026-10-22 |
| D-030 | Ngưỡng hiện số liệu lương: tối thiểu 5 khoản mỗi nhóm vai trò + thành phố + cấp bậc (trả lời Q-001, nhóm cập nhật theo D-032) | Cân bằng ẩn danh và tốc độ có dữ liệu | 2026-10-22 |
| D-031 | Mỗi người tối đa 10 lượt xác nhận skill mỗi tháng (trả lời Q-002) | Chống xác nhận chéo hàng loạt | 2026-10-22 |
| D-032 | Khai lương gồm: vai trò, thành phố, cấp bậc (intern/fresher/junior/middle), lương gộp mỗi tháng (VND); số liệu nhóm theo vai trò + thành phố + cấp bậc (trả lời Q-003) | Con số so được với nhau; cấp bậc là điều junior quan tâm nhất | 2026-10-22 |
| D-033 | Trang hồ sơ công khai hiển thị theo ngôn ngữ trình duyệt người xem, có nút đổi Việt/Anh (trả lời Q-004) | Phục vụ cả nhà tuyển dụng Việt và nước ngoài | 2026-10-22 |
| D-034 | Quản trị viên xử lý báo cáo qua Supabase Studio, không làm màn hình quản trị riêng (trả lời Q-005) | Không tốn công giao diện, hợp ngân sách và thời gian | 2026-10-22 |
| D-035 | Bản đầu không đặt con số thời gian phản hồi; dùng tiêu chí hành vi (không đơ, luôn có trạng thái, AI có giới hạn chờ cấu hình được); con số chốt sau đo trong thử nghiệm kín (trả lời Q-006) | Chưa có số đo thật, tránh bịa số | 2026-10-22 |
| D-036 | Hạn mức AI mặc định mỗi người mỗi tháng: 3 lượt trích skill, 10 lượt phân tích khoảng cách; chỉnh được từ phía hệ thống (trả lời Q-007) | Điểm xuất phát, chỉnh theo chi phí thật | 2026-10-22 |
| D-037 | Trần chi phí AI giai đoạn thử nghiệm kín: 20 USD/tháng, cảnh báo chủ dự án ở 80% (trả lời Q-008) | Đủ để đo chi phí thật mỗi lượt | 2026-10-22 |
| D-038 | Hỗ trợ tối thiểu iOS 15.0 và Android 7.0 (API 24), theo mặc định Flutter 3.47 (trả lời Q-009) | Không tốn thêm công, phủ cả máy Android đời cũ | 2026-10-22 |
| D-039 | Thử nghiệm kín khoảng 20 người (trả lời Q-010) | Một người hỗ trợ được | 2026-10-22 |
| D-040 | Mục tiêu kích hoạt thử nghiệm kín: ≥ 50% (10/20) trong 7 ngày đầu sau khi cài; là chỉ số thành công, không thuộc tiêu chí hoàn thành MVP (trả lời Q-011) | Người được mời có động lực; dưới mức này là luồng tạo hồ sơ có vấn đề | 2026-10-22 |
| D-041 | Đăng nhập email bằng mã 6 số gửi qua email, không mật khẩu (trả lời Q-012) | Dùng được khi đọc email trên máy khác; không cần luồng quên mật khẩu | 2026-10-22 |
| D-042 | Hồ sơ gồm: tên hiển thị (bắt buộc), giới thiệu ngắn, thành phố, cấp bậc, mục liên hệ tùy chọn (email/LinkedIn); ảnh lấy từ GitHub/Google, không tự tải ảnh (trả lời Q-013) | Khớp cách nhóm lương; bớt rủi ro ảnh vi phạm; nhà tuyển dụng có cách liên hệ | 2026-10-22 |
| D-043 | Tối đa 10 link bằng chứng mỗi hồ sơ (trả lời Q-014) | Giữ chi phí mỗi lượt trích skill dễ đoán | 2026-10-22 |
| D-044 | Giới thiệu ngắn tối đa 300 ký tự (trả lời Q-016) | Gọn, trang công khai dễ đọc, không lấn át bằng chứng | 2026-10-22 |
| D-045 | Người dùng tự chọn tối đa 10 repo công khai làm bằng chứng; mặc định chọn sẵn 10 repo gần nhất, bỏ fork (trả lời Q-017) | Chi phí dễ đoán; người dùng biết repo nào thể hiện mình | 2026-10-22 |
| D-046 | Tên sản phẩm: Atom (trả lời Q-015) | Chủ dự án chọn | 2026-10-22 |

## 4. Giả định chưa kiểm chứng

| Mã | Nội dung | Cách kiểm chứng |
|---|---|---|
| A-001 | Nhà tuyển dụng sẵn lòng mở link hồ sơ thay vì chỉ đọc CV | Hỏi 3–5 nhà tuyển dụng khi thử nghiệm kín |
| A-002 | App Store quy định 4.8 bắt buộc Sign in with Apple khi có đăng nhập Google/GitHub | Đối chiếu App Review Guidelines hiện hành trước khi gửi duyệt |
| A-003 | Nghị định 13/2023/NĐ-CP là khung pháp lý về dữ liệu cá nhân áp dụng | Tham khảo văn bản hiện hành hoặc người có chuyên môn pháp lý |
| A-004 | Người xác nhận skill phải tự có skill đó ở mức "có bằng chứng" là đủ chống lạm dụng | Theo dõi tỷ lệ xác nhận chéo bất thường khi thử nghiệm kín |
| A-005 | Lên mức "được xác nhận" chỉ cần 1 lượt xác nhận hợp lệ | Chủ dự án chốt khi rà soát |
| A-006 | Mỗi người một xác nhận cho một skill của một người | Chủ dự án chốt khi rà soát |
| A-007 | Mỗi người một khoản lương cho mỗi công việc | Chủ dự án chốt khi rà soát |
| A-008 | Lương tính bằng VND, chia theo thành phố Việt Nam | Chủ dự án chốt khi rà soát |
| A-009 | Gắn bằng chứng thủ công vào skill tự khai đủ để lên mức "có bằng chứng" | Chủ dự án chốt khi rà soát |
| A-010 | Nội dung người dùng viết không được dịch tự động | Chủ dự án chốt khi rà soát |
| A-011 | Ngôn ngữ mặc định theo máy, đổi được trong cài đặt | Chủ dự án chốt khi rà soát |
| A-012 | Bản lưu khi mất mạng bị xóa khi hồ sơ chuyển riêng tư/bị gỡ | Chủ dự án chốt khi rà soát |
| A-013 | Quản trị viên duy nhất là chủ dự án | Chủ dự án chốt khi rà soát |
| A-014 | Ngưỡng tiếp cận: tương phản ≥ 4.5:1, vùng bấm ≥ 48×48 dp | Đối chiếu WCAG 2.1 và hướng dẫn Material/Apple |
| A-015 | Cần tài khoản Apple Developer và Google Play Console, khai báo quyền riêng tư trên cả hai store | Kiểm tra khi đăng ký tài khoản |
| A-016 | Persona Minh và Lan đại diện đúng người dùng | Phỏng vấn 5 người dùng thật trước khi làm |
| A-017 | Hạn mức 10 lượt xác nhận tính theo tháng dương lịch (không phải 30 ngày trượt) | Chủ dự án chốt khi rà soát |
| A-018 | Trang hồ sơ công khai dùng tiếng Anh khi trình duyệt không đặt tiếng Việt | Chủ dự án chốt khi rà soát |
| A-019 | Lượt AI chạy lỗi do hệ thống không bị trừ vào hạn mức | Chủ dự án chốt khi rà soát |
| A-020 | Hạn mức AI tính theo tháng dương lịch, giống A-017 | Chủ dự án chốt khi rà soát |
| A-021 | iOS 15+ và Android 7.0+ phủ gần hết máy của người dùng mục tiêu ở Việt Nam | Xem thống kê phiên bản hệ điều hành của người thử nghiệm kín |
| A-022 | Tỷ lệ kích hoạt đo được từ dữ liệu sẵn có của hệ thống (thời điểm tạo tài khoản, nối GitHub, duyệt skill, bật công khai), không cần công cụ phân tích hành vi bên ngoài | Chủ dự án chốt khi rà soát |
| A-023 | Thời hạn hiệu lực của mã đăng nhập email theo mặc định của dịch vụ xác thực | Chủ dự án chốt khi rà soát |
| A-024 | Người đăng nhập bằng email hoặc Apple dùng ảnh đại diện mặc định | Chủ dự án chốt khi rà soát |
| A-025 | Mục liên hệ mặc định ẩn, người dùng tự bật | Chủ dự án chốt khi rà soát |
| A-026 | Tên "Atom" dùng được trên App Store và Google Play (chưa bị app khác dùng, không vướng nhãn hiệu) | Tra cứu tên trên hai store và cơ sở dữ liệu nhãn hiệu trước khi gửi duyệt |
| A-027 | Gỡ hồ sơ vi phạm chỉ đổi trạng thái (không xóa) và ghi lại ai gỡ, khi nào (cách giảm R-008) | Chủ dự án chốt khi rà soát |

## 5. Câu hỏi mở

| Mã | Câu hỏi | Ai trả lời | Hạn |
|---|---|---|---|
| Q-001 | ~~Ngưỡng tối thiểu N khoản để hiện số liệu lương của một nhóm?~~ Đã trả lời → D-030 | Chủ dự án | Đã đóng |
| Q-002 | ~~Giới hạn số lượt xác nhận skill mỗi người?~~ Đã trả lời → D-031 | Chủ dự án | Đã đóng |
| Q-003 | ~~Trường thông tin khi khai lương?~~ Đã trả lời → D-032 | Chủ dự án | Đã đóng |
| Q-004 | ~~Trang hồ sơ công khai có cần hai ngôn ngữ?~~ Đã trả lời → D-033 | Chủ dự án | Đã đóng |
| Q-005 | ~~Quản trị viên xử lý báo cáo ở đâu?~~ Đã trả lời → D-034 | Chủ dự án | Đã đóng |
| Q-006 | Con số thời gian phản hồi mục tiêu của app và của AI (tiêu chí hành vi đã chốt ở D-035)? | Chủ dự án, sau khi đo trong thử nghiệm kín | Sau thử nghiệm kín; không chặn v1.0 |
| Q-007 | ~~Hạn mức lượt AI mỗi người?~~ Đã trả lời → D-036 | Chủ dự án | Đã đóng |
| Q-008 | Trần chi phí AI khi phát hành công khai (trần thử nghiệm kín đã chốt ở D-037)? | Chủ dự án | Trước phát hành công khai; không chặn v1.0 |
| Q-009 | ~~Phiên bản iOS/Android tối thiểu?~~ Đã trả lời → D-038 | Chủ dự án | Đã đóng |
| Q-010 | ~~Số người tham gia thử nghiệm kín?~~ Đã trả lời → D-039 | Chủ dự án | Đã đóng |
| Q-011 | ~~Mục tiêu tỷ lệ kích hoạt và khung thời gian đo?~~ Đã trả lời → D-040 | Chủ dự án | Đã đóng |
| Q-012 | ~~Đăng nhập email dùng mã hay link?~~ Đã trả lời → D-041 | Chủ dự án | Đã đóng |
| Q-013 | ~~Hồ sơ gồm những trường thông tin cơ bản nào?~~ Đã trả lời → D-042 | Chủ dự án | Đã đóng |
| Q-014 | ~~Số link bằng chứng tối đa mỗi hồ sơ?~~ Đã trả lời → D-043 | Chủ dự án | Đã đóng |
| Q-015 | ~~Tên sản phẩm chính thức?~~ Đã trả lời → D-046 | Chủ dự án | Đã đóng |
| Q-016 | ~~Độ dài tối đa của giới thiệu ngắn trên hồ sơ?~~ Đã trả lời → D-044 | Chủ dự án | Đã đóng |
| Q-017 | ~~Mỗi lượt trích skill, AI đọc tối đa bao nhiêu repo GitHub công khai?~~ Đã trả lời → D-045 | Chủ dự án | Đã đóng |

## 6. Rủi ro chính

| Mã | Mô tả | Ảnh hưởng | Cách giảm |
|---|---|---|---|
| R-001 | Phạm vi Must lớn so với 3 tháng một người | Trễ hạn, chất lượng thấp | Phương án dự phòng: hạ F-016 và đăng nhập Google xuống Should; sau đó cân nhắc chỉ tiếng Việt |
| R-002 | Lúc ra mắt chưa đủ dữ liệu lương; với 20 người thử nghiệm và nhóm theo vai trò + thành phố + cấp bậc, nhiều khả năng không nhóm nào đủ 5 khoản | Tính năng lương trống, mất sức kéo; không kiểm chứng được giá trị thật của F-015 trong thử nghiệm kín | "Góp để xem"; hiện "chưa đủ dữ liệu" thay vì số sai; kiểm tra tiêu chí F-015 bằng dữ liệu thử |
| R-003 | Xác nhận skill bị lạm dụng (xác nhận chéo) | Mất uy tín mức "được xác nhận" | Điều kiện người xác nhận (A-004), giới hạn lượt (Q-002) |
| R-004 | Chi phí AI vượt ngân sách | Phải dừng AI | Giới hạn lượt (F-018), trần chi phí tháng |
| R-005 | Bị từ chối khi duyệt app | Trễ phát hành | Sign in with Apple, báo cáo/chặn, xóa tài khoản trong app |
| R-006 | AI trích skill sai | Hồ sơ không đáng tin | Người dùng duyệt trước khi hiện (F-007) |
| R-007 | Lộ danh tính qua dữ liệu lương | Mất niềm tin, rủi ro pháp lý | Ngưỡng tối thiểu, chỉ số liệu gộp, không gửi lương cho AI |
| R-008 | Thao tác nhầm khi gỡ hồ sơ trực tiếp trên bảng dữ liệu (Supabase Studio) | Gỡ nhầm hoặc sửa nhầm dữ liệu người dùng | Chỉ đổi trạng thái hồ sơ, không xóa; ghi lại ai gỡ và khi nào [GIẢ ĐỊNH] |

## 7. Tiêu chí hoàn thành MVP

- [ ] Mọi tính năng Must (mục 1) đạt toàn bộ tiêu chí chấp nhận trong [FEATURES.md](FEATURES.md).
- [ ] `make check` và `make check-db` đều xanh.
- [ ] Có bản thử nghiệm kín cài được trên TestFlight và kênh thử nghiệm nội bộ Google Play.
- [ ] Luồng xóa tài khoản (F-002) và đồng ý dùng AI (F-006) đã được kiểm thử.
- [ ] Trần chi phí AI đã được cấu hình (F-018).

## 8. Quy tắc thay đổi yêu cầu

Sau khi thống nhất (phiên bản 1.0), mọi thay đổi được ghi vào mục 10 kèm lý do, tác động và người duyệt. Không sửa mục 1–7 mà không ghi vào mục 10.

## 9. Xác nhận của chủ dự án

> tôi đồng ý biên bản yêu cầu v1.0

KUN, 2026-10-22

## 10. Lịch sử phiên bản và thay đổi

| Phiên bản | Ngày | Thay đổi | Lý do | Tác động | Người duyệt |
|---|---|---|---|---|---|
| Nháp 0.1 | 2026-10-22 | Bản nháp đầu từ phỏng vấn Giai đoạn A | — | — | — |
| Nháp 0.1 (rà soát) | 2026-10-22 | Trả lời Q-001 → Q-017 (D-030 → D-046); thêm A-017 → A-027, R-008; Q-006, Q-008 thu hẹp, không chặn v1.0 | Giai đoạn C | Tiêu chí Must không còn [MỞ] | KUN |
| 1.0 | 2026-10-22 | Chốt biên bản; F-001 → F-019 chuyển Agreed; F-020 → F-024 giữ Draft | Chủ dự án xác nhận | Từ đây mọi thay đổi ghi vào mục này | KUN |
