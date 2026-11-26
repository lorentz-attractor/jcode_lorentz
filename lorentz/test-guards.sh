#!/usr/bin/env bash
# jcode_lorentz :: testa as travas de seguranca (roda local e no Lorentz CI).
set -u
cd "$(dirname "$0")/.."
fail=0
ok()  { echo "  ok    $1"; }
bad() { echo "  FALHA $1"; fail=1; }

echo "== sintaxe"
for f in lorentz/*.sh lorentz/githooks/* lorentz/hooks/*; do
  bash -n "$f" && ok "$f" || bad "$f"
done

echo "== pre-push (git)"
for url in https://github.com/1jehuang/jcode.git git@github.com:1JEHUANG/jcode ssh://git@github.com/1jehuang/jcode; do
  LORENTZ_ALLOW_FOREIGN_PUSH=1 lorentz/githooks/pre-push origin "$url" 2>/dev/null \
    && bad "nao bloqueou $url" || ok "bloqueia $url"
done
lorentz/githooks/pre-push upstream https://example.com/x 2>/dev/null && bad "remote upstream liberado" || ok "bloqueia remote upstream"
lorentz/githooks/pre-push x https://gitlab.com/a/b 2>/dev/null && bad "repo alheio liberado" || ok "bloqueia repo alheio sem override"
lorentz/githooks/pre-push origin https://github.com/lorentz-attractor/jcode_lorentz.git 2>/dev/null \
  && ok "libera o fork" || bad "bloqueou o fork"

echo "== pre_tool (agente jcode)"
gate() { jq -nc --arg c "$1" '{command:$c}' | JCODE_HOOK_TOOL_NAME=bash lorentz/hooks/jcode-tool-policy 2>/dev/null; echo $?; }
U="1jeh""uang"
for c in "git push upstream master" "git push --force upstream" "git -C . push https://github.com/$U/jcode.git HEAD" \
         "git -c core.hooksPath=/dev/null push origin" "git remote set-url --push upstream x" \
         "gh pr create -R $U/jcode --fill" "gh api -X POST repos/$U/jcode/issues -f title=x"; do
  [ "$(gate "$c")" = 2 ] && ok "bloqueia: $c" || bad "liberou: $c"
done
for c in "git push origin master" "git fetch upstream" "gh run list -R $U/jcode" "gh pr view 1 -R $U/jcode"; do
  [ "$(gate "$c")" = 0 ] && ok "libera:   $c" || bad "bloqueou: $c"
done

[ $fail = 0 ] && echo "TODAS AS TRAVAS OK" || { echo "HA TRAVAS COM FALHA"; exit 1; }
