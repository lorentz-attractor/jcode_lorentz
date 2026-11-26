# jcode_lorentz

Fork pessoal do [jcode](https://github.com/1jehuang/jcode), usado como motor de
programacao agentica para projetos pessoais, academicos e de trabalho.
A ideia e ir empilhando camadas (configuracao, hooks, skills, ferramentas) sem
brigar com o upstream.

> **O repositorio central `1jehuang/jcode` e SOMENTE LEITURA a partir daqui.**
> Contribuicoes vao por Pull Request aberto pelo navegador, a partir deste fork.

## Estrutura do fork

Tudo que e especifico do fork mora em `lorentz/` (e neste arquivo), para que os
merges do upstream quase nunca conflitem.

| Caminho | O que e |
|---|---|
| `FORK.md` | Este arquivo: o que mudou e por que |
| `lorentz/setup.sh` | Instala as travas de seguranca (idempotente) |
| `lorentz/update.sh` | Puxa o upstream, faz merge, push pro fork, compila e instala |
| `lorentz/test-guards.sh` | Testa todas as travas (roda local e no CI) |
| `lorentz/ci-trim.sh` | Desativa no GitHub os workflows pesados herdados do upstream |
| `lorentz/githooks/pre-push` | Hook git que bloqueia push pro jcode central |
| `lorentz/hooks/jcode-tool-policy` | Gate `pre_tool` do jcode: bloqueia o *agente* |
| `.github/workflows/lorentz-ci.yml` | CI enxuto (Linux): travas + fmt + check |
| `.gitignore` (secao final) | Arquivos sensiveis e pessoais |

## Travas contra push no jcode central

Cinco camadas independentes. Qualquer uma sozinha ja impede o push.

1. **`remote.upstream.pushurl = DISABLED`**: `git push upstream` nao tem destino.
2. **pre-push hook** (`core.hooksPath = lorentz/githooks`): bloqueia qualquer URL
   com `1jehuang/jcode` (https, ssh, maiusculas...) e o remote `upstream`, sem
   override. Push para fora de `lorentz-attractor/` exige
   `LORENTZ_ALLOW_FOREIGN_PUSH=1`.
3. **`pushInsteadOf` global** (`~/.gitconfig`): em *qualquer* clone da maquina,
   push para `1jehuang/jcode` vira `no-push://...` e falha.
4. **Gate `pre_tool` do jcode** (`~/.jcode/config.toml` -> `[hooks] pre_tool`):
   o agente nao consegue rodar `git push` pro upstream, `gh pr/issue/release/api`
   com escrita no `1jehuang`, nem desligar as travas. Leituras continuam livres.
5. **GitHub**: a conta `lorentz-attractor` nao tem permissao de push no upstream.

Verificar: `lorentz/test-guards.sh`. Reinstalar (clone novo): `lorentz/setup.sh`.

## Atualizar

```bash
cd ~/Projetos/jcode && lorentz/update.sh          # merge + push + build + install
lorentz/update.sh --no-build                       # so sincroniza
lorentz/update.sh --lto                            # build otimizado (mais lento)
lorentz/ci-trim.sh                                 # apos update: desliga workflows novos do upstream
```

No NixOS o build precisa do `nix develop` (o script ja faz isso). Leva ~45 min
nesta maquina no perfil `--fast` quando ha muitas mudancas.
Versoes antigas ficam em `~/.jcode/builds/versions/` para rollback.

## Onde customizar (do mais seguro ao mais invasivo)

1. **`~/.jcode/config.toml`**: providers, swarm, hooks, keybindings. Nao versionado.
2. **Hooks** (`docs/HOOKS.md`): scripts em `lorentz/hooks/`, ligados pelo config.
3. **Skills**: `~/.claude/skills/<nome>/SKILL.md`.
4. **MCP servers**: ferramentas externas.
5. **`AGENTS.md` por projeto**: instrucoes locais de cada repo.
6. **Codigo** (self-dev mode): registrar aqui embaixo cada mudanca.

## Mudancas no codigo em relacao ao upstream

| Data | Commit | Mudanca | Motivo |
|---|---|---|---|
| 2026-11-25 | `677ff185b` | `.gitignore`: secao de arquivos sensiveis | Seguranca |
| 2026-11-25 | - | `lorentz/`, `FORK.md`, `lorentz-ci.yml` | Infra do fork |

## Notas

### Providers (Anthropic + Together AI)

- A conta Anthropic atual e **OAuth de assinatura** (Claude). Ela nao funciona
  atras de um gateway como o Bifrost, que precisa de **API key** do console.
  Manter a assinatura direto no jcode.
- O jcode ja tem Together nativo: `jcode login --provider together`.
- Gateway proprio (Bifrost, LiteLLM...): declarar como provider nomeado:

  ```toml
  [providers.bifrost]
  type = "openai-compatible"        # ou "anthropic-compatible"
  base_url = "http://localhost:8080/v1"
  api_key_env = "BIFROST_API_KEY"   # chave fica no ambiente, nunca no repo
  default_model = "<provedor>/<modelo>"   # formato de nome do Bifrost
  ```

### Swarm (`[agents]` no config)

| Chave | Valor atual | Efeito |
|---|---|---|
| `swarm_model` | `claude-haiku-5-5` | Modelo padrao dos workers (`inherit` = mesmo do coordenador) |
| `swarm_model_selection` | `true` | Coordenador pode escolher o modelo do worker... |
| `swarm_model_allowlist` | haiku, sonnet | ...mas so entre estes |
| `swarm_effort` | (unset = low) | Esforco de raciocinio dos workers |
| `swarm_root_effort` | (unset = low) | Esforco do coordenador em modo swarm |
| `swarm_spawn_mode` | `inline` | Workers aparecem como painel dentro da sessao (`alt+n`) |
| `swarm_max_concurrent_agents` | `32` | Teto de workers simultaneos |
| `swarm_stall_after_secs` | `600` | Worker parado 10 min e marcado como travado |
| `swarm_stall_nudge` | `false` | Se `true`, cutuca o worker travado automaticamente |

Arquitetura completa: `docs/SWARM_ARCHITECTURE.md`.
