# claude-sessions-tracker

Plugin de Claude Code que escreve o estado working/idle de cada sessão em `~/.claude/sessions-state/<session_id>.json` via hooks. Serve pra ferramentas externas (ex: o [Claude Sessions menu bar app](../README.md)) saberem com precisão quando uma sessão está trabalhando — inclusive durante o "thinking", antes de qualquer token aparecer no transcript.

## Por que

O método ingênuo de olhar `mtime` do JSONL da sessão tem um buraco: enquanto o modelo pensa (entre o `UserPromptSubmit` e o primeiro token gerado), nada escreve no transcript e a sessão parece idle. Hooks disparam em eventos determinísticos, então dão a verdade.

## O que ele escreve

`~/.claude/sessions-state/<session_id>.json`:

```json
{
  "session_id": "abc-123",
  "cwd": "/Users/you/project",
  "transcript_path": "/Users/you/.claude/projects/.../abc-123.jsonl",
  "working": true,
  "working_since": 1776545913.596,
  "updated_at": 1776545913.631,
  "last_event": "PreToolUse",
  "last_tool": "Write",
  "last_tool_at": 1776545913.631,
  "started_at": 1776545900.01
}
```

| Evento | Efeito no state |
|---|---|
| `SessionStart` | cria arquivo, `working=false` |
| `UserPromptSubmit` | `working=true`, grava `working_since` |
| `PreToolUse` | `working=true`, grava `last_tool` |
| `PostToolUse` | atualiza `last_tool_at` |
| `Stop` | `working=false` |
| `SubagentStop` | grava `last_subagent_stop_at` (não mexe no `working` do pai) |
| `SessionEnd` | remove o arquivo |

Escrita é atômica (`tempfile` + `os.replace`) pra evitar leituras parciais.

## Instalação

Dentro de qualquer sessão do Claude Code:

```text
/plugin marketplace add hassekf/claude-sessions-menubar
/plugin install claude-sessions-tracker@claude-sessions-menubar
```

Os hooks são **globais** — todas as sessões futuras (inclusive em outros projetos) passam a alimentar o state file automaticamente. Pra confirmar: `/plugin` e veja se o `claude-sessions-tracker` aparece como enabled.

**Dev local (sem marketplace):**

```bash
claude --plugin-dir "$(pwd)"
```

## Requisitos

- Claude Code com suporte a hooks (`SessionStart`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `PreToolUse`, `PostToolUse`, `SessionEnd`).
- `python3` no `PATH` (já vem no macOS).

## Privacidade

- O script só escreve metadados (session_id, cwd, evento, timestamps, nome da tool). **Não** grava o conteúdo do prompt nem da resposta.
- Tudo fica em `~/.claude/sessions-state/` no teu Mac. Nada sai da máquina.
- Se você remover o plugin, os arquivos remanescentes podem ser apagados com `rm -rf ~/.claude/sessions-state`.

## Testando manualmente

```bash
echo '{"session_id":"test","hook_event_name":"UserPromptSubmit","cwd":"/tmp"}' \
  | ./scripts/track.py
cat ~/.claude/sessions-state/test.json
```
