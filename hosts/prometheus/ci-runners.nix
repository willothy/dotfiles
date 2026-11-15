# crucible's CI runner pool, like ci-1's (crucible: hosts/ci/ci-1), sized for
# this box: a Ryzen 7 5800X (16 threads) with 46 GiB of memory.
{ config, lib, inputs, ... }:
let
  # The Attic binary cache on crucible's dev box, over the tailnet; the same
  # cache ci-1 substitutes from and publishes to.
  binaryCache = rec {
    name = "crucible";
    host = "crucible.curl-bramble.ts.net";
    address = "100.77.164.8";
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
    "${inputs.crucible}/nix/modules/platform/resource-guards.nix"
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
    count = 3;
    reservedForMain = 1;
    url = "https://github.com/willothy/crucible";
    kvmModule = "kvm-amd";
    tokenFile = config.sops.secrets.crucible-runner-token.path;
    compilerCacheSize = 20;
    environment = {
      ATTIC_ENDPOINT = binaryCache.url;
      ATTIC_CACHE = binaryCache.name;
    };
    vm = {
      # Every VM builds in this box's nix-daemon, into one shared store.
      nix = "host";
      vcpu = 4;
      memory = 8192;
      cacheSize = 49152;
      cacheTrimPercent = 80;
      scratchSize = 16384;
    };
    network = {
      address = "10.77.0.0";
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      # Publishing reaches the cache over the tailnet by a name the VMs'
      # resolvers don't know.
      hosts.${binaryCache.address} = [ binaryCache.host ];
      isolate = false;
    };
  };

  services.crucible-binary-cache-client = {
    enable = true;
    url = "${binaryCache.url}/${binaryCache.name}";
    inherit (binaryCache) publicKey;
  };

  services.crucible-resource-guards = {
    enable = true;
    ci = {
      cpuWeight = 100;
      # Of 46 GiB, the host keeps 8: the VMs' 27 and nix-daemon's 14 add up
      # to more than the slice, which zram and oomd bound rather than the host.
      memoryMax = "38G";
      memoryPressureLimit = "60%";
    };
    nix = {
      # The runners' builds: three at a time, of 4 threads each.
      maxJobs = 3;
      cores = 4;
      cpuWeight = 100;
      memoryHigh = "12G";
      memoryMax = "14G";
    };
    runners = { };
    services = lib.genAttrs (map (vm: "microvm@${vm}") config.services.crucible-ci-runner-vms.vms) (_: {
      cpuWeight = 100;
      memoryMax = "9G";
    });
    zram.memoryPercent = 25;
    sysstat.collectFrequency = "*:*:00";
    journal.syncInterval = "10s";
  };

  # The VMs' disk images are rewritten in place; on btrfs, copy-on-write
  # would fragment them. New files under these directories inherit +C.
  systemd.tmpfiles.rules = [
    "d ${config.services.crucible-ci-runner-vms.stateDirectory} 0755 root root -"
    "h ${config.services.crucible-ci-runner-vms.stateDirectory} - - - - +C"
    "d /var/lib/crucible-ci-sccache 0700 root root -"
    "h /var/lib/crucible-ci-sccache - - - - +C"
  ];

  # The store mostly caches what the runners built; collect when less than
  # 50 GiB is free, until 150 GiB is.
  nix.settings = {
    min-free = 50 * 1024 * 1024 * 1024;
    max-free = 150 * 1024 * 1024 * 1024;
  };
}
