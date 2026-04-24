# NewsApp 진행 현황 (2026-04-22)

점심 후 이어서 작업용 상태 스냅샷.

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

- ✅ Supabase 프로젝트 `sefkaalksvaiihlcjfvu` — 스키마 적용됨
- ✅ Groq API key — 작동 확인
- ⚠️ Anthropic API key — 키는 있지만 크레딧 이슈로 401/400
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
