// Authored trusted test-only input. Never used as production fallback.
import {provenance as topics, page} from './fedwiki-mech-topics-reference.mjs'
export function largeSitemaps() {
  return {kind:'Generated trusted 1500-entry test fixture; not observed production data',
    clock:topics.clock, sites:[page.site,'thompson.fed.wiki','thompson.patterns.ustawi.wiki'].map((domain,site) => ({domain,
      sitemap:Array.from({length:500},(_,i) => ({slug:`fixture-${site}-${i}`,title:`Fixture ${site} ${i}`,
        date:i < 8 ? topics.clock - (i+1)*3600000 : 1,
        links:i%2===0 ? {[`fixture-${site}-${i+1}`]:'trusted-fixture-item'} : {}}))}))}
}
