# Agent instructions

## Communication

- Do not edit files unless the user tells you to. If they ask a question or are
  discussing an approach, answer in chat only. Do not change code until they
  agree on the approach and tell you to apply it.
- Never form feedback. Do not call `send_feedback`, write feedback drafts, or
  open `/feedback`.

## Git

- Do not propose git operations unless the user asks for them.
- Read-only inspect commands do not need approval. Run them when git work is
  requested: `git status`, `git diff`, `git diff --staged`, `git log`. Never
  treat a chat-start snapshot as live status.
- Mutating commands (`add`, `rm`, `commit`, `reset`, `checkout`, `restore`,
  `push`, `pull`, `merge`, `rebase`, and anything that changes the index or
  working tree) require the user to authorize them by saying `exec git`.
- When the user asks for git work, print the exact mutating command(s) for
  review before asking for authorization.
- Write the commit command as git commit -F - followed by a heredoc message with
  one summary line, a blank line, then bullet points.
- Use formatting when emitting the git commands to the console.
- After approval, run only the authorized command(s) and echo the exact
  command(s) issued.
- Do not git revert any files without authorization.

## Project files

- do not delete any files without authorization

## Production isolation

- Never read, write, copy, or quote live user config or secrets into tests,
  fixtures, source, commits, or commands. 
- Fixtures must be invented: synthetic paths only (`/tmp/proj`), never
`/Users/...`, `/home/...`, usernames, real project dirs, or developer machine
files.

