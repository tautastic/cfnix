{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          start = "1M";
          size = "2560M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
            extraArgs = [ "-n" "BOOT" ];
          };
        };

        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "ROOT" ];
              subvolumes = {
                "@" = { mountpoint = "/"; };
                "@home" = { mountpoint = "/home"; };
              };
            };
          };
        };
      };
    };
  };
}
