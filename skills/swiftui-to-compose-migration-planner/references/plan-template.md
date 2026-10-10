# Android Migration Plan: <Feature/Module Name>

> SwiftUI → Jetpack Compose. Fill every section. Delete guidance in angle brackets.

## 1. Overview & scope

- **Feature:** <name>
- **In scope:** <screens/flows included>
- **Out of scope:** <explicitly excluded>
- **iOS UI stack:** SwiftUI
- **Android UI stack:** Jetpack Compose
- **Detected Android stack:** <navigation / DI / networking / persistence / image
  loading libraries already used in the Android project, or "none — see decisions">

## 2. Source inventory

| Swift file | Role | Key state / dependencies | ~LOC |
|---|---|---|---|
| <path> | <view / view model / service> | <@State, view model, services> | <n> |

## 3. Target structure (mirrors iOS)

> Keep business logic (ViewModels, Repositories, Models) strictly separated from
> Compose UI, so it could later be lifted into a shared Kotlin Multiplatform (KMP)
> module. UI-free logic → `domain`/`data`; Compose UI → `presentation`/`ui`.
> ViewModels sit in `presentation` but must not import Compose.

| iOS source | Android target file | Destination path |
|---|---|---|
| <FeatureView.swift> | <FeatureScreen.kt> | <feature/.../presentation/> |
| <FeatureViewModel.swift> | <FeatureViewModel.kt> | <feature/.../presentation/> |
| <FeatureService.swift> | <FeatureRepository.kt> | <feature/.../data/> |

## 4. Component & state mapping

<Per screen: the SwiftUI hierarchy → Compose equivalents, using the mapping cheat
sheet. Call out state ownership and where @Binding becomes hoisted state.>

| SwiftUI construct | Compose equivalent | Note / risk |
|---|---|---|
| <VStack + @State> | <Column + remember{mutableStateOf}> | — |

## 5. Navigation mapping

<Entry points, destinations, sheets/alerts, back handling. NavigationStack →
NavHost routes; sheets → bottom sheets/dialogs; add BackHandler where needed.>

## 6. Data, async & services

<Combine→Flow, async/await→coroutines, networking client, persistence, secure
storage. One row per dependency.>

## 7. Testing mapping

<Map existing XCTest/XCUITest suites to their Android equivalents.>

| iOS test file | Android target | Type (Unit/UI) |
|---|---|---|
| <FeatureViewModelTests.swift> | <FeatureViewModelTest.kt> | Unit (JUnit/MockK) |
| <FeatureUITests.swift> | <FeatureScreenTest.kt> | UI (Compose Test Rule) |

## 8. Risks & open questions

- <Platform-only behavior with no clean Android equivalent>
- <Third-party SDK needing an Android replacement>
- <Behavioral/parity differences to confirm with design/PM>

## 9. Decision points (unresolved stack choices)

- <e.g. Navigation library, DI framework, HTTP client — only if not already set>

## 10. Task breakdown

Ordered, independently ticketable where possible. Size = S/M/L.

| # | Task | Depends on | Size |
|---|---|---|---|
| 1 | Scaffold Android module structure mirroring iOS | — | S |
| 2 | Port <ViewModel> state + logic | 1 | M |
| 3 | Build <Screen> Compose UI | 2 | M |
| 4 | Wire navigation + back handling | 3 | S |
| 5 | Port data/service layer | 1 | M |
| 6 | Resources (strings, colors, icons) | 1 | S |

## 11. Parity / definition of done

- [ ] Visual parity with iOS screen(s)
- [ ] State & side effects behave equivalently (loading, error, empty)
- [ ] Navigation (forward + back/gesture) matches
- [ ] Data/async paths tested
- [ ] Unit/UI tests ported and passing
- [ ] Localized strings (incl. plurals), colors, icons in place
- [ ] Accessibility parity (content descriptions, headings, large font scale)
- [ ] Edge-to-edge / window insets correct on all screens
