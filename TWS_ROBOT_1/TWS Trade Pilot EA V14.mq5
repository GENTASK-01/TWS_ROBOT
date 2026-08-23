//+------------------------------------------------------------------+
//|                                     TWS Trade Pilot EA V14.mq5   |
//|                         Multi Strategy v14 - AUTO SWITCH TF      |
//|                                                                  |
//|  Reconstructed complete source of "TWS Trade Pilot EA V14"      |
//|  Fully reproduces the execution workflow captured in the        |
//|  backtest journals (TWS_LOGS_1.txt / TWS_LOGS_2.txt) generated  |
//|  by "TWS Trade Pilot EA V14.ex5" on MetaTrader 5 build 6140.    |
//|                                                                  |
//|  WORKFLOW (per tick):                                            |
//|   1. Position count monitor  (external change / partial close)   |
//|   2. Group Break-Even activation check                           |
//|   3. SL Monitor update + server-side SL + client-side SL check   |
//|   4. Trade logic (initial entry / martingale / pyramid)          |
//|   5. Position count monitor (post-trade)                         |
//|   6. Trailing stop activation / hit check                        |
//|   7. Cut-loss safety net                                         |
//+------------------------------------------------------------------+
#property copyright   "TWS"
#property link        ""
#property version     "14.0"
#property description "TWS Trade Pilot EA V14 - Multi Strategy with AI based timeframe switch,"
#property description "Group Break Even protection, client-side SL monitor, martingale & pyramid"
#property description "grids, CloseBy hedge optimization and aggressive force-close engine."

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_TRADE_DIRECTION
  {
   DIRECTION_NORMAL    = 0,   // Normal (Buy & Sell)
   DIRECTION_BUY_ONLY  = 1,   // Buy
   DIRECTION_SELL_ONLY = 2    // Sell
  };

enum ENUM_ENTRY_MODE
  {
   ENTRY_TREND_AREA = 0,      // Trend Area Mode
   ENTRY_CROSSOVER  = 1       // Crossover Mode
  };

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "===== AI BASED TIMEFRAME SWITCH ====="
input bool              InpEnableAutoSwitchTF     = true;        // Enable Auto Switch Timeframe
input ENUM_TIMEFRAMES   InpEntryTimeframe         = PERIOD_M1;   // Entry Timeframe (for initial position)
input ENUM_TIMEFRAMES   InpManagementTimeframe    = PERIOD_H1;   // Management Timeframe (after position opened)

input group "===== CORE SETTINGS ====="
input long              InpMagicNumber            = 202501;

input group "===== TRADING DIRECTION ====="
input ENUM_TRADE_DIRECTION InpTradingDirection    = DIRECTION_NORMAL;

input group "===== RISK FILTERS ====="
input bool              EnableFilterClock         = false;
input int               InpTradingStartTime       = 9;
input int               InpMinutesStartTrading    = 0;
input int               InpMinutesEndTrading      = 17;
input int               InpMinutesCompleteTrading = 0;
input bool              InpEnableLeverageFilter   = false;
input int               InpMinimalLeverage        = 2000;

input group "===== SPREAD & SLIPPAGE CONTROL ====="
input bool              InpEnableSpreadFilter     = true;
input int               InpMaximumSpread          = 300;
input bool              InpEnableSlippageControl  = false;
input int               InpMaximumSlippage        = 30;

input group "===== EMA TREND SETTINGS ====="
input int               InpEmaPeriod              = 5;
input int               InpEmaShift               = 0;
input ENUM_MA_METHOD    InpEmaMethod              = MODE_SMA;
input ENUM_APPLIED_PRICE InpEmaPrice              = PRICE_CLOSE;

input group "===== INITIAL ENTRY SETTINGS ====="
input ENUM_ENTRY_MODE   InpEntryMode              = ENTRY_TREND_AREA;
input double            InpInitialLot             = 0.01;
input bool              InpEnableEmaDistanceFilter= false;
input int               InpMaxDistancePoints      = 1000;
input bool              InpEnableRsiCounterTrend  = false;

input group "===== MAX LOT LIMITER ====="
input bool              InpEnableMaxLot           = true;
input double            InpMaxLotSize             = 0.1;
input bool              InpStopTradingAtMaxLot    = false;

input group "===== CLOSEBY & HEDGE SETTINGS ====="
input bool              InpEnableCloseBy          = true;
input bool              InpCloseByBeforeRegular   = true;
input int               InpCloseByMaxAttempts     = 3;
input int               InpCloseByRetryDelayMs    = 50;
input bool              InpEnableCloseByLogging   = true;

input group "===== PYRAMIDING SETTINGS (Profit Mode) ====="
input bool              InpPyramidEnabled         = true;
input int               InpPyramidTriggerPoints   = 1500;
input double            InpPyramidLotMultiplier   = 1.0;
input int               InpMaxPyramidOrders       = 100;

input group "===== MARTINGALE SETTINGS (Loss Mode) ====="
input bool              InpEnableMartingale       = true;
input bool              InpEnableMartingaleRsiFilter = false;
input int               InpMartingaleDistancePoints  = 400;
input double            InpMartingaleLotMultiplier   = 1.1;
input int               InpMartingaleMaxOrders    = 1000;

input group "===== RSI INDICATOR SETTINGS ====="
input int               InpRsiPeriod              = 14;
input ENUM_APPLIED_PRICE InpRsiPrice              = PRICE_CLOSE;
input double            InpRsiOverboughtLevel     = 70.0;
input double            InpRsiOversoldLevel       = 30.0;

input group "===== CUT LOSS (SAFETY NET) ====="
input bool              InpEnableCutLoss          = false;
input double            InpCutLossUSD             = 1000.0;

input group "===== GROUP BREAK EVEN PROTECTION ====="
input bool              InpEnableGroupBEP         = true;
input int               InpGroupBEP_MinOrders     = 1;
input int               InpGroupBEP_TriggerPoints = 500;
input int               InpGroupBEP_LockPoints    = 500;

input group "===== TRAILING STOP SETTINGS ====="
input bool              InpTrailingEnabled        = true;
input int               InpTrailingTriggerPoints  = 600;
input int               InpTrailingDistancePoints = 500;
input bool              InpCloseAllOnTrailingHit  = true;

input group "===== ADVANCED PROTECTION ====="
input bool              InpEnableClientSideSL     = true;
input int               InpClientSLBufferPoints   = 10;
input int               InpMaxCloseAttempts       = 10;
input int               InpCloseRetryDelayMs      = 100;
input bool              InpEnablePanicMode        = true;
input int               InpPanicModeThreshold     = 5;

input group "===== DEBUG & LOGGING ====="
input bool              InpEnableDetailedLog      = true;
input bool              InpEnableTradeHistory     = true;

//+------------------------------------------------------------------+
//| Log separator constants (verbatim widths)                        |
//+------------------------------------------------------------------+
const string SEP_EQ40    = "========================================";
const string SEP_DEQ39   = "═══════════════════════════════════════";
const string SEP_DASH39  = "───────────────────────────────────────";
const string SEP_DASH37  = "─────────────────────────────────────";
const string BOX_TOP     = "╔═══════════════════════════════════════╗";
const string BOX_BOTTOM  = "╚═══════════════════════════════════════╝";
const string SBOX_TOP    = "┌─────────────────────────────────────┐";
const string SBOX_MID    = "├─────────────────────────────────────┤";
const string SBOX_BOTTOM = "└─────────────────────────────────────┘";

//+------------------------------------------------------------------+
//| Timeframe mode                                                   |
//+------------------------------------------------------------------+
enum ENUM_TF_MODE
  {
   TF_MODE_ENTRY = 0,
   TF_MODE_MANAGEMENT = 1
  };

//+------------------------------------------------------------------+
//| Globals                                                          |
//+------------------------------------------------------------------+
CTrade      g_trade;
int         g_emaHandle          = INVALID_HANDLE;
int         g_rsiHandle          = INVALID_HANDLE;

// --- bar tracking
datetime    g_lastBarTime        = 0;
bool        g_isNewBar           = false;

// --- cycle tracking
int         g_cycleDirection     = -1;          // POSITION_TYPE_BUY / POSITION_TYPE_SELL / -1 none
double      g_lastGridPrice      = 0.0;         // reference price of last grid order (bid at trigger)
double      g_lastLot            = 0.0;         // lot of most recent open
int         g_martingaleCount    = 0;
int         g_pyramidCount       = 0;
double      g_maxLotUsed         = 0.0;
bool        g_maxLotReached      = false;

// --- trading lock
bool        g_tradingLocked      = false;

// --- lifetime statistics
int         g_totalTradesOpened  = 0;
int         g_totalTradesClosed  = 0;
double      g_totalProfit        = 0.0;

// --- position count monitor
int         g_lastPositionCount  = 0;
ulong       g_knownTickets[];

// --- group BEP / SL monitor
bool        g_slMonitorActive    = false;
int         g_slDirection        = -1;
double      g_slTargetPrice      = 0.0;
double      g_slAvgEntry         = 0.0;
ulong       g_slInitialTickets[];
int         g_slPassSuccess      = 0;
int         g_slPassFailed       = 0;

// --- trailing stop
bool        g_trailingActive     = false;
double      g_trailingPeakPoints = 0.0;

// --- timeframe mode
ENUM_TF_MODE g_tfMode            = TF_MODE_ENTRY;

// --- force close snapshot
ulong       g_snapTickets[];
int         g_snapTypes[];
double      g_snapPrices[];
double      g_snapLots[];
double      g_snapSLs[];
double      g_snapProfits[];
int         g_snapCount          = 0;
double      g_snapProfitSum      = 0.0;

//+------------------------------------------------------------------+
//| Helpers - mode strings                                           |
//+------------------------------------------------------------------+
string ModeText()
  {
   switch(InpTradingDirection)
     {
      case DIRECTION_BUY_ONLY:  return("BUY ONLY ⬆️");
      case DIRECTION_SELL_ONLY: return("SELL ONLY ⬇️");
      default:                  return("NORMAL ⬆️⬇️");
     }
  }

string ModeTag()
  {
   switch(InpTradingDirection)
     {
      case DIRECTION_BUY_ONLY:  return("[BUY]");
      case DIRECTION_SELL_ONLY: return("[SELL]");
      default:                  return("[NORMAL]");
     }
  }

//+------------------------------------------------------------------+
//| Helpers - timeframe to string ("M1","H1","CURRENT",...)          |
//+------------------------------------------------------------------+
string TfToString(const ENUM_TIMEFRAMES tf)
  {
   string s = EnumToString(tf);
   StringReplace(s, "PERIOD_", "");
   return(s);
  }

//+------------------------------------------------------------------+
//| Helpers - sleep that is safe under optimization                  |
//+------------------------------------------------------------------+
void SafeSleep(const int ms)
  {
   if(ms > 0 && !MQLInfoInteger(MQL_OPTIMIZATION))
      Sleep(ms);
  }

//+------------------------------------------------------------------+
//| Helpers - filling mode selection                                 |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING AutoFillingMode()
  {
   long flags = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((flags & SYMBOL_FILLING_IOC) != 0)
      return(ORDER_FILLING_IOC);
   if((flags & SYMBOL_FILLING_FOK) != 0)
      return(ORDER_FILLING_FOK);
   return(ORDER_FILLING_RETURN);
  }

void PrepareTradeForOpen()
  {
   g_trade.SetTypeFilling(AutoFillingMode());
   if(InpEnableSlippageControl)
      g_trade.SetDeviationInPoints((ulong)InpMaximumSlippage);
   else
      g_trade.SetDeviationInPoints((ulong)100000000);
  }

void PrepareTradeForClose(const int stage)
  {
   // Stage 1 uses the strict all-or-nothing FOK request first; from stage 2
   // onwards the symbol-supported filling mode is used as fallback.
   if(stage <= 1)
      g_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else
      g_trade.SetTypeFilling(AutoFillingMode());
   if(InpEnableSlippageControl)
      g_trade.SetDeviationInPoints((ulong)InpMaximumSlippage);
   else
      g_trade.SetDeviationInPoints((ulong)100000000);
  }

//+------------------------------------------------------------------+
//| Helpers - own position utilities                                 |
//+------------------------------------------------------------------+
bool IsOwnPosition(const ulong ticket)
  {
   if(ticket == 0)
      return(false);
   if(!PositionSelectByTicket(ticket))
      return(false);
   if(PositionGetString(POSITION_SYMBOL) != _Symbol)
      return(false);
   if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
      return(false);
   return(true);
  }

int CountOwnPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(IsOwnPosition(ticket))
         count++;
     }
   return(count);
  }

double SumOwnFloatingProfit()
  {
   double total = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(IsOwnPosition(ticket))
         total += PositionGetDouble(POSITION_PROFIT);
     }
   return(total);
  }

//+------------------------------------------------------------------+
//| Helpers - group averages / profit in points                      |
//+------------------------------------------------------------------+
bool RecalcGroupAverages(double &avgEntry, int &direction, int &count)
  {
   double lotSum = 0.0, weighted = 0.0;
   direction = -1;
   count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!IsOwnPosition(ticket))
         continue;
      double lot = PositionGetDouble(POSITION_VOLUME);
      weighted += PositionGetDouble(POSITION_PRICE_OPEN) * lot;
      lotSum   += lot;
      if(direction < 0)
         direction = (int)PositionGetInteger(POSITION_TYPE);
      count++;
     }
   if(count == 0 || lotSum <= 0.0)
      return(false);
   avgEntry = weighted / lotSum;
   return(true);
  }

double GroupProfitPoints(const double avgEntry, const int direction)
  {
   double pnt = _Point;
   if(pnt <= 0.0)
      return(0.0);
   if(direction == POSITION_TYPE_BUY)
      return((SymbolInfoDouble(_Symbol, SYMBOL_BID) - avgEntry) / pnt);
   return((avgEntry - SymbolInfoDouble(_Symbol, SYMBOL_ASK)) / pnt);
  }

//+------------------------------------------------------------------+
//| Helpers - lot normalization with max-lot limiter                 |
//+------------------------------------------------------------------+
double NormalizeLotSize(const double requested, bool &adjusted)
  {
   double lot = requested;

   if(InpEnableMaxLot && lot > InpMaxLotSize)
     {
      if(!g_maxLotReached)
        {
         Print(SEP_DEQ39);
         Print("⚠️ MAX LOT LIMIT REACHED");
         Print(SEP_DEQ39);
         Print("Requested lot capped at: ", InpMaxLotSize);
         Print(SEP_DEQ39);
         g_maxLotReached = true;
        }
      lot = InpMaxLotSize;
     }

   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step > 0.0)
      lot = MathRound(lot / step) * step;
   if(lot < vmin)
      lot = vmin;
   if(lot > vmax)
      lot = vmax;
   lot = NormalizeDouble(lot, 8);

   adjusted = (MathAbs(lot - requested) > 1.0e-12);
   return(lot);
  }

//+------------------------------------------------------------------+
//| Helpers - trading lock                                           |
//+------------------------------------------------------------------+
void LockTrading(const string reason)
  {
   g_tradingLocked = true;
   Print(SEP_DEQ39);
   Print("🔒 TRADING LOCKED");
   Print("Mode: ", ModeText());
   Print("Reason: ", reason);
   Print("Timestamp: ", TimeToString(TimeCurrent()));
   Print(SEP_DEQ39);
  }

void UnlockTrading(const string reason)
  {
   g_tradingLocked = false;
   Print(SEP_DEQ39);
   Print("🔓 TRADING UNLOCKED");
   Print("Mode: ", ModeText());
   Print("Reason: ", reason);
   Print(SEP_DEQ39);
  }

//+------------------------------------------------------------------+
//| Helpers - cycle reset                                            |
//+------------------------------------------------------------------+
void ResetCycleTracking()
  {
   g_cycleDirection     = -1;
   g_lastGridPrice      = 0.0;
   g_lastLot            = 0.0;
   g_martingaleCount    = 0;
   g_pyramidCount       = 0;
   g_maxLotUsed         = 0.0;
   g_maxLotReached      = false;

   g_slMonitorActive    = false;
   g_slDirection        = -1;
   g_slTargetPrice      = 0.0;
   g_slAvgEntry         = 0.0;
   ArrayFree(g_slInitialTickets);
   g_slPassSuccess      = 0;
   g_slPassFailed       = 0;

   g_trailingActive     = false;
   g_trailingPeakPoints = 0.0;

   Print("🔄 All tracking variables reset - Mode: ", ModeText());
  }

//+------------------------------------------------------------------+
//| Helpers - timeframe switching                                    |
//+------------------------------------------------------------------+
bool AttemptSwitchTimeframe(const ENUM_TIMEFRAMES tf, const bool toManagement)
  {
   if(Period() == tf)
     {
      if(toManagement)
        {
         Print("✓ Already on Management Timeframe: ", TfToString(tf));
         g_tfMode = TF_MODE_MANAGEMENT;
        }
      else
        {
         Print("✓ Already on Entry Timeframe: ", TfToString(tf));
         g_tfMode = TF_MODE_ENTRY;
        }
      return(true);
     }

   if(ChartSetSymbolPeriod(0, _Symbol, tf))
     {
      if(toManagement)
        {
         Print("✓ Switched to Management Timeframe: ", TfToString(tf));
         g_tfMode = TF_MODE_MANAGEMENT;
        }
      else
        {
         Print("✓ Switched to Entry Timeframe: ", TfToString(tf));
         g_tfMode = TF_MODE_ENTRY;
        }
      return(true);
     }

   if(toManagement)
      Print("⚠️ Failed to switch to Management Timeframe: ", TfToString(tf));
   else
      Print("⚠️ Failed to switch to Entry Timeframe: ", TfToString(tf));
   return(false);
  }

void SwitchToManagementTimeframe()
  {
   if(!InpEnableAutoSwitchTF)
      return;
   AttemptSwitchTimeframe(InpManagementTimeframe, true);
  }

void SwitchToEntryTimeframeAfterClose()
  {
   if(!InpEnableAutoSwitchTF)
      return;
   Print("🔔 All positions closed - Switching to Entry TF");
   AttemptSwitchTimeframe(InpEntryTimeframe, false);
  }

//+------------------------------------------------------------------+
//| Position count monitor                                           |
//+------------------------------------------------------------------+
void RefreshKnownTickets()
  {
   ArrayFree(g_knownTickets);
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!IsOwnPosition(ticket))
         continue;
      ArrayResize(g_knownTickets, n + 1);
      g_knownTickets[n] = ticket;
      n++;
     }
   // keep newest-first ordering (descending tickets)
   if(n > 1)
     {
      for(int a = 0; a < n - 1; a++)
         for(int b = a + 1; b < n; b++)
            if(g_knownTickets[b] > g_knownTickets[a])
              {
               ulong tmp = g_knownTickets[a];
               g_knownTickets[a] = g_knownTickets[b];
               g_knownTickets[b] = tmp;
              }
     }
  }

void HandlePartialClose(const int prevCount, const int nowCount)
  {
   Print("⚠️ PARTIAL CLOSE DETECTED!");
   Print("Mode: ", ModeText());
   Print("Initial positions: ", prevCount);
   Print("Current positions: ", nowCount);

   int closed = 0;
   int known = ArraySize(g_knownTickets);
   for(int k = 0; k < known; k++)
     {
      if(!IsOwnPosition(g_knownTickets[k]))
        {
         Print("  ❌ Closed: Ticket #", g_knownTickets[k]);
         closed++;
        }
     }
   Print("Total closed: ", closed);

   Print("🚨 PARTIAL CLOSE DETECTED - Triggering FORCE CLOSE ALL");
   Print("Mode: ", ModeText());
   ForceCloseAllPositions();
   ResetCycleTracking();
   UnlockTrading("Partial close handled");
  }

void CheckPositionChanges()
  {
   int now = CountOwnPositions();
   if(now == g_lastPositionCount)
      return;

   int prev = g_lastPositionCount;

   Print(SEP_DASH37);
   Print("Position count changed: ", prev, " → ", now);
   Print(SEP_DASH37);

   if(now < prev && now > 0 && !g_tradingLocked)
     {
      HandlePartialClose(prev, now);
     }
   else if(now == 0 && prev > 0)
     {
      SwitchToEntryTimeframeAfterClose();
     }
   else if(prev == 0 && now > 0)
     {
      if(InpEnableAutoSwitchTF)
        {
         Print("🔔 First position opened - Switching to Management TF");
         AttemptSwitchTimeframe(InpManagementTimeframe, true);
        }
     }

   g_lastPositionCount = CountOwnPositions();
   RefreshKnownTickets();
  }

//+------------------------------------------------------------------+
//| Force close: snapshot                                            |
//+------------------------------------------------------------------+
void TakePositionSnapshot()
  {
   g_snapCount = 0;
   g_snapProfitSum = 0.0;
   ArrayFree(g_snapTickets);
   ArrayFree(g_snapTypes);
   ArrayFree(g_snapPrices);
   ArrayFree(g_snapLots);
   ArrayFree(g_snapSLs);
   ArrayFree(g_snapProfits);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!IsOwnPosition(ticket))
         continue;
      int n = g_snapCount;
      ArrayResize(g_snapTickets, n + 1);
      ArrayResize(g_snapTypes, n + 1);
      ArrayResize(g_snapPrices, n + 1);
      ArrayResize(g_snapLots, n + 1);
      ArrayResize(g_snapSLs, n + 1);
      ArrayResize(g_snapProfits, n + 1);
      g_snapTickets[n] = ticket;
      g_snapTypes[n]   = (int)PositionGetInteger(POSITION_TYPE);
      g_snapPrices[n]  = PositionGetDouble(POSITION_PRICE_OPEN);
      g_snapLots[n]    = PositionGetDouble(POSITION_VOLUME);
      g_snapSLs[n]     = PositionGetDouble(POSITION_SL);
      g_snapProfits[n] = PositionGetDouble(POSITION_PROFIT);
      g_snapProfitSum += g_snapProfits[n];
      g_snapCount++;
     }

   // newest-first (descending ticket order)
   for(int a = 0; a < g_snapCount - 1; a++)
      for(int b = a + 1; b < g_snapCount; b++)
         if(g_snapTickets[b] > g_snapTickets[a])
           {
            ulong  ti = g_snapTickets[a]; g_snapTickets[a] = g_snapTickets[b]; g_snapTickets[b] = ti;
            int    ty = g_snapTypes[a];   g_snapTypes[a]   = g_snapTypes[b];   g_snapTypes[b]   = ty;
            double d;
            d = g_snapPrices[a];  g_snapPrices[a]  = g_snapPrices[b];  g_snapPrices[b]  = d;
            d = g_snapLots[a];    g_snapLots[a]    = g_snapLots[b];    g_snapLots[b]    = d;
            d = g_snapSLs[a];     g_snapSLs[a]     = g_snapSLs[b];     g_snapSLs[b]     = d;
            d = g_snapProfits[a]; g_snapProfits[a] = g_snapProfits[b]; g_snapProfits[b] = d;
           }

   Print("📸 Position Snapshot taken: ", g_snapCount, " positions");
   Print("Mode: ", ModeText());
   for(int k = 0; k < g_snapCount; k++)
     {
      Print("  [", k + 1, "] #", g_snapTickets[k],
            " | ", (g_snapTypes[k] == POSITION_TYPE_BUY ? "BUY" : "SELL"),
            " | Price: ", g_snapPrices[k],
            " | Lot: ", g_snapLots[k],
            " | SL: ", g_snapSLs[k],
            " | P/L: $", DoubleToString(g_snapProfits[k], 2));
     }
  }

//+------------------------------------------------------------------+
//| Force close: standard close pass                                 |
//+------------------------------------------------------------------+
int StandardClosePass(const int stage)
  {
   string method = "STANDARD";
   if(InpEnablePanicMode && stage > InpPanicModeThreshold)
      method = "PANIC";
   Print("Method: ", method, " (Stage ", stage, ")");

   PrepareTradeForClose(stage);
   if(method == "PANIC")
      g_trade.SetDeviationInPoints((ulong)100000000);

   int closed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!IsOwnPosition(ticket))
         continue;
      ResetLastError();
      if(g_trade.PositionClose(ticket))
        {
         Print("  ✓ Closed #", ticket);
         closed++;
        }
     }
   return(closed);
  }

//+------------------------------------------------------------------+
//| Force close: CloseBy hedge optimization (stage 1)                |
//+------------------------------------------------------------------+
int CloseByOptimizationPass(const int stage)
  {
   Print(BOX_TOP);
   Print("║  🎯 CLOSEBY HEDGE OPTIMIZATION        ║");
   Print(BOX_BOTTOM);
   Print("Mode: ", ModeText());

   Print(SBOX_TOP);
   Print("│  PHASE 1: CloseBy Hedge Pairs       │");
   Print(SBOX_BOTTOM);

   // --- hedge pair analysis
   int buyCount = 0, sellCount = 0;
   ulong buyTickets[];
   ulong sellTickets[];
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!IsOwnPosition(ticket))
         continue;
      if((int)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         ArrayResize(buyTickets, buyCount + 1);
         buyTickets[buyCount] = ticket;
         buyCount++;
        }
      else
        {
         ArrayResize(sellTickets, sellCount + 1);
         sellTickets[sellCount] = ticket;
         sellCount++;
        }
     }

   Print(SBOX_TOP);
   Print("│  🔍 HEDGE PAIR ANALYSIS             │");
   Print(SBOX_MID);
   Print("│  Mode: ", ModeText());
   Print("│  BUY Positions:  ", buyCount);
   Print("│  SELL Positions: ", sellCount);
   Print(SBOX_BOTTOM);

   int pairs = MathMin(buyCount, sellCount);
   int closedByPairs = 0;
   if(pairs == 0)
     {
      Print("  ℹ️ No hedge pairs found");
     }
   else
     {
      for(int p = 0; p < pairs; p++)
        {
         bool done = false;
         for(int attempt = 1; attempt <= InpCloseByMaxAttempts && !done; attempt++)
           {
            ResetLastError();
            if(g_trade.PositionCloseBy(buyTickets[p], sellTickets[p]))
              {
               done = true;
               closedByPairs += 2;
               if(InpEnableCloseByLogging)
                  Print("  ✓ CloseBy: #", buyTickets[p], " ↔ #", sellTickets[p],
                        " (attempt ", attempt, ")");
              }
            else
              {
               if(InpEnableCloseByLogging)
                  Print("  ⚠️ CloseBy failed: #", buyTickets[p], " ↔ #", sellTickets[p],
                        " (attempt ", attempt, ") - Error: ", GetLastError());
               SafeSleep(InpCloseByRetryDelayMs);
              }
           }
        }
     }

   SafeSleep(InpCloseByRetryDelayMs);

   // --- phase 2: close whatever remains
   int closed = closedByPairs;
   int remaining = CountOwnPositions();
   if(remaining > 0)
     {
      Print(SBOX_TOP);
      Print("│  PHASE 2: Close Remaining Positions │");
      Print(SBOX_BOTTOM);
      Print("  Remaining: ", remaining, " positions");
      int std = StandardClosePass(stage);
      Print("  Closed: ", std, " positions");
      closed += std;
     }
   return(closed);
  }

//+------------------------------------------------------------------+
//| Force close all positions (aggressive, staged)                   |
//+------------------------------------------------------------------+
bool ForceCloseAllPositions()
  {
   Print(BOX_TOP);
   Print("║  🚨 FORCE CLOSE ALL - AGGRESSIVE MODE ║");
   Print(BOX_BOTTOM);
   Print("Direction Mode: ", ModeText());

   LockTrading("Aggressive force close initiated");

   TakePositionSnapshot();
   int total = g_snapCount;

   if(total == 0)
     {
      Print("✅ No positions to close");
      UnlockTrading("No positions found");
      ResetCycleTracking();
      SwitchToEntryTimeframeAfterClose();
      return(true);
     }

   Print("Total positions to close: ", total);

   for(int stage = 1; stage <= InpMaxCloseAttempts; stage++)
     {
      Print(SEP_DASH39);
      Print("Stage ", stage, " of ", InpMaxCloseAttempts);
      Print(SEP_DASH39);

      int remaining = CountOwnPositions();
      Print("Remaining positions: ", remaining);
      if(remaining == 0)
         break;

      if(stage > 1)
        {
         Print("Waiting ", InpCloseRetryDelayMs, "ms before retry...");
         SafeSleep(InpCloseRetryDelayMs);
        }

      int closed = 0;
      if(stage == 1 && InpEnableCloseBy && InpCloseByBeforeRegular)
         closed = CloseByOptimizationPass(stage);
      else
         closed = StandardClosePass(stage);

      Print("Closed in stage ", stage, ": ", closed, " positions");

      if(CountOwnPositions() == 0)
         break;

      if(closed == 0)
         Print("⚠️ WARNING: No progress in stage ", stage);
      else
         Print("✓ Progress: ", closed, " positions closed");
     }

   // --- final verification
   Print(SEP_DEQ39);
   Print("FINAL VERIFICATION");
   Print(SEP_DEQ39);
   SafeSleep(InpCloseRetryDelayMs);

   int left = CountOwnPositions();
   if(left == 0)
     {
      Print("✅ VERIFICATION PASSED: All positions confirmed closed!");
      Print("Mode: ", ModeText());
      Print(BOX_TOP);
      Print("║     ✅ ALL POSITIONS CLOSED SUCCESS    ║");
      Print(BOX_BOTTOM);

      double cycleProfit = g_snapProfitSum;
      g_totalProfit += cycleProfit;
      g_totalTradesClosed += total;
      Print("Cycle Profit: $", DoubleToString(cycleProfit, 2));
      Print("Total Profit: $", DoubleToString(g_totalProfit, 2));

      ResetCycleTracking();
      UnlockTrading("All positions closed successfully");
      SwitchToEntryTimeframeAfterClose();
      return(true);
     }

   Print("❌ VERIFICATION FAILED: ", left, " positions still open!");
   Print("Mode: ", ModeText());
   Print(BOX_TOP);
   Print("║  ⚠️ FORCE CLOSE INCOMPLETE            ║");
   Print(BOX_BOTTOM);
   UnlockTrading("Force close incomplete - will retry");
   return(false);
  }

//+------------------------------------------------------------------+
//| Group BEP / SL monitor                                           |
//+------------------------------------------------------------------+
void StoreSLMonitorTickets()
  {
   ArrayFree(g_slInitialTickets);
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!IsOwnPosition(ticket))
         continue;
      ArrayResize(g_slInitialTickets, n + 1);
      g_slInitialTickets[n] = ticket;
      n++;
     }
  }

void PrintSLMonitorBlock(const int count)
  {
   Print(SEP_DEQ39);
   Print("🎯 SL MONITOR ACTIVATED");
   Print(SEP_DEQ39);
   Print("Mode: ", ModeText());
   Print("SL Price: ", g_slTargetPrice);
   Print("Direction: ", (g_slDirection == POSITION_TYPE_BUY ? "BUY" : "SELL"));
   Print("Avg Entry: ", g_slAvgEntry);
   Print("Positions: ", count);
   Print("Initial Tickets: ", ArraySize(g_slInitialTickets));
   Print(SEP_DEQ39);
  }

void ApplyServerSideSL()
  {
   g_slPassSuccess = 0;
   g_slPassFailed  = 0;

   double target = NormalizeDouble(g_slTargetPrice, _Digits);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!IsOwnPosition(ticket))
         continue;
      double curSL = PositionGetDouble(POSITION_SL);
      if(MathAbs(curSL - target) < _Point / 2.0)
         continue;
      double tp = PositionGetDouble(POSITION_TP);
      ResetLastError();
      if(g_trade.PositionModify(ticket, target, tp))
        {
         g_slPassSuccess++;
         Print("  ✅ SL set for #", ticket, " at ", DoubleToString(target, _Digits));
        }
      else
        {
         g_slPassFailed++;
         Print("  ⚠️ SL modify failed for #", ticket, " - Error: ", GetLastError());
        }
     }
  }

void PrintBEPStatus()
  {
   Print(SEP_DEQ39);
   Print("Break Even Protection Status:");
   Print("  Mode: ", ModeText());
   Print("  Server-side SL SUCCESS: ", g_slPassSuccess);
   Print("  Server-side SL FAILED: ", g_slPassFailed);
   Print("  Client-side Monitor: ", (InpEnableClientSideSL ? "ACTIVE ✅" : "DISABLED ⚠️"));
   Print("  Target SL: ", g_slTargetPrice);
   Print("  Monitoring Buffer: ", InpClientSLBufferPoints, " points");
   Print(SEP_DEQ39);
  }

void RecalcSLMonitorTargets()
  {
   double avg = 0.0;
   int dir = -1, count = 0;
   if(!RecalcGroupAverages(avg, dir, count))
      return;
   g_slAvgEntry = avg;
   g_slDirection = dir;
   if(dir == POSITION_TYPE_BUY)
      g_slTargetPrice = avg + InpGroupBEP_LockPoints * _Point;
   else
      g_slTargetPrice = avg - InpGroupBEP_LockPoints * _Point;
  }

void RunSLMonitorPass()
  {
   int count = CountOwnPositions();
   if(count == 0)
      return;
   RecalcSLMonitorTargets();
   PrintSLMonitorBlock(count);
   ApplyServerSideSL();
   PrintBEPStatus();
  }

void ActivateSLMonitor()
  {
   g_slMonitorActive = true;
   RecalcSLMonitorTargets();
   StoreSLMonitorTickets();
   RunSLMonitorPass();
  }

void CheckGroupBEPActivation()
  {
   if(!InpEnableGroupBEP || g_slMonitorActive || g_tradingLocked)
      return;

   double avg = 0.0;
   int dir = -1, count = 0;
   if(!RecalcGroupAverages(avg, dir, count))
      return;
   if(count < InpGroupBEP_MinOrders)
      return;

   double profitPts = GroupProfitPoints(avg, dir);
   if(profitPts >= (double)InpGroupBEP_TriggerPoints)
     {
      Print(SEP_DEQ39);
      Print("🛡️ BREAK EVEN ACTIVATED");
      Print("Mode: ", ModeText());
      Print(SEP_DEQ39);
      ActivateSLMonitor();
     }
  }

void HandleClientSLHit(const string dirText, const double currentPrice, const double triggerPrice)
  {
   Print("🔴 CLIENT-SIDE SL HIT DETECTED (", dirText, ")");
   Print("Mode: ", ModeText());
   Print("Current Price: ", currentPrice);
   Print("Trigger Price: ", triggerPrice);
   Print("Target SL: ", g_slTargetPrice);
   Print("Buffer: ", InpClientSLBufferPoints, " points");
   Print("🚨 CLIENT-SIDE SL HIT - Triggering FORCE CLOSE ALL");
   Print("Mode: ", ModeText());
   ForceCloseAllPositions();
   ResetCycleTracking();
   UnlockTrading("SL hit handled");
  }

void CheckClientSideSLHit()
  {
   if(!InpEnableClientSideSL || !g_slMonitorActive || g_tradingLocked)
      return;

   double buffer = InpClientSLBufferPoints * _Point;

   if(g_slDirection == POSITION_TYPE_BUY)
     {
      double current = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double trigger = g_slTargetPrice + buffer;
      if(current <= trigger)
         HandleClientSLHit("BUY", current, trigger);
     }
   else if(g_slDirection == POSITION_TYPE_SELL)
     {
      double current = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double trigger = g_slTargetPrice - buffer;
      if(current >= trigger)
         HandleClientSLHit("SELL", current, trigger);
     }
  }

void UpdateSLMonitorTick()
  {
   if(!g_slMonitorActive || g_tradingLocked)
      return;
   RunSLMonitorPass();
   CheckClientSideSLHit();
  }

//+------------------------------------------------------------------+
//| Trailing stop                                                    |
//+------------------------------------------------------------------+
void CheckTrailingStop()
  {
   if(!InpTrailingEnabled || g_tradingLocked)
      return;

   double avg = 0.0;
   int dir = -1, count = 0;
   if(!RecalcGroupAverages(avg, dir, count))
     {
      g_trailingActive = false;
      g_trailingPeakPoints = 0.0;
      return;
     }

   double profitPts = GroupProfitPoints(avg, dir);

   if(!g_trailingActive)
     {
      if(profitPts >= (double)InpTrailingTriggerPoints)
        {
         g_trailingActive = true;
         g_trailingPeakPoints = profitPts;
         Print(SEP_DEQ39);
         Print("🔥 TRAILING STOP ACTIVATED!");
         Print("Mode: ", ModeText());
         Print(SEP_DEQ39);
        }
      return;
     }

   if(profitPts > g_trailingPeakPoints)
     {
      g_trailingPeakPoints = profitPts;
      return;
     }

   double drawdown = g_trailingPeakPoints - profitPts;
   if(drawdown >= (double)InpTrailingDistancePoints)
     {
      Print(SEP_DEQ39);
      Print("🚨 TRAILING STOP HIT - CLOSING ALL");
      Print(SEP_DEQ39);
      Print("Mode: ", ModeText());
      Print("Total Positions: ", count);
      Print("Profit: ", DoubleToString(profitPts, 1), " points");
      Print("Drawdown from peak: ", DoubleToString(drawdown, 1), " points");
      Print(SEP_DEQ39);
      if(InpCloseAllOnTrailingHit)
         ForceCloseAllPositions();
     }
  }

//+------------------------------------------------------------------+
//| Cut loss safety net                                              |
//+------------------------------------------------------------------+
void CheckCutLoss()
  {
   if(!InpEnableCutLoss || g_tradingLocked)
      return;
   if(CountOwnPositions() == 0)
      return;

   double floating = SumOwnFloatingProfit();
   if(floating <= -InpCutLossUSD)
     {
      Print(SEP_DEQ39);
      Print("💀 CUT LOSS TRIGGERED");
      Print("Mode: ", ModeText());
      Print("Floating Loss: $", DoubleToString(floating, 2));
      Print("Cut Loss Limit: $", DoubleToString(InpCutLossUSD, 2));
      Print(SEP_DEQ39);
      ForceCloseAllPositions();
      ResetCycleTracking();
      UnlockTrading("Cut loss executed");
     }
  }

//+------------------------------------------------------------------+
//| Entry filters                                                    |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
  {
   if(!EnableFilterClock)
      return(true);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int nowMinutes   = dt.hour * 60 + dt.min;
   int startMinutes = InpTradingStartTime * 60 + InpMinutesStartTrading;
   int endMinutes   = InpMinutesEndTrading * 60 + InpMinutesCompleteTrading;
   return(nowMinutes >= startMinutes && nowMinutes < endMinutes);
  }

bool PassesLeverageFilter()
  {
   if(!InpEnableLeverageFilter)
      return(true);
   return(AccountInfoInteger(ACCOUNT_LEVERAGE) >= InpMinimalLeverage);
  }

bool PassesSpreadFilter()
  {
   if(!InpEnableSpreadFilter)
      return(true);
   return(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= InpMaximumSpread);
  }

//+------------------------------------------------------------------+
//| Indicator readers                                                |
//+------------------------------------------------------------------+
bool GetEmaValue(const int shift, double &value)
  {
   double buf[];
   if(CopyBuffer(g_emaHandle, 0, shift, 1, buf) != 1)
      return(false);
   value = buf[0];
   return(true);
  }

bool GetRsiValue(const int shift, double &value)
  {
   double buf[];
   if(CopyBuffer(g_rsiHandle, 0, shift, 1, buf) != 1)
      return(false);
   value = buf[0];
   return(true);
  }

//+------------------------------------------------------------------+
//| Entry signal (-1 = none, ORDER_TYPE_BUY / ORDER_TYPE_SELL)       |
//+------------------------------------------------------------------+
int GetEntrySignal()
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ema;
   if(!GetEmaValue(1, ema))
      return(-1);

   // --- optional RSI counter-trend override
   if(InpEnableRsiCounterTrend)
     {
      double rsi;
      if(GetRsiValue(1, rsi))
        {
         if(rsi >= InpRsiOverboughtLevel)
            return((int)ORDER_TYPE_SELL);
         if(rsi <= InpRsiOversoldLevel)
            return((int)ORDER_TYPE_BUY);
        }
     }

   // --- optional EMA distance filter
   if(InpEnableEmaDistanceFilter)
     {
      double distancePts = MathAbs(bid - ema) / _Point;
      if(distancePts > (double)InpMaxDistancePoints)
         return(-1);
     }

   if(InpEntryMode == ENTRY_TREND_AREA)
     {
      if(bid > ema)
         return((int)ORDER_TYPE_BUY);
      if(bid < ema)
         return((int)ORDER_TYPE_SELL);
      return(-1);
     }

   // --- crossover mode
   double emaPrev, closeCur, closePrev;
   if(!GetEmaValue(2, emaPrev))
      return(-1);
   closeCur  = iClose(_Symbol, PERIOD_CURRENT, 1);
   closePrev = iClose(_Symbol, PERIOD_CURRENT, 2);
   if(closePrev <= emaPrev && closeCur > ema)
      return((int)ORDER_TYPE_BUY);
   if(closePrev >= emaPrev && closeCur < ema)
      return((int)ORDER_TYPE_SELL);
   return(-1);
  }

bool DirectionAllowed(const int orderType)
  {
   if(InpTradingDirection == DIRECTION_BUY_ONLY && orderType != (int)ORDER_TYPE_BUY)
      return(false);
   if(InpTradingDirection == DIRECTION_SELL_ONLY && orderType != (int)ORDER_TYPE_SELL)
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//| Order opening                                                    |
//+------------------------------------------------------------------+
bool SendMarketOrder(const int orderType, const double lot, const string comment)
  {
   PrepareTradeForOpen();
   ResetLastError();
   bool ok;
   if(orderType == (int)ORDER_TYPE_BUY)
      ok = g_trade.Buy(lot, _Symbol, 0.0, 0.0, 0.0, comment);
   else
      ok = g_trade.Sell(lot, _Symbol, 0.0, 0.0, 0.0, comment);
   return(ok);
  }

void TrackOpenedLot(const double lot)
  {
   if(lot > g_maxLotUsed)
      g_maxLotUsed = lot;
  }

void OpenInitialPosition(const int orderType)
  {
   double bidNow = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool adjusted;
   double lot = NormalizeLotSize(InpInitialLot, adjusted);
   string comment = ModeTag() + " Initial";

   if(!SendMarketOrder(orderType, lot, comment))
      return;

   ulong ticket = g_trade.ResultOrder();

   g_totalTradesOpened++;
   g_cycleDirection  = (orderType == (int)ORDER_TYPE_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
   g_lastGridPrice   = bidNow;
   g_lastLot         = lot;
   g_martingaleCount = 0;
   g_pyramidCount    = 0;
   TrackOpenedLot(lot);

   Print("=== POSITION OPENED ===");
   Print("Direction Mode: ", ModeText());
   Print("Type: ", (orderType == (int)ORDER_TYPE_BUY ? "BUY" : "SELL"));
   Print("Price: ", bidNow);
   Print("Lot: ", lot);
   Print("Ticket: ", ticket);
   Print("Comment: ", comment);
   Print("=======================");

   if(InpEnableAutoSwitchTF)
     {
      Print("🔔 Initial position opened - Switching to Management TF");
      AttemptSwitchTimeframe(InpManagementTimeframe, true);
     }
  }

//+------------------------------------------------------------------+
//| Initial entry logic (only when flat, on a new bar)               |
//+------------------------------------------------------------------+
void CheckEntry()
  {
   if(!g_isNewBar)
      return;
   if(!IsWithinTradingHours())
      return;
   if(!PassesLeverageFilter())
      return;
   if(!PassesSpreadFilter())
      return;

   int signal = GetEntrySignal();
   if(signal < 0)
      return;
   if(!DirectionAllowed(signal))
      return;

   Print("=== NEW ENTRY SIGNAL ===");
   Print("Mode: ", ModeText());
   Print("Type: ", (signal == (int)ORDER_TYPE_BUY ? "BUY" : "SELL"));
   Print("Current TF: ", TfToString(Period()));
   Print("========================");

   OpenInitialPosition(signal);
  }

//+------------------------------------------------------------------+
//| Cycle resynchronization (safety after restart)                   |
//+------------------------------------------------------------------+
void ResyncCycleState()
  {
   if(g_cycleDirection >= 0 && g_lastGridPrice > 0.0)
      return;

   int count = 0;
   ulong newest = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!IsOwnPosition(ticket))
         continue;
      count++;
      if(ticket > newest)
         newest = ticket;
     }
   if(count == 0 || newest == 0)
      return;
   if(!PositionSelectByTicket(newest))
      return;

   g_cycleDirection  = (int)PositionGetInteger(POSITION_TYPE);
   g_lastGridPrice   = PositionGetDouble(POSITION_PRICE_OPEN);
   g_lastLot         = PositionGetDouble(POSITION_VOLUME);
   g_martingaleCount = (count > 0 ? count - 1 : 0);
  }

//+------------------------------------------------------------------+
//| Martingale (loss mode grid)                                      |
//+------------------------------------------------------------------+
bool RsiAllowsMartingale(const int direction)
  {
   if(!InpEnableMartingaleRsiFilter)
      return(true);
   double rsi;
   if(!GetRsiValue(1, rsi))
      return(false);
   if(direction == POSITION_TYPE_BUY)
      return(rsi <= InpRsiOversoldLevel);
   return(rsi >= InpRsiOverboughtLevel);
  }

void CheckMartingale()
  {
   if(!InpEnableMartingale || g_tradingLocked)
      return;
   if(g_cycleDirection < 0 || g_lastGridPrice <= 0.0)
      return;
   if(g_martingaleCount >= InpMartingaleMaxOrders)
      return;
   if(InpStopTradingAtMaxLot && g_maxLotReached)
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double distance = InpMartingaleDistancePoints * _Point;

   bool triggered = false;
   if(g_cycleDirection == POSITION_TYPE_BUY)
      triggered = (bid <= g_lastGridPrice - distance);
   else
      triggered = (bid >= g_lastGridPrice + distance);

   if(!triggered)
      return;
   if(!RsiAllowsMartingale(g_cycleDirection))
      return;

   int newCount = g_martingaleCount + 1;
   double requested = InpInitialLot * MathPow(InpMartingaleLotMultiplier, newCount);
   bool adjusted;
   double lot = NormalizeLotSize(requested, adjusted);
   if(adjusted)
      Print("  ℹ️ Martingale lot capped: ", requested, " → ", lot);

   int orderType = (g_cycleDirection == POSITION_TYPE_BUY ? (int)ORDER_TYPE_BUY : (int)ORDER_TYPE_SELL);
   string comment = ModeTag() + " Martingale";

   if(!SendMarketOrder(orderType, lot, comment))
      return;

   g_martingaleCount = newCount;
   g_totalTradesOpened++;
   g_lastLot = lot;
   TrackOpenedLot(lot);

   Print("=== MARTINGALE OPENED ===");
   Print("Mode: ", ModeText());
   Print("Count: ", g_martingaleCount);
   Print("Lot: ", lot);
   Print("Price: ", bid);
   Print("Comment: ", comment);
   Print("=========================");

   g_lastGridPrice = bid;

   if(g_slMonitorActive)
     {
      RecalcSLMonitorTargets();
      StoreSLMonitorTickets();
      Print("  ℹ️ SL Monitor updated for new martingale position");
     }
  }

//+------------------------------------------------------------------+
//| Pyramiding (profit mode grid)                                    |
//+------------------------------------------------------------------+
void CheckPyramid()
  {
   if(!InpPyramidEnabled || g_tradingLocked)
      return;
   if(g_cycleDirection < 0 || g_lastGridPrice <= 0.0)
      return;
   if(g_pyramidCount >= InpMaxPyramidOrders)
      return;
   if(InpStopTradingAtMaxLot && g_maxLotReached)
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double trigger = InpPyramidTriggerPoints * _Point;

   bool triggered = false;
   if(g_cycleDirection == POSITION_TYPE_BUY)
      triggered = (bid >= g_lastGridPrice + trigger);
   else
      triggered = (bid <= g_lastGridPrice - trigger);

   if(!triggered)
      return;

   double base = (g_lastLot > 0.0 ? g_lastLot : InpInitialLot);
   double requested = base * InpPyramidLotMultiplier;
   bool adjusted;
   double lot = NormalizeLotSize(requested, adjusted);
   if(adjusted)
      Print("  ℹ️ Pyramid lot capped: ", requested, " → ", lot);

   int orderType = (g_cycleDirection == POSITION_TYPE_BUY ? (int)ORDER_TYPE_BUY : (int)ORDER_TYPE_SELL);
   string comment = ModeTag() + " Pyramid";

   if(!SendMarketOrder(orderType, lot, comment))
      return;

   g_pyramidCount++;
   g_totalTradesOpened++;
   g_lastLot = lot;
   TrackOpenedLot(lot);

   Print("=== PYRAMID OPENED ===");
   Print("Mode: ", ModeText());
   Print("Lot: ", lot);
   Print("Price: ", bid);
   Print("Total: ", CountOwnPositions());
   Print("Comment: ", comment);
   Print("======================");

   g_lastGridPrice = bid;

   if(g_slMonitorActive)
     {
      RecalcSLMonitorTargets();
      StoreSLMonitorTickets();
      Print("  ℹ️ SL Monitor updated for new pyramid position");
     }
  }

//+------------------------------------------------------------------+
//| Trade management dispatcher                                      |
//+------------------------------------------------------------------+
void ManageTrading()
  {
   if(g_tradingLocked)
      return;

   int count = CountOwnPositions();
   if(count == 0)
     {
      CheckEntry();
     }
   else
     {
      ResyncCycleState();
      CheckMartingale();
      CheckPyramid();
     }
  }

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   // --- trade object
   g_trade.SetExpertMagicNumber((ulong)InpMagicNumber);
   g_trade.SetTypeFilling(AutoFillingMode());
   g_trade.SetDeviationInPoints(InpEnableSlippageControl ? (ulong)InpMaximumSlippage
                                                         : (ulong)100000000);
   g_trade.LogLevel(LOG_LEVEL_NO);

   // --- indicators
   g_emaHandle = iMA(_Symbol, PERIOD_CURRENT, InpEmaPeriod, InpEmaShift, InpEmaMethod, InpEmaPrice);
   if(g_emaHandle == INVALID_HANDLE)
     {
      Print("❌ Failed to create EMA indicator handle - Error: ", GetLastError());
      return(INIT_FAILED);
     }
   g_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, InpRsiPeriod, InpRsiPrice);
   if(g_rsiHandle == INVALID_HANDLE)
     {
      Print("❌ Failed to create RSI indicator handle - Error: ", GetLastError());
      return(INIT_FAILED);
     }

   // --- state
   g_lastBarTime       = 0;
   g_isNewBar          = false;
   g_tradingLocked     = false;
   g_totalTradesOpened = 0;
   g_totalTradesClosed = 0;
   g_totalProfit       = 0.0;
   g_lastPositionCount = CountOwnPositions();
   RefreshKnownTickets();
   g_tfMode            = TF_MODE_ENTRY;

   // --- banner
   Print(SEP_EQ40);
   Print("Multi Strategy v14 - AUTO SWITCH TF");
   Print(SEP_EQ40);
   Print("Symbol: ", _Symbol);
   Print("Period: ", TfToString(PERIOD_CURRENT));
   Print("Magic Number: ", InpMagicNumber);
   Print("Initial Lot: ", InpInitialLot);
   Print(SEP_DASH37);

   if(InpEnableAutoSwitchTF)
     {
      Print("📊 AUTO SWITCH TIMEFRAME: ENABLED ✅");
      Print("  Entry TF: ", TfToString(InpEntryTimeframe));
      Print("  Management TF: ", TfToString(InpManagementTimeframe));
      Print("  Current Chart TF: ", TfToString(Period()));
      if(g_lastPositionCount > 0)
        {
         Print("  Positions exist - Setting Management TF");
         AttemptSwitchTimeframe(InpManagementTimeframe, true);
        }
      else
        {
         Print("  No positions - Setting Entry TF");
         AttemptSwitchTimeframe(InpEntryTimeframe, false);
        }
     }
   else
     {
      Print("📊 AUTO SWITCH TIMEFRAME: DISABLED");
     }

   Print(SEP_DASH37);
   Print("TRADING DIRECTION: ", ModeText());
   Print(SEP_DASH37);
   switch(InpTradingDirection)
     {
      case DIRECTION_BUY_ONLY:
         Print("  ⬆️ BUY ONLY MODE ACTIVE");
         Print("  • Will open BUY positions only");
         Print("  • SELL signals will be ignored");
         break;
      case DIRECTION_SELL_ONLY:
         Print("  ⬇️ SELL ONLY MODE ACTIVE");
         Print("  • Will open SELL positions only");
         Print("  • BUY signals will be ignored");
         break;
      default:
         Print("  ⬆️⬇️ NORMAL MODE ACTIVE");
         Print("  • Will open both BUY & SELL positions");
         Print("  • Standard bidirectional trading");
         break;
     }
   Print(SEP_DASH37);
   Print("Max Lot Enabled: ", (InpEnableMaxLot ? "YES" : "NO"));
   Print("Max Lot Size: ", InpMaxLotSize);
   Print("Stop at Max Lot: ", (InpStopTradingAtMaxLot ? "YES" : "NO"));
   Print("CloseBy Hedge: ", (InpEnableCloseBy ? "ENABLED ✅" : "DISABLED"));
   Print("CloseBy Priority: ", (InpCloseByBeforeRegular ? "FIRST" : "AFTER"));
   Print("CloseBy Max Attempts: ", InpCloseByMaxAttempts);
   Print("Client-Side SL: ", (InpEnableClientSideSL ? "ENABLED" : "DISABLED"));
   Print("SL Buffer: ", InpClientSLBufferPoints, " points");
   Print("Panic Mode: ", (InpEnablePanicMode ? "ENABLED" : "DISABLED"));
   Print(SEP_EQ40);

   ResetCycleTracking();

   Print("✅ EA v14 Initialized Successfully!");
   Print(SEP_EQ40);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinit reason text                                               |
//+------------------------------------------------------------------+
string DeinitReasonText(const int reason)
  {
   switch(reason)
     {
      case REASON_PROGRAM:     return("ExpertRemove() called");
      case REASON_REMOVE:      return("EA removed");
      case REASON_RECOMPILE:   return("EA recompiled");
      case REASON_CHARTCHANGE: return("Chart symbol/period changed");
      case REASON_CHARTCLOSE:  return("Chart closed");
      case REASON_PARAMETERS:  return("Input parameters changed");
      case REASON_ACCOUNT:     return("Account changed");
      case REASON_TEMPLATE:    return("Template applied");
      case REASON_INITFAILED:  return("Initialization failed");
      case REASON_CLOSE:       return("Terminal closed");
     }
   return("Unknown (" + IntegerToString(reason) + ")");
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print(SEP_EQ40);
   Print("EA Deinitialized - Reason: ", DeinitReasonText(reason));
   Print("Direction Mode: ", ModeText());
   if(InpEnableAutoSwitchTF)
      Print("Auto Switch TF: ", (g_tfMode == TF_MODE_ENTRY ? "Was Entry mode" : "Was Management mode"));
   Print("Final TF: ", TfToString(Period()));
   if(InpEnableTradeHistory)
     {
      Print("Total Trades Opened: ", g_totalTradesOpened);
      Print("Total Trades Closed: ", g_totalTradesClosed);
      Print("Total Profit: $", DoubleToString(g_totalProfit, 2));
      Print("Max Lot Used: ", g_maxLotUsed);
      Print("Max Lot Reached: ", (g_maxLotReached ? "YES" : "NO"));
     }
   Print(SEP_EQ40);

   if(g_emaHandle != INVALID_HANDLE)
     {
      IndicatorRelease(g_emaHandle);
      g_emaHandle = INVALID_HANDLE;
     }
   if(g_rsiHandle != INVALID_HANDLE)
     {
      IndicatorRelease(g_rsiHandle);
      g_rsiHandle = INVALID_HANDLE;
     }
  }

//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
  {
   // --- new bar detection (bar is consumed every tick regardless of state)
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   g_isNewBar = (barTime != g_lastBarTime);
   g_lastBarTime = barTime;

   // --- re-entrancy guard: everything below is synchronous
   if(g_tradingLocked)
      return;

   // 1. position count monitor (external closes / partial close handling)
   CheckPositionChanges();
   if(g_tradingLocked)
      return;

   // 2. group break-even activation
   CheckGroupBEPActivation();

   // 3. SL monitor maintenance + client-side SL protection
   UpdateSLMonitorTick();
   if(g_tradingLocked)
      return;

   // 4. trade logic: initial entry / martingale / pyramid
   ManageTrading();

   // 5. position count monitor (post-trade update)
   CheckPositionChanges();
   if(g_tradingLocked)
      return;

   // 6. trailing stop management
   CheckTrailingStop();

   // 7. cut loss safety net
   CheckCutLoss();
  }
//+------------------------------------------------------------------+
