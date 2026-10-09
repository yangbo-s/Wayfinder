# Wayfinder
<!-- impeccable:product-schema 1 -->

## Platform
Native macOS (the skill's mobile/web enum does not describe this product).

## Stack
Swift, SwiftUI and AppKit; Finder Sync extension. Chosen as a routine implementation detail for the explicitly requested native Mac utility. Sparkle 2.10.0 is the only third-party runtime, used for the user-requested updater.

## Users and purpose
A Finder user wants Command X-style file cut/paste, cd to-style terminal opening, and context-menu copying of the actual filesystem path.

## Confirmed behavior
Default terminal is Apple Terminal. User currently uses Ghostty and requires terminal selection in settings. File cut is ⌘X followed by ⌘V. Opening a terminal keeps the current Finder location.

## Constraints and assumptions
Local-first Finder features; optional update checks connect to GitHub, with no file/path upload or system-profile reporting. User explicitly enables Accessibility and the Finder extension in macOS. Working name Wayfinder; no visual brand provided. Native Chinese settings is an implementation assumption. Actual path means absolute path with symbolic links resolved. Finder virtual collections have no single directory and report an actionable error.

## Folder actions and toolbar (beta.3–beta.4)
The user explicitly chose a real Finder toolbar menu for terminal, path copying and folder creation. Context menus always offer an empty folder regardless of selection, plus single-item and multi-item grouping. All menu actions use small native icons; terminal wording is 在当前目录下打开终端. Folder creation immediately creates `untitled folder` with a numbered suffix on collision, then selects it and starts native Finder inline rename. There is no naming dialog. Empty, single-item and multi-item actions share this flow. Existing files are preserved; session-local undo follows a renamed folder within the same parent by filesystem identity.

## Cut audio (beta.5)
The user chose to ship all five original procedural sound effects, including the initial 105 ms preview. Settings offers sound selection and explicit preview, with persistent selection and the existing automatic-sound toggle. Default is 轻快剪切. Muting automatic cut feedback does not prevent intentional previews; both respect macOS system UI sound settings. No Command X sound assets are distributed.

## Software updates (beta.7, build 7)
The user requested Sparkle with manual checks, automatic checking and automatic installation switches. Both automatic preferences default off; Sparkle owns persistence and scheduling. Automatic installation downloads in the background and installs at quit, with prompts when required. Builds and feeds require Ed25519 validation. User requested code and local verification first, then authorized publishing beta.7 source and packages. Publishing does not replace the installed /Applications app. Users on beta.6 or earlier need one manual upgrade. An explicit ad-hoc build option is available without a paid certificate, with app-scoped Library Validation disabled and other hardened runtime protections retained. Developer ID builds do not carry that exception.
