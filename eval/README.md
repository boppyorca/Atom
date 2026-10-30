# Bộ câu chấm chatbot hỏi tài liệu

`chat.jsonl` là bộ khởi đầu. Câu ghi `chờ tài liệu` trong `notes` vì file nguồn chưa được viết và chưa duyệt.

`independent.jsonl` để trống. Người thử viết câu vào đây, mỗi dòng một đối tượng JSON theo `chat.schema.json`. Không chép câu từ `chat.jsonl`.

`attack-docs/` chứa tài liệu có chỉ thị gài. Chỉ dùng khi kiểm thử. Không đưa vào `knowledge/` và không đồng bộ.

Kiểm khung, không cần máy trả lời:

```
python3 scripts/eval-chat --dry
```

Chấm thật, hiện là bản chờ cho tới khi có hàm `ask-atom`. Nếu đặt `ASK_ATOM_URL` thì runner gọi địa chỉ đó.

```
python3 scripts/eval-chat
```

Mỗi câu được hỏi 3 lần. Báo cáo có tỉ lệ, độ dao động, và cột trống để chấm tay.
