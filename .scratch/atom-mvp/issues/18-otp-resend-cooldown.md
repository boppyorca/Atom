# 18: Nút "Gửi lại mã" chờ 60 giây

**What to build:** Trên S-02, nút "Gửi lại mã" bị khóa 60 giây sau mỗi lần gửi (kể cả lần gửi đầu từ S-01) và hiện số giây còn lại ("Gửi lại mã (sau 42 giây)"). Hết giờ thì bấm được. Giới hạn phía server của Supabase vẫn giữ, nhưng UI không để người dùng bấm liên tục rồi gặp lỗi.

**Blocked by:** 01

**Status:** ready-for-agent

Thiết kế: F-001, S-02 (wireframe UI_DESIGN § 3: "Gửi lại mã (sau 60 giây)"). Nợ ghi lại khi làm ticket 01, 2026-10-22.

- [ ] Vào S-02 thì nút bị khóa và đếm ngược từ 60 (test ViewModel với đồng hồ giả, không chờ thật)
- [ ] Hết 60 giây thì bấm được; bấm xong lại khóa 60 giây
- [ ] Gửi lại thất bại (mất mạng) thì không khóa, hiện lỗi
- [ ] Rời màn hình thì hủy bộ đếm (không gọi `notifyListeners` sau `dispose`)
- [ ] Chuỗi đếm ngược có trong `app_vi.arb` và `app_en.arb`; nút bị khóa vẫn có nhãn đọc được
- [ ] `make check` xanh
