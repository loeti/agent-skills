# SwiftUI → Jetpack Compose mapping cheat sheet

Use this to translate constructs during planning. Where a mapping is imperfect,
the "Notes" flag what to watch — turn those into tasks/risks in the plan.

## State & data flow

| SwiftUI | Compose | Notes |
|---|---|---|
| `@State` | `var x by remember { mutableStateOf(...) }` | Local UI state. `rememberSaveable` to survive config changes. |
| `@Binding` | Value + `onValueChange: (T) -> Unit` (state hoisting) | Compose has no two-way binding; hoist state to caller. Biggest structural difference. |
| `@StateObject` / `@ObservedObject` | `androidx.lifecycle.ViewModel` | Expose `StateFlow`/`State`; collect with `collectAsStateWithLifecycle()`. |
| `ObservableObject` + `@Published` | ViewModel exposing `StateFlow` or `mutableStateOf` | — |
| `@Observable` (macro) | ViewModel with `StateFlow` or `mutableStateOf` | Replaces `ObservableObject` in iOS 17+. |
| `@Bindable` | State hoisting (value + callback) | Same pattern as `@Binding` — no two-way binding in Compose. |
| `@FocusState` | `FocusRequester` + `Modifier.focusRequester()` / `onFocusChanged` | — |
| `@Environment(\.scenePhase)` | Screen: `LifecycleEventEffect` / `LifecycleResumeEffect` / `LifecycleStartEffect`; app-wide: `ProcessLifecycleOwner` | Very important for app-backgrounding logic. App-level `scenePhase` ≈ process lifecycle, not Activity lifecycle. |
| `@EnvironmentObject` / `@Environment(Type.self)` | Shared/scoped ViewModel or `CompositionLocal` | Prefer a nav-graph-scoped ViewModel (provided via the project's DI) over CompositionLocal for real state. |
| `@Environment(\.…)` | `CompositionLocal` (`LocalContext`, `LocalConfiguration`, …) | — |
| `@AppStorage` | Jetpack DataStore (Preferences) | SharedPreferences only if legacy. |
| `@Query` (SwiftData) / `@FetchRequest` | Room DAO returning `Flow` | — |

## Layout

| SwiftUI | Compose | Notes |
|---|---|---|
| `VStack` | `Column` | — |
| `HStack` | `Row` | — |
| `ZStack` | `Box` | — |
| `List` / `LazyVStack` | `LazyColumn` | `List` styling ≠ automatic on Android; rebuild dividers/insets. |
| `LazyHStack` | `LazyRow` | — |
| `LazyVGrid` / `LazyHGrid` | `LazyVerticalGrid` / `LazyHorizontalGrid` | — |
| `ScrollView` | `Modifier.verticalScroll()` / `horizontalScroll()` | Use `Lazy*` for large/dynamic content. |
| `Spacer()` | `Spacer(Modifier.weight(1f))` | `weight` only inside `Row`/`Column`; in fixed layouts use a sized `Spacer`. |
| `Section` | Header/footer items in `LazyColumn`; `stickyHeader` | — |
| `GeometryReader` | `BoxWithConstraints` / `onGloballyPositioned` | Use `Modifier.onSizeChanged` to track a view's size reactively. |
| `.ignoresSafeArea()` / `.safeAreaInset` | `enableEdgeToEdge()` + `WindowInsets` (`Modifier.safeDrawingPadding()`, `windowInsetsPadding(...)`, `Scaffold` `contentPadding`) | Edge-to-edge is enforced from targetSdk 35 — decide inset handling per screen. |
| `Form` | `Column`/`LazyColumn` with grouped items | No direct equivalent; rebuild grouping/styling. |
| `ViewThatFits` | `BoxWithConstraints` + branch | — |

## Components

| SwiftUI | Compose | Notes |
|---|---|---|
| `Text` | `Text` | — |
| `Label` | `Row { Icon(); Text() }` / `ListItem` | — |
| `Image` / `Image(systemName:)` | `Image(painterResource)` / `Icon(imageVector)` | SF Symbols → Material Icons or vector drawables. |
| `AsyncImage` | Coil `AsyncImage` (or project's image loader) | — |
| `Button` | `Button` / `TextButton` / `IconButton` | — |
| `Menu` | `IconButton` + `DropdownMenu` | — |
| `TextField` / `SecureField` | `TextField` / `OutlinedTextField` (state-based `TextFieldState` overloads) | Password: `SecureTextField` / `OutlinedSecureTextField`. |
| `Toggle` | `Switch` / `Checkbox` | — |
| `Slider` | `Slider` | — |
| `Stepper` | `Row` with `IconButton`s | No Material equivalent. |
| `DatePicker` | `DatePicker` / `DatePickerDialog` / `TimePicker` | — |
| `Picker` | `DropdownMenu` / `ExposedDropdownMenuBox` / `SingleChoiceSegmentedButtonRow` | Choose by iOS picker style. |
| `ProgressView` | `CircularProgressIndicator` / `LinearProgressIndicator` | — |
| `TabView` | `Scaffold` + `NavigationBar` (bottom nav) or `HorizontalPager` | Page-style TabView → Pager; tab bar → NavigationBar (or `NavigationSuiteScaffold` for adaptive). |
| `ShareLink` | `Intent.ACTION_SEND` via `Intent.createChooser` | — |
| `Map` (MapKit) | Project's map SDK (e.g. MapLibre `MapView` in `AndroidView`, or its Compose wrapper) | Annotations/overlays → layers/sources; camera API differs. |

## Navigation

| SwiftUI | Compose | Notes |
|---|---|---|
| `NavigationStack` / `NavigationView` | Navigation-Compose `NavHost` + `NavController` | Confirm the project's nav library first. |
| `NavigationLink` | `navController.navigate(route)` | Type-safe (`@Serializable`) routes recommended. |
| `NavigationSplitView` | `ListDetailPaneScaffold` / `NavigableListDetailPaneScaffold` (material3-adaptive) | — |
| `.toolbar` / `.navigationTitle` | `Scaffold(topBar = { TopAppBar(...) })` | Toolbar items → `actions` slot; bottom toolbar → `BottomAppBar`. |
| `.sheet` | `ModalBottomSheet` / `Dialog` | iOS sheet ≈ bottom sheet on Android; align with UX. `presentationDetents` → `SheetState` / `BottomSheetScaffold`. |
| `.alert` | `AlertDialog` | — |
| `.confirmationDialog` | `ModalBottomSheet` with actions / `AlertDialog` | — |
| `.contextMenu` | `Modifier.combinedClickable(onLongClick)` + `DropdownMenu` | — |
| `.fullScreenCover` | Full-screen destination or `Dialog(usePlatformDefaultWidth=false)` | — |
| `.searchable` | `SearchBar` / `DockedSearchBar` | — |
| System back / swipe-back | `BackHandler` / `PredictiveBackHandler` | Android has hardware/gesture back — handle explicitly. |

## Modifiers

> **Modifier order matters — and it is reversed between the two.** A SwiftUI
> modifier wraps everything *before* it; a Compose modifier chain applies from
> the *outside in*, left to right. So reverse the order when porting:
> `Text("x").padding(16).background(.red)` (red includes the padding) becomes
> `Text("x", Modifier.background(Red).padding(16.dp))`. Copying the order
> verbatim (`padding().background()`) colors only the content area.

| SwiftUI | Compose | Notes |
|---|---|---|
| `.padding()` | `Modifier.padding()` | — |
| `.frame()` | `Modifier.size/width/height/fillMaxWidth()` | — |
| `.background()` | `Modifier.background()` | — |
| `.foregroundColor` / `.foregroundStyle` | `color` param / `LocalContentColor` | — |
| `.font()` | `style = TextStyle(...)` / theme typography | — |
| `.cornerRadius` / `.clipShape` | `Modifier.clip(RoundedCornerShape(...))` | — |
| `.overlay` / `.background(view)` | `Box` layering | — |
| `.opacity` | `Modifier.alpha()` | — |
| `.onTapGesture` | `Modifier.clickable()` | — |
| `.swipeActions` | `SwipeToDismissBox` | — |
| `.refreshable` | `PullToRefreshBox` | — |
| `.onAppear` / `.onDisappear` | `LaunchedEffect(Unit)` / `DisposableEffect` | Lifecycle timing differs — verify. |
| `.task` / `.task(id:)` | `LaunchedEffect(Unit)` / `LaunchedEffect(id)` | Both cancel automatically, like `.task`. |
| `.onChange(of:)` | `LaunchedEffect(value)` / `snapshotFlow` | — |
| `withAnimation` / `.animation` | `animate*AsState` / `AnimatedVisibility` / `updateTransition` | — |
| `.sensoryFeedback` | `LocalHapticFeedback.current.performHapticFeedback(...)` | — |
| `.disabled` | `enabled = false` param | — |
| Custom `ViewModifier` | `Modifier` extension function (`Modifier.foo()`) or `Modifier.Node` | — |

## Accessibility

| SwiftUI | Compose | Notes |
|---|---|---|
| `.accessibilityLabel` | `contentDescription` / `Modifier.semantics { contentDescription = … }` | — |
| `.accessibilityHidden(true)` | `Modifier.clearAndSetSemantics {}` / `contentDescription = null` | — |
| `.accessibilityElement(children: .combine)` | `Modifier.semantics(mergeDescendants = true)` | — |
| `.accessibilityAddTraits(.isHeader)` | `Modifier.semantics { heading() }` | — |
| Dynamic Type | `sp` units + theme typography | Respects system font scale; check layouts at large scales. |

## Async, networking, persistence

| iOS | Android | Notes |
|---|---|---|
| `async`/`await`, `Task` | Kotlin coroutines, `viewModelScope`, `suspend` | — |
| `@MainActor` | `Dispatchers.Main` / `viewModelScope` (main by default) | — |
| `actor` | Class guarded by `Mutex` (kotlinx.coroutines) | — |
| `AsyncStream` / `AsyncSequence` | `Flow` / `callbackFlow` | — |
| Combine `Publisher` | `Flow` / `StateFlow` | — |
| `URLSession` | Ktor (KMP-capable) / Retrofit + OkHttp | Use the project's chosen client. |
| `Codable` | kotlinx.serialization (KMP-capable) / Moshi | — |
| Core Data / SwiftData | Room (KMP-capable) | — |
| `UserDefaults` | DataStore (KMP-capable) | — |
| Keychain | Android Keystore (+ Tink-encrypted DataStore) | EncryptedSharedPreferences (security-crypto) is deprecated — don't use for new code. |
| CoreLocation | `LocationManager` (AOSP) / Fused Location Provider (GMS) | Fused needs Google Play Services — confirm whether the project allows GMS. |
| Manual DI / Environment | Hilt / Koin | Confirm project's DI. |

## Resources

| iOS | Android |
|---|---|
| `Assets.xcassets` (images) | `res/drawable*` |
| Color assets | `colors.xml` + theme / Compose color scheme |
| `Localizable.strings` / `Localizable.xcstrings` (String Catalog) | `res/values*/strings.xml` |
| String Catalog plural variants / `.stringsdict` | `<plurals>` + `pluralStringResource()` |
| SF Symbols | Material Icons / vector drawables |
| `#Preview` | `@Preview` composable |
| App lifecycle (`App`/`Scene`) | `Application` + `Activity` |
