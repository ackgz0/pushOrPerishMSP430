# Push or Perish Game 🎮🚦

## **Hardware Components 🛠️**
### **1. Input Buttons 🔘**
- **Player 1:** P2.2  
- **Player 2:** P2.3  

### **2. Output LEDs 💡**
- **Player 1 Indicator:** P2.0  
- **Player 2 Indicator:** P2.1  

### **3. Seven-Segment Display 🖥️**
- **Segment Mapping:**
  - P1.0 = g, P1.1 = f, P2.5 = a, P2.4 = b, P1.4 = e, P1.5 = d, P1.6 = j, P1.7 = dp  

### **4. Timer ⏲️**
- **Timer A0** is used to generate periodic interrupts for countdown and display updates.

---

## **Overview of the Game 🎯**
1. **Countdown Timer ⏱️:**  
   The game begins with a countdown from 3, displayed on the seven-segment display. The timer decrements by 1 every second.  

2. **Manual Reset 🔄:**  
   A player can manually reset the game by pressing their button twice in quick succession.  

3. **Dash Indicator ➖:**  
   When a player wins, a dash (`-`) is displayed on the seven-segment display, indicating the round has ended. After 3 seconds, the game automatically restarts.  

4. **Player Actions 🏆:**  
   Players win or lose based on when they press their buttons, and the result is shown using LEDs.  

---

## **Interrupt Design ⚙️**
- **Timer A0 Interrupt ⏱️:**  
  Manages the countdown timer and updates the seven-segment display.  

- **Button Interrupts 🔘:**  
  Detect and process player actions, such as button presses for winning or resetting the game.  

---

## **Code Structure 🧩**
### **1. Initialization ⚙️**
- The program disables the watchdog timer and configures GPIO pins:
  - Seven-segment display and LEDs are set as outputs.
  - Button pins are set as inputs with pull-up resistors enabled.
- Timer A0 is configured in up mode with a clock divider to generate 0.5-second intervals.

---

### **2. Flags 🚩**
- **R11:** Toggle flag for button presses.  
- **R12:** Timer interrupt count flag for managing 1-second intervals (since Timer A0's max interval is 0.5 seconds).  
- **R13:** Dash flag for displaying a dash on the seven-segment display.  
- **R8:** Manual reset flag for Player 1.  
- **R10:** Manual reset flag for Player 2.  
- **R6:** Dash display timer to ensure the dash shows for 3 seconds.  
- **R7:** Next round phase flag to control game state transitions.  
- **R9:** Zero flag, active when the countdown reaches 0.

---

### **3. Timer A0 Interrupt ⏲️**
- **Countdown Logic:**  
  Decrements the countdown value. If a player presses a button, the game determines a winner or loser, ends the round, and restarts after showing a dash.  

- **Manual Reset 🔄:**  
  Tracks consecutive button presses. If a button is pressed twice quickly, the game immediately resets.  

- **Seven-Segment Update 🖥️:**  
  Calls the `UPDATE_DISPLAY` subroutine to show the current countdown value or dash on the display.  

---

### **4. Button Interrupt 🔘**
- Each button press triggers an interrupt, and the system reacts based on the game's state:
  - **Winning or Losing 🏆:**  
    Depending on the countdown value and flags, the corresponding LED turns on to indicate the winner.
  - **Manual Reset 🔄:**  
    A player pressing their button twice quickly triggers a game reset, starting the countdown from 3.

---

### **5. Seven-Segment Display 🖥️**
- Displays countdown values (3, 2, 1, 0) or a dash (`-`) during special phases:
- **Dash Display ➖:**  
    Indicates the end of a round and lasts for 3 seconds before restarting the game.

---

### **6. Reset Logic 🔄**
- The `RESET_COUNTER` subroutine resets key variables and flags, ensuring a clean restart:
  ```assembly
  mov.w #3, R4 ; Reset countdown
  call #UPDATE_DISPLAY

---

## **Interrupt Vector Table 🗂️**
- **Button Interrupt:** Assigned to .int03.
- **Timer A0 Interrupt:** Assigned to .int09.
- **Reset Vector:** Assigned to .reset (system-level reset, not manual reset).

---

## **Summary of Logic 📜**
- This code implements a competitive game with two players. The seven-segment display counts down from 3, decrementing every second using a timer interrupt. If the countdown reaches 0, it stays there until one player presses their button. The first button press after reaching 0 displays a dash (-) for 3 seconds before restarting the game. Players can also manually reset the game by pressing their button twice quickly. Flags (r7, r9, r11, r13, etc.) manage game states, such as the dash phase, keeping the display at 0, or resetting manually. The timer interrupt handles countdown updates and transitions, while button interrupts track player inputs, determining winners and resetting conditions. The code achieves synchronized gameplay through interrupts and state flags without continuous polling.
