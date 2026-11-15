# Timeline snapshots of /home, a btrfs subvolume of its own. Nested
# subvolumes (.capy, .cache, the toolchains, Downloads) are left out: they
# churn, or can be re-downloaded. Snapshots live in /home/.snapshots.
{ globalUserInfo, ... }:
{
  services.snapper.configs.home = {
    SUBVOLUME = "/home";
    ALLOW_USERS = [ globalUserInfo.userName ];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = 24;
    TIMELINE_LIMIT_DAILY = 7;
    TIMELINE_LIMIT_WEEKLY = 4;
    TIMELINE_LIMIT_MONTHLY = 0;
    TIMELINE_LIMIT_YEARLY = 0;
  };
}
