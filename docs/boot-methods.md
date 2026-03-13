# Boot Methods

> **AI Disclosure:** This documentation was written by an AI assistant and may contain errors or inaccuracies. Please verify any configuration options against the source code before use. Items marked `<!-- TODO -->` require human review.

The library provides three pre-configured boot method modules for common hardware targets.

---

## Available Boot Methods

| Output | Target Hardware | Boot Loader |
|--------|----------------|-------------|
| `boot.bios` | Legacy BIOS / MBR systems | GRUB |
| `boot.uefi` | Modern UEFI systems | systemd-boot |
| `boot.rpi` | Raspberry Pi 4 | generic-extlinux |

---

## `boot.bios`

**Source:** `boot-methods/bios.nix`

GRUB-based boot configuration for legacy BIOS systems.

- Installs GRUB to `/dev/sda`
- Configures MBR boot

```nix
# Usage
imports = [ hl1-lib.boot.bios ];
```

> **Note:** The boot device is hardcoded to `/dev/sda`. If your system uses a different disk, you will need to override this after importing. <!-- TODO: Verify the exact override mechanism and whether it can be set via an option -->

---

## `boot.uefi`

**Source:** `boot-methods/uefi.nix`

systemd-boot configuration for UEFI systems.

- Uses `systemd-boot` as the EFI boot manager
- Enables EFI variable management (`efiSysMountPoint`)

```nix
# Usage
imports = [ hl1-lib.boot.uefi ];
```

This is the recommended boot method for most modern x86_64 servers and workstations.

---

## `boot.rpi`

**Source:** `boot-methods/rpi.nix`

Boot configuration for Raspberry Pi 4.

- Loads the appropriate Linux kernel for the RPi 4
- Uses `generic-extlinux-compatible` bootloader (no GRUB or systemd-boot)

```nix
# Usage
imports = [ hl1-lib.boot.rpi ];
```

### Raspberry Pi Setup Notes

- The SD card or USB drive must be partitioned with a FAT32 `/boot/firmware` partition
- <!-- TODO: Add any additional RPi-specific requirements (e.g. firmware files, SD card imaging instructions) -->

---

## Overriding Boot Settings

Boot methods are plain NixOS modules and can be combined with additional configuration:

```nix
{ ... }: {
  imports = [ hl1-lib.boot.uefi ];

  # Override the EFI mount point if different on your system
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Additional kernel parameters
  boot.kernelParams = [ "console=ttyS0,115200" ];
}
```
