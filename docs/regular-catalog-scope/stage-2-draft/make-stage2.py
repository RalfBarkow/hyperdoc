#!/usr/bin/env python3
"""Build the Stage 2 (declaration) tree from the Stage 1 worktree, in a scratch directory. Reads the worktree, writes only the target."""
import os, shutil, subprocess, sys
W, T, TPL = sys.argv[1], sys.argv[2], sys.argv[3]
if os.path.exists(T): shutil.rmtree(T)
os.makedirs(T)
subprocess.check_call(['rsync','-a','--exclude=.git',W+'/',T+'/'])
os.chdir(T)
def sub(path,a,b,count=1):
    s=open(path).read()
    assert s.count(a)==count,(path,a[:70],s.count(a))
    open(path,'w').write(s.replace(a,b))
# the draft dictionary becomes the declared dictionary, with an introduction that says what it now is
old='dreyeck/pages/project/Regular Catalog WBS Dictionary.html'; new='dreyeck/pages/work/Regular HyperDoc Catalog WBS Dictionary.html'
shutil.move(old,new)
s=open(new).read()
start=s.index('<h1>'); end=s.index('<section data-wbs-entry="tm-reg-wp-1">')
intro='''<h1>Regular HyperDoc Catalog WBS Dictionary</h1>
<p>The WBS Dictionary of the Deliverable <code>tm-regular-catalog</code> (the Work item <code>topic-maps-regular-hyperdoc</code>, "Regular HyperDoc Catalog with a Navigable Project Topic Map") declared on <a page="Regular HyperDoc Catalog">Regular HyperDoc Catalog</a>, in the form of the <a page="CTM Plan Page WBS Dictionary">CTM Plan Page WBS Dictionary</a>: for each work package its scope and exclusions, acceptance criterion, authority, effect, the evidence it requires, and its controls.</p>
<p>The <em>scope</em> field ends with what the package excludes. The <em>evidence</em> field states the evidence a package <em>requires</em>; it is not an observation. What an executor observed and reports is the evidence of an assignment on <a page="Implementation Assignments" hyperbook="dreyeck/work/project">Implementation Assignments</a>; an independent review is a report of its own; and whether a package was accepted is stated only by a record on an Acceptance Records page, which does not exist for any of these packages. A control marked <code>planned</code> has no test yet; <code>external</code> runs outside this repository.</p>
<p>This scope is distinct from <code>tmd-deployment</code>, the separate staging Catalog, and from <code>project-work-ctm-exchange</code>, the exchangeable project CTM. Neither is redefined here and none of their deliverables is repeated: the staging package is context for package 5, not part of it.</p>

'''
open(new,'w').write(s[:start]+intro+s[end:])
shutil.copy(TPL+'/Regular HyperDoc Catalog.html','dreyeck/pages/work/Regular HyperDoc Catalog.html')
shutil.copy(TPL+'/project-scope.stage2.lisp','dreyeck/tests/project-scope.lisp')
# the Work item on the Work Breakdown
sub('dreyeck/pages/work/Work Breakdown.html','<h2>Conversation coordinates</h2>','''<h2>Regular HyperDoc Catalog</h2>
<ul><li><a page="Regular HyperDoc Catalog" data-topic="topic-maps-regular-hyperdoc" data-kind="work item" data-status="open">Regular HyperDoc Catalog with a Navigable Project Topic Map</a> — open: the regular HyperDoc Catalog, built on a reviewed Topic Maps revision, in which the project's work is itself a Topic Map that a reader can navigate and inspect. Its WBS, WBS Dictionary and plan are on the linked page; nothing is accepted and no deployment is authorized.</li>
<li data-from="dogfooding" data-to="topic-maps-regular-hyperdoc" data-relation="current-work">HyperDoc dogfooding → Regular HyperDoc Catalog with a Navigable Project Topic Map: current-work.</li></ul>

<h2>Conversation coordinates</h2>''')
# registration: the HyperBook pages and the source registry of the project CTM
sub('dreyeck.asd','''                             (:static-file "Project Work Exchange WBS Dictionary.html") (:static-file "Acceptance Records.html")
                             (:static-file "Regular Catalog WBS Dictionary.html"))))''','''                             (:static-file "Project Work Exchange WBS Dictionary.html") (:static-file "Acceptance Records.html"))))''')
sub('dreyeck.asd','''                      (:static-file "CTM Plan Page WBS Dictionary.html")
''','''                      (:static-file "CTM Plan Page WBS Dictionary.html")
                      (:static-file "Regular HyperDoc Catalog.html")
                      (:static-file "Regular HyperDoc Catalog WBS Dictionary.html")
''')
sub('dreyeck/work/project/project-ctm.lisp','''    (:dictionary "dreyeck/work/reading" "CTM Plan Page WBS Dictionary" :dictionary)
''','''    (:dictionary "dreyeck/work/reading" "CTM Plan Page WBS Dictionary" :dictionary)
    (:scope-plan "dreyeck/work/reading" "Regular HyperDoc Catalog" :work)
    (:scope-dictionary "dreyeck/work/reading" "Regular HyperDoc Catalog WBS Dictionary" :dictionary)
''')
# the one test assumption that there is a single declared dictionary
sub('dreyeck/tests/project-ctm.lisp',"""      (check "correspond:plan-reader:every-dictionary-entry"
             (equal (mapcar #'plan::entry-element-id (plan::reading-entries reading)) (mapcar #'plan::entry-element-id (p::model-entries model)))))""","""      ;; The plan reader reads the dictionary of the CTM plan page; a further declared dictionary is another source with its own entries.
      (check "correspond:plan-reader:every-dictionary-entry"
             (equal (mapcar #'plan::entry-element-id (plan::reading-entries reading))
                    (loop for (entry . item) in (p::model-declared-entries model)
                          when (eq item (%item sources :dictionary)) collect (plan::entry-element-id entry)))))""")
# the assignments page: this scope's proposals are retired, the assignments refer to the declared work
p='dreyeck/pages/project/Implementation Assignments.html'
s=open(p).read()
a=s.index('<h2>Proposed Work: Regular HyperDoc Catalog with a Navigable Project Topic Map</h2>'); b=s.index('<h2>Assignments</h2>')
s=s[:a]+'''<h2>Declared Work: Regular HyperDoc Catalog with a Navigable Project Topic Map</h2>
<p>Zettel 11359 proposed this scope on this page. The Work item <code>topic-maps-regular-hyperdoc</code> is now declared on the <a page="Work Breakdown" hyperbook="dreyeck/work/reading">Work Breakdown</a>, and its Deliverable <code>tm-regular-catalog</code>, six work packages, six plan steps and four preconditions on <a page="Regular HyperDoc Catalog" hyperbook="dreyeck/work/reading">Regular HyperDoc Catalog</a>; the work packages are defined by the <a page="Regular HyperDoc Catalog WBS Dictionary" hyperbook="dreyeck/work/reading">Regular HyperDoc Catalog WBS Dictionary</a>. They are no longer proposals: this page keeps no <code>data-proposed-topic</code> for them. Every one of them has the status <code>open</code>; the assignments below report results and change no status.</p>

'''+s[b:]
for a_,b_,n in [
 ('<p data-field="work-item" data-ref="topic-maps-regular-hyperdoc">The proposed Work Item above. It is not declared on the Work Breakdown.</p>','<p data-field="work-item" data-ref="topic-maps-regular-hyperdoc">The Work item topic-maps-regular-hyperdoc, declared on the Work Breakdown with the status open.</p>',4),
 ('The proposed work package "1 Integrated Topic Maps Revision" above.','The work package "1 Integrated Topic Maps Revision", declared on Regular HyperDoc Catalog with the status open.',1),
 ('The proposed work package "2 Compatible Project Workspace" above.','The work package "2 Compatible Project Workspace", declared on Regular HyperDoc Catalog with the status open.',1),
 ('The proposed work package "3 Inspectable Project Work" above. The reading','The work package "3 Inspectable Project Work", declared on Regular HyperDoc Catalog with the status open. The reading',1),
 ('Its text cannot make one; the proposed step tm-reg-p1 produces the package.','Its text cannot make one; the declared step tm-reg-p1, status open, produces the package.',1),
 ('Its text cannot make one; the proposed step tm-reg-p2 produces the package.','Its text cannot make one; the declared step tm-reg-p2, status open, produces the package.',1),
 ('Its text cannot make one; the proposed step tm-reg-p3 produces the package.','Its text cannot make one; the declared step tm-reg-p3, status open, produces the package.',1)]:
    assert s.count(a_)==n,(a_[:60],s.count(a_)); s=s.replace(a_,b_)
open(p,'w').write(s)
shutil.copy(TPL+'/test-project-workspace-scope.stage2.mjs','scripts/test-project-workspace-scope.mjs')
print('STAGE2-TREE-BUILT')
