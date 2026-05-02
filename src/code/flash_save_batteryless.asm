SECTION "Flash Save Routines", ROMX[$4000], BANK[$3E]

; Zelda: Link's Awakening DX - Batteryless Save Support
; Minimal behavior: copy SRAM to flash on save, and flash to SRAM on boot.

DEF FLASH_SAVE_BANK0      EQU $44
DEF FLASH_SAVE_BANK_COUNT EQU 4
; Yellow patch uses 0xAAA/0x555 command addresses in fixed CPU space.
DEF FLASH_UNLOCK_ADDR1    EQU $0AAA
DEF FLASH_UNLOCK_ADDR2    EQU $0555
DEF FLASH_UNLOCK_DATA1    EQU $AA
DEF FLASH_UNLOCK_DATA2    EQU $55
DEF FLASH_MODE_REG        EQU $0000
DEF FLASH_MODE_VALUE      EQU $F0
DEF FLASH_WRITE_BASE      EQU $4000
DEF FLASH_POLL_TIMEOUT    EQU $4000
DEF FLASH_ERASE_POLL_TIMEOUT EQU $FFFF
DEF FLASH_ROUTINE_BANK    EQU $3E
; No header/checksum logic (match Yellow-style minimal flow).

CopyFlashToSRAM::
    ld   hl, FlashRestoreRoutineWRAM
    ld   bc, FlashRestoreRoutineWRAMEnd - FlashRestoreRoutineWRAM
    ld   de, wFlashWRAMRoutine
.copy
    ld   a, [hli]
    ld   [de], a
    inc  de
    dec  bc
    ld   a, b
    or   c
    jr   nz, .copy
    call wFlashWRAMRoutine
    ret

; Routine copied to WRAM bank 2. It can freely switch ROMX banks while
; copying the flash save area back to SRAM, then restores bank $3E before ret.
FlashRestoreRoutineWRAM:
    xor  a
    ld   [rRAMG], a
    ld   a, FLASH_SAVE_BANK0
    ld   [rSelectROMBank], a
    ld   a, FLASH_MODE_VALUE
    ld   [FLASH_MODE_REG], a

    ld   hl, FLASH_WRITE_BASE + (SaveGame1 - _SRAM)
    ld   a, [hli]
    cp   $01
    jr   nz, .checkSlot2
    ld   a, [hli]
    cp   $03
    jr   nz, .checkSlot2
    ld   a, [hli]
    cp   $05
    jr   nz, .checkSlot2
    ld   a, [hli]
    cp   $07
    jr   nz, .checkSlot2
    ld   a, [hl]
    cp   $09
    jr   z, .restore

.checkSlot2
    ld   hl, FLASH_WRITE_BASE + (SaveGame2 - _SRAM)
    ld   a, [hli]
    cp   $01
    jr   nz, .checkSlot3
    ld   a, [hli]
    cp   $03
    jr   nz, .checkSlot3
    ld   a, [hli]
    cp   $05
    jr   nz, .checkSlot3
    ld   a, [hli]
    cp   $07
    jr   nz, .checkSlot3
    ld   a, [hl]
    cp   $09
    jr   z, .restore

.checkSlot3
    ld   hl, FLASH_WRITE_BASE + (SaveGame3 - _SRAM)
    ld   a, [hli]
    cp   $01
    jr   nz, .cleanup
    ld   a, [hli]
    cp   $03
    jr   nz, .cleanup
    ld   a, [hli]
    cp   $05
    jr   nz, .cleanup
    ld   a, [hli]
    cp   $07
    jr   nz, .cleanup
    ld   a, [hl]
    cp   $09
    jr   nz, .cleanup

.restore
    xor  a
    ld   [wFlashBankIndex], a

.bankLoop
    ld   a, [wFlashBankIndex]
    ld   [rRAMB], a
    add  a, FLASH_SAVE_BANK0
    ld   [rSelectROMBank], a
    ld   a, CART_SRAM_ENABLE
    ld   [rRAMG], a
    ld   hl, FLASH_WRITE_BASE
    ld   de, $A000
    ld   bc, $2000

.copyLoop
    ld   a, [hli]
    ld   [de], a
    inc  de
    dec  bc
    ld   a, b
    or   c
    jr   nz, .copyLoop

    ld   a, [wFlashBankIndex]
    inc  a
    ld   [wFlashBankIndex], a
    cp   FLASH_SAVE_BANK_COUNT
    jr   nz, .bankLoop

.cleanup
    xor  a
    ld   [rRAMB], a
    ld   [rRAMG], a
    ld   a, FLASH_ROUTINE_BANK
    ld   [rSelectROMBank], a
    ret
FlashRestoreRoutineWRAMEnd:
ASSERT (FlashRestoreRoutineWRAMEnd - FlashRestoreRoutineWRAM) <= $400

; ---------------------------------------------------------
; WRAM routine copied into wFlashWRAMRoutine (bank 2).
; Entire save write loop runs from WRAM so flash can stay busy.
FlashSaveRoutineWRAM:
    push af
    push bc
    push de
    push hl

    ; Enable SRAM
    ld   a, CART_SRAM_ENABLE
    ld   [rRAMG], a
    xor  a
    ld   [rRAMB], a
    xor  a
    ld   [wFlashError], a

    ; Erase 64KB block covering save banks (AMD/FlashGBX sequence)
    xor  a
    ld   [rRAMG], a
    ld   a, FLASH_SAVE_BANK0
    ld   [rSelectROMBank], a
    ld   a, FLASH_MODE_VALUE
    ld   [FLASH_MODE_REG], a
    ld   a, FLASH_UNLOCK_DATA1
    ld   [FLASH_UNLOCK_ADDR1], a
    ld   a, FLASH_UNLOCK_DATA2
    ld   [FLASH_UNLOCK_ADDR2], a
    ld   a, $80
    ld   [FLASH_UNLOCK_ADDR1], a
    ld   a, FLASH_UNLOCK_DATA1
    ld   [FLASH_UNLOCK_ADDR1], a
    ld   a, FLASH_UNLOCK_DATA2
    ld   [FLASH_UNLOCK_ADDR2], a
    ld   a, $30
    ld   [FLASH_WRITE_BASE], a
    ld   bc, FLASH_ERASE_POLL_TIMEOUT
.erase_poll
    ; DQ7/DQ6 toggle poll
    ld   a, [FLASH_WRITE_BASE]
    ld   [wFlashTemp], a
    bit  7, a
    jr   nz, .erase_done
    ld   a, [FLASH_WRITE_BASE]
    ld   hl, wFlashTemp
    xor  [hl]
    bit  6, a
    jr   z, .erase_done
    dec  bc
    ld   a, b
    or   c
    jr   nz, .erase_poll
    ld   a, $01
    ld   [wFlashError], a
.erase_done
    ; Verify erase: first few bytes should read as $FF
    ld   hl, FLASH_WRITE_BASE
    ld   b, $04
.erase_verify
    ld   a, [hl]
    cp   $FF
    jr   z, .erase_verify_next
    ld   a, $01
    ld   [wFlashError], a
    jr   .erase_verify_done
.erase_verify_next
    inc  hl
    dec  b
    jr   nz, .erase_verify
.erase_verify_done
    ld   a, CART_SRAM_ENABLE
    ld   [rRAMG], a
    ld   a, [wFlashError]
    and  a
    jr   nz, .cleanup

    xor  a
    ld   [wFlashBankIndex], a
.bank_loop
    ld   a, [wFlashBankIndex]
    add  a, FLASH_SAVE_BANK0
    ld   [rSelectROMBank], a

    ld   hl, $A000
    ld   de, FLASH_WRITE_BASE
.byte_loop
    ; Ensure SRAM is enabled and the correct SRAM bank is selected
    ld   a, CART_SRAM_ENABLE
    ld   [rRAMG], a
    ld   a, [wFlashBankIndex]
    ld   [rRAMB], a
    ld   a, [hl]
    ld   b, a
    ld   [wFlashTemp], a

    xor  a
    ld   [rRAMG], a
    ld   a, [wFlashBankIndex]
    add  a, FLASH_SAVE_BANK0
    ld   [rSelectROMBank], a
    ld   a, FLASH_MODE_VALUE
    ld   [FLASH_MODE_REG], a
    ld   a, FLASH_UNLOCK_DATA1
    ld   [FLASH_UNLOCK_ADDR1], a
    ld   a, FLASH_UNLOCK_DATA2
    ld   [FLASH_UNLOCK_ADDR2], a
    ld   a, $A0
    ld   [FLASH_UNLOCK_ADDR1], a
    ld   a, b
    ld   [de], a
    ld   bc, FLASH_POLL_TIMEOUT
.prog_poll
    ld   a, [de]
    push hl
    ld   hl, wFlashTemp
    xor  [hl]
    pop  hl
    bit  7, a
    jr   z, .prog_done
    dec  bc
    ld   a, b
    or   c
    jr   nz, .prog_poll
    ld   a, $01
    ld   [wFlashError], a
.prog_done

    ld   a, CART_SRAM_ENABLE
    ld   [rRAMG], a
    ld   a, [wFlashBankIndex]
    ld   [rRAMB], a
    ld   a, [wFlashError]
    and  a
    jr   nz, .cleanup

    inc  hl
    inc  de
    ld   a, h
    cp   $C0
    jr   nz, .byte_loop

    ld   a, [wFlashBankIndex]
    inc  a
    ld   [wFlashBankIndex], a
    cp   FLASH_SAVE_BANK_COUNT
    jr   nz, .bank_loop

.cleanup
    ld   a, FLASH_MODE_VALUE
    ld   [FLASH_MODE_REG], a
    xor  a
    ld   [rRAMB], a
    ld   [rRAMG], a

    ld   a, BANK(FlashLoaderStub)
    ld   [rSelectROMBank], a

    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
FlashSaveRoutineWRAMEnd:

ASSERT (FlashSaveRoutineWRAMEnd - FlashSaveRoutineWRAM) <= $400
