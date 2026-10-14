# HelpLink

**A consent-based remote help tool: turn a command line into a web page so someone you trust can help you — or do a task for you — from their browser.**

HelpLink is built for the situation *"I'm stuck, can you look at my terminal?"*. You run one command, read what it is about to share, and type `y` to agree. You get a temporary link to send to your helper. When you press `Ctrl+C` (or the timer ends) everything is shut down.

> ## Consent notice (please read)
> HelpLink is a **remote assistance tool that only works with the knowledge and explicit consent of the person being helped.**
> - It never starts by itself, never runs in the background, never survives a reboot and never installs a service.
> - Every run prints exactly what will be shared and **asks you to type `y` to consent** before anything is started.
> - It is visible: progress is printed in your terminal and you are told when a helper connects or disconnects.
> - **Do not** use it on a device you do not own or without the owner's permission. Doing so may be illegal and is not what this project is for.

## How it works

```
 Helper's browser ──https──> Cloudflare quick tunnel ──> Python web terminal (127.0.0.1)
                                                             │  (secret token required)
                                                             └─ ssh (key login) ──> OpenSSH server (127.0.0.1 only)
```

| Part | Role |
|------|------|
| **OpenSSH** | A private `sshd` started as *your* user on a random port, bound to `127.0.0.1` only, public-key login only. Nothing is exposed to your network. |
| **Python (stdlib only)** | A tiny HTTP + WebSocket server that bridges the browser to an `ssh` session through a PTY. No pip packages. |
| **cloudflared** | A Cloudflare *quick tunnel* that gives the local page a temporary `https://….trycloudflare.com` address. No account needed. |

The web page has a minimal UI: a terminal plus **zoom** (A−/A+), **scroll** (▲ ▼ ⤓) and reconnect buttons. It works on phones too.

## Requirements

Works on **Termux** and any **Linux** distribution (Debian/Ubuntu, Fedora/RHEL, Arch, Alpine, openSUSE, Void…), with **Bash, Zsh or Fish**.
Needed: `python3` (3.7+), OpenSSH client + server, `curl`, `cloudflared`. The installer checks them and installs what is missing (it asks first).

## Install (one line)

```sh
curl -sL https://raw.githubusercontent.com/TTT2978/helplink/main/install.sh | sh
```

What it does, step by step:
1. Downloads `helplink.zip` from this repo and unzips it to `~/.helplink/app`.
2. Starts `setup.sh`, which first asks the **language** (Tiếng Việt / English).
3. Installs missing packages (asks before doing so) and `cloudflared`.
4. Runs the setup wizard (alias name, SSH key mode, access token mode, auto-stop timer) — each question is explained in detail.
5. Adds your alias to `~/.bashrc`, `~/.zshrc` and `~/.config/fish/config.fish`.

Manual install: download `helplink.zip`, unzip it anywhere, run `sh helplink/setup.sh`.

## Use

On the device that needs help, type the alias (default `helplink`):

```
$ helplink
  ... explains what will be shared ...
Do you consent and want to continue? [y/N]: y
[+] start ssh
[+] start cloudflared tunnel
[+] done!
link public:
https://example-words.trycloudflare.com/?t=SECRET
```

Send the link to your helper. They open it in a browser and get your terminal. Press `Ctrl+C` to stop.

Other commands: `helplink --setup` (change answers), `helplink --uninstall` (remove aliases and data), `helplink --version`.

## Security model

- The link contains a secret token (`?t=…`); requests without it get `403`. By default a new random token is generated every run.
- Only **one** helper can be connected at a time.
- `sshd` listens on `127.0.0.1` only, uses public-key authentication only, and runs unprivileged as your user (no root needed).
- Whoever has the link can run commands **as your user**: send it only to the person you asked, over a channel you trust, and stop when you are done.
- Optional auto-stop timer (default 60 minutes).
- The helper's browser loads the `xterm.js` terminal library from the jsDelivr CDN; your device does not.
- Quick tunnels are a free Cloudflare service without uptime guarantees. Review Cloudflare's terms before use.

## Project layout

```
helplink/
├── setup.sh            # language question, dependency install, launches the wizard
├── bin/helplink        # POSIX sh launcher used by the alias
├── lang/               # translations: en.json, vi.json
├── web/index.html      # the minimal terminal page (zoom + scroll)
└── src/helplink/
    ├── cli.py          # argument handling (--setup, --uninstall, …)
    ├── wizard.py       # interactive setup with detailed explanations
    ├── session.py      # run flow: consent → ssh → web → tunnel → wait
    ├── sshd.py         # OpenSSH: keys + private sshd on 127.0.0.1
    ├── tunnel.py       # cloudflared quick tunnel
    ├── webterm.py      # HTTP server + PTY bridge
    ├── wsproto.py      # minimal WebSocket implementation
    ├── shells.py       # alias for Bash / Zsh / Fish
    ├── i18n.py, ui.py, paths.py
```

Each folder has one job, so a bug is easy to locate: SSH problems → `sshd.py`; no link → `tunnel.py`; blank page → `web/` or `webterm.py`; wrong text → `lang/`.

## Troubleshooting

- **`sshd failed to start`** — see `~/.helplink/run/sshd.log`. Run `helplink --setup` or `setup.sh` again to (re)install OpenSSH.
- **No link / tunnel error** — check your internet; make sure `cloudflared --version` works. On Termux: `pkg install cloudflared`.
- **Account locked errors on some servers** — a locked system account may be refused by `sshd`; use a normal user account.
- **Debian/Ubuntu started a system SSH service on port 22 after installing `openssh-server`** — HelpLink does not need it; disable with `sudo systemctl disable --now ssh`.
- **Alias not found** — open a new terminal or `source ~/.bashrc` / `source ~/.zshrc` / `source ~/.config/fish/config.fish`.

## Uninstall

```sh
helplink --uninstall
```

removes the alias blocks from your shell files and deletes `~/.helplink`.

## License

MIT — see `LICENSE`. Provided "as is", without warranty. You are responsible for using it only with the consent of the person being helped.
