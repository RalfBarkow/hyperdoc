// Shared disposable fixture for the automated witness and interactive demo.
export const slug = 'original-editor-test'
export const paragraphId = '1111111111111111'
export const codeId = '2222222222222222'
export const paragraph = {id:paragraphId, type:'paragraph', text:'An isolated paragraph; this item stays unchanged.'}
export const code = {id:codeId, type:'code', text:'(defun square (x) (* x x))', language:'lisp'}
export function initialPage() {
  return structuredClone({title:'Original Editor Test', story:[paragraph, code],
    journal:[{type:'create', id:'3333333333333333', item:{title:'Original Editor Test'}, date:1700000000000},
      {type:'add', id:paragraphId, item:paragraph, date:1700000000001},
      {type:'add', id:codeId, item:code, after:paragraphId, date:1700000000002}]})
}

// Second disposable page: the Wiki counterpart of the introductory paragraph of
// dreyeck/pages/upstream-intake/Assessing an Upstream Commit.html. The HTML file
// is only READ, once, to seed the item's first text; nothing ever writes it, and
// afterwards the item in this page is the authoritative text (see docs/fedwiki-paragraph-association.md).
export const upstreamSlug = 'assessing-an-upstream-commit'
export const upstreamParagraphId = '5555555555555555'
const decode = t => t.replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/&amp;/g,'&')
/** Plain text of the first <p> after the first <h1> of an HTML source: tags removed, entities decoded, whitespace collapsed. */
export function introductionText(html) {
  const afterHeading = html.slice(html.search(/<\/h1>/i))
  const match = afterHeading.match(/<p(?:\s[^>]*)?>([\s\S]*?)<\/p>/i)
  if (!match) throw Error('No introductory paragraph found')
  return decode(match[1].replace(/<[^>]*>/g,'')).replace(/\s+/g,' ').trim()
}
export function upstreamPage(text) {
  const item = {id:upstreamParagraphId, type:'paragraph', text}
  return structuredClone({title:'Assessing an Upstream Commit', story:[item],
    journal:[{type:'create', id:'6666666666666666', item:{title:'Assessing an Upstream Commit'}, date:1700000000000},
      {type:'add', id:upstreamParagraphId, item, date:1700000000001}]})
}
