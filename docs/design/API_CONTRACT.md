# Hợp đồng API (API_CONTRACT)

> v1.0 · Đã thống nhất · 2026-10-22 · Chỉ gồm **RPC** (hàm Postgres) và **Edge Functions**. Bảng và RLS: [DATA_MODEL.md](DATA_MODEL.md). Quyết định: [ADR-0006](../adr/0006-data-access-rls-rpc-edge-functions.md).

## 1. Dữ liệu dùng REST tự sinh của Supabase (PostgREST + RLS)

App gọi thẳng bảng bằng `supabase.from('<bảng>')`, RLS bảo đảm chỉ chạm dữ liệu của chính mình:

| Bảng | Thao tác app dùng | Tính năng |
|---|---|---|
| `profiles` | đọc/tạo/sửa hồ sơ của mình (chỉ cột được phép) | F-003 |
| `github_connections` | đọc; xóa = ngắt kết nối | F-004 |
| `evidence` | đọc; thêm/sửa/xóa link (`article`, `product`); xóa repo khỏi danh sách | F-004, F-005 |
| `skills` | đọc; thêm skill tự khai; xóa skill | F-008 |
| `skill_evidence` | gắn/gỡ bằng chứng vào skill | F-008, F-009 |
| `endorsements` | đọc lượt đã cho; xóa = rút lại xác nhận | F-010 |
| `ai_consents` | đọc; upsert `granted` | F-006 |
| `ai_jobs` | đọc trạng thái và kết quả; sửa `seen_at` | F-007, F-014 |
| `skill_suggestions` | đọc đề xuất đang chờ | F-007 |
| `salary_roles`, `cities` | đọc danh sách | F-003, F-015 |
| `salary_entries` | đọc/thêm/sửa/xóa khoản của mình | F-015 |
| `reports` | thêm báo cáo | F-013 |
| `blocks` | đọc/thêm/xóa người mình chặn | F-013 |

Lỗi ràng buộc CSDL trả về `PostgrestException`; app ánh xạ `code` (`23505` trùng, `23514` vi phạm check, `P0001` + `message` là mã lỗi nghiệp vụ như `EVIDENCE_LIMIT`) sang thông báo đã dịch (F-017).

## 2. Quy ước chung

- **RPC:** gọi bằng `supabase.rpc('<tên>', params: {...})`. Tất cả là `security definer`, `set search_path = ''`, tự kiểm `auth.uid()`. Lỗi nghiệp vụ: `raise exception using errcode = 'P0001', message = '<MÃ_LỖI>'`; app đọc `PostgrestException.message`.
- **Edge Functions:** gọi bằng `supabase.functions.invoke('<tên>', body: {...})`, phương thức `POST`, bắt buộc JWT người dùng (mặc định `verify_jwt`). Lỗi trả JSON `{ "error": { "code": "<MÃ_LỖI>", "message": "<tiếng Anh, cho log>" } }` kèm mã HTTP. App **không** hiện `message` cho người dùng; chỉ dựa vào `code`.
- Mã lỗi chung: `UNAUTHORIZED` (401), `NOT_FOUND`, `INTERNAL` (500). Lỗi mạng phía app → trạng thái `offline` (ADR-0004).

## 3. RPC

### 3.1 `get_public_profile` — xem hồ sơ công khai (F-011, F-012, F-013, F-016)

- **Quyền:** `anon`, `authenticated`.
- **Input:** `p_profile_id uuid`.
- **Output:** `jsonb` hoặc `null`.
  - `null` khi: không tồn tại, `visibility = 'private'`, `moderation_status = 'removed'`, hoặc (người gọi đã đăng nhập và) chủ hồ sơ đã chặn người gọi. Không phân biệt các trường hợp.
  - Khi có:
    ```json
    {
      "id": "uuid", "display_name": "Minh", "bio": "…",
      "city": { "code": "hcm", "label_vi": "TP. Hồ Chí Minh", "label_en": "Ho Chi Minh City" },
      "seniority": "fresher", "avatar_url": null,
      "contact": { "type": "linkedin", "value": "https://www.linkedin.com/in/…" },
      "skills": [
        { "id": "uuid", "name": "Flutter", "confidence": "endorsed", "endorsement_count": 2,
          "evidence_ids": ["uuid"], "viewer_can_endorse": true, "viewer_endorsement_id": null }
      ],
      "evidence": [ { "id": "uuid", "kind": "github_repo", "url": "https://github.com/…", "title": "todo_app" } ],
      "updated_at": "2026-10-22T10:00:00Z"
    }
    ```
  - `contact` = `null` khi `contact_visible = false`. `viewer_*` = `null` khi người gọi là `anon`. Không bao giờ có email đăng nhập, lương, kết quả phân tích khoảng cách.
- **Lỗi:** không có (trả `null`).
- **Ví dụ (app):** `await supabase.rpc('get_public_profile', params: {'p_profile_id': id});`
- **Ví dụ (trang web, ADR-0007):**
  ```js
  fetch(`${SUPABASE_URL}/rest/v1/rpc/get_public_profile`, {
    method: 'POST',
    headers: { apikey: PUBLISHABLE_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ p_profile_id: id }),
  });
  ```
  [CHƯA XÁC MINH] với khóa publishable mới, chỉ header `apikey` là đủ hay cần thêm `Authorization`; kiểm trên Supabase local khi làm trang.

### 3.2 `search_profiles` — tìm hồ sơ theo skill (F-012, F-013)

- **Quyền:** `authenticated`.
- **Input:** `p_query text` (sau khi chuẩn hóa ≥ 2 ký tự), `p_limit int default 20` (tối đa 50), `p_offset int default 0`.
- **Output:** mảng
  ```json
  [ { "profile_id": "uuid", "display_name": "Lan", "avatar_url": null,
      "city_code": "hn", "seniority": "junior",
      "matched_skills": [ { "name": "React", "confidence": "evidenced" } ] } ]
  ```
- **Quy tắc:** ALG-04.
- **Lỗi:** `QUERY_TOO_SHORT`.
- **Ví dụ:** `await supabase.rpc('search_profiles', params: {'p_query': 'flutter'});`

### 3.3 `endorse_skill` — xác nhận skill (F-010, F-009, F-013)

- **Quyền:** `authenticated`.
- **Input:** `p_skill_id uuid`.
- **Output:** `{ "endorsement_id": "uuid", "remaining_this_month": 7, "resets_at": "2026-11-01T00:00:00+07:00" }`.
- **Quy tắc:** ALG-02.
- **Lỗi:** `NOT_FOUND` (không có skill, hồ sơ không xem được, hoặc bị chủ hồ sơ chặn), `SELF_ENDORSE`, `NOT_ELIGIBLE` (chưa có skill này ở mức ≥ có bằng chứng), `ALREADY_ENDORSED`, `QUOTA_EXCEEDED` (kèm `resets_at` trong `details`).
- **Rút lại:** REST `delete` trên `endorsements` theo `id` (RLS: `endorser_id = auth.uid()`).
- **Ví dụ:** `await supabase.rpc('endorse_skill', params: {'p_skill_id': skillId});`

### 3.4 `get_salary_aggregate` — số liệu lương gộp (F-015, R-007)

- **Quyền:** `authenticated`.
- **Input:** `p_role_id smallint`, `p_city_id smallint`, `p_seniority seniority_level`.
- **Output:** `{ "status": "ok", "p25_vnd": 12000000, "median_vnd": 15000000, "p75_vnd": 18000000 }` hoặc `{ "status": "insufficient_data" }`.
- **Quy tắc:** ALG-07. Không trả số khoản, không trả min/max, không trả dòng riêng lẻ.
- **Lỗi:** `CONTRIBUTION_REQUIRED` (người gọi chưa có khoản lương nào).
- **Ví dụ:** `await supabase.rpc('get_salary_aggregate', params: {'p_role_id': 1, 'p_city_id': 2, 'p_seniority': 'fresher'});`

### 3.5 `connect_github` — ghi nhận kết nối GitHub (F-004)

- **Quyền:** `authenticated`.
- **Input:** không.
- **Output:** `{ "github_username": "minh-dev" }`.
- **Quy tắc:** đọc `auth.identities` của `auth.uid()` với `provider = 'github'`, lấy tên người dùng từ `identity_data`; upsert `github_connections`. App gọi ngay sau khi đăng nhập GitHub hoặc sau `linkIdentity` thành công.
- **Lỗi:** `GITHUB_IDENTITY_MISSING`.
- **Ví dụ:** `await supabase.rpc('connect_github');`

### 3.6 `review_suggestion` — duyệt skill AI đề xuất (F-007, F-009)

- **Quyền:** `authenticated` (chỉ chủ đề xuất).
- **Input:** `p_suggestion_id uuid`, `p_accept boolean`.
- **Output:** `{ "skill_id": "uuid" }` khi chấp nhận, `{ "skill_id": null }` khi bỏ.
- **Quy tắc:** ALG-03.
- **Lỗi:** `NOT_FOUND`, `ALREADY_REVIEWED`, `SKILL_LIMIT`.
- **Ví dụ:** `await supabase.rpc('review_suggestion', params: {'p_suggestion_id': id, 'p_accept': true});`

### 3.7 `get_ai_quota` — lượt phân tích còn lại (F-018)

- **Quyền:** `authenticated`.
- **Input:** không.
- **Output:**
  ```json
  { "extract_skills": { "used": 1, "limit": 3 },
    "gap_analysis": { "used": 0, "limit": 10 },
    "resets_at": "2026-11-01T00:00:00+07:00" }
  ```
  `used` đếm như ALG-05 bước 4.
- **Lỗi:** không.
- **Ví dụ:** `await supabase.rpc('get_ai_quota');`

## 4. Edge Functions

Mã ở `supabase/functions/<tên>/index.ts`; dùng chung `_shared/skill_dictionary.json` (ADR-0010), `_shared/github_client.ts`, `_shared/database.types.ts` (ADR-0008). Secret cần có (đặt qua `supabase secrets`/file env local **không commit**): token GitHub chỉ đọc dữ liệu công khai. Không có khóa AI (ADR-0010). Khóa `service_role` chỉ dùng bên trong function.

### 4.1 `github-repos` — liệt kê và lưu repo bằng chứng (F-004)

- **Quyền:** người dùng đã đăng nhập, đã có `github_connections`.
- **Input:**
  - `{ "action": "list" }`
  - `{ "action": "save", "full_names": ["minh-dev/todo_app", "…"] }` (tối đa 10)
- **Output:**
  - `list` → `{ "repos": [ { "full_name": "minh-dev/todo_app", "url": "https://github.com/minh-dev/todo_app", "description": "…", "is_fork": false, "pushed_at": "…", "selected": true } ] }`. Chỉ repo công khai của chính `github_username`. Khi người dùng chưa từng lưu, `selected` đánh sẵn cho 10 repo không phải fork có `pushed_at` mới nhất.
  - `save` → `{ "saved": 7 }`. Thay toàn bộ `evidence` loại `github_repo` của người dùng bằng danh sách mới (giữ `id` của repo đã có để không mất `skill_evidence`).
- **Quy tắc:** gọi GitHub REST API công khai `GET /users/{username}/repos` (chỉ trả repo công khai) bằng token server; kiểm từng `full_name` thuộc danh sách đó.
- **Lỗi:** `GITHUB_NOT_CONNECTED` (409), `TOO_MANY_REPOS` (422), `REPO_NOT_PUBLIC` (422), `GITHUB_UNAVAILABLE` (502, gồm vượt giới hạn gọi của GitHub).
- **Ví dụ:** `await supabase.functions.invoke('github-repos', body: {'action': 'list'});`

### 4.2 `extract-skills` — trích skill tự động, chạy nền (F-006, F-007, F-018)

- **Quyền:** người dùng đã đăng nhập.
- **Input:** `{}`.
- **Output:** `202` `{ "job_id": "uuid", "status": "queued" }`. Việc thật chạy trong `EdgeRuntime.waitUntil(...)`; app theo dõi qua bảng `ai_jobs`.
- **Quy tắc:** ALG-05 (hạn mức, thời gian chờ) + ALG-08 (trích skill bằng quy tắc). Chỉ đọc repo **đã chọn** và link bằng chứng; không dùng tên hiển thị, email, liên hệ, lương (F-006); không gửi dữ liệu cho bên thứ ba nào ngoài việc gọi GitHub API và tải trang của chính link người dùng đã thêm. Kết quả: các dòng `skill_suggestions`, mỗi dòng ≥ 1 `evidence_id` và ≥ 1 `signal`; bỏ skill trùng skill đã có.
- **Lỗi (trước khi tạo job):** `CONSENT_REQUIRED` (403), `QUOTA_EXCEEDED` (429, `details.resets_at`), `JOB_ALREADY_RUNNING` (409), `NO_SOURCES` (422, chưa có repo/link nào).
- **Lỗi (trong job, ghi `ai_jobs.error_code`):** `GITHUB_UNAVAILABLE`, `SOURCE_UNREADABLE`, `TIMEOUT`, `INTERNAL`.
- **Thử lại:** gọi lại chính function này (tạo job mới; job lỗi không bị tính lượt).
- **Ví dụ:** `await supabase.functions.invoke('extract-skills', body: {});`

### 4.3 `analyze-gap` — phân tích khoảng cách skill, chạy nền (F-014, F-018)

- **Quyền:** người dùng đã đăng nhập.
- **Input:** `{ "job_description": "…" }` (1–8.000 ký tự [GIẢ ĐỊNH]).
- **Output:** `202` `{ "job_id": "uuid", "status": "queued" }`. Khi xong, `ai_jobs.result`:
  ```json
  { "status": "ok",
    "have": [ { "skill": "Flutter", "confidence": "evidenced" } ],
    "missing": [ { "skill": "CI/CD", "suggestion": { "vi": "…", "en": "…" } } ] }
  ```
  hoặc `{ "status": "no_known_skills" }`.
- **Quy tắc:** ALG-05 + ALG-09. Chỉ dùng tên các skill của người dùng + mức tin cậy + nội dung mô tả job; không gửi ra ngoài. Kết quả chỉ chủ xem (RLS `ai_jobs`).
- **Lỗi:** như 4.2, thay `NO_SOURCES` bằng `NO_SKILLS` (422) và thêm `INPUT_INVALID` (422, rỗng hoặc quá dài).
- **Ví dụ:** `await supabase.functions.invoke('analyze-gap', body: {'job_description': text});`

### 4.4 `delete-account` — xóa tài khoản (F-002)

- **Quyền:** người dùng đã đăng nhập; chỉ xóa chính mình (id lấy từ JWT, không nhận id từ body).
- **Input:** `{ "confirm": true }`.
- **Output:** `200` `{ "deleted": true }`. App sau đó `signOut()` và xóa cache (ADR-0004).
- **Quy tắc:** `auth.admin.deleteUser(uid)` bằng client `service_role`; cascade như [DATA_MODEL.md § 6](DATA_MODEL.md#6-xóa-tài-khoản-kéo-theo-gì-f-002).
- **Lỗi:** `CONFIRM_REQUIRED` (400), `UNAUTHORIZED` (401), `INTERNAL` (500, app hiện lỗi + thử lại).
- **Ví dụ:** `await supabase.functions.invoke('delete-account', body: {'confirm': true});`

## 5. Lịch sử

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| 0.1 | 2026-10-22 | Bản nháp đầu |
| 1.0 | 2026-10-22 | Đã thống nhất v1.0 |
