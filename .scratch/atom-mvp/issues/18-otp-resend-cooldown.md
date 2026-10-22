# 18: Nút "Gửi lại mã" chờ 60 giây

**What to build:** Trên S-02, nút "Gửi lại mã" bị khóa 60 giây sau mỗi lần gửi (kể cả lần gửi đầu từ S-01) và hiện số giây còn lại ("Gửi lại mã (sau 42 giây)"). Hết giờ thì bấm được. Giới hạn phía server của Supabase vẫn giữ, nhưng UI không để người dùng bấm liên tục rồi gặp lỗi.

**Blocked by:** 01

**Status:** resolved

Thiết kế: F-001, S-02 (wireframe UI_DESIGN § 3: "Gửi lại mã (sau 60 giây)"). Nợ ghi lại khi làm ticket 01, 2026-10-22.

- [x] Vào S-02 thì nút bị khóa và đếm ngược từ 60 (test ViewModel với đồng hồ giả, không chờ thật)
- [x] Hết 60 giây thì bấm được; bấm xong lại khóa 60 giây
- [x] Gửi lại thất bại (mất mạng) thì không khóa, hiện lỗi
- [x] Rời màn hình thì hủy bộ đếm (không gọi `notifyListeners` sau `dispose`)
- [x] Chuỗi đếm ngược có trong `app_vi.arb` và `app_en.arb`; nút bị khóa vẫn có nhãn đọc được
- [x] `make check` xanh

## Comments

- 2026-10-23: Nút "Gửi lại mã" khóa 60 giây ngay khi vào màn nhập mã, hiện số giây còn lại. Gửi thành công thì khóa lại. Mất mạng thì không khóa và hiện "Không có kết nối". Rời màn hình thì tắt bộ đếm, kể cả khi lệnh gửi đang chờ.
- Đỏ rồi xanh: lần đầu test không biên dịch vì chưa có `secondsLeft` / `canResend`. Test "rời màn hình giữa lúc gửi" đỏ khi bỏ chốt `dispose` (còn bộ đếm), xanh sau khi chốt lại.
- `make check`: No issues found (5.1s); 00:40 +56 All tests passed. `make docs-check`: ok. Không đụng cơ sở dữ liệu.
- Rà soát: không có lỗi phải sửa. Chưa chạy trên máy ảo.
- Chủ dự án cho gộp khi kiểm thử sạch, không chờ review riêng.
