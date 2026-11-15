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
    # Three VMs of 5 vCPUs and 11 GiB: 15 vCPUs of the 16 threads, and 33
    # GiB of memory, under the slice's cap with cloud-hypervisor's and
    # virtiofsd's own. A guest's own Nix runs a compiler per vCPU, and
    # cloud-hypervisor's build peaked 349 MiB short of 8 GiB in a VM of
    # 8 vCPUs (crucible CRU-118); 11 GiB left 3.7 GiB free at 6 vCPUs.
    count = 3;
    reservedForMain = 1;
    url = "https://github.com/willothy/crucible";
    kvmModule = "kvm-amd";
    tokenFile = config.sops.secrets.crucible-runner-token.path;
    compilerCacheSize = 20;
    vm = {
      # Each VM builds in its own nix-daemon, inside the VM's network filter
      # and memory, on a store volume of its own; this host's store reaches
      # it read-only, as its first substituter.
      nix = "guest";
      vcpu = 5;
      memory = 11264;
      # Three cache volumes of 32 GiB, three store volumes of 32 GiB, and
      # three scratch volumes of 16 GiB: 240 GiB at most, in sparse images,
      # on the disk this host's own files share.
      cacheSize = 32768;
      nixStoreSize = 32768;
      cacheTrimPercent = 80;
      scratchSize = 16384;
    };
    # Google's mirror of Docker Hub, which serves the tests' images without
    # Docker Hub's limit on anonymous pulls from this one home address.
    dockerHubMirrors = [ "mirror.gcr.io" ];
    network = {
      address = "10.77.0.0";
      # Public resolvers: the LAN's own resolver is out of the VMs' reach.
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
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
