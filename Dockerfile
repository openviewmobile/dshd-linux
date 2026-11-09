# Domestic-mirror friendly build. For x64 on an arm64 host:
#   docker build --platform linux/amd64 \
#     --build-arg NODE_IMAGE=node:24-bookworm-slim-amd64 \
#     --build-arg APT_MIRROR=http://mirrors.aliyun.com \
#     -t dshd-linux-test:amd64 -f Dockerfile .
ARG NODE_IMAGE=node:24-bookworm
ARG APT_MIRROR=http://mirrors.aliyun.com
ARG NPM_REGISTRY=https://registry.npmmirror.com
ARG ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
FROM ${NODE_IMAGE}

ARG APT_MIRROR
ARG NPM_REGISTRY
ARG ELECTRON_MIRROR
ENV DEBIAN_FRONTEND=noninteractive
ENV ELECTRON_MIRROR=${ELECTRON_MIRROR}
ENV COREPACK_NPM_REGISTRY=${NPM_REGISTRY}
ENV ELECTRON_DISABLE_SANDBOX=1
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

RUN if [ -n "$APT_MIRROR" ]; then \
      sed -i "s|http://deb.debian.org|$APT_MIRROR|g" /etc/apt/sources.list.d/debian.sources; \
    fi \
 && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git xz-utils unzip zip \
    build-essential python3 python3-venv pkg-config \
    libgtk-3-0 libnss3 libasound2 libgbm1 libdrm2 \
    libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 libxfixes3 \
    libxkbcommon0 libatk-bridge2.0-0 libatk1.0-0 libcups2 \
    libpango-1.0-0 libcairo2 libatspi2.0-0 libxss1 libxtst6 \
    xvfb x11-utils imagemagick \
    flatpak flatpak-builder rpm \
    && rm -rf /var/lib/apt/lists/*

RUN npm config set registry "$NPM_REGISTRY" \
 && corepack enable && corepack prepare pnpm@11.28.5 --activate

# Flathub itself may be blocked; Flatpak packaging can add the remote later.
RUN (flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true) \
 && (flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true)

WORKDIR /work

CMD ["bash"]
