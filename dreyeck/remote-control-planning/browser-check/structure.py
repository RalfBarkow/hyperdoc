"""Static reading contracts; object evaluation is in the separate ASDF tests."""
from pathlib import Path
from html.parser import HTMLParser
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
PAGES = ROOT / 'pages/remote-control-planning'
CSS = ROOT / 'remote-control-planning/assets/remote-control-reading/css/reading.css'
TITLES = ['Planning Remote Control for the Zettelkasten App with SHOP3',
          'Model Authority and the Control Surface',
          'How SHOP3 Reads the Architecture Task',
          'Case C - Two Alternative Plan Trees',
          'Cases D and E - When Planning Refuses', 'Evidence and Open Acceptance']

class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.links, self.stack, self.tables, self.headings = [], [], [], []
        self.wrappers = 0
        self.feed(text)
        self.close()
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'a': self.links.append(attrs)
        if tag == 'div' and attrs.get('class') == 'remote-control-reading': self.wrappers += 1
        if tag == 'h1': self.headings.append(tag)
        if tag == 'table': self.tables.append(any(t == 'div' and 'table-scroll' in a.get('class', '').split() for t, a in self.stack))
        if tag not in ('br', 'hr', 'img', 'meta', 'link', 'input', 'wbr'): self.stack.append((tag, attrs))
    def handle_endtag(self, tag):
        if not self.stack or self.stack[-1][0] != tag: raise AssertionError(f'unbalanced {tag}')
        self.stack.pop()

class ReadingStructure(unittest.TestCase):
    def test_six_pages_and_native_forward_path(self):
        self.assertEqual(sorted(p.stem for p in PAGES.glob('*.html')), sorted(TITLES))
        for i, title in enumerate(TITLES):
            page = Page((PAGES / (title + '.html')).read_text())
            self.assertFalse(page.stack)
            self.assertEqual(page.wrappers, 1)
            self.assertEqual(len(page.headings), 1)
            self.assertTrue(all(page.tables))
            targets = [a['page'] for a in page.links if 'page' in a]
            self.assertTrue(set(targets).issubset(TITLES))
            if i < 5: self.assertIn(TITLES[i+1], targets)
            if i > 0: self.assertIn(TITLES[i-1], targets)
            self.assertGreater(len([a for a in page.links if 'expr' in a]), 0)
    def test_css_is_scoped(self):
        css = re.sub(r'/\*.*?\*/', '', CSS.read_text(), flags=re.S)
        selectors = re.findall(r'([^{}]+)\{[^{}]*\}', css)
        self.assertTrue(selectors)
        for group in selectors:
            for selector in group.split(','):
                self.assertIn('.remote-control-reading', selector)
    def test_case_c_links_are_computed_components(self):
        page = Page((PAGES / (TITLES[3]+'.html')).read_text())
        exprs = [a['expr'] for a in page.links if 'expr' in a]
        for route in ('agent', 'direct'):
            for part in ('plan', 'tree', 'state'):
                self.assertIn(f'(reading-alternative :{route} :{part})', exprs)
    def test_no_new_view_overrides_content(self):
        source = (ROOT / 'work/remote-control-reading.lisp').read_text()
        self.assertNotIn('defview', source.lower())
        # This checks the existing source contract, not runtime view order.
        renderer = (ROOT.parent / 'hyperbook-explorer/rendering.lisp').read_text()
        self.assertIn(':title "Content" :priority 1', renderer)

if __name__ == '__main__': unittest.main()
