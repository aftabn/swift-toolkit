# voidleaf's fork of readium/swift-toolkit

`macos-support` is upstream `3.8.0` plus macOS support and two bug fixes. It
exists because [voidleaf](https://github.com/aftabn/voidleaf) is an EPUB reader
for iOS *and* macOS, and upstream declares itself iOS-only — not because the code
is deeply iOS-bound, but because a handful of files import UIKit for types that
AppKit also has.

Everything lives on the branch:

    git log --oneline 3.8.0..macos-support

That is the complete inventory of the delta, and deliberately the only one — there
is no patch list to keep in sync, and no commit count written down here to go
stale.

## The two kinds of patch

They are different in kind, and the distinction matters at rebase time.

**macOS support** is `#if`-guarded and leaves iOS behaviour
unchanged. Two of them do restructure code that iOS compiles — the PDF helpers
drop a now-wrong `UIKit.` module qualifier, and the user-agent builder hoists
two values into locals — but both produce the identical result. Nothing else on
this branch is reachable from an iOS build.

**Upstream bug fixes** (both in `MinizipContainer.swift`) are
deliberately *not* guarded, and they *do* change iOS behaviour. That is the
point: the bug is upstream's, it is present on iOS too, and gating the fix to
macOS would preserve the defect on the platform where it does the most damage.
The first is a real crash — a corrupt chapter kills the process. The second
clamps two unvalidated size conversions in the same read path; no fixture
reaches those, so treat it as hardening on attacker-controlled input rather than
a demonstrated fix. Both are marked `VOIDLEAF PATCH` in the source, because
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

   The `--target` is not a shortcut. Only `ReadiumShared` and `ReadiumStreamer`
   are ported: `Sources/Navigator` and `Sources/LCP` still import UIKit and
   WebKit unguarded, so a bare `swift build` at the root fails on macOS and
   always has. The `platforms:` declaration claims macOS 14 package-wide because
   SwiftPM has no way to say otherwise per target — depending on the
   `ReadiumNavigator` or `ReadiumLCP` product from a macOS target will resolve
   cleanly and then fail to compile.

4. **Tag it** `<new-upstream-version>-voidleaf.<n>` and update the pin in
   voidleaf's `Packages/BookKit/Package.swift`.

### If `AudioSession.swift` or `UIImage.swift` conflicts

These two files are gated whole, with a SwiftFormat `--ifdef no-indent` option
directive above the `#if`. Without it SwiftFormat indents the entire file body,
which turns a two-line patch into a several-hundred-line one and guarantees a
conflict on every future upstream edit. The narrow option is deliberate: it
suppresses ifdef-body indentation while leaving the `indent` rule enforcing the
code itself, so a real indentation defect arriving in a later rebase is still
caught. If you hit a conflict here, take upstream's version wholesale and
re-apply the wrapper — it is only the header comment, the `#if`, and a trailing
`#endif`.

## Consuming it

voidleaf pins an exact tag rather than tracking the branch:

    .package(url: "https://github.com/aftabn/swift-toolkit.git", exact: "3.8.0-voidleaf.1")

`exact:` is not merely tidy here, it is the only safe form. This fork inherited
upstream's tags, and `3.8.0-voidleaf.1` is a SemVer *prerelease*, which sorts
below plain `3.8.0` and is therefore excluded from every version range. Measured,
not argued — `from: "3.8.0"` against this repository resolves to:

    3.11.0

which is pure upstream: no macOS support, and none of the Minizip fix. It still
compiles, and it still passes every iOS test, so nothing announces the loss. No
range expression can express "voidleaf tags only" either; even
`.upToNextMinor(from: "3.8.0-voidleaf.1")` admits plain `3.8.0`. voidleaf checks
this mechanically in `scripts/check-readium-pin.sh`.

Note also that this fork carries upstream's own `feature-macos-support` branch,
which is *not* this work and is several years stale. The branch you want is
`macos-support`.

## Upstreaming

The Minizip crash fix is worth sending upstream on its own — it is a genuine bug
in their code, independent of macOS, and it is a self-contained commit for
exactly that reason. The macOS support commits are a plausible contribution too;
Readium has had standing community interest in macOS. Run `make format` and drop
the `VOIDLEAF PATCH` markers before opening anything.
