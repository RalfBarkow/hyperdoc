// ClaimLinkSurveyProbe.js
//
// ES module for Site Survey Factory.
// Loaded by:
//   update.html?probe=ClaimLinkSurveyProbe
//
// Contract (per update.html):
//   const {version, probe, format, summary} = await import(`${probes}/${module}.js`)
//
// - version : any string/number
// - probe   : function(page, info) -> per-page record
//             index.update(site, survey, probe) collects results into `survey`
// - format  : function(survey) -> HTML string
// - summary : OPTIONAL function(survey) -> wiki item
//
// Notes (important):
// - The current Site Survey Factory update.html computes the *opened page title*
//   from the module name (CamelCase -> spaced). It does NOT (currently) read an
//   exported `title` from this module.
// - We still export `resultTitle` for clarity/future compatibility, but it is
//   informational unless update.html is updated to use it.

export const version = 1;

// Informational only unless update.html is changed to import/use it.
export const resultTitle = 'Claim Link Survey';

// ---------- helpers --------------------------------------------------------

function normalizeFoldName(text) {
  if (!text) return null;
  const t = String(text).trim().toLowerCase();
  if (t === 'question' || t === 'questions') return 'question';
  if (t === 'claim' || t === 'claims') return 'claim';
  if (t === 'support' || t === 'supports') return 'support';
  if (t === 'oppose' || t === 'opposes' || t === 'objection') return 'oppose';
  return null;
}

// Coarse fedwiki-style slug from [[Title]].
// Keeps ASCII words/digits and hyphens; collapses whitespace to hyphens.
function titleToSlug(title) {
  return String(title || '')
    .trim()
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-');
}

function extractBracketLinksFromText(text) {
  const links = [];
  if (typeof text !== 'string') return links;

  const re = /\[\[([^\]]+)\]\]/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    const t = (m[1] || '').trim();
    if (!t) continue;
    links.push({
      title: t,
      slug: titleToSlug(t),
      form: 'bracket'
    });
  }
  return links;
}

function extractLinksFromItem(item) {
  const links = [];
  if (!item || typeof item !== 'object') return links;

  const type = item.type;

  // Text-bearing items may include [[links]]
  if (type === 'paragraph' || type === 'markdown' || type === 'html') {
    links.push(...extractBracketLinksFromText(item.text));
  }

  // Reference items point to a page and optionally a remote site.
  if (type === 'reference') {
    const t = item.title || item.text || null;
    const slug = item.slug || (t ? titleToSlug(t) : null);
    if (slug) {
      links.push({
        title: t || slug,
        slug,
        site: item.site || null,
        form: 'reference'
      });
    }
  }

  return links;
}

function primaryRoleFromFolds(folds) {
  // Choose a primary “role” for display. This is not IBIS; it is a convenience.
  // Priority: question > claim > support > oppose.
  if (!Array.isArray(folds)) return '';
  if (folds.includes('question')) return 'question';
  if (folds.includes('claim')) return 'claim';
  if (folds.includes('support')) return 'support';
  if (folds.includes('oppose')) return 'oppose';
  return '';
}

// ---------- per-page analysis ----------------------------------------------

function analysePage(page, info) {
  const story = Array.isArray(page?.story) ? page.story : [];

  // Use sitemap info when present: it is the authoritative slug/title/date.
  const slug = info?.slug ? info.slug : titleToSlug(page?.title || '');
  const title = info?.title || page?.title || slug;
  const date = info?.date ?? page?.date ?? null;

  // Avoid surveying the survey result page itself (prevents feedback loops).
  // This guard is intentionally loose: compare by title OR slug.
  if (title === resultTitle || slug === titleToSlug(resultTitle)) {
    return { title, slug, date, folds: [], role: '', links: {}, edges: [] };
  }

  const foldOrder = [];
  const linksByFold = {}; // foldName -> [link,...]
  const edges = []; // discourse edges

  let currentFold = null;

  for (const item of story) {
    if (!item) continue;

    if (item.type === 'pagefold') {
      const foldName = normalizeFoldName(item.text || item.title || '');
      currentFold = foldName; // may be null
      if (foldName && !foldOrder.includes(foldName)) foldOrder.push(foldName);
      continue;
    }

    const links = extractLinksFromItem(item);
    if (!links.length) continue;

    const foldKey = currentFold || 'body';
    if (!linksByFold[foldKey]) linksByFold[foldKey] = [];

    for (const link of links) {
      linksByFold[foldKey].push(link);

      // Only links found *within a recognized fold* become discourse edges.
      if (currentFold) {
        edges.push({
          from: slug,
          to: link.slug,
          type: currentFold, // question | claim | support | oppose
          fold: currentFold,
          targetTitle: link.title || null,
          targetSite: link.site || null,
          form: link.form || null
        });
      }
    }
  }

  const role = primaryRoleFromFolds(foldOrder);

  return {
    title,
    slug,
    date,
    role,
    folds: foldOrder,
    links: linksByFold,
    edges
  };
}

// ---------- probe() --------------------------------------------------------
//
// Site Survey Factory calls: result = probe(page, info)
// index.update(...) then pushes `result` into the survey array.

export function probe(page, info) {
  return analysePage(page, info);
}

// ---------- summary() (optional) -------------------------------------------

export function summary(survey) {
  const totals = {
    pages: Array.isArray(survey) ? survey.length : 0,
    edges: 0,
    question: 0,
    claim: 0,
    support: 0,
    oppose: 0
  };

  for (const rec of survey || []) {
    const edges = rec?.edges || [];
    totals.edges += edges.length;
    for (const e of edges) {
      const t = e?.type;
      if (t && Object.prototype.hasOwnProperty.call(totals, t)) totals[t] += 1;
    }
  }

  const lines = [
    `### ${resultTitle}`,
    '',
    `* Pages analysed: ${totals.pages}`,
    `* Discourse edges: ${totals.edges}`,
    `  * questions: ${totals.question}`,
    `  * claims: ${totals.claim}`,
    `  * supports: ${totals.support}`,
    `  * opposes: ${totals.oppose}`
  ];

  return { type: 'markdown', text: lines.join('\n') };
}

// ---------- format() -------------------------------------------------------

export function format(survey) {
  const rows = (survey || []).filter(
    rec => Array.isArray(rec?.folds) && rec.folds.length > 0
  );

  const esc = s =>
    String(s ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');

  if (rows.length === 0) {
    return '<p>No pages with discourse folds were found.</p>';
  }

  let html = '';
  html += '<table>';
  html += '<tr><th>Page</th><th>Role</th><th>Folds</th><th>Edges</th></tr>';

  for (const rec of rows) {
    const pageTitle = rec.title || rec.slug || '';
    const role = rec.role || '';
    const folds = (rec.folds || []).join(', ');
    const edges = (rec.edges || []).length;

    // FedWiki link syntax as requested:
    const pageCell = `[[${esc(pageTitle)}]]`;

    html +=
      '<tr>' +
        `<td>${pageCell}</td>` +
        `<td>${esc(role)}</td>` +
        `<td>${esc(folds)}</td>` +
        `<td>${edges}</td>` +
      '</tr>';
  }

  html += '</table>';
  return html;
}
