# ADR-0001 · Quản lý trạng thái: MVVM với `ChangeNotifier`

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 1) · 2026-10-22
- **Truy vết:** mọi màn hình Must (F-001…F-019); NFR khả năng kiểm thử (`make check`), F-016 (trạng thái "đang xử lý" không khóa giao diện).

## Bối cảnh

App có nhiều màn hình đọc/ghi qua mạng, có trạng thái đang tải/lỗi/mất mạng (F-016) và việc nền AI (F-007, F-014). Một người làm trong khoảng 3 tháng (D-026, R-001), nên cần cách ít khái niệm, có tài liệu chính thức, dễ test mà không cần package mock.

## Phương án đã cân nhắc

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. MVVM theo hướng dẫn kiến trúc chính thức của Flutter: ViewModel kế thừa `ChangeNotifier`, `provider` chỉ để tiêm phụ thuộc (DI)** | Có hướng dẫn và case study chính thức; ít khái niệm; test bằng fake viết tay | Phải tự gọi `notifyListeners()` đúng chỗ |
| B. Riverpod | Mạnh, kiểm soát vòng đời tốt | Thêm khái niệm, thường kèm sinh mã |
| C. BLoC | Tách sự kiện/trạng thái rõ | Nhiều mã khuôn mẫu cho MVP một người |

## Quyết định

Chọn **A**. Mỗi màn hình có một `<feature>_view_model.dart` (`ChangeNotifier`) và một `<feature>_screen.dart`. ViewModel nhận repository qua constructor và chỉ gọi repository, không gọi Supabase trực tiếp. Hành động bất đồng bộ lộ ra dưới dạng trạng thái `idle / running / error` để màn hình hiện "đang xử lý" mà vẫn cuộn, bấm được (D-035). `provider` chỉ dùng ở gốc app để cung cấp service và repository.

## Hệ quả

- Test ViewModel bằng repository giả viết tay trong `test/fakes/`; không thêm `mockito`/`mocktail`.
- Trạng thái hiển thị chung của màn hình: `loading`, `data`, `empty`, `error`, `offline` (xem [UI_DESIGN.md](../design/UI_DESIGN.md)).
- Không có lớp use-case (ADR-0003). Nếu trạng thái chia sẻ giữa nhiều màn hình trở nên phức tạp, xem lại bằng ADR mới.

## Nguồn

- Flutter docs, "Guide to app architecture" và "Architecture case study" (Context7 `/flutter/website`), tra ngày 2026-10-22.
- `provider` 6.1.5+1, pub.dev, tra ngày 2026-10-22.
