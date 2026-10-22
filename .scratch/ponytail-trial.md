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
| `make check` xanh ở lần báo xong đầu tiên (có/không) | | |
| Số dòng thêm / xóa (`git diff --shortstat`, không tính file sinh tự động) | | |
| Số file bị chạm | | |
| Đạt hết tiêu chí nghiệm thu của ticket (x/y) | | |
| Có thêm thứ không ai yêu cầu (liệt kê) | | |
| Có bỏ sót thứ ticket cần (liệt kê) | | |
| Số lượt phải nhắc/sửa trước khi đạt | | |

## Quy tắc quyết định

- **Giữ** nếu A đạt tiêu chí nghiệm thu bằng B **và** (ít dòng/ít file hơn ≥ 20 % **hoặc** ít thứ thừa hơn).
- **Bỏ** nếu A bỏ sót tiêu chí nghiệm thu hoặc test mà B có.
- Hòa → giữ thêm 2 ticket rồi đo lại.

## Kết quả

(chưa đo)

Lưu ý: từ 2026-10-22 dự án có thêm rule graphify (luôn bật). Chạy cả A và B với graphify bật như nhau để chỉ ponytail là khác biệt.
