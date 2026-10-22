# ADR-0004 · Đọc khi mất mạng: mỗi hồ sơ một file JSON

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 4) · 2026-10-22
- **Truy vết:** F-016, F-013 (hồ sơ bị gỡ biến mất khỏi bản lưu), F-002 (xóa tài khoản), F-017 (lưu ngôn ngữ đã chọn).

## Bối cảnh

Chỉ cần **đọc** lại hồ sơ đã mở khi mất mạng; không cần sửa khi mất mạng hay đồng bộ hai chiều.

## Phương án đã cân nhắc

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. Mỗi hồ sơ một file JSON trong thư mục ứng dụng (`path_provider`)** | Không cần CSDL; dễ test; dễ xóa | Tự viết giới hạn số file |
| B. CSDL cục bộ (sqlite/drift) | Truy vấn được | Thêm package và sinh mã; quá mức nhu cầu |
| C. Cache HTTP | Ít mã | Không kiểm soát được việc xóa hồ sơ bị gỡ |

## Quyết định

Chọn **A**. Thuật toán chi tiết ở [ALGORITHMS.md § ALG-06](../design/ALGORITHMS.md#alg-06--bản-lưu-hồ-sơ-khi-mất-mạng-lru).
- Tải thành công → ghi đè file `profiles/<id>.json`.
- Lỗi mạng → đọc file, hiện băng "Đang xem bản lưu" kèm nút thử lại.
- Server trả "không tồn tại/không được xem" → xóa file.
- Tối đa 50 hồ sơ, bỏ file dùng lâu nhất (LRU) [GIẢ ĐỊNH].
- Đăng xuất hoặc xóa tài khoản → xóa cả thư mục cache.
- Không dùng package kiểm tra kết nối: lỗi mạng khi gọi API được coi là mất mạng.
- Ngôn ngữ đã chọn lưu bằng `shared_preferences` (không phải dữ liệu nhạy cảm).

## Hệ quả

- File cache chứa dữ liệu hồ sơ công khai và hồ sơ của chính mình; không chứa lương, không chứa token (token ở ADR-0005).
- Bản lưu có thể cũ tới lần mở trước; chấp nhận được vì F-016 chỉ yêu cầu "lần tải gần nhất".

## Nguồn

- `path_provider` 2.1.6, `shared_preferences` 2.5.6, pub.dev, tra ngày 2026-10-22.
