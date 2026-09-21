# Package research policy: docs before sources

When you need information about a third-party package (anything under
`~/.pub-cache` or another dependency cache), consult documentation
FIRST. Treat reading package sources as a last resort.

Order of preference:

1. MCP doc servers, when available for the ecosystem:
   - `dart` MCP: `pub_dev_search`, `read_package_uris` (README /
     `example/` via `package:` and `package-root:` URIs),
     `rip_grep_packages`.
   - `serverpod` MCP: `ask-docs`, `get-guide`, `list-guides`.
   - `jaspr` MCP: `list_doc_files`, `read_doc_page`.
   (tool names may be prefixed with the server name, e.g. `dart_pub_dev_search`.)
2. The package's README, CHANGELOG, and `example/` directory.
3. Official docs / API reference on pub.dev or the project website.

Only if docs do not answer the question: read sources under
`~/.pub-cache`, surgically — search for the specific symbol or
signature (e.g. with `rg`), do not browse whole files or dump large
source chunks into your output. Cite package + symbol + version.

Rationale: docs match the resolved version and stay current; cached
sources may not, and doc tools are cheaper and more targeted.
