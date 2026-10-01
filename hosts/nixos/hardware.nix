{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [
    "nvme" "xhci_pci" "thunderbolt" "usbhid" "uas" "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  systemd.services."mkswap-swap-swapfile".unitConfig.ConditionPathIsMountPoint = "/swap";

  swapDevices = [{
    device = "/swap/swapfile";
    size = 16 * 1024;
  }];

  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [ pkgs.mesa.opencl ];
  };

  hardware.bluetooth.enable = true;

  boot.initrd.systemd.emergencyAccess = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };
}
