# .nix

One flake for all of my machines: NixOS desktops and servers, and a nix-darwin Mac.

| Host | Platform | What it is |
| --- | --- | --- |
| `nostromo` | NixOS, x86_64 | Main desktop. NVIDIA (RTX 5070), COSMIC, rEFInd with Secure Boot (lanzaboote). Two crucible CI runners. |
| `prometheus` | NixOS, x86_64 | Mostly-headless AMD box running crucible's CI runner pool. Boots to a TTY; `desktop` starts COSMIC on demand. Installed with nixos-anywhere + disko. |
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

## Storage

| Host | Disk | Mounted at | Notes |
| --- | --- | --- | --- |
| nostromo | 990 PRO 4 TB (NVMe) | `/`, `/boot` | btrfs root (`@`) and the ESP; the rest of the disk is Windows' `Big` |
| nostromo | 980 1 TB (NVMe), label `fast` | `/var/lib/microvms`, `/var/lib/crucible-ci-sccache`, `/mnt/fast` | one btrfs filesystem, subvolumes `@microvms`, `@sccache` (both nodatacow) and `@data` share its space |
| nostromo | 512 GB SATA SSD, label `bulk` | `/mnt/bulk` | btrfs, subvolume `@data` |
| prometheus | 1 TB NVMe | `/`, `/home`, `/nix`, `/boot` | btrfs subvolumes, laid out by disko (`hosts/prometheus/disk.nix`) |
| prometheus | 1 TB HDD | `/mnt/hdd` | automounted on first access, unmounted and spun down when idle |

`hosts/nostromo/storage.nix` mounts nostromo's extra disks by filesystem UUID; the CI mounts are
required, the `/mnt` ones are `nofail`.

### Snapshots of /home

On nostromo, `/home` is a btrfs subvolume of its own, and snapper
(`hosts/nostromo/snapshots.nix`) keeps 24 hourly, 7 daily and 4 weekly snapshots of it in
`/home/.snapshots`. `.capy`, `.cache`, `.bun`, `.rustup`, `.npm`, `.cargo` and `Downloads` are nested
subvolumes, which snapshots leave out: they churn, or can be re-downloaded.

```sh
snapper -c home list
cp /home/.snapshots/<N>/snapshot/willothy/<path> ~/<path>   # restore a file
```

## CI runners

Both Linux hosts run [crucible](https://github.com/willothy/crucible) CI runner VMs with crucible's own
runner modules:

- **prometheus** (`hosts/prometheus/ci-runners.nix`): three isolated VMs (5 vCPU, 11 GiB). Each
  builds in a Nix store of its own, reaches only the internet (not the LAN, the tailnet or the host),
  and runs in a low-priority slice capped at 36 GiB. Registered as `prometheus-runner-*`.
- **nostromo**: two runners with crucible's desktop role, below the desktop's own work, with their
  VM images and compiler cache on `fast`. Registered as `desktop-runner-*`.

Runner VMs drain their job (up to 10 minutes) before stopping. If one is killed mid-job instead (a
forced reboot), GitHub keeps counting the job as running and refuses the VM's re-registration under
the same name (HTTP 422) until the job fails on its own, or its workflow run is cancelled.

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

# prometheus, deployed from another machine (building on prometheus, so the
# deploying machine only evaluates)
nixos-rebuild switch --flake .#prometheus --build-host willothy@prometheus --target-host willothy@prometheus --sudo

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
