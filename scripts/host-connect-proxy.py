import socket, socketserver, select, sys
class H(socketserver.BaseRequestHandler):
    def handle(self):
        data=self.request.recv(65536)
        if not data: return
        line=data.split(b'\r\n',1)[0].decode('latin1')
        parts=line.split()
        if len(parts)<2: return
        if parts[0]=='CONNECT':
            host,port=parts[1].rsplit(':',1); port=int(port)
            try:
                up=socket.create_connection((host,port),timeout=20)
            except Exception as e:
                self.request.sendall(b'HTTP/1.1 502 Bad Gateway\r\n\r\n'); return
            self.request.sendall(b'HTTP/1.1 200 Connection Established\r\n\r\n')
            socks=[self.request,up]
            while True:
                r,_,_=select.select(socks,[],[],60)
                if not r: break
                for s in r:
                    try: b=s.recv(65536)
                    except Exception: b=b''
                    if not b: return
                    (up if s is self.request else self.request).sendall(b)
        else:
            # plain HTTP proxy
            from urllib.parse import urlsplit
            u=urlsplit(parts[1])
            try:
                up=socket.create_connection((u.hostname,u.port or 80),timeout=20)
            except Exception:
                self.request.sendall(b'HTTP/1.1 502 Bad Gateway\r\n\r\n'); return
            path=u.path or '/'
            if u.query: path+='?'+u.query
            up.sendall(f'{parts[0]} {path} HTTP/1.1\r\n'.encode()+b'\r\n'.join(data.split(b'\r\n')[1:]))
            while True:
                b=up.recv(65536)
                if not b: break
                self.request.sendall(b)
class S(socketserver.ThreadingTCPServer): allow_reuse_address=True
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, default=18888)
args = parser.parse_args()
S(("0.0.0.0", args.port), H).serve_forever()
