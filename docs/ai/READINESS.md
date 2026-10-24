# Độ sẵn sàng để thêm gọi LLM qua Edge Function — Bản nháp

**Trạng thái: Draft.** Ngày chạy: 2026-10-23. Người soạn: Grok 4.7.

## Phán quyết

**CHƯA SẴN SÀNG** để thêm ô chat gọi LLM qua Supabase Edge Function.

Ngày 2026-10-25 bạn thêm: muốn cả ô chat, 8.000 token, chữ ở lại máy, ưu tiên 0 đồng, và còn token Gemini hoặc ZCode. Token đó chỉ dùng được khi chữ rời máy. Chưa chọn cách nào trong ba cách của AI_SPEC. Vì vậy cổng T-AI-00 vẫn đóng.

Lý do ngắn:

1. ADR-0010 đang Accepted: bộ từ khóa, không gọi hãng AI. Màn đồng ý đang có câu “Không gửi cho công ty AI nào.”
2. Chưa có thư mục `supabase/functions/`. Máy không có lệnh `deno`.
3. Việc “gọi LLM” chưa được mô tả thành một tính năng. Việc đã chốt là tìm skill bằng các bước cố định.
4. `.cursorignore` không có. Git thì đã chặn file env.
5. Chuỗi “hết hạn mức / 502 / 504” chưa có trong file ngôn ngữ.

App vẫn sẵn sàng để tiếp tục ticket bộ từ khóa (05, rồi 06, rồi 15). Đó là đường khác.

## Kết quả lệnh, 2026-10-23

Flutter 3.47.7. Dart 3.13.5. Supabase CLI 2.121.0. Docker 29.2.1, đang chạy. `deno --version`: `command not found`.

`make check`:

- `dart format --set-exit-if-changed .` — Formatted 72 files (0 changed)
- `flutter analyze` — `No issues found! (ran in 3.3s)`
- `flutter test` — `00:16 +71: All tests passed!`

`make check-db`:

- Reset xong, gồm migration `20261023160000_ai_consents.sql`
- `ai_consents_rls_test.sql` ok
- `profiles_rls_test.sql` ok
- `Files=9, Tests=77`
- `Result: PASS`

## Bảng kiểm

| # | Mục | Kết quả | Bằng chứng |
|---|---|---|---|
| 1 | `make check` và `make check-db`; test RLS hồ sơ | OK | Kết quả lệnh ở trên. `supabase/tests/profiles_rls_test.sql` dòng 2: `plan(15)`, file ok. Thêm `ai_consents_rls_test.sql` ok |
| 2 | `supabase_flutter` và phiên đăng nhập | OK cho phiên hiện có. Chưa có lời gọi hàm | `pubspec.yaml` dòng 41: `supabase_flutter: ^2.18.3`. `lib/data/services/supabase_service.dart` dòng 8: `currentSession`. Không thấy `functions.invoke` |
| 3 | Thư mục hàm và `verify_jwt` | CẦN SỬA trước khi có hàm. Không chặn app hôm nay | Không có `supabase/functions/`. `config.toml` có `[edge_runtime]` dòng 384, không có khối `[functions.…]`. Tài liệu Supabase: mặc định `verify_jwt` = true ([CLI config](https://supabase.com/docs/guides/local-development/cli/config)). Khi thêm hàm phải ghi tường minh `verify_jwt = true` |
| 4 | Git và Cursor có chặn file env không | Git: OK. Cursor: CẦN SỬA | `.gitignore` dòng 56 `.env*` và dòng 67 `supabase/.env*`. Không có file `.cursorignore` |
| 5 | Deno để test hàm | CHẶN nếu ticket đòi `deno test` ngay | `deno` không có trên máy. Phương án trong ADR-0013. Chưa cài |
| 6 | Màn đồng ý và chỗ tắt / xóa dữ liệu AI | CẦN SỬA nếu gọi hãng AI. Ổn cho bộ từ khóa | Màn S-08 và công tắc Cài đặt đã có. Câu `analysisNoCompany` trong `lib/l10n/app_vi.arb` dòng 108. Xóa tài khoản là ticket 17, chưa làm. `[MỞ]` xóa riêng lịch sử phân tích |
| 7 | Chuỗi lỗi vi/en cho AI | CẦN SỬA trước UI gọi mô hình | Có “Không có kết nối” và “Có lỗi, thử lại”. Chưa có câu hết hạn mức, 502, 504, đang chờ |
| 8 | Thiết kế đã nói tới AI chưa | OK theo bộ từ khóa. CẦN ADR mới nếu đổi sang LLM | ADR-0010, `docs/design/ALGORITHMS.md` ALG-08. Không sửa tài liệu yêu cầu v1.0 trong buổi này |
| 9 | Hàm `security definer` thiếu `search_path` | OK với hàm hiện có | `handle_new_user`: `search_path = ''` trong `20261022120000_create_profiles.sql` dòng 39–40. `get_salary_aggregate`: `security definer` và `search_path = public` trong `20261023150000_salary.sql` dòng 94–95. Hàm hạn mức mới vẫn phải đặt `search_path` cố định |
| 10 | AGENTS.md đủ luật AI và còn ngắn | CẦN SỬA sau khi bạn duyệt dòng thêm | File 53 dòng. Luật 1–6 chưa nói eval, khóa LLM, hay `service_role` trong công cụ agent. Đề xuất bên dưới. Chưa sửa file |

## Giới hạn Edge Function đã đọc lại

Nguồn [Limits](https://supabase.com/docs/guides/functions/limits), đọc 2026-10-23:

- Bộ nhớ tối đa: 256 MB
- Wall clock: 150 giây gói miễn phí, 400 giây gói trả phí
- CPU: 2 giây mỗi yêu cầu, không tính I/O bất đồng bộ
- Request idle timeout: 150 giây thì 504

Trang [546](https://supabase.com/docs/guides/troubleshooting/edge-function-546-error-response) cùng ngày ghi bộ nhớ **250 MB**. Hai trang chính thức không khớp. `[CHƯA XÁC MINH]` con số đang áp cho dự án.

Secret: tên không được bắt đầu bằng `SUPABASE_` ([secrets](https://supabase.com/docs/guides/functions/secrets)). Trang đó nói hàm đọc secret mới ngay, không cần deploy lại.

Local: `supabase/functions/.env` được nạp khi stack chạy. File tự đặt chỉ được đọc khi `supabase functions serve --env-file`. Cùng nguồn secrets ở trên.

## Dòng đề xuất cho AGENTS.md

Chưa sửa. Nếu bạn duyệt, thêm khoảng bốn dòng, file vẫn dưới 60 dòng:

- Không để khóa của hãng AI trong app.
- Công cụ để AI hành động không dùng `service_role`.
- Không sửa ví dụ hoặc đáp án trong `evals/` để lần chấm trở thành đạt.
- Gọi mô hình của hãng chỉ sau khi ADR thay ADR-0010 được chấp nhận.

## Việc phải xong trước ticket gọi LLM

1. Bạn duyệt hoặc bác ADR-0011, 0012, 0013.
2. Nếu vẫn gọi hãng AI: đổi câu trên màn đồng ý và khai báo store. Nếu không: không mở ticket đó.
3. Có `.cursorignore` chặn `.env` trước khi tạo secret. File này trước đây Cursor không cho agent ghi. Bạn tạo.
4. Chọn công cụ test (ADR-0013) trước khi viết hàm.

## Ticket đề xuất — chỉ mô tả, chưa làm

### T-AI-00 — Quyết định

Xong khi: ADR-0011 được chấp nhận hoặc bị bác; câu đồng ý khớp với đường đã chọn; bản đồ dữ liệu trong AI_SPEC không còn `[MỞ]` ở các ô bạn muốn chốt.

Dừng nếu bạn chưa chọn A/B/C ở ADR-0011.

### T-AI-01 — Hàm và hạn mức

Chỉ bắt đầu sau T-AI-00 và chỉ nếu bạn chọn đường có gọi mô hình.

Gồm: một Edge Function, migration hạn mức, UI tối thiểu (chờ, thành công, hết lượt, lỗi, thử lại), test với máy chủ giả, pgTAP cho hạn mức.

Đụng migration, RLS, và tiền. Phải dừng để bạn duyệt kế hoạch trước khi viết.

Xong khi: `make check` và `make check-db` xanh với kết quả dán thật; hàm từ chối người chưa đăng nhập; hai lần bấm cùng lúc không vượt hạn mức; không có khóa hãng trong app.

### T-AI-02 — Bộ chấm

20–50 ví dụ bạn đã gắn nhãn. `make eval` riêng, không nằm trong `make check`.

Xong khi: một lần chạy in số thiếu và số thừa so với nhãn, và không ai sửa đáp án để lần đó đạt.

### Các nấc RAG hoặc agent

Chỉ mở ticket khi T-AI-02 chỉ ra lỗi thuộc loại đó. Không làm trước.
