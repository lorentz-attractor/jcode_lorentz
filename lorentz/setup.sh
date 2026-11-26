#!/usr/bin/env bash
# jcode_lorentz :: instala as travas de seguranca e configuracoes do fork.
# Idempotente: pode rodar quantas vezes quiser (o update.sh roda sempre).
#
# Camadas de protecao contra push no jcode central (1jehuang/jcode):
#   1. remote.upstream.pushurl = DISABLED          (deste clone)
#   2. pre-push hook em lorentz/githooks           (deste clone, versionado)
#   3. url.*.pushInsteadOf global                  (TODOS os clones da maquina)
#   4. gh repo default = fork                      (PRs/issues do gh vao pro fork)
#   5. GitHub: sua conta nao tem permissao de push no upstream.
set -euo pipefail
repo_root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$repo_root"

UPSTREAM_URL="https://github.com/1jehuang/jcode.git"
FORK_URL="https://github.com/lorentz-attractor/jcode_lorentz.git"
BLACKHOLE="no-push://1jehuang-jcode-e-somente-leitura/"

echo "==> remotes"
git remote get-url origin >/dev/null 2>&1 || git remote add origin "$FORK_URL"
git remote get-url upstream >/dev/null 2>&1 || git remote add upstream "$UPSTREAM_URL"
git remote set-url --push upstream DISABLED

echo "==> pre-push hook (core.hooksPath=lorentz/githooks)"
chmod +x lorentz/githooks/*
git config core.hooksPath lorentz/githooks

echo "==> pushInsteadOf global (bloqueia push pro jcode central em qualquer clone)"
for prefix in \
  "https://github.com/1jehuang/jcode" \
  "http://github.com/1jehuang/jcode" \
  "git@github.com:1jehuang/jcode" \
  "ssh://git@github.com/1jehuang/jcode" \
  "git://github.com/1jehuang/jcode"; do
  if ! git config --global --get-all "url.${BLACKHOLE}.pushInsteadOf" 2>/dev/null | grep -qxF "$prefix"; then
    git config --global --add "url.${BLACKHOLE}.pushInsteadOf" "$prefix"
  fi
done

if command -v gh >/dev/null 2>&1; then
  echo "==> gh default repo = fork"
  gh repo set-default lorentz-attractor/jcode_lorentz >/dev/null 2>&1 || true
fi

echo "==> ok. Travas ativas."
