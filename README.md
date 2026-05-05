# Links Awakening DX Disassembly

I have made batteryless patches for the LADX decompilation. This was a vibe-coded project using Codex. This is a fork of [LADX-Disassembly](https://github.com/zladx/LADX-Disassembly). Also, credits to BennVenn as this was built with learnings from his YouTube video on this subject.

It builds the following ROMs:

- azlj-batteryless.gbc (Japanese, v1.0) `md5: 34a512fa0588ca90cead45af00456109`
- azlj-r1-batteryless.gbc (Japanese, v1.1) `md5: 638917994daad576a775a70228f1fbb7`
- azlj-r2-batteryless.gbc (Japanese, v1.2) `md5: dc81400e3d29981826da95546d62e6dd`
- azlg-batteryless.gbc (German, v1.0) `md5: 894d7a33e977e6a18ba5e9f2908a2728`
- azlg-r1-batteryless.gbc (German, v1.1) `md5: cd34fbb5e14effffc54f79a89d9d3ea7`
- azlf-batteryless.gbc (French, v1.0) `md5: ba90f61352e5f51d1e5c5c030e8dedfc`
- azlf-r1-batteryless.gbc (French, v1.1) `md5: 4d4cebb5379c30d0e6a65f07f82ccc3e`
- azle-batteryless.gbc (English, v1.0) `md5: b72ef7a3917856029810124ba1de91e0`
- azle-r1-batteryless.gbc (English, v1.1) `md5: e070eefd4f922dc49b7c8233f9aa46c8`
- azle-r2-batteryless.gbc (English, v1.2) `md5: cd1527b5cdadff4089b155e79eb1e47a`

## Changes

This fork adds batteryless save support for Link's Awakening DX on flash carts that do not use a battery-backed SRAM save.

The game still writes saves to SRAM through the original save routines, then mirrors the SRAM contents into an unused flash area in the padded ROM. On boot, the ROM restores the saved flash contents back into SRAM before the normal file select flow begins. Should work on carts with the `M29W320` series of flash chips. Support for other flash chips can be added by altering the flash commands in `flash_save_batteryless.asm`.

### Implemented save flows:

- In-game save from the Save and Quit screen
- Game Over: Save and Continue
- Game Over: Save and Quit
- File creation from the name entry screen
- File erase after OK confirmation
- File copy after OK confirmation

### Build changes:

- Adds batteryless ROM outputs for all supported revisions as `*-batteryless.gbc`
- Pads batteryless ROMs to 2 MB
- Stores save data starting at physical ROM offset `0x110000` at the first half of rom bank (for FlashGBX save dumping and injecting on batteryless carts) 
- Adds `make all-batteryless` for build + checksum verification
- Adds `ladx-batteryless.md5` for expected batteryless ROM hashes

The original upstream-style ROM builds and checksum tests are still available separately.

## Usage

1. Install Python 3 and [rgbds](https://github.com/gbdev/rgbds#1-installing-rgbds) (version >= 1.0.0 required);
2. `make all-batteryless`.

This will build both the games and their debug symbols. Once built, use [BGB](https://github.com/zladx/LADX-Disassembly/wiki/Tooling-for-reverse-engineering#bgb) to load the debug symbols into the debugger.


## Resources

For additional documentation and research references, see the upstream repository:
https://github.com/zladx/LADX-Disassembly

## Contributors

This project is based on the work of the original contributors to the upstream repository:
https://github.com/zladx/LADX-Disassembly/graphs/contributors
