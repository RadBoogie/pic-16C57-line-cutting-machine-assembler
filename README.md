# Line Cutter Card Program

## Overview
This is an assembler program for a Line Cutter Card, designed to control a motor-driven line cutting system using a Microchip PIC16C57 microcontroller. The program manages the cutting of a line to a specified length based on input from a DIP switch, with each encoder pulse corresponding to 1.8mm of line fed.

- **Author**: Richard Moore
- **Year**: 1997
- **Microcontroller**: PIC16C57
- **Assembler**: MPALC (Use command: `MPALC /P 16C57 CUTTER.ASM`)

## Hardware Setup
- **Port A**: Used for environmental I/O
  - Bit 0: Motor on/off control
  - Bit 1: Revolution pulses (encoder input)
  - Bit 2: Motor inch push button
  - Bit 3: Start button
- **Port B**: Configured as input to read the desired cut length from a DIP switch (8-bit value)
- **Port C**: Controls the solenoid (Bit 0)

## Functionality
- **Initialization**: Configures ports, stops the motor, de-energizes the solenoid, and reads the desired cut length from Port B.
- **Operation**:
  - Polls Port A for inch and start button presses.
  - **Inch Mode**: Briefly activates the motor for manual adjustment when the inch button is pressed.
  - **Cut Mode**: When the start button is pressed, the motor runs, and the program counts encoder pulses (6 pulses = 1 increment of current length). The line is cut when the current length matches the desired length set by the DIP switch.
  - The solenoid is energized to perform the cut, and the motor pauses briefly before resuming for the next cut.
  - The system stops after 10 cuts or if the start button is released.
- **Delays**:
  - Short delay (768µs) for debouncing.
  - Long delay (392ms) for motor and solenoid timing.

## Registers
- `DesiredLength` (0x08): Stores the target length from Port B.
- `CurrentLength` (0x0B): Tracks the current length of the line fed.
- `CurrentPulse` (0x0C): Counts encoder pulses (resets every 6 pulses).
- `CurrentCut` (0x0D): Tracks the number of cuts (up to 10).
- `Delay_1` (0x09), `Delay_2` (0x0A): Used for timing delays.

## Constants
- `Cuts`: 0x0A (10 cuts maximum)
- `Motor`: Bit 0 (Port A)
- `Pulse`: Bit 1 (Port A)
- `Inch`: Bit 2 (Port A)
- `Go`: Bit 3 (Port A)
- `Solenoid`: Bit 0 (Port C)

## How to Use
1. **Assemble the Code**:
   ```bash
   MPALC /P 16C57 CUTTER.ASM
