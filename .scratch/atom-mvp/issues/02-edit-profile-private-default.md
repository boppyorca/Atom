# 02: Sửa hồ sơ, mặc định riêng tư

**What to build:** Ứng viên xem hồ sơ của mình (S-03) và sửa tên hiển thị, giới thiệu, thành phố, mục liên hệ (S-04). Hồ sơ mới luôn riêng tư. Ô giới thiệu đếm ký tự còn lại, chặn quá 300.

**Blocked by:** 01

**Status:** ready-for-human

Thiết kế: F-019 (tiếp cận), F-003, S-03, S-04; DATA_MODEL `profiles`, `cities`; ADR-0008. Ticket dùng để đo ponytail (`.scratch/ponytail-trial.md`).

- [x] Sửa và lưu được tên, giới thiệu, thành phố (chọn từ `cities` seed), liên hệ; mở lại thấy giá trị mới
- [x] Giới thiệu > 300 ký tự bị chặn ở app (đếm còn lại) và ở CSDL (`check`)
- [x] Người dùng không ghi được `moderation_status`, `avatar_url`, `first_public_at` (pgTAP quyền cột)
- [x] Người khác không đọc được hồ sơ riêng tư (pgTAP)
- [x] Model `Profile` đọc/ghi JSON đúng với fixture (unit test)
- [x] Trạng thái tải/lỗi/mất mạng của S-03, S-04 có widget test; đạt guideline tiếp cận; chuỗi đủ vi/en
- [x] `make check` và `make check-db` xanh

## Comments

- 2026-10-22: Đã làm (chạy thử B, ponytail tắt).
  - Đã xây: migration mới `20261022140000_profile_edit_fields.sql` (bảng `cities` 5 thành phố, RLS bật, chỉ đọc cho `anon`/`authenticated`; cột `bio` ≤ 300, `city_id`, `contact_type`/`contact_value`/`contact_visible` kèm check; mở quyền cột insert/update cho các cột mới). Model `Profile`, `City` + fixture lấy từ Supabase local. `ProfileRepository`, S-03 (xem hồ sơ) và S-04 `/profile/edit` (sửa tên, giới thiệu đếm ký tự còn lại, thành phố, liên hệ, bật/tắt hiện liên hệ). Chuỗi vi/en.
  - Đỏ → xanh từng tiêu chí:
    - Lưu/mở lại: `profile_edit_view_model_test.dart` đỏ "Method not found: 'ProfileEditViewModel'"; `profile_edit_test.sql` đỏ "planned 17 tests but ran 0" (chưa có `cities`) → xanh.
    - Giới thiệu > 300: cùng hai file trên đỏ như trên; `profile_screens_test.dart` đỏ "No named parameter with the name 'profileRepository'" → xanh ("còn 245 ký tự", "Quá 1 ký tự", không gọi lưu; CSDL trả `23514`).
    - Quyền cột: `profile_edit_test.sql` đỏ "ran 0" (cả file lỗi vì chưa có `cities`). Lưu ý thật: phần `avatar_url`/`first_public_at` đã bị chặn sẵn từ migration ticket 01, nên test này khóa lại hành vi cũ chứ không đỏ vì thiếu quyền.
    - Người khác không đọc được: test mới cũng đỏ "ran 0" chỉ vì cả file lỗi; RLS đã đúng từ ticket 01.
    - Model JSON: `profile_test.dart` đỏ (không có `lib/domain/models/profile.dart`) → xanh.
    - Tải/lỗi/mất mạng S-03, S-04 + tiếp cận: `profile_screens_test.dart`, `profile_a11y_test.dart` đỏ (thiếu `profileRepository`, `Routes.profileEdit`) → xanh.
  - Kết quả: `make check` "All tests passed!" (39 test); `make check-db` "Result: PASS" (45 test); `make docs-check` "docs-check: ok".
  - Review (ponytail-review): không có "Must fix". Còn lại:
    - Nên sửa: lưu hồ sơ gửi lại cả `visibility` cũ; khi có nút "Công khai" (ticket sau) và người dùng sửa trên hai máy, máy cũ có thể ghi đè về giá trị cũ. Cách sửa: bỏ `visibility` khỏi dữ liệu gửi đi.
    - Nên sửa: chưa có test cho `SupabaseProfileRepository` (đổi lỗi mất mạng thành `NetworkFailure`); hiện chỉ test qua repository giả.
    - Nên có: S-03/S-04 tải hồ sơ và thành phố lần lượt, có thể tải song song.
    - Nên có: đếm ký tự tính cả dấu cách cuối, nhưng khi lưu thì cắt dấu cách; 299 ký tự + 2 dấu cách bị chặn dù lưu được.
  - Khác thiết kế / chưa làm: cột `seniority` (cấp bậc) chưa có trong CSDL nên chưa cấp quyền và S-04 chưa có ô "Cấp bậc" (ticket không yêu cầu). S-03 hiện vòng quay thay cho skeleton; chưa có công tắc "Công khai hồ sơ", ảnh đại diện, skill (ticket khác). Chưa có test cỡ chữ lớn nhất. Ba file test cũ (`router_redirect_test`, `widget_test`, `sign_in_a11y_test`) chỉ thêm repository giả vào phần dựng app; một dòng kiểm chữ giữ chỗ "Hồ sơ của bạn sẽ hiện ở đây." đổi thành tên hồ sơ vì màn trống đã được thay.
  - UI not run on a device.
- 2026-10-22: Rà soát của agent chính: bản này cấp quyền đọc `cities` cho `anon`, trái ma trận RLS (`anon` = —). Lỗi do lời giao việc tóm tắt sai ma trận. Đã sửa test trước (`cities_test.sql` "anon cannot read cities", đỏ `Failed test 2`) rồi bỏ `anon` khỏi grant và policy → `make check-db` 45/45 PASS. Bản này là bản B (tắt ponytail) của phép đo, xem `.scratch/ponytail-trial.md`; rule ponytail đã được khôi phục trên nhánh.
