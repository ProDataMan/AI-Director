# AI Director — Detailed Implementation Plan

This document is the authoritative development handoff for implementing **AI Director**.

It is written so that another coding agent — especially Claude Code — can take over development with minimal additional explanation.

The README describes the product vision. This file defines **how to build it**.

---


# Implementation Status

Last updated: initial Swift foundation branch.

## Completed

- [x] Create Swift Package Manager project.
- [x] Create StudioCore target.
- [x] Create OBSKit target.
- [x] Create StudioDirector target.
- [x] Create AIKit target.
- [x] Create RecordingKit target.
- [x] Create StudioCore and OBSKit test targets.
- [x] Add macOS GitHub Actions build/test workflow.
- [x] Implement StudioState.
- [x] Implement SceneRole.
- [x] Implement CameraShot.
- [x] Implement RGBColor.
- [x] Implement ColorPalette.
- [x] Implement OBS Hello DTOs.
- [x] Implement OBS Identify DTOs.
- [x] Implement OBS Identified DTOs.
- [x] Implement OBS Request DTOs.
- [x] Implement OBS RequestResponse DTOs.
- [x] Implement OBS Event DTOs.
- [x] Add actor-based OBSWebSocketClient transport skeleton.
- [x] Add protocol/domain encoding and decoding tests.
- [x] Validate current package locally with `swift test` — 7 tests passing.

## In Progress / Next

- [ ] Decode and route incoming OBS opcodes in OBSWebSocketClient.
- [ ] Implement Hello -> Identify -> Identified handshake state machine.
- [ ] Implement OBS authentication challenge hashing.
- [ ] Add request ID correlation with checked continuations.
- [ ] Add request timeout handling.
- [ ] Add event delivery mechanism.
- [ ] Add typed GetVersion and GetSceneList operations.
- [ ] Add optional live OBS integration test gated by environment variable.

## Known Limitations

The current `OBSWebSocketClient` establishes a WebSocket task and can encode/send JSON, but it does not yet complete OBS protocol negotiation. Its `connected` state currently means the WebSocket task has been resumed, not that OBS has completed the Identified handshake.

---

# 1. Project Goal

Build a Swift-first macOS application that uses AI to orchestrate a video-production workflow built around:

- OBS Studio for live production
- DaVinci Resolve Free for post-production
- Fusion for titles, overlays, and motion graphics
- Claude, ChatGPT/OpenAI, or Grok as interchangeable AI providers
- Swift as the primary language and orchestration layer
- SwiftUI as the desktop UI
- Swift Concurrency for asynchronous workflows
- OBS WebSocket for deterministic studio control
- Core Image/Core Graphics for asset and palette processing
- Vision for future presenter tracking

The long-term user experience should be:

```text
User:
"Prepare my studio for a Swift concurrency tutorial."

AI Director:
- Creates a visual design
- Generates or selects background assets
- Builds OBS scenes
- Positions the camera
- Configures demo/screen layouts
- Loads lower-thirds and overlays
- Prepares recording metadata

User:
"Start recording."

AI Director:
- Starts OBS recording
- Tracks scene changes
- Tracks camera moves
- Records markers and timestamps

User:
"Demo mode."

AI Director:
- Switches to code/demo layout
- Animates presenter camera into picture-in-picture

User:
"Redo that."

AI Director:
- Marks the previous segment as a retake

User:
"Stop recording."

AI Director:
- Stops recording
- Saves metadata
- Produces edit-plan inputs for DaVinci Resolve
```

---

# 2. Core Engineering Principles

These principles are requirements unless explicitly changed by the project owner.

## 2.1 Swift First

Use Swift for all application logic unless a third-party product requires another language.

Preferred:

- Swift
- SwiftUI
- actors
- async/await
- Codable
- Observation
- Foundation
- Core Image
- Core Graphics
- Vision

Avoid introducing:

- Node.js
- Electron
- Python application services
- Java
- .NET

A small Python or Lua adapter is acceptable only when DaVinci Resolve or Fusion requires it.

## 2.2 AI Produces Intent, Swift Executes

AI providers must not directly manipulate OBS or the operating system.

AI returns structured intent.

Example:

```swift
struct StudioPlan: Codable, Sendable {
    let title: String
    let design: StudioDesign
    let scenes: [ScenePlan]
}
```

Swift validates and executes that plan.

Do not create an architecture where raw model text is translated directly into shell commands.

## 2.3 Deterministic Live Operations

Operations that affect a live recording must be deterministic.

Examples:

- scene switching
- camera positioning
- pan/zoom
- recording start/stop
- source visibility
- media-source changes

AI may request these operations, but only Swift executes them.

## 2.4 No UI Screen-Scraping Unless Unavoidable

Prefer public APIs.

Order of preference:

1. OBS WebSocket
2. documented application APIs
3. documented local scripting
4. project/export formats
5. controlled file generation
6. UI automation only as last resort

## 2.5 Free DaVinci Resolve Is the Baseline

Do not require Resolve Studio for the MVP.

The MVP must still work if the user only has:

- OBS Studio
- DaVinci Resolve Free
- an AI provider API key

Any Studio-only enhancement must be isolated behind an optional capability.

---

# 3. Target Platform

Initial supported platform:

```text
macOS
Apple Silicon preferred
Swift 6+
Xcode current stable
OBS Studio current stable
DaVinci Resolve Free current stable
```

Do not optimize for Windows or Linux during the first implementation.

The architecture should not prevent future portability, but macOS is the first-class target.

---

# 4. Repository Structure

Target structure:

```text
AI-Director/
|
+-- README.md
+-- IMPLEMENTATION_PLAN.md
+-- Package.swift
|
+-- Apps/
|   +-- AIStudioMac/
|       +-- AIStudioApp.swift
|       +-- Views/
|       +-- ViewModels/
|       +-- Resources/
|
+-- Sources/
|   +-- StudioCore/
|   +-- StudioDirector/
|   +-- OBSKit/
|   +-- AIKit/
|   +-- GraphicsKit/
|   +-- AssetKit/
|   +-- RecordingKit/
|   +-- ResolveKit/
|   +-- VisionDirector/
|
+-- Tests/
|   +-- StudioCoreTests/
|   +-- StudioDirectorTests/
|   +-- OBSKitTests/
|   +-- AIKitTests/
|   +-- GraphicsKitTests/
|   +-- RecordingKitTests/
|
+-- Resolve/
|   +-- Fusion/
|   +-- Scripts/
|   +-- Templates/
|
+-- Examples/
|   +-- StudioPlans/
|   +-- RecordingMetadata/
|   +-- EditPlans/
|
+-- Docs/
    +-- OBS_PROTOCOL.md
    +-- AI_PROVIDER_SCHEMA.md
    +-- RESOLVE_INTEGRATION.md
    +-- ARCHITECTURE.md
```

Do not create every folder immediately if empty directories add no value.

Create the structure incrementally as functionality is implemented.

---

# 5. Module Responsibilities

## 5.1 StudioCore

Contains domain models only.

No networking.
No SwiftUI.
No OBS-specific transport.
No AI-specific HTTP code.

Primary types:

```swift
StudioProject
StudioPlan
StudioDesign
ScenePlan
SceneRole
SourcePlan
CameraShot
CameraTransform
ColorPalette
RGBColor
RecordingSession
RecordingEvent
RecordingMetadata
EditPlan
EditAction
AssetDescriptor
```

These models must conform to:

```swift
Codable
Sendable
Equatable
```

where practical.

---

## 5.2 OBSKit

Responsible only for talking to OBS.

Responsibilities:

- connect to OBS WebSocket
- authenticate
- reconnect
- send requests
- receive responses
- receive OBS events
- expose typed Swift operations

OBSKit should not know about Claude, Grok, OpenAI, or user prompts.

Suggested public interface:

```swift
public protocol OBSControlling: Sendable {
    func connect() async throws
    func disconnect() async

    func version() async throws -> OBSVersion

    func scenes() async throws -> [OBSScene]
    func currentProgramScene() async throws -> String

    func createScene(named name: String) async throws
    func removeScene(named name: String) async throws
    func setCurrentProgramScene(_ name: String) async throws

    func sceneItems(in scene: String) async throws -> [OBSSceneItem]

    func setSceneItemEnabled(
        scene: String,
        itemID: Int,
        enabled: Bool
    ) async throws

    func setSceneItemTransform(
        scene: String,
        itemID: Int,
        transform: OBSSceneItemTransform
    ) async throws

    func startRecording() async throws
    func stopRecording() async throws -> OBSRecordingResult
}
```

---

## 5.3 StudioDirector

High-level orchestration layer.

This is the core application service.

Responsibilities:

- enforce studio state machine
- execute validated StudioPlans
- coordinate OBSKit
- coordinate asset generation
- coordinate camera animations
- start/stop recording metadata
- translate high-level StudioIntent into operations

Suggested actor:

```swift
public actor StudioDirector {
    private let obs: any OBSControlling
    private let assets: any AssetManaging
    private let ai: any AIVideoDirector
    private let recorder: RecordingMetadataRecorder

    public private(set) var state: StudioState

    public func prepareStudio(
        prompt: String
    ) async throws -> StudioPlan

    public func execute(
        plan: StudioPlan
    ) async throws

    public func switchTo(
        role: SceneRole
    ) async throws

    public func setCameraShot(
        _ shot: CameraShot
    ) async throws

    public func startRecording() async throws

    public func markRetake() async throws

    public func stopRecording() async throws -> RecordingMetadata
}
```

---

# 6. Studio State Machine

Implement early.

```swift
enum StudioState: String, Codable, Sendable {
    case disconnected
    case idle
    case preparing
    case ready
    case recording
    case paused
    case finishing
    case editing
    case failed
}
```

Valid transitions should be explicit.

Example:

```text
disconnected
   |
   v
 idle
   |
   v
preparing
   |
   v
 ready
   |
   v
recording
   |
   v
finishing
   |
   v
 ready
```

Illegal transitions must throw a typed error.

Example:

```swift
enum StudioStateError: Error {
    case invalidTransition(from: StudioState, to: StudioState)
    case operationNotAllowed(operation: String, state: StudioState)
}
```

---

# 7. Milestone 1 — Bootstrap the Swift Project

## Goal

Create a buildable Swift project with the initial module boundaries.

## Tasks

1. Create Package.swift.
2. Create StudioCore target.
3. Create OBSKit target.
4. Create StudioDirector target.
5. Create AIKit target.
6. Create RecordingKit target.
7. Create initial test targets.
8. Ensure `swift test` succeeds.
9. Add .gitignore suitable for Swift/Xcode/macOS.
10. Add a minimal architecture document.

## Acceptance Criteria

```bash
swift build
swift test
```

both succeed on a clean checkout.

No OBS connection is required yet.

## Definition of Done

- package builds
- tests run
- no unused third-party dependencies
- basic domain types compile
- architecture boundaries documented

---

# 8. Milestone 2 — OBS WebSocket Transport

## Goal

Connect reliably to OBS using Swift.

OBS WebSocket should be implemented directly using:

```swift
URLSessionWebSocketTask
```

Avoid third-party WebSocket libraries unless the Foundation implementation proves insufficient.

## Required Features

- connect
- receive Hello
- negotiate Identify
- authenticate
- receive Identified
- send request
- correlate response to request ID
- decode events
- disconnect
- connection status
- timeout handling
- typed errors

## Suggested Internal Types

```swift
OBSWebSocketClient
OBSOpCode
OBSHello
OBSIdentify
OBSIdentified
OBSRequest
OBSRequestResponse
OBSEvent
OBSAuthentication
```

## Request Correlation

Maintain pending continuations keyed by request ID.

Concept:

```swift
private var pendingRequests:
    [String: CheckedContinuation<OBSResponse, Error>]
```

Generate request IDs using UUID.

When a response arrives:

1. extract requestId
2. find continuation
3. validate requestStatus
4. resume continuation
5. remove from dictionary

Use an actor to prevent concurrency bugs.

---

# 9. OBS Authentication

Implement OBS WebSocket v5 authentication correctly.

Do not store OBS passwords in source control.

Store secrets using Keychain.

Create:

```swift
struct OBSConnectionConfiguration: Codable {
    let host: String
    let port: Int
    let useTLS: Bool
}
```

Password should be retrieved separately from secure storage.

Add:

```swift
protocol SecretStore {
    func value(for key: String) throws -> String?
    func set(_ value: String, for key: String) throws
    func removeValue(for key: String) throws
}
```

Provide Keychain implementation in the app target.

---

# 10. OBS Integration Tests

Do not make the unit-test suite require OBS.

Create two test layers.

## Unit Tests

Use prerecorded WebSocket JSON fixtures.

Fixtures should cover:

- Hello without auth
- Hello with auth
- successful Identify
- request success
- request failure
- malformed JSON
- unknown opcode
- event decoding

## Optional Integration Tests

Only run when:

```text
AI_DIRECTOR_OBS_TESTS=1
```

is present.

Integration test should:

1. connect
2. get version
3. get scene list
4. disconnect

Do not mutate the user's OBS scene collection during the first integration test.

---

# 11. Milestone 3 — Typed OBS Operations

Build typed wrappers for the operations AI Director actually needs.

Priority order:

## Tier 1

- GetVersion
- GetSceneList
- GetCurrentProgramScene
- SetCurrentProgramScene
- GetRecordStatus
- StartRecord
- StopRecord

## Tier 2

- CreateScene
- RemoveScene
- GetSceneItemList
- SetSceneItemEnabled
- GetSceneItemTransform
- SetSceneItemTransform

## Tier 3

- CreateInput
- RemoveInput
- SetInputSettings
- GetInputSettings

## Tier 4

- transitions
- filters
- media-source playback
- virtual camera
- screenshots

Each operation gets typed request and response structs.

Do not expose raw JSON dictionaries in public APIs.

---

# 12. Milestone 4 — Scene Model

Define the scene plan independently of OBS transport.

Example:

```swift
enum SceneRole: String, Codable, Sendable {
    case intro
    case presenter
    case presenterWithTitle
    case codeDemo
    case codeWithPresenter
    case terminal
    case closeUp
    case outro
}

struct ScenePlan: Codable, Sendable, Equatable {
    let id: UUID
    let name: String
    let role: SceneRole
    let sources: [SourcePlan]
}
```

Source types:

```swift
enum SourceKind: Codable, Sendable, Equatable {
    case camera(deviceID: String?)
    case display(displayID: String?)
    case window(bundleIdentifier: String?)
    case image(assetID: UUID)
    case video(assetID: UUID)
    case text(String)
}
```

Avoid storing OBS-specific numeric item IDs in StudioPlan.

Those IDs belong in runtime state.

---

# 13. Scene Provisioning

Implement:

```swift
actor OBSSceneProvisioner
```

Responsibilities:

- compare StudioPlan to existing OBS scenes
- create missing scenes
- create missing inputs
- update existing sources when safe
- preserve unknown user-owned scenes
- map logical source IDs to OBS scene item IDs

Do not delete arbitrary existing OBS scenes.

Only modify resources tagged or named as AI Director-owned.

Suggested prefix:

```text
AID -
```

Example:

```text
AID - Presenter
AID - Code Demo
AID - Terminal
```

---

# 14. Milestone 5 — Camera Director

Implement a high-level camera abstraction.

## CameraShot

```swift
enum CameraShot: String, Codable, Sendable {
    case wide
    case medium
    case closeUp
    case left
    case center
    case right
    case pictureInPicture
}
```

## CameraTransform

```swift
struct CameraTransform: Codable, Sendable, Equatable {
    var positionX: Double
    var positionY: Double

    var scaleX: Double
    var scaleY: Double

    var cropLeft: Int
    var cropRight: Int
    var cropTop: Int
    var cropBottom: Int

    var rotation: Double
}
```

## Camera Presets

Store presets by canvas size.

Initial target:

```text
1920 x 1080
```

Support 4K source feeding a 1080p canvas.

---

# 15. Smooth Pan and Zoom

Do not jump directly between transforms.

Implement interpolation.

Create:

```swift
actor CameraAnimator
```

API:

```swift
func animate(
    scene: String,
    itemID: Int,
    from: CameraTransform,
    to: CameraTransform,
    duration: Duration,
    easing: EasingCurve
) async throws
```

Initial easing:

```swift
enum EasingCurve {
    case linear
    case easeInOut
}
```

Update rate:

```text
30 updates / second
```

Do not start with 60 updates/second.

Use cancellation so a new camera command can replace an animation already in progress.

---

# 16. Camera Safety Rules

Prevent AI from producing unusable framing.

Implement validation such as:

- scale cannot go below minimum
- scale cannot exceed maximum
- crop cannot exceed source dimensions
- source must remain partially visible
- position must stay inside configurable bounds

Example:

```swift
struct CameraConstraints {
    let minimumScale: Double
    let maximumScale: Double
    let maximumCropPercentage: Double
}
```

Default suggestions:

```text
minimum scale: 0.25
maximum scale: 2.5
maximum crop: 60%
```

These defaults should be configurable.

---

# 17. Milestone 6 — Recording Metadata

Implement metadata collection before adding AI.

## RecordingMetadata

```swift
struct RecordingMetadata: Codable, Sendable {
    let sessionID: UUID
    let projectID: UUID

    let startedAt: Date
    var endedAt: Date?

    var recordingFile: URL?

    var events: [RecordingEvent]
}
```

## RecordingEvent

```swift
enum RecordingEventKind: Codable, Sendable {
    case sceneChanged(scene: String)
    case cameraShotChanged(CameraShot)
    case marker(label: String)
    case retakeStarted
    case retakeEnded
    case chapter(title: String)
}
```

Every event needs:

```swift
struct RecordingEvent: Codable, Sendable {
    let id: UUID
    let elapsedMilliseconds: Int64
    let timestamp: Date
    let kind: RecordingEventKind
}
```

---

# 18. Retake Workflow

Initial behavior:

User presses:

```text
Mark Retake
```

or invokes voice command later.

Version 1 behavior:

- create a single marker at current timestamp
- allow user to manually define previous segment start later

Version 2 behavior:

- track "last clean checkpoint"
- retake marker automatically refers to the previous checkpoint

Version 3 behavior:

- AI interprets transcript and determines likely replacement range

Do not attempt automatic speech-based range selection in the MVP.

---

# 19. Session File Format

At recording stop, create:

```text
<ProjectName>/
    recording.mov
    recording-metadata.json
    studio-plan.json
    studio-design.json
```

Use stable pretty-printed JSON.

Example:

```json
{
  "sessionID": "...",
  "startedAt": "...",
  "events": [
    {
      "elapsedMilliseconds": 0,
      "kind": {
        "sceneChanged": {
          "scene": "AID - Intro"
        }
      }
    }
  ]
}
```

Schema stability matters because future AI/edit tools depend on these files.

---

# 20. Milestone 7 — AI Provider Abstraction

Create a provider-neutral interface.

```swift
public protocol AIVideoDirector: Sendable {
    func createStudioPlan(
        request: StudioPlanningRequest
    ) async throws -> StudioPlan

    func createStudioDesign(
        request: StudioDesignRequest
    ) async throws -> StudioDesign

    func createEditPlan(
        request: EditPlanningRequest
    ) async throws -> EditPlan
}
```

Do not expose vendor-specific message types outside AIKit.

---

# 21. AI Provider Order

Implementation order:

1. Claude
2. OpenAI / ChatGPT API
3. Grok

Only implement the second provider after the first works end-to-end.

All providers must produce the same domain models.

---

# 22. Structured Output

Never parse free-form prose to build OBS scenes.

The model must return structured JSON.

Use a schema equivalent to StudioPlan.

Required validation:

- scene names unique
- supported scene roles only
- supported source types only
- valid colors
- valid asset references
- transform ranges valid
- no arbitrary file paths
- no shell commands
- no URLs unless expected

If validation fails:

1. reject response
2. optionally ask provider to repair JSON
3. never partially execute an invalid plan

---

# 23. AI Prompt Design

System prompt should explain:

- role: studio creative director
- output must conform to schema
- do not issue OS commands
- do not invent unsupported OBS capabilities
- prefer reusable scene roles
- leave readable presenter space
- optimize code-demo scenes for legibility
- avoid visually busy backgrounds
- return design tokens rather than isolated arbitrary colors

Keep provider prompts versioned.

Suggested:

```text
Sources/AIKit/Prompts/
    studio-plan-v1.md
    studio-design-v1.md
    edit-plan-v1.md
```

---

# 24. API Keys

Never commit API keys.

Use macOS Keychain.

Define:

```swift
enum AIProviderKind: String, Codable {
    case claude
    case openAI
    case grok
}
```

Configuration stores provider name/model preferences.

Secrets live only in Keychain.

---

# 25. Milestone 8 — SwiftUI App

Create the first useful application interface.

## Main Window

Suggested layout:

```text
+----------------------------------------------------+
| AI Director                              OBS: Live |
+--------------------+-------------------------------+
| Scenes             | Preview / Studio Status       |
|                    |                               |
| Presenter          |                               |
| Code Demo          |                               |
| Terminal           |                               |
| Close Up           |                               |
| Outro              |                               |
+--------------------+-------------------------------+
| AI Prompt                                          |
| [ Prepare a studio for a Swift tutorial...       ] |
|                                  [Generate Studio] |
+----------------------------------------------------+
| Camera                                             |
| [Wide] [Medium] [Close] [PIP]                     |
+----------------------------------------------------+
| Recording                                          |
| [Record] [Mark Retake] [Stop]                     |
+----------------------------------------------------+
```

---

# 26. SwiftUI State

Use Observation rather than legacy ObservableObject where supported.

Example:

```swift
@Observable
@MainActor
final class StudioViewModel {
    var connectionStatus: ConnectionStatus
    var studioState: StudioState
    var scenes: [SceneSummary]
    var currentScene: String?
    var recordingDuration: Duration?
}
```

Networking and OBS operations remain inside actors.

View model only coordinates UI.

---

# 27. Milestone 9 — Asset Management

Implement a project-level asset directory.

```text
~/Movies/AI Director/
    Projects/
        <project-id>/
            Assets/
            Recordings/
            Metadata/
            Resolve/
```

Allow root folder to be changed in Settings.

Do not hard-code a developer filesystem path.

---

# 28. AssetDescriptor

```swift
enum AssetKind: String, Codable {
    case obsBackground
    case webexBackground
    case overlay
    case logo
    case lowerThird
    case intro
    case outro
    case thumbnail
}

struct AssetDescriptor: Codable, Sendable {
    let id: UUID
    let kind: AssetKind
    let fileName: String
    let mediaType: String
    let width: Int?
    let height: Int?
}
```

Store relative paths in project JSON where possible.

---

# 29. Milestone 10 — Color and Palette System

Use Core Image/Core Graphics.

Goals:

- extract representative background colors
- calculate contrast
- choose readable text
- create stable design tokens

Domain model:

```swift
struct ColorPalette: Codable, Sendable, Equatable {
    var background: RGBColor
    var surface: RGBColor
    var primary: RGBColor
    var secondary: RGBColor
    var accent: RGBColor
    var text: RGBColor
}
```

---

# 30. Contrast Rules

Implement WCAG-inspired contrast validation.

For text overlays:

- prefer >= 4.5:1 normal text
- prefer >= 3:1 large text
- automatically choose light/dark text when possible

Do not rely solely on AI to decide text color.

Color matching should be computationally validated.

---

# 31. Palette Extraction Strategy

Version 1:

- downsample image
- cluster colors
- discard extremely dark/bright outliers as needed
- identify dominant colors
- calculate candidate accent
- compute readable text

Keep palette algorithm deterministic and testable.

Do not use AI for basic pixel-color extraction.

---

# 32. Background Generation Interface

Do not bind the domain to a particular image-generation vendor.

Define:

```swift
protocol BackgroundGenerating: Sendable {
    func generate(
        request: BackgroundGenerationRequest
    ) async throws -> GeneratedBackground
}
```

The AI Director can provide the creative prompt.

A separate image-generation service generates pixels.

This keeps Claude/Grok/OpenAI reasoning independent from image provider selection.

---

# 33. Background Design Rules

Generated backgrounds should support real presenters.

Prompt constraints should include:

- 16:9
- 1920x1080 or 3840x2160
- no fake text
- no logos unless explicitly supplied
- negative space around presenter region
- avoid high-detail pattern behind face
- maintain readable contrast
- avoid strong edges crossing presenter's face
- leave screen-demo region clear when requested

---

# 34. Webex Output

Initial Webex integration is asset generation only.

Output:

```text
Assets/Webex/
    <design>-1920x1080.png
```

Do not automate Webex UI in the MVP.

Animated backgrounds can be investigated later.

---

# 35. Milestone 11 — Fusion Template Library

Create templates manually in DaVinci Resolve Fusion and store source/template files in repository where licensing permits.

Initial templates:

1. PresenterLowerThird
2. TopicLowerThird
3. ChapterTitle
4. CodeCallout
5. ImportantPoint
6. URLCallout
7. Intro
8. Outro

Each should expose parameters that can later be driven programmatically or manually.

---

# 36. Fusion Parameter Naming

Use stable names.

Example:

```text
AID_Title
AID_Subtitle
AID_PrimaryColor
AID_AccentColor
AID_TextColor
AID_LogoPath
AID_Duration
```

Do not depend on anonymous node names generated by Fusion.

---

# 37. Transparency Requirements

All overlay templates must support alpha.

Design overlays so they work over:

- camera footage
- code demos
- screen recordings
- full-screen background footage

The title system must not require a baked solid background unless the specific template intentionally provides one.

---

# 38. Milestone 12 — Resolve Free Integration Research Spike

Before writing a large ResolveKit implementation, perform a bounded research spike against the exact installed free Resolve version.

Document findings in:

```text
Docs/RESOLVE_INTEGRATION.md
```

Test:

- which local scripts run in Free
- which Python/Lua APIs are exposed
- Fusion scripting availability
- timeline manipulation limitations
- rendering/export access
- whether local console scripts differ from remote API capabilities
- whether alpha-output workflows are available for target formats

Do not assume Studio documentation applies to Free.

---

# 39. Resolve Integration Strategy

Order of preference:

## Level 1

Generate reusable Fusion templates and project metadata.

## Level 2

Generate deterministic edit plans.

## Level 3

Use supported local scripting available in Free.

## Level 4

Generate files/import formats that Resolve can consume.

## Level 5

Manual apply step in Resolve.

The project remains useful even if editing cannot initially be 100% automated.

---

# 40. EditPlan Model

```swift
struct EditPlan: Codable, Sendable {
    let recordingFile: String
    let actions: [EditAction]
}

enum EditAction: Codable, Sendable {
    case cut(startMs: Int64, endMs: Int64, reason: String)
    case addTitle(timeMs: Int64, template: String, title: String, subtitle: String?)
    case chapter(timeMs: Int64, title: String)
    case normalizeAudio
}
```

Keep the model vendor-neutral.

ResolveKit translates it into whatever mechanism is supported.

---

# 41. Milestone 13 — Transcript Pipeline

Transcription should be a separate capability.

Define:

```swift
protocol Transcribing: Sendable {
    func transcribe(
        mediaURL: URL
    ) async throws -> Transcript
}
```

Transcript:

```swift
struct TranscriptSegment: Codable, Sendable {
    let startMs: Int64
    let endMs: Int64
    let text: String
}
```

The edit planner receives transcript + recording metadata.

---

# 42. Edit Planning

AI edit planning should use:

- transcript
- scene-change metadata
- retake markers
- chapter markers
- known studio intent

AI should not blindly rewrite all timing.

Rules:

- preserve user's intentionally marked sections
- remove only explicit or high-confidence retakes by default
- proposed low-confidence cuts should be reviewable
- never overwrite source recording

---

# 43. Milestone 14 — Vision Presenter Tracking

Do this after deterministic camera presets are stable.

Use Vision.

Pipeline:

```text
Camera frame
     |
     v
Vision request
     |
     v
face/person bounding box
     |
     v
tracking filter
     |
     v
desired framing
     |
     v
CameraAnimator
     |
     v
OBS transform
```

---

# 44. Presenter Tracking Smoothing

Implement:

- dead zone
- exponential smoothing
- maximum velocity
- minimum movement interval
- zoom hysteresis

Do not send an OBS transform update for every Vision frame.

Target a calm professional movement.

---

# 45. Milestone 15 — Voice Command Layer

Voice is optional and comes after the core app works.

Initial command vocabulary:

```text
"Presenter"
"Demo mode"
"Terminal"
"Close up"
"Wide shot"
"Mark retake"
"Start recording"
"Stop recording"
```

Voice commands map to typed StudioIntent.

No direct voice-to-OBS commands.

---

# 46. StudioIntent

Create a single command model.

```swift
enum StudioIntent: Sendable {
    case switchScene(SceneRole)
    case cameraShot(CameraShot)
    case startRecording
    case stopRecording
    case markRetake
    case addChapter(String)
}
```

Inputs from:

- AI
- SwiftUI
- keyboard
- Stream Deck
- voice
- iPhone/iPad

all eventually produce StudioIntent.

This is a critical architectural boundary.

---

# 47. Milestone 16 — External Control Surfaces

After the SwiftUI app is stable, add:

- keyboard shortcuts
- Stream Deck integration
- local HTTP or WebSocket control API
- optional iPhone/iPad remote

All must route through StudioDirector.

Avoid duplicating studio logic in control-surface code.

---

# 48. Error Handling

Create domain-specific errors.

Examples:

```swift
OBSConnectionError
OBSRequestError
StudioStateError
PlanValidationError
AIProviderError
AssetError
RecordingError
ResolveIntegrationError
```

User-facing UI errors should be concise.

Detailed diagnostics should go into logs.

---

# 49. Logging

Use Apple's unified logging.

```swift
import OSLog
```

Suggested categories:

```text
studio
obs.transport
obs.requests
camera
recording
ai
assets
resolve
```

Never log:

- API keys
- OBS passwords
- private authentication tokens

---

# 50. Configuration

Create a Settings model.

```swift
struct AppSettings: Codable {
    var obsHost: String
    var obsPort: Int

    var defaultAIProvider: AIProviderKind

    var projectRoot: URL

    var defaultCanvasWidth: Int
    var defaultCanvasHeight: Int

    var cameraAnimationDurationMs: Int
}
```

Non-secret settings can use AppStorage/UserDefaults.

Secrets use Keychain.

---

# 51. Testing Strategy

Testing is required.

Do not build all functionality first and add tests later.

## StudioCore

Test:

- Codable round trips
- validation
- color math
- state transitions

## OBSKit

Test:

- message encoding
- response decoding
- request correlation
- event handling
- errors

## CameraDirector

Test:

- interpolation
- bounds
- easing
- cancellation

## AIKit

Test:

- schema decoding
- validation
- provider error mapping

Mock network responses.

Do not spend API tokens in unit tests.

## RecordingKit

Test:

- timestamps
- event ordering
- JSON serialization
- retake markers

---

# 52. CI

Add GitHub Actions after Milestone 1.

Workflow should run:

```bash
swift build
swift test
```

on macOS.

Do not add deployment/signing initially.

---

# 53. Code Quality Rules

Claude or any development agent must follow these rules.

- Prefer small focused types.
- Prefer protocols at external boundaries.
- Prefer actors for mutable concurrent state.
- Avoid global singletons.
- Avoid force unwrap.
- Avoid force try.
- Use typed errors.
- Public APIs should have documentation comments.
- Keep network DTOs separate from domain models.
- Avoid unnecessary dependencies.
- Run tests after each meaningful change.
- Do not rewrite functioning architecture without an explicit reason.

---

# 54. Git Workflow

Preferred:

```text
main
  |
  +-- feature/obs-websocket
  +-- feature/camera-director
  +-- feature/recording-metadata
  +-- feature/claude-provider
```

Each significant feature should have its own branch.

Commit messages should describe outcomes.

Examples:

```text
Add OBS WebSocket handshake and authentication
Add typed OBS scene requests
Add smooth camera transform animator
Add recording metadata event model
```

Avoid vague commits such as:

```text
updates
changes
fix stuff
```

---

# 55. Claude Development Instructions

When Claude Code takes over this repository, it should use this process.

## Before Coding

1. Read README.md.
2. Read IMPLEMENTATION_PLAN.md completely.
3. Inspect the existing repository tree.
4. Run existing tests.
5. Identify the current milestone.
6. Do not skip ahead unless blocked.

## During Coding

For each milestone:

1. create or update domain types
2. create tests
3. implement smallest working behavior
4. run tests
5. refactor
6. run tests again
7. update documentation if public behavior changed

## Before Committing

Claude should report:

```text
Implemented:
- ...

Tests:
- ...

Known limitations:
- ...

Next recommended step:
- ...
```

Do not claim functionality was tested unless it actually ran.

---

# 56. Claude Must Not

Claude must not:

- replace Swift with Python because Python has more examples
- introduce Electron
- introduce a server unless a real requirement demands it
- expose AI keys in source
- control OBS using keyboard/mouse automation
- issue arbitrary shell commands from model output
- allow AI to directly mutate live studio state without validation
- delete existing user scenes
- require Resolve Studio for the MVP
- silently change public JSON schemas
- make large unrelated refactors while implementing a milestone

---

# 57. Milestone Delivery Checklist

Each milestone must have:

- implementation
- unit tests
- error handling
- minimal documentation
- no compiler warnings introduced
- no committed secrets
- clean `swift test`

A milestone is not complete because code exists.

It is complete when its acceptance criteria pass.

---

# 58. Priority Roadmap

Build in this order.

## Phase 1 — Live Studio Foundation

### M1
Swift package bootstrap

### M2
OBS WebSocket transport

### M3
Typed OBS operations

### M4
Scene model and provisioning

### M5
Camera Director

### M6
Recording metadata

This phase delivers the first useful non-AI studio controller.

---

## Phase 2 — AI Studio Creation

### M7
AI provider abstraction

### M8
Claude provider

### M9
SwiftUI studio interface

### M10
Asset management

### M11
Color/palette system

### M12
Background-generation abstraction

This phase delivers:

```text
prompt -> StudioPlan -> OBS studio
```

---

## Phase 3 — Resolve and Graphics

### M13
Fusion template library

### M14
Resolve Free capability research

### M15
ResolveKit boundary

### M16
EditPlan model

### M17
Transcript pipeline

### M18
AI edit planner

This phase delivers an AI-assisted post-production workflow.

---

## Phase 4 — Intelligent Camera Direction

### M19
Vision presenter tracking

### M20
tracking smoothing

### M21
semantic shot selection

### M22
automatic scene transitions

This phase starts moving toward an autonomous director.

---

## Phase 5 — Control Surfaces

### M23
voice commands

### M24
keyboard shortcuts

### M25
Stream Deck

### M26
iPhone/iPad remote

---

# 59. MVP Definition

The MVP is reached when all of the following work.

1. User launches AI Director.
2. App connects to OBS.
3. App lists OBS scenes.
4. User enters a studio description.
5. Claude returns a validated StudioPlan.
6. AI Director creates owned OBS scenes.
7. AI Director loads a background asset.
8. User can select:
   - presenter
   - code demo
   - terminal
9. User can select:
   - wide
   - medium
   - close-up
   - picture-in-picture
10. Camera changes animate smoothly.
11. App can start and stop OBS recording.
12. App records scene/camera timestamps.
13. User can create a retake marker.
14. Session metadata is saved to JSON.
15. Project can be built and tested from a clean checkout.

Resolve automation is not required to declare the live-production MVP successful.

---

# 60. Version 1.0 Definition

Version 1.0 adds:

- generated studio backgrounds
- automatic palette extraction
- OBS + Webex visual assets
- reusable Fusion templates
- transcript ingestion
- AI-generated edit plans
- documented Resolve Free workflow
- basic Resolve integration where supported
- project/session browser
- persistent studio templates

---

# 61. Future Capabilities

Possible later work:

- automatically inspect source code and choose useful demo crops
- detect when terminal output changes
- semantic scene switching from live transcription
- automatically show code when presenter says "look at this code"
- automatically return to presenter after demo
- generate social-media clips
- generate thumbnails
- produce vertical 9:16 versions
- caption generation
- automatic chapter creation
- presenter eye-line framing
- multiple cameras
- multicam recording
- hardware PTZ support
- Resolve Studio optional integration
- MCP server exposing StudioDirector tools
- local-model support

These are not MVP requirements.

---

# 62. First Claude Assignment

The first development assignment should be exactly:

```text
Implement Milestone 1 and the non-network portion of Milestone 2.

Requirements:

1. Create the Swift package/module structure described in IMPLEMENTATION_PLAN.md.
2. Implement initial StudioCore models:
   - StudioState
   - SceneRole
   - CameraShot
   - RGBColor
   - ColorPalette
3. Create OBSKit.
4. Implement OBS WebSocket message DTOs for:
   - Hello
   - Identify
   - Identified
   - Request
   - RequestResponse
   - Event
5. Implement OBSWebSocketClient actor using URLSessionWebSocketTask.
6. Do not implement AI yet.
7. Do not implement SwiftUI yet.
8. Add unit tests using JSON fixtures.
9. Ensure swift build and swift test pass.
10. Update documentation describing what was completed.

Stop after that milestone and report:
- files created
- tests executed
- known limitations
- next recommended milestone
```

That assignment intentionally keeps the first PR small enough to review carefully.

---

# 63. Decision Log

Current architectural decisions:

| Decision | Choice |
|---|---|
| Primary language | Swift |
| UI | SwiftUI |
| Async model | Swift Concurrency |
| Live studio | OBS Studio |
| OBS automation | obs-websocket |
| Post-production | DaVinci Resolve Free |
| Motion graphics | Fusion |
| AI architecture | provider-neutral |
| First AI provider | Claude |
| AI output | structured JSON |
| AI execution authority | Swift |
| Presenter tracking | Apple Vision |
| Image analysis | Core Image/Core Graphics |
| Secrets | macOS Keychain |
| Primary platform | macOS |
| MVP dependency on Resolve Studio | No |

Update this table only when an architectural decision intentionally changes.

---

# 64. Final Engineering Goal

The project is successful when the user can concentrate on teaching rather than operating production software.

The final system should make this possible:

```text
"Prepare the studio."
"Start recording."
"Demo mode."
"Focus on me."
"Mark that as a retake."
"Back to code."
"Stop recording."
```

while AI Director handles the underlying scene switching, framing, recording metadata, visual design, and post-production preparation.

The application should feel like a **software-defined technical-video studio with an AI director**, not an AI chatbot bolted onto OBS.
