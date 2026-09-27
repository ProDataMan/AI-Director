# AI Director

AI Director is a Swift-first studio automation project for using AI to orchestrate live production in OBS, generate visual assets for OBS and Webex, and streamline post-production in DaVinci Resolve.

The goal is an end-to-end workflow where Claude, ChatGPT, or another model provides high-level creative and production intent, while Swift performs deterministic control of the studio.


## Current Implementation Status

Development has started on `feature/initial-swift-foundation`.

Implemented in the first code slice:

- Swift Package Manager project targeting macOS 14+
- `StudioCore`, `OBSKit`, `StudioDirector`, `AIKit`, and `RecordingKit` targets
- Initial domain models: `StudioState`, `SceneRole`, `CameraShot`, `RGBColor`, and `ColorPalette`
- Typed OBS WebSocket v5 envelopes for Hello, Identify, Identified, Request, RequestResponse, and Event
- Actor-based `OBSWebSocketClient` transport skeleton using `URLSessionWebSocketTask`
- Unit tests for domain-model serialization and OBS protocol encoding/decoding
- GitHub Actions workflow running `swift build` and `swift test` on macOS
- `Docs/ARCHITECTURE.md` describing the implemented architecture and immediate next work

Local validation was performed with Swift 6.2.1. The current test suite passes 7 tests.

Not implemented yet:

- OBS Hello/Identify handshake orchestration
- OBS authentication challenge hashing
- request/response correlation
- typed OBS operations such as GetVersion and GetSceneList
- live OBS integration tests
- SwiftUI
- AI provider integration
- Resolve integration

The next implementation target is completing the OBS WebSocket v5 handshake and request-correlation layer.

## Vision

A typical workflow should eventually look like this:

```text
"Prepare my studio for a Swift concurrency tutorial."
                     |
                     v
             AI Studio Director
                     |
        +------------+------------+
        |            |            |
        v            v            v
      Design      Resolve        OBS
        |            |            |
        |         Graphics      Scenes
        |         Assets        Camera
        |            |          Audio
        +------------+------------+
                     |
                     v
                   READY
                     |
              "Start recording"
                     |
                     v
               AI-directed OBS
                     |
               "Stop recording"
                     |
                     v
            DaVinci Resolve Free
                     |
              Edit / Titles /
             Audio / Final Render
```

## Core Design Principle

AI produces intent. Swift executes it.

Claude, ChatGPT, or another model should not directly manipulate OBS or the operating system. Instead, the model returns a structured plan such as:

```swift
struct StudioPlan: Codable {
    let title: String
    let palette: ColorPalette
    let scenes: [OBSScenePlan]
    let graphics: [GraphicAsset]
}
```

The Swift application validates the plan and performs the requested operations.

This makes the system easier to test, safer during live recording, and much more deterministic.

## Target Architecture

```text
                         Claude / ChatGPT / Grok
                                  |
                              API calls
                                  |
                                  v
                     +-------------------------+
                     |   AI STUDIO DIRECTOR    |
                     |                         |
                     |      Swift / SwiftUI    |
                     +------------+------------+
                                  |
                 +----------------+----------------+
                 |                |                |
                 v                v                v
          AI Generation       OBS Control       Asset System
                                  |
                             WebSocket API
                                  |
                 +----------------+----------------+
                 |                |                |
                 v                v                v
              Scenes          Pan / Zoom       Recording
              Sources         Camera Crop      Start / Stop
              Graphics        Transitions      Markers
                 |
                 +------------------+
                                    v
                              Recording Files
                                    |
                                    v
                         DaVinci Resolve Free
                                    |
                           Fusion Templates
                                    |
                       +------------+------------+
                       |            |            |
                       v            v            v
                     Edit        Titles /       Final
                  Recording      Lower Thirds   Render
```

## Technology Choices

### Primary Language

Swift should be used for nearly all application logic.

Primary technologies:

- Swift
- SwiftUI
- Swift Concurrency
- URLSessionWebSocketTask
- Core Image
- Core Graphics
- Vision
- Codable
- OBS WebSocket
- DaVinci Resolve / Fusion

Python or Lua should only be introduced where DaVinci Resolve or Fusion requires it.

## Free DaVinci Resolve Strategy

The project is initially designed around the free version of DaVinci Resolve.

Free Resolve is still useful for:

- Editing recordings
- Fusion compositions
- Custom animated titles
- Lower thirds
- Transparent overlays
- Compositing
- Motion graphics
- Color correction
- Audio finishing
- Rendering final videos

The architecture should not depend on Studio-only AI features or Studio-only remote scripting APIs.

Instead:

1. Swift controls OBS and the studio.
2. AI generates plans, prompts, edit decisions, titles, and metadata.
3. Fusion provides reusable visual templates.
4. Resolve performs post-production.
5. We test how much local scripting is practical in the free edition before depending on it.

A future Studio upgrade may unlock deeper Resolve automation, but it should not be required for the first working system.

## OBS Automation

OBS should be controlled directly from Swift using OBS WebSocket.

The application should eventually support:

- Connect and authenticate with OBS
- Enumerate scenes
- Create scenes
- Delete scenes
- Add sources
- Add camera sources
- Add display capture
- Add window capture
- Add image and video backgrounds
- Show and hide sources
- Position sources
- Scale sources
- Crop sources
- Change scene item transforms
- Switch scenes
- Trigger transitions
- Start recording
- Stop recording
- Start virtual camera
- Maintain recording metadata

### Example Swift API

```swift
actor OBSController {
    func createScene(named name: String) async throws
    func switchScene(to name: String) async throws

    func addCamera(to scene: String) async throws
    func addDisplayCapture(to scene: String) async throws
    func addBackground(to scene: String, asset: URL) async throws

    func setTransform(
        scene: String,
        source: String,
        transform: SceneTransform
    ) async throws

    func startRecording() async throws
    func stopRecording() async throws
}
```

## AI-Generated Studio Backgrounds

The AI system should be able to produce visual direction for:

- OBS backgrounds
- Webex backgrounds
- Title cards
- Intro graphics
- Outro graphics
- Lower thirds
- Corner accents
- Code callouts
- Thumbnails
- Overlay elements

A prompt might be:

> Create a sophisticated 16:9 virtual studio background for a Swift concurrency tutorial. Use a dark graphite environment, subtle blue and orange illumination, an uncluttered presenter area on the right, and space for demo content on the left.

Generated assets could be organized as:

```text
Assets/
  SwiftActors/
    background-4k.png
    background-webex.png
    background-obs.png
    title-background.png
    overlay.png
    corner-accent.png
    palette.json
```

## Shared Color System

The studio should not allow each generated asset to use unrelated visual styling.

A single design system should drive OBS, Resolve, Webex, titles, overlays, and thumbnails.

Example:

```swift
struct StudioDesign: Codable {
    var theme: String

    var backgroundColor: RGBColor
    var surfaceColor: RGBColor
    var primaryColor: RGBColor
    var secondaryColor: RGBColor
    var accentColor: RGBColor
    var textColor: RGBColor

    var titleFont: String
    var bodyFont: String
}
```

Core Image can analyze AI-generated backgrounds and derive a palette such as:

```text
Background   #101318
Surface      #1A2028
Primary      #4A90E2
Accent       #FF8A34
Text         #F5F7FA
```

That palette should be reused everywhere.

## Fusion Templates

DaVinci Resolve Fusion should provide reusable, parameterized graphics rather than having AI generate flattened title images every time.

Initial templates:

```text
Fusion Templates/
  PresenterLowerThird
  TopicLowerThird
  ChapterTitle
  CodeCallout
  ImportantPoint
  URLCallout
  SocialMedia
  Intro
  Outro
```

Each template should expose useful parameters such as:

```text
Title
Subtitle
PrimaryColor
AccentColor
TextColor
Logo
PositionX
PositionY
Scale
AnimationDuration
```

This allows the same animation to be reused across Swift, Ansible, C#, DevOps, Jira, and other course topics while preserving consistent branding.

## Transparency

Fusion graphics should use alpha transparency for compositing over camera and screen recordings.

Example lower third:

```text
+------------------------------------+
|                                    |
|                                    |
|                                    |
|  +----------------------+          |
|  | ANTOINE VICTOR       |          |
|  | Technical Trainer    |          |
|  +----------------------+          |
|                                    |
+------------------------------------+

Everything outside the title is transparent.
```

## Camera Director

Digital camera movement should be performed in OBS using scene-item transforms.

A 4K camera can be framed inside a 1080p OBS canvas to allow software pan and zoom without physically moving the camera.

### Shot Model

```swift
enum CameraShot {
    case wide
    case medium
    case closeUp

    case left
    case center
    case right

    case pictureInPicture
}
```

### Camera Director

```swift
actor CameraDirector {
    func focusOnPresenter() async throws
    func wideShot() async throws
    func mediumShot() async throws
    func closeUp() async throws
    func pictureInPicture() async throws
    func focusOnScreen() async throws

    func animate(
        from: CameraTransform,
        to: CameraTransform,
        duration: Duration
    ) async throws
}
```

Transforms should animate smoothly rather than jump instantly.

For example:

```text
0.00 sec   scale 1.00
0.10 sec   scale 1.05
0.20 sec   scale 1.10
0.40 sec   scale 1.20
0.60 sec   scale 1.30
0.80 sec   scale 1.40
```

## Presenter Tracking

A later version can use Apple's Vision framework for person or face detection.

```text
Camera Feed
    |
    v
Apple Vision
    |
    v
Face / Person Bounding Box
    |
    v
CameraDirector
    |
    v
OBS Transform
```

The system should use smoothing and dead zones so the framing does not twitch with every small head movement.

Potential future framing rules:

- Keep presenter centered
- Preserve headroom
- Preserve look room
- Avoid excessive zoom
- Limit movement speed
- Ignore minor motion

## Scene Generation

Given a prompt such as:

> I'm recording a tutorial about Swift protocols using VS Code. Create my studio.

AI may produce:

```text
Scene 1  INTRO
Scene 2  PRESENTER
Scene 3  PRESENTER + TITLE
Scene 4  CODE DEMO
Scene 5  CODE + CAMERA
Scene 6  TERMINAL
Scene 7  PRESENTER CLOSEUP
Scene 8  OUTRO
```

Swift then creates and configures those scenes through OBS WebSocket.

## Webex Backgrounds

The same design system should generate Webex-compatible backgrounds.

Example:

```text
Webex/
  SwiftActors.png
  SwiftActors-animated.mp4
```

The goal is for the Webex background, OBS studio, and final Resolve video to look like one unified production.

## Recording Metadata

One of the most useful features is to record studio state alongside the OBS recording.

Every scene switch and production event should be timestamped.

Example:

```text
00:00:00 INTRO
00:00:11 PRESENTER
00:02:31 CODE DEMO
00:05:42 PRESENTER
00:07:13 TERMINAL
00:09:44 RETAKE START
00:10:12 RETAKE END
00:14:11 CHAPTER "Protocol Extensions"
```

This metadata reduces the amount of post-production inference required later.

## Marking Retakes While Recording

The presenter should be able to say or trigger:

> Redo that.

The Swift application records a marker such as:

```json
{
  "type": "retake",
  "start": "00:13:17.200",
  "end": "00:13:42.600"
}
```

This becomes input for the final edit plan.

The goal is to capture editing intent during recording instead of forcing AI to rediscover every mistake afterward.

## AI Edit Plan

AI should analyze:

- Recording transcript
- Studio metadata
- Retake markers
- Scene changes
- Chapters
- Speaker intent

and generate a deterministic edit plan.

Example:

```json
{
  "cuts": [
    {
      "start": "00:02:14.200",
      "end": "00:02:18.700",
      "reason": "false start"
    }
  ],
  "titles": [
    {
      "time": "00:04:11",
      "template": "ChapterTitle",
      "title": "Swift Actors"
    }
  ]
}
```

DaVinci Resolve remains the final editing environment.

## AI Providers

AI providers should be interchangeable.

```swift
protocol AIVideoDirector: Sendable {
    func planStudio(
        prompt: String
    ) async throws -> StudioPlan

    func designScene(
        prompt: String
    ) async throws -> SceneDesign

    func createEditPlan(
        transcript: String,
        metadata: RecordingMetadata
    ) async throws -> EditPlan
}
```

Potential providers:

- Claude
- ChatGPT / OpenAI
- Grok
- Local models

Provider-specific code should live behind the protocol.

## Studio State Machine

The live studio should enforce safe states.

```swift
enum StudioState {
    case idle
    case preparing
    case ready
    case live
    case recording
    case paused
    case finishing
    case editing
    case rendering
}
```

For example, destructive scene changes may be blocked while recording.

This keeps AI suggestions from accidentally destabilizing a live production.

## Control Surfaces

The StudioDirector should eventually accept commands from multiple interfaces:

```text
AI
Keyboard
Stream Deck
iPhone / iPad
Voice
SwiftUI Control Panel
```

All interfaces call the same Swift StudioDirector API.

That means:

- A Stream Deck button
- A spoken command
- A SwiftUI button
- An AI intent

can all trigger the exact same studio action.

## Proposed Repository Structure

```text
AI-Director/
|
+-- Apps/
|   +-- AIStudioMac/
|
+-- Packages/
|   +-- StudioCore/
|   +-- StudioDirector/
|   +-- OBSKit/
|   +-- ResolveKit/
|   +-- AIKit/
|   |   +-- Claude/
|   |   +-- OpenAI/
|   |   +-- Grok/
|   +-- GraphicsKit/
|   +-- VisionKit/
|   +-- VoiceDirector/
|   +-- AssetKit/
|
+-- Resolve/
|   +-- Fusion/
|   +-- Scripts/
|   +-- Templates/
|
+-- Assets/
|
+-- Tests/
|
+-- README.md
```

## Development Roadmap

### Milestone 1 - Swift OBSKit

Build reliable OBS control from Swift.

Deliverables:

- Connect to OBS WebSocket
- Authenticate
- Query OBS version
- Enumerate scenes
- Enumerate sources
- Create scenes
- Switch scenes
- Add image sources
- Add camera sources
- Add display capture
- Manipulate transforms
- Start recording
- Stop recording

### Milestone 2 - Camera Director

Build high-level camera controls.

Deliverables:

- Wide shot
- Medium shot
- Close-up
- Picture-in-picture
- Left/right framing
- Animated pan
- Animated zoom
- Animated crop
- Easing
- Safety bounds

### Milestone 3 - AI Studio Designer

Add model integration.

Deliverables:

- AIVideoDirector protocol
- Claude provider
- OpenAI provider
- Optional Grok provider
- StudioPlan schema
- ScenePlan schema
- StudioDesign schema
- Prompt templates
- Structured JSON output

### Milestone 4 - Asset and Color System

Deliverables:

- Background generation workflow
- Core Image palette extraction
- Brand palette JSON
- OBS background variants
- Webex background variants
- Overlay assets
- Shared design tokens

### Milestone 5 - Resolve / Fusion Templates

Deliverables:

- Lower third
- Chapter title
- Code callout
- Intro
- Outro
- Transparent overlay templates
- Exposed template parameters
- Color injection workflow

### Milestone 6 - Recording Metadata

Deliverables:

- Timestamp every scene change
- Store recording events
- Add chapter markers
- Add retake markers
- Save RecordingMetadata JSON
- Link metadata to recording file

### Milestone 7 - AI Edit Planner

Deliverables:

- Transcript ingestion
- Retake detection
- Cut planning
- Chapter planning
- Title placement
- EditPlan JSON
- Resolve-oriented output

### Milestone 8 - Vision Camera Tracking

Deliverables:

- Face detection
- Person detection
- Bounding box tracking
- Framing rules
- Smooth follow behavior
- Dead-zone logic
- Max pan / zoom limits

### Milestone 9 - Autonomous Studio Director

Potential future capabilities:

- Live transcription
- Semantic scene switching
- AI-directed shot selection
- Automatic code/demo transitions
- Voice commands
- Stream Deck integration
- iPhone/iPad control
- Automatic post-production handoff

## Example User Experience

The long-term goal:

```text
User:
"Prepare my studio for a Swift actors tutorial."

AI:
Creates StudioPlan and StudioDesign.

Swift:
Creates OBS scenes.
Loads generated background.
Positions camera.
Loads lower-third assets.
Prepares code demo scene.

User:
"Start recording."

Swift:
Starts OBS recording and metadata capture.

User:
"Demo mode."

Swift:
Moves camera to picture-in-picture.
Shows VS Code.
Hides presenter title.

User:
"Focus on me."

Swift:
Smoothly transitions camera to medium presenter shot.

User:
"Redo that."

Swift:
Creates a retake marker.

User:
"Back to code."

Swift:
Restores code scene.

User:
"Stop recording."

Swift:
Stops recording.
Writes metadata.
Creates inputs for the AI edit planner.
```

## Initial Success Criteria

Version 0.1 should be considered successful when a user can:

1. Launch the Swift macOS application.
2. Connect to OBS.
3. Enter a prompt describing a training video.
4. Receive a structured studio plan from an AI provider.
5. Automatically create the required OBS scenes.
6. Load a generated background.
7. Switch between presenter and demo modes.
8. Smoothly reposition and scale the camera.
9. Start and stop recording.
10. Save scene-change and retake metadata.

DaVinci Resolve integration should follow after the live studio workflow is reliable.

## Guiding Principle

The project should avoid unnecessary automation through screen scraping or simulated keyboard/mouse input.

Prefer:

- Public APIs
- OBS WebSocket
- Swift concurrency
- Structured AI outputs
- Reusable Fusion templates
- Deterministic state transitions
- Explicit project metadata

over fragile UI automation.

The intent is to create a reusable, extensible AI production platform rather than a collection of one-off scripts.
