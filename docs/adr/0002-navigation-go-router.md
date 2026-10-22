# ADR-0002 · Điều hướng: `go_router` khai báo tay

- **Trạng thái:** Được chấp nhận (Giai đoạn A, quyết định 2) · 2026-10-22
- **Truy vết:** F-001 (chặn màn hình khi chưa đăng nhập), F-012 (mở hồ sơ theo id), các tab chính (F-003, F-012, F-015, F-017).

## Bối cảnh

App cần: chặn vào khi chưa đăng nhập; 4 tab dưới đáy giữ trạng thái riêng; mở hồ sơ một người theo id (`/u/:id`) từ kết quả tìm kiếm.

## Phương án đã cân nhắc

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. `go_router`, route khai báo tay** | Gói chính thức của flutter.dev; có `redirect` và `StatefulShellRoute.indexedStack` | Đường dẫn là chuỗi, cần test route |
| B. `go_router` + `go_router_builder` | Route có kiểu | Thêm bước sinh mã, thêm package |
| C. `Navigator` thuần | Không thêm package | Tự làm chặn đăng nhập và tab giữ trạng thái |

## Quyết định

Chọn **A**.
- `redirect` toàn cục: chưa có phiên thì về `/sign-in`; đã có phiên mà đang ở `/sign-in*` thì về `/profile`.
- `StatefulShellRoute.indexedStack` cho 4 tab: Hồ sơ, Khám phá, Lương, Cài đặt.
- Hồ sơ người khác: `/u/:id`. Danh sách route đầy đủ ở [UI_DESIGN.md](../design/UI_DESIGN.md).
- Mở app từ link web (universal link/app link) **không** thuộc MVP [GIẢ ĐỊNH]; link công khai mở trang web (ADR-0007).

## Hệ quả

- Có test widget cho `redirect` (chưa đăng nhập → `/sign-in`).
- `refreshListenable` của router lắng nghe trạng thái đăng nhập từ `AuthRepository`.

## Nguồn

- `go_router` 18.1.1, pub.dev (publisher flutter.dev), tra ngày 2026-10-22.
- Context7 `/flutter/packages` (go_router: `redirect`, `StatefulShellRoute.indexedStack`), tra ngày 2026-10-22.
