# RF‑FXTTS Expert Advisor (EA) Documentation

This page provides a complete technical overview of the MetaTrader 4 Expert Advisor included in the RF‑FXTTS project.  
The EA demonstrates how structural principles, risk architecture, and antifragile execution can be implemented in a practical trading system.

---

## 1. Overview

The **RSI_Trend.mq4** Expert Advisor is a rule‑based execution engine that combines:

- structural RSI filtering  
- candlestick pattern recognition  
- ATR‑based volatility‑adaptive risk management  
- account‑level equity protection  
- one‑trade‑per‑symbol discipline  
- automatic breakeven logic  
- real‑time on‑chart monitoring panel  

The EA is not a predictive system.  
It is a **structural execution module** designed to operate within the RF‑FXTTS paradigm of cycle completion, symmetry restoration, and controlled exposure.

EA file location:

---

## 2. Core Logic

### 2.1 RSI Structural Filter
The EA uses two RSI readings to determine structural bias:

- **RSI > Middle (50)** → structural upward pressure  
- **RSI < Middle (50)** → structural downward pressure  
- **RSI < Overbought (60)** → room for continuation  
- **RSI > Oversold (40)** → room for continuation  

This filter prevents trades against structural flow.

---

## 3. Candlestick Pattern Engine

The EA includes recognition for:

### ✔ Pin Bar  
### ✔ Engulfing Pattern  
### ✔ Morning/Evening Star  
### ✔ Hammer  

Patterns are evaluated only when RSI structure allows.

---

## 4. ATR‑Based Risk Architecture

- **Stop Loss = 3 × ATR**  
- **Take Profit = 9 × ATR**  
- **Breakeven activation = 6 × ATR**  

This creates a consistent **1:3 risk‑reward structure** independent of timeframe or symbol.

---

## 5. Breakeven Logic

When price moves **6 × ATR** in profit:

- Stop Loss is moved to entry + buffer  
- Ensures risk‑free continuation  

---

## 6. Account‑Level Equity Protection

- **MaxProfitPercent** → close all trades when reached  
- **MaxLossPercent** → emergency stop  
- Uses global variables to track starting equity  
- Resets automatically after limit hit  

---

## 7. Trade Management Rules

- One trade per symbol  
- Margin check  
- Lot normalization  

---

## 8. On‑Chart Status Panel

Displays:

- equity  
- balance  
- PnL  
- profit/loss limits  
- open/pending orders  
- EA status  

---

## 9. Recommended Usage

- Works on any major FX pair  
- Best on H1–H4  
- Avoids over‑trading  
- Designed for stable, long‑term operation  

---

## 10. File Structure


---

## 11. Purpose Within RF‑FXTTS

This EA is a **reference implementation** showing how:

- structural filters  
- volatility‑adaptive risk  
- antifragile execution  
- symmetry‑aware entries  

can be combined into a practical trading module.

Future versions will integrate:

- K₈ structural deformation metrics  
- cycle‑phase detection  
- symmetry restoration triggers  
- multi‑pair structural mapping  

---

## 12. License

This EA is released under the repository’s license terms.

