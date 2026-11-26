# Agent notes

## Downloads

- For large downloads, prefer domestic mirrors when running from this machine or a China-based remote host; avoid consuming overseas bandwidth unnecessarily.
- Preferred mirrors:
  - Node: `https://npmmirror.com/mirrors/node`
  - Python build standalone: `https://registry.npmmirror.com/-/binary/python-build-standalone`
  - npm/pnpm registry: `https://registry.npmmirror.com`
  - pip: `https://pypi.tuna.tsinghua.edu.cn/simple`
- GitHub release assets may use a proxy such as `https://ghfast.top/https://github.com/...` or `https://ghproxy.net/https://github.com/...`; verify checksums after download.
- GitHub Actions runners are overseas: keep mirrors configurable and do not blindly switch CI downloads when that would be slower or unreachable.
