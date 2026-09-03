# voidleaf's fork of readium/swift-toolkit

`macos-support` is upstream `3.8.0` plus eight commits. It exists because
[voidleaf](https://github.com/aftabn/voidleaf) is an EPUB reader for iOS *and*
macOS, and upstream declares itself iOS-only — not because the code is deeply
iOS-bound, but because a handful of files import UIKit for types that AppKit
also has.

Everything lives on the branch. `git log --oneline 3.8.0..macos-support` is the
complete inventory of the delta; there is no separate patch list to keep in sync.

## The two kinds of patch

They are different in kind, and the distinction matters at rebase time.

**macOS support** (6 commits) is `#if`-guarded and leaves iOS behaviour
unchanged. Two of them do restructure code that iOS compiles — the PDF helpers
drop a now-wrong `UIKit.` module qualifier, and the user-agent builder hoists
two values into locals — but both produce the identical result. Nothing else on
this branch is reachable from an iOS build.

**Upstream bug fixes** (2 commits, both in `MinizipContainer.swift`) are
deliberately *not* guarded, and they *do* change iOS behaviour. That is the
point: the bug is upstream's, it is present on iOS too, and gating the fix to
macOS would preserve the defect on the platform where it does the most damage.
The first is a real crash — a corrupt chapter kills the process — and the second
is hardening around it. Both are marked `VOIDLEAF PATCH` in the source, because
an unguarded change to shared code is the kind a reader could otherwise mistake
for upstream's own.

## Rebasing onto a new upstream release

    git fetch upstream --tags
    git rebase --onto <new-tag> 3.8.0 macos-support

Then, in order:

1. **Re-run the formatter.** `make format` — upstream's SwiftFormat config is
   authoritative, and `make lint-format` is what CI checks.
2. **Check whether the bug fixes are still needed.** If upstream has fixed the
   Minizip conversions themselves, drop those commits rather than carrying a
   conflicting duplicate. `git log <new-tag> -- Sources/Shared/Toolkit/ZIP/`
   is the fast way to look.
3. **Build both platforms.** Neither is optional; the whole branch exists to
   keep them in step:

       swift build --target ReadiumStreamer
       xcodebuild -scheme ReadiumStreamer -destination 'generic/platform=iOS' build

4. **Tag it** `<new-upstream-version>-voidleaf.<n>` and update the pin in
   voidleaf's `Packages/BookKit/Package.swift`.

### If `AudioSession.swift` or `UIImage.swift` conflicts

These two files are gated whole, with `// swiftformat:disable indent` above the
`#if`. Without that directive SwiftFormat indents the entire file body, which
turns a two-line patch into a several-hundred-line one and guarantees a conflict
on every future upstream edit. If you hit a conflict here, take upstream's
version wholesale and re-apply the wrapper — it is only the header comment, the
`#if os(iOS)`, and a trailing `#endif`.

## Consuming it

voidleaf pins an exact tag rather than tracking the branch, so a push here can
never silently change a build:

    .package(url: "https://github.com/aftabn/swift-toolkit.git", exact: "3.8.0-voidleaf.1")

## Upstreaming

The Minizip crash fix is worth sending upstream on its own — it is a genuine bug
in their code, independent of macOS, and it is a self-contained commit for
exactly that reason. The macOS support commits are a plausible contribution too;
Readium has had standing community interest in macOS. Run `make format` and drop
the `VOIDLEAF PATCH` markers before opening anything.
