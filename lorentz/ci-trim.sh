#!/usr/bin/env bash
# jcode_lorentz :: desativa no GitHub (so no fork) os workflows herdados do upstream,
# deixando ativo apenas o "Lorentz CI". Reversivel: lorentz/ci-trim.sh --restore
# Rode de novo apos updates: workflows NOVOS do upstream nascem ativados.
set -euo pipefail
REPO="lorentz-attractor/jcode_lorentz"
KEEP="Lorentz CI"
mode="${1:-trim}"
gh workflow list -R "$REPO" --all --json name,state,id -q '.[] | [.id, .state, .name] | @tsv' |
while IFS=$'\t' read -r id state name; do
  if [ "$mode" = "--restore" ]; then
    [ "$state" = "active" ] || { echo "ativando:    $name"; gh workflow enable "$id" -R "$REPO"; }
  elif [ "$name" != "$KEEP" ] && [ "$state" = "active" ]; then
    echo "desativando: $name"; gh workflow disable "$id" -R "$REPO"
  fi
done
echo "ok."
