# Later Thoughts for KOReader

**Later Thoughts** is a lightweight, book-independent notes plugin for KOReader.

The idea was to capture a thought while reading without turning note-taking into a second app or having notes lost in book specific annotations. The name rhymes with tater tots.

## Features

- Create named plain-text notes
- Quick Entry for fast timestamped thoughts
- Manage Notes: open, rename, and delete
- Notes sorted by most recently modified
- Quick inserts:
  - Timestamp
  - Date
  - Book + page
  - Timestamp + book + page
  - Divider
  - Bullet
- Tap outside the Insert menu to dismiss it
- Plain `.txt` storage
- No accounts, database, syncing, network access, tags, or background service
- Tested on Kindle with KOReader and ZenUI

## Installation

1. Download the latest release ZIP from GitHub Releases.
2. Extract it.
3. Copy the entire `later_thoughts.koplugin` folder into your KOReader `plugins` folder.
4. Fully exit and relaunch KOReader.

Your layout should look like:

```text
koreader/
└── plugins/
    └── later_thoughts.koplugin/
        ├── main.lua
        ├── _meta.lua
        └── README.md
```

On Kindle, KOReader is commonly located under `/mnt/base-us/koreader/`.

## Updating from the development builds

Exit KOReader, remove the old `quick_scratch.koplugin` folder, and install `later_thoughts.koplugin`.

Later Thoughts intentionally keeps using the same existing notes storage location used by the development builds, so your notes should remain available.

## Usage

Open **Later Thoughts** from KOReader/ZenUI.

The main screen provides:

```text
+ Quick Entry
+ New Note
⚙ Manage Notes
────────────────
Your existing notes…
```

While editing a note, use **Insert** for timestamps, dates, book/page context, dividers, and bullets.

## Philosophy

Later Thoughts intentionally stays small:

- quick to open
- quick to write
- quick to close
- ordinary text files
- minimal UI overhead

## Known limitations

- ZenUI may display its own lightning-bolt launcher icon.
- Selected-text-to-note integration is not included but possible in the future.
- Other KOReader devices may work, but Kindle + ZenUI is the combination tested so far.

## Contributing

Bug reports and focused pull requests are welcome. Please include your device, KOReader version, ZenUI version if applicable, and steps to reproduce.

## License

MIT — see [LICENSE](LICENSE).

## Disclaimer

Later Thoughts is an independent community plugin and is not an official KOReader component.

## Development note

Generative AI tools were used during the development of Later Thoughts, including assistance with coding, debugging, documentation, and iteration. The plugin was tested and refined through real-device use on Kindle with KOReader and ZenUI.
