# NewsApp 진행 현황 (2026-04-22)

점심 후 이어서 작업용 상태 스냅샷.

---

## 📌 2026-04-25 업데이트 — 요약 품질/다국어/안정성

### 적용된 변경
- **요약 포맷: 평문 → 3개 불렛포인트**
  - `backend/summarizer/base.py` SYSTEM_PROMPT가 정확히 3개 bullet을 `\n`으로 join하여 요청
  - 앱은 `_BulletList` 위젯으로 split 후 `•` prefix 렌더 (`app/lib/widgets/article_card.dart`)
  - DB 스키마 변경 없음 (`summary_en` TEXT 그대로)
- **EN + KO 동시 생성** (코드 추가했으나 KO 부분은 보류 — 아래 "향후 개선 방향" 참고)
  - 한 번의 LLM 호출로 영어 + 한국어 bullet 둘 다 받아 `summary_en`, `summary_ko`에 저장
  - `max_tokens` 600 → 1000 (한국어 분량 확보)
  - **현재 상태:** prompt를 EN-only로 환원 (Llama 한국어 한자 오염 79%). DB `summary_ko` 컬럼/앱 fallback 로직은 유지 — KO 재개 시 코드 변경 최소
- **device locale 자동 매칭** (migration `0007_user_prefs_language_explicit.sql` 필요)
  - 첫 실행 시 한국어 디바이스 → `language='ko'`, 그 외 → `'en'` 자동 세팅
  - 새 컬럼 `language_explicit boolean` — 한 번 자동 매칭/수동 설정되면 다시 덮어쓰지 않음
- **LLM provider fallback chain**
  - `LLM_PROVIDER` 콤마 구분 지원 (`groq,gemini`). 첫 provider 실패 시 다음으로 자동 fallback
  - `backend/summarizer/chain.py` 새 추가
  - Gemini provider 추가 (`backend/summarizer/gemini_provider.py`, default `gemini-2.0-flash`, OpenAI 호환 endpoint)
  - 새 GitHub Secret: `GEMINI_API_KEY`
- **rate-limit burst 방지**
  - 요청 간 2초 throttle (`backend/main.py`)
  - chain 내 fallback 호출 전 1초 cooldown (`chain.py`)

### 결과
- 워크플로우 실패율: **5건 → 1건** (19개 요약 대상 기준 95%+ 성공)
- 총 실행 시간: 40초 → 80초 (10분 timeout 내)
- 남은 1건 패턴: Groq가 특정 기사에 **400 Bad Request** 반환 (rate limit 아님 — content/payload 이슈로 추정)

### 향후 개선 방향 (보류)
- **🇰🇷 한국어 요약 복원** — 현재 EN-only로 운영 중 (2026-04-25 보류)
  - **보류 사유:** Llama-via-Groq의 한국어 출력이 79% 비율로 한자(简化字) 오염 (`影响`, `地政`, `不确定`, `投资`, `开`, `医` 등). 빈약한 한국어 학습 데이터 + 한중 토큰 혼동으로 추정. chain validation으로 reject + Gemini fallback 시도해봤으나 Gemini의 15 RPM 한도가 부하 못 받아 더 큰 손실(26% 성공률) 발생.
  - **재개 옵션:**
    1. `LLM_PROVIDER=gemini,groq` — Gemini를 primary로. 무료 유지, 한국어 품질 압도적으로 좋음, 영어도 양호. Throttle 4초 필요 (Gemini 15 RPM 한도). **가장 단순한 길.**
    2. Anthropic Claude Haiku 도입 — 유료(일 ~$0.01)지만 한국어/영어 둘 다 최고 품질 + 안정. 수익 검증 후 권장.
    3. KO 전용 보조 호출 — EN은 Groq, KO는 Gemini로 분리. 호출 수 2배.
  - **재개 시 코드 변경 범위:** `backend/summarizer/base.py` SYSTEM_PROMPT만 다시 EN+KO로. `chain.py` 의 KO validation도 재추가. DB/앱 코드는 그대로 (`summary_ko` 컬럼, device-locale 자동매칭, `language_explicit` 모두 유지됨).
- **(d) Anthropic Claude Haiku를 chain 최후 fallback으로 추가** — `LLM_PROVIDER=groq,gemini,anthropic`
  - 유료지만 비용 매우 작음 (일 약 $0.01, 26 articles × 200 in + 600 out 토큰 기준)
  - RPM/RPD 한도 매우 넉넉 → Groq 400 + Gemini 429 동시 발생해도 Claude가 받음 → 100% 근접
  - 전제: Anthropic 크레딧 이슈(아래 🟡 섹션) 해결
- **Groq 400 원인 분석** — 자주 실패하는 기사(MarketWatch, Yahoo의 일부) 패턴 파악 후 snippet sanitization 고려
- **Telegram bot 채널** — 동일 digest 파이프라인을 텔레그램으로도 fan-out (Phase 3, 미착수)

---

## 🟢 완료

### Phase 1 — 백엔드 파이프라인
- **프로젝트 구조 + README** (`D:\dev\NewsApp\README.md`, `.gitignore`)
- **Supabase DB 스키마** — `digests`, `articles`, `user_preferences` + RLS 정책 + 익명 사용자 prefs 자동 생성 트리거 (`supabase/migrations/0001_initial_schema.sql` → Supabase SQL Editor에서 이미 적용됨)
- **LLM Provider 추상화** — `.env`에서 `LLM_PROVIDER=anthropic|groq|glm` 한 줄로 전환 (`backend/summarizer/`)
- **RSS Fetcher + 클러스터링** — Bloomberg/Reuters/FT/CNBC/Yahoo Finance/MarketWatch 6개 소스 병렬 수집 → 토큰 기반 cross-source 클러스터링 → 상위 5건 선정 (`backend/fetcher.py`)
- **라이선스 정책 분기** — Bloomberg/FT는 `summarize=False` → 헤드라인 + 링크만 저장, 나머지는 AI 요약 (`backend/sources.py`)
- **main.py + Supabase upsert + GitHub Actions cron** — 매일 05:30 KST (20:30 UTC) 자동 실행 워크플로우 작성됨 (`.github/workflows/daily-digest.yml`) — 아직 GitHub Secrets 등록은 안 함
- **로컬 검증 성공** ✅ — 87개 기사 → 5건 선정 → Groq로 요약 → Supabase 저장 확인

### Phase 2a — Flutter Android 앱 스캐폴드
- **Flutter 프로젝트 생성** — Package: `kr.co.wkac.news_app` (`D:\dev\NewsApp\app\`)
- **의존성** — supabase_flutter, flutter_riverpod, go_router, url_launcher, flutter_dotenv, intl
- **모델** — `Article`, `Digest`, `UserPrefs` (`app/lib/models/`)
- **서비스** — `SupabaseService` (익명 로그인, digest fetch, prefs CRUD)
- **화면**:
  - `DigestListScreen` — 오늘의 Top 5 카드 리스트, 탭하면 원문 오픈
  - `SettingsScreen` — 알림 시간 피커, 언어 토글(ko/en), 소스 on/off
- **위젯** — `ArticleCard` — Bloomberg/FT는 링크 아이콘만, 나머지는 요약 표시
- **Material 3 라이트/다크 테마**
- **정적 분석 통과** — `flutter analyze` → No issues found
- **기기 확인** — Galaxy S24 Ultra (`R5KL301XDLZ`) USB 연결 상태 감지됨

---

## 🟡 진행 중 / 보류

### LLM 품질 이슈 — Anthropic 크레딧 문제 (보류)
- **현상**: Anthropic 콘솔에 $100 크레딧 있다고 표시되지만 API는 "credit balance too low" 400 반환
- **원인 추정**: (a) Claude.ai Pro/Max 구독 크레딧을 API 크레딧으로 착각, (b) 다른 조직/워크스페이스에 붙어있음
- **임시 대응**: `LLM_PROVIDER=groq`로 복귀 (무료, 한국어 3/5 정도 누락)
- **재개 시**: [console.anthropic.com/settings/billing](https://console.anthropic.com/settings/billing)에서 정확한 "Credit balance" 확인 → $0이면 $5 충전 → `.env`를 `LLM_PROVIDER=anthropic`으로 바꾸고 재실행

---

## 🔴 미완료 (로드맵)

### 즉시 다음 스텝 (Phase 2a 실행)
**점심 후 첫 작업 — 앱 실물로 돌려보기:**
1. Supabase → Authentication → **Allow anonymous sign-ins** 토글 ON (기본 OFF!)
2. Supabase → Project Settings → API Keys → **Publishable key** 복사
3. `D:\dev\NewsApp\app\.env`의 `PASTE_PUBLISHABLE_KEY_HERE` 자리에 붙여넣기
4. 실행:
   ```bash
   cd D:\dev\NewsApp\app
   flutter run -d R5KL301XDLZ
   ```
5. 본인 폰에 앱 설치됨 → 홈 화면에 오늘의 digest 5건 보여야 함

### Phase 2b — 로컬 알림 (서버 불필요)
- `flutter_local_notifications` 설정 (Android 알림 권한, notification channel)
- 사용자 설정 시간(`notify_time`)에 로컬 알림 예약
- 앱 실행 시 하루치 알림 스케줄링

### Phase 2c — FCM 원격 푸시
- Firebase 프로젝트 생성 + `google-services.json` 연결
- `firebase_messaging` 추가, 앱 실행 시 토큰 받아서 `user_preferences.fcm_token`에 저장
- Supabase Edge Function 또는 GitHub Actions 시간별 cron 추가 — 매 시간 `notify_time ± 5분` 사용자 조회 → FCM send
- 딥링크: 알림 탭 → 해당 기사 상세

### Phase 2d — AdMob 배너
- Google AdMob 가입 + 앱 등록
- `google_mobile_ads` 통합 — 하단 배너 1개
- Play Store 출시 직전 프로덕션 광고 유닛으로 전환

### Phase 3 — Telegram 봇
- `@BotFather`에서 봇 생성 + 토큰 발급
- Python `python-telegram-bot` 또는 직접 Bot API
- `/start` → `telegram_chat_id`를 `user_preferences` 테이블에 연결
- `/settime HH:MM`, `/setlang en|ko` 명령
- GitHub Actions 시간별 cron이 FCM과 함께 Telegram에도 fan-out

### Phase 4 — Play Store 출시 준비
- 앱 아이콘 + 스플래시 + 스토어 스크린샷
- 키스토어 서명 설정 (`android/key.properties`, release `build.gradle.kts`)
- Google Play Console 개발자 계정 가입 ($25 일회성)
- 내부 테스트 → 프로덕션 롤아웃

### Phase 5 — iOS 포팅
- macOS 머신 필요 (또는 Codemagic 같은 CI)
- Apple Developer Program 가입 ($99/yr)
- `ios/Runner/Info.plist` 푸시 알림 권한 등 조정
- App Store Connect 등록

---

## 📁 주요 경로 치트시트

| 용도 | 경로 |
|---|---|
| 백엔드 실행 | `cd D:\dev\NewsApp && .venv\Scripts\activate && python -m backend.main` |
| Flutter 실행 | `cd D:\dev\NewsApp\app && flutter run -d R5KL301XDLZ` |
| 백엔드 시크릿 | `backend\.env` (gitignored) |
| 앱 시크릿 | `app\.env` (gitignored) |
| DB 스키마 | `supabase\migrations\0001_initial_schema.sql` |
| cron 워크플로우 | `.github\workflows\daily-digest.yml` |

## 🔑 계정 상태

- ✅ Supabase 프로젝트 `sefkaalksvaiihlcjfvu` — 스키마 적용됨 (마지막 migration `0007_user_prefs_language_explicit.sql`까지)
- ✅ Groq API key — 작동 확인 (chain 1순위)
- ✅ Gemini API key — 작동 확인 (chain 2순위, fallback)
- ⚠️ Anthropic API key — 키는 있지만 크레딧 이슈로 401/400 (해결 시 chain 3순위 추가 예정)
- 🟡 Telegram Bot — 아직 생성 안 함 (Phase 3)
- 🟡 Firebase — 아직 생성 안 함 (Phase 2c)
- 🟡 Google AdMob — 아직 가입 안 함 (Phase 2d)
- 🟡 Google Play Console — 아직 가입 안 함 (Phase 4, $25)

---

## 🧠 중요 설계 결정 (기억용)

- **콘텐츠 라이선스**: Bloomberg/FT는 헤드라인만 (법적 리스크). 트래픽 생긴 후 Reuters Connect/BBG/FT syndication 협상.
- **수익 모델**: 무료 + AdMob (월 구독 아님)
- **언어**: 사용자가 ko/en 토글. 요약 파이프라인은 매일 양 언어 둘 다 생성.
- **Android 우선**: 본인 폰(Galaxy S24)으로 dogfood → 안정화 후 iOS.
- **스택**: Flutter(앱) + Supabase(auth/DB) + Python(백엔드) + GitHub Actions(cron) + LLM는 교체 가능한 추상화.
- **타깃**: 한국 금융/증권 업계 종사자 — 출근길 트렌드 빠른 파악.
