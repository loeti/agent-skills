---
name: swiftui-to-compose-migration-planner
description: >-
  Analyze a SwiftUI feature or module and produce a structured Android (Jetpack
  Compose) migration plan plus a granular, ticket-ready task breakdown. Mirrors
  the existing iOS module/feature structure on the Android side and detects the
  rest of the target stack at run time. Use when planning an iOS→Android port,
  asked for a "migration plan", "porting plan", "SwiftUI to Compose", "port this
  screen/feature to Android", or estimating migration effort. This skill PLANS
  the migration; it does not translate the code line-by-line.
---

# SwiftUI → Compose Migration Planner

Produce a migration plan for porting a SwiftUI feature/module to Android + Jetpack
Compose. The deliverable is a written plan and an ordered task breakdown — not the
ported code. Aim for a plan another engineer could execute without re-reading the
whole iOS codebase.

## When to use

Use when the user wants to **plan** (not yet write) an iOS→Android port of a
screen, feature, or module. If the user actually wants code translated now, plan
first, then offer to execute the tasks.

## Inputs to establish first

Before analyzing, confirm (ask only for what you can't infer from the repo):

1. **Scope** — which SwiftUI screen/feature/module is being ported. Get concrete
   file paths or a feature name that maps to files.
2. **Target Android location** — where the Android project/module lives (or that
   it doesn't exist yet). The plan mirrors the iOS structure here.
3. **Existing Android stack** — inspect the Android side for already-chosen
   libraries (navigation, DI, networking, persistence, image loading). If none
   exists, note it as a decision point rather than assuming one.

## Workflow

1. **Inventory the SwiftUI source.** Read the in-scope files. Catalog: the view
   hierarchy, state ownership (`@State`/`@Binding`/`@StateObject`/
   `@EnvironmentObject`/`@Environment`), navigation entry/exit points, side
   effects (`.onAppear`/`.task`/timers), and every dependency the views reach
   (view models, services, networking, persistence, platform APIs).

2. **Map structure.** Mirror the iOS module/feature folder layout on the Android
   side (see the source→target table in the plan template). Produce a file-by-file
   mapping: each Swift file → its Kotlin counterpart(s) and destination path.

3. **Map components & state.** Translate each SwiftUI construct to its Compose
   equivalent using `references/swiftui-compose-mapping.md`. Note where the
   mapping is imperfect (state hoisting, lifecycle differences, navigation model
   changes) — those become tasks and risks, not silent assumptions.

4. **Map data, async, and services.** Combine→Flow, async/await→coroutines,
   URLSession→the project's HTTP client, Core Data/SwiftData→Room,
   UserDefaults→DataStore, Keychain→Android Keystore (+ Tink-encrypted DataStore).
   Flag any iOS-only capability with no clean Android equivalent.

5. **Map the tests.** Inventory the feature's XCTest/XCUITest suites and map each
   to its Android equivalent — unit tests → JUnit/MockK, UI tests → the Compose
   test rule. Note any iOS test that has no clean Android counterpart.

6. **Surface risks & open questions.** Platform-only behavior, third-party SDKs
   needing Android replacements, behavioral parity gaps, and any stack decisions
   the team still owes.

7. **Write the plan.** Use `references/plan-template.md`. Save it into the repo
   under a sensible docs path (e.g. `docs/migration/<feature>-android-plan.md`);
   confirm the location if ambiguous. End with the **ordered task breakdown**:
   each task independently ticketable, with dependencies noted and a T-shirt size
   (S/M/L).

## Principles

- **Mirror, don't reinvent.** The Android structure should be recognizable to
  someone who knows the iOS one. Only diverge where the platform forces it, and
  say why.
- **Name the imperfect mappings.** SwiftUI↔Compose is mostly clean, but state
  hoisting, navigation, and lifecycle differ. Call these out explicitly.
- **No silent stack choices.** If the Android target hasn't picked a navigation/
  DI/persistence library, list it as a decision point — don't bury an assumption
  inside a task.
- **Plans are executable.** Tasks are ordered, sized, and scoped so they map to
  real tickets and can be done independently where possible.
- **Preserve naming conventions.** Keep class, variable, and function names
  identical to iOS where semantically appropriate. Adapt only for language
  standards (e.g. Swift `FooProtocol` → Kotlin interface `Foo` with impl
  `DefaultFoo`; Swift `Foo+Extensions.swift` → Kotlin `FooExt.kt`).
- **Separate logic from UI (KMP-ready).** Keep business logic (ViewModels,
  Repositories, Models) strictly separated from Compose UI code. ViewModels live
  in `presentation/` but must not import Compose. Structure the Android side so
  it could later be lifted into a shared Kotlin Multiplatform (KMP) module —
  prefer KMP-capable libraries (Ktor, kotlinx.serialization, Room, DataStore,
  `androidx.lifecycle.ViewModel`) when the project hasn't chosen yet.
- **Target the latest on both sides.** The iOS source is assumed to use the
  newest frameworks and OS APIs available; produce the Android plan against the
  latest stable Kotlin, Compose, and AndroidX/Jetpack APIs — not deprecated or
  legacy equivalents. When mapping, prefer the modern API (e.g. `@Observable` →
  ViewModel + `StateFlow`, not legacy patterns) and flag anything that requires a
  high `minSdk`.

## References

- `references/swiftui-compose-mapping.md` — construct-by-construct cheat sheet
  (state, layout, components, navigation, modifiers, accessibility, async, data,
  resources).
- `references/plan-template.md` — the output document structure to fill in.
