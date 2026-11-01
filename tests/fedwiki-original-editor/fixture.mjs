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
