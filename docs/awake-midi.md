# awake-midi

An alternate of the Awake script for Norns, which allows for MIDI CC control of certain parameters.


---
## Manual

Using [Control Change](https://www.midi.org/specifications-old/item/table-3-control-change-messages-data-bytes-2) messages, certain parameters can be modulated.

**Loop Step Data**
Change the step value of the loop's current position. For CC values between `00` and `07` adjust loop 1.

| Control Number (hex) | Control Function   | Value |
|----------------------|--------------------|-------|
| `00`                 | Loop 1 position    | 1     |
| `01`                 | Loop 1 position    | 2     |
| `02`                 | Loop 1 position    | 3     |
| `03`                 | Loop 1 position    | 4     |
| `04`                 | Loop 1 position    | 5     |
| `05`                 | Loop 1 position    | 6     |
| `06`                 | Loop 1 position    | 7     |
| `07`                 | Loop 1 position    | 8     |

For CC values between `00` and `07` adjust loop 2.

| Control Number (hex) | Control Function   | Value |
|----------------------|--------------------|-------|
| `08`                 | Loop 2 position    | 1     |
| `09`                 | Loop 2 position    | 2     |
| `0A`                 | Loop 2 position    | 3     |
| `0B`                 | Loop 2 position    | 4     |
| `0C`                 | Loop 2 position    | 5     |
| `0D`                 | Loop 2 position    | 6     |
| `0E`                 | Loop 2 position    | 7     |
| `0F`                 | Loop 2 position    | 8     |

**Loop Length**
Change the length of the loops.

| Control Number (hex) | Control Function   | Value |
|----------------------|--------------------|-------|
| `10`                 | Loop 1 length      | 1     |
| `11`                 | Loop 1 length      | 2     |
| `12`                 | Loop 1 length      | 3     |
| `13`                 | Loop 1 length      | 4     |
| `14`                 | Loop 1 length      | 5     |
| `15`                 | Loop 1 length      | 6     |
| `16`                 | Loop 1 length      | 7     |
| `17`                 | Loop 1 length      | 8     |
| `18`                 | Loop 1 length      | 9     |
| `19`                 | Loop 1 length      | 10    |
| `1A`                 | Loop 1 length      | 11    |
| `1B`                 | Loop 1 length      | 12    |
| `1C`                 | Loop 1 length      | 13    |
| `1D`                 | Loop 1 length      | 14    |
| `1E`                 | Loop 1 length      | 15    |
| `1F`                 | Loop 1 length      | 16    |
|                      |                    |       |
| `20`                 | Loop 2 length      | 1     |
| `21`                 | Loop 2 length      | 2     |
| `22`                 | Loop 2 length      | 3     |
| `23`                 | Loop 2 length      | 4     |
| `24`                 | Loop 2 length      | 5     |
| `25`                 | Loop 2 length      | 6     |
| `26`                 | Loop 2 length      | 7     |
| `27`                 | Loop 2 length      | 8     |
| `28`                 | Loop 2 length      | 9     |
| `29`                 | Loop 2 length      | 10    |
| `2A`                 | Loop 2 length      | 11    |
| `2B`                 | Loop 2 length      | 12    |
| `2C`                 | Loop 2 length      | 13    |
| `2D`                 | Loop 2 length      | 14    |
| `2E`                 | Loop 2 length      | 15    |
| `2F`                 | Loop 2 length      | 16    |


**Step Length**
Change the length of the steps.

| Control Number (hex) | Control Function   | Value |
|----------------------|--------------------|-------|
| `30`                 | Step length        | 1 bar |
| `31`                 | Step length        | 1/2   |
| `32`                 | Step length        | 1/3   |
| `33`                 | Step length        | 1/4   |
| `34`                 | Step length        | 1/6   |
| `35`                 | Step length        | 1/8   |
| `36`                 | Step length        | 1/12  |
| `37`                 | Step length        | 1/16  |
| `38`                 | Step length        | 1/24  |
| `39`                 | Step length        | 1/32  |
| `3A`                 | Step length        | 1/48  |
| `3B`                 | Step length        | 1/64  |


**Root Note**
Change the root note. This uses 2 commands to change the note, the first must be a CC message `40` immediately followed by a `noteon` message, to set the root note.

| Control Number (hex) | Control Function      | Value |
|----------------------|-----------------------|-------|
| `40`                 | Root note change arm  | 1 bar |


**Scale Mode**
Change the scale mode. Not every possible scale is supported only the 16 listed below. You can tweak yourself, reference [MusicUtil.SCALES](https://github.com/markwheeler/norns/blob/master/lua/lib/musicutil.lua) and update the `on_midi_event` function to your needs.

| Control Number (hex) | Control Function   | Value            |
|----------------------|--------------------|------------------|
| `50`                 | Scale mode         | Major            |
| `51`                 | Scale mode         | Natural Minor    |
| `52`                 | Scale mode         | Harmonic Minor   |
| `53`                 | Scale mode         | Melodic Minor    |
| `54`                 | Scale mode         | Dorian           |
| `55`                 | Scale mode         | Phrygian         |
| `56`                 | Scale mode         | Lydian           |
| `57`                 | Scale mode         | Mixolydian       |
| `58`                 | Scale mode         | Locrian          |
| `59`                 | Scale mode         | Gypsy Minor      |
| `5A`                 | Scale mode         | Whole Tone       |
| `5B`                 | Scale mode         | Major Pentatonic |
| `5C`                 | Scale mode         | Minor Pentatonic |
| `5D`                 | Scale mode         | Blues Scale      |
| `5E`                 | Scale mode         | Arabian          |
| `5F`                 | Scale mode         | Chromatic        |


---
## Change log

**2.2.1 @frederickk**
- Refactored code for improved readability
- Added ability to control certain parameters with MIDI CC commands
- Implemented 'awake.pset' for reading/writing parameters
