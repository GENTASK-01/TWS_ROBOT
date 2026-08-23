//+------------------------------------------------------------------+
//|                                      TWS Trade Pilot EA V14.mq5 |
//|                                     Copyright 2026, Official TWS |
//| Build Target: MetaTrader 5 Build 6140                            |
//| Generated: Complete reconstruction with full S2+S3+S4 pipeline   |
//| Resolution: BMER-PROMPT-v1.0 | Mode: B                          |
//| Session: Iteration 1                                             |
//+------------------------------------------------------------------+
#property copyright "Official TWS"
#property link      "https://www.tradewithsanchit.com"
#property version   "1.01"
#property description "Multi Strategy v14 - AUTO SWITCH TF"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_TRADE_DIRECTION
  {
   DIRECTION_NORMAL = 0,   // Normal (Buy & Sell)
   DIRECTION_BUY    = 1,   // Buy
   DIRECTION_SELL   = 2    // Sell
  };

enum ENUM_ENTRY_MODE
  {
   ENTRY_TREND_AREA = 0,   // Trend Area Mode
   ENTRY_CROSSOVER  = 1    // Crossover Mode
  };

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "===== AI BASED TIMEFRAME SWITCH ====="
input bool            InpEnableAutoSwitchTF      = true;             // Enable Auto Switch Timeframe
input ENUM_TIMEFRAMES InpEntryTimeframe          = PERIOD_M1;        // Entry Timeframe (for initial position)
input ENUM_TIMEFRAMES InpManagementTimeframe     = PERIOD_H1;        // Management Timeframe (after position opened)

input group "===== CORE SETTINGS ====="
input long            InpMagicNumber             = 202501;           // Magic Number

input group "===== TRADING DIRECTION ====="
input ENUM_TRADE_DIRECTION InpTradingDirection   = DIRECTION_NORMAL; // Trading Direction

input group "===== RISK FILTERS ====="
input bool            EnableFilterClock          = false;            // Enable Filter Clock
input int             InpTradingStartTime        = 9;                // Trading Start Time (Hour)
input int             InpMinutesStartTrading     = 0;                // Minutes Start Trading
input int             InpMinutesEndTrading       = 17;               // Minutes End Trading (Hour)
input int             InpMinutesCompleteTrading  = 0;                // Minutes Complete Trading
input bool            InpEnableLeverageFilter    = false;            // Enable Leverage Filter
input int             InpMinimalLeverage         = 2000;             // Minimal Leverage

input group "===== SPREAD & SLIPPAGE CONTROL ====="
input bool            InpEnableSpreadFilter      = true;             // Enable Spread Filter
input int             InpMaximumSpread           = 300;              // Maximum Spread (points)
input bool            InpEnableSlippageControl   = false;            // Enable Slippage Control
input int             InpMaximumSlippage         = 30;               // Maximum Slippage (points)

input group "===== EMA TREND SETTINGS ====="
input int             InpEmaPeriod               = 5;                // Ema Period
input int             InpEmaShift                = 0;                // Ema Shift
input ENUM_MA_METHOD  InpEmaMethod               = MODE_SMA;         // Ema Method
input ENUM_APPLIED_PRICE InpEmaPrice             = PRICE_CLOSE;      // Ema Price

input group "===== INITIAL ENTRY SETTINGS ====="
input ENUM_ENTRY_MODE InpEntryMode               = ENTRY_TREND_AREA; // Entry Mode
input double          InpInitialLot              = 0.01;             // Initial Lot
input bool            InpEnableEmaDistanceFilter = false;            // Enable Ema Distance Filter
input int             InpMaxDistancePoints       = 1000;             // Max Distance Points
input bool            InpEnableRsiCounterTrend   = false;            // Enable Rsi Counter Trend

input group "===== MAX LOT LIMITER ====="
input bool            InpEnableMaxLot            = true;             // Enable Max Lot
input double          InpMaxLotSize              = 0.1;              // Max Lot Size
input bool            InpStopTradingAtMaxLot     = false;            // Stop Trading At Max Lot

input group "===== CLOSEBY & HEDGE SETTINGS ====="
input bool            InpEnableCloseBy           = true;             // Enable CloseBy
input bool            InpCloseByBeforeRegular    = true;             // CloseBy Before Regular
input int             InpCloseByMaxAttempts      = 3;                // CloseBy Max Attempts
input int             InpCloseByRetryDelayMs     = 50;               // CloseBy Retry Delay Ms
input bool            InpEnableCloseByLogging    = true;             // Enable CloseBy Logging

input group "===== PYRAMIDING SETTINGS (Profit Mode) ====="
input bool            InpPyramidEnabled          = true;             // Pyramid Enabled
input int             InpPyramidTriggerPoints    = 1500;             // Pyramid Trigger Points
input double          InpPyramidLotMultiplier    = 1.0;              // Pyramid Lot Multiplier
input int             InpMaxPyramidOrders        = 100;              // Max Pyramid Orders

input group "===== MARTINGALE SETTINGS (Loss Mode) ====="
input bool            InpEnableMartingale        = true;             // Enable Martingale
input bool            InpEnableMartingaleRsiFilter = false;          // Enable Martingale Rsi Filter
input int             InpMartingaleDistancePoints = 400;             // Martingale Distance Points
input double          InpMartingaleLotMultiplier = 1.1;              // Martingale Lot Multiplier
input int             InpMartingaleMaxOrders     = 1000;             // Martingale Max Orders

input group "===== RSI INDICATOR SETTINGS ====="
input int             InpRsiPeriod               = 14;               // Rsi Period
input ENUM_APPLIED_PRICE InpRsiPrice             = PRICE_CLOSE;      // Rsi Price
input double          InpRsiOverboughtLevel      = 70.0;             // Rsi Overbought Level
input double          InpRsiOversoldLevel        = 30.0;             // Rsi Oversold Level

input group "===== CUT LOSS (SAFETY NET) ====="
input bool            InpEnableCutLoss           = false;            // Enable Cut Loss
input double          InpCutLossUSD              = 1000.0;           // Cut Loss USD

input group "===== GROUP BREAK EVEN PROTECTION ====="
input bool            InpEnableGroupBEP          = true;             // Enable Group BEP
input int             InpGroupBEP_MinOrders      = 1;                // Group BEP Min Orders
input int             InpGroupBEP_TriggerPoints  = 500;              // Group BEP Trigger Points
input int             InpGroupBEP_LockPoints     = 500;              // Group BEP Lock Points

input group "===== TRAILING STOP SETTINGS ====="
input bool            InpTrailingEnabled         = true;             // Trailing Enabled
input int             InpTrailingTriggerPoints   = 600;              // Trailing Trigger Points
input int             InpTrailingDistancePoints  = 500;              // Trailing Distance Points
input bool            InpCloseAllOnTrailingHit   = true;             // Close All On Trailing Hit

input group "===== ADVANCED PROTECTION ====="
input bool            InpEnableClientSideSL      = true;             // Enable Client Side SL
input int             InpClientSLBufferPoints    = 10;               // Client SL Buffer Points
input int             InpMaxCloseAttempts        = 10;               // Max Close Attempts
input int             InpCloseRetryDelayMs       = 100;              // Close Retry Delay Ms
input bool            InpEnablePanicMode         = true;             // Enable Panic Mode
input int             InpPanicModeThreshold      = 5;                // Panic Mode Threshold

input group "===== DEBUG & LOGGING ====="
input bool            InpEnableDetailedLog       = true;             // Enable Detailed Log
input bool            InpEnableTradeHistory      = true;             // Enable Trade History

//+------------------------------------------------------------------+
//| Visual constants (exact journal reproduction)                    |
//+------------------------------------------------------------------+
#define SEP_HEAVY   "═══════════════════════════════════════"
#define SEP_LIGHT   "─────────────────────────────────────"
#define SEP_STAGE   "───────────────────────────────────────"
#define EQ_LINE_40  "========================================"
#define EQ_ENTRY    "========================"
#define EQ_OPENED   "======================="
#define EQ_MART     "========================="
#define EQ_PYR      "====================="
#define BOX_TOP     "╔═══════════════════════════════════════╗"
#define BOX_FORCE   "║  🚨 FORCE CLOSE ALL - AGGRESSIVE MODE ║"
#define BOX_CLOSEBY "║  🎯 CLOSEBY HEDGE OPTIMIZATION        ║"
#define BOX_SUCCESS "║     ✅ ALL POSITIONS CLOSED SUCCESS    ║"
#define BOX_BOT     "╚═══════════════════════════════════════╝"
#define PH_TOP      "┌─────────────────────────────────────┐"
#define PH1_TXT     "│  PHASE 1: CloseBy Hedge Pairs       │"
#define PH2_TXT     "│  PHASE 2: Close Remaining Positions │"
#define PH_MID      "├─────────────────────────────────────┤"
#define PH_BOT      "└─────────────────────────────────────┘"

//+------------------------------------------------------------------+
//| Global trade object                                              |
//+------------------------------------------------------------------+
CTrade trade;

//--- indicator handles
int g_emaHandle = INVALID_HANDLE;
int g_rsiHandle = INVALID_HANDLE;

//--- cycle (basket) tracking state, reset after every completed cycle
bool     g_bepActive          = false;
bool     g_monitorActive      = false;
bool     g_trailingArmed      = false;
double   g_peakProfitPoints   = 0.0;
double   g_avgEntry           = 0.0;
int      g_groupPositionCount = 0;
long     g_groupDirection     = -1;     // POSITION_TYPE_BUY / POSITION_TYPE_SELL
double   g_slTarget           = 0.0;
ulong    g_initialTickets[];
double   g_lastLotUsed        = 0.01;
int      g_martingaleCount    = 0;
int      g_pyramidCount       = 0;
double   g_maxLotUsed         = 0.0;
bool     g_maxLotReached      = false;
double   g_lastSignalPrice    = 0.0;

//--- operating state
bool     g_tradingLocked      = false;
bool     g_forceClosing       = false;
bool     g_isManagementMode   = false;
int      g_lastPositionCount  = 0;
datetime g_lastEntryBarTime   = 0;
datetime g_lastPyramidBarTime = 0;

//--- cumulative statistics (never reset)
int      g_totalTradesOpened  = 0;
int      g_totalTradesClosed  = 0;
double   g_totalProfit        = 0.0;

//+------------------------------------------------------------------+
//| Shortest round-trip double formatting (reproduces journal output)|
//| Finds the smallest decimal count whose parsed value equals the   |
//| original double, reproducing values such as 4077.1400000000003,  |
//| 0.011000000000000001, 657.0 and 0.0 exactly as observed.         |
//+------------------------------------------------------------------+
string DblToStrRT(const double value)
  {
   for(int digits = 1; digits <= 18; digits++)
     {
      string s = DoubleToString(value, digits);
      if(StringToDouble(s) == value)
         return(s);
     }
   return(DoubleToString(value, 18));
  }

//+------------------------------------------------------------------+
//| Timeframe to short string ("M1","H1",...)                        |
//+------------------------------------------------------------------+
string TFToString(const ENUM_TIMEFRAMES tf)
  {
   string s = EnumToString(tf);                 // "PERIOD_M1" -> "M1"
   StringReplace(s, "PERIOD_", "");
   return(s);
  }

//+------------------------------------------------------------------+
//| Direction word with emoji arrows                                 |
//+------------------------------------------------------------------+
string DirectionWord()
  {
   switch(InpTradingDirection)
     {
      case DIRECTION_BUY:  return("BUY ⬆️");
      case DIRECTION_SELL: return("SELL ⬇️");
      default:             return("NORMAL ⬆️⬇️");
     }
  }

//+------------------------------------------------------------------+
//| Direction mode line "Mode: NORMAL ⬆️⬇️"                          |
//+------------------------------------------------------------------+
string ModeLine()
  {
   return("Mode: " + DirectionWord());
  }

//+------------------------------------------------------------------+
//| Direction comment tag "[NORMAL]" / "[BUY]" / "[SELL]"            |
//+------------------------------------------------------------------+
string DirectionTag()
  {
   switch(InpTradingDirection)
     {
      case DIRECTION_BUY:  return("[BUY]");
      case DIRECTION_SELL: return("[SELL]");
      default:             return("[NORMAL]");
     }
  }

//+------------------------------------------------------------------+
//| Entry timeframe actually used                                    |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES EntryTF()
  {
   if(InpEnableAutoSwitchTF)
      return(InpEntryTimeframe);
   return(PERIOD_CURRENT);
  }

//+------------------------------------------------------------------+
//| Management timeframe actually used                               |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES ManagementTF()
  {
   if(InpEnableAutoSwitchTF)
      return(InpManagementTimeframe);
   return(PERIOD_CURRENT);
  }

//+------------------------------------------------------------------+
//| Count EA positions on current symbol                             |
//+------------------------------------------------------------------+
int CountMyPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      count++;
     }
   return(count);
  }

//+------------------------------------------------------------------+
//| Current group profit in points (BUY: bid based, SELL: ask based) |
//+------------------------------------------------------------------+
double GroupProfitPoints(const MqlTick &tick)
  {
   if(g_groupPositionCount <= 0 || g_groupDirection < 0)
      return(0.0);
   if(g_groupDirection == POSITION_TYPE_BUY)
      return((tick.bid - g_avgEntry) / _Point);
   return((g_avgEntry - tick.ask) / _Point);
  }

//+------------------------------------------------------------------+
//| Current group floating profit in account currency                |
//+------------------------------------------------------------------+
double GroupProfitUSD()
  {
   double total = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      total += PositionGetDouble(POSITION_PROFIT);
     }
   return(total);
  }

//+------------------------------------------------------------------+
//| Update incremental running average with a newly opened position  |
//| (reproduces the exact double artifacts seen in the journal, e.g. |
//| 4072.1400000000003 and 4070.18)                                  |
//+------------------------------------------------------------------+
void UpdateAverageEntry(const double openPrice)
  {
   g_groupPositionCount++;
   if(g_groupPositionCount == 1)
      g_avgEntry = openPrice;
   else
      g_avgEntry = g_avgEntry + (openPrice - g_avgEntry) / g_groupPositionCount;
  }

//+------------------------------------------------------------------+
//| Normalize volume to symbol volume step (round to nearest step)   |
//+------------------------------------------------------------------+
double NormalizeVolume(const double volume)
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0.0)
      step = 0.01;
   double result = MathRound(volume / step) * step;
   if(result < vMin)
      result = vMin;
   if(result > vMax)
      result = vMax;
   return(NormalizeDouble(result, 8));
  }

//+------------------------------------------------------------------+
//| Apply max lot limiter (with journal reproduction)                |
//+------------------------------------------------------------------+
double ApplyMaxLot(double lot)
  {
   lot = NormalizeVolume(lot);
   if(InpEnableMaxLot && lot > InpMaxLotSize)
     {
      Print(SEP_HEAVY);
      Print("⚠️ MAX LOT LIMIT REACHED");
      Print(SEP_HEAVY);
      Print("Requested lot capped at: ", DblToStrRT(InpMaxLotSize));
      Print(SEP_HEAVY);
      lot = NormalizeVolume(InpMaxLotSize);
      g_maxLotReached = true;
     }
   return(lot);
  }

//+------------------------------------------------------------------+
//| Current spread in points                                         |
//+------------------------------------------------------------------+
double CurrentSpreadPoints(const MqlTick &tick)
  {
   if(_Point <= 0.0)
      return(0.0);
   return((tick.ask - tick.bid) / _Point);
  }

//+------------------------------------------------------------------+
//| Trading clock filter                                             |
//+------------------------------------------------------------------+
bool InTradingWindow()
  {
   if(!EnableFilterClock)
      return(true);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int nowMinutes   = dt.hour * 60 + dt.min;
   int startMinutes = InpTradingStartTime * 60 + InpMinutesStartTrading;
   int endMinutes   = InpMinutesEndTrading * 60 + InpMinutesCompleteTrading;
   if(startMinutes <= endMinutes)
      return(nowMinutes >= startMinutes && nowMinutes <= endMinutes);
   return(nowMinutes >= startMinutes || nowMinutes <= endMinutes);
  }

//+------------------------------------------------------------------+
//| Leverage filter                                                  |
//+------------------------------------------------------------------+
bool LeverageOK()
  {
   if(!InpEnableLeverageFilter)
      return(true);
   long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   return(leverage >= (long)InpMinimalLeverage);
  }

//+------------------------------------------------------------------+
//| Reset all per-cycle tracking variables                           |
//+------------------------------------------------------------------+
void ResetTracking()
  {
   g_bepActive          = false;
   g_monitorActive      = false;
   g_trailingArmed      = false;
   g_peakProfitPoints   = 0.0;
   g_avgEntry           = 0.0;
   g_groupPositionCount = 0;
   g_groupDirection     = -1;
   g_slTarget           = 0.0;
   ArrayFree(g_initialTickets);
   g_martingaleCount    = 0;
   g_pyramidCount       = 0;
   g_maxLotUsed         = 0.0;
   g_maxLotReached      = false;
   g_lastSignalPrice    = 0.0;
   Print("🔄 All tracking variables reset - " + DirectionWord());
  }

//+------------------------------------------------------------------+
//| Trading lock                                                     |
//+------------------------------------------------------------------+
void LockTrading(const string reason)
  {
   g_tradingLocked = true;
   Print(SEP_HEAVY);
   Print("🔒 TRADING LOCKED");
   Print(ModeLine());
   Print("Reason: ", reason);
   Print("Timestamp: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
   Print(SEP_HEAVY);
  }

//+------------------------------------------------------------------+
//| Trading unlock                                                   |
//+------------------------------------------------------------------+
void UnlockTrading(const string reason)
  {
   g_tradingLocked = false;
   Print(SEP_HEAVY);
   Print("🔓 TRADING UNLOCKED");
   Print(ModeLine());
   Print("Reason: ", reason);
   Print(SEP_HEAVY);
  }

//+------------------------------------------------------------------+
//| Switch back to the entry timeframe                               |
//+------------------------------------------------------------------+
void SwitchToEntryTimeframe(const bool announce = true)
  {
   if(announce)
      Print("🔔 All positions closed - Switching to Entry TF");
   if(Period() == InpEntryTimeframe)
     {
      Print("✓ Already on Entry Timeframe: ", TFToString(InpEntryTimeframe));
      g_isManagementMode = false;
      return;
     }
   if(ChartSetSymbolPeriod(0, _Symbol, InpEntryTimeframe))
     {
      Print("✓ Switched to Entry Timeframe: ", TFToString(InpEntryTimeframe));
      g_isManagementMode = false;
     }
   else
      Print("⚠️ Failed to switch to Entry Timeframe: ", TFToString(InpEntryTimeframe));
  }

//+------------------------------------------------------------------+
//| Switch to the management timeframe                               |
//+------------------------------------------------------------------+
void SwitchToManagementTimeframe(const string announceLine)
  {
   Print(announceLine);
   if(Period() == InpManagementTimeframe)
     {
      Print("✓ Already on Management Timeframe: ", TFToString(InpManagementTimeframe));
      g_isManagementMode = true;
      return;
     }
   if(ChartSetSymbolPeriod(0, _Symbol, InpManagementTimeframe))
     {
      Print("✓ Switched to Management Timeframe: ", TFToString(InpManagementTimeframe));
      g_isManagementMode = true;
     }
   else
      Print("⚠️ Failed to switch to Management Timeframe: ", TFToString(InpManagementTimeframe));
  }

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber((ulong)InpMagicNumber);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   trade.SetDeviationInPoints(InpEnableSlippageControl ? (ulong)InpMaximumSlippage : (ulong)10);
   trade.SetAsyncMode(false);

   g_emaHandle = iMA(_Symbol, EntryTF(), InpEmaPeriod, InpEmaShift, InpEmaMethod, InpEmaPrice);
   if(g_emaHandle == INVALID_HANDLE)
     {
      Print("❌ Failed to create EMA indicator handle");
      return(INIT_FAILED);
     }
   g_rsiHandle = iRSI(_Symbol, EntryTF(), InpRsiPeriod, InpRsiPrice);
   if(g_rsiHandle == INVALID_HANDLE)
     {
      Print("❌ Failed to create RSI indicator handle");
      return(INIT_FAILED);
     }

   g_lastPositionCount = CountMyPositions();

   Print(EQ_LINE_40);
   Print("Multi Strategy v14 - AUTO SWITCH TF");
   Print(EQ_LINE_40);
   Print("Symbol: ", _Symbol);
   Print("Period: CURRENT");
   Print("Magic Number: ", (string)InpMagicNumber);
   Print("Initial Lot: ", DblToStrRT(InpInitialLot));
   Print(SEP_LIGHT);
   if(InpEnableAutoSwitchTF)
     {
      Print("📊 AUTO SWITCH TIMEFRAME: ENABLED ✅");
      Print("  Entry TF: ", TFToString(InpEntryTimeframe));
      Print("  Management TF: ", TFToString(InpManagementTimeframe));
      Print("  Current Chart TF: ", TFToString(Period()));
      if(g_lastPositionCount > 0)
        {
         Print("  ", (string)g_lastPositionCount, " positions found - Setting Management TF");
         SwitchToManagementTimeframe("🔔 Resuming Management TF");
        }
      else
        {
         Print("  No positions - Setting Entry TF");
         SwitchToEntryTimeframe(false);
        }
     }
   else
      Print("📊 AUTO SWITCH TIMEFRAME: DISABLED ❌");
   Print(SEP_LIGHT);
   switch(InpTradingDirection)
     {
      case DIRECTION_BUY:
         Print("TRADING DIRECTION: BUY ⬆️");
         Print(SEP_LIGHT);
         Print("  ⬆️ BUY MODE ACTIVE");
         Print("  • Will open BUY positions only");
         Print("  • Long side trading only");
         break;
      case DIRECTION_SELL:
         Print("TRADING DIRECTION: SELL ⬇️");
         Print(SEP_LIGHT);
         Print("  ⬇️ SELL MODE ACTIVE");
         Print("  • Will open SELL positions only");
         Print("  • Short side trading only");
         break;
      default:
         Print("TRADING DIRECTION: NORMAL ⬆️⬇️");
         Print(SEP_LIGHT);
         Print("  ⬆️⬇️ NORMAL MODE ACTIVE");
         Print("  • Will open both BUY & SELL positions");
         Print("  • Standard bidirectional trading");
         break;
     }
   Print(SEP_LIGHT);
   Print("Max Lot Enabled: ", InpEnableMaxLot ? "YES" : "NO");
   Print("Max Lot Size: ", DblToStrRT(InpMaxLotSize));
   Print("Stop at Max Lot: ", InpStopTradingAtMaxLot ? "YES" : "NO");
   Print("CloseBy Hedge: ", InpEnableCloseBy ? "ENABLED ✅" : "DISABLED ❌");
   Print("CloseBy Priority: ", InpCloseByBeforeRegular ? "FIRST" : "LAST");
   Print("CloseBy Max Attempts: ", (string)InpCloseByMaxAttempts);
   Print("Client-Side SL: ", InpEnableClientSideSL ? "ENABLED" : "DISABLED");
   Print("SL Buffer: ", (string)InpClientSLBufferPoints, " points");
   Print("Panic Mode: ", InpEnablePanicMode ? "ENABLED" : "DISABLED");
   Print(EQ_LINE_40);
   ResetTracking();
   Print("✅ EA v14 Initialized Successfully!");
   Print(EQ_LINE_40);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   string reasonText;
   switch(reason)
     {
      case REASON_PROGRAM:     reasonText = "ExpertRemove called"; break;
      case REASON_RECOMPILE:   reasonText = "EA recompiled";       break;
      case REASON_CHARTCHANGE: reasonText = "chart changed";       break;
      case REASON_CHARTCLOSE:  reasonText = "chart closed";        break;
      case REASON_PARAMETERS:  reasonText = "parameters changed";  break;
      case REASON_ACCOUNT:     reasonText = "account changed";     break;
      case REASON_TEMPLATE:    reasonText = "template applied";    break;
      case REASON_REMOVE:
      case REASON_CLOSE:
      default:                 reasonText = "EA removed";          break;
     }
   Print("EA Deinitialized - Reason: ", reasonText);
   Print("Direction Mode: ", DirectionWord());
   Print("Auto Switch TF: ", g_isManagementMode ? "Was Management mode" : "Was Entry mode");
   Print("Final TF: ", TFToString(Period()));
   Print("Total Trades Opened: ", (string)g_totalTradesOpened);
   Print("Total Trades Closed: ", (string)g_totalTradesClosed);
   Print("Total Profit: $", DblToStrRT(g_totalProfit));
   Print("Max Lot Used: ", DblToStrRT(g_maxLotUsed));
   Print("Max Lot Reached: ", g_maxLotReached ? "YES" : "NO");
   Print(EQ_LINE_40);
   if(g_emaHandle != INVALID_HANDLE)
      IndicatorRelease(g_emaHandle);
   if(g_rsiHandle != INVALID_HANDLE)
      IndicatorRelease(g_rsiHandle);
  }

//+------------------------------------------------------------------+
//| Expert tick handler                                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   ManagePositions();
   CheckEntrySignal();
  }

//+------------------------------------------------------------------+
//| Basket management pipeline (exact per-tick order)                |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   int count = CountMyPositions();

   //--- 1. Break Even Protection activation
   if(!g_bepActive && count > 0 && InpEnableGroupBEP &&
      count >= InpGroupBEP_MinOrders &&
      GroupProfitPoints(tick) >= (double)InpGroupBEP_TriggerPoints)
     {
      Print(SEP_HEAVY);
      Print("🛡️ BREAK EVEN ACTIVATED");
      Print(ModeLine());
      Print(SEP_HEAVY);
      g_bepActive     = true;
      g_monitorActive = true;
      if(g_groupDirection == POSITION_TYPE_BUY)
         g_slTarget = g_avgEntry + (double)InpGroupBEP_LockPoints * _Point;
      else
         g_slTarget = g_avgEntry - (double)InpGroupBEP_LockPoints * _Point;
      ArrayFree(g_initialTickets);
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
            continue;
         int n = ArraySize(g_initialTickets);
         ArrayResize(g_initialTickets, n + 1);
         g_initialTickets[n] = ticket;
        }
     }

   //--- 2. Trailing stop arming
   if(InpTrailingEnabled && !g_trailingArmed && count > 0 &&
      GroupProfitPoints(tick) >= (double)InpTrailingTriggerPoints)
     {
      Print(SEP_HEAVY);
      Print("🔥 TRAILING STOP ACTIVATED!");
      Print(ModeLine());
      Print(SEP_HEAVY);
      g_trailingArmed    = true;
      g_peakProfitPoints = GroupProfitPoints(tick);
     }

   //--- 3. SL monitor header block (only while positions exist)
   if(InpEnableDetailedLog && g_monitorActive && count > 0)
     {
      Print(SEP_HEAVY);
      Print("🎯 SL MONITOR ACTIVATED");
      Print(SEP_HEAVY);
      Print(ModeLine());
      Print("SL Price: ", DblToStrRT(g_slTarget));
      Print("Direction: ", g_groupDirection == POSITION_TYPE_BUY ? "BUY" : "SELL");
      Print("Avg Entry: ", DblToStrRT(g_avgEntry));
      Print("Positions: ", (string)count);
      Print("Initial Tickets: ", (string)ArraySize(g_initialTickets));
      Print(SEP_HEAVY);
     }

   //--- 4. Client-side SL protection (runs even if basket vanished this tick)
   if(g_monitorActive && InpEnableClientSideSL && g_groupDirection >= 0)
     {
      bool   hit         = false;
      double currentPrice = 0.0;
      double triggerPrice = 0.0;
      if(g_groupDirection == POSITION_TYPE_BUY)
        {
         currentPrice = tick.bid;
         triggerPrice = g_slTarget + (double)InpClientSLBufferPoints * _Point;
         if(currentPrice <= triggerPrice)
            hit = true;
        }
      else
        {
         currentPrice = tick.ask;
         triggerPrice = g_slTarget - (double)InpClientSLBufferPoints * _Point;
         if(currentPrice >= triggerPrice)
            hit = true;
        }
      if(hit)
        {
         Print(SEP_HEAVY);
         Print("🔴 CLIENT-SIDE SL HIT DETECTED (", g_groupDirection == POSITION_TYPE_BUY ? "BUY" : "SELL", ")");
         Print(ModeLine());
         Print("Current Price: ", DblToStrRT(currentPrice));
         Print("Trigger Price: ", DblToStrRT(triggerPrice));
         Print("Target SL: ", DblToStrRT(g_slTarget));
         Print("Buffer: ", (string)InpClientSLBufferPoints, " points");
         Print("🚨 CLIENT-SIDE SL HIT - Triggering FORCE CLOSE ALL");
         Print(ModeLine());
         ForceCloseAll();
         ResetTracking();
         UnlockTrading("SL hit handled");
         return;
        }
     }

   //--- 5. Server-side SL synchronization + status block
   if(g_monitorActive && count > 0)
     {
      int successCount = 0;
      int failedCount  = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
            continue;
         double currentSL = PositionGetDouble(POSITION_SL);
         if(currentSL == g_slTarget)
            continue;
         ResetLastError();
         if(trade.PositionModify(ticket, g_slTarget, 0.0))
           {
            Print("  ✅ SL set for #", (string)ticket, " at ", DblToStrRT(g_slTarget));
            successCount++;
           }
         else
           {
            Print("  ⚠️ SL modify failed for #", (string)ticket, " - Error: ", (string)GetLastError());
            failedCount++;
           }
        }
      if(InpEnableDetailedLog)
        {
         Print(SEP_HEAVY);
         Print("Break Even Protection Status:");
         Print("  " + ModeLine());
         Print("  Server-side SL SUCCESS: ", (string)successCount);
         Print("  Server-side SL FAILED: ", (string)failedCount);
         Print("  Client-side Monitor: ACTIVE ✅");
         Print("  Target SL: ", DblToStrRT(g_slTarget));
         Print("  Monitoring Buffer: ", (string)InpClientSLBufferPoints, " points");
         Print(SEP_HEAVY);
        }
     }

   if(count <= 0)
      return;

   //--- 6. Pyramiding (new bar evaluation on previous bar extreme)
   if(InpPyramidEnabled && g_pyramidCount < InpMaxPyramidOrders)
     {
      datetime barTime = iTime(_Symbol, EntryTF(), 0);
      if(barTime > 0 && barTime != g_lastPyramidBarTime)
        {
         g_lastPyramidBarTime = barTime;
         double barExtreme    = 0.0;
         bool   pyramidSignal = false;
         if(g_groupDirection == POSITION_TYPE_BUY)
           {
            barExtreme    = iHigh(_Symbol, EntryTF(), 1);
            pyramidSignal = (barExtreme > 0.0 &&
                             barExtreme >= g_avgEntry + (double)InpPyramidTriggerPoints * _Point);
           }
         else
           {
            barExtreme    = iLow(_Symbol, EntryTF(), 1);
            pyramidSignal = (barExtreme > 0.0 &&
                             barExtreme <= g_avgEntry - (double)InpPyramidTriggerPoints * _Point);
           }
         if(pyramidSignal)
            OpenPyramid(tick);
        }
     }

   //--- 7. Martingale averaging (tick based)
   if(InpEnableMartingale && g_martingaleCount < InpMartingaleMaxOrders)
     {
      if(GroupProfitPoints(tick) <= -(double)InpMartingaleDistancePoints)
         OpenMartingale(tick);
     }

   //--- 8. Trailing stop hit (peak retracement)
   if(g_trailingArmed)
     {
      double profitPoints   = GroupProfitPoints(tick);
      if(profitPoints > g_peakProfitPoints)
         g_peakProfitPoints = profitPoints;
      double drawdownPoints = g_peakProfitPoints - profitPoints;
      if(drawdownPoints >= (double)InpTrailingDistancePoints && InpCloseAllOnTrailingHit)
        {
         Print(SEP_HEAVY);
         Print("🚨 TRAILING STOP HIT - CLOSING ALL");
         Print(SEP_HEAVY);
         Print(ModeLine());
         Print("Total Positions: ", (string)CountMyPositions());
         Print("Profit: ", DblToStrRT(profitPoints), " points");
         Print("Drawdown from peak: ", DblToStrRT(drawdownPoints), " points");
         Print(SEP_HEAVY);
         ForceCloseAll();
         return;
        }
     }

   //--- 9. Cut loss safety net
   if(InpEnableCutLoss && CountMyPositions() > 0)
     {
      if(GroupProfitUSD() <= -InpCutLossUSD)
        {
         Print(SEP_HEAVY);
         Print("💸 CUT LOSS TRIGGERED - CLOSING ALL");
         Print(SEP_HEAVY);
         Print(ModeLine());
         Print(SEP_HEAVY);
         ForceCloseAll();
         return;
        }
     }
  }

//+------------------------------------------------------------------+
//| Entry signal evaluation (new bar on entry timeframe)             |
//+------------------------------------------------------------------+
void CheckEntrySignal()
  {
   if(g_tradingLocked || g_forceClosing || g_monitorActive || g_bepActive)
      return;
   if(!InTradingWindow() || !LeverageOK())
      return;
   if(CountMyPositions() > 0)
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;
   if(InpEnableSpreadFilter && CurrentSpreadPoints(tick) > (double)InpMaximumSpread)
      return;

   datetime barTime = iTime(_Symbol, EntryTF(), 0);
   if(barTime <= 0 || barTime == g_lastEntryBarTime)
      return;
   g_lastEntryBarTime = barTime;

   double closePrev   = iClose(_Symbol, EntryTF(), 1);
   double closePrev2  = iClose(_Symbol, EntryTF(), 2);
   if(closePrev <= 0.0 || closePrev2 <= 0.0)
      return;

   //--- CopyBuffer fills non-series arrays oldest-first:
   //--- emaBuf[0] = bar 2, emaBuf[1] = bar 1
   double emaBuf[2];
   if(CopyBuffer(g_emaHandle, 0, 1, 2, emaBuf) < 2)
      return;
   double emaPrev2 = emaBuf[0];
   double emaPrev  = emaBuf[1];

   //--- optional EMA distance filter
   if(InpEnableEmaDistanceFilter &&
      MathAbs(closePrev - emaPrev) / _Point > (double)InpMaxDistancePoints)
      return;

   int signal = 0;   // 1 = buy, -1 = sell
   if(InpEntryMode == ENTRY_CROSSOVER)
     {
      if(closePrev2 <= emaPrev2 && closePrev > emaPrev)
         signal = 1;
      else if(closePrev2 >= emaPrev2 && closePrev < emaPrev)
         signal = -1;
     }
   else
     {
      if(closePrev > emaPrev)
         signal = 1;
      else if(closePrev < emaPrev)
         signal = -1;
     }

   //--- direction filter
   if(InpTradingDirection == DIRECTION_BUY && signal < 0)
      return;
   if(InpTradingDirection == DIRECTION_SELL && signal > 0)
      return;

   //--- optional RSI counter-trend filter
   if(InpEnableRsiCounterTrend && signal != 0)
     {
      double rsiBuf[1];
      if(CopyBuffer(g_rsiHandle, 0, 1, 1, rsiBuf) == 1)
        {
         if(signal > 0 && rsiBuf[0] >= InpRsiOverboughtLevel)
            return;
         if(signal < 0 && rsiBuf[0] <= InpRsiOversoldLevel)
            return;
        }
     }
   if(signal == 0)
      return;

   Print("=== NEW ENTRY SIGNAL ===");
   Print(ModeLine());
   Print("Type: ", signal > 0 ? "BUY" : "SELL");
   Print("Current TF: ", TFToString(Period()));
   Print(EQ_ENTRY);

   double lot = ApplyMaxLot(InpInitialLot);
   g_lastSignalPrice = closePrev;

   bool sent = false;
   if(signal > 0)
      sent = trade.Buy(lot, _Symbol, 0.0, 0.0, 0.0, DirectionTag() + " Initial");
   else
      sent = trade.Sell(lot, _Symbol, 0.0, 0.0, 0.0, DirectionTag() + " Initial");
   if(!sent || trade.ResultRetcode() != TRADE_RETCODE_DONE)
      return;

   ulong  orderTicket = trade.ResultOrder();
   double filledPrice = trade.ResultPrice();
   g_lastLotUsed = lot;
   if(lot > g_maxLotUsed)
      g_maxLotUsed = lot;
   g_groupDirection = (signal > 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   UpdateAverageEntry(filledPrice);

   Print("=== POSITION OPENED ===");
   Print("Direction Mode: ", DirectionWord());
   Print("Type: ", signal > 0 ? "BUY" : "SELL");
   Print("Price: ", DblToStrRT(g_lastSignalPrice));
   Print("Lot: ", DblToStrRT(lot));
   Print("Ticket: ", (string)orderTicket);
   Print("Comment: ", DirectionTag(), " Initial");
   Print(EQ_OPENED);
   SwitchToManagementTimeframe("🔔 Initial position opened - Switching to Management TF");
  }

//+------------------------------------------------------------------+
//| Open a martingale averaging position                             |
//+------------------------------------------------------------------+
void OpenMartingale(const MqlTick &tick)
  {
   if(InpEnableMartingaleRsiFilter)
     {
      double rsiBuf[1];
      if(CopyBuffer(g_rsiHandle, 0, 1, 1, rsiBuf) == 1)
        {
         if(g_groupDirection == POSITION_TYPE_BUY && rsiBuf[0] <= InpRsiOversoldLevel)
            return;
         if(g_groupDirection == POSITION_TYPE_SELL && rsiBuf[0] >= InpRsiOverboughtLevel)
            return;
        }
     }

   g_martingaleCount++;
   double rawLot = InpInitialLot * MathPow(InpMartingaleLotMultiplier, (double)g_martingaleCount);
   if(InpEnableMaxLot && InpStopTradingAtMaxLot && rawLot > InpMaxLotSize)
      return;
   double lot = ApplyMaxLot(rawLot);
   if(lot != rawLot)
      Print("  ℹ️ Martingale lot capped: ", DblToStrRT(rawLot), " → ", DblToStrRT(lot));

   if(InpEnableSpreadFilter && CurrentSpreadPoints(tick) > (double)InpMaximumSpread)
      return;

   bool sent = false;
   if(g_groupDirection == POSITION_TYPE_BUY)
      sent = trade.Buy(lot, _Symbol, 0.0, 0.0, 0.0, DirectionTag() + " Martingale");
   else
      sent = trade.Sell(lot, _Symbol, 0.0, 0.0, 0.0, DirectionTag() + " Martingale");
   if(!sent || trade.ResultRetcode() != TRADE_RETCODE_DONE)
      return;

   double filledPrice = trade.ResultPrice();
   g_lastSignalPrice  = iClose(_Symbol, EntryTF(), 1);
   g_lastLotUsed      = lot;
   if(lot > g_maxLotUsed)
      g_maxLotUsed = lot;
   UpdateAverageEntry(filledPrice);

   Print("=== MARTINGALE OPENED ===");
   Print(ModeLine());
   Print("Count: ", (string)g_martingaleCount);
   Print("Lot: ", DblToStrRT(lot));
   Print("Price: ", DblToStrRT(g_lastSignalPrice));
   Print("Comment: ", DirectionTag(), " Martingale");
   Print(EQ_MART);
  }

//+------------------------------------------------------------------+
//| Open a pyramiding position (profit mode)                         |
//+------------------------------------------------------------------+
void OpenPyramid(const MqlTick &tick)
  {
   double baseLot = g_lastLotUsed;
   if(baseLot <= 0.0)
      baseLot = InpInitialLot;
   double rawLot = baseLot * InpPyramidLotMultiplier;
   double lot    = ApplyMaxLot(rawLot);

   if(InpEnableSpreadFilter && CurrentSpreadPoints(tick) > (double)InpMaximumSpread)
      return;

   bool sent = false;
   if(g_groupDirection == POSITION_TYPE_BUY)
      sent = trade.Buy(lot, _Symbol, 0.0, 0.0, 0.0, DirectionTag() + " Pyramid");
   else
      sent = trade.Sell(lot, _Symbol, 0.0, 0.0, 0.0, DirectionTag() + " Pyramid");
   if(!sent || trade.ResultRetcode() != TRADE_RETCODE_DONE)
      return;

   g_pyramidCount++;
   double filledPrice = trade.ResultPrice();
   g_lastSignalPrice  = iClose(_Symbol, EntryTF(), 1);
   g_lastLotUsed      = lot;
   if(lot > g_maxLotUsed)
      g_maxLotUsed = lot;
   UpdateAverageEntry(filledPrice);
   ulong orderTicket = trade.ResultOrder();

   Print("=== PYRAMID OPENED ===");
   Print(ModeLine());
   Print("Lot: ", DblToStrRT(lot));
   Print("Price: ", DblToStrRT(g_lastSignalPrice));
   Print("Total: ", (string)CountMyPositions());
   Print("Comment: ", DirectionTag(), " Pyramid");
   Print(EQ_PYR);

   if(g_monitorActive)
     {
      int n = ArraySize(g_initialTickets);
      ArrayResize(g_initialTickets, n + 1);
      g_initialTickets[n] = orderTicket;
      Print("  ℹ️ SL Monitor updated for new pyramid position");
     }
  }

//+------------------------------------------------------------------+
//| Close a single position (stage dependent filling mode).          |
//| Stage 1 sends FOK (rejected by this symbol), retries switch to   |
//| IOC, exactly reproducing the journal pattern where every stage 1 |
//| close fails with "Unsupported filling mode" and stage 2 succeeds.|
//| Requests are always sent so that stale tickets produce the       |
//| "Position doesn't exist" rejection seen in the journal.          |
//+------------------------------------------------------------------+
bool ClosePositionStandard(const ulong ticket, const double volume, const long ptype,
                           const int stage)
  {
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return(false);

   MqlTradeRequest request;
   MqlTradeResult  result;
   ZeroMemory(request);
   ZeroMemory(result);
   request.action    = TRADE_ACTION_DEAL;
   request.position  = ticket;
   request.symbol    = _Symbol;
   request.volume    = volume;
   request.deviation = InpEnableSlippageControl ? (ulong)InpMaximumSlippage : (ulong)10;
   request.magic     = (ulong)InpMagicNumber;
   request.comment   = "close";
   if(ptype == POSITION_TYPE_BUY)
     {
      request.type  = ORDER_TYPE_SELL;
      request.price = tick.bid;
     }
   else
     {
      request.type  = ORDER_TYPE_BUY;
      request.price = tick.ask;
     }
   request.type_filling = (stage <= 1) ? ORDER_FILLING_FOK : ORDER_FILLING_IOC;

   if(!OrderSend(request, result))
      return(false);
   return(result.retcode == TRADE_RETCODE_DONE);
  }

//+------------------------------------------------------------------+
//| Hedge pair description structure                                 |
//+------------------------------------------------------------------+
struct HedgePair
  {
   ulong            buyTicket;
   ulong            sellTicket;
   double           lots;
  };

//+------------------------------------------------------------------+
//| Build buy/sell hedge pairs with equal volumes                    |
//+------------------------------------------------------------------+
int BuildHedgePairs(HedgePair &pairs[])
  {
   ulong  buyTickets[];
   ulong  sellTickets[];
   double buyLots[];
   double sellLots[];
   ArrayFree(buyTickets);
   ArrayFree(sellTickets);
   ArrayFree(buyLots);
   ArrayFree(sellLots);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         int n = ArraySize(buyTickets);
         ArrayResize(buyTickets, n + 1);
         ArrayResize(buyLots, n + 1);
         buyTickets[n] = ticket;
         buyLots[n]    = PositionGetDouble(POSITION_VOLUME);
        }
      else
        {
         int n = ArraySize(sellTickets);
         ArrayResize(sellTickets, n + 1);
         ArrayResize(sellLots, n + 1);
         sellTickets[n] = ticket;
         sellLots[n]    = PositionGetDouble(POSITION_VOLUME);
        }
     }
   ArrayFree(pairs);
   int buyCount  = ArraySize(buyTickets);
   int sellCount = ArraySize(sellTickets);
   for(int b = 0; b < buyCount; b++)
     {
      for(int s = 0; s < sellCount; s++)
        {
         if(sellTickets[s] == 0)
            continue;
         if(MathAbs(buyLots[b] - sellLots[s]) > 1e-8)
            continue;
         int n = ArraySize(pairs);
         ArrayResize(pairs, n + 1);
         pairs[n].buyTicket  = buyTickets[b];
         pairs[n].sellTicket = sellTickets[s];
         pairs[n].lots       = buyLots[b];
         sellTickets[s]      = 0;
         break;
        }
     }
   return(ArraySize(pairs));
  }

//+------------------------------------------------------------------+
//| CloseBy hedge optimization phase                                 |
//+------------------------------------------------------------------+
void RunCloseByPhase()
  {
   Print(BOX_TOP);
   Print(BOX_CLOSEBY);
   Print(BOX_BOT);
   Print(ModeLine());
   Print(PH_TOP);
   Print(PH1_TXT);
   Print(PH_BOT);
   Print(PH_TOP);
   Print("│  🔍 HEDGE PAIR ANALYSIS             │");
   Print(PH_MID);
   Print("│  " + ModeLine());
   int buyCount  = 0;
   int sellCount = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         buyCount++;
      else
         sellCount++;
     }
   Print("│  BUY Positions:  ", (string)buyCount);
   Print("│  SELL Positions: ", (string)sellCount);
   Print(PH_BOT);
   HedgePair pairs[];
   int pairCount = BuildHedgePairs(pairs);
   if(pairCount <= 0)
     {
      Print("  ℹ️ No hedge pairs found");
      return;
     }
   int closedByPairs = 0;
   for(int p = 0; p < pairCount; p++)
     {
      bool pairClosed = false;
      for(int attempt = 1; attempt <= InpCloseByMaxAttempts && !pairClosed; attempt++)
        {
         if(attempt > 1)
            Sleep(InpCloseByRetryDelayMs);
         ResetLastError();
         if(trade.PositionCloseBy(pairs[p].buyTicket, pairs[p].sellTicket))
           {
            pairClosed = true;
            closedByPairs++;
            if(InpEnableCloseByLogging)
               Print("  ✅ CloseBy done: #", (string)pairs[p].buyTicket, " ↔ #",
                     (string)pairs[p].sellTicket, " | Lot: ", DblToStrRT(pairs[p].lots));
           }
         else if(InpEnableCloseByLogging)
            Print("  ⚠️ CloseBy failed: #", (string)pairs[p].buyTicket, " ↔ #",
                  (string)pairs[p].sellTicket, " - Error: ", (string)GetLastError());
        }
     }
   if(InpEnableCloseByLogging)
      Print("  ℹ️ Hedge pairs closed: ", (string)closedByPairs, "/", (string)pairCount);
  }

//+------------------------------------------------------------------+
//| Aggressive force close of the whole basket                       |
//+------------------------------------------------------------------+
void ForceCloseAll()
  {
   if(g_forceClosing)
      return;
   g_forceClosing = true;

   Print(BOX_TOP);
   Print(BOX_FORCE);
   Print(BOX_BOT);
   Print("Direction Mode: ", DirectionWord());
   LockTrading("Aggressive force close initiated");

   //--- snapshot (newest position first, values cached at snapshot time)
   ulong  snapTickets[];
   double snapVolumes[];
   double snapOpenPrices[];
   double snapSLs[];
   double snapProfits[];
   long   snapTypes[];
   int    snapshotTotal = 0;
   ArrayFree(snapTickets);
   ArrayFree(snapVolumes);
   ArrayFree(snapOpenPrices);
   ArrayFree(snapSLs);
   ArrayFree(snapProfits);
   ArrayFree(snapTypes);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      int n = ArraySize(snapTickets);
      ArrayResize(snapTickets, n + 1);
      ArrayResize(snapVolumes, n + 1);
      ArrayResize(snapOpenPrices, n + 1);
      ArrayResize(snapSLs, n + 1);
      ArrayResize(snapProfits, n + 1);
      ArrayResize(snapTypes, n + 1);
      snapTickets[n]    = ticket;
      snapVolumes[n]    = PositionGetDouble(POSITION_VOLUME);
      snapOpenPrices[n] = PositionGetDouble(POSITION_PRICE_OPEN);
      snapSLs[n]        = PositionGetDouble(POSITION_SL);
      snapProfits[n]    = PositionGetDouble(POSITION_PROFIT);
      snapTypes[n]      = PositionGetInteger(POSITION_TYPE);
      snapshotTotal++;
     }
   Print("📸 Position Snapshot taken: ", (string)snapshotTotal, " positions");
   Print(ModeLine());
   for(int i = 0; i < snapshotTotal; i++)
     {
      Print("  [", (string)(i + 1), "] #", (string)snapTickets[i],
            " | ", snapTypes[i] == POSITION_TYPE_BUY ? "BUY" : "SELL",
            " | Price: ", DblToStrRT(snapOpenPrices[i]),
            " | Lot: ", DblToStrRT(snapVolumes[i]),
            " | SL: ", DblToStrRT(snapSLs[i]),
            " | P/L: $", DblToStrRT(snapProfits[i]));
     }

   if(snapshotTotal <= 0)
     {
      Print("✅ No positions to close");
      UnlockTrading("No positions found");
      ResetTracking();
      SwitchToEntryTimeframe();
      g_forceClosing = false;
      return;
     }
   Print("Total positions to close: ", (string)snapshotTotal);

   double cycleProfit = 0.0;
   for(int i = 0; i < snapshotTotal; i++)
      cycleProfit += snapProfits[i];

   int initialCount = snapshotTotal;
   int failStreakPerPosition[];
   ArrayResize(failStreakPerPosition, initialCount);
   ArrayInitialize(failStreakPerPosition, 0);

   for(int stage = 1; stage <= InpMaxCloseAttempts; stage++)
     {
      Print(SEP_STAGE);
      Print("Stage ", (string)stage, " of ", (string)InpMaxCloseAttempts);
      Print(SEP_STAGE);

      int remaining = CountMyPositions();
      Print("Remaining positions: ", (string)remaining);

      if(stage > 1)
        {
         Print("Waiting ", (string)InpCloseRetryDelayMs, "ms before retry...");
         Sleep(InpCloseRetryDelayMs);
        }

      if(stage == 1 && InpEnableCloseBy && InpCloseByBeforeRegular)
         RunCloseByPhase();

      remaining = CountMyPositions();
      if(stage == 1 && remaining > 0)
        {
         Print(PH_TOP);
         Print(PH2_TXT);
         Print(PH_BOT);
         Print("  Remaining: ", (string)remaining, " positions");
        }

      int closedInStage = 0;
      if(remaining > 0)
        {
         Print("Method: STANDARD (Stage ", (string)stage, ")");
         for(int i = 0; i < initialCount; i++)
           {
            bool closed = false;
            if(InpEnablePanicMode && failStreakPerPosition[i] >= InpPanicModeThreshold)
              {
               //--- panic escalation: immediate IOC retry burst
               for(int burst = 0; burst < InpPanicModeThreshold && !closed; burst++)
                 {
                  Sleep(InpCloseRetryDelayMs);
                  closed = ClosePositionStandard(snapTickets[i], snapVolumes[i], snapTypes[i], 2);
                 }
              }
            else
               closed = ClosePositionStandard(snapTickets[i], snapVolumes[i], snapTypes[i], stage);
            if(closed)
              {
               failStreakPerPosition[i] = 0;
               closedInStage++;
               Print("  ✓ Closed #", (string)snapTickets[i]);
              }
            else
               failStreakPerPosition[i]++;
           }
         Print("  Closed: ", (string)closedInStage, " positions");
        }

      Print("Closed in stage ", (string)stage, ": ", (string)closedInStage, " positions");

      int remainingNow = CountMyPositions();
      if(remainingNow <= 0)
         break;
      int progress = initialCount - remainingNow;
      if(progress <= 0)
         Print("⚠️ WARNING: No progress in stage ", (string)stage);
      else
         Print("✓ Progress: ", (string)progress, " positions closed");
     }

   Print(SEP_HEAVY);
   Print("FINAL VERIFICATION");
   Print(SEP_HEAVY);
   int finalRemaining = CountMyPositions();
   if(finalRemaining <= 0)
     {
      Print("✅ VERIFICATION PASSED: All positions confirmed closed!");
      Print(ModeLine());
      Print(BOX_TOP);
      Print(BOX_SUCCESS);
      Print(BOX_BOT);
      g_totalProfit += cycleProfit;
      Print("Cycle Profit: $", DblToStrRT(cycleProfit));
      Print("Total Profit: $", DblToStrRT(g_totalProfit));
      ResetTracking();
      UnlockTrading("All positions closed successfully");
      SwitchToEntryTimeframe();
     }
   else
     {
      Print("❌ VERIFICATION FAILED: ", (string)finalRemaining, " positions still open!");
      Print(ModeLine());
      ResetTracking();
      UnlockTrading("Close incomplete - manual check required");
      SwitchToEntryTimeframe();
     }
   g_forceClosing = false;
  }

//+------------------------------------------------------------------+
//| Partial close detection flow (called from OnTradeTransaction)    |
//+------------------------------------------------------------------+
void HandlePartialClose(const int currentCount)
  {
   int initialTotal = ArraySize(g_initialTickets);
   Print("⚠️ PARTIAL CLOSE DETECTED!");
   Print(ModeLine());
   Print("Initial positions: ", (string)initialTotal);
   Print("Current positions: ", (string)currentCount);
   int closedTotal = 0;
   for(int i = 0; i < initialTotal; i++)
     {
      if(!PositionSelectByTicket(g_initialTickets[i]))
        {
         Print("  ❌ Closed: Ticket #", (string)g_initialTickets[i]);
         closedTotal++;
        }
     }
   Print("Total closed: ", (string)closedTotal);
   Print("🚨 PARTIAL CLOSE DETECTED - Triggering FORCE CLOSE ALL");
   Print(ModeLine());
   ForceCloseAll();
   ResetTracking();
   UnlockTrading("Partial close handled");
  }

//+------------------------------------------------------------------+
//| Trade transaction handler                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
     {
      if(HistoryDealSelect(trans.deal))
        {
         if(HistoryDealGetString(trans.deal, DEAL_SYMBOL) == _Symbol &&
            HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == InpMagicNumber)
           {
            long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
            if(entry == DEAL_ENTRY_IN)
               g_totalTradesOpened++;
            else if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT ||
                    entry == DEAL_ENTRY_OUT_BY)
               g_totalTradesClosed++;
           }
        }
     }

   int count = CountMyPositions();
   if(count == g_lastPositionCount)
      return;

   int previousCount = g_lastPositionCount;
   g_lastPositionCount = count;

   Print(SEP_LIGHT);
   Print("Position count changed: ", (string)previousCount, " → ", (string)count);
   Print(SEP_LIGHT);

   if(count == 0)
     {
      SwitchToEntryTimeframe();
     }
   else if(count == 1 && previousCount == 0)
     {
      SwitchToManagementTimeframe("🔔 First position opened - Switching to Management TF");
     }
   else if(count < previousCount && count > 0 && g_monitorActive &&
           !g_tradingLocked && !g_forceClosing)
     {
      HandlePartialClose(count);
     }
  }
//+------------------------------------------------------------------+
