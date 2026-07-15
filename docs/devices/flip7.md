# Samsung Galaxy Z Flip7

## State: blocked before bring-up

OpenPhone has **no Flip7 product, recovery image, flash instructions, or
device-specific kernel/device tree**. This is intentional: the device port may
not start until every gate below is evidenced for the exact retail unit.

Current public reporting indicates that Galaxy Z Flip7 firmware based on One UI
8 does not expose user bootloader unlocking. The official LineageOS device list
also has no Flip7 target. This means the port is blocked under the project
policy; do not use an exploit, paid unlocking service, modified boot chain, or
unsigned-image workaround to bypass it.

The exact codename is deliberately marked `pending verification`. Samsung
model numbers and firmware differ by region/carrier, so a marketing name is not
sufficient to name a build target.

## Required evidence before an OpenPhone product can be added

1. Record the retail model, region/carrier, firmware fingerprint, SoC, and
   device codename from the connected handset.
2. Confirm that the stock firmware exposes OEM unlocking and that the supported
   unlock flow completes after a complete encrypted backup. Unlocking must
   visibly wipe the device.
3. Identify an upstream LineageOS branch plus reproducible device tree, kernel
   source, vendor extraction flow, and dynamic-partition layout for that exact
   model.
4. Download and checksum the exact stock firmware and document an Odin/Download
   Mode restoration procedure that has been tested on the same model.
5. Run `scripts/verify-flip7-preflight.sh` with an evidence directory. It must
   pass before any `openphone_flip7` makefile, image, or flash command is added.

## Non-negotiable stop conditions

- no user-supported bootloader unlock;
- no bootable build from matching kernel/device/vendor sources; or
- no documented, tested stock-firmware restoration route.

Any one of these keeps the state `blocked`. The generic `openphone_arm64`
emulator build and the local Bonsai runtime work may continue independently.

## When the gate opens

Create this target only after the preflight succeeds:

- `device/samsung/<verified-codename>` product inheritance and folding/display
  configuration;
- matching kernel and vendor blob extraction instructions;
- recovery and restore documentation;
- SELinux policy and init service for `BonsaiRuntime`;
- hardware acceptance evidence, including both folded and unfolded display and
  touch paths, radios/IMS, camera/audio, encryption, suspend, and recovery.

FlexWindow polish is explicitly later work. It must use device display/fold
configuration, never Samsung proprietary application assumptions.
