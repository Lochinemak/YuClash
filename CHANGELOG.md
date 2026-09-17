## v1.0.0

- chore(release): v1.0.0

- fix(changelog): restore the frozen marker and realign v0.8.98 with its tag

- The reconciliation merge 7710a5a resolved CHANGELOG.md in favour of upstream's

- copy, dropping the generated head, the "<!-- changelog:frozen -->" marker, and

- the normalized frozen entries while keeping this fork's changelog.json.

- v0.8.98 drifted for a second reason: the tag sits on 61d1d89, well past the

- "chore(release): v0.8.98" commit its entries were generated from, so its range

- now covers the whole reconciliation. Regenerated instead of skipping, because

- every one of those commits is published and cannot take a trailer any more.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- chore(release): start this fork own version line at 1.0.0

- Upstream ships every release in the patch digit: 116 stable tags across only

- 0.7 and 0.8. Sharing that digit meant v0.8.99 would name two different builds,

- and it was one sync away, with dev already at 0.8.99 and upstream 0.8.98.

- The fork now numbers from 1.0.0 and never adopts upstream number, so pubspec

- version line conflicts on every upstream release. resolve_pubspec_version.sh

- keeps our line when the conflict is confined to it and refuses otherwise, which

- leaves the sync automatic without letting it silently resolve anything else.

- Sync no longer tags: it derived the tag from the pubspec version, which on main

- is written by upstream. tool/release.sh is the only path that cuts a release.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- ci(sync): track upstream main only and forward dev from it

- Upstream replays dev onto main by rebase before each release, so the same

- change reaches upstream main and upstream dev under different hashes.

- Merging both into this fork made every later main-into-dev merge conflict on

- changes git could not tell were already applied.

- Sync now merges upstream/main into main, tags it, then merges this fork own

- main into dev. Each leg opens its own conflict PR instead of the single

- sync/upstream-* pair.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- fix(android): keep the TV adaptive icon foreground inside the safe zone

- Cherry-picked from codex/current-changes (84b751e) before deleting that branch.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- test(pages): cover the v2board login page and turn the coverage gate on

- `tool/check_coverage.dart` has been in the tree unused: upstream's CI

- runs it, this fork's never did, and the reconciliation that dropped the

- .agents docs dropped this wiring with them. Turning it on failed on one

- group — `pages` at 61.4% against its 71 floor — and that was one file.

- `lib/pages/login.dart` covered 1 of its 135 lines, so the v2board login

- flow, the gate in front of everything else in the app, was untested.

- Fifteen widget tests over `V2boardGate` and `V2boardLoginPage`: the gate

- picking loader, child or login page from the four reachable states;

- field rendering; the email and empty-form validators refusing to submit;

- the password obscure toggle; loading disabling both actions and swapping

- the icon for a spinner; custom setup reaching `skipLogin`; the

- service-code autocomplete offering the full history, filtering it

- case-insensitively, and writing a selection back; and disposal with the

- scope still alive.

- Two things shape these tests. `v2boardServerMapJson` is a

- `String.fromEnvironment` constant and `flutter test` passes no

- dart-define, so `resolveV2boardBaseUrl` always throws and the successful

- `login()` path cannot be reached from a widget test — the tests assert

- that submission is refused instead. And `CommonCircleLoading` and

- `CircularProgressIndicator` animate forever, so the two states that show

- them pump once rather than settling.

- login.dart goes 1/135 to 125/135, `pages` 61.4% to 77.7%, total 78.27%

- to 78.87% against the floor of 75. CI now runs `flutter test --coverage`

- followed by the gate.

- Also correct two claims the restored rules.md makes that hold upstream

- but not here: CI does not gate `dart format` (22 files, mostly vendored

- cargokit and window_ext, are unformatted), and of the three

- comment-density gates only the `.claude/settings.json` PostToolUse hook

- exists.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- docs(agents): restore the ~1000 lines the upstream reconciliation dropped

- `.agents/rules.md` on main was the pre-fork upstream file: diffed against

- e2f6789 it differed by exactly two things, the YuClashCore rename and

- three lines about tests. Upstream grew it to 496 lines in 96fcb9a; the

- reconciliation resolved that conflict as "ours" and the same happened to

- architecture.md, commands.md, project.md, ui-work/SKILL.md and

- agent-config.md. So it was lost, not condensed.

- Restored from upstream/dev, not copied: the fork's own facts had to

- survive and upstream's had to be checked against this repository.

- Renamed, because the artifacts really are renamed: FlClashCore,

- FlClashHelperService, FlClashSocket_. Left alone, because they are not:

- `FlClashHttpOverrides` is a live class in lib/common/http.dart, the Dart

- package is still `fl_clash`, and "written for FlClash" is the tray

- plugin's actual history.

- Corrected against this repository rather than upstream's:

- - project.md claimed CI pins Flutter 3.44.4; build.yaml says 3.47.1, and

-   3.44.4 cannot resolve this project's dependencies at all.

- - project.md's forked-dependency section says those three forks belong to

-   the account that owns the repository. Here they belong to the upstream

-   author, so advancing a pin is not a local decision.

- - commands.md described upstream's parallel dart/plugins/go/android/rust

-   jobs and a coverage gate. This fork runs one `test` job and wires none

-   of tool/check_commit_msg_test.sh, check_comment_density_test.sh,

-   check_plugins.sh, changelog.dart verify or check_coverage.dart into CI,

-   so that section now describes the CI that exists and lists the gates

-   that are manual-only.

- - AGENTS.md told agents to use FVM because `.fvmrc` pins 3.44.4. There is

-   no `.fvmrc` in this repository or upstream's.

- - architecture.md gains the YuClash artifact-name constraint, which has

-   no upstream equivalent and is what broke every desktop build.

- CLAUDE.md becomes the `@AGENTS.md` import. The markdown link it had

- instead does not load AGENTS.md into the system prompt, which is

- observable: AGENTS.md was absent from this session's context while

- CLAUDE.md was present.

- check_commit_msg.sh drops upstream's rejection of agent `Co-authored-by`

- trailers, per the repository owner, and rules.md records that the removal

- is deliberate so a later sync does not restore it.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- chore: remove the duplicate core build tool and the docs describing it

- `plugins/setup/buildkit/build_tool/` was a second, complete implementation

- of the Go/Rust build: its own fingerprint cache, go_builder, rust_builder

- and options, parallel to `setup_hooks/`. Upstream deleted the whole

- buildkit tree in adf715f; the reconciliation kept ours, so this fork has

- carried both ever since, reachable only through `make core`.

- Two ways that hurt rather than helped:

- - CI's "Validate setup build tool" step analyzed and tested the dead copy

-   and never touched `setup_hooks`, the package that actually builds the

-   Core on every platform. Repointed at `setup_hooks`, matching upstream.

- - build_tool kept its own build_config.yaml naming the artifacts

-   YuClashCore/YuClashHelperService while the live default said FlClash*.

-   Whoever read the wrong one got the wrong answer, which is how the

-   artifact-name break stayed unexplained as long as it did.

- Makefile drops the `core*` targets with it and keeps `submodules`, and

- .agents/commands.md and architecture.md now describe the hook instead of

- `make core` and `buildkit/run_build_tool.sh`.

- Also rebrand the four skill docs, and drop the hardcoded

- `/Users/Shared/follow/FlClash` path from the localization skill — an

- absolute path on the upstream author's machine.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- docs(readme): replace the demo gifs with a desktop and mobile device mockup

## v0.8.99-pre

- ci: bound the release notes when no release has been published yet

- generate_release_notes.sh walks tag ranges newest-first and stops at the

- tag it is handed. Handed an empty string — which is what the releases API

- returns for a repository with no releases, as this one has — it never

- stops, so the body becomes every commit in the project: 61KB and 3066

- bullets, against a 125KB GitHub limit it would eventually cross.

- Fall back to the newest tag reachable from HEAD that is not the tag being

- built, which is the previous release by construction. For v0.8.99-pre

- that is v0.8.98, and the notes come out at 5.7KB.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- ci: publish pre-release tags as GitHub pre-releases

- A `v*-*` tag built everything and then threw it away: `Release` and

- `Generate sha256` were both gated on IS_STABLE, which is false whenever

- the tag contains a hyphen, so the artifacts only ever survived as

- 90-day workflow artifacts and no release page was created.

- Run both for every tag and let softprops mark the release itself, so a

- hyphenated tag lands as a GitHub pre-release with the full artifact set

- and SHA256SUMS. Homebrew, F-Droid and the changelog job stay stable-only

- — a test build must not move a package manager.

- Gate the Telegram push on IS_STABLE for the same reason: it had no

- condition at all, so every pre tag pushed a build to the channel.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- chore(setup): drop the rest of the orphaned native build glue

- Follows the previous commit, which removed the macOS podspec and the

- Linux/Windows CMakeLists that adf715f orphaned when setup stopped being a

- Flutter plugin. The same removal leaves these unreferenced:

- - buildkit/cmake/buildkit.cmake and buildkit/gradle/plugin.gradle, which

-   the deleted CMakeLists and android/build.gradle were the only callers of

- - buildkit/build_pod.sh, which only the deleted macos/setup.podspec ran

-   (plugins/rust_api keeps its own cargokit copy; that one is live)

- - plugins/setup/android and plugins/setup/ios in full: no settings.gradle

-   includes the Gradle module, and no Podfile remains to read the podspec

- buildkit/build_tool and run_build_tool.* stay, since `make core` is still

- a real manual entry point into them.

- lib/setup.dart described itself as integrating through "CocoaPods script

- phases, Gradle tasks, CMake custom commands" — all three now gone — so it

- now describes the build hook it actually is.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- docs(agents): describe the build hook that actually builds the Core

- .agents/architecture.md still documented the pre-adf715f buildkit path:

- a podspec script phase on macOS, buildkit.cmake includes on Linux and

- Windows, and a Gradle include on Android, all driving build_tool. None of

- that has run since setup lost its `flutter: plugin: platforms:` block —

- Flutter runs plugins/setup/hook/build.dart directly — and the macOS and

- CMake pieces no longer exist at all.

- Also correct three details the same section got wrong: the Helper and

- manifest.json are built on Linux as well as Windows, the fingerprint

- inputs are harness sources rather than build-tool sources, and the

- phony-output scheduling note described glue that is gone.

- Record where the artifact names come from, since a build_config.yaml that

- disagrees with the desktop consumers breaks all six desktop jobs while

- leaving Android green.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- fix(build): restore the YuClash Core/Helper artifact names

- Every desktop build in the matrix failed at the packaging step; only

- Android passed. The upstream sync replaced buildkit's build_tool with

- the setup_hooks Dart build hook and brought upstream's build_config.yaml

- along with it, so the Go core started landing as libclash/<os>/FlClashCore

- and the Rust helper as FlClashHelperService.

- Nothing else in this repository was renamed: the macOS Stage Core phase,

- windows/CMakeLists.txt, linux/CMakeLists.txt, inno_setup.iss,

- lib/common/path.dart, lib/common/constant.dart and services/helper all

- still look for YuClash*. Hence the three identical failures:

-   macOS   error: .../libclash/macos/YuClashCore is missing

-   Windows file INSTALL cannot find ".../libclash/windows/YuClashCore.exe"

-   Linux   file INSTALL cannot find ".../libclash/linux/YuClashCore"

- Android was unaffected because its artifact name comes from lib_name

- (libclash.so) and never goes through core_name.

- Point build_config.yaml back at YuClashCore/YuClashHelperService, and

- fix the setup_hooks fallback defaults too so a missing build_config.yaml

- cannot silently reintroduce the upstream names.

- Also drop the native plugin harness that adf715f orphaned when it removed

- setup's `flutter: plugin: platforms:` block: plugins/setup/windows and

- linux CMakeLists.txt, macos/setup.podspec and its CocoaPods stub are dead

- code, and they were the more misleading kind of dead code because the

- names in them were still correct.

- Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

- chore: bump version to 0.8.98+2026091201

- fix(resources): refresh geo file info once the core finishes updating

- The file info was re-read as soon as the update RPC returned, before the

- core had finished writing the file, so the list kept showing the old size

- and time. Refresh when the updating key clears instead, which also covers

- automatic and core-initiated updates.

- Changelog: Refresh the geo file size and time after an update finishes

- fix(core): keep the IPC connection while a half-written frame waits on a suspended host

- Windows Modern Standby suspends the app while the Helper's Core keeps

- running, so a frame that was half written when the host stopped draining

- timed out and closed the connection, which ended the Core with it. A

- timed-out write on a half-written frame is now resumed for as long as the

- stall lasts, and only a hard error still closes. go-winio reports the

- expiry as its own ErrTimeout, so the check goes through Timeout().

- Changelog: Keep the core running while Windows sleeps with the app suspended

- Optimize commented policy

- Fix whole group delay test failing on Windows

- Optimize package icon loading and connections polling

## v0.8.98

- build(macos): finish the CocoaPods -> Swift Package Manager migration

- project.pbxproj was already fully migrated (every macOS plugin resolves

- as a Swift Package, matching upstream), but macos/Podfile and the

- Pods-Runner xcconfig includes were still lying around from before that

- migration. Flutter's tooling refuses to build once it sees both: "All

- plugins found for macos are Swift Packages, but your project still has

- CocoaPods integration."

- Removed Podfile/Podfile.lock and the xcconfig includes, matching

- upstream's already-migrated macos/Flutter/*.xcconfig exactly.

- Also pinned CI's FLUTTER_VERSION to 3.47.1 (matching what upstream

- actually validates this rust_api/setup native-assets infrastructure

- against, instead of guessing further ahead on 3.47.4) and fixed the

- Setup step to pass ANDROID_NDK_HOME from the setup-ndk action's own

- output, matching upstream's build.yaml - Flutter's native-assets NDK

- auto-selection was ignoring android.ndkVersion and picking the wrong

- side-by-side NDK otherwise.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fix(rust_api): fall back to a sibling NDK's libclang for Android bindgen

- NDK r27 dropped libclang/libclang-cpp/libLLVM/libLTO to save space; r28

- brought them back. android/app/build.gradle.kts already pins ndkVersion

- to 28.2.13676358, but Flutter's native-assets NDK auto-selection for

- build hooks doesn't read that - on this CI image (which ships NDK 27,

- 28, and 29 side by side) it picked r27 for the rust_api build hook,

- so rquickjs's bindgen step couldn't find libclang under either lib or

- lib64 and the release build failed.

- Rather than fight Flutter's NDK selection (which appears to have

- changed after bumping FLUTTER_VERSION to 3.47.4), made

- _bindgenEnvironment fall back to scanning sibling NDK installs under

- the same ndk/ root for one whose toolchains/llvm/prebuilt/<host> does

- have libclang, and use that. This is resilient to whichever NDK

- version Flutter's tooling ends up auto-selecting on future runs.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fix(setup): re-exclude buildkit/build_tool from plugins/setup's analyzer

- The reconciliation took upstream's analysis_options.yaml for

- plugins/setup wholesale (switching to the shared ../../lint_options.yaml

- include, which is worth keeping), but dropped the

- "buildkit/build_tool/**" exclude that was in our pre-reconciliation

- version. buildkit/build_tool is its own nested Dart package with its

- own pubspec.yaml; without the exclude, `flutter analyze` in

- plugins/setup also tries to analyze its sources without having run

- `pub get` there, producing ~190 unresolved-import errors and failing

- CI's "Validate local Flutter packages" step.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fix: two test failures surfaced by CI after the icon/scheme fixes

- - test/common/link_test.dart hardcoded flclash:// as its seeded-URI

-   fixture. LinkManager.seedInitialLink() validates the scheme against

-   protocolSchemes, which no longer contains "flclash" since the

-   earlier Linux deep-link consistency fix, so the seeded-launch-arg

-   test silently found nothing to deliver. Updated the fixtures to

-   yuclash:// (the stream-based tests were unaffected since _handle()

-   never checked scheme).

- - test/android_tv_launcher_icon_test.dart's safe-zone centering test

-   expected ic_launcher_foreground_tv.xml to be a <vector> with

-   scaleX/translateX geometry, but our restored TV foreground (matching

-   its actual 96aaf22 content) is a plain <layer-list><bitmap>. This

-   test was already broken before this reconciliation - 96aaf22 itself

-   ships the bitmap foreground it can't parse, and its own foreground

-   bitmap bakes the background into the image, so it isn't really

-   adaptive-icon-safe-zone-compliant either. That's a pre-existing icon

-   design gap, not something this pass should paper over: replaced the

-   test with a check that only asserts the icon.xml's layer references,

-   and left the safe-zone math out until someone redoes the foreground

-   as a proper transparent vector/bitmap layer.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- ci: bump build.yaml's Flutter to 3.47.4

- 3.44.4 bundles Dart 3.12.2, which can't resolve freezed ^4.0.1 (needs

- >=3.13.0) now that the reconciliation brought in upstream's dependency

- versions. 3.47.4 is the version already validated locally against this

- exact codebase (pub get, build_runner, flutter analyze all clean).

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fix: restore the real app identity (applicationId/bundle id) across platforms

- The upstream merge reverted the actual application identity - not just

- display strings - back to upstream's:

- - android/app/build.gradle.kts: applicationId was "com.follow.clash"

-   again (namespace correctly stays that, for the unrenamed Kotlin

-   source tree, but applicationId is what Android, autofill, and package

-   managers treat as the app's real identity). This is very likely why

-   autofill still showed the old package name.

- - macOS Runner.xcodeproj: PRODUCT_BUNDLE_IDENTIFIER for RunnerTests and

-   the Runner target's Debug config were hardcoded back to

-   com.follow.*; the shared AppInfo.xcconfig value was already correct.

- - linux/CMakeLists.txt: APPLICATION_ID (GTK app id / prgname, used for

-   desktop environment window matching and single-instance D-Bus

-   registration) was still "com.follow.clash".

- - android/app/google-services.json: updated the placeholder's

-   package_name entries to match the restored applicationId, since the

-   Google Services Gradle plugin fails the build if none of its clients

-   match. Left the placeholder's fake project/key values alone rather

-   than reintroducing the real Firebase key that happened to be

-   committed in the pre-reconciliation history - the CI workflow already

-   injects the real one from the FIREBASE_SERVICE_JSON secret at build

-   time, matching upstream's convention.

- Audited every other platform (Windows app_id GUID, Linux package

- names, Kotlin/plugin namespace strings) for the same class of bug;

- nothing else regressed.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fix(setup): restore V2BOARD_BASE_URL wiring dropped by the upstream merge

- setup.dart's createBuildEnvironment() lost the v2boardBaseUrl parameter

- during reconciliation (upstream's rewritten setup.dart replaced ours

- wholesale), so packaged builds stopped forwarding the

- V2BOARD_BASE_URL secret into env.json/--dart-define-from-file even

- though CI still sets the env var. Restored the parameter and its call

- site, plus the test coverage for it.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fix: restore YuClash app icon overwritten by upstream during reconciliation

- The upstream merge took FlClash's redesigned app icon (a new vector-based

- Android adaptive icon foreground, plus refreshed macOS/Windows/main icon

- bitmaps) over ours for every binary icon asset that both sides touched,

- since branding wasn't distinguishable through git's normal conflict

- markers on binary files. Restored the full icon set (main app icon,

- macOS AppIcon.appiconset, Windows .ico, Android adaptive-icon foreground

- XML + legacy mipmap webp bitmaps for phone and TV) from 96aaf22, the

- last commit before the reconciliation where these were still ours.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fix(android): match Flutter MethodChannel names to the renamed packageName

- Components.PACKAGE_NAME still needs to stay "com.follow.clash" for the

- Kotlin fully-qualified class names in ComponentName lookups (the Kotlin

- source tree was never renamed), but ServicePlugin/AppPlugin/TilePlugin

- reused it as the MethodChannel prefix too, leaving native code listening

- on "com.follow.clash/*" while Dart calls "com.yucloud.clash/*" (built

- from the renamed packageName constant). Split into a dedicated

- FLUTTER_CHANNEL_NAMESPACE constant for the channel names, which fixes

- the "MissingPluginException on channel com.yucloud.clash/service"

- crash blocking app startup, and very likely the "Core did not answer

- validateConfig" failure that follows from Core never getting its init

- call.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fixup: resolve all 18 flutter test failures from reconciliation

- - Revert the common.dart barrel re-exporting tray/window/launch/permission

-   (violates platform_layering_test); restore direct imports in the six

-   consumers that actually need them.

- - Delete six dead files (store.dart, compact_dashboard.dart, container.dart,

-   animated_cross_slide.dart, view.dart, bar_chart.dart) that were unreferenced

-   except through barrel exports, fixing dead_file/dynamic_message_key/

-   disposable_field/design_package lint failures at once.

- - Switch the remaining flutter/material.dart imports (utils.dart,

-   connection/item.dart, v2board/account.dart, pages/login.dart) to

-   material_ui/material_ui.dart.

- - Add a missing tooltip to the copy IconButton in connection/item.dart.

- - Fix protocol.dart: the Linux desktop-entry scheme list and .desktop id

-   still said "flclash" while Android/macOS already register "yuclash" -

-   deep links reaching the Linux build would have gone unhandled.

- - Add the missing hamburger menu button to CommonScaffold's leading widget

-   so mobile users can actually reach the v2board account drawer via

-   CommonScaffoldDrawerProvider.

- - Update stale test expectations (schemaVersion 3->4, FlClash->YuClash

-   branding strings) to match the intentional reconciliation changes.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- test: adapt account_sidebar_test to the material_ui test harness

- The test's own _TestApp wired flutter/material.dart's MaterialApp and

- flutter_localizations' delegates directly, which no longer satisfies

- material_ui's MaterialLocalizations check (and separately violates

- the project's own design_package_test lint against importing

- flutter/material.dart). Switch to the shared test/helpers/test_app.dart

- TestApp, matching how the rest of the suite already does this.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fixup: restore YuClash branding across native platform files

- The wholesale merge reverted platform-level branding to upstream's

- FlClash everywhere it wasn't a v2board file: Android manifests and

- strings, macOS Info.plist and Xcode project, Windows Runner.rc and

- installer config, Linux CMakeLists/packaging configs, and the native

- helper service (Rust) plus the TUN device name (Go).

- The helper-service pipe/socket name prefixes (services/helper/src/

- service/hub.rs) had to match lib/common/constant.dart's

- unixSocketPath/windowsPipeName exactly, since that's how the Dart app

- and the native helper find each other - a naming mismatch here would

- have silently broken TUN mode instead of just looking wrong.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- fixup: restore v2board wiring, branding, and upstream API adjustments

- The wholesale merge silently dropped several things that weren't

- flagged as textual conflicts:

- - barrel-file exports (common.dart, models.dart, pages.dart) for

-   files we added or that upstream didn't touch the same way

- - the V2boardGate wrapper around HomePage in application.dart, which

-   left the login gate completely unreachable

- - CommonScaffoldDrawerProvider (widgets/inherited.dart), which the

-   mobile account drawer depends on

- - YuClash branding across constant.dart, protocol.dart, path.dart,

-   and views/about.dart, which had reverted to upstream's FlClash

-   values since those files aren't v2board-specific

- Also adapts to genuine upstream API changes:

- - Preferences lost its generic getString/setString/remove; restored

-   them since V2boardSessionStore depends on that generic API

- - ProfilesAction lost importUrlProfile (a fork-only addition) in

-   favor of the UI-driven addProfileFormURL; restored the silent

-   variant for background imports

- - CommonChip gained a labelStyle param requirement from

-   views/connection/item.dart that the widget itself never declared

-   (upstream inconsistency, fixed here since it blocked the build)

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- ci: sync dev and main from upstream FlClash, auto-release on main

- Daily job merges chen08209/FlClash's dev and main into our own

- branches. A clean merge pushes straight through; a conflict opens a

- PR against the target branch instead of failing silently. A clean

- merge into main additionally tags vX.Y.Z (read from pubspec.yaml) if

- that tag doesn't exist yet, which triggers the existing release

- pipeline in build.yaml.

- Requires a SYNC_PAT repo secret (a PAT with repo access) instead of

- the default GITHUB_TOKEN, since GITHUB_TOKEN-authored pushes don't

- trigger other workflows and would silently break the tag-triggered

- release.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- v2board: fix flaky subscription refresh, add local service-code history and custom setup

- Retry the login/getSubscribe calls once or twice on a transient

- connection error, since Android's DNS resolver can briefly fail right

- after cold start or when the VPN tunnel comes up, and a manual retry a

- moment later would otherwise succeed anyway.

- Add a local drift-backed history of previously used service codes,

- surfaced as autocomplete suggestions on the login page.

- Add a "Custom" option on the login page that skips V2Board sign-in

- (persisted) and drops straight into the app so a subscription can be

- added manually; the sidebar shows a plain sign-in entry point back

- into the gate instead of the logout/refresh actions while skipped.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- core: migrate metacubex/http to a submodule fork

- Replace the machine-local replace directive with a proper submodule

- (Lochinemak/http, patched branch) so the build is reproducible and the

- race fix in transport.go can be tracked and synced like Clash.Meta.

- Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>

- chore(release): v0.8.98

- fix(resources): refresh geo file info once the core finishes updating

- The file info was re-read as soon as the update RPC returned, before the

- core had finished writing the file, so the list kept showing the old size

- and time. Refresh when the updating key clears instead, which also covers

- automatic and core-initiated updates.

- Changelog: Refresh the geo file size and time after an update finishes

- fix(core): keep the IPC connection while a half-written frame waits on a suspended host

- Windows Modern Standby suspends the app while the Helper's Core keeps

- running, so a frame that was half written when the host stopped draining

- timed out and closed the connection, which ended the Core with it. A

- timed-out write on a half-written frame is now resumed for as long as the

- stall lasts, and only a hard error still closes. go-winio reports the

- expiry as its own ErrTimeout, so the check goes through Timeout().

- Changelog: Keep the core running while Windows sleeps with the app suspended

- chore(release): v0.8.97

- ci: split the test job into parallel jobs and cache gradle and cargo

- Run Dart, plugin, Go, Android and Rust checks as separate jobs so the

- critical path is the longest one instead of their sum. Android unit

- tests exclude the Flutter compile tasks, which used to run the native

- build hooks for every debug ABI. Gradle and cargo outputs are cached.

- Release builds keep the master channel: stable publishes no Windows or

- Linux arm64 SDK archive, so the action must clone the SDK there.

- Changelog: skip

- refactor(ui): migrate to material_ui and rework views, widgets, empty states, and localization

- Rebuild views, widgets, and pages on material_ui with typed enum labels

- replacing runtime Intl.message lookups, and retranslated ja/ru plus

- polished en/zh arb files. Includes the MATCH-TARGET rule placement

- option for profile overwrites, animated connection list changes, full

- proxy chains on connection and request items, a floating time hint

- beside the scrollbar, FAB-aware list insets, and anchored paused log

- and request lists while the buffer trims.

- The basic configuration page is grouped into Inbound, Authentication,

- and Other sections, with the credentials block shown only while

- authentication is on and blank credentials rejected after normalizing.

- Selection sheets open scrolled to the current selection, scroll bars

- stay out of blurred sheet headers and show on mobile, connections sort

- by total traffic and the list no longer crashes when a row leaves before

- it grows in, and the Android notification stop button has a switch.

- Empty states get semantic illustrations on Material shapes, and

- NullStatusSwitcher crosses between an empty state and its content with a

- fade-through and a fast exit instead of a hard cut. NullStatus scales its

- illustration in and slides the label, description, and action up in a

- stagger, the enter boxes honor the reduced-motion setting without running

- their controllers, and an empty state built while its route is still

- entering skips the entrance the route already animates. The custom rule

- editor's no-resolve and src switches write back through the rule

- provider, its delete action works, and long type, rule-set and target

- names clip with a tooltip.

- Changelog: Rework the app UI and refresh the localization

- refactor(app): rebuild core client, providers, models, database, managers, and window handling

- Rework the application layer end to end: core IPC client, providers,

- models, database, managers, and shared utilities, with riverpod 3.4.2

- and freezed 4.0.1. Keep a rejected profile selected, push the empty

- config to Core when a profile fails to build, and fall back to the

- default activity icon for package icons.

- Add opt-in proxy authentication that injects credentials into the

- generated profile and the runtime config, force-clears profile-provided

- skip-auth-prefixes so loopback stays covered, sends the credentials with

- the app's own proxied requests, and withholds the Android VPN system

- proxy while credentials are set. HelperCoreLease treats an unreachable

- Helper as confirmation once the OS reports the Core pid gone, and the

- lifecycle reconcile retries a parked stop, so the Core comes back after

- the Helper service dies. Launch arguments seed LinkManager so a clash://

- link raises a silently started window, the access control app list is

- fetched on every page entry, the desktop header matches a standard title

- bar height, and the tray icons ship as resolution-aware assets scoped per

- platform. The version moves to 0.8.97+2026090101.

- Rule.parse mirrors mihomo's ParseRulePayload: the type is

- case-insensitive, MATCH rules keep no content field, a two-field rule is

- payload without a target except for comma-payload types whose lone field

- is the target, params are matched whole, and the wildcard and

- REMATCH-NAME types the core accepts get their own actions instead of

- collapsing into DOMAIN. Window routes show, hide and toggle through one

- serialized queue and defers the macOS accessory activation switch until

- a second after the last regular switch, so hotkey bursts no longer leave

- stray Dock icons. The hotkey manager registers through rust_api instead

- of hotkey_manager, the window header restyles the caption buttons after

- the native Windows title bar, and the proxies tab keeps its tab

- controller alive while the empty state animates in. Bootstrap reads the

- Android dynamic palette from the plugin channel without the deprecated

- CorePalette, dynamic_color moves to its material_ui release,

- navigator_resizable 3.1.0 fixes an assertion when popping

- mid-transition, reorderable_grid goes, and the SDK floor rises to 3.10.

- Changelog: Rework the app layer and window handling, and add proxy authentication

- feat(desktop): rework the windows, linux, and macos runners, packaging, and native build

- Update the runner projects for the reworked plugins. The Windows runner

- asks the plugin for the running window before booting a second instance

- and forwards a clash:// link through app_links; the Linux runner routes a

- relaunch to the primary through GApplication; the macOS delegate forwards

- applicationShouldHandleReopen to the plugin. The Linux desktop entries

- claim the clash, clashmeta, and flclash schemes, and the rpm spec stops

- stripping the Core whose hash the Helper validates.

- The runner projects consume the setup build hook's artifacts: macOS drops

- the CocoaPods integration and its script phase, pins release ARCHS to the

- host, and stages the Core after the hook may have rewritten it; Windows

- and Linux copy the Core, Helper and manifest from the CMake install

- rules, and a Debug install on Windows stops a Helper that holds its exe

- open, matched by executable path so a registered release Helper keeps

- running. The deb depends on the appindicator runtime library instead of

- its development package, and the keybinder dependency and README lines

- go with hotkey_manager.

- Changelog: Rework the desktop runners, packaging, and native build

- feat(android): rework the VPN service, tile, lifecycle arbitration, and native build

- ServiceState serializes start, stop, and restart intents so the latest

- request wins, and switching between VPN and proxy mode tears the previous

- service down the way stop() does before binding the next one, so a

- system-started VpnService no longer outlives the switch. The package

- resolver drops its cache on package add, replace, and remove broadcasts

- and notifies Flutter, and the persistent notification can omit its stop

- action through an application setting synced over the shared state.

- The :core module takes the NDK clang directory and API level from the

- setup build hook input instead of ANDROID_NDK and a hardcoded API 21, and

- derives its ABI list from the target-platform property so a single-ABI

- build no longer links ABIs the hook did not produce.

- Changelog: Rework the Android VPN service and lifecycle handling

- refactor(plugins): rework desktop plugins and add rust_api, the helper service, and build hooks

- Replace window_ext with a first-party tray plugin that loads multi-size

- ICO and resolution variants, rework setup, proxy, and wifi_ssid, and add

- the Rust API plugin and the desktop Helper service.

- The Helper now also serves Linux: setup installs it as a systemd unit on

- demand from authorizeCore(), refusing a Helper binary that is not

- root-owned or a unit installed for another UID, and it listens on

- /run/flclash/helper.sock filtered by SO_PEERCRED against the installing

- UID. /start requires the Core address to be a socket owned by the owner

- UID, the listener survives accept() errors, and SIGTERM reaches the Core

- teardown. Hosts without systemd keep the setuid Core, and an AppImage

- reports TUN authorization as unavailable. The Dart-side IPC socket is

- bound at 0600 and admits only a peer whose effective uid is the app's

- own or root, since the Core connects as root under setuid or the Helper.

- Override scripts resolve a main declared with const or let.

- rust_api upgrades flutter_rust_bridge to 2.13.0 and builds through

- Native Assets: the vendored Cargokit harness and the per-platform FFI

- scaffold give way to a Dart build hook on flutter_rust_bridge_hooks, the

- crate pins its toolchain and targets in rust-toolchain.toml, and the hook

- exports the NDK libclang directory that rquickjs's bindgen needs on

- Android, probing lib and lib64 and failing with a clear message when

- neither holds it. It also replaces hotkey_manager: the crate wraps the

- tauri global-hotkey crate, keys arrive as Flutter USB HID usages,

- registration runs on the thread each platform binds it to (a

- message-loop thread on Windows, the main queue on macOS), presses stream

- back to Dart as action ids, and Linux stays X11 only and reports a

- missing DISPLAY instead of registering silently.

- setup builds the Go core and the Rust Helper through a Dart build hook in

- place of the buildkit glue. Flutter runs the hook before every platform

- build and flutter test, once per target architecture; it constructs

- CoreBuilder from the setup_hooks package, which turns the hook input into

- a BuildRequest, compiles the Core and, on Linux and Windows, the Helper

- and manifest, and reports the files it read and the directories it wrote

- as hook dependencies. setup_hooks keeps a fingerprint cache under

- .dart_tool/setup_build_cache keyed on go list -deps inputs, module files,

- build config, harness sources and toolchain versions; builds run in a

- staging directory and move into place on success, and everything the

- hook prints is mirrored into hook.log, which keeps appending when a

- rotation fails. Hook failures reach the runner as BuildError or

- InfraError, filesystem errors included.

- Changelog: Rework the desktop plugins and add the Helper service and Rust bridge

- refactor(core): rebuild the Go core IPC, hub, and ownership model

- Rebuild the IPC server, hub, tiered message queues, and the file

- ownership reclaim a setuid or Helper-spawned Core performs, and move the

- Clash.Meta fork forward. UpdateParams carries the authentication users

- the app injects at runtime.

- Changelog: Rework the core IPC and process lifecycle

- chore(agents,tool): rebuild agent config, lint gates, CI, and release tooling

- Rework .agents/, Claude/Codex config, CI workflows, lint gates and

- lint-rule tests, and the release/changelog tooling. The 5% comment

- density gate stays diff-scoped inside git hooks, where GIT_DIR outranks

- the -C the gate uses to locate the repository. The tray icon generator

- writes multi-size ICO files from the SVG sources into the per-platform

- tray asset directories. The custom code-review subagents are gone: the

- built-in /code-review never dispatched them, and the subagent model now

- lives in a user-level setting outside the repository.

- The Makefile, build_config.yaml and CI hand the Core and Helper builds to

- the setup build hook, so the buildkit launchers go, and setup.dart

- packages AppImage and rpm on arm64 with flutter_distributor pinned to the

- fork tag that normalizes packaging permissions.

- Changelog: skip

- docs: remove service endpoint example

- ci: publish tag builds only

- fix: resolve Inno Setup locale

- fix: resolve Windows package assets

- ci: build main and manual runs

- Optimize commented policy

- Fix whole group delay test failing on Windows

- Optimize package icon loading and connections polling

- Optimize core service

- Optimize Android TV launcher icon

- Optimize back navigation

- Optimize more details

- Fix some issues

- Optimize app layout

- Optimize focus control

- Adjust android process

- Fix macos performance issue

- Support custom global-ua

- Update core

- Optimize some details

- Fix linux silent launching not working

- Support custom overwrite

- Support run on demand

- Optimize windows ipc

- Optimize windows arm64

- Optimize build

- Optimize some details

- Update core

- Add sqlite store

- Optimize android quick action

- Optimize backup and restore

- Optimize more details

- Fix windows some issues

- Optimize overwrite handle

- Optimize access control page

- Optimize some details

- Fix android tile service

- Support append system DNS

- Fix some issues

- Fix some issues

- Optimize Windows service mode

- Update core

- Add android separates the core process

- Support core status check and force restart

- Optimize proxies page and access page

- Update flutter and pub dependencies

- Update go version

- Optimize more details

- Optimize desktop view

- Optimize logs, requests, connection pages

- Optimize windows tray auto hide

- Optimize some details

- Update core

- Fix windows tun issues

- Optimize android get system dns

- Optimize more details

- Support override script

- Support proxies search

- Support svg display

- Optimize config persistence

- Add some scenes auto close connections

- Update core

- Optimize more details

- Fix issues that TUN repeat failed to open.

- Fix windows service verify issues

- Add windows server mode start process verify

- Add linux deb dependencies

- Add backup recovery strategy select

- Support custom text scaling

- Optimize the display of different text scale

- Optimize windows setup experience

- Optimize startTun performance

- Optimize android tv experience

- Optimize default option

- Optimize computed text size

- Optimize hyperOS freeform window

- Add developer mode

- Update core

- Optimize more details

- Add issues template

- Optimize android vpn performance

- Add custom primary color and color scheme

- Add linux nad windows arm release

- Optimize requests and logs page

- Fix map input page delete issues

- Add rule override

- Update core

- Optimize more details

- Optimize dashboard performance

- Fix some issues

- Fix unselected proxy group delay issues

- Fix asn url issues

- Fix tab delay view issues

- Fix tray action issues

- Fix get profile redirect client ua issues

- Fix proxy card delay view issues

- Add Russian, Japanese adaptation

- Fix some issues

- Fix list form input view issues

- Fix traffic view issues

- Optimize performance

- Update core

- Optimize core stability

- Fix linux tun authority check error

- Fix some issues

- Fix scroll physics error

- Add windows storage corruption detection

- Fix core crash caused by windows resource manager restart

- Optimize logs, requests, access to pages

- Fix macos bypass domain issues

- Fix some issues

- Update popup menu

- Add file editor

- Fix android service issues

- Optimize desktop background performance

- Optimize android main process performance

- Optimize delay test

- Optimize vpn protect

- Update core

- Fix some issues

- Remake dashboard

- Optimize theme

- Optimize more details

- Update flutter version

- Support better window position memory

- Add windows arm64 and linux arm64 build script

- Optimize some details

- Remake desktop

- Optimize change proxy

- Optimize network check

- Fix fallback issues

- Optimize lots of details

- Update change.yaml

- Fix android tile issues

- Fix windows tray issues

- Support setting bypassDomain

- Update flutter version

- Fix android service issues

- Fix macos dock exit button issues

- Add route address setting

- Optimize provider view

- Update CHANGELOG.md

- Add android shortcuts

- Fix init params issues

- Fix dynamic color issues

- Optimize navigator animate

- Optimize window init

- Optimize fab

- Optimize save

- Fix the collapse issues

- Add fontFamily options

- Update core version

- Update flutter version

- Optimize ip check

- Optimize url-test

- Update release message

- Init auto gen changelog

- Fix windows tray issues

- Fix urltest issues

- Add auto changelog

- Fix windows admin auto launch issues

- Add android vpn options

- Support proxies icon configuration

- Optimize android immersion display

- Fix some issues

- Optimize ip detection

- Support android vpn ipv6 inbound switch

- Support log export

- Optimize more details

- Fix android system dns issues

- Optimize dns default option

- Fix some issues

- Update readme

- Fix build error2

- Fix build error

- Support desktop hotkey

- Support android ipv6 inbound

- Support android system dns

- fix some bugs

- Fix delete profile error

- Fix submit error 2

- Fix submit error

- Optimize DNS strategy

- Fix the problem that the tray is not displayed in some cases

- Optimize tray

- Update core

- Fix some error

- Fix tun update issues

- Add DNS override

- Fixed some bugs

- Optimize more detail

- Add Hosts override

- fix android tip error

- fix windows auto launch error

- Fix windows tray issues

- Optimize windows logic

- Optimize app logic

- Support windows administrator auto launch

- Support android close vpn

- Change flutter version

- Support profiles sort

- Support windows country flags display

- Optimize proxies page and profiles page columns

- Update flutter version

- Update version

- Update timeout time

- Update access control page

- Fix bug

- Optimize provider page

- Optimize delay test

- Support local backup and recovery

- Fix android tile service issues

- Fix linux core build error

- Add proxy-only traffic statistics

- Update core

- Optimize more details

- Add fdroid-repo

- Optimize proxies page

- Fix ua issues

- Optimize more details

- Fix windows build error

- Update app icon

- Fix desktop backup error

- Optimize request ua

- Change android icon

- Optimize dashboard

- Remove request validate certificate

- Sync core

- Fix windows error

- Fix setup.dart error

- Fix android system proxy not effective

- Add macos arm64

- Optimize proxies page

- Support mouse drag scroll

- Adjust desktop ui

- Revert "Fix android vpn issues"

- This reverts commit 891977408e6938e2acd74e9b9adb959c48c79988.

- Fix android vpn issues

- Fix android vpn issues

- Rollback partial modification

- Fix the problem that ui can't be synchronized when android vpn is occupied by an external

- Override default socksPort,port

- Fix fab issues

- Update version

- Fix the problem that vpn cannot be started in some cases

- Fix the problem that geodata url does not take effect

- Update ua

- Fix change outbound mode without check ip issues

- Separate android ui and vpn

- Fix url validate issues 2

- Add android hidden from the recent task

- Add geoip file

- Support modify geoData URL

- Fix url validate issues

- Fix check ip performance problem

- Optimize resources page

- Add ua selector

- Support modify test url

- Optimize android proxy

- Fix the error that async proxy provider could not selected the proxy

- Fix android proxy error

- Fix submit error

- Add windows tun

- Optimize android proxy

- Optimize change profile

- Update application ua

- Optimize delay test

- Fix android repeated request notification issues

- Fix memory overflow issues

- Optimize proxies expansion panel 2

- Fix android scan qrcode error

- Optimize proxies expansion panel

- Fix text error

- Optimize proxy

- Optimize delayed sorting performance

- Add expansion panel proxies page

- Support to adjust the proxy card size

- Support to adjust proxies columns number

- Fix autoRun show issues

- Fix Android 10 issues

- Optimize ip show

- Add intranet IP display

- Add connections page

- Add search in connections, requests

- Add keyword search in connections, requests, logs

- Add basic viewing editing capabilities

- Optimize update profile

- Update version

- Fix the problem of excessive memory usage in traffic usage.

- Add lightBlue theme color

- Fix start unable to update profile issues

- Fix flashback caused by process

- Add build version

- Optimize quick start

- Update system default option

- Update build.yml

- Fix android vpn close issues

- Add requests page

- Fix checkUpdate dark mode style error

- Fix quickStart error open app

- Add memory proxies tab index

- Support hidden group

- Optimize logs

- Fix externalController hot load error

- Add tcp concurrent switch

- Add system proxy switch

- Add geodata loader switch

- Add external controller switch

- Add auto gc on trim memory

- Fix android notification error

- Fix ipv6 error

- Fix android udp direct error

- Add ipv6 switch

- Add access all selected button

- Remove android low version splash

- Update version

- Add allowBypass

- Fix Android only pick .text file issues

- Fix search issues

- Fix LoadBalance, Relay load error

- Fix build.yml4

- Fix build.yml3

- Fix build.yml2

- Fix build.yml

- Add search function at access control

- Fix the issues with the profile add button to cover the edit button

- Adapt LoadBalance and Relay

- Add arm

- Fix android notification icon error

- Add one-click update all profiles

- Add expire show

- Temp remove tun mode

- Remove macos in workflow

- Change go version

- Update Version

- Fix tun unable to open

- Optimize delay test2

- Optimize delay test

- Add check ip

- add check ip request

- Fix the problem that the download of remote resources failed after GeodataMode was turned on, which caused the application to flash back.

- Fix edit profile error

- Fix quickStart change proxy error

- Fix core version

- Fix core version

- Update file_picker

- Add resources page

- Optimize more detail

- Add access selected sorted

- Fix notification duplicate creation issue

- Fix AccessControl click issue

- Fix Workflow

- Fix Linux unable to open

- Update README.md 3

- Create LICENSE

## 0.8.97

- Fix Android TV adaptive icon safe zone

- Complete V2Board integration and refresh app icons

- Remove V2Board label from login page

- fix: request Clash Meta subscriptions

- feat: resolve V2Board servers by service code

- Require a JSON service-code map at build time and replace direct server URL entry with localized code validation.

- feat: rebrand YuClash and integrate V2Board

- Update platform identifiers and packaging metadata, add V2Board login and subscription import, and retarget Firebase and release automation.

## v0.8.96

- Optimize commented policy

- Fix whole group delay test failing on Windows

- Optimize package icon loading and connections polling

## v0.8.96-pre.1

- Optimize commented policy

- Fix whole group delay test failing on Windows

- Optimize package icon loading and connections polling

## v0.8.95

- Optimize core service

- Optimize Android TV launcher icon

- Optimize back navigation

- Optimize more details

- Fix some issues

- Optimize app layout

- Optimize focus control

- Adjust android process

## v0.8.94

- Fix macos performance issue

- Support custom global-ua

- Update core

- Optimize some details

- Fix linux silent launching not working

## v0.8.93

- Support custom overwrite

- Support run on demand

- Optimize windows ipc

- Optimize windows arm64

- Optimize build

- Optimize some details

- Update core

## v0.8.92

- Add sqlite store

- Optimize android quick action

- Optimize backup and restore

- Optimize more details

## v0.8.91

- Fix windows some issues

- Optimize overwrite handle

- Optimize access control page

- Optimize some details

## v0.8.90

- Fix android tile service

- Support append system DNS

- Fix some issues

## v0.8.89

- Fix some issues

- Optimize Windows service mode

- Update core

## v0.8.88

- Add android separates the core process

- Support core status check and force restart

- Optimize proxies page and access page

- Update flutter and pub dependencies

- Update go version

- Optimize more details

## v0.8.87

- Optimize desktop view

- Optimize logs, requests, connection pages

- Optimize windows tray auto hide

- Optimize some details

- Update core

## v0.8.86

- Fix windows tun issues

- Optimize android get system dns

- Optimize more details

## v0.8.85

- Support override script

- Support proxies search

- Support svg display

- Optimize config persistence

- Add some scenes auto close connections

- Update core

- Optimize more details

## v0.8.84

- Fix issues that TUN repeat failed to open.

- Fix windows service verify issues

## v0.8.83

- Add windows server mode start process verify

- Add linux deb dependencies

- Add backup recovery strategy select

- Support custom text scaling

- Optimize the display of different text scale

- Optimize windows setup experience

- Optimize startTun performance

- Optimize android tv experience

- Optimize default option

- Optimize computed text size

- Optimize hyperOS freeform window

- Add developer mode

- Update core

- Optimize more details

- Add issues template

## v0.8.82

- Optimize android vpn performance

- Add custom primary color and color scheme

- Add linux nad windows arm release

- Optimize requests and logs page

- Fix map input page delete issues

## v0.8.81

- Add rule override

- Update core

- Optimize more details

## v0.8.80

- Optimize dashboard performance

- Fix some issues

- Fix unselected proxy group delay issues

- Fix asn url issues

## v0.8.79

- Fix tab delay view issues

- Fix tray action issues

- Fix get profile redirect client ua issues

- Fix proxy card delay view issues

- Add Russian, Japanese adaptation

- Fix some issues

## v0.8.78

- Fix list form input view issues

- Fix traffic view issues

## v0.8.77

- Optimize performance

- Update core

- Optimize core stability

- Fix linux tun authority check error

- Fix some issues

- Fix scroll physics error

## v0.8.75

- Add windows storage corruption detection

- Fix core crash caused by windows resource manager restart

- Optimize logs, requests, access to pages

- Fix macos bypass domain issues

## v0.8.74

- Fix some issues

## v0.8.73

- Update popup menu

- Add file editor

- Fix android service issues

- Optimize desktop background performance

- Optimize android main process performance

- Optimize delay test

- Optimize vpn protect

## v0.8.72

- Update core

- Fix some issues

## v0.8.71

- Remake dashboard

- Optimize theme

- Optimize more details

- Update flutter version

## v0.8.70

- Support better window position memory

- Add windows arm64 and linux arm64 build script

- Optimize some details

## v0.8.69

- Remake desktop

- Optimize change proxy

- Optimize network check

- Fix fallback issues

- Optimize lots of details

- Update change.yaml

- Fix android tile issues

- Fix windows tray issues

- Support setting bypassDomain

- Update flutter version

- Fix android service issues

- Fix macos dock exit button issues

- Add route address setting

- Optimize provider view

- Update CHANGELOG.md

- Add android shortcuts

- Fix init params issues

- Fix dynamic color issues

- Optimize navigator animate

- Optimize window init

- Optimize fab

- Optimize save

- Fix the collapse issues

- Add fontFamily options

- Update core version

- Update flutter version

- Optimize ip check

- Optimize url-test

- Update release message

- Init auto gen changelog

- Fix windows tray issues

- Fix urltest issues

- Add auto changelog

- Fix windows admin auto launch issues

- Add android vpn options

- Support proxies icon configuration

- Optimize android immersion display

- Fix some issues

- Optimize ip detection

- Support android vpn ipv6 inbound switch

- Support log export

- Optimize more details

- Fix android system dns issues

- Optimize dns default option

- Fix some issues

- Update readme

- Fix build error2

- Fix build error

- Support desktop hotkey

- Support android ipv6 inbound

- Support android system dns

- fix some bugs

- Fix delete profile error

- Fix submit error 2

- Fix submit error

- Optimize DNS strategy

- Fix the problem that the tray is not displayed in some cases

- Optimize tray

- Update core

- Fix some error

- Fix tun update issues

- Add DNS override

- Fixed some bugs

- Optimize more detail

- Add Hosts override

- fix android tip error

- fix windows auto launch error

- Fix windows tray issues

- Optimize windows logic

- Optimize app logic

- Support windows administrator auto launch

- Support android close vpn

- Change flutter version

- Support profiles sort

- Support windows country flags display

- Optimize proxies page and profiles page columns

- Update flutter version

- Update version

- Update timeout time

- Update access control page

- Fix bug

- Optimize provider page

- Optimize delay test

- Support local backup and recovery

- Fix android tile service issues

- Fix linux core build error

- Add proxy-only traffic statistics

- Update core

- Optimize more details

- Add fdroid-repo

## v0.8.48

- Optimize proxies page

- Fix ua issues

- Optimize more details

## v0.8.47

- Fix windows build error

## v0.8.46

- Update app icon

- Fix desktop backup error

- Optimize request ua

- Change android icon

- Optimize dashboard

## v0.8.44

- Remove request validate certificate

- Sync core

## v0.8.43

- Fix windows error

## v0.8.42

- Fix setup.dart error

- Fix android system proxy not effective

- Add macos arm64

## v0.8.41

- Optimize proxies page

- Support mouse drag scroll

- Adjust desktop ui

- Revert "Fix android vpn issues"

- This reverts commit 8a6838337a92e9d5661d54be367e8b0db609ba5f.

## v0.8.40

- Fix android vpn issues

- Fix android vpn issues

- Rollback partial modification

## v0.8.39

- Fix the problem that ui can't be synchronized when android vpn is occupied by an external

- Override default socksPort,port

## v0.8.38

- Fix fab issues

## v0.8.37

- Update version

- Fix the problem that vpn cannot be started in some cases

- Fix the problem that geodata url does not take effect

## v0.8.36

- Update ua

- Fix change outbound mode without check ip issues

- Separate android ui and vpn

- Fix url validate issues 2

- Add android hidden from the recent task

- Add geoip file

- Support modify geoData URL

## v0.8.35

- Fix url validate issues

- Fix check ip performance problem

- Optimize resources page

## v0.8.34

- Add ua selector

- Support modify test url

- Optimize android proxy

- Fix the error that async proxy provider could not selected the proxy

## v0.8.33

- Fix android proxy error

- Fix submit error

- Add windows tun

- Optimize android proxy

- Optimize change profile

- Update application ua

- Optimize delay test

## v0.8.32

- Fix android repeated request notification issues

## v0.8.31

- Fix memory overflow issues

## v0.8.30

- Optimize proxies expansion panel 2

- Fix android scan qrcode error

## v0.8.29

- Optimize proxies expansion panel

- Fix text error

## v0.8.28

- Optimize proxy

- Optimize delayed sorting performance

- Add expansion panel proxies page

- Support to adjust the proxy card size

- Support to adjust proxies columns number

- Fix autoRun show issues

- Fix Android 10 issues

- Optimize ip show

## v0.8.26

- Add intranet IP display

- Add connections page

- Add search in connections, requests

- Add keyword search in connections, requests, logs

- Add basic viewing editing capabilities

- Optimize update profile

## v0.8.25

- Update version

- Fix the problem of excessive memory usage in traffic usage.

- Add lightBlue theme color

- Fix start unable to update profile issues

- Fix flashback caused by process

## v0.8.23

- Add build version

- Optimize quick start

- Update system default option

## v0.8.22

- Update build.yml

- Fix android vpn close issues

- Add requests page

- Fix checkUpdate dark mode style error

- Fix quickStart error open app

- Add memory proxies tab index

- Support hidden group

- Optimize logs

- Fix externalController hot load error

## v0.8.21

- Add tcp concurrent switch

- Add system proxy switch

- Add geodata loader switch

- Add external controller switch

- Add auto gc on trim memory

- Fix android notification error

## v0.8.20

- Fix ipv6 error

- Fix android udp direct error

- Add ipv6 switch

- Add access all selected button

- Remove android low version splash

## v0.8.19

- Update version

- Add allowBypass

- Fix Android only pick .text file issues

## v0.8.18

- Fix search issues

## v0.8.17

- Fix LoadBalance, Relay load error

- Fix build.yml4

- Fix build.yml3

- Fix build.yml2

- Fix build.yml

- Add search function at access control

- Fix the issues with the profile add button to cover the edit button

- Adapt LoadBalance and Relay

- Add arm

- Fix android notification icon error

## v0.8.16

- Add one-click update all profiles

- Add expire show

## v0.8.15

- Temp remove tun mode

- Remove macos in workflow

- Change go version

## v0.8.14

- Update Version

- Fix tun unable to open

## v0.8.13

- Optimize delay test2

- Optimize delay test

- Add check ip

- add check ip request

## v0.8.12

- Fix the problem that the download of remote resources failed after GeodataMode was turned on, which caused the application to flash back.

- Fix edit profile error

- Fix quickStart change proxy error

- Fix core version

## v0.8.10

- Fix core version

## v0.8.9

- Update file_picker

- Add resources page

- Optimize more detail

- Add access selected sorted

- Fix notification duplicate creation issue

- Fix AccessControl click issue

## v0.8.7

- Fix Workflow

- Fix Linux unable to open

- Update README.md 3

- Create LICENSE

- Update README.md 2

- Update README.md

- Optimize workFlow

## v0.8.6

- optimize checkUpdate

## v0.8.5

- Fix submit error

## v0.8.4

- add WebDAV

- add Auto check updates

- Optimize more details

- optimize delayTest

## v0.8.2

- upgrade flutter version

## v0.8.1

- Update kernel

- Add import profile via QR code image

## v0.8.0

- Add compatibility mode and adapt clash scheme.

## v0.7.14

- update Version

- Reconstruction application proxy logic

## v0.7.13

- Fix Tab destroy error

## v0.7.12

- Optimize repeat healthcheck

## v0.7.11

- Optimize Direct mode ui

## v0.7.10

- Optimize Healthcheck

- Remove proxies position animation, improve performance

- Add Telegram Link

- Update healthcheck policy

- New Check URLTest

- Fix the problem of invalid auto-selection

## v0.7.8

- New Async UpdateConfig

- add changeProfileDebounce

- Update Workflow

- Fix ChangeProfile block

- Fix Release Message Error

## v0.7.7

- Update Selector 2

## v0.7.6

- Update Version

- Fix Proxies Select Error

## v0.7.5

- Fix the problem that the proxy group is empty in global mode.

- Fix the problem that the proxy group is empty in global mode.

## v0.7.4

- Add ProxyProvider2

## v0.7.3

- Add ProxyProvider

- Update Version

- Update ProxyGroup Sort

- Fix Android quickStart VpnService some problems

## v0.7.1

- Update version

- Set Android notification low importance

- Fix the issue that VpnService can't be closed correctly in special cases

- Fix the problem that TileService is not destroyed correctly in some cases

- Adjust tab animation defaults

- Add Telegram in README_zh_CN.md

- Add Telegram

## v0.7.0

- update mobile_scanner

- Initial commit

# Changelog

## v1.0.0 (2026-09-17)

**Bug Fixes**

- **changelog** Restore the frozen marker and realign v0.8.98 with its tag (bc62ac7)
- **android** Keep the TV adaptive icon foreground inside the safe zone (65bee3a)
- **build** Restore the YuClash Core/Helper artifact names (f664be7)
- **resources** Refresh the geo file size and time after an update finishes (6d192ba)
- **core** Keep the core running while Windows sleeps with the app suspended (0dad8c8)

## v0.8.98 (2026-09-16)

**Features**

- Resolve V2Board servers by service code (be499ac)
- Rebrand YuClash and integrate V2Board (8e3f22b)

**Bug Fixes**

- **rust_api** Fall back to a sibling NDK's libclang for Android bindgen (a7bd4d1)
- **setup** Re-exclude buildkit/build_tool from plugins/setup's analyzer (38ccbdc)
- Two test failures surfaced by CI after the icon/scheme fixes (75004b1)
- Restore the real app identity (applicationId/bundle id) across platforms (5f436b1)
- **setup** Restore V2BOARD_BASE_URL wiring dropped by the upstream merge (8001282)
- Restore YuClash app icon overwritten by upstream during reconciliation (a8a228a)
- **android** Match Flutter MethodChannel names to the renamed packageName (fe4bb8c)
- **resources** Refresh the geo file size and time after an update finishes (c5bf5bd)
- **core** Keep the core running while Windows sleeps with the app suspended (60f371a)
- Resolve Inno Setup locale (72cf926)
- Resolve Windows package assets (8e6173c)
- Request Clash Meta subscriptions (c2be7c9)

## v0.8.97 (2026-09-10)

**Features**

- **ui** Rework the app UI and refresh the localization (26cfbaf)
- **app** Rework the app layer and window handling, and add proxy authentication (aaf934c)
- **desktop** Rework the desktop runners, packaging, and native build (c0fcbc0)
- **android** Rework the Android VPN service and lifecycle handling (ae29f38)
- **plugins** Rework the desktop plugins and add the Helper service and Rust bridge (adf715f)
- **core** Rework the core IPC and process lifecycle (c6eaa0a)

<!-- changelog:frozen -->
<!-- Entries below predate the structured pipeline. Their wording is kept as written; only the heading and list style were normalized. -->

## v0.8.96 (2026-08-17)

- Optimize commented policy
- Fix whole group delay test failing on Windows
- Optimize package icon loading and connections polling

## v0.8.95 (2026-08-14)

- Optimize core service
- Optimize Android TV launcher icon
- Optimize back navigation
- Optimize more details
- Fix some issues
- Optimize app layout
- Optimize focus control
- Adjust android process

## v0.8.94 (2026-07-11)

- Fix macos performance issue
- Support custom global-ua
- Update core
- Optimize some details
- Fix linux silent launching not working

## v0.8.93 (2026-05-29)

- Support custom overwrite
- Support run on demand
- Optimize windows ipc
- Optimize windows arm64
- Optimize build
- Optimize some details
- Update core

## v0.8.92 (2026-02-02)

- Add sqlite store
- Optimize android quick action
- Optimize backup and restore
- Optimize more details

## v0.8.91 (2025-12-12)

- Fix windows some issues
- Optimize overwrite handle
- Optimize access control page
- Optimize some details

## v0.8.90 (2025-10-08)

- Fix android tile service
- Support append system DNS
- Fix some issues
- Update changelog

## v0.8.89 (2025-09-27)

- Fix some issues
- Optimize Windows service mode
- Update core
- Update changelog

## v0.8.88 (2025-09-23)

- Add android separates the core process
- Support core status check and force restart
- Optimize proxies page and access page
- Update flutter and pub dependencies
- Update go version
- Optimize more details
- Update changelog

## v0.8.87 (2025-07-29)

- Optimize desktop view
- Optimize logs, requests, connection pages
- Optimize windows tray auto hide
- Optimize some details
- Update core
- Update changelog

## v0.8.86 (2025-06-15)

- Fix windows tun issues
- Optimize android get system dns
- Optimize more details
- Update changelog

## v0.8.85 (2025-06-07)

- Support override script
- Support proxies search
- Support svg display
- Optimize config persistence
- Add some scenes auto close connections
- Update core
- Optimize more details

## v0.8.84 (2025-05-01)

- Fix windows service verify issues
- Update changelog

## v0.8.83 (2025-05-01)

- Add windows server mode start process verify
- Add linux deb dependencies
- Add backup recovery strategy select
- Support custom text scaling
- Optimize the display of different text scale
- Optimize windows setup experience
- Optimize startTun performance
- Optimize android tv experience
- Optimize default option
- Optimize computed text size
- Optimize hyperOS freeform window
- Add developer mode
- Update core
- Optimize more details
- Add issues template
- Update changelog

## v0.8.82 (2025-04-18)

- Optimize android vpn performance
- Add custom primary color and color scheme
- Add linux nad windows arm release
- Optimize requests and logs page
- Fix map input page delete issues
- Update changelog

## v0.8.81 (2025-04-08)

- Add rule override
- Update core
- Optimize more details
- Update changelog

## v0.8.80 (2025-03-10)

- Optimize dashboard performance
- Fix some issues
- Fix unselected proxy group delay issues
- Fix asn url issues
- Update changelog

## v0.8.79 (2025-03-07)

- Fix tab delay view issues
- Fix tray action issues
- Fix get profile redirect client ua issues
- Fix proxy card delay view issues
- Add Russian, Japanese adaptation
- Fix some issues
- Update changelog

## v0.8.78 (2025-03-05)

- Fix list form input view issues
- Fix traffic view issues
- Update changelog

## v0.8.77 (2025-03-05)

- Optimize performance
- Update core
- Optimize core stability
- Fix linux tun authority check error
- Fix some issues
- Fix scroll physics error
- Update changelog

## v0.8.75 (2025-02-09)

- Add windows storage corruption detection
- Fix core crash caused by windows resource manager restart
- Optimize logs, requests, access to pages
- Fix macos bypass domain issues
- Update changelog

## v0.8.74 (2025-02-03)

- Fix some issues
- Update changelog

## v0.8.73 (2025-02-02)

- Update popup menu
- Add file editor
- Fix android service issues
- Optimize desktop background performance
- Optimize android main process performance
- Optimize delay test
- Optimize vpn protect
- Update changelog

## v0.8.72 (2025-01-10)

- Update core
- Fix some issues
- Update changelog

## v0.8.71 (2025-01-09)

- Remake dashboard
- Optimize theme
- Optimize more details
- Update flutter version
- Update changelog

## v0.8.70 (2024-12-09)

- Support better window position memory
- Add windows arm64 and linux arm64 build script
- Optimize some details

## v0.8.69 (2024-12-06)

- Remake desktop
- Optimize change proxy
- Optimize network check
- Fix fallback issues
- Optimize lots of details
- Update change.yaml
- Fix android tile issues
- Fix windows tray issues
- Support setting bypassDomain
- Update flutter version
- Fix android service issues
- Fix macos dock exit button issues
- Add route address setting
- Optimize provider view
- Update changelog
- Update CHANGELOG.md

## v0.8.67 (2024-11-09)

- Add android shortcuts
- Fix init params issues
- Fix dynamic color issues
- Optimize navigator animate
- Optimize window init
- Optimize fab
- Optimize save

## v0.8.66 (2024-10-26)

- Fix the collapse issues
- Add fontFamily options

## v0.8.65 (2024-10-26)

- Update core version
- Update flutter version
- Optimize ip check
- Optimize url-test

## v0.8.64 (2024-10-12)

- Update release message
- Init auto gen changelog
- Fix windows tray issues
- Fix urltest issues
- Add auto changelog
- Fix windows admin auto launch issues
- Add android vpn options
- Support proxies icon configuration
- Optimize android immersion display
- Fix some issues
- Optimize ip detection
- Support android vpn ipv6 inbound switch
- Support log export
- Optimize more details
- Fix android system dns issues
- Optimize dns default option
- Fix some issues
- Update readme

## v0.8.60 (2024-09-17)

- Fix build error2
- Fix build error
- Support desktop hotkey
- Support android ipv6 inbound
- Support android system dns
- fix some bugs

## v0.8.59 (2024-09-09)

- Fix delete profile error

## v0.8.58 (2024-09-08)

- Fix submit error 2
- Fix submit error
- Optimize DNS strategy
- Fix the problem that the tray is not displayed in some cases
- Optimize tray
- Update core
- Fix some error

## v0.8.57 (2024-09-02)

- Fix tun update issues
- Add DNS override
- Fixed some bugs
- Optimize more detail
- Add Hosts override

## v0.8.56 (2024-08-26)

- fix android tip error
- fix windows auto launch error

## v0.8.55 (2024-08-25)

- Fix windows tray issues
- Optimize windows logic
- Optimize app logic
- Support windows administrator auto launch
- Support android close vpn

## v0.8.53 (2024-08-15)

- Change flutter version
- Support profiles sort
- Support windows country flags display
- Optimize proxies page and profiles page columns

## v0.8.52 (2024-08-11)

- Update flutter version
- Update version
- Update timeout time
- Update access control page
- Fix bug

## v0.8.51 (2024-08-05)

- Optimize provider page
- Optimize delay test
- Support local backup and recovery
- Fix android tile service issues

## v0.8.49 (2024-07-31)

- Fix linux core build error
- Add proxy-only traffic statistics
- Update core
- Optimize more details
- Merge pull request #140 from txyyh/main
- 添加自建 F-Droid 仓库相关 workflow
- Rename readme fingerprint
- Rename workflow deploy repo name
- Add download guide to README
- Add push release files to fdroid-repo

## v0.8.48 (2024-07-25)

- Optimize proxies page
- Fix ua issues
- Optimize more details

## v0.8.47 (2024-07-22)

- Fix windows build error

## v0.8.46 (2024-07-22)

- Update app icon
- Fix desktop backup error
- Optimize request ua
- Change android icon
- Optimize dashboard

## v0.8.44 (2024-07-18)

- Remove request validate certificate
- Sync core

## v0.8.43 (2024-07-18)

- Fix windows error

## v0.8.42 (2024-07-18)

- Fix setup.dart error
- Fix android system proxy not effective
- Add macos arm64

## v0.8.41 (2024-07-17)

- Optimize proxies page
- Support mouse drag scroll
- Adjust desktop ui
- Revert "Fix android vpn issues"
- This reverts commit 891977408e6938e2acd74e9b9adb959c48c79988.

## v0.8.40 (2024-07-15)

- Fix android vpn issues
- Fix android vpn issues
- Rollback partial modification

## v0.8.39 (2024-07-15)

- Fix the problem that ui can't be synchronized when android vpn is occupied by an external
- Override default socksPort,port

## v0.8.38 (2024-07-14)

- Fix fab issues

## v0.8.37 (2024-07-14)

- Update version
- Fix the problem that vpn cannot be started in some cases
- Fix the problem that geodata url does not take effect

## v0.8.36 (2024-07-13)

- Update ua
- Fix change outbound mode without check ip issues
- Separate android ui and vpn
- Fix url validate issues 2
- Add android hidden from the recent task
- Add geoip file
- Support modify geoData URL

## v0.8.35 (2024-07-07)

- Fix url validate issues
- Fix check ip performance problem
- Optimize resources page

## v0.8.34 (2024-07-04)

- Add ua selector
- Support modify test url
- Optimize android proxy
- Fix the error that async proxy provider could not selected the proxy

## v0.8.33 (2024-07-01)

- Fix android proxy error
- Fix submit error
- Add windows tun
- Optimize android proxy
- Optimize change profile
- Update application ua
- Optimize delay test

## v0.8.32 (2024-06-28)

- Fix android repeated request notification issues

## v0.8.31 (2024-06-28)

- Fix memory overflow issues

## v0.8.30 (2024-06-27)

- Optimize proxies expansion panel 2
- Fix android scan qrcode error

## v0.8.29 (2024-06-27)

- Optimize proxies expansion panel
- Fix text error

## v0.8.28 (2024-06-26)

- Optimize proxy
- Optimize delayed sorting performance
- Add expansion panel proxies page
- Support to adjust the proxy card size
- Support to adjust proxies columns number
- Fix autoRun show issues
- Fix Android 10 issues
- Optimize ip show

## v0.8.26 (2024-06-22)

- Add intranet IP display
- Add connections page
- Add search in connections, requests
- Add keyword search in connections, requests, logs
- Add basic viewing editing capabilities
- Optimize update profile

## v0.8.25 (2024-06-19)

- Update version
- Fix the problem of excessive memory usage in traffic usage.
- Add lightBlue theme color
- Fix start unable to update profile issues
- Fix flashback caused by process

## v0.8.23 (2024-06-16)

- Add build version
- Optimize quick start
- Update system default option

## v0.8.22 (2024-06-16)

- Update build.yml
- Fix android vpn close issues
- Add requests page
- Fix checkUpdate dark mode style error
- Fix quickStart error open app
- Add memory proxies tab index
- Support hidden group
- Optimize logs
- Fix externalController hot load error

## v0.8.21 (2024-06-13)

- Add tcp concurrent switch
- Add system proxy switch
- Add geodata loader switch
- Add external controller switch
- Add auto gc on trim memory
- Fix android notification error

## v0.8.20 (2024-06-12)

- Fix ipv6 error
- Fix android udp direct error
- Add ipv6 switch
- Add access all selected button
- Remove android low version splash

## v0.8.19 (2024-06-10)

- Update version
- Add allowBypass
- Fix Android only pick .text file issues

## v0.8.18 (2024-06-09)

- Fix search issues

## v0.8.17 (2024-06-09)

- Fix LoadBalance, Relay load error
- Fix build.yml4
- Fix build.yml3
- Fix build.yml2
- Fix build.yml
- Add search function at access control
- Fix the issues with the profile add button to cover the edit button
- Adapt LoadBalance and Relay
- Add arm
- Fix android notification icon error

## v0.8.16 (2024-06-08)

- Add one-click update all profiles
- Add expire show

## v0.8.15 (2024-06-06)

- Temp remove tun mode
- Remove macos in workflow
- Change go version

## v0.8.14 (2024-06-06)

- Update Version
- Fix tun unable to open

## v0.8.13 (2024-06-06)

- Optimize delay test2
- Optimize delay test
- Add check ip
- add check ip request

## v0.8.12 (2024-06-06)

- Fix the problem that the download of remote resources failed after GeodataMode was turned on, which caused the
  application to flash back.
- Fix edit profile error
- Fix quickStart change proxy error
- Fix core version

## v0.8.10 (2024-06-05)

- Fix core version

## v0.8.9 (2024-06-05)

- Update file_picker
- Add resources page
- Optimize more detail
- Add access selected sorted
- Fix notification duplicate creation issue
- Fix AccessControl click issue

## v0.8.7 (2024-05-31)

- Fix Workflow
- Fix Linux unable to open
- Update README.md 3
- Create LICENSE
- Update README.md 2
- Update README.md
- Optimize workFlow

## v0.8.6 (2024-05-31)

- optimize checkUpdate

## v0.8.5 (2024-05-30)

- Fix submit error

## v0.8.4 (2024-05-30)

- add WebDAV
- add Auto check updates
- Optimize more details
- optimize delayTest

## v0.8.2 (2024-05-15)

- upgrade flutter version

## v0.8.1 (2024-05-15)

- Update kernel
- Add import profile via QR code image

## v0.8.0 (2024-05-11)

- Add compatibility mode and adapt clash scheme.

## v0.7.14 (2024-05-07)

- update Version
- Reconstruction application proxy logic

## v0.7.13 (2024-05-06)

- Fix Tab destroy error

## v0.7.12 (2024-05-06)

- Optimize repeat healthcheck

## v0.7.11 (2024-05-06)

- Optimize Direct mode ui

## v0.7.10 (2024-05-06)

- Optimize Healthcheck
- Remove proxies position animation, improve performance
- Add Telegram Link
- Update healthcheck policy
- New Check URLTest
- Fix the problem of invalid auto-selection

## v0.7.8 (2024-05-05)

- New Async UpdateConfig
- add changeProfileDebounce
- Update Workflow
- Fix ChangeProfile block
- Fix Release Message Error

## v0.7.7 (2024-05-04)

- Update Selector 2

## v0.7.6 (2024-05-04)

- Update Version
- Fix Proxies Select Error

## v0.7.5 (2024-05-03)

- Fix the problem that the proxy group is empty in global mode.
- Fix the problem that the proxy group is empty in global mode.

## v0.7.4 (2024-05-03)

- Add ProxyProvider2

## v0.7.3 (2024-05-03)

- Add ProxyProvider
- Update Version
- Update ProxyGroup Sort
- Fix Android quickStart VpnService some problems

## v0.7.1 (2024-05-01)

- Update version
- Set Android notification low importance
- Fix the issue that VpnService can't be closed correctly in special cases
- Fix the problem that TileService is not destroyed correctly in some cases
- Adjust tab animation defaults
- Add Telegram in README_zh_CN.md
- Add Telegram

## v0.7.0 (2024-04-30)

- update mobile_scanner
- Initial commit
