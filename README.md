# .nix

One flake for all of my machines: NixOS desktops and servers, and a nix-darwin Mac.

| Host | Platform | What it is |
| --- | --- | --- |
| `nostromo` | NixOS, x86_64 | Main desktop. NVIDIA, COSMIC, rEFInd with Secure Boot (lanzaboote). |
| `prometheus` | NixOS, x86_64 | Mostly-headless AMD box. Boots to a TTY; `desktop` starts COSMIC on demand. Installed with nixos-anywhere + disko. |
| `macbonk` | nix-darwin, aarch64 | Mac. nix-darwin with integrated home-manager, Homebrew casks. |

## Layout

```
flake.nix          every host is wired up here
hosts/<name>/      per-machine config, hardware, and home-manager entry point
modules/common/    system modules shared by every host (packages, vim, shells)
modules/nixos/     NixOS modules shared between the Linux hosts (incl. Determinate Nix)
modules/darwin/    nix-darwin modules
home/common/       home-manager config shared by every host (shells, ssh, git, neovim, CLI tools)
home/nixos/        home-manager config for the Linux hosts
home/darwin/       home-manager config for the Mac
configs/           raw dotfiles linked in by home-manager (ghostty, wezterm, aerospace, ...)
overlays/          nixpkgs overlays
scripts/           manual maintenance scripts
secrets/<host>/    sops-encrypted secrets, one file per secret (.sops.yaml lists recipients)
```

Every host follows the same `nixos-unstable` nixpkgs and home-manager pins, and runs Determinate Nix
configured through the flake (on the Mac, Nix itself is installed by Determinate's installer).

CI (`.github/workflows/eval.yml`) evaluates every host's configuration on each push, and a weekly job
(`update.yml`) opens a `flake.lock` update PR once the updated lock evaluates on every host.

prometheus runs a pool of [crucible](https://github.com/willothy/crucible) CI runner VMs
(`hosts/prometheus/ci-runners.nix`), using crucible's own runner modules.

## Secrets

Secrets are encrypted with [sops](https://github.com/getsops/sops) to age keys and decrypted on the
host at activation by [sops-nix](https://github.com/Mic92/sops-nix); nothing secret enters the Nix
store. Each host decrypts with its SSH host key (its recipient in `.sops.yaml` comes from
`ssh-to-age`); my own age key, kept in 1Password, can decrypt and edit everything.

```sh
# add or replace a secret (needs only the recipients' public keys)
sops encrypt --filename-override secrets/<host>/<name> --input-type binary --output-type binary /dev/stdin \
  > secrets/<host>/<name>

# edit one (needs my age key in ~/.config/sops/age/keys.txt)
sops edit secrets/<host>/<name>
```

## Usage

Each host's config name matches its hostname, so no `#name` is needed when running on the machine itself.

```sh
# nostromo (or any NixOS host, locally)
# (--sudo, not `sudo nixos-rebuild`: evaluation needs your ssh agent for the
# private crucible input, and only the switch runs as root)
nixos-rebuild switch --flake ~/.dotfiles --sudo

# prometheus, deployed from another machine
nixos-rebuild switch --flake .#prometheus --target-host willothy@prometheus --sudo

# macbonk (system and home-manager together)
sudo darwin-rebuild switch --flake ~/.dotfiles
```

### Installing a new NixOS host

Add `hosts/<name>/` with a `disk.nix` (disko) and a placeholder `hardware-configuration.nix`, wire it
into `flake.nix`, boot the target into a NixOS installer (or any Linux with SSH), then:

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#<name> \
  --generate-hardware-config nixos-generate-config ./hosts/<name>/hardware-configuration.nix \
  <user>@<ip>
```

## History

The NixOS side started as its own repo; the original nix-darwin config from this repo was merged into
it. The pre-merge Mac-only history is kept at the `legacy-darwin` tag.
