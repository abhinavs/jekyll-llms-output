# Changelog

## 0.1.0 - 2026-05-05

- Initial release.
- Generates `/llms.txt` from `_data/llms.yml` (curated) or auto from collections.
- Generates `/llms-full.txt` by concatenating source bodies (Liquid rendered).
- Per-document opt-out for `llms-full.txt` via `llms_output: false` in frontmatter.
