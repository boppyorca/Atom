# Thử nghiệm ponytail (lite)

**Status:** chờ ticket 01 xong; đo trên ticket 02 (`atom-mvp/issues/02-edit-profile-private-default.md`), chủ dự án chọn 2026-10-22

Quy tắc: `.cursor/rules/ponytail.mdc` (luôn bật, mức lite). Giữ hay bỏ quyết định sau khi đo trên **một ticket thật**.

## Cách đo

1. Ticket đo: 02 (đủ UI + dữ liệu + test, không quá lớn). Ticket 01 làm bình thường với quy tắc bật.
2. Làm ticket đó **hai lần**, mỗi lần trong một git worktree riêng, cùng model, cùng lời giao việc ("làm ticket NN theo AGENTS.md"):
   - **A (bật):** giữ `.cursor/rules/ponytail.mdc`.
   - **B (tắt):** xóa file đó trong worktree B trước khi chạy.
3. Không sửa tay giữa chừng. Ghi số liệu vào bảng dưới, rồi chủ dự án chọn bản để merge.

## Số liệu

| Chỉ số | A (bật) | B (tắt) |
|---|---|---|
| `make check` xanh ở lần báo xong đầu tiên (có/không) | không (dừng trước khi xong) | có |
| Số dòng thêm / xóa (`git diff --shortstat`, không tính file sinh tự động) | +1378 / −33 (chưa xong) | +1580 / −35 |
| Số file bị chạm | 27 | 30 |
| Đạt hết tiêu chí nghiệm thu của ticket (x/y) | 5/7 | 7/7 |
| Có thêm thứ không ai yêu cầu (liệt kê) | `ErrorView`; check định dạng liên hệ (có trong DATA_MODEL) | `ErrorView`; model + fixture `City`; `cities_test.sql`; fixture hồ sơ trống |
| Có bỏ sót thứ ticket cần (liệt kê) | S-04: sau khi lưu lỗi lúc mất mạng, ô tên hiện chữ của ô giới thiệu; chưa chạy ponytail-review | cấp quyền đọc `cities` cho `anon`, trái ma trận RLS (do lời giao việc mơ hồ, xem dưới); S-03 dùng vòng xoay thay cho skeleton |
| Số lượt phải nhắc/sửa trước khi đạt | 4 lần `make check` đỏ, rồi dừng theo luật "hỏng 2 lần liên tiếp" | 0 lần chạy lại toàn bộ; 4 lần test S-04 đỏ liền nhau, nó **không dừng** vì mỗi lần một nguyên nhân khác |

## Quy tắc quyết định

- **Giữ** nếu A đạt tiêu chí nghiệm thu bằng B **và** (ít dòng/ít file hơn ≥ 20 % **hoặc** ít thứ thừa hơn).
- **Bỏ** nếu A bỏ sót tiêu chí nghiệm thu hoặc test mà B có.
- Hòa → giữ thêm 2 ticket rồi đo lại.

## Kết quả

2026-10-22, ticket 02, chạy lần lượt (A rồi B) vì hai worktree dùng chung một Supabase local. Cùng model, cùng lời giao việc.

- Theo quy tắc quyết định: A bỏ sót tiêu chí mà B đạt → **Bỏ**.
- Nhưng kết quả bị nhiễu: A tuân luật dừng còn B thì không; nếu A cũng được sửa tiếp thì rất có thể nó đã xong (cách sửa đã tìm ra). A ít dòng hơn khoảng 13 %, dưới ngưỡng 20 %. Chỉ có 1 ticket.
- Lời giao việc ghi "read-only for anon/authenticated per the RLS matrix", trong khi ma trận ghi `anon` không được đọc `cities`. A làm theo ma trận, B làm theo câu chữ.
- Bài học cho harness: luật "hỏng 2 lần liên tiếp" cần ghi rõ "cùng một bước, bất kể nguyên nhân"; lời giao việc không được diễn giải lại ma trận RLS, chỉ trỏ tới nó.

Quyết định của chủ dự án (2026-10-22): **chưa kết luận, giữ rule và đo lại** trên 2 ticket kế tiếp, cả hai bản cùng luật dừng chặt (AGENTS.md quy tắc 6). Dùng bản B cho ticket 02, sau khi sửa quyền đọc `cities` cho đúng ma trận (chỉ `authenticated`).

Lời giao việc cho lần đo sau: chỉ trỏ tới ticket và DATA_MODEL, không tóm tắt lại quyền.

Lưu ý: từ 2026-10-22 dự án có thêm rule graphify (luôn bật). Chạy cả A và B với graphify bật như nhau để chỉ ponytail là khác biệt.
