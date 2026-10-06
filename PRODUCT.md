# Wayfinder
<!-- impeccable:product-schema 1 -->

## Platform
Native macOS (the skill's mobile/web enum does not describe this product).

## Stack
Swift, SwiftUI and AppKit; Finder Sync extension. Chosen as a routine implementation detail for the explicitly requested native Mac utility. No third-party runtime.

## Users and purpose
A Finder user wants Command X-style file cut/paste, cd to-style terminal opening, and context-menu copying of the actual filesystem path.

## Confirmed behavior
Default terminal is Apple Terminal. User currently uses Ghostty and requires terminal selection in settings. File cut is ⌘X followed by ⌘V. Opening a terminal keeps the current Finder location.

## Constraints and assumptions
Local-first, no network dependency. User explicitly enables Accessibility and the Finder extension in macOS. Working name Wayfinder; no visual brand provided. Native Chinese settings is an implementation assumption. Actual path means absolute path with symbolic links resolved. Finder virtual collections have no single directory and report an actionable error.
