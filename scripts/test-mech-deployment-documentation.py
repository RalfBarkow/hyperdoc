#!/usr/bin/env python3
"""Check authored operator examples without executing any deployment command."""
from html.parser import HTMLParser
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
class Examples(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.blocks = {}
        self.current = None
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'pre' and attrs.get('data-shell') == 'bash':
            self.current = attrs['id']
            assert self.current not in self.blocks
            self.blocks[self.current] = ''
    def handle_endtag(self, tag):
        if tag == 'pre':
            self.current = None
    def handle_data(self, data):
        if self.current:
            self.blocks[self.current] += data

parser = Examples()
parser.feed((ROOT / 'dreyeck/pages/work/dreyeck.ch deployment.html').read_text())
assert set(parser.blocks) == {'asset-prepare', 'asset-http', 'asset-switch',
                              'asset-rollback', 'catalog-historical',
                              'catalog-selected', 'catalog-rollback'}
for name, shell in parser.blocks.items():
    subprocess.run(['bash', '-n'], input=shell, text=True, check=True)
    print(f'PASS Bash syntax: {name}')
# Guard the ordering/scope of the operating contract, not production execution.
prepare = parser.blocks['asset-prepare']
assert 'nix eval --raw --impure' in prepare and 'source.rev == rev' in prepare
assert prepare.index('diff -qr') < prepare.index('mv -T')
assert 'mv -Tf' not in prepare
assert 'find "$version_dir" -type f' in parser.blocks['asset-http']
assert 'cmp "$version_dir/$resource"' in parser.blocks['asset-http']
assert 'application/javascript' in parser.blocks['asset-http']
assert '/dialog/' in parser.blocks['asset-http'] and '/plugins/solo/dialog/' in parser.blocks['asset-http']
assert 'mv -Tf' in parser.blocks['asset-switch']
assert 'previous-link' in parser.blocks['asset-rollback']
catalog = parser.blocks['catalog-selected']
assert catalog.index('nixos-rebuild build') < catalog.index('nixos-rebuild switch')
assert catalog.count('test "$(locked_hyperdoc_rev)" = "$CATALOG_REV"') == 2
assert 'previous-system' in catalog and 'previous-revision' in catalog
print('PASS two independent update/rollback contracts; no server commands executed')
