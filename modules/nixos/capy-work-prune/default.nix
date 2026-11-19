# Prunes cargo target directories under a work directory that crews share for
# builds, so a machine cannot be filled by build output nobody is using any
# more: nostromo had 1.1 GB free of 2.2 TB on 2026-11-19, roughly 500 GB of it
# target directories from finished crews.
#
# A target directory counts whether it is a checkout's target/ or a top-level
# directory that is one itself, and it is recognised by cargo's own marks
# (CACHEDIR.TAG, .rustc_info.json, or deps/ beside .fingerprint/ in a profile
# directory), never by its name: a checkout that ships a release/ directory of
# packaging scripts is source. Nothing is removed while a process has it as its
# working directory, holds a file in it open, has one of its files mapped, or
# while cargo holds its build locks in it, and nothing is removed until the
# newest write anywhere under it is older than the idle window. On top of that each crew is capped by name (`CRU-334` and
# `CRU-334-target` are one crew), oldest first, and a filesystem below the floor
# drops to the shorter pressure window so a build starting later cannot be the
# thing that finds the disk full.
#
# To see what it would do without touching anything, run it by hand as the user
# the service runs as; the hourly timer is what normally starts it:
#
#   capy-work-prune --dry-run
#
# Every option below is passed explicitly by the service, so this is the same
# command with the configuration this module holds. The script's own defaults
# are the same numbers when no option is given.
{
  config,
  lib,
  pkgs,
  globalUserInfo,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;

  cfg = config.services.capyWorkPrune;

  package = pkgs.writeShellApplication {
    name = "capy-work-prune";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnugrep
      util-linux
    ];
    text = builtins.readFile ./prune.sh;
  };

  stateDirectory = "capy-work-prune";

  commonArguments = [
    "--work-dir"
    cfg.workDir
    "--crew-budget-gib"
    (toString cfg.crewBudgetGiB)
    "--idle-hours"
    (toString cfg.idleHours)
    "--pressure-idle-hours"
    (toString cfg.pressureIdleHours)
    "--free-floor-gib"
    (toString cfg.freeFloorGiB)
    "--state-dir"
    "/var/lib/${stateDirectory}"
  ];

  # The hourly run and the daily run differ only in whether they may skip the
  # walk over every target directory.
  pruneService =
    { description, arguments }:
    {
      inherit description;

      # A system service gets no HOME, and the prune wants the one a login
      # session has: cargo and git in a crew's tree read it, and the script's
      # default work directory is under it.
      environment.HOME = config.users.users.${cfg.user}.home;

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = lib.escapeShellArgs ([ "${package}/bin/capy-work-prune" ] ++ arguments ++ commonArguments);
        StateDirectory = stateDirectory;

        # Hundreds of gigabytes take minutes to delete, and nothing waits on it.
        TimeoutStartSec = "1h";

        # Reclaiming space must never be what makes a desktop stutter.
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };
in
{
  options.services.capyWorkPrune = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Prune cargo target directories under {option}`workDir` that are idle or
        over their crew's budget.

        The process check reads `/proc`, so it sees the processes of the user
        this service runs as and nothing else: a build running under another
        user, or inside a container, is invisible to it. Cargo builds are still
        safe there, because cargo holds a lock file in the target directory for
        as long as it builds and the prune probes that lock before deleting; a
        build that is not cargo, runs in a container, and holds nothing open
        inside its target directory can be removed under it.
      '';
    };

    user = mkOption {
      type = types.str;
      default = globalUserInfo.userName;
      description = ''
        The user that owns the work directory. The prune runs as this user, so it
        needs no escalation beyond the files it deletes.
      '';
    };

    workDir = mkOption {
      type = types.str;
      default = "${config.users.users.${cfg.user}.home}/.capy/work";
      defaultText = lib.literalExpression ''"''${config.users.users.''${config.services.capyWorkPrune.user}.home}/.capy/work"'';
      description = ''
        The directory whose target directories are pruned. Only its top-level
        entries are considered: one that holds `debug/` or `release/` itself, or
        one whose `target/` does.
      '';
    };

    crewBudgetGiB = mkOption {
      type = types.ints.positive;
      default = 100;
      description = ''
        Ceiling, in GiB, on the target directories one crew holds. A crew is
        named after its top-level entry, lowercased with a trailing `-target`
        removed, so `CRU-334` and `CRU-334-target` share a budget. Applied after
        the idle window, so only a crew still over budget with everything recent
        loses anything to it, oldest first.
      '';
    };

    idleHours = mkOption {
      type = types.ints.positive;
      default = 24;
      description = ''
        How long neither `debug/` nor `release/` must have been written for a
        target directory to count as idle. An idle directory is removed whatever
        its crew's budget.
      '';
    };

    pressureIdleHours = mkOption {
      type = types.ints.positive;
      default = 2;
      description = ''
        The idle window used instead of {option}`idleHours` while the filesystem
        holding {option}`workDir` has less than {option}`freeFloorGiB` free. It
        must not exceed {option}`idleHours`.
      '';
    };

    freeFloorGiB = mkOption {
      type = types.ints.positive;
      default = 200;
      description = ''
        Free space, in GiB, on the filesystem holding {option}`workDir` below
        which every idle target directory is pruned and the hourly run stops
        skipping its scan.
      '';
    };

    schedule = mkOption {
      type = types.str;
      default = "*-*-* 05:00:00";
      example = "*-*-* 04:30:00";
      description = ''
        When the full daily prune runs, as a systemd calendar expression. It
        scans whether or not anything looks wrong, which is what keeps the
        per-crew budgets enforced. The hourly check runs besides it, and most of
        its runs exit after the cheap checks.
      '';
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      default = package;
      defaultText = lib.literalExpression "a writeShellApplication wrapping the module's prune.sh";
      description = ''
        The prune command, on `PATH` for running it by hand.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.pressureIdleHours <= cfg.idleHours;
        message = "services.capyWorkPrune.pressureIdleHours must not exceed idleHours.";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    systemd.services = {
      capy-work-prune = pruneService {
        description = "Prune cargo target directories that are idle or over their crew's budget";
        arguments = [ ];
      };

      capy-work-prune-daily = pruneService {
        description = "Full prune of cargo target directories under the shared work directory";
        arguments = [ "--full" ];
      };
    };

    systemd.timers = {
      # Hourly, so a filesystem that drops below the floor is seen within the
      # hour; the script exits early when there is nothing to do, which keeps the
      # walk over every target directory for the runs that can act on it.
      capy-work-prune = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      capy-work-prune-daily = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
        };
      };
    };
  };
}
