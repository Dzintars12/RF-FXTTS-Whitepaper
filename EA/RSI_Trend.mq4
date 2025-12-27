//+------------------------------------------------------------------+
//|                                                    RSI_Trend.mq4 |
//|                                                         Dzintars |
//|                     https://www.mql5.com/ru/users/rav-stein/news |
//+------------------------------------------------------------------+
#property copyright "Dzintars"
#property link      "https://www.mql5.com/ru/users/rav-stein/news"
#property version   "1.00"
#property strict

//==================== Trading Parameters ============================
input double    Lots            = 0.01;    // Lots
input int       MagicNumber     = 123;     
input double    PinBarRatio     = 2.5;     
input int       Slippage        = 3;       // Slippage
input int       ATRPeriod       = 14;      // ATR indicator
input double    ATRMultiplierSL = 3;       // ATR Stop Loss
input double    ATRMultiplierTP = 9;       // ATR Take Profit
extern double   Breakeven       = 6;       // ATR Breakeven

// RSI parameters
input int       RSIPeriod        = 14;     
input double    Overbought       = 60;     
input double    Oversold         = 40;     
input double    Middle           = 50;     
datetime lastBarTime = 0;

//==================== EQUITY LIMIT (Variants B) =====================
input bool      CloseOnLimit     = true;   // Close on profit/loss limit
input bool      CloseWholeAccount= true;   // Variant B: close ALL orders on account
input double    MaxProfitPercent = 1.0;    
input double    MaxLossPercent   = 5.0;    

double gStartEquity = 0.0;

//+------------------------------------------------------------------+
//| StartEquity storage (GlobalVariable)                             |
//+------------------------------------------------------------------+
string StartEquityGVName()
{
   // konta līmenis, neatkarīgi no Magic
   return "RSI_StartEquity_" + IntegerToString(AccountNumber()) + "_WHOLE";
}

void LoadOrInitStartEquity()
{
   string gv = StartEquityGVName();

   if (GlobalVariableCheck(gv))
      gStartEquity = GlobalVariableGet(gv);

   if (gStartEquity <= 0.0)
   {
      gStartEquity = AccountEquity();
      GlobalVariableSet(gv, gStartEquity);
   }
}

void ResetStartEquity()
{
   gStartEquity = AccountEquity();
   GlobalVariableSet(StartEquityGVName(), gStartEquity);
}

double CurrentTotalPnLFromStart()
{
   return (AccountEquity() - gStartEquity); // ietver floating
}

//+------------------------------------------------------------------+
//| Close ALL account orders (market + pending)                      |
//+------------------------------------------------------------------+
bool CloseAllAccountOrders()
{
   bool allOk = true;

   for (int pass = 0; pass < 7; pass++)
   {
      bool didSomething = false;

      for (int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;

         int type = OrderType();
         string sym = OrderSymbol();

         // Pending -> delete
         if (type == OP_BUYLIMIT || type == OP_SELLLIMIT || type == OP_BUYSTOP || type == OP_SELLSTOP)
         {
            if (!OrderDelete(OrderTicket()))
            {
               Print("Failed to delete pending. Ticket=", OrderTicket(), " Err=", GetLastError());
               allOk = false;
            }
            else
               didSomething = true;

            continue;
         }

         // Market -> close
         RefreshRates();
         double price = 0.0;

         if (type == OP_BUY)
            price = MarketInfo(sym, MODE_BID);
         else if (type == OP_SELL)
            price = MarketInfo(sym, MODE_ASK);
         else
            continue;

         if (!OrderClose(OrderTicket(), OrderLots(), price, Slippage, clrNONE))
         {
            Print("Failed to close order. Ticket=", OrderTicket(), " Sym=", sym, " Err=", GetLastError());
            allOk = false;
         }
         else
            didSomething = true;
      }

      if (!didSomething)
         break;
   }

   return allOk;
}

//+------------------------------------------------------------------+
//| Check equity limits and handle                                   |
//+------------------------------------------------------------------+
bool CheckEquityLimitAndHandle()
{
   if (!CloseOnLimit) return false;

   if (gStartEquity <= 0.0)
      LoadOrInitStartEquity();

   double profitLimit = gStartEquity * (MaxProfitPercent / 100.0);
   double lossLimit   = gStartEquity * (MaxLossPercent   / 100.0);

   double pnl = CurrentTotalPnLFromStart();

   // Profit hit
   if (MaxProfitPercent > 0.0 && pnl >= profitLimit)
   {
      Print("MaxProfit reached. StartEquity=", DoubleToString(gStartEquity,2),
            " PnL=", DoubleToString(pnl,2), " -> closing WHOLE account.");

      if (CloseWholeAccount)
         CloseAllAccountOrders();

      ResetStartEquity();
      return true;
   }

   // Loss hit
   if (MaxLossPercent > 0.0 && (-pnl) >= lossLimit)
   {
      Print("MaxLoss reached. StartEquity=", DoubleToString(gStartEquity,2),
            " PnL=", DoubleToString(pnl,2), " -> closing WHOLE account.");

      if (CloseWholeAccount)
         CloseAllAccountOrders();

      ResetStartEquity();
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Status panel on chart                                            |
//+------------------------------------------------------------------+
void DrawStatusPanel()
{
   if (gStartEquity <= 0.0) LoadOrInitStartEquity();

   double equity     = AccountEquity();
   double balance    = AccountBalance();
   double pnl        = equity - gStartEquity;
   double pnlPct     = (gStartEquity > 0.0) ? (pnl / gStartEquity * 100.0) : 0.0;

   double maxProfit  = gStartEquity * (MaxProfitPercent / 100.0);
   double maxLoss    = gStartEquity * (MaxLossPercent   / 100.0);

   int totalOrders = OrdersTotal();
   int marketOrders = 0, pendingOrders = 0;

   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      int t = OrderType();
      if (t == OP_BUY || t == OP_SELL) marketOrders++;
      else if (t == OP_BUYLIMIT || t == OP_SELLLIMIT || t == OP_BUYSTOP || t == OP_SELLSTOP) pendingOrders++;
   }

   string status = "RUNNING";
   if (CloseOnLimit)
   {
      if (MaxProfitPercent > 0.0 && pnl >= maxProfit) status = "PROFIT TARGET HIT";
      else if (MaxLossPercent > 0.0 && (-pnl) >= maxLoss) status = "LOSS LIMIT HIT";
   }

   Comment(
      "==============================\n",
      "RSI Equity Control (WHOLE ACCOUNT)\n",
      "==============================\n",
      "Symbol (this chart): ", Symbol(), "\n",
      "Magic (this chart) : ", MagicNumber, "\n",
      "------------------------------\n",
      "Start Equity : ", DoubleToString(gStartEquity, 2), "\n",
      "Balance      : ", DoubleToString(balance, 2), "\n",
      "Equity       : ", DoubleToString(equity, 2), "\n",
      "------------------------------\n",
      "PnL          : ", DoubleToString(pnl, 2), " (", DoubleToString(pnlPct, 2), "%)\n",
      "------------------------------\n",
      "Max Profit   : +", DoubleToString(maxProfit, 2), " (", DoubleToString(MaxProfitPercent, 2), "%)\n",
      "Max Loss     : -", DoubleToString(maxLoss, 2), " (", DoubleToString(MaxLossPercent, 2), "%)\n",
      "------------------------------\n",
      "CloseOnLimit : ", (CloseOnLimit ? "true" : "false"), "\n",
      "CloseWholeAcc: ", (CloseWholeAccount ? "true" : "false"), "\n",
      "------------------------------\n",
      "Orders Total : ", totalOrders, " (Market=", marketOrders, " Pending=", pendingOrders, ")\n",
      "STATUS       : ", status, "\n",
      "=============================="
   );
}

//+------------------------------------------------------------------+
//| Function to normalize lot size                                  |
//+------------------------------------------------------------------+
double NormalizeLots(double lots)
{
    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

    if (lots < minLot) lots = minLot;
    if (lots > maxLot) lots = maxLot;

    return NormalizeDouble(MathFloor(lots / lotStep) * lotStep, 2);
}

//+------------------------------------------------------------------+
//| Function to check if margin is sufficient                       |
//+------------------------------------------------------------------+
bool IsEnoughMargin(double lots)
{
    double marginRequired = MarketInfo(Symbol(), MODE_MARGINREQUIRED) * lots;
    return (AccountFreeMargin() > marginRequired);
}

//+------------------------------------------------------------------+
//| Check if the candle is a Pin Bar                                |
//+------------------------------------------------------------------+
bool IsPinBar(int index, string direction)
{
   double high = High[index];
   double low = Low[index];
   double open = Open[index];
   double close = Close[index];

   double body = MathAbs(open - close);
   double upperWick = high - MathMax(open, close);
   double lowerWick = MathMin(open, close) - low;

   if (direction == "buy")
      return (lowerWick > body * PinBarRatio && upperWick < body);
   else if (direction == "sell")
      return (upperWick > body * PinBarRatio && lowerWick < body);

   return false;
}

//+------------------------------------------------------------------+
//| Check if the candle is a Morning Star or Evening Star           |
//+------------------------------------------------------------------+
bool IsStarPattern(int index, string direction, bool isDoji)
{
   double open2 = Open[index + 2];
   double close2 = Close[index + 2];
   double open1 = Open[index + 1];
   double close1 = Close[index + 1];
   double open0 = Open[index];
   double close0 = Close[index];

   double body1 = MathAbs(open1 - close1);

   if (direction == "buy")
      return (close2 < open2 && close0 > open0 && body1 < MathAbs(open2 - close2) * 0.3 && (isDoji ? body1 < MathAbs(open1 - close1) * 0.1 : true));
   else if (direction == "sell")
      return (close2 > open2 && close0 < open0 && body1 < MathAbs(open2 - close2) * 0.3 && (isDoji ? body1 < MathAbs(open1 - close1) * 0.1 : true));

   return false;
}

//+------------------------------------------------------------------+
//| Check if the candle is an Engulfing Pattern                     |
//+------------------------------------------------------------------+
bool IsEngulfing(int index, string direction)
{
   double currentOpen = Open[index];
   double currentClose = Close[index];
   double previousOpen = Open[index + 1];
   double previousClose = Close[index + 1];

   if (direction == "buy")
      return (previousOpen > previousClose && currentOpen < previousClose && currentClose > previousOpen);
   else if (direction == "sell")
      return (previousOpen < previousClose && currentOpen > previousClose && currentClose < previousOpen);

   return false;
}

//+------------------------------------------------------------------+
//| Check if the candle is a Hammer                                 |
//+------------------------------------------------------------------+
bool IsHammer(int index, string direction)
{
   double open = Open[index];
   double close = Close[index];
   double high = High[index];
   double low = Low[index];

   double body = MathAbs(open - close);
   double lowerWick = MathMin(open, close) - low;
   double upperWick = high - MathMax(open, close);

   if (direction == "buy")
      return (lowerWick > body * 2.5 && upperWick < body);
   else if (direction == "sell")
      return (upperWick > body * 2.5 && lowerWick < body);

   return false;
}

//+------------------------------------------------------------------+
//| OnInit                                                          |
//+------------------------------------------------------------------+
int OnInit()
{
   LoadOrInitStartEquity();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit                                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
}

//+------------------------------------------------------------------+
//| OnTick                                                          |
//+------------------------------------------------------------------+
void OnTick()
{
   // Status panel always visible
   DrawStatusPanel();

   // Equity limit check FIRST. If hit -> close whole account + reset start equity + return
   if (CheckEquityLimitAndHandle())
      return;

   // New bar filter
   if (iTime(NULL, 0, 0) == lastBarTime)
      return;

   lastBarTime = iTime(NULL, 0, 0);

   TransferToBreakeven();

   // Only one trade at a time per symbol for this Magic
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if (OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
            return;
      }
   }

   double atr = iATR(Symbol(), 0, ATRPeriod, 0);
   double rsi1 = iRSI(Symbol(), 0, RSIPeriod, PRICE_CLOSE, 0);
   double rsi2 = iRSI(Symbol(), 0, RSIPeriod, PRICE_CLOSE, 0);
   double sl, tp;

   // BUY logic
   if (rsi1 > Middle && rsi2 < Overbought)
   {
      if (IsPinBar(1, "buy") && IsEnoughMargin(Lots))
      {
         sl = Bid - ATRMultiplierSL * atr;
         tp = Bid + ATRMultiplierTP * atr;
         OpenBuyOrder(Lots, sl, tp, "Pin Bar Buy", Slippage, MagicNumber);
      }
      else if (IsStarPattern(1, "buy", false) && IsEnoughMargin(Lots))
      {
         sl = Bid - ATRMultiplierSL * atr;
         tp = Bid + ATRMultiplierTP * atr;
         OpenBuyOrder(Lots, sl, tp, "Morning Star Buy", Slippage, MagicNumber);
      }
      else if (IsEngulfing(1, "buy") && IsEnoughMargin(Lots))
      {
         sl = Bid - ATRMultiplierSL * atr;
         tp = Bid + ATRMultiplierTP * atr;
         OpenBuyOrder(Lots, sl, tp, "Bullish Engulfing Buy", Slippage, MagicNumber);
      }
      else if (IsHammer(1, "buy") && IsEnoughMargin(Lots))
      {
         sl = Bid - ATRMultiplierSL * atr;
         tp = Bid + ATRMultiplierTP * atr;
         OpenBuyOrder(Lots, sl, tp, "Bullish Hammer Buy", Slippage, MagicNumber);
      }
   }

   // SELL logic
   if (rsi1 < Middle && rsi2 > Oversold)
   {
      if (IsPinBar(1, "sell") && IsEnoughMargin(Lots))
      {
         sl = Ask + ATRMultiplierSL * atr;
         tp = Ask - ATRMultiplierTP * atr;
         OpenSellOrder(Lots, sl, tp, "Pin Bar Sell", Slippage, MagicNumber);
      }
      else if (IsStarPattern(1, "sell", false) && IsEnoughMargin(Lots))
      {
         sl = Ask + ATRMultiplierSL * atr;
         tp = Ask - ATRMultiplierTP * atr;
         OpenSellOrder(Lots, sl, tp, "Evening Star Sell", Slippage, MagicNumber);
      }
      else if (IsEngulfing(1, "sell") && IsEnoughMargin(Lots))
      {
         sl = Ask + ATRMultiplierSL * atr;
         tp = Ask - ATRMultiplierTP * atr;
         OpenSellOrder(Lots, sl, tp, "Bearish Engulfing Sell", Slippage, MagicNumber);
      }
      else if (IsHammer(1, "sell") && IsEnoughMargin(Lots))
      {
         sl = Ask + ATRMultiplierSL * atr;
         tp = Ask - ATRMultiplierTP * atr;
         OpenSellOrder(Lots, sl, tp, "Bearish Hammer Sell", Slippage, MagicNumber);
      }
   }
}

//+------------------------------------------------------------------+
//| Open a Buy order                                                |
//+------------------------------------------------------------------+
void OpenBuyOrder(double lots, double sl, double tp, string comment, int slippage, int magicNumber)
{
   lots = NormalizeLots(lots);
   int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, slippage, sl, tp, comment, magicNumber, 0, clrGreen);
   if (ticket < 0)
      Print("Error opening buy order: ", GetLastError());
   else
      Print("Buy order opened: ", comment, " Ticket: ", ticket, " SL: ", sl, " TP: ", tp);
}

//+------------------------------------------------------------------+
//| Open a Sell order                                               |
//+------------------------------------------------------------------+
void OpenSellOrder(double lots, double sl, double tp, string comment, int slippage, int magicNumber)
{
   lots = NormalizeLots(lots);
   int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, slippage, sl, tp, comment, magicNumber, 0, clrRed);
   if (ticket < 0)
      Print("Error opening sell order: ", GetLastError());
   else
      Print("Sell order opened: ", comment, " Ticket: ", ticket, " SL: ", sl, " TP: ", tp);
}

//+------------------------------------------------------------------+
//| Transfer to Breakeven based on ATR                              |
//+------------------------------------------------------------------+
void TransferToBreakeven()
{
    bool result;
    double atrValue = iATR(Symbol(), 0, ATRPeriod, 0);
    double buffer = 1 * Point;

    for (int i = 0; i < OrdersTotal(); i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            Print("Failed to select order. Error: ", GetLastError());
            continue;
        }

        if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
            continue;

        double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

        if (OrderType() == OP_BUY)
        {
            if ((Bid - OrderOpenPrice() > Breakeven * atrValue) && (OrderStopLoss() < OrderOpenPrice()))
            {
                double newStopLoss = OrderOpenPrice() + buffer;
                if (MathAbs(OrderOpenPrice() - newStopLoss) < stopLevel)
                {
                    Print("Stop Loss is too close for Buy Ticket: ", OrderTicket());
                    continue;
                }

                result = OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), 0);
                if (!result) Print("Failed to move Buy order to breakeven. Error: ", GetLastError());
                else Print("Buy order moved to breakeven. Ticket: ", OrderTicket(), " New SL: ", newStopLoss);
            }
        }
        else if (OrderType() == OP_SELL)
        {
            if ((OrderOpenPrice() - Ask > Breakeven * atrValue) && (OrderStopLoss() > OrderOpenPrice()))
            {
                double newStopLoss = OrderOpenPrice() - buffer;
                if (MathAbs(OrderOpenPrice() - newStopLoss) < stopLevel)
                {
                    Print("Stop Loss is too close for Sell Ticket: ", OrderTicket());
                    continue;
                }

                result = OrderModify(OrderTicket(), OrderOpenPrice(), newStopLoss, OrderTakeProfit(), 0);
                if (!result) Print("Failed to move Sell order to breakeven. Error: ", GetLastError());
                else Print("Sell order moved to breakeven. Ticket: ", OrderTicket(), " New SL: ", newStopLoss);
            }
        }
    }
}
//+------------------------------------------------------------------+
