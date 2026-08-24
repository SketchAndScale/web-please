# Web Please

**Skip AI Overviews. Keep the web.**

Web Please makes ordinary Google searches open in Google’s Web-results mode. That means no AI Overview panel, no delayed cleanup, and no page selectors to break when Google redesigns Search.

It is a tiny desktop Chrome extension with one switch. Images, News, Shopping, and other search modes still work when you intentionally choose them.

## Why Web mode?

Google’s own Web filter is the supported way to show text-based links without AI Overviews. Web Please makes that choice automatic for ordinary searches.

Web mode intentionally omits some Google rich-result features, including knowledge panels, currency cards, sports cards and some featured answers. This is a deliberate tradeoff for a predictable Web-only search page.

## Privacy

Web Please collects no search data, has no account, makes no network requests of its own and contains no analytics. Chrome applies a local URL rule to supported Google Search requests.

## Development

The repository root is a loadable Manifest V3 extension. No build step, package manager, remote script, or external service is required.

## Release package

The project root is the source of truth for extension code. Run `./tools/package-release.ps1` to create the Chrome Web Store upload package. The script reads the version from `manifest.json`, validates the archive, removes temporary staging files, and writes the only canonical release ZIP to `dist/web-please-v<version>.zip`.

## Non-affiliation

Web Please is independent and is not affiliated with or endorsed by Google.

<p>
  <a href="https://ko-fi.com/shay_kawatra" target="_blank">
    <img height="36" style="border:0px;height:36px;" src="https://storage.ko-fi.com/cdn/kofi6.png?v=6" border="0" alt="Buy Me a Coffee at ko-fi.com" />
  </a>
</p>
