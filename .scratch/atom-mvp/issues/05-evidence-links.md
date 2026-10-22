# 05: Link bằng chứng + gắn vào skill

**What to build:** Ứng viên dán link bài viết hoặc sản phẩm đã ship (S-07), tối đa 10 link. Gắn một link vào skill → skill tự lên mức `evidenced`; gỡ hết bằng chứng → về `selfClaimed`.

**Blocked by:** 04

**Status:** ready-for-agent

Thiết kế: F-019 (tiếp cận), F-005, F-008, F-009, S-05, S-07; DATA_MODEL `evidence`, `skill_evidence`; ALG-01.

- [ ] Thêm/xóa link loại `article`/`product`; URL sai bị chặn ở app và CSDL
- [ ] Link thứ 11 bị từ chối (pgTAP + thông báo trên app)
- [ ] Gắn/gỡ bằng chứng làm trigger tính lại mức tin cậy theo các test mẫu ALG-01 liên quan (pgTAP)
- [ ] RLS `evidence`, `skill_evidence`: chỉ chủ ghi; không gắn được bằng chứng của người khác (pgTAP)
- [ ] S-07 có trạng thái trống/lỗi; đạt guideline tiếp cận; chuỗi đủ vi/en
- [ ] `make check` và `make check-db` xanh
