# Text Thumbnailer

Readable preview thumbnails for plain-text and Markdown files in GNOME Files
(Nautilus) and any other [freedesktop thumbnail](https://specifications.freedesktop.org/thumbnail-spec/latest/)
consumer.

GNOME ships no text thumbnailer by default, so `.md`, `.txt` and similar files
show a generic icon. This adds a tiny thumbnailer that renders the first lines
of the file into a clean preview — fast, and Unicode-correct.

<!-- Add a screenshot here, e.g.: ![screenshot](docs/screenshot.png) -->

## Features

- Preview thumbnails for Markdown and plain-text files
- **Fast** — uses ImageMagick's `pango:` (HarfBuzz) renderer: ~0.2 s even for
  non-Latin / accented text, where `caption:` takes several seconds
- Handles large files and code-heavy Markdown without failing
- Renders a short summary for `.desktop` entries (name, comment, exec)
- Single self-contained Bash script, no daemon

## Requirements

- **ImageMagick 7** built with the Pango delegate
  (check: `magick -list format | grep -i pango` → should list `PANGO`)
- `bash`, `coreutils`, `file` (all standard)
- GNOME Files / Nautilus, or any freedesktop thumbnail consumer

## Installation

```bash
sudo install -Dm755 textthumb         /usr/local/bin/textthumb
sudo install -Dm644 text.thumbnailer  /usr/share/thumbnailers/text.thumbnailer

# refresh the thumbnail cache so existing files get re-thumbnailed
rm -rf ~/.cache/thumbnails/{normal,large,x-large,xx-large,fail}
nautilus -q     # or log out and back in
```

> **Why `/usr/local/bin`?** GNOME runs thumbnailers inside a `bwrap` sandbox
> that binds `/usr` but **not** `~/.local/bin`. The script must live under
> `/usr` (e.g. `/usr/local/bin`) to be reachable. `/usr/local/bin` is on `PATH`,
> which the bare `Exec=textthumb` line relies on.

### Uninstall

```bash
sudo rm -f /usr/local/bin/textthumb /usr/share/thumbnailers/text.thumbnailer
rm -rf ~/.cache/thumbnails/{normal,large,x-large,xx-large,fail}
nautilus -q
```

## Usage

GNOME calls the thumbnailer automatically. To run it by hand:

```bash
textthumb <input> <output.png> [size_px]
```

- `input`  — the text/Markdown file
- `output` — destination PNG
- `size`   — square size in pixels (optional, default `1024`)

```bash
textthumb notes.md preview.png 512
```

## Supported file types

The thumbnailer registers these MIME types in `text.thumbnailer`:

```
text/plain;text/markdown;text/x-markdown;
```

The script itself also accepts other text-based types (`text/*`,
`application/javascript`, `application/json`, `application/xml`,
`application/x-shellscript`, `application/x-desktop`). To thumbnail more types,
add them to the `MimeType=` line in `text.thumbnailer` and reinstall.

## How it works

1. Detect the MIME type with `file`; bail out on anything non-textual.
2. Take the first 40 lines, expand tabs, strip `\r`, and escape `&`, `<`, `>`
   (Pango treats its input as markup).
3. Render with ImageMagick `pango:` at a point size scaled to the requested
   thumbnail size, wrapped to width.
4. Crop the top of the document to a square, add a small white border, flatten
   onto white, and write a **plain PNG**.

A few deliberate choices, learned the hard way:

| Choice | Reason |
| --- | --- |
| `pango:` not `caption:` | `caption:` re-measures text while fitting and is ~30× slower on non-ASCII glyphs. |
| plain PNG, not `PNG8:` | `PNG8` quantizes the grayscale+alpha text image down to one colour → a blank thumbnail. |
| `head` before `sed` | With `set -o pipefail`, `sed \| head` lets `sed` die on `SIGPIPE` for files larger than the pipe buffer, aborting the script. |
| width-only render + crop | A fixed `WxH` box shrinks long files until the text is invisible. |

## Troubleshooting

- **Blank thumbnails** — your ImageMagick likely lacks Pango, or an old build
  is cached. Verify `magick -list format | grep -i pango`, then clear the cache.
- **No thumbnails at all** — clear `~/.cache/thumbnails` (including `fail/`) and
  restart Nautilus; GNOME never retries a file marked failed until it changes.
- **Test directly** — `textthumb file.md /tmp/t.png 512 && xdg-open /tmp/t.png`.

## License

MIT — see [`LICENSE`](LICENSE).
