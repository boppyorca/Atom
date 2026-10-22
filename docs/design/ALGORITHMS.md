# Thuật toán (ALGORITHMS)

> v1.0 · Đã thống nhất · 2026-10-22 · Chỉ ghi phần logic không hiển nhiên. Bảng/cột: [DATA_MODEL.md](DATA_MODEL.md); lời gọi: [API_CONTRACT.md](API_CONTRACT.md).

"Đầu tháng" (`month_start`) = 00:00 ngày 1 của tháng hiện tại theo giờ `Asia/Ho_Chi_Minh` [GIẢ ĐỊNH]; `resets_at` = đầu tháng kế tiếp. Trong SQL: `date_trunc('month', now() at time zone 'Asia/Ho_Chi_Minh') at time zone 'Asia/Ho_Chi_Minh'`.

## ALG-01 · Tính mức tin cậy của skill (F-009, F-008, F-010, F-002)

**Nơi chạy:** hàm SQL `recompute_skill_confidence(skill_id)`, gọi bởi trigger `after insert or delete` trên `skill_evidence` và `endorsements`.

1. `has_evidence` = tồn tại dòng `skill_evidence` của skill.
2. `has_endorsement` = tồn tại dòng `endorsements` của skill.
3. `confidence` =
   - `endorsed` nếu `has_evidence` **và** `has_endorsement` (ngưỡng 1 lượt, A-005);
   - `evidenced` nếu chỉ `has_evidence`;
   - `self_claimed` nếu không có bằng chứng (kể cả khi còn lượt xác nhận).
4. Cập nhật `skills.confidence` nếu khác giá trị cũ.

**Trường hợp biên:**
- Bằng chứng bị gỡ (xóa link, ngắt GitHub) → `skill_evidence` bị cascade xóa → trigger chạy → mức hạ xuống. Lượt xác nhận cũ vẫn được giữ, sẽ tính lại khi gắn bằng chứng mới.
- Skill bị xóa → cascade xóa các dòng con; trigger cập nhật skill không còn tồn tại thì không làm gì.
- Người xác nhận mất điều kiện sau khi đã xác nhận → lượt xác nhận vẫn hợp lệ [GIẢ ĐỊNH]; điều kiện chỉ kiểm lúc tạo (ALG-02).
- Người xác nhận xóa tài khoản → lượt bị xóa → mức được tính lại (F-002).

**Test mẫu (pgTAP):**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | Skill mới, không bằng chứng, không xác nhận | `self_claimed` |
| 2 | Gắn 1 link vào skill ở #1 | `evidenced` |
| 3 | Skill `evidenced` nhận 1 lượt xác nhận | `endorsed` |
| 4 | Skill `endorsed`; xóa link duy nhất | `self_claimed`, lượt xác nhận vẫn còn trong bảng |
| 5 | Skill `endorsed` có 1 lượt; người xác nhận xóa tài khoản | `evidenced` |

## ALG-02 · Xác nhận skill (F-010, F-013)

**Nơi chạy:** RPC `endorse_skill(p_skill_id)` trong một transaction.

1. `caller = auth.uid()`; null → `UNAUTHORIZED`.
2. Đọc skill (`for share`) và chủ skill `owner`. Không có → `NOT_FOUND`.
3. Hồ sơ `owner` không `public` hoặc không `active` → `NOT_FOUND`. Có dòng `blocks` giữa `owner` và `caller` theo **bất kỳ chiều nào** → `NOT_FOUND` [GIẢ ĐỊNH: chặn chiều ngược cũng ẩn]. Hồ sơ `caller` bị gỡ → `NOT_FOUND`.
4. `owner = caller` → `SELF_ENDORSE`.
5. `caller` không có skill cùng `name_normalized` với `confidence in ('evidenced','endorsed')` → `NOT_ELIGIBLE` (A-004).
6. Đã có `(skill_id, caller)` → `ALREADY_ENDORSED` (A-006).
7. `pg_advisory_xact_lock(hashtext('endorse:' || caller))` để hai lượt gọi đồng thời không cùng lọt hạn mức. `used` = số `endorsements` của `caller` có `created_at >= month_start`. `used >= endorsements_per_month` (mặc định 10) → `QUOTA_EXCEEDED` kèm `resets_at`.
8. Thêm dòng; trigger chạy ALG-01. Trả `remaining_this_month = limit - used - 1`.

**Trường hợp biên:** rút lại xác nhận xóa dòng nên trả lại một lượt trong tháng [GIẢ ĐỊNH]; so khớp skill chỉ theo chữ đã chuẩn hóa ("Flutter" = " flutter "), không hiểu từ đồng nghĩa ("JS" ≠ "JavaScript") [GIẢ ĐỊNH].

**Test mẫu:**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | A có "Flutter" `evidenced`, xác nhận "flutter" của B (công khai) | thành công, `remaining_this_month = 9` |
| 2 | A chỉ có "Flutter" `self_claimed` | `NOT_ELIGIBLE` |
| 3 | A xác nhận skill của chính A | `SELF_ENDORSE` |
| 4 | A đã có 10 lượt từ ngày 2026-10-01 00:00 (+07); gọi lúc 2026-10-31 23:59 (+07) / lúc 2026-11-01 00:00 (+07) | `QUOTA_EXCEEDED` / thành công |
| 5 | B đã chặn A | `NOT_FOUND` |

## ALG-03 · Duyệt skill AI đề xuất (F-007, F-009)

**Nơi chạy:** RPC `review_suggestion(p_suggestion_id, p_accept)`.

1. Khóa đề xuất (`for update`); không có hoặc `profile_id <> auth.uid()` → `NOT_FOUND`; `status <> 'pending'` → `ALREADY_REVIEWED`.
2. `p_accept = false` → `status = 'rejected'`, `reviewed_at = now()`; trả `skill_id = null`. Skill bị bỏ không bao giờ hiện trên hồ sơ.
3. `p_accept = true`:
   1. Tìm skill cùng `name_normalized` của người dùng; chưa có thì tạo (vượt 50 skill → `SKILL_LIMIT`).
   2. Với mỗi `evidence_id` trong đề xuất **còn tồn tại và thuộc người dùng**: thêm `skill_evidence` (bỏ qua nếu đã có).
   3. `status = 'accepted'`, `reviewed_at = now()`; trigger chạy ALG-01.

**Trường hợp biên:** bằng chứng đã bị xóa sau khi AI chạy → skill vẫn được tạo, có thể chỉ ở mức `self_claimed` [GIẢ ĐỊNH]; đề xuất trùng skill sẵn có → chỉ thêm bằng chứng.

**Test mẫu:**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | Đề xuất "Dart" với 1 repo còn tồn tại; chấp nhận | skill "Dart" mới, `evidenced` |
| 2 | Đề xuất "Dart" khi đã có "dart" `self_claimed`; chấp nhận | không tạo skill mới; "dart" lên `evidenced` |
| 3 | Bỏ đề xuất | `rejected`; không có skill mới |
| 4 | Duyệt lại đề xuất đã `accepted` | `ALREADY_REVIEWED` |
| 5 | Người khác gọi với id đề xuất của tôi | `NOT_FOUND` |

## ALG-04 · Tìm hồ sơ theo skill (F-012, F-013)

**Nơi chạy:** RPC `search_profiles(p_query, p_limit, p_offset)`.

1. `q = lower(regexp_replace(btrim(p_query), '\s+', ' ', 'g'))`; `char_length(q) < 2` → `QUERY_TOO_SHORT`. Thoát ký tự `%`, `_`, `\` trong `q`.
2. Chọn skill có `name_normalized like q || '%'` (dùng chỉ mục `text_pattern_ops`).
3. Chỉ giữ hồ sơ: `visibility = 'public'`, `moderation_status = 'active'`, khác `auth.uid()`, và **không** có dòng `blocks` giữa hồ sơ đó và người gọi theo bất kỳ chiều nào.
4. Gom theo hồ sơ; `matched_skills` là các skill khớp.
5. Sắp xếp: mức tin cậy cao nhất trong các skill khớp (`endorsed` > `evidenced` > `self_claimed`), rồi `profiles.updated_at desc`, rồi `id`.
6. `limit least(p_limit, 50)`, `offset p_offset`.

**Trường hợp biên:** không phân biệt dấu tiếng Việt chưa hỗ trợ (tên skill thường là tiếng Anh) [GIẢ ĐỊNH]; hồ sơ vừa chuyển riêng tư biến mất ngay ở lần tìm kế tiếp.

**Test mẫu:**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | B công khai có "Flutter"; A tìm "flu" | có B |
| 2 | C riêng tư có "Flutter"; A tìm "flutter" | không có C |
| 3 | B đã chặn A; A tìm "flutter" | không có B |
| 4 | D bị gỡ (`removed`) | không có D |
| 5 | A tìm "f" | `QUERY_TOO_SHORT` |

## ALG-05 · Vòng đời lượt phân tích: hạn mức, thời gian chờ (F-007, F-014, F-018, D-035)

**Nơi chạy:** Edge Functions `extract-skills`, `analyze-gap`; bước 1–6 trong một hàm SQL nội bộ `ai_begin_job(profile_id, kind, input)` (chỉ `service_role` gọi được) để chạy trong một transaction.

**Bắt đầu (trả lời ngay cho app):**
1. `ai_consents.granted` phải là `true` → nếu không: `CONSENT_REQUIRED` (F-006).
2. Dọn lượt treo: mọi job `queued/running` có `deadline_at < now()` → `timed_out`, `error_code = 'TIMEOUT'`, `finished_at = now()`.
3. `pg_advisory_xact_lock(hashtext('ai:' || profile_id || kind))`. Còn job `queued/running` cùng loại → `JOB_ALREADY_RUNNING`.
4. `used` = số job cùng loại của người dùng, `created_at >= month_start`, `status in ('queued','running','succeeded')`. Lượt `failed`/`timed_out` **không** tính (A-019). `used >= quota` → `QUOTA_EXCEEDED` kèm `resets_at`.
5. Kiểm đầu vào (`NO_SOURCES`, `NO_SKILLS`, `INPUT_INVALID`); tạo job `queued`, `deadline_at = now() + ai_timeout_seconds`.
6. Trả `202 { job_id }`; phần còn lại chạy trong `EdgeRuntime.waitUntil`.

Không có bước kiểm trần chi phí: chi phí theo lượt bằng 0 (ADR-0010).

**Chạy nền:**
7. `status = 'running'`. Chạy ALG-08 (trích skill) hoặc ALG-09 (khoảng cách), dừng đọc nguồn mới khi còn < 5 giây tới `deadline_at`.
8. Thành công: ghi kết quả; `succeeded`.
9. Lỗi/hết giờ: `failed` + `error_code` (`GITHUB_UNAVAILABLE`, `SOURCE_UNREADABLE`, `TIMEOUT`, `INTERNAL`); ghi `console.error` chỉ với id job và mã lỗi.

**Phía app (hiển thị trạng thái):** trạng thái hiệu lực = `timed_out` nếu `status in ('queued','running')` và `now() > deadline_at`, ngược lại là `status`. Vì Edge Function có thể bị dừng cứng ở 150 giây (gói miễn phí) mà không kịp ghi lỗi, quy tắc này bảo đảm không treo mãi ở "đang chạy". App đọc lại `ai_jobs` khi mở màn hình, khi app trở lại foreground và mỗi 5 giây khi đang xem job chạy [GIẢ ĐỊNH]. Dấu báo "đã xong" hiện khi có job `succeeded` với `seen_at is null`.

**Trường hợp biên:** đổi `ai_timeout_seconds` hoặc hạn mức trong `app_settings` có hiệu lực ngay với lượt mới (F-018), không ảnh hưởng job đang chạy; hai lượt gọi đồng thời cùng loại → khóa ở bước 3 cho một lượt qua, lượt kia nhận `JOB_ALREADY_RUNNING`.

**Test mẫu:**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | Tháng này có 2 `succeeded` + 1 `failed` trích skill; hạn mức 3 | bắt đầu được (used = 2) |
| 2 | Tháng này có 3 `succeeded`; gọi trích skill | `QUOTA_EXCEEDED`, `resets_at` = đầu tháng sau |
| 3 | Đổi `ai_quota_extract_per_month` từ 3 thành 4 khi đã có 3 `succeeded` | bắt đầu được, không cần phát hành app |
| 4 | Job `running`, `deadline_at` đã qua 1 giây | app hiện lỗi + nút thử lại; lần bắt đầu kế tiếp chuyển nó thành `timed_out` |
| 5 | Đang có job trích skill `running`; gọi lại trích skill | `JOB_ALREADY_RUNNING` |

## ALG-06 · Bản lưu hồ sơ khi mất mạng (LRU) (F-016, F-013, F-002)

**Nơi chạy:** `ProfileRepository` + `ProfileCacheService` trong app (ADR-0004).

Thư mục: `<application support>/profile_cache/`; mỗi file `<profile_id>.json` = `{ "saved_at", "last_opened_at", "data": <kết quả get_public_profile hoặc hồ sơ của mình> }`.

1. Mở hồ sơ → gọi server.
2. Thành công, có dữ liệu → ghi đè file, `last_opened_at = now`; nếu số file > 50 [GIẢ ĐỊNH] → xóa file có `last_opened_at` cũ nhất cho tới khi còn 50. Hiện dữ liệu mới.
3. Thành công nhưng `null` (riêng tư/bị gỡ/đã xóa/bị chặn) → xóa file nếu có; hiện "Hồ sơ không tồn tại" (A-012, F-013).
4. Lỗi mạng → có file: hiện dữ liệu trong file + băng "Đang xem bản lưu lúc <saved_at>" + nút thử lại, cập nhật `last_opened_at`; không có file: trạng thái `offline` + nút thử lại.
5. Lỗi khác (server 5xx) → giống lỗi mạng nhưng thông báo "Có lỗi, thử lại".
6. Đăng xuất / xóa tài khoản → xóa cả thư mục.
7. File hỏng (JSON sai) → xóa file, coi như không có.

"Lỗi mạng" = ngoại lệ kết nối khi gọi Supabase (ví dụ `SocketException`, `TimeoutException`, `http.ClientException`) [CHƯA XÁC MINH: loại ngoại lệ chính xác `supabase_flutter` 2.18.3 ném ra khi mất mạng; kiểm bằng test tích hợp khi làm].

**Test mẫu (unit, fake service + thư mục tạm):**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | Server trả hồ sơ X | file `X.json` được ghi; màn hình không có băng "bản lưu" |
| 2 | Đã có `X.json`; server ném lỗi mạng | hiện dữ liệu từ file + băng "Đang xem bản lưu" |
| 3 | Đã có `X.json`; server trả `null` | file bị xóa; "Hồ sơ không tồn tại" |
| 4 | Có 50 file; mở hồ sơ thứ 51 thành công | còn 50 file; file `last_opened_at` cũ nhất bị xóa |
| 5 | Đăng xuất | thư mục `profile_cache` rỗng |

## ALG-07 · Số liệu lương gộp "góp để xem" (F-015, R-007, D-030)

**Nơi chạy:** RPC `get_salary_aggregate(p_role_id, p_city_id, p_seniority)`.

1. Người gọi chưa có dòng `salary_entries` nào → `CONTRIBUTION_REQUIRED`.
2. Lấy `gross_monthly_vnd` của nhóm (vai trò + thành phố + cấp bậc), gồm cả khoản của người gọi.
3. `n < salary_min_sample_size` (mặc định 5) → `{ status: 'insufficient_data' }`.
4. Tính `percentile_cont(0.25)`, `percentile_cont(0.5)`, `percentile_cont(0.75)`; làm tròn từng số tới 100.000 VND gần nhất (`round(x / 100000) * 100000`, nửa làm tròn lên) [GIẢ ĐỊNH: "khoảng" = từ p25 tới p75, không dùng min/max vì min/max chính là một khoản riêng lẻ].
5. Trả `{ status: 'ok', p25_vnd, median_vnd, p75_vnd }`; không trả `n`.

**Trường hợp biên:** khoản bị xóa/sửa hoặc tài khoản bị xóa → lần gọi kế tiếp tự tính lại (F-002). Rủi ro còn lại: so sánh kết quả trước/sau khi một người góp có thể đoán được khoảng lương của người đó; làm tròn và không trả `n` giảm bớt, không loại bỏ (R-007) [GIẢ ĐỊNH chấp nhận ở thử nghiệm kín].

**Test mẫu:**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | Người gọi chưa góp | `CONTRIBUTION_REQUIRED` |
| 2 | Nhóm có 4 khoản | `insufficient_data` |
| 3 | Nhóm: 10, 12, 14, 16, 18 triệu | p25 = 12.000.000, median = 14.000.000, p75 = 16.000.000 |
| 4 | Nhóm: 10; 11; 12,5; 15; 20; 30 triệu | p25 = 11.400.000 (11,375 tr), median = 13.800.000 (13,75 tr), p75 = 18.800.000 (18,75 tr) |
| 5 | Nhóm có đúng 5 khoản; một người xóa khoản của mình | `insufficient_data` |

## Từ điển skill (dùng cho ALG-08, ALG-09)

File `supabase/functions/_shared/skill_dictionary.json` (ADR-0010). Mỗi mục:

```json
{
  "id": "flutter",
  "name": "Flutter",
  "aliases": ["flutter"],
  "signals": {
    "languages": [],
    "dependencies": { "pub": ["flutter"], "npm": [], "pypi": [], "gradle": [], "go": [], "cargo": [], "composer": [], "gem": [], "maven": [] },
    "topics": ["flutter"],
    "files": [],
    "keywords": ["flutter"],
    "keywords_case_sensitive": []
  },
  "suggestion": { "vi": "Làm một app nhỏ có …", "en": "Build a small app that …" }
}
```

- `languages`: tên ngôn ngữ đúng như GitHub trả (ví dụ `Dart`, `TypeScript`).
- `files`: tên file/thư mục ở gốc repo là dấu hiệu (ví dụ `Dockerfile` → Docker, `.github/workflows` → CI/CD).
- `keywords_case_sensitive`: từ dễ nhầm với từ thường, chỉ khớp đúng hoa/thường (ví dụ `React`, `Go`, `Swift`).
- Test của từ điển: mọi `id` duy nhất; mọi `name`/`aliases` sau chuẩn hóa không trùng giữa hai mục; mọi mục có `suggestion.vi` và `suggestion.en`.

Chuẩn hóa tên (`normalize`) giống `skills.name_normalized`: bỏ khoảng trắng đầu/cuối, gộp khoảng trắng, chữ thường.

## ALG-08 · Trích skill bằng quy tắc (F-007)

**Nơi chạy:** phần chạy nền của `extract-skills` (ALG-05 bước 7).

**Đầu vào:** các `evidence` của người dùng: repo `github_repo` đã chọn (≤ 10) và link `article`/`product` (≤ 10). Không dùng tên hiển thị, email, liên hệ, lương (F-006).

1. **Với mỗi repo** (gọi GitHub bằng token server, ADR-0006):
   1. Thông tin repo: `language`, `topics`, nhánh mặc định. Repo trả 404 (đã xóa/thành riêng tư) → bỏ qua repo này, ghi nhận là nguồn hỏng.
   2. `GET /repos/{owner}/{repo}/languages` → giữ ngôn ngữ chiếm ≥ 10% số byte [GIẢ ĐỊNH].
   3. Cây thư mục gốc của nhánh mặc định → danh sách file ở gốc.
   4. Với file khai báo thư viện có mặt ở gốc (`pubspec.yaml`, `package.json`, `requirements.txt`, `pyproject.toml`, `build.gradle`, `build.gradle.kts`, `go.mod`, `Cargo.toml`, `composer.json`, `Gemfile`, `pom.xml`): tải về (≤ 200 KB), lấy **tên** thư viện (không lấy phiên bản).
   5. README (≤ 4.000 ký tự đầu) → văn bản để dò từ khóa.
2. **Với mỗi link:** tải trang (chỉ `http/https`, chặn IP nội bộ, ≤ 1 MB, ≤ 10 giây, ≤ 3 lần chuyển hướng — TECH_DESIGN § 5.3); bỏ thẻ `script`/`style`/HTML; lấy ≤ 4.000 ký tự văn bản đầu. Không tải được → nguồn hỏng.
3. **Khớp dấu hiệu** (mỗi nguồn riêng):
   - ngôn ngữ ∈ `signals.languages` → `language:<tên>`;
   - tên thư viện ∈ `signals.dependencies.<hệ>` → `dependency:<hệ>:<tên>`;
   - chủ đề ∈ `signals.topics` → `topic:<tên>`;
   - file gốc ∈ `signals.files` → `file:<tên>`;
   - từ khóa xuất hiện **trọn từ** trong README/văn bản link (không phân biệt hoa/thường, trừ `keywords_case_sensitive`) → `keyword:<từ>`.
4. **Gom theo skill:** mỗi skill có danh sách nguồn (`evidence_ids`) và danh sách dấu hiệu (`signals`). Skill chỉ có dấu hiệu `keyword` mà từ khóa ngắn hơn 3 ký tự → bỏ (giảm nhầm).
5. **Bỏ skill người dùng đã có:** so `normalize(name)` và `normalize(aliases)` với `skills.name_normalized`.
6. **Sắp xếp và cắt:** theo số nguồn giảm dần, rồi theo độ mạnh của dấu hiệu (`dependency` > `language` > `topic`/`file` > `keyword`), rồi theo tên; giữ tối đa 20 đề xuất [GIẢ ĐỊNH].
7. **Kết quả:** mỗi skill → một dòng `skill_suggestions(name = dictionary.name, evidence_ids, signals)`. Không có đề xuất nào → job vẫn `succeeded` (màn S-09 hiện "Không tìm thấy skill mới"). **Mọi** nguồn đều hỏng → `failed`, `SOURCE_UNREADABLE`. GitHub lỗi 5xx/giới hạn gọi → `failed`, `GITHUB_UNAVAILABLE`.

**Trường hợp biên:** repo không có README hay file khai báo → chỉ còn ngôn ngữ/chủ đề; README tiếng Việt vẫn dò được vì tên công nghệ thường viết bằng tiếng Anh; repo fork do người dùng tự chọn vẫn được đọc (F-004); trang link chặn bot → nguồn hỏng nhưng không làm hỏng cả job nếu còn nguồn khác.

**Test mẫu (`deno test`, GitHub và trang link được giả lập):**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | Repo có `pubspec.yaml` chứa `flutter`, `provider`; ngôn ngữ Dart 95% | đề xuất Flutter, Provider, Dart; `signals` của Provider = `{"dependency:pub:provider"}` |
| 2 | Người dùng đã có skill "flutter" | không đề xuất Flutter; vẫn đề xuất Provider, Dart |
| 3 | README có câu "we react quickly to issues", không có thư viện React | không đề xuất React (từ khóa phân biệt hoa/thường) |
| 4 | Hai repo đều dùng `provider` | một đề xuất Provider với 2 `evidence_ids` |
| 5 | Repo duy nhất trả 404 và link duy nhất hết giờ | job `failed`, `SOURCE_UNREADABLE` |

## ALG-09 · Phân tích khoảng cách skill bằng từ điển (F-014)

**Nơi chạy:** phần chạy nền của `analyze-gap` (ALG-05 bước 7).

**Đầu vào:** `job_description` (1–8.000 ký tự) và danh sách skill của người dùng (tên + mức tin cậy). Không dùng dữ liệu khác.

1. Dò mọi mục từ điển có `aliases` hoặc `keywords` xuất hiện **trọn từ** trong mô tả job (quy tắc hoa/thường như ALG-08). Ghi vị trí xuất hiện đầu tiên.
2. `required` = các skill tìm được, sắp theo vị trí xuất hiện đầu tiên trong mô tả; bỏ trùng.
3. `required` rỗng → kết quả `{ "status": "no_known_skills" }` (job vẫn `succeeded`; S-10 hiện "Chưa nhận ra skill nào trong mô tả job").
4. Với mỗi skill trong `required`: người dùng có skill khớp (`normalize(name)`/`aliases` = `skills.name_normalized`) → vào `have` kèm mức tin cậy; không có → vào `missing` kèm `suggestion.vi` và `suggestion.en`.
5. Ghi `ai_jobs.result` (API_CONTRACT § 4.3). App hiện câu gợi ý theo ngôn ngữ đang dùng (F-017).

**Trường hợp biên:** mô tả job tiếng Việt vẫn dò được tên công nghệ; skill người dùng tự khai bằng tên lạ không có trong từ điển chỉ khớp nếu trùng đúng tên; từ điển không biết kỹ năng mềm ("giao tiếp") → không xuất hiện trong kết quả [GIẢ ĐỊNH, chấp nhận ở MVP].

**Test mẫu:**

| # | Đầu vào | Kết quả mong đợi |
|---|---|---|
| 1 | Mô tả: "Yêu cầu Flutter, REST API, CI/CD"; người dùng có Flutter (`evidenced`) | `have` = [Flutter (evidenced)]; `missing` = [REST API, CI/CD] kèm gợi ý vi/en |
| 2 | Mô tả không chứa tên công nghệ nào trong từ điển | `status = "no_known_skills"` |
| 3 | Mô tả nhắc "Flutter" 3 lần | Flutter xuất hiện 1 lần |
| 4 | Người dùng có skill "flutter " (khoảng trắng thừa, chữ thường) | Flutter vào `have` |
| 5 | Mô tả có "Go" (đúng hoa/thường) và "go to market" | đúng 1 skill Go |

## Lịch sử

| Phiên bản | Ngày | Thay đổi |
|---|---|---|
| 0.1 | 2026-10-22 | Bản nháp đầu |
| 1.0 | 2026-10-22 | Đã thống nhất v1.0 |
