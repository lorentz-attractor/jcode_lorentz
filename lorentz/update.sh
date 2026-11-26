#!/usr/bin/env bash
# jcode_lorentz :: atualiza o fork com o upstream, compila e instala.
#
# Uso: lorentz/update.sh [--no-build] [--no-push] [--lto]
#   --no-build  so faz merge/push, nao compila
#   --no-push   nao envia o resultado pro origin (seu fork)
#   --lto       build otimizado (bem mais lento) em vez de --fast
set -euo pipefail
repo_root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$repo_root"

build=1; push=1; fast="--fast"
for arg in "$@"; do
  case "$arg" in
    --no-build) build=0 ;;
    --no-push) push=0 ;;
    --lto) fast="" ;;
    *) echo "argumento desconhecido: $arg" >&2; exit 2 ;;
  esac
done

lorentz/setup.sh >/dev/null

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "Ha alteracoes nao commitadas. Faca commit ou stash antes." >&2
  exit 1
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
echo "==> branch: $branch"
echo "==> fetch origin + upstream"
git fetch origin
git fetch upstream --tags

echo "==> sincronizando com origin/$branch"
git merge --ff-only "origin/$branch" 2>/dev/null || git merge --no-edit "origin/$branch"

behind="$(git rev-list --count HEAD..upstream/master)"
echo "==> $behind commit(s) novos no upstream"
if [ "$behind" -gt 0 ]; then
  if ! git merge --no-edit upstream/master; then
    echo >&2
    echo "CONFLITO no merge com o upstream. Resolva, faca 'git commit' e rode de novo." >&2
    echo "Dica: veja FORK.md para lembrar o que foi customizado." >&2
    exit 1
  fi
fi

if [ "$push" = 1 ]; then
  echo "==> push para origin (seu fork)"
  git push origin "$branch"
fi

if [ "$build" = 1 ]; then
  echo "==> build + install (nix develop)"
  nix develop --command scripts/install_release.sh $fast
  "$HOME/.local/bin/jcode" --version || true
fi
echo "==> pronto."
