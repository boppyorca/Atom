# ADR-0010 · Trích skill và phân tích khoảng cách bằng bộ quy tắc tự xây (không dùng nhà cung cấp AI)

- **Trạng thái:** Được chấp nhận · 2026-10-22 · **Thay thế** phần 8b của [ADR-0009](0009-packages-and-ai-client.md).
- **Truy vết:** F-006, F-007, F-014, F-018; D-037 (trần chi phí), R-004, R-006.

## Bối cảnh

Chủ dự án muốn tự xây "model cơ bản" thay vì gọi nhà cung cấp AI. Đã tra (2026-10-22):
- OpenAI đang đóng nền tảng tinh chỉnh model; tài khoản mới không dùng được (trang Pricing của OpenAI).
- Tự chạy model trên Hugging Face Inference Endpoints: GPU nhỏ nhất 0,5 USD/giờ (~365 USD/tháng nếu chạy liên tục), CPU nhỏ nhất 0,033 USD/giờ (~24 USD/tháng); đều vượt trần 20 USD/tháng (D-037).
- Edge Function: 256 MB bộ nhớ, 2 giây CPU mỗi yêu cầu → không chạy được model ngôn ngữ bên trong.
- Chưa có dữ liệu đã gán nhãn để huấn luyện.

## Phương án đã cân nhắc

| Phương án | Chi phí/tháng | Ưu | Nhược |
|---|---|---|---|
| **A. Bộ quy tắc + từ điển skill tự xây, chạy trong Edge Function; thu dữ liệu duyệt để huấn luyện sau** | 0 USD | Không gửi dữ liệu cho bên thứ ba; dễ test; chạy được trong giới hạn Edge Function | Chỉ nhận skill có dấu hiệu rõ (ngôn ngữ, thư viện, từ khóa); gợi ý cho skill thiếu là câu soạn sẵn |
| B. Tinh chỉnh model mã nguồn mở, tự host | ~24–365 USD | Model "của mình" | Vượt trần; chưa có dữ liệu; nhiều tuần làm việc chuyên môn học máy |
| C. Nhà cung cấp AI (Claude Haiku 5.5: 0,10/0,50 USD mỗi triệu token) | < 1 USD (ước tính) | Chất lượng tốt nhất | Gửi dữ liệu cho bên thứ ba; không phải model tự xây |

## Quyết định

Chọn **A** (chủ dự án chọn ngày 2026-10-22).
- Từ điển skill là file `supabase/functions/_shared/skill_dictionary.json` nằm trong repo (có test), gồm cho mỗi skill: tên chuẩn, tên gọi khác, dấu hiệu (ngôn ngữ GitHub, tên thư viện theo hệ sinh thái, chủ đề, từ khóa) và câu gợi ý tiếng Việt/tiếng Anh. Khoảng 150 skill ban đầu [GIẢ ĐỊNH].
- Trích skill: [ALGORITHMS.md § ALG-08](../design/ALGORITHMS.md#alg-08--trích-skill-bằng-quy-tắc-f-007). Phân tích khoảng cách: [§ ALG-09](../design/ALGORITHMS.md#alg-09--phân-tích-khoảng-cách-skill-bằng-từ-điển-f-014).
- Vẫn giữ: màn đồng ý (F-006), chạy nền + trạng thái + thử lại + thời gian chờ (F-007, D-035), duyệt đề xuất trước khi hiện, hạn mức lượt mỗi tháng (F-018).
- Mỗi đề xuất ghi lại dấu hiệu đã dùng (`skill_suggestions.signals`) và kết quả duyệt; đây là dữ liệu để đo độ chính xác và **huấn luyện một bộ phân loại nhỏ về sau** (ADR mới khi đó, kèm xin đồng ý dùng dữ liệu).

## Hệ quả

- Không có khóa API AI, không có chi phí theo token. Các cột/bảng chỉ phục vụ tính chi phí (token, `cost_usd`, giá token, `admin_alerts`) **bị bỏ** khỏi DATA_MODEL v1.0 (không thêm "phòng khi cần"). Nếu sau này chuyển sang C, thêm lại bằng ADR mới.
- Hai tiêu chí chi phí của F-018 (tạm dừng khi chạm trần, cảnh báo 80%) luôn được thỏa vì chi phí bằng 0; không có cơ chế riêng.
- Chất lượng thấp hơn AI lớn (R-006): giảm bớt nhờ người dùng duyệt từng đề xuất và nhờ đo tỷ lệ chấp nhận trong thử nghiệm kín.
- Cần thêm lượt gọi GitHub (cây thư mục gốc, file khai báo thư viện) → vẫn cần token GitHub phía server (ADR-0006).

## Lệch với tài liệu yêu cầu v1.0 (cần chủ dự án xử lý ngoài phạm vi thiết kế)

FEATURES.md, GLOSSARY.md, REQUIREMENTS_AGREEMENT.md v1.0 gọi tính năng là "AI" và nói "dữ liệu gửi cho AI". Với ADR này, xử lý do Atom tự làm, không gửi cho bên thứ ba. Mọi tiêu chí chấp nhận vẫn đạt được; chỉ cách gọi và D-037 (trần chi phí AI) trở nên không còn tác dụng. Thiết kế giữ nguyên tên mã `ai_*` theo GLOSSARY. Đề xuất: cập nhật tài liệu yêu cầu lên v1.1 trong một nhiệm vụ riêng (không sửa trong nhiệm vụ thiết kế này).

## Nguồn (tra 2026-10-22)

- OpenAI, "Pricing" (platform.openai.com/docs/pricing): mục fine-tuning đang ngừng.
- Hugging Face, "Inference Endpoints › Pricing".
- Anthropic, "Pricing" và "Is my data used for model training?".
- Google, "Gemini Developer API pricing".
- Supabase docs, "Edge Functions › Limits".
