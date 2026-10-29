# Truy vết (TRACEABILITY)

> v1.0 · Đã thống nhất · 2026-10-22 · F-xxx → màn hình → bảng / RPC / Edge Function → test dự kiến. Màn hình: [UI_DESIGN.md](UI_DESIGN.md); bảng: [DATA_MODEL.md](DATA_MODEL.md); RPC/Edge: [API_CONTRACT.md](API_CONTRACT.md); thuật toán: [ALGORITHMS.md](ALGORITHMS.md).

Đường dẫn test: `test/…` chạy trong `make check`; `supabase/tests/…` chạy trong `make check-db`; `supabase/functions/tests/…` chạy trong `make check-functions` (thêm khi viết Edge Function đầu tiên, TECH_DESIGN § 8).

## 1. Tính năng Must → thiết kế → test

| F | Màn hình | Bảng | RPC / Edge Function | ADR / ALG | Test dự kiến |
|---|---|---|---|---|---|
| F-001 Đăng nhập | S-01, S-02, S-16 | `auth.users` (Supabase), `profiles` | — (Supabase Auth: `signInWithOtp`, `verifyOTP`, `signInWithOAuth`, `signOut`) | ADR-0002, ADR-0005 | `test/routing/router_redirect_test.dart`; `test/ui/auth/sign_in_view_model_test.dart`; `test/ui/auth/otp_view_model_test.dart` (mã sai/hết hạn); `test/data/services/secure_session_storage_test.dart`; thủ công: email, GitHub, Google trên iOS + Android, Apple trên iOS |
| F-002 Xóa tài khoản | S-18 | mọi bảng (cascade, DATA_MODEL § 6) | `delete-account` | ALG-01 | `supabase/tests/delete_account_test.sql`; `supabase/functions/tests/delete_account_test.ts`; `test/ui/settings/delete_account_view_model_test.dart` |
| F-003 Hồ sơ | S-03, S-04 | `profiles`, `cities` | `get_public_profile` (kiểm riêng tư) | ADR-0006, ADR-0008 | `supabase/tests/profiles_rls_test.sql`; `test/domain/models/profile_test.dart`; `test/ui/profile/profile_edit_view_model_test.dart` |
| F-004 GitHub | S-06 | `github_connections`, `evidence` | `connect_github`, `github-repos` | ADR-0005, ADR-0006 | `supabase/tests/github_connection_test.sql`; `supabase/functions/tests/github_repos_test.ts`; `test/ui/github/github_repos_view_model_test.dart` |
| F-005 Link bằng chứng | S-07 | `evidence` | — (REST) | — | `supabase/tests/evidence_links_test.sql`; `test/ui/evidence/evidence_view_model_test.dart` |
| F-006 Đồng ý AI | S-08, S-16 | `ai_consents` | `extract-skills`, `analyze-gap` (kiểm đồng ý) | ADR-0010 | `supabase/tests/ai_consents_rls_test.sql`; `test/ui/consent/consent_view_model_test.dart` |
| F-007 AI trích skill | S-03, S-09 | `ai_jobs`, `skill_suggestions`, `evidence_signal`, `app_settings` | `extract-skills`, `review_suggestion`, `get_ai_quota` | ADR-0010, ADR-0011, ALG-03, ALG-05, ALG-08 | `supabase/functions/tests/extract_test.ts`; `supabase/functions/tests/read_repo_test.ts`; `supabase/functions/tests/gold_repos_test.ts`; `supabase/tests/skill_suggestions_test.sql`; `supabase/tests/evidence_strength_test.sql`; `test/ui/suggestions/suggestions_view_model_test.dart` |
| F-008 Tự khai skill | S-05 | `skills`, `skill_evidence` | — (REST) | ALG-01 | `supabase/tests/skills_test.sql`; `test/ui/profile/skills_view_model_test.dart` |
| F-009 Mức tin cậy | S-03, S-05, S-12, W-01 | `skills.confidence`, `skill_evidence`, `evidence_signal` | `skill_confidence` | ADR-0011, ALG-01 | `supabase/tests/evidence_strength_test.sql`; `test/ui/core/widgets/confidence_badge_test.dart` |
| F-010 Xác nhận skill | S-12 | `endorsements`, `skills`, `blocks` | `endorse_skill` | ALG-02 | Chưa có file test cho xác nhận skill đầy đủ. `supabase/tests/report_block_test.sql` chỉ kiểm người bị chặn không xác nhận được |
| F-011 Link công khai | S-03 (chép link), W-01 | `profiles`, `skills`, `evidence` | `get_public_profile` | ADR-0007 | `supabase/tests/public_profile_test.sql`; `test/ui/profile/public_link_test.dart` |
| F-012 Tìm hồ sơ | S-11, S-12 | `skills`, `profiles`, `blocks` | `search_profiles`, `get_public_profile` | ALG-04 | `supabase/tests/report_block_test.sql` có lọc chặn khi tìm. Chưa có file test riêng cho màn khám phá |
| F-013 Báo cáo & chặn | S-12, S-13, S-17 | `reports`, `blocks`, `profiles.moderation_status`, `moderation_log` | `search_profiles`, `get_public_profile`, `endorse_skill` (lọc chặn) | ALG-02, ALG-04 | `supabase/tests/report_block_test.sql`; `test/ui/safety/safety_view_model_test.dart` |
| F-014 Phân tích khoảng cách | S-10 | `ai_jobs` | `analyze-gap`, `get_ai_quota` | ADR-0010, ALG-05, ALG-09 | `supabase/functions/tests/gap_test.ts`; `supabase/tests/gap_analysis_test.sql`; `test/ui/gap/gap_view_model_test.dart` |
| F-015 Lương ẩn danh | S-14, S-15 | `salary_entries`, `salary_roles`, `cities` | `get_salary_aggregate` | ALG-07 | `supabase/tests/salary_test.sql`; `test/ui/salary/salary_view_model_test.dart` |
| F-016 Mất mạng | S-03, S-12 (+ mọi màn có thao tác mạng) | — (file trên máy) | `get_public_profile` | ADR-0004, ALG-06 | `test/data/repositories/supabase_profile_repository_test.dart`. Chưa có bài kiểm đọc hồ sơ khi mất mạng |
| F-017 Hai ngôn ngữ | mọi màn, S-16, W-01 | — (`shared_preferences`) | — | ADR-0004 | `test/l10n/arb_keys_test.dart`; `test/data/services/locale_preference_test.dart` |
| F-018 Giới hạn AI | S-09, S-10 | `ai_jobs`, `app_settings` | `extract-skills`, `analyze-gap`, `get_ai_quota` | ALG-05, ADR-0010 | `supabase/tests/skill_suggestions_test.sql` |
| F-019 Tiếp cận | mọi màn Must | — | — | UI_DESIGN § 5–6 | `test/a11y/profile_a11y_test.dart`; `test/a11y/suggestions_a11y_test.dart`; `test/a11y/github_repos_a11y_test.dart` |

Kiểm chung: `supabase/tests/rls_enabled_test.sql` (mọi bảng `public` bật RLS, NFR-08).

## 2. Truy ngược: mọi màn hình có nguồn

| Màn hình | F |
|---|---|
| S-01 | F-001, F-017 |
| S-02 | F-001 |
| S-03 | F-003, F-007, F-009, F-011, F-016 |
| S-04 | F-003 |
| S-05 | F-008, F-009 |
| S-06 | F-004 |
| S-07 | F-005 |
| S-08 | F-006 |
| S-09 | F-007, F-018 |
| S-10 | F-014, F-018 |
| S-11 | F-012 |
| S-12 | F-010, F-012, F-013, F-016 |
| S-13 | F-013 |
| S-14 | F-015 |
| S-15 | F-015 |
| S-16 | F-001, F-006, F-017 |
| S-17 | F-013 |
| S-18 | F-002 |
| W-01 | F-011 |

## 3. Truy ngược: mọi bảng có nguồn

| Bảng | F / NFR |
|---|---|
| `profiles` | F-003, F-011, F-013 |
| `github_connections` | F-004, D-040 |
| `evidence` | F-004, F-005 |
| `skills` | F-007, F-008, F-009 |
| `skill_evidence` | F-008, F-009 |
| `endorsements` | F-010, F-009 |
| `ai_consents` | F-006 |
| `ai_jobs` | F-007, F-014, F-018 |
| `skill_suggestions` | F-007 |
| `salary_roles` | F-015 |
| `cities` | F-015, F-003 |
| `salary_entries` | F-015 |
| `reports` | F-013 |
| `blocks` | F-013, F-010, F-012 |
| `moderation_log` | F-013 (A-027, R-008) |
| `app_settings` | F-018, F-007, F-010, F-015 |

## 4. Truy ngược: mọi RPC / Edge Function có nguồn

| Tên | Loại | F |
|---|---|---|
| `get_public_profile` | RPC | F-011, F-012, F-016 |
| `search_profiles` | RPC | F-012, F-013 |
| `endorse_skill` | RPC | F-010 |
| `get_salary_aggregate` | RPC | F-015 |
| `connect_github` | RPC | F-004 |
| `review_suggestion` | RPC | F-007 |
| `get_ai_quota` | RPC | F-018 |
| `github-repos` | Edge | F-004 |
| `extract-skills` | Edge | F-006, F-007, F-018 |
| `analyze-gap` | Edge | F-006, F-014, F-018 |
| `delete-account` | Edge | F-002 |

## 5. Lịch sử

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| 0.1 | 2026-10-22 | Bản nháp đầu |
| 1.0 | 2026-10-22 | Đã thống nhất v1.0 |
