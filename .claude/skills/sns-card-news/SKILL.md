---
name: sns-card-news
description: SNS 카드뉴스·커버·썸네일 세트 제작 스킬. 여행/마케팅 캠페인용 인스타그램 카드뉴스(1080×1080 5장), SNS 커버(1200×630), 썸네일(1200×630)을 도쿄 2박3일 캠페인과 동일한 품질로 만들 때 사용. "카드뉴스", "SNS 이미지", "썸네일", "커버", "card news", "SNS assets" 요청 시 반드시 먼저 읽는다.
---

# SNS 카드뉴스 세트 제작 스킬

이 스킬은 `sns/images/`의 도쿄 2박3일 캠페인(기준 작업물)을 역설계한 것이다.
**여기 적힌 순서와 스펙을 그대로 따르면 모델 성능과 무관하게 동일한 품질이 나온다.**
스펙을 "참고"하지 말고 "준수"할 것. 창의성은 카피와 사진 선택에서 발휘하고, 레이아웃·토큰에서는 발휘하지 않는다.

## 0. 절대 원칙 (실패의 90%를 막는 규칙)

1. **텍스트는 HTML/CSS로 조판한다.** 이미지 생성 모델에 한글 텍스트를 넣으라고 시키면 반드시 깨진다. 이미지 모델의 역할은 배경 사진 소재까지만.
2. **모든 카피에 구체적 숫자를 넣는다.** "맛집 추천" ❌ → "타베로그 3.5+ 맛집 8곳" ⭕. 가격(엔), 시간, 도보 분, 평점, 높이(m) 중 최소 1개가 모든 정보 블록에 있어야 한다.
3. **렌더 → Read로 눈검수 → 수정**을 최소 1회 반복한다. 첫 렌더를 그대로 최종본으로 쓰지 않는다.
4. 모르는 정보(가격·운영시간·평점)는 웹 검색으로 확인하거나, 확인 불가 시 범위로 표기한다("100~150엔", "30분~1시간 예상"). 그럴듯한 단정 수치를 지어내지 않는다.

## 1. 산출물 세트 (1캠페인 = 7파일)

| 파일 | 크기 | 역할 | 템플릿 |
|---|---|---|---|
| `thumbnail.png` | 1200×630 | 훅 헤드라인 + 통계 칩 4개 | `templates/wide_banner.html` (variant A) |
| `sns_cover.png` | 1200×630 | 헤드라인 + 하이라이트 카드 3개 + CTA 버튼 | `templates/wide_banner.html` (variant B) |
| `card_news_1.png` | 1080×1080 | 훅 카드: 질문형 헤드라인 + Day1~3 미리보기 | `templates/card_news.html` |
| `card_news_2.png` | 1080×1080 | Day 1 상세 (오전/오후/저녁 3스팟) | `templates/card_news.html` |
| `card_news_3.png` | 1080×1080 | Day 2 상세 | `templates/card_news.html` |
| `card_news_4.png` | 1080×1080 | Day 3 상세 | `templates/card_news.html` |
| `card_news_5.png` | 1080×1080 | 요약 + CTA (FOOD / ITINERARY / TIP 3열) | `templates/card_news.html` |

## 2. 디자인 토큰 (변경 금지 — 새 캠페인은 배경 사진과 카피만 교체)

```css
/* 색상 */
--bg-navy:      #171233;   /* 카드뉴스 베이스 다크 네이비 */
--bg-navy-2:    #241a4f;   /* 그라데이션 보조 */
--footer-navy:  #1e1745;   /* 푸터 스트립 */
--accent:       #ffd94a;   /* 옐로 — 강조 단어, 숫자, CTA, 칩 테두리 */
--text-white:   #ffffff;
--text-sub:     rgba(255,255,255,0.72);  /* 서브라인, 상세 불릿 */
--text-dim:     rgba(255,255,255,0.55);  /* 원어 지명 등 최하위 정보 */
/* 와이드 배너 배경: 보라→마젠타→오렌지 대각 그라데이션
   background: linear-gradient(115deg, #3b1e63 0%, #7a2f7a 45%, #c95b2e 100%); 위에
   radial-gradient 광원 1~2개를 얹어 깊이감 부여 */

/* 타이포 — 폰트 스택 고정 */
font-family: Pretendard, "Noto Sans CJK KR", "Noto Sans KR", sans-serif;
/* 아이브로(영문 라벨): 13~15px, letter-spacing 0.35em, 대문자, 색 --accent 또는 white 70% */
/* 헤드라인: 카드뉴스 64px / 와이드 72px, weight 800, line-height 1.25, 2~3줄 */
/*   → 핵심 단어 1개(코스명·"완벽" 류)만 <span class="hl">로 옐로 처리 */
/* 서브라인: 26~28px, --text-sub */
/* 본문 불릿: 22~24px, --text-sub, line-height 1.6 */
/* 칩/뱃지: 20~22px bold */
```

**질감 규칙:** 단색 배경 금지. 다크 네이비 위에도 미세한 radial-gradient 광원을 얹는다. 사진 위 텍스트 영역에는 반드시 상/하단 그라데이션 오버레이(`linear-gradient(180deg, rgba(23,18,51,.92), transparent 30%)` 및 하단 대칭)를 깔아 대비를 확보한다.

## 3. 레이아웃 스펙

### 3-1. 카드뉴스 (1080×1080) — 3열 트립틱 구조

```
┌──────────────────────────────────────────┐
│ [필 뱃지: 이모지+라벨]        ← 좌상단 48px 여백 │
│ 헤드라인 2줄 (흰색, 강조어 옐로)              │
│ 서브라인: A → B → C (루트 요약, dim)         │
│                                          │
│ ← 배경: 세로 사진 3장 풀블리드, 열 사이 2px 갭 → │
│   (각 열 위에 다크 오버레이, 상단 진하게)        │
│                                          │
│ 각 열 하단 정보 블록 (아래에서 위로):            │
│   TIME 라벨 (08:00 AM, letterspace, 옐로)   │
│   이모지 아이콘 (40px)                       │
│   스팟명 2줄 (28px bold white)              │
│   원어 지명 (浅草寺·仲見世通り, dim, 18px)      │
│   상세 불릿 3줄 (숫자 포함 필수)               │
│   ┌ 옐로 테두리 칩: 가격/팁 ┐                 │
├──────────────────────────────────────────┤
│ 푸터 스트립 56px: 캠페인명 · [옐로 하이라이트 문구] │
└──────────────────────────────────────────┘
```

- **card 1 (훅):** 헤드라인은 질문형("어디서부터 시작해야 할까요?"). 3열 = Day1/2/3 미리보기. 열마다 스팟 3개 나열 + 성격 칩("전통 & 감성" 류).
- **card 2~4 (Day 상세):** 뱃지 = 📅 DAY N. 3열 = 오전/오후/저녁 스팟. TIME 라벨 필수. 칩 = 가격 또는 예약 팁.
- **card 5 (요약+CTA):** 뱃지 = 시즌 라벨. 3열 아이브로 = FOOD / ITINERARY / SUMMER TIP 류 영문. 칩 대신 옐로 배경 CTA 버튼("맛집 전부 보기 →").

### 3-2. 썸네일 (1200×630, variant A)

좌측 55% 텍스트 존: 필 뱃지 2개(시즌 특집 마젠타 배경 + 타깃 아웃라인) → 헤드라인 2줄(2행 전체 옐로) → 서브 2줄 → **통계 칩 4개** (반투명 카드, 큰 숫자 옐로 34px + 아래 라벨 18px. 예: `3일/완전 일정`, `8곳/맛집 검증`, `3.5+/타베로그`, `229m/시부야스카이`). 우측 45%: 오렌지 광원 그라데이션 (사진 없음).

### 3-3. 커버 (1200×630, variant B)

좌측: 영문 아이브로("2026 SUMMER TOKYO GUIDE") → 헤드라인 3줄(중간 행 옐로) → 서브 2줄(Day 요약 + 검증 포인트). 우측: 반투명 하이라이트 카드 3개 세로 스택(이모지 타일 + 제목 bold + 서브 dim) + 맨 아래 **옐로 배경 CTA 버튼** 2줄("전체 일정 + 맛집 링크 / 블로그에서 확인하기", 검정 텍스트).

## 4. 카피라이팅 공식

- **헤드라인:** `<대상> + <단정적 약속>`. "도쿄 2박3일 / 이 코스면 / 완벽해요" 패턴. 강조 1단어만 옐로. 물음표 훅은 card 1 전용.
- **신뢰 장치:** 반드시 외부 검증 소스를 1개 이상 인용 — "타베로그 인증", "타베로그 3.49", "OO역 도보 5분", "2주 전 예약 필수".
- **서브라인:** 루트를 `A → B → C` 화살표로 압축.
- **상세 불릿 3줄 구성:** ①할 것/볼 것 ②실전 팁(시간대·좌석·인파) ③숫자(가격·평점·소요).
- **원어 병기:** 지명·상호는 현지어 원문을 dim 텍스트로 병기 (浅草寺·仲見世通り / SHIBUYA SKY 229m). 신뢰도를 크게 올리는 디테일이므로 생략 금지.
- **CTA:** 행동 + 위치. "전체 일정 + 맛집 링크 블로그에서 확인하기", "팁 전부 보기 →".
- 금지: 감탄사 남발, "꿀팁", 이모지 3개 이상 연속, 숫자 없는 추상 문장("정말 맛있는 맛집").

## 5. 제작 파이프라인 (순서대로 실행)

### Step 1 — 환경 준비 (렌더 전 1회)

```bash
# 한글 폰트 확인 — 없으면 설치 (이 컨테이너는 기본 미설치)
fc-list | grep -qi "Noto Sans CJK" || {
  apt-get install -y fonts-noto-cjk fonts-noto-color-emoji 2>/dev/null \
  || sudo apt-get install -y fonts-noto-cjk fonts-noto-color-emoji
  fc-cache -f
}
# Pretendard가 있으면 더 좋음 (선택): jsDelivr에서 받아 ~/.fonts에 설치 후 fc-cache -f
# Chromium은 /opt/pw-browsers/chromium 에 이미 있음 — playwright install 금지
```

### Step 2 — 캠페인 브리프 정리

스크래치패드에 `brief.md`로 정리: 목적지/기간, Day별 오전·오후·저녁 스팟(각각 원어 지명, 가격, 시간, 팁), 검증 소스(평점), 시즌 한정 요소, 타깃, CTA 목적지. **숫자가 비어 있으면 웹 검색으로 채운 뒤에** 다음 단계로 간다.

### Step 3 — 배경 사진 소재 (카드뉴스용 세로 사진)

이미지 생성 MCP(`generate_image`)로 열당 1장, 세로 구도(권장 프롬프트 방향: 실사 여행 사진, 시네마틱, 어두운 톤 — 위에 오버레이가 얹히므로 밝아도 무방하나 텍스트 없는 구도로). **사진 안에 글자를 요구하지 않는다.** 저장은 스크래치패드에.

### Step 4 — 템플릿 채우고 렌더

`templates/card_news.html`, `templates/wide_banner.html`을 스크래치패드로 복사해 카피·사진 경로만 교체. 렌더 스크립트:

```js
// render.mjs — node render.mjs <html> <out.png> <width> <height>
import { chromium } from 'playwright';
const [,, htmlPath, outPath, w, h] = process.argv;
const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium/chrome-linux/chrome' });
const page = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 2 });
await page.goto('file://' + htmlPath, { waitUntil: 'networkidle' });
await page.waitForTimeout(400); // 폰트/이미지 안착
await page.screenshot({ path: outPath });
await browser.close();
```

2배 스케일 PNG가 나오므로 필요 시 `python3 -c "from PIL import Image; ..."` 또는 ImageMagick으로 목표 크기로 리사이즈한다. (chromium 실행 파일 경로는 `ls /opt/pw-browsers/chromium*` 로 실제 위치를 먼저 확인.)

### Step 5 — QA 체크리스트 (렌더된 PNG를 Read로 열어 전 항목 확인)

- [ ] 텍스트 잘림/오버플로 없음 (특히 스팟명 2줄, 칩 안 긴 문구)
- [ ] 모든 정보 블록에 숫자 1개 이상
- [ ] 원어 지명 병기됨
- [ ] 헤드라인 강조어 옐로 처리 정확히 1곳 (card 1 질문형 제외 가능)
- [ ] 사진 위 텍스트 대비 충분 (오버레이 진하기 확인)
- [ ] TIME 라벨·아이브로 letter-spacing 적용됨
- [ ] 푸터 스트립 존재, 캠페인명 일관
- [ ] 7개 파일 세트 완성, 크기 정확 (1080×1080 / 1200×630)
- [ ] 5장 카드가 훅→Day1→Day2→Day3→요약CTA 서사로 이어짐

실패 항목은 HTML 수정 → 재렌더 → 재검수. 통과본만 `sns/<campaign>/images/`로 이동 후 커밋.

## 6. 흔한 실패 패턴 (하지 말 것)

| 실패 | 교정 |
|---|---|
| 이미지 모델에 "한글 카드뉴스 만들어줘" 프롬프트 | 텍스트는 무조건 HTML 조판 |
| 폰트 미설치 상태로 렌더 → 두부(□) 글자 | Step 1 폰트 확인 먼저 |
| 카피에 숫자 없이 형용사만 | 공식 4번 준수, 검색으로 숫자 확보 |
| 옐로를 여기저기 남용 | 강조는 헤드라인 1곳 + 숫자/칩/CTA로 한정 |
| 배경을 단색으로 깔기 | 그라데이션+광원 필수 (토큰 참조) |
| 첫 렌더를 검수 없이 커밋 | Step 5 체크리스트 통과 전 커밋 금지 |
| 카드마다 레이아웃을 새로 발명 | 템플릿 구조 고정, 내용만 교체 |
