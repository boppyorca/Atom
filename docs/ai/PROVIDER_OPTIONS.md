# Các cách chạy mô hình — Bản nháp

**Trạng thái: Draft.** Ngày 2026-10-23. Người soạn: Grok 4.7.

Không chọn nhà cung cấp. Mỗi ô chưa đọc được nguồn cho đúng phiên bản thì để `[CHƯA XÁC MINH]`.

Ba cách:

- **A.** API do bên khác chạy (dữ liệu rời máy bạn).
- **B.** Tự thuê máy GPU và chạy mô hình mở.
- **C.** Chạy trên máy của bạn, không gọi ra ngoài.

Một mô hình đóng (hãng không mở trọng số) chỉ đi được cách A. `[MỞ]` Hãng nào. Giá cách A của mô hình đóng: `[CHƯA XÁC MINH]` — buổi này không chép bảng giá từ trí nhớ.

## Giấy phép đã đọc được

| Mô hình | Nguồn đã mở | Giấy phép ghi trên nguồn đó | Chỗ chưa chắc |
|---|---|---|---|
| Gemma 4 (cả họ) | [Google Open Source Blog, 2026-03](https://opensource.googleblog.com/2026/03/gemma-4-expanding-the-gemmaverse-with-apache-20.html) | Bài viết nói Gemma 4 là bản Gemma đầu dùng Apache 2.0 | Trang model card đã tải không chứa dòng “License” trong phần chữ trích được. `[CHƯA XÁC MINH]` từng file trọng số |
| Qwen2.5-1.5B | [LICENSE trên Hugging Face](https://huggingface.co/Qwen/Qwen2.5-1.5B/blob/main/LICENSE) | Apache 2.0 cho đúng repo này | [Blog Qwen 2024-09-19](https://qwenlm.github.io/blog/qwen2.5/) nói mọi bản mở **trừ 3B và 72B** là Apache 2.0. Bản khác và đời sau: `[CHƯA XÁC MINH]` |
| DeepSeek-V4-Pro và V4-Flash, bản mở | [Model card PDF](https://fe-static.deepseek.com/chat/transparency/deepseek-V4-model-card-EN.pdf), [Hugging Face V4-Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro) | MIT cho trọng số và mã mở | API không theo MIT. API theo điều khoản Open Platform, chưa đọc hết trong buổi này |
| Mô hình đóng | — | `[MỞ]` | `[CHƯA XÁC MINH]` |

## Nơi xử lý dữ liệu và cửa hàng ứng dụng

| Cách | Dữ liệu người dùng | Khai báo cửa hàng |
|---|---|---|
| A, bất kỳ hãng nào | Rời máy tới hãng đó | Apple [mục 5.1.2(i)](https://developer.apple.com/app-store/review/guidelines/) (bản hướng dẫn đang đăng; tin [2025](https://developer.apple.com/news/?id=ey6d8onl) nói mục này được làm rõ cho AI bên thứ ba): phải nói rõ chia sẻ cho ai, kể cả AI bên thứ ba, và xin phép trước. Google Play [User Data](https://support.google.com/googleplay/android-developer/answer/10144311) và [thông báo 2026-07-15](https://support.google.com/googleplay/android-developer/answer/17134731): chính sách dữ liệu áp dụng cho AI bên thứ ba. Không phải tư vấn pháp lý. |
| A, API DeepSeek | `[CHƯA XÁC MINH]` máy chủ nào xử lý nội dung API | Chính sách riêng tư DeepSeek cập nhật 2026-02-10 nói dữ liệu của **ứng dụng DeepSeek** được lưu ở Trung Quốc, và **không** chi phối dữ liệu người dùng cuối của ứng dụng bên thứ ba dùng nền tảng mở. Nhà phát triển phải tự công bố. Nguồn: [privacy policy](https://cdn.deepseek.com/policies/en-US/deepseek-privacy-policy.html). Không kết luận API đặt ở Trung Quốc chỉ từ trang này. |
| B hoặc C | Không gửi nội dung cho hãng mô hình | Vẫn có thể phải khai nếu còn gửi dữ liệu cho GitHub hoặc server của chính bạn. `[MỞ]` câu chữ trên store. |

Tiếng Việt của từng mô hình: `[CHƯA XÁC MINH]`. Chỉ bộ ví dụ của dự án, do bạn gắn nhãn, mới được quyết định.

## Rủi ro ngắn

- A: khóa API, tiền theo token, chữ repo ra ngoài, phải sửa màn đồng ý đang nói “không gửi cho công ty AI”.
- B: tiền máy chạy suốt. Ngưỡng “300–350 đô một tháng” trong bối cảnh nghiên cứu là `[GIẢ ĐỊNH]` của người viết bối cảnh, **chưa** được kiểm bằng báo giá. Không dùng số đó để quyết định.
- C: máy bạn phải đủ mạnh. Gemma 4 có bản nhỏ; DeepSeek-V4-Pro khoảng 1,6 nghìn tỷ tham số theo model card — không phải bản để chạy trên điện thoại. `[CHƯA XÁC MINH]` bản nào chạy được trên máy bạn.

Giá API DeepSeek đã đọc ngày 2026-10-23 nằm ở [COST_MODEL.md](COST_MODEL.md). Giá Gemma API, Qwen API, và mô hình đóng: `[CHƯA XÁC MINH]`.
