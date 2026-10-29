import socket,struct,subprocess,sys,time,os,signal,tempfile,urllib.request
EXE=sys.argv[1]; FIX=sys.argv[2]
home=tempfile.mkdtemp()
s=socket.socket(); s.bind(("127.0.0.1",0)); port=s.getsockname()[1]; s.close()
env={"HOME":home,"PATH":os.environ["PATH"],"HYPERDOC_FEDWIKI_SITE_ROOT":FIX,"TMPDIR":os.environ.get("TMPDIR","/tmp")}
log=open(home+"/log","w+b")
p=subprocess.Popen([EXE,str(port)],env=env,stdout=log,stderr=log)
def up():
    try:
        urllib.request.build_opener(urllib.request.ProxyHandler({})).open(f"http://127.0.0.1:{port}/",timeout=60).read(); return True
    except Exception: return False
t=time.time()
while not up():
    assert p.poll() is None,"died at start"; time.sleep(1)
    assert time.time()-t<600
print("warm and up",flush=True)
def abort(path,mode):
    c=socket.create_connection(("127.0.0.1",port))
    c.sendall(f"GET {path} HTTP/1.1\r\nHost: x\r\nConnection: keep-alive\r\n\r\n".encode())
    if mode=="rst": c.setsockopt(socket.SOL_SOCKET,socket.SO_LINGER,struct.pack("ii",1,0))
    if mode=="read1": c.recv(1)
    c.close()
for path in ["/","/js/boot.js","/view/reading-java-source-as-data"]:
    for mode in ["close","rst","read1"]:
        for _ in range(40): abort(path,mode)
        time.sleep(1)
        print(path,mode,"alive" if p.poll() is None else f"DEAD exit={p.returncode}",flush=True)
        if p.poll() is not None: break
    if p.poll() is not None: break
log.seek(0); out=log.read().decode(errors="replace")
print("broken-pipe lines:",out.count("BROKEN-PIPE"),"| connection-reset lines:",out.count("reset"),"| alive at end:",p.poll() is None)
if p.poll() is None: p.send_signal(signal.SIGTERM); p.wait(20)
