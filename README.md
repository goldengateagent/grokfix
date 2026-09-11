# Grok Build patches

## Fixes

- issue with protoc on Windows prevents Windows builds. lib.rs fixes it.
- issue with api backend responses from providers sending non-standard 'ping' keep alive breaks connection. client.rs patches this allowing Grok Build to connect to OpenCode Meta Spark Muse model and other 'responses' models.

## Build Grok Build from source with the patches

### GitHub clone grok-build repo

```sh
git clone https://github.com/xai-org/grok-build.git
```

### Apply patch files

Do not copy `lib.rs` or `client.rs` over the grok-build checkout. Diff them
against grok-build and apply the patch so git can merge.

Target files in the grok-build checkout (same relative paths as this repo):

- `crates/build/xai-proto-build/src/lib.rs`
- `crates/codegen/xai-grok-sampler/src/client.rs`

```sh
diff -u grok-build/crates/build/xai-proto-build/src/lib.rs \
        grokfix/crates/build/xai-proto-build/src/lib.rs \
        > lib.rs.patch
diff -u grok-build/crates/codegen/xai-grok-sampler/src/client.rs \
        grokfix/crates/codegen/xai-grok-sampler/src/client.rs \
        > client.rs.patch

cd grok-build
git apply --3way ../lib.rs.patch ../client.rs.patch
```

`--3way` merges the hunks. Conflicts get marked in the files if the patch does not apply cleanly.

### Subsequent updates

After the patches are already applied in your grok-build checkout, pull new
upstream commits without copying files over the tree. Stash local patch
changes, pull, then pop the stash so git merges the patches onto the update:

```sh
cd grok-build
git stash
git pull
git stash pop
```

If `git stash pop` reports conflicts, resolve the marked hunks in:

- `crates/build/xai-proto-build/src/lib.rs`
- `crates/codegen/xai-grok-sampler/src/client.rs`

Keep the Windows protoc early return and the `ping` skip as described below.
Then `git add` the resolved files. Drop the leftover stash with `git stash drop`
only if pop left it in place after conflicts.

#### 1. `lib.rs` — Windows protoc fix

Port the `#[cfg(windows)]` early return at the top of
`emit_rerun_if_changed` (the block that loops over `protos` / `includes`,
emits `cargo:rerun-if-changed=` for each, and returns `Ok(())` before the
`--dependency_out=/dev/stdout` / `--descriptor_set_out=/dev/null` path).
That Unix-only invocation uses `/dev/stdout` and `/dev/null`, which do not
exist on Windows, so Windows builds must take the early-return path instead.

Leave everything else in the grok-build `lib.rs` as is.

#### 2. `client.rs` — skip non-standard `ping` keep-alive events

Port three related pieces as one unit:

1. `deserialize_response_event`: change the signature to return
  `Result<Option<rs::ResponseStreamEvent>>` and add the `ping` guard — when
   the payload parses as JSON with `"type": "ping"` (e.g.
   `{"type":"ping","cost":"0"}` from providers such as OpenCode Meta Spark
   Muse), return `Ok(None)` instead of a serialization error. Keep the
   existing unknown-tool stripping and terminal `total_tokens` override logic.
2. The stream call site (where `deserialize_response_event(data)` is matched):
  map `Ok(Some(event))` to an event, `Ok(None)` to a dropped item
   (`Some(None)` before the `filter_map`, so the `ping` heartbeat is skipped
   without ending the stream), and `Err(e)` to a stream error.
3. The `deserialize_response_event_skips_unknown_event_types_like_ping` test,
  which asserts `ping` yields `Ok(None)` while a malformed known event still
   errors.

Leave all other client logic (headers, auth, endpoints, defaults) as is.

### MacOS

```sh
brew install rust
cargo install dotslash
cd grok-build
cargo build -p xai-grok-pager-bin --release
mkdir -p ~/.grokfix/bin
cp target/release/xai-grok-pager ~/.grokfix/bin/grokfix
echo 'export PATH="$HOME/.grokfix/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
grokfix
```

### Windows

- install rust from [https://rust-lang.org/tools/install/](https://rust-lang.org/tools/install/)

```powershell
winget install protobuf
cd grok-build
cargo build -p xai-grok-pager-bin --release
$bin = Join-Path $env:USERPROFILE ".grokfix\bin"
New-Item -ItemType Directory -Force -Path $bin | Out-Null
Copy-Item target\release\xai-grok-pager.exe (Join-Path $bin "grokfix.exe")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$bin*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$bin", "User")
}
$env:Path = "$bin;$env:Path"
grokfix.exe
```

That writes `%USERPROFILE%\.grokfix\bin` into your **User** PATH (new terminals pick it up). You can also add it in Settings → System → About → Advanced system settings → Environment Variables → User variables → Path.
