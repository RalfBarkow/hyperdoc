"""Real Chromium navigation, with server-side EQ observations of the pane actually opened by each link."""
import json, pathlib, socket, subprocess, os, time, traceback
from playwright.sync_api import sync_playwright

out = pathlib.Path(__file__).resolve().parent
sock = socket.socket(); sock.bind(('127.0.0.1', 0)); port = sock.getsockname()[1]; sock.close()
stop = out / 'inspector.stop'
if stop.exists(): stop.unlink()
env = dict(os.environ, DEFEDERATION_REPO='/workspace/work/acceptance-pr42',
           TOPIC_MAPS_CANDIDATE_ROOT='/workspace/work/acceptance-runtime/browser/topic-maps-c446a822',
           ACCEPTANCE_INSPECTOR_PORT=str(port), ACCEPTANCE_INSPECTOR_STOP=str(stop))
command = ['/workspace/scratch/tmdm-mcp-portable/bin/sbcl', '--noinform', '--no-sysinit', '--no-userinit', '--non-interactive',
           '--load', str(out/'hyperdoc-bootstrap.lisp'), '--load', str(out/'inspector.lisp')]
log = (out/'inspector.log').open('wb')
child = subprocess.Popen(command, cwd='/workspace/work/acceptance-pr42', env=env, stdout=log, stderr=subprocess.STDOUT)
record = {'lispCommand':command, 'port':port, 'steps':[], 'externalRequests':[], 'browserErrors':[]}
browser = None
try:
    deadline = time.monotonic()+300
    while 'ACCEPTANCE-INSPECTOR-READY' not in (out/'inspector.log').read_text(errors='replace'):
        if child.poll() is not None: raise RuntimeError('Fresh Lisp process exited: '+str(child.returncode))
        if time.monotonic()>deadline: raise TimeoutError('Fresh Inspector startup exceeded 300 seconds')
        time.sleep(.2)
    with sync_playwright() as pw:
        browser = pw.chromium.launch(executable_path='/usr/bin/chromium', headless=True,
                                    args=['--disable-background-networking','--no-proxy-server'])
        context = browser.new_context(viewport={'width':1500,'height':950}, service_workers='block')
        origin = f'http://127.0.0.1:{port}'
        def route(request):
            if request.request.url.startswith(origin+'/'):
                request.continue_()
            else:
                record['externalRequests'].append(request.request.url); request.abort()
        context.route('**/*', route)
        page = context.new_page(); page.set_default_timeout(30000)
        page.on('pageerror', lambda error: record['browserErrors'].append(str(error)))
        page.goto(origin)
        def click(locator):
            locator.wait_for(state='visible')
            locator.evaluate('''el => new Promise((resolve,reject)=>{
              const end=performance.now()+10000;
              const poll=()=>{const jq=window.jQuery; const e=jq&&jq._data(el,'events');
                if(e&&e.click)return resolve(true);
                if(performance.now()>end)return reject(Error('Inspector click handler not bound'));
                setTimeout(poll,5)};poll()})''')
            locator.click()
        def probe(expected):
            click(page.get_by_role('button',name='Probe actual pane EQ',exact=True))
            page.locator('#eq-result').get_by_text('EQ:'+expected+';',exact=False).wait_for()
            record['steps'].append({'actualPaneObjectEQ':expected,'result':page.locator('#eq-result').inner_text()})
        def follow(pane,label,expected,index=0):
            old = page.locator('.inspector-pane').last.get_attribute('id')
            click(pane.get_by_text(label,exact=True).nth(index))
            page.wait_for_function("old=>{const ps=document.querySelectorAll('.inspector-pane');return ps.length&&ps[ps.length-1].id!==old}",arg=old)
            # Native CREATE-PANE registers the pane after CREATE-DOM, before SELECT-VIEW activates a tab.
            # Its div can therefore exist while INSPECTOR-PANES still ends at the source pane.
            page.locator('.inspector-pane').last.locator('.inspector-tabs button.active').first.wait_for()
            probe(expected)
        root = page.locator('.inspector-pane').first
        root.get_by_role('heading',name='One stated relationship — read only').wait_for()
        probe('STATEMENT')
        for label,key in [('Source Association','ASSOCIATION'),('Instance Topic','INSTANCE'),('Type Topic','TYPE'),
                          ('Native Topic Map','MAP'),('Source CTM revision','REVISION')]:
            follow(root,label,key)
        root.screenshot(path=str(out/'inspector-statement.png'))
        click(page.get_by_role('button',name='Open retained investigation',exact=True))
        plan = page.locator('.inspector-pane').last
        plan.get_by_role('heading',name='Topic Maps investigation — plan only').wait_for()
        plan_id = plan.get_attribute('id'); plan=page.locator('[id="'+plan_id+'"]')
        assert plan.get_by_role('heading',name='Alternative 0:',exact=False).count()==1
        assert plan.get_by_role('heading',name='Alternative 1:',exact=False).count()==1
        probe('INVESTIGATION')
        follow(plan,'Native SHOP3 result','PLAN-RESULT')
        follow(plan,'Native plan tree / method','PLAN-TREE-0',0)
        follow(plan,'Native plan tree / method','PLAN-TREE-1',1)
        plan.screenshot(path=str(out/'inspector-plans.png'))
        page.locator('.inspector-pane').last.screenshot(path=str(out/'inspector-native-tree.png'))
        assert not record['browserErrors'], record['browserErrors']
        assert not record['externalRequests'], record['externalRequests']
        record['success']=True
        browser.close(); browser=None
except Exception:
    record['success']=False; record['failure']=traceback.format_exc()
    if browser:
        try: page.screenshot(path=str(out/'inspector-failure.png'), full_page=True)
        except Exception: pass
        try: browser.close()
        except Exception: pass
finally:
    stop.write_text('stop\n')
    try: record['lispExitCode']=child.wait(timeout=15)
    except subprocess.TimeoutExpired:
        child.terminate(); record['lispExitCode']=child.wait(timeout=10)
    log.close(); stop.unlink(missing_ok=True)
    (out/'browser-results.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps({'success':record['success'],'steps':len(record['steps']),'lispExitCode':record['lispExitCode']}))
raise SystemExit(0 if record['success'] else 1)
