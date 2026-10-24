# Ước tính tiền — Bản nháp

**Trạng thái: Draft.** Ngày 2026-10-23. Người soạn: Grok 4.7.

Đường đã chốt (bộ từ khóa, 0 đồng mỗi người) không dùng công thức này. Công thức chỉ để xem **nếu** sau này gọi API tính theo token.

## Công thức

```
token_vào_tháng  = số_lần_mỗi_ngày × 30 × token_vào_mỗi_lần
token_ra_tháng   = số_lần_mỗi_ngày × 30 × token_ra_mỗi_lần
tiền_tháng       = token_vào_tháng / 1_000_000 × giá_vào
                 + token_ra_tháng  / 1_000_000 × giá_ra
```

Ngày 2026-10-25 bạn chọn **8.000 token** làm độ dài kế hoạch mỗi lần gửi. Các cột 2.000 và 30.000 vẫn để so sánh, là `[GIẢ ĐỊNH]`. Đầu ra 500 token và 10 hoặc 100 lần mỗi ngày cũng là `[GIẢ ĐỊNH]`. 30 ngày.

Giá để trống là `[CHƯA XÁC MINH]`. Không điền từ trí nhớ.

## Giá đã đọc được

Chỉ DeepSeek API, trang [Models & Pricing](https://api-docs.deepseek.com/quick_start/pricing/), đọc 2026-10-23. Đơn vị: đô la Mỹ cho 1 triệu token. Giờ cao điểm trên trang đó: 01:00–04:00 và 06:00–10:00 UTC, thứ Hai–thứ Sáu, trừ ngày lễ Trung Quốc. Giờ khác là thấp điểm.

| Mô hình trên trang | Đầu vào, trượt cache, cao điểm | Đầu ra, cao điểm | Đầu vào, trượt cache, thấp điểm | Đầu ra, thấp điểm |
|---|---|---|---|---|
| deepseek-flash (trang ghi đang phục vụ bởi DeepSeek-V4.1-Flash-1017) | 0,30 | 1,20 | 0,15 | 0,60 |
| deepseek-v4-pro (DeepSeek-V4-Pro-0813) | 1,32 | 3,96 | 0,66 | 1,98 |

Giá khi trúng cache thấp hơn trên cùng trang. Tỉ lệ trúng cache của Atom: `[CHƯA XÁC MINH]`. Bảng tiền dùng cột **trượt cache, cao điểm**, tức mức đắt hơn trong hai mức trượt cache.

## Tiền một tháng, DeepSeek, trượt cache, cao điểm

Đầu ra mỗi lần = 500 token. Phép nhân làm lại, không chép kết luận cũ.

| Lần/ngày | Token vào mỗi lần | Token vào / tháng | Token ra / tháng | Flash (đô) | Pro (đô) |
|---|---|---|---|---|---|
| 10 | 2.000 | 600.000 | 150.000 | 0,36 | 1,39 |
| 10 | 8.000 | 2.400.000 | 150.000 | 0,90 | 3,76 |
| 10 | 30.000 | 9.000.000 | 150.000 | 2,88 | 12,47 |
| 100 | 2.000 | 6.000.000 | 1.500.000 | 3,60 | 13,86 |
| 100 | 8.000 | 24.000.000 | 1.500.000 | 9,00 | 37,62 |
| 100 | 30.000 | 90.000.000 | 1.500.000 | 28,80 | 124,74 |

Cách tính một ô, để kiểm: 100 lần × 30 ngày × 30.000 token = 90.000.000 token vào = 90 × 0,30 = 27,00 đô. Token ra = 100 × 30 × 500 = 1.500.000 = 1,5 × 1,20 = 1,80 đô. Cộng = 28,80 đô cho Flash.

Ô Pro cùng dòng: 90 × 1,32 = 118,80; 1,5 × 3,96 = 5,94; cộng = 124,74. Ba ô Pro ở 10 lần/ngày làm tròn tới xu (1,386 → 1,39; 3,762 → 3,76; 12,474 → 12,47).

## Ô để trống

| Hãng | Giá vào / 1 triệu | Giá ra / 1 triệu | Nguồn | Ngày đọc |
|---|---|---|---|---|
| Gemma API | [CHƯA XÁC MINH] | [CHƯA XÁC MINH] | | |
| Qwen API | [CHƯA XÁC MINH] | [CHƯA XÁC MINH] | | |
| Một mô hình đóng | [CHƯA XÁC MINH] | [CHƯA XÁC MINH] | | |
| Thuê GPU | [CHƯA XÁC MINH] | — | | |

Ngưỡng “thuê GPU khi API vượt khoảng 300–350 đô/tháng” là giả định trong bối cảnh được giao, **không** dùng làm ngưỡng của dự án. `[GIẢ ĐỊNH]` của người viết bối cảnh. Ngưỡng của Atom: `[MỞ]`.

Cách thay giả định: mỗi lần gọi thật ghi số token vào và token ra (không ghi nội dung nếu chưa được phép). Cuối tháng cộng lại rồi nhân giá đang trả.
