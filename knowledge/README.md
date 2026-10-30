# Viết tài liệu cho chatbot

Đây là kho chữ để bot hỏi tài liệu trả lời. Không đưa hồ sơ, lương, email, số điện thoại, hoặc khóa của bất kỳ người nào vào đây.

Chỉ file có `status: reviewed` mới được đồng bộ vào kho tìm. Bản `draft` được phép nằm trong thư mục, nhưng lệnh đồng bộ sau này sẽ từ chối.

## Thư mục

- `app-guide/` — cách dùng Atom.
- `roadmap/` — lộ trình học theo ngách.
- `language/` — ngôn ngữ hoặc framework trong lộ trình.
- `foundation/` — Git, SQL, và nền tảng khác.
- `faq/` — câu hỏi thường gặp.
- `_templates/doc.md` — khuôn.
- `_generated/skill-catalog.md` — xuất từ bảng skill. Không sửa tay.

`eval/attack-docs/` không nằm ở đây và không bao giờ được đồng bộ.

## Mỗi file

Tên file trùng `id`. Một chủ đề một file. Tiếng Việt. Khoảng 150 đến 1.500 từ. Có ngày `updated`.

Không viết các ngưỡng "5 commit", "200 dòng", "14 ngày" trong `app-guide`. Những số đó là quy tắc nội bộ, không phải lời hướng dẫn cho người dùng.

`skills` chỉ dùng tên hoặc tên gọi khác có trong danh mục đã xuất.

Link ghi đủ dạng `https://` hoặc đường dẫn tương đối. Lệnh kiểm tra thường không mở mạng. Kiểm link sống bằng `python3 scripts/kb-lint --links`.

Xuất lại danh mục, khi database local đang bật:

```
python3 scripts/export-skill-catalog
```
