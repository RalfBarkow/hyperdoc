import socket, fcntl, struct
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
SIOCGIFFLAGS,SIOCSIFFLAGS=0x8913,0x8914
ifr=struct.pack('16sH14s',b'lo',0,b'\0'*14)
flags=struct.unpack('16sH14s',fcntl.ioctl(s,SIOCGIFFLAGS,ifr))[1]
fcntl.ioctl(s,SIOCSIFFLAGS,struct.pack('16sH14s',b'lo',flags|1,b'\0'*14))
print('lo up')
