# RF‑FXTTS Whitepaper  
A Topological and Ecosystem‑Based Model of the FX Market

This repository contains the official whitepaper for the **Ricci Flow FX Topological Trading System (RF‑FXTTS)**.

RF‑FXTTS treats the foreign exchange market not as a collection of isolated currency pairs, but as a **closed 8‑currency ecosystem** — a complete graph of 28 structural connections.  
The model describes how pressure, energy and deformation propagate through this structure, and how the system rhythmically restores symmetry through natural cycles.

## Core Concepts

- **8‑Currency Sphere (K₈ Topology)**  
  The FX market is modeled as a closed, simply‑connected topological space where each currency is a node and each pair is an edge.

- **USD‑Centric Toroidal Substructure**  
  The 7 major USD pairs form a torus embedded within the global sphere, creating a dominant but locally unstable loop.

- **Pressure and Energy Flow**  
  External forces (capital flows, policy, macro events) deform the ecosystem.  
  This deformation spreads across all 28 pairs through correlation displacement.

- **Symmetry Restoration (Ricci Flow Analogy)**  
  The system continuously redistributes pressure and returns to equilibrium through rhythmic cycles.

- **Biological Analogy: The Heart**  
  A viable system does not avoid pressure — it absorbs it, distributes it, and restores balance through rhythmic motion.

- **Trading Architecture (RF‑FXTTS)**  
  A systematic approach built on cycle completion, structural symmetry and antifragility.

## Repository Structure

## Expert Advisor (EA)

This project includes a practical MetaTrader 4 Expert Advisor (EA) that demonstrates how structural principles can be applied within an execution architecture.

The EA implements:

- RSI-based structural filtering  
- Candlestick pattern recognition (Pin Bar, Engulfing, Morning/Evening Star)  
- ATR‑based Stop Loss and Take Profit system (3×ATR SL, 9×ATR TP)  
- Automatic breakeven transfer (6×ATR)  
- Account‑level equity protection (MaxProfit%, MaxLoss%)  
- One‑trade‑per‑symbol restriction  
- On‑chart status panel for real‑time monitoring  

The EA file is located at:

