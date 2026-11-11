#!/usr/bin/env python3
"""Tiny CONNECT/HTTP forwarder used by the Linux build and acceptance scripts.

By default it dials the requested host directly. With ``--upstream`` it chains
through another HTTP proxy (for example a local Clash listener that is bound to
127.0.0.1 and therefore invisible to Docker).
"""
import argparse
import select
import socket
import socketserver
from urllib.parse import urlsplit

UPSTREAM = None


def dial(host, port):
    if UPSTREAM is None:
        return socket.create_connection((host, port), timeout=20)
    upstream = socket.create_connection(UPSTREAM, timeout=20)
    upstream.sendall(f"CONNECT {host}:{port} HTTP/1.1\r\nHost: {host}:{port}\r\n\r\n".encode())
    response = b""
    while b"\r\n\r\n" not in response:
        chunk = upstream.recv(4096)
        if not chunk:
            upstream.close()
            raise OSError("upstream proxy closed during CONNECT")
        response += chunk
    status = response.split(b"\r\n", 1)[0]
    if b" 200 " not in status and not status.endswith(b" 200"):
        upstream.close()
        raise OSError(f"upstream proxy refused CONNECT: {status!r}")
    return upstream


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        data = self.request.recv(65536)
        if not data:
            return
        line = data.split(b"\r\n", 1)[0].decode("latin1")
        parts = line.split()
        if len(parts) < 2:
            return
        if parts[0] == "CONNECT":
            host, port = parts[1].rsplit(":", 1)
            try:
                upstream = dial(host, int(port))
            except Exception:
                self.request.sendall(b"HTTP/1.1 502 Bad Gateway\r\n\r\n")
                return
            self.request.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            sockets = [self.request, upstream]
            while True:
                readable, _, _ = select.select(sockets, [], [], 60)
                if not readable:
                    return
                for source in readable:
                    try:
                        chunk = source.recv(65536)
                    except Exception:
                        chunk = b""
                    if not chunk:
                        return
                    (upstream if source is self.request else self.request).sendall(chunk)
        else:
            url = urlsplit(parts[1])
            try:
                upstream = dial(url.hostname, url.port or 80)
            except Exception:
                self.request.sendall(b"HTTP/1.1 502 Bad Gateway\r\n\r\n")
                return
            path = url.path or "/"
            if url.query:
                path += "?" + url.query
            upstream.sendall(f"{parts[0]} {path} HTTP/1.1\r\n".encode()
                             + b"\r\n".join(data.split(b"\r\n")[1:]))
            while True:
                chunk = upstream.recv(65536)
                if not chunk:
                    break
                self.request.sendall(chunk)


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    global UPSTREAM
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=18888)
    parser.add_argument("--upstream", help="host:port of an HTTP proxy to chain through")
    args = parser.parse_args()
    if args.upstream:
        host, port = args.upstream.rsplit(":", 1)
        UPSTREAM = (host, int(port))
    Server(("0.0.0.0", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
