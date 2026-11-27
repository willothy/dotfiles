# crucible's CI runner pool, like ci-1's (crucible: hosts/ci/ci-1), sized for
# this box: a Ryzen 7 5800X (16 threads) with 46 GiB of memory.
#
# The box sits on the home LAN and runs other services, so the pool runs as
# crucible's workstations' does (nix/profiles/roles/ci-runner-desktop.nix):
# each VM builds in a Nix of its own, reaches the internet alone (not the
# LAN, the tailnet, or this host), and runs in a slice below the host's own
# work.
{ config, lib, inputs, ... }:
let
  # The Attic binary cache on crucible's dev box, over the tailnet; the same
  # cache ci-1 substitutes from. This host's own builds substitute from it;
  # the VMs, isolated from the tailnet, substitute from this host's store.
  binaryCache = rec {
    name = "crucible";
    host = "crucible.curl-bramble.ts.net";
    url = "https://${host}:9443";
    publicKey = "crucible:Vp6MwjyWpcdj8ebv1m8qIhLNSP4m3WUFC2G7VALrUss=";
  };
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.crucible.nixosModules.ci-runner-host
    "${inputs.crucible}/nix/profiles/roles/ci-runner-pool.nix"
    "${inputs.crucible}/nix/modules/platform/binary-cache-client.nix"
  ];

  # Decrypted with the SSH host key, the recipient .sops.yaml lists for
  # this box. The token only registers runners.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.gnupg.sshKeyPaths = [ ];
  sops.secrets.crucible-runner-token = {
    sopsFile = ../../secrets/prometheus/crucible-runner-token;
    format = "binary";
  };

  services.crucible-ci-runner-vms = {
    # Four VMs of 4 vCPUs and 8 GiB, the shape of crucible's CI boxes' VMs:
    # 16 vCPUs of the 16 threads, and 32 GiB of memory, under the slice's
    # cap with QEMU's and virtiofsd's own. A guest's own Nix runs a compiler
    # per vCPU; at 4 vCPUs and 8 GiB, a job on crucible's CI boxes has
    # peaked at 6.1 GiB.
    count = 4;
    # Every VM is branch capacity: main's jobs run on ci-1 alone.
    reservedForMain = 0;
    url = "https://github.com/willothy/crucible";
    kvmModule = "kvm-amd";
    tokenFile = config.sops.secrets.crucible-runner-token.path;
    compilerCacheSize = 20;
    vm = {
      # Each VM builds in its own nix-daemon, inside the VM's network filter
      # and memory, on a store volume of its own; this host's store reaches
      # it read-only, as its first substituter.
      nix = "guest";
      vcpu = 4;
      memory = 8192;
      # Four cache volumes of 32 GiB, four store volumes of 32 GiB, and
      # four scratch volumes of 16 GiB: 320 GiB at most, in sparse images,
      # on the disk this host's own files share.
      cacheSize = 32768;
      nixStoreSize = 32768;
      cacheTrimPercent = 80;
      scratchSize = 16384;
    };
    # The tests' Docker Hub images from a cache on this host first, which
    # fetches outside the VMs' NAT and keeps serving the images it holds
    # while the home connection or Docker Hub is out: 10 GiB at most, under
    # /var/lib/crucible-ci-docker-hub-cache. Then Google's mirror of Docker
    # Hub, which serves them without Docker Hub's limit on anonymous pulls
    # from this one home address.
    dockerHubCache.enable = true;
    dockerHubMirrors = [ "mirror.gcr.io" ];
    network = {
      address = "10.77.0.0";
      # Public resolvers: the LAN's own resolver is out of the VMs' reach.
      # Three providers, as on crucible's CI boxes, so one that stops
      # answering is not every lookup; Quad9's unfiltered address, so every
      # server gives the same answers.
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
        "9.9.9.10"
        "1.0.0.1"
      ];
      # No job a branch triggers reaches the LAN, the tailnet, or this host.
      isolate = true;
    };

    asAvailable = {
      enable = true;
      startAtBoot = true;
      # A stopping VM's job gets this long; shutdown waits this long at most.
      drainTimeout = 10;
      # Free space every VM boot leaves on the disk beyond what the pool's
      # volumes and compiler cache may still take of it.
      diskMargin = 32;
      slice = {
        # A tenth of user.slice's and system.slice's weight each, so this
        # host's own services win the CPU and disk whenever they want them.
        cpuWeight = 10;
        ioWeight = 10;
        # Of the 46 GiB, the host and its services always keep about 10.
        memoryMax = "36G";
      };
    };
  };

  services.crucible-binary-cache-client = {
    enable = true;
    url = "${binaryCache.url}/${binaryCache.name}";
    inherit (binaryCache) publicKey;
  };

  # The VMs' disk images are rewritten in place; on btrfs, copy-on-write
  # would fragment them. New files under these directories inherit +C.
  systemd.tmpfiles.rules = [
    "d ${config.services.crucible-ci-runner-vms.stateDirectory} 0755 root root -"
    "h ${config.services.crucible-ci-runner-vms.stateDirectory} - - - - +C"
    "d /var/lib/crucible-ci-sccache 0700 root root -"
    "h /var/lib/crucible-ci-sccache - - - - +C"
  ];

  # The store mostly caches what this host built and what it serves the VMs;
  # collect when less than 50 GiB is free, until 150 GiB is.
  nix.settings = {
    min-free = 50 * 1024 * 1024 * 1024;
    max-free = 150 * 1024 * 1024 * 1024;
  };
}
