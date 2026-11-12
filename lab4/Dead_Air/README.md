# Dead Air

A three-station Morse radio game for the Digilent Basys 3 (XC7A35T-1CPG236C, 100 MHz). This reference implementation follows the Dead Air proposal by Sachin Raja and Judas Lopez for UCLA CS M152A Lab 4. Start with the hardware connections and Vivado steps below.

## Connect the board

Turn board power off before connecting the modules. Match pin 1 on each Pmod to pin 1 on its Basys 3 header. JA and JC use the six positions numbered 1–6. The keypad occupies both rows of JB.

| Basys 3 | Module in the lab photo | Connections |
| --- | --- | --- |
| JA | Original PmodJSTK, six-pin SPI joystick | JA1 CS, JA2 MOSI, JA3 MISO, JA4 SCK, JA5 GND, JA6 3.3 V |
| JB | PmodKYPD, 16-key hexadecimal keypad | JB1–4 connect to COL4 through COL1. JB7–10 connect to ROW4 through ROW1. Align the full 12-pin plug. |
| JC | PmodAMP2 audio amplifier | JC1 AIN, JC2 GAIN, JC3 unused, JC4 active-low shutdown, JC5 GND, JC6 3.3 V. Plug the lab's compatible mono speaker into the amplifier's audio jack. |

The game's display is the four-digit display built into the Basys 3. The separate two-digit PmodSSD and Pmod button board in the photo can stay in the kit. If the JSTK's J1 is six bare holes, get a header-equipped module or a suitable connector from the lab before testing.

## Open, simulate and program in Vivado

1. Unzip the whole folder to a writable location. In a fresh Vivado session, open **Window → Tcl Console**. Type `cd `, then the path to the extracted **Dead_Air** folder inside braces. For example, `cd {C:/FPGA/Dead_Air}`.
2. Run `source create_project.tcl`. This selects `xc7a35tcpg236-1`, adds the RTL, constraints and simulation files, and creates `build/dead_air.xpr`. The project references the source folders next to `build`. Keep them together.
3. Choose **Run Simulation → Run Behavioral Simulation**. The top is `tb_dead_air`. If the simulator stops at its default time limit, type `run all` in its Tcl console. Look for **PASS Dead Air: all five suites**. Close the simulation before building.
4. Choose **Generate Bitstream** and allow synthesis and implementation to run. Check the implementation timing summary for the 10 ns clock. Connect the Basys 3's USB programming port, turn it on, open **Hardware Manager → Open Target → Auto Connect**, and choose **Program Device**. The generated file is `build/dead_air.runs/impl_1/dead_air_top.bit`.
5. Press the upper button, release it, set the difficulty, and press the center button to play. To share the working Vivado project, use **File → Project → Archive** so that the relative source files travel with it.

## First round on the board

1. Leave SW2, SW1 and SW0 down. Press center. The display reads **000**. Move up once and release to get **010**, then move right once to get **011**. If the axes are rotated or reversed in the way you are holding the joystick, check the orientation settings below.
2. Tune to **137**. On Easy, **135–139** all lock. LD8 lights and the first digit sounds as four short beeps followed by one long beep. Let a whole message repeat to hear the boundaries.
3. Switch the display to entry (SW1 up, SW0 down). Type **482** and press **A**. LD9 lights, the entry clears and the audio stops. Switch back to frequency to tune the next station.
4. At **482**, enter **756** and press **A**. At **756**, enter **029** and press **A**. LD15 and all three progress LEDs light at the win. The upper button resets the round.
5. For a quick loss test, start Hard, tune to exactly **137**, enter **000**, and tap **A** repeatedly, releasing between presses. Each new press deducts ten seconds. The clock stops at zero and LD14 lights.

### Controls

| Control | Action |
| --- | --- |
| Joystick left / right | Subtract / add 1. Hold to repeat. |
| Joystick up / down | Add / subtract 10. Vertical wins on a diagonal. Range is 000–999. |
| Keypad 0–9 | Append up to three digits. Leading zeros count. |
| Keypad A / B / C | Submit / backspace / clear. D, E and F are unused. |
| Center / upper button | Start, pause or resume / reset to Idle. |
| SW2 before start | Down selects Easy (180 seconds, ±2). Up selects Hard (120 seconds, exact). |
| SW1 SW0 | 00 frequency, 01 seconds, 10 keypad entry, 11 station number. |

LD0–LD7 show increasing signal strength. LD8 indicates a lock. LD9–LD11 show one, two or three completed stations. LD12 is pause, LD13 is a one-second error indication, LD14 is loss and LD15 is win. A complete wrong answer stays on the display for correction. An incomplete or off-station submission leaves the entry in place and costs no time. A regular second tick still counts during play. If time runs out on the clock edge of a final answer, the player loses.

### Morse card for players

| Digit | Morse | Digit | Morse |
| --- | --- | --- | --- |
| 0 | `-----` | 5 | `.....` |
| 1 | `.----` | 6 | `-....` |
| 2 | `..---` | 7 | `--...` |
| 3 | `...--` | 8 | `---..` |
| 4 | `....-` | 9 | `----.` |

A dot lasts 150 ms and a dash lasts 450 ms. The silent intervals are 150 ms between symbols, 450 ms between digits and 1,050 ms between messages. The first digit starts over after pause or loss of lock. In this implementation the tone is about 700 Hz.

## Source map

| File | Responsibility |
| --- | --- |
| `rtl/dead_air_top.v` | Board ports, millisecond enable, synchronization, button debounce and status LEDs. |
| `rtl/joystick.v` | Five-byte mode-0 SPI read, joystick dead zone, direction priority and repeat events. |
| `rtl/keypad.v` | Matrix scanning, three-frame debounce and one event per press/release. |
| `rtl/game.v` | Station records, tuning limits, signal strength, entry, countdown, penalties and game states. |
| `rtl/audio.v` | Morse symbols and spacing, 700 Hz tone, 8-bit PWM and AMP2 control. |
| `rtl/display.v` | Binary-to-decimal conversion, digit blanking and display multiplexing. |
| `constraints/basys3.xdc` | Board pin assignments and the 100 MHz clock constraint. |
| `sim/` | Self-checking SystemVerilog tests. `tb_dead_air.sv` runs all five suites. |

The example frequencies 137, 482 and 756 come from the approved proposal. The final code **029** was chosen for this implementation to exercise leading-zero input. Change the three records in `game.v` to design a different puzzle, and update the reference answers in the tests to match. The second and third frequencies should match the preceding messages.

The joystick polls around every 10 ms. Values from 324 through 700 are neutral on each axis. A held direction repeats approximately every 110–125 ms, depending on poll phase. With the joystick header facing away from the player, check all four directions on the frequency display. If needed, `SWAP_XY`, `INVERT_X` and `INVERT_Y` in `dead_air_top.v` adapt the mapping to your module's physical orientation. Rebuild the bitstream after changing them.

## Verification

All five suites passed under Icarus Verilog 12.0. The end-to-end test reads SPI bytes from a joystick model, closes individual contacts in a keypad matrix model, operates the board buttons and reaches Won through real top-level interfaces. It also checks transmitted SPI bytes and clock timing. The other suites cover Easy and Hard lock boundaries, timeout versus final submit, saturating penalties, pause, all 16 keypad positions, all ten Morse digits, mark/gap durations, amplifier PWM and display values from 000 through 999.

The production top also synthesized for Xilinx 7-series using Yosys 0.52. The structural check reported zero problems and the netlist contained four tri-state column output buffers. Physical Pmod response, speaker loudness, Vivado place-and-route and 100 MHz timing closure still need to be checked on the lab setup. Use the first-round steps to record your own demo results.

To rerun the simulation on a machine with Icarus installed, run these commands from this folder.

```sh
iverilog -g2012 -Wall -s tb_dead_air -o dead_air_sim rtl/*.v sim/*.sv
vvp dead_air_sim
```

To capture waveforms for the report in Vivado, add `frequency`, `locked`, `tone`, `entry`, `completed` and `seconds` from `tb_dead_air/board_suite/dut`. Restart and run the simulation with those signals logged. For a close-up of mark and gap timing, inspect `tb_dead_air/audio_suite/dut`. That unit test uses four clock cycles per Morse unit so all ten digits can be tested quickly.

## References and credit

The CS M152A Lab 4 slides ask teams to write their own project. Identify any portions your team uses in the report and distinguish simulation results from your own board measurements.

- [Digilent Basys 3 master constraints](https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc)
- [Digilent PmodJSTK reference manual](https://digilent.com/reference/_media/reference/pmod/pmodjstk/pmodjstk_rm.pdf) and [legacy SPI timing specification](https://www.datasheets.com/digilent/410-116/datasheet.pdf)
- [Digilent PmodKYPD reference manual](https://digilent.com/reference/_media/pmod%3Apmod%3ApmodKYPD_rm.pdf)
- [Digilent PmodAMP2 reference manual](https://digilent.com/reference/_media/pmod%3Apmod%3ApmodAMP2_rm.pdf)
- [ITU-R M.1677-1 international Morse code](https://www.itu.int/rec/R-REC-M.1677-1-200910-I/en)
