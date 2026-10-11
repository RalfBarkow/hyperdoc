import fs from 'node:fs'
import vm from 'node:vm'
import crypto from 'node:crypto'
import assert from 'node:assert/strict'
const root = new URL('./fixtures/mech-popup/', import.meta.url)
export const provenance = JSON.parse(fs.readFileSync(new URL('provenance.json', root)))
export const popupSource = fs.readFileSync(new URL('ward-popup.js', root), 'utf8')
export const clientSource = fs.readFileSync(new URL('wiki-dialog.cjs', root), 'utf8')
const hash = value => crypto.createHash('sha256').update(value).digest('hex')
assert.equal(hash(popupSource), provenance.popup.excerptSha256)
assert.equal(hash(clientSource), provenance.dialog.sha256)
export const popupInsertion = '\n// Original POPUP intake: Ward a028b4bba04e539dcaa090423d38a00a0050489d.\n' + popupSource
assert.equal(hash(popupInsertion), provenance.popup.insertionSha256)
export function originalPopup(stuff, dialog) {
  const popup = vm.runInNewContext(popupSource + '\npopup_emit', {wiki:{dialog}, JSON})
  popup(stuff)
}
export function originalDialog(mockWindow) {
  const context = {window:mockWindow,module:{exports:{}}}
  vm.runInNewContext(clientSource,context)
  return context.module.exports.open
}
