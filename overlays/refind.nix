final: prev: {
  # Override or extend the refind package if needed
  refind = prev.refind.overrideAttrs (oldAttrs: {
    # Add your modifications here
    # For example:
    # patches = oldAttrs.patches or [] ++ [ ./my-patch.patch ];
  });

  # Create a reusable refind installer builder
  refindInstaller =
    { nixPath
    , efiBootMgrPath ? final.efibootmgr
    , refindPath ? final.refind
    , efiMountPoint
    , fileSystems
    , luksDevices
    , canTouchEfiVariables
    , efiRemovable
    , maxGenerations
    , hostArchitecture
    , timeout
    , extraConfig
    , additionalFiles
    ,
    }:
    let
      installConfig = final.writeText "refind-install.json" (
        builtins.toJSON {
          inherit
            nixPath
            efiBootMgrPath
            refindPath
            efiMountPoint
            fileSystems
            luksDevices
            canTouchEfiVariables
            efiRemovable
            maxGenerations
            hostArchitecture
            timeout
            extraConfig
            additionalFiles
            ;
        }
      );
    in
    final.replaceVarsWith {
      src = ../modules/nixos/refind/refind-install.py;
      isExecutable = true;
      replacements = {
        python3 = final.python3.withPackages (python-packages: [ python-packages.psutil ]);
        configPath = installConfig;
      };
    };
}
