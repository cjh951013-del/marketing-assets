# 월 100만원 수익 파이프라인 설계서

> 보유 자산: **Claude Pro · Gemini Pro · Google Antigravity · Canva Pro** + **Etsy · Payoneer · Gumroad 계정**
> 가용 시간: **하루 2시간** / 타겟: **국내외 무관** / 목표: **월 1,000,000원 (≈ $730)**
> 작성일: 2026-06-20 · 기준 환율 약 1,370원/$

---

## 0. 먼저, 솔직한 현실 점검 (devil's advocate)

요청하신 "많이 동작하지 않아도, 어렵지 않게 월 100"은 **결론부터 말하면 도달 가능하지만, '거의 무노동 패시브'는 환상**입니다. 데이터가 그렇게 말합니다:

- Etsy 셀러의 **65%는 연 $100(약 13만원)도 못 법니다.** ([Insight Agent](https://www.insightagent.app/guides/average-etsy-seller-income))
- 첫 판매까지 보통 **30~60일**, 월 $1,000~3,000(=목표 구간)에 도달하는 셀러는 보통 **6~12개월** 걸립니다. ([SideQuestHustle](https://sidequesthustle.com/guides/what-etsy-sellers-actually-make))
- **3~6개월차에 포기하는 사람이 변곡점 직전에 그만둡니다.** 이게 가장 흔한 실패 패턴입니다.

**즉, 진짜 변수는 "재능"이 아니라 "90일을 버티며 매주 출시하느냐"입니다.**
하루 2시간이면 충분합니다. 단, 그 2시간을 **"제작"이 아니라 "AI에게 제작을 시키고 나는 출시·SEO·반복"에 쓰는 구조**여야 합니다. 그게 이 보유 도구 조합의 핵심 레버리지입니다.

이 문서는 그 구조를 그대로 설계해 둔 것입니다.

---

## 1. 왜 "디지털 상품 (Etsy + Gumroad 듀얼채널)"이 정답인가

가진 자산으로 가능한 후보를 전부 비교한 결과입니다.

| 파이프라인 | 월 100 도달 신뢰도 | 일 2시간 적합도 | 수익화까지 기간 | 천장(상한) | 판정 |
|---|---|---|---|---|---|
| **디지털 상품 (Etsy+Gumroad)** | ★★★★★ | ★★★★★ | 1~3개월 | 중상 | **✅ 메인 엔진** |
| 페이스리스 영상(Veo/YouTube) | ★★☆ | ★★☆ | 4~8개월+ | 상 | 🔸 증폭기(2단계) |
| 마이크로 SaaS(Antigravity) | ★★★ | ★★☆ | 2~5개월 | 최상 | 🔸 증폭기(2단계) |
| 외주/대행(크몽 등) | ★★★★ | ★★☆ | 즉시 | 낮음(시간=돈) | ❌ 시간 종속 |

**디지털 상품이 메인인 이유:**
1. **Etsy = 공짜 검색 트래픽.** 광고 없이도 구매 의도 높은 유입이 들어옵니다. (마케팅 부담 ↓)
2. **한 번 만들면 무한 판매**, 재고·배송 0, 마진 85~90%. ([litcommerce](https://litcommerce.com/blog/digital-products-to-sell-on-etsy/))
3. **Canva Pro + Claude/Gemini가 제작 시간을 1/10로** 압축 → 하루 2시간에 주 3~5개 출시 가능.
4. **Payoneer로 USD 정산** → 환율 + 글로벌 단가(국내보다 2~3배)로 달러 수익.

페이스리스 영상·SaaS는 **천장은 더 높지만 수익화 runway가 길고 매일 손이 갑니다.** 그래서 "어렵지 않게 빨리 100만원"에는 디지털 상품이 정확히 맞고, 둘은 base가 돌기 시작한 뒤 얹는 **증폭기**로 배치합니다.

---

## 2. 수익 구조의 숫자 (목표 역산)

목표 $730/월을 채우는 3가지 경로 — **실제로는 셋을 섞습니다.**

| 모델 | 채널 | 객단가(순수익) | 필요 판매량 | 하루 환산 |
|---|---|---|---|---|
| 저가 대량 | Etsy | $10 | **73건/월** | 2.4건/일 |
| 중가 번들 | Gumroad | $25 | **30건/월** | 1건/일 |
| 혼합(권장) | Etsy+Gumroad | 평균 $14 | **~52건/월** | 1.7건/일 |

**현실적 조합 (6개월차 목표 그림):**
- Etsy 리스팅 **40개**, 각 월 1~3건 → 약 60~70건 → **$650**
- Gumroad 번들 **3~4종**, 월 합산 10건 → **$250**
- 합계 **≈ $900 (약 123만원)** → 목표 초과 달성 구조

핵심: **리스팅 개수가 곧 매출입니다.** 40개 리스팅이 "복권 40장"이고, AI가 그걸 싸게 찍어줍니다.

---

## 3. 니치 선정 — "생산성 + 스몰비즈니스" 쐐기

2026년 잘 팔리는 카테고리(리서치 기반) 중, **재사용 가능한 디자인 시스템 하나로 대량 변주 가능 + 객단가 높음 + AI 친화적**인 교집합을 노립니다.

**1순위 메인 니치 (택1 집중):**
- **Notion 템플릿** — Gumroad의 최강 카테고리. 프리랜서 인보이스, 콘텐츠 크리에이터 워크플로, ADHD 데일리 플래너, 구직 트래커 등 **구체적 니치일수록 잘 팔림.** 객단가 $15~49. ([Kupkaike](https://kupkaike.com/blog/how-to-sell-notion-templates-gumroad-2026))
- **Canva 소셜미디어 템플릿 팩** — 소상공인·코치·부동산 대상. Canva Pro의 Bulk Create로 대량 생산. ([mydesigns](https://mydesigns.io/blog/digital-products-to-sell-on-etsy/))

**2순위 보조 (메인 디자인 자산 재활용):**
- 예산/재무 스프레드시트, 프린터블 플래너, 결혼 초대장 템플릿, AI 프롬프트 팩.

> **devil's note:** "디지털 월아트/AI 그림"은 진입은 쉽지만 **레드오션 + Etsy의 AI 콘텐츠 정책 리스크**가 있어 메인으로 비추천. 보조로만.

**추천 결정:** 메인 = **Notion 템플릿 (Gumroad 주력) + 동일 시스템의 Canva 버전 (Etsy 주력)**.
하나의 "생산성 시스템"을 만들어 Notion판/Canva판/PDF판으로 **3채널 변주** → 제작 1회, 판매처 3곳.

---

## 4. 도구별 역할 분담 (이게 당신의 '불공정 우위')

| 도구 | 파이프라인에서의 역할 |
|---|---|
| **Claude Pro** | 니치 리서치, SEO 제목/태그 13개 생성, 상품 설명 카피, 번들 기획, 고객 응대 템플릿, 이 전략의 실행 코치 |
| **Gemini Pro** | 이미지(Imagen)로 목업/썸네일, Veo로 상품 소개 영상(증폭기), Google 생태계 트렌드 리서치 |
| **Canva Pro** | **Bulk Create**로 템플릿 수십 종 일괄 생산, 브랜드 키트로 일관성, Mockup으로 리스팅 사진 |
| **Antigravity** | (2단계) Notion 템플릿의 **컴패니언 웹툴**(예: 예산 계산기) 제작 → 트립와이어/업셀, 또는 마이크로 SaaS |
| **Etsy** | 공짜 검색 트래픽 → 저가 대량 진입점 |
| **Gumroad** | 고마진(수수료 ~10%) 번들 + 크리에이터 오디언스 + 이메일 수집 |
| **Payoneer** | Etsy/Gumroad USD → 원화 정산 |

---

## 5. 90일 실행 플랜 (하루 2시간 기준)

### 🟢 Phase 1 — 셋업 & 첫 출시 (Day 1~14)
- [ ] **Day 1–2:** 메인 니치 1개 확정. Claude로 "이 니치에서 가장 고통받는 구체적 사용자 + 그들이 검색하는 키워드 20개" 도출.
- [ ] **Day 3–4:** Etsy 샵 개설(이미 계정 보유), 프로필·정책·배너(Canva) 세팅. Gumroad 프로필 세팅.
- [ ] **Day 5–10:** Canva Bulk Create로 **첫 10개 리스팅** 제작. Claude로 각 리스팅 SEO 제목+태그 13개+설명 작성.
- [ ] **Day 11–14:** 10개 전부 업로드. Gumroad에 동일 자산 **번들 1종($19~29)** 등록.
- **목표:** 14일 안에 **라이브 리스팅 10개 + 번들 1개.**

### 🟡 Phase 2 — 출시 리듬 & 첫 매출 (Day 15~45)
- [ ] **매주 5개 리스팅 추가** (하루 1개 페이스). → 45일차 누적 ~30개.
- [ ] Pinterest 계정 개설 → 리스팅마다 핀 2~3개(Canva 자동) → **무료 외부 트래픽**.
- [ ] 첫 판매 데이터로 Claude에게 "팔리는 것 vs 안 팔리는 것" 분석 시켜 **더블다운**.
- **목표:** 첫 판매(보통 이 구간), 월 $100~300 진입.

### 🔵 Phase 3 — 확장 & 증폭기 탑재 (Day 46~90)
- [ ] 리스팅 **40+개**로 확장. 베스트셀러의 변주판 집중 생산.
- [ ] Gumroad 번들 **3~4종**으로 확장(가격 사다리: $9 / $29 / $49).
- [ ] **증폭기 1 (Antigravity):** 메인 템플릿의 컴패니언 웹툴 제작 → 무료 리드마그넷 or $5 트립와이어.
- [ ] **증폭기 2 (Gemini Veo):** 상품 소개 8초 영상 → Pinterest/Shorts/Reels에 뿌려 트래픽 확대.
- **목표:** 월 $500~900 (목표 100만원 도달/근접).

> 상세 주차별 체크리스트는 [`90-day-action-plan.md`](./90-day-action-plan.md) 참고.

---

## 6. 리스크 & 대응

| 리스크 | 대응 |
|---|---|
| Etsy 신규샵 노출 저조 | 리스팅 개수로 돌파(복권 효과) + Pinterest 외부 트래픽 병행 |
| 니치 포화 | "구체적 하위 니치"로 좁히기(예: 플래너 X → "프리랜서 디자이너용 세금 플래너") |
| Etsy 디지털 정책/AI 콘텐츠 규정 | 순수 AI아트 메인 회피, 본인 가공·편집 가치 추가, Gumroad로 리스크 분산 |
| 3~6개월차 동기 저하(최대 리스크) | 90일 출시 KPI를 "매출"이 아닌 "주 5개 출시"로 고정 — 통제 가능한 지표로 |
| 단일 채널 의존 | Etsy(트래픽) + Gumroad(마진) 듀얼 + 이메일 리스트 자산화 |

---

## 7. 지금 바로 할 일 (Day 1)

1. **메인 니치 1개 결정** (Notion 생산성 템플릿 추천).
2. Claude에게: *"[니치]에서 돈 내고 문제를 해결할 사용자 5명의 페르소나와, 그들이 Etsy/구글에 검색하는 키워드 20개, 첫 출시할 템플릿 10개 아이디어를 표로 줘."*
3. Canva Pro 열어 브랜드 키트 1개 + 첫 템플릿 1개 제작.
4. Etsy 샵 골격 세팅.

**완벽 말고 출시. 첫 10개를 14일 안에 올리는 것이 이 모든 계획의 전부입니다.**

---

### 출처
- [What Etsy Sellers Actually Make in 2026](https://sidequesthustle.com/guides/what-etsy-sellers-actually-make)
- [Average Etsy Seller Income — Insight Agent](https://www.insightagent.app/guides/average-etsy-seller-income)
- [33+ Best Digital Products to Sell on Etsy in 2026 — litcommerce](https://litcommerce.com/blog/digital-products-to-sell-on-etsy/)
- [Digital Products to Sell on Etsy 2026 — mydesigns](https://mydesigns.io/blog/digital-products-to-sell-on-etsy/)
- [Best Selling Digital Products on Gumroad 2026 — conversionproplus](https://conversionproplus.com/blog/gumroad-trends-2026-what-s-selling-right-now)
- [How to Sell Notion Templates on Gumroad 2026 — Kupkaike](https://kupkaike.com/blog/how-to-sell-notion-templates-gumroad-2026)
- [Build with Google Antigravity — Google Developers Blog](https://developers.googleblog.com/build-with-google-antigravity-our-new-agentic-development-platform/)
- [How to Build a Faceless Video Business with Veo 3 — aifire](https://www.aifire.co/p/how-to-build-a-faceless-video-business-with-google-veo-3-ai)
