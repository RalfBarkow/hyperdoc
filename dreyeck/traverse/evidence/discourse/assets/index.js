export const asSlug = title => title.replace(/\s/g, '-').replace(/[^A-Za-z0-9-]/g, '').toLowerCase();
export const asCopy = obj => JSON.parse(JSON.stringify(obj));

// F E T C H

// Define the `newer` function outside of `site`
export function newer(sitemap, epoch) {
  return sitemap
    .filter(info => info.date > epoch)
    .map(info => info.title);
}

export async function site(domain) {
  const sitemap = await fetch(`//${domain}/system/sitemap.json`).then(res => res.json());
  return { sitemap, info, newer: (epoch) => newer(sitemap, epoch), changed, page, pages };

  function info(title) {
    const slug = asSlug(title);
    return sitemap?.find(info => info?.slug === slug);
  }

  function changed(oldmap = []) {
    if (!Array.isArray(oldmap)) {
      console.warn("Expected oldmap to be an array; defaulting to empty array.");
      oldmap = [];
    }

    const titles = info => info?.title || info?.slug;

    const more = sitemap
      ?.filter(info => info?.slug && !oldmap.find(old => old?.slug === info.slug))
      .map(titles) || [];

    const less = oldmap
      ?.filter(old => old?.slug && !sitemap.find(info => info?.slug === old.slug))
      .map(titles) || [];

    const older = sitemap
      ?.filter(info => {
        const old = oldmap.find(old => old?.slug === info?.slug);
        return old && info?.date < old?.date;
      })
      .map(titles) || [];

    const newer = sitemap
      ?.filter(info => {
        const old = oldmap.find(old => old?.slug === info?.slug);
        return old && info?.date > old?.date;
      })
      .map(titles) || [];

    return { more, less, older, newer };
  }

  function page(title) {
    const slug = asSlug(title);
    return fetch(`//${domain}/${slug}.json`)
      .then(res => res.ok ? res.json() : null)
      .catch(error => {
        console.error(`Failed to fetch page: ${title}`, error);
        return null;
      });
  }

  function pages(titles) {
    return Promise.all(
      titles
        .map(title => page(title))
    );
  }
}

// F I N D

export function links(items) {
  const link = /\[\[(.*?)\]\]/g;
  const links = [];
  let m;
  for (const item of items) {
    if (item.type == 'paragraph') {
      const text = item.text;
      while (m = link.exec(text)) {
        links.push(m[1]);
      }
    }
  }
  return links;
}

export function locs(items) {
  const locs = [];
  for (const item of items) {
    if (item?.type == 'image' && item.location) {
      locs.push([+item.location.latitude, +item.location.longitude]);
    }
  }
  return locs;
}

export function tags(items, tag) {
  const link = new RegExp(`<${tag}.*?>`, 'gi');
  const tags = [];
  let m;
  for (const item of items) {
    if (item?.type == 'html') {
      const text = item.text;
      while (m = link.exec(text)) {
        tags.push(m[0]);
      }
    }
  }
  return tags;
}

export function folds(items) {
  const folds = items
    .map((item, index) => ({ item, index }))
    .filter(fold => fold?.item.type == 'pagefold');
  return folds.reduce((sum, each, i, a) => {
    if (each.item.text != '.') {
      const upto = (a[i + 1]?.index) || 9999;
      const span = items.slice(each.index + 1, upto);
      sum[each.item.text] = span;
    }
    return sum;
  }, {});
}

// I N D E X

export function index(site, oldindex) {
  const details = [`${site.sitemap.length} pages`];
  const changes = site.changed(oldindex);
  const altered = changes.older.length + changes.newer.length;
  if (altered) details.push(`${altered} altered`);
  const more = changes.more.length;
  if (more) details.push(`${more} more`);
  const less = changes.less.length;
  if (less) details.push(`${less} less`);
  return details.join(", ");
}

export function update(site, oldindex, finder) {
  const key = page => ({
    date: site.info(page.title)?.date || "Unknown",
    slug: asSlug(page.title),
    title: page.title,
  });

  const get = title => {
    return site.page(title).then(page => {
      if (!page) {
        console.warn(`Page not found: ${title}`);
        return null;
      }
      return Object.assign(key(page), finder(page));
    });
  };

  const old = title => oldindex.find(info => info?.title === title);

  const changes = site.changed(oldindex);

  // Remove less
  for (const title of changes.less) {
    const index = oldindex.findIndex(info => info?.title === title);
    if (index !== -1) oldindex.splice(index, 1);
  }

  // IMPORTANT: no .slice(0, 500) here → no page limit
  const result = Promise.all(
    [
      changes.more.map(title =>
        get(title).then(info => {
          if (info) oldindex.push(info);
          return info;
        })
      ),
      changes.newer.map(title =>
        get(title).then(info => {
          if (info) Object.assign(old(title), info);
          return info;
        })
      ),
      changes.older.map(title =>
        get(title).then(info => {
          if (info) Object.assign(old(title), info);
          return info;
        })
      ),
    ].flat()
  );

  return result;
}



