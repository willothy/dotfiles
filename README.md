# .nix

One flake for all of my machines: NixOS desktops and servers, and a nix-darwin Mac.

| Host | Platform | What it is |
| --- | --- | --- |
| `nostromo` | NixOS, x86_64 | Main desktop. NVIDIA, COSMIC + Hyprland, rEFInd with Secure Boot (lanzaboote). |
| `prometheus` | NixOS, x86_64 | Mostly-headless AMD box. Boots to a TTY; `desktop` starts COSMIC on demand. Installed with nixos-anywhere + disko. |
| `macbonk` | nix-darwin, aarch64 | Mac. System config plus standalone home-manager, Homebrew casks. |

## Layout

```
flake.nix          every host is wired up here
hosts/<name>/      per-machine config, hardware, and home-manager entry point
modules/nixos/     NixOS modules shared between the Linux hosts
modules/darwin/    nix-darwin modules
home/common/       home-manager config shared by every host (shells, starship, git, CLI tools)
home/nixos/        home-manager config for the Linux hosts
home/darwin/       home-manager config for the Mac
configs/           raw dotfiles linked in by home-manager (ghostty, wezterm, aerospace, ...)
overlays/          nixpkgs overlays
scripts/           manual maintenance scripts
```

The Linux hosts follow `nixos-unstable`. The Mac has its own pinned inputs (`nixpkgs-darwin`,
`home-manager-darwin`, `darwin`) so it can be updated independently.

## Usage

Each host's config name matches its hostname, so no `#name` is needed when running on the machine itself.

```sh
# nostromo (or any NixOS host, locally)
sudo nixos-rebuild switch --flake ~/.dotfiles

# prometheus, deployed from another machine
nixos-rebuild switch --flake .#prometheus --target-host willothy@prometheus --sudo

# macbonk
cd ~/.dotfiles
sudo darwin-rebuild switch --flake .
home-manager switch --flake .
```

The Mac configs live under `packages.aarch64-darwin.{darwinConfigurations,homeConfigurations}`;
`darwin-rebuild` and `home-manager` find them through nix's `packages.<system>` fallback.

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
