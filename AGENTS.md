# Repository Guidelines

## Project Structure & Module Organization
Application code lives in `SwiftFastPass/`. `UI/` contains the controllers, rows, and reusable cells; `Models/` defines password entities; and `PasswordCreator/` holds generator logic shared across flows. Assets and fonts are stored in `Assets.xcassets` and `fonts/`, while `Base.lproj`, `en.lproj`, and `zh-Hans.lproj` track localized storyboards and strings. Third-party code is checked in through `Pods/` and `Carthage/`, and glue types live under `Utils/`. Tests are isolated to `SwiftFastPassTests/` (unit) and `SwiftFastPassUITests/` (automation).

## Build, Test, and Development Commands
- `pod install` — install CocoaPods dependencies (SnapKit, MenuItemKit, Eureka) and refresh the workspace.
- `carthage bootstrap --platform iOS --use-xcframeworks` — pull Carthage frameworks required by the bridging header.
- `xcodebuild -workspace SwiftFastPass.xcworkspace -scheme SwiftFastPass -destination "platform=iOS Simulator,name=iPhone 15"` — build without tests.
- `xcodebuild test -workspace SwiftFastPass.xcworkspace -scheme SwiftFastPass -destination "platform=iOS Simulator,name=iPhone 15"` — run unit + UI tests headlessly.

## Coding Style & Naming Conventions
Use Swift 5 defaults: four-space indentation, brace-on-same-line, and `final class` unless subclasses are expected. Types/enums use `UpperCamelCase`, members and files use `lowerCamelCase`, and storyboard identifiers match their controller (e.g., `PasswordListViewController`). Shared constants or password policies should live in `Utils/` extensions; reusable views belong in nested folders under `UI/`. Keep asset names lowercase-with-dashes and update every `.lproj` variant when adding localized copy.

## Testing Guidelines
XCTest backs both targets. Name test files `<Type>Tests.swift` and functions `test<Scenario>_<Expectation>()`. Focus unit tests on generator math, model encoding, and localization helpers inside `SwiftFastPassTests/`. End-to-end flows (copying passwords, switching locales) belong in `SwiftFastPassUITests/` with descriptive method names like `testPasswordCopyFlow`. Every feature must add at least one unit test, and UI-impacting changes need a smoke test before review.

## Commit & Pull Request Guidelines
The history favors concise, imperative subjects (`fix code sign.`, `beta iOS 13.`); mirror that tone and optionally prefix the subsystem (`UI:` or `Models:`). Keep commits focused and cite issue numbers in the body when relevant. Pull requests must include a short summary, linked issues, simulator screenshots for UI work, and confirmation that `xcodebuild test` passed. Call out localization edits, dependency upgrades, or signing changes so reviewers can double-check them quickly.

## Security & Configuration Tips
Do not commit real provisioning profiles or certificates; only share the placeholders referenced by `SwiftFastPass.entitlements`. Inject keys and secrets via Xcode build settings instead of `Info.plist`. When touching `SwiftFastPass-Bridging-Header.h`, expose the minimum Objective-C surface and prefer `@objc` wrappers to isolate legacy code.
