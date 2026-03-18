# A site value of `localhost` should not be treated as remote

The healthy part is that the server starts, serves pages, CSS/JS, and has a real `/system/sitemap.json` route. In `wiki-server`, that endpoint is explicitly defined and served from `status/sitemap.json` or generated on demand, so the core localhost service is not the failure here.

What is broken is the client’s site-resolution logic for localhost-on-a-port.

`wiki-client` treats a site as “origin” only when `site === window.location.host` or `site` is falsy. Otherwise it treats it as remote. On your browser, `window.location.host` is `localhost:3000`, but the failing neighbor/proxy site is just `localhost`, so it does **not** count as origin. That pushes the client into remote probing. 

Once that happens, `siteAdapter` probes reachability via `favicon.png`, not via `system/sitemap.json`. For a loopback-looking site it first tries `http://${site}/favicon.png`; for HTTPS pages it falls back to `/proxy/${site}/favicon.png`. When `site` is just `localhost`, that becomes exactly `http://localhost/favicon.png` or `/proxy/localhost/favicon.png`, with no `:3000`.

On the server side, `/proxy/*` takes the host segment literally and builds only two candidates: `https://${remoteHost}/${remoteResource}` and `http://${remoteHost}/${remoteResource}`. So when the client asks for `/proxy/localhost/favicon.png`, the server will try `https://localhost/favicon.png` and `http://localhost/favicon.png`, again without port 3000. That exactly matches your log.

So the first concrete bug is:

`localhost` and `localhost:3000` are being treated as different sites.

That is the main reason for the `ECONNREFUSED` proxy noise.

The second bug is the `.../view/null/system/sitemap.json` request. I did not find the exact caller from the snippets I searched, but I did find an important upstream clue: when a page is localized/forked, `pageHandler.put` explicitly does `$page.data('site', null)`. Separately, `siteAdapter.site()` treats real `null` as origin, but a literal string `"null"` would be treated as a remote site. That strongly suggests some path is serializing the null site marker into the string `"null"`, which then leaks into URL construction as `/view/null/...`. I can support the two endpoints of that chain, but I did not locate the exact stringification step in the available snippets.

What to fix in source, in order:

1. In `wiki-client/lib/siteAdapter.js`, normalize loopback same-origin comparison.
   The current check is too strict. It compares against `window.location.host`, which includes the port. A site value of `localhost` should not be treated as remote when the current page is on `localhost:3000`. Compare normalized hostnames, or canonicalize loopback origins before the equality test. The existing code path shows why the mismatch happens.

2. In `wiki-client/lib/siteAdapter.js`, stop using `favicon.png` as the reachability probe.
   Your own HyperDoc notes point to the right design correction: probe `system/sitemap.json` instead, and on HTTPS go proxy-first for remotes. That removes a whole class of false negatives and side effects from favicon probing.

3. In `wiki-client`, prevent `"null"` from ever becoming a site id.
   Somewhere after `$page.data('site', null)`, a null marker is being turned into the string `"null"`. That should be blocked at the boundary: if site is `null`, `undefined`, `''`, or `"null"`, route to origin and never build a remote URL. I can confirm the null marker is written and that only falsy values are treated as origin today.

4. In `wiki-server`, server changes are secondary.
   The proxy is doing what it was coded to do: preserve the host string it receives and try HTTPS then HTTP. The issue is that the client is handing it the wrong host string. Server-side improvements would mostly be diagnostics, not the primary fix. That matches the code and also your HyperDoc incident write-up.

The smallest high-value patch is therefore in `wiki-client`, not `wiki-server`:

* canonicalize localhost/loopback site ids so `localhost` resolves to current origin when the browser is already on `localhost:3000`
* use `system/sitemap.json` instead of `favicon.png` for reachability
* reject `"null"` as a remote site token

Your HyperDoc page “What to fix in the wiki source code” reaches the same conclusion: mostly `wiki-client`, especially `siteAdapter.js` and neighbor failure handling. 

If you want, I’ll turn this into a concrete copy-paste patch target list for `wiki-client/lib/siteAdapter.js` and the likely `"null"` guard points.
