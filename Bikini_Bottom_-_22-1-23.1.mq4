//+------------------------------------------------------------------+
//|                                                                  |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "  "
#property version "9"
#property description "Bikini Bottom"
#property description "www.bikinibottom.io"
#property strict


//---
enum ENUM_LOT_MODE
  {
   LOT_MODE_FIXED = 1,   // Fixed Lot
   LOT_MODE_PERCENT = 2, // Percent Lot
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_TYPE_GRID_LOT
  {
   fix_lot = 0,    // Fixed Start Lot 0.01 / 0.01 / 0.01 / 0.01 / 0.01 /.............
   Summ_lot = 1,   // Summ Sart Lot   0.01 / 0.02 / 0.03 / 0.04 / 0.05 /.............
   Martingale = 2, // Martingale Lot  0.01 / 0.02 / 0.04 / 0.08 / 0.16 /.............
   Step_lot = 3    // Step Lot        0.01 / 0.01 / 0.01 / 0.02 / 0.02 / 0.02 / 0.03 / 0.03 / 0.03 / 0.04 / 0.04 / 0.04 /............
  };

//--- input parameters
extern string Version__ =  "--------------------------------------------------------------------";
extern string Version1__ = "---------------------- BIKINI BOTTOM ---------------------------";
extern string Version2__ = "--------------------------------------------------------------------";

input string   hint2       = "--------- Max Trades --------------";       //Max Trades and hard SL
input int      MaxBuy      = 10;    //Max buys
input int      MaxSell     = 10;    //Max sells

string InpChartDisplay__ = "------------------------DISPLAY INFO--------------------";
bool InpChartDisplay = true;              // Display Info
bool InpDisplayInpBackgroundColor = true; // Display background color
color InpBackgroundColor = DarkBlue;          // background color

extern string Switches = "--------------------------- CLOSE ALL ORDERS  --------------------------- ";
bool InpManualInitGrid = false; // Start MANUAL Order  Grid  (Only if A / B Enable)
bool InpOpenNewOrders = true;   // Open New Orders ?
bool OpenNewOrdersGrid = true;  // Enable Grid ?
extern bool InpCloseAllNow = false;    // closes all orders now
extern string Magic = "-------- MAGIC NUMBERS ---------";
string Magic_ = "------------------------------------------------------------------";
bool InpEnableEngineA = true;  // Enable Engine A   [BUY]
input int InpMagic = 686401;           // Magic Number  A
bool InpEnableEngineB = true;  // Enable Engine B   [SELL]
input int InpMagic2 = 106864;          // Magic Number  B

string ConfigLOTE__ = "-----------------------------CONFIG LOT ----------------------------------------";
ENUM_LOT_MODE InpLotMode = LOT_MODE_FIXED;  // Lot Mode
input double InpFixedLot = 0.1;                 // Fixed Lot
double InpPercentLot = 0.1;                       // Percent Lot

extern string BB_ConfigGrid__ = "---------------------------CONFIG GRID--------------------------------------";
input ENUM_TYPE_GRID_LOT TypeGridLot = Martingale; // Type Grid Lot
input double InpGridFactor = 1.00;                    // ****** GRID INCREMENT FACTOR ******
input double InpMinLot = 0.04;                     // Minimum Lot
input double InpMaxLot = 2;                        // Maximium Lot
int InpHedgex = 10;                           // After Level Change Lot A to B 
input bool GridAllDirect = false;                  // Enable Grid Dual Side
input int HardSL      = 11000;                     // ****** STOP LOSS ******

extern string BreakEven = "--------------------BREAK EVEN ----------------------";
bool InpUseBreakEven = true; // Use Break Even ?
//extern int InpBreakEvenStartPer = 50;  //Break Even Start Percentage
//extern int InpBreakEvenStopPer = 30; // Break Even Step Percentage
input int InpBreakEvenStart = 60;   //   Break Even Start
input int InpBreakEvenStop = 30;    //  Break Even Step

extern string PipStepConfig = "********************************* IMPORTANT *********************************";
input int InpTakeProfit = 120;                     // ****** TAKE PROFIT ******
input int InpGridSize = 80;                        // ****** STEP SIZE ******
input double InpGridStepMultiplier = 1.6;            // ****** STEP MULTIPLIER ******
input int InpGridStepActivationLayer = 2;          // Step size multiplier activation layer

string FilterOpenOneCandle__ = "--------------------Filter One Order by Candle--------------";
bool InpOpenOneCandle = false;                         // Open one order by candle
ENUM_TIMEFRAMES InpTimeframeBarOpen = PERIOD_M1; // Timeframe OpenOneCandle

double indicator_low;
double indicator_high;
double diff_highlow;
bool isbidgreaterthanima;

extern string MovingAverageConfig__ = "-----------------------------MOVING AVERAGE-----------------------";
ENUM_TIMEFRAMES InpMaFrame = PERIOD_M1; // Moving Average TimeFrame
input int InpMaPeriod = 5;                         // Moving Average Period
input ENUM_MA_METHOD InpMaMethod = MODE_EMA;       // Moving Average Method
input ENUM_APPLIED_PRICE InpMaPrice = PRICE_OPEN;  // Moving Average Price
int InpMaShift = 0;                          // Moving Average Shift
extern string RVOLConfig__="-------------------------RVOL-------------------------------";
input bool RVOL_ENABLE = true;
input int days1 = 5; //Days look back average
input double RVOL_MAX = 6;

string HILOConfig__ = "-----------------------------HILO--------------------";
bool EnableSinalHILO = false;                   //Enable Sinal  HILO
bool InpHILOFilterInverter = false;            // If True Invert Filter
ENUM_TIMEFRAMES InpHILOFrame = PERIOD_M1; // HILO TimeFrame
int InpHILOPeriod = 3;                         // HILO Period
ENUM_MA_METHOD InpHILOMethod = MODE_EMA;       // HILO Method
int InpHILOShift = 0;                          // HILO Shift

input    string      TRADE_MANAGEMENT= "--------------------------- TRADE MANAGEMENT ---------------------------";
input    bool        EnableProfitClose  = true;        // Minimum Profit Close (True/False)
input    int         minTrades       = 2;           // Min Amount of Trades Per Side Close Profit (Buy/Sell)
input    double      minProfit1       = 50;          // Floating Profit Value ($)

input    string      TIME_MANAGEMENT = "--------------------------- TIME MANAGEMENT 1 ---------------------------";
input    int         maxTime         = 1000;          // Max Time Order is Open (Minutes)
input    double      timeProfit      = -50;           // Revised Floating Profit 

input    string      TIME_MANAGEMENT2 = "--------------------------- TIME MANAGEMENT 2 ---------------------------";
input    int         maxTime2        = 2880;          // Max Time Order is Open (Minutes)
input    double      timeProfit2     = -200;           // Revised Floating Profit 

string      CHART_MANAGEMENT= "--------------------------- CHART MANAGEMENT ---------------------------";
//input    string      symbol          = "EURUSD";    // Symbol
int         maxCharts       = 2;           // Max Charts

extern string EquitySTOP__ = "------------------------EQUITY PROTECTION  ---------------";
bool InpUseEquityStop = true;        // Use EquityStop?
input double InpTotalEquityRisk = 3;    // Total % Risk to EquityStop
bool InpAlertPushEquityLoss = false; //Send Alert to Celular
bool InpCloseAllEquityLoss = true;  // Close all orders in TotalEquityRisk
input bool  InpCloseRemoveEA        = true;  //Remove EA and close chart after Equity stop closes trades


/////////////////////////////////////////////////////
extern string TwoLotSize = "UTC +3 = Asian (00:00 - 10:00), NY (13:00 - 21:00), London (17:30 - 9:30)";
input double InpConsolidatingRatio = 0.5; // Consolidating/Trending Ratio
input double Starting_Lot = 0.1; // Starting Lot Slot 1
input double Starting_Lot2 = 0.07; // Starting Lot Slot 2
input double Starting_Lot3 = 0.05; // Starting Lot Slot 3
input double Starting_Lot4 = 0.1; // Starting Lot Slot 4
input string Lot1_Start = "00:00"; // Lot 1 Start Trading
input string Lot1_Stop = "11:00"; // Lot 1 Stop Trading

input string Lot2_Start = "11:01"; // Lot 2 Start Trading
input string Lot2_Stop = "14:00"; // Lot 2 Stop Trading

input string Lot3_Start = "18:00"; // Lot 3 Start Trading
input string Lot3_Stop = "21:00"; // Lot 3 Stop Trading


input string Lot4_Start = "21:01"; // Lot 4 Start Trading
input string Lot4_Stop = "23:54"; // Lot 4 Stop Trading
///////////////////////////////////////////////
extern string TimeFilter__ = "-------------------------Filter DateTime---------------------------";
extern string InpStartHour = "00:00";
extern string InpEndHour = "14:00";
extern string InpStartHour1 = "18:30";
extern string InpEndHour1 = "23:54";
bool InpUtilizeTimeFilter = true;
bool InpTrade_in_Monday = true;
bool InpTrade_in_Tuesday = true;
bool InpTrade_in_Wednesday = true;
bool InpTrade_in_Thursday = true;
extern bool InpTrade_in_Friday = true;

//--------------------------------RVOL--------------------------------------+
double RVOL_1min1 = iCustom(_Symbol, PERIOD_M1,"RVOL" , days1, 3, 1);
double RVOL_1min2 = iCustom(_Symbol, PERIOD_M1,"RVOL" , 5, 3, 1);
double RVOL_5min = iCustom(_Symbol, PERIOD_M5,"RVOL" , 5, 3, 1);
double RVOL_15min = iCustom(_Symbol, PERIOD_M15,"RVOL" , 5, 3, 1);

//+------------------------------------------------------------------+
//| Non Visible Inputs                                               |
//+------------------------------------------------------------------+

string FilterSpread__ = "----------------------------Filter Max Spread--------------------";
int InpMaxSpread = 5000; // Max Spread in Pips

string TrailingStop__ = "--------------------Trailling Stop--------------";
bool InpUseTrailingStop = false; // Use Trailling Stop´?
int InpTrailStart = 20;          //   TraillingStart
int InpTrailStop = 20;           // Size Trailling stop

int InpGridStepLot = 4;                      // STEP LOT (If  Step Lot)

string MinimalProfitClose__ = "--------------------Minimal Profit Close/ Protect Grid --------------";
bool InpEnableMinProfit = false;  // Enable  Minimal Profit Close
bool ProtectGridLastFist = false; // Enable Protect Grid Last save Firsts
double MinProfit = 10.00;        // Minimal Profit Close /Protect Grid
int QtdTradesMinProfit = 10;      // Qtd Trades to Minimal Profit Close/ Protect Grid

string TakeEquitySTOP__ = "------------------------Take  Equity STOP ---------------";
bool InpUseTakeEquityStop = false;   // Usar Take EquityStop?
double InpProfitCloseandSTOP = 50.0; // Closes all orders once Float hits this $ amount

string EquityCaution__ = "------------------------Filter Caution of Equity ---------------";
bool InpUseEquityCaution = false;                       //  EquityCaution?
double InpTotalEquityRiskCaution = 20;                 // Total % Risk to EquityCaution
ENUM_TIMEFRAMES InpTimeframeEquityCaution = PERIOD_D1; // Timeframe as EquityCaution

string Config__ = "---------------------------Config--------------------------------------";
int InpHedge = 10;        // Hedge After Level
int InpDailyTarget = 50; // Daily Target in Money


string _Visor1_ = "-----------------------------Visor 1 --------------------";
bool Visor1_Show_the_Time = false;
bool Visor1_Show_the_Price = false;

color Visor1_Price_Up_Color = LawnGreen;
color Visor1_Price_Down_Color = Tomato;
int Visor1_Price_X_Position = 10;
int Visor1_Price_Y_Position = 10;
int Visor1_Price_Size = 20;
double Visor1_Old_Price;

int Visor1_Porcent_X_Position = 10;
int Visor1_Porcent_Y_Position = 70;
int Visor1_Porcent_Size = 20;

int Visor1_Symbol_X_Position = 10;
int Visor1_Symbol_Y_Position = 40;
int Visor1_Symbol_Size = 20;

int Visor1_Chart_Timezone = -5;
color Visor1_Time_Color = Yellow;
int Visor1_Time_Size = 17;
int Visor1_Time_X_Position = 10;
int Visor1_Time_Y_Position = 10;

int Visor1_Spread_Size = 10;
int Visor1_Spread_X_Position = 10;
int Visor1_Spread_Y_Position = 100;


color Visor1_FontColor = Black;

int Visor1_Sinal = 0;

//LOT_MODE_FIXED
//---
int SlipPage = 3;
bool GridAll = false;

//---

bool m_hedging1, m_target_filter1;
int m_direction1, m_current_day1, m_previous_day1;
double m_level1, m_buyer1, m_seller1, m_target1, m_profit1;
double m_pip1, m_size1, m_take1;
datetime m_datetime_ultcandleopen1;
datetime m_time_equityrisk1;
double m_mediaprice1, profit1;
int m_orders_count1;
double m_lastlot1;

bool m_hedging2, m_target_filter2;
int m_direction2, m_current_day2, m_previous_day2;
double m_level2, m_buyer2, m_seller2, m_target2, m_profit2;
double m_pip2, m_size2, m_take2;
datetime m_datetime_ultcandleopen2;
datetime m_time_equityrisk2;
double m_mediaprice2;
int m_orders_count2;
double m_lastlot2, profit2;

string InpADXtext;

int slippage = 10;

string m_symbol;
bool m_news_time;
double m_spreadX;
double Spread;
bool m_initpainel;
string m_filters_on;
double m_profit_all;
datetime m_time_equityriskstopall;

//Enter Your Expiry Date inside the " "
string expired = "2025.10.01";
//====================================
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!IsTradeAllowed())
      Alert("Not TradeAllowed");

   Spread = 2.0;
   if(InpManualInitGrid)
     {

      DrawRects(250, 15, Gray, 80, 50, "SELL");
      DrawRects(420, 15, Gray, 80, 50, "BUY");
      DrawRects(600, 15, Gray, 80, 50, "CLOSE ALL BUY");
      DrawRects(770, 15, Gray, 80, 50, "CLOSE ALL SELL");
     }

   EventSetTimer(1);
   
   
//---
   m_symbol = Symbol();

   if(Digits == 3 || Digits == 5)
      m_pip1 = 10.0 * Point;
   else
      m_pip1 = Point;
   m_size1 = InpGridSize * m_pip1;
   m_take1 = InpTakeProfit * m_pip1;
   m_hedging1 = false;
   m_target_filter1 = false;
   m_direction1 = 0;

   m_datetime_ultcandleopen1 = -1;
   m_time_equityrisk1 = -1;
   m_orders_count1 = 0;
   m_lastlot1 = 0;

   if(Digits == 3 || Digits == 5)
      m_pip2 = 10.0 * Point;
   else
      m_pip2 = Point;
   m_size2 = InpGridSize * m_pip2;
   m_take2 = InpTakeProfit * m_pip2;
   m_hedging2 = false;
   m_target_filter2 = false;
   m_direction2 = 0;

   m_datetime_ultcandleopen2 = -1;
   m_time_equityrisk2 = -1;
   m_orders_count2 = 0;
   m_lastlot2 = 0;

   m_filters_on = "";
   m_initpainel = true;
   HideTestIndicators(True);

//---
   printf("Chicken in the Corn");
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete("Market_Price_Label");
   ObjectDelete("Time_Label");
   ObjectDelete("Porcent_Price_Label");
   ObjectDelete("Spread_Price_Label");
   ObjectDelete("Simbol_Price_Label");
   HideTestIndicators(False);
//---
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Informacoes()
  {

   string Ls_64;

   int Li_84;

   if(!IsOptimization())
     {
      Visor1Handling();
      Ls_64 = "\n\n  ";
      Ls_64 = "\n\n  ";
      Ls_64 = "\n\n  ";
      Ls_64 = "\n\n  ";
      Ls_64 = "\n\n  ";
      //Ls_64 = Ls_64 + "==========================\n";
      //Ls_64 = Ls_64 + " " + " Chicken in the Corn " + "\n";
      //Ls_64 = Ls_64 + "==========================\n";
      // Ls_64 = Ls_64 + "  Broker:  " + AccountCompany() + "\n";
      //Ls_64 = Ls_64 + "  Time of Broker:" + TimeToStr(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n";
      // Ls_64 = Ls_64 + "  Currenci: " + AccountCurrency() + "\n";   Ls_64 = "\n\n  ";
      //Ls_64 = "\n\n  ";
      //Ls_64 = "\n\n  ";
      //Ls_64 = "\n\n  ";
      //Ls_64 = "\n\n  ";
      //Ls_64 = Ls_64 + "  Spread: " + m_spreadX + " pips\n";
      //Ls_64 = Ls_64 + "==========================\n";
      //Ls_64 = Ls_64 + "  ADX Value : " + (string)InpADXtext + "\n";
      //Ls_64 = Ls_64 + "  TakeProfit: " + (string)InpTakeProfit + " Pips \n";
      //Ls_64 = Ls_64 + "  Lot Mode : " + (string)InpLotMode + "  \n";
      //Ls_64 = Ls_64 + "  Exponent Factor: " + (string)InpGridFactor + " pips\n";
      //Ls_64 = Ls_64 + "  Daily Target: " + (string)InpDailyTarget + "\n";
      // Ls_64 = Ls_64 + "  Hedge After Level: " + (string)InpHedge + " \n";
      //Ls_64 = Ls_64 + "  InpMaxSpread: " + (string)InpMaxSpread + " pips\n";
      //Ls_64 = Ls_64 + "==========================\n";
      // Ls_64 = Ls_64 + "  Spread: " + (string)MarketInfo(Symbol(), MODE_SPREAD) + " \n";
      //Ls_64 = Ls_64 + "  Equity:      " + DoubleToStr(AccountEquity(), 2) + " \n";
      //Ls_64 = Ls_64 + "  Last Lot : | A : " + DoubleToStr(m_lastlot1, 2) + " | B : " + DoubleToStr(m_lastlot2, 2) + " \n";
      //Ls_64 = Ls_64 + "  Orders Opens :   " + string(CountTrades()) + " | A : " + (string)m_orders_count1 + " | B : " + (string)m_orders_count2 + " \n";
      //Ls_64 = Ls_64 + "  Profit/Loss: " + DoubleToStr(m_profit_all, 2) + " | A : " + DoubleToStr(CalculateProfit(InpMagic), 2) + " | B : " + DoubleToStr(CalculateProfit(InpMagic2), 2) + " \n";
      //Ls_64 = Ls_64 + " ==========================\n";
      //Ls_64 = Ls_64 + " EquityCautionFilter : " + (string)InpUseEquityCaution + " \n";
      //Ls_64 = Ls_64 + " TotalEquityRiskCaution : " + DoubleToStr(InpTotalEquityRiskCaution, 2) + " % \n";
      //Ls_64 = Ls_64 + " EquityStopFilter : " + (string)InpUseEquityStop + " \n";
      //Ls_64 = Ls_64 + " TotalEquityRiskStop : " + DoubleToStr(InpTotalEquityRisk, 2) + " % \n";
      //Ls_64 = Ls_64 + " NewsFilter : " + (string)UseNewsFilter + " \n";
      ////Ls_64 = Ls_64 + " TimeFilter : " + (string)InpUtilizeTimeFilter + " \n";
      //Ls_64 = Ls_64 + " ==========================\n";
      //Ls_64 = Ls_64 + m_filters_on;
      
	   Comment(Ls_64);

      Li_84 = 16;
      if(InpDisplayInpBackgroundColor)
        {
         if(m_initpainel || Seconds() % 5 == 0)
           {
            m_initpainel = FALSE;
            for(int count_88 = 0; count_88 < 12; count_88++)
              {
               for(int count_92 = 1; count_92 < Li_84; count_92++)
                 {
                  ObjectDelete("background" + (string)count_88 + (string)count_92);
                  ObjectDelete("background" + (string)count_88 + ((string)(count_92 + 1)));
                  ObjectDelete("background" + (string)count_88 + ((string)(count_92 + 2)));
                  ObjectCreate("background" + (string)count_88 + (string)count_92, OBJ_LABEL, 0, 0, 0);
                  ObjectSetText("background" + (string)count_88 + (string)count_92, "n", 30, "Wingdings", InpBackgroundColor);
                  ObjectSet("background" + (string)count_88 + (string)count_92, OBJPROP_XDISTANCE, 26.8 * count_88);
                  ObjectSet("background" + (string)count_88 + (string)count_92, OBJPROP_YDISTANCE, 28.5 * count_92 + 9);
                 }
              }
           }
        }
      else
        {
         if(m_initpainel || Seconds() % 5 == 0)
           {
            m_initpainel = FALSE;
            for(int count_88 = 0; count_88 < 9; count_88++)
              {
               for(int count_92 = 0; count_92 < Li_84; count_92++)
                 {
                  ObjectDelete("background" + (string)count_88 + (string)count_92);
                  ObjectDelete("background" + (string)count_88 + ((string)(count_92 + 1)));
                  ObjectDelete("background" + (string)count_88 + ((string)(count_92 + 2)));
                 }
              }
           }
        }
     }
  }

bool checkSlot1()
{

   datetime t=TimeCurrent();
   datetime time_begin1=StringToTime(TimeToString(t, TIME_DATE)+" "+Lot1_Start);
   datetime time_end1=  StringToTime(TimeToString(t, TIME_DATE)+" "+Lot1_Stop);
 
   
   if( (TimeCurrent() >= time_begin1  && TimeCurrent() < time_end1)  )
   {
      
         return true;
      
   } 
   return false;
} 



bool checkSlot2()
{

   datetime t=TimeCurrent();
   datetime time_begin1=StringToTime(TimeToString(t, TIME_DATE)+" "+Lot2_Start);
   datetime time_end1=  StringToTime(TimeToString(t, TIME_DATE)+" "+Lot2_Stop);
 
   
   if( (TimeCurrent() >= time_begin1  && TimeCurrent() < time_end1)  )
   {
      
         return true;
      
   } 
   return false;
} 


bool checkSlot3()
{

   datetime t=TimeCurrent();
   datetime time_begin1=StringToTime(TimeToString(t, TIME_DATE)+" "+Lot3_Start);
   datetime time_end1=  StringToTime(TimeToString(t, TIME_DATE)+" "+Lot3_Stop);
 
   
   if( (TimeCurrent() >= time_begin1  && TimeCurrent() < time_end1)  )
   {
      
         return true;
      
   } 
   return false;
} 


bool checkSlot4()
{

   datetime t=TimeCurrent();
   datetime time_begin1=StringToTime(TimeToString(t, TIME_DATE)+" "+Lot4_Start);
   datetime time_end1=  StringToTime(TimeToString(t, TIME_DATE)+" "+Lot4_Stop);
 
   
   if( (TimeCurrent() >= time_begin1  && TimeCurrent() < time_end1)  )
   {
      
         return true;
      
   } 
   return false;
} 

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(TimeCurrent() > StringToTime(expired))
     {
      ShowAlert("EX", "LICENSE EXPIRED !!. PLEASE CONTACT @bikinibottom ", (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0) / 2, 8);
      return;
     }
   else ObjectDelete(0, "EX");

   if(CountTrades() == 0)
      {
      m_size1 = InpGridSize * m_pip1;
      m_size2 = InpGridSize * m_pip2;
      if(InpGridStepActivationLayer == 1)
         {
         m_size1 += InpGridStepMultiplier * InpGridSize * m_pip1;
         m_size2 += InpGridStepMultiplier * InpGridSize * m_pip2;
         }
      }


   bool TradeNow = true;
   if(m_orders_count1 == 0)
      ObjectDelete("AvgA");

   if(m_orders_count2 == 0)
      ObjectDelete("AvgB");

   m_profit_all = CalculateProfit();

   if(InpCloseAllNow)
     {
      CloseThisSymbolAll(InpMagic);
      CloseThisSymbolAll(InpMagic2);
      InpManualInitGrid = true;
     }

   if(InpUseTakeEquityStop == true && m_profit_all >= InpProfitCloseandSTOP)
     {
      CloseThisSymbolAll(InpMagic);
      CloseThisSymbolAll(InpMagic2);
     }

   m_lastlot2 = FindLastSellLot(InpMagic2);
   m_lastlot1 = FindLastBuyLot(InpMagic);

   if(InpManualInitGrid)
     {
      if(m_lastlot1 > 0 || !InpEnableEngineA)
        {
         ObjectSetInteger(0, "_lBUY", OBJPROP_BGCOLOR, Gray);
         ObjectSetInteger(0, "_lCLOSE ALL BUY", OBJPROP_BGCOLOR, Green);
        }
      else
        {
         ObjectSetInteger(0, "_lBUY", OBJPROP_BGCOLOR, Blue);
         ObjectSetInteger(0, "_lCLOSE ALL BUY", OBJPROP_BGCOLOR, Gray);
        }

      if(m_lastlot2 > 0 || !InpEnableEngineB)
        {
         ObjectSetInteger(0, "_lSELL", OBJPROP_BGCOLOR, Gray);
         ObjectSetInteger(0, "_lCLOSE ALL SELL", OBJPROP_BGCOLOR, Green);
        }
      else
        {
         ObjectSetInteger(0, "_lSELL", OBJPROP_BGCOLOR, Red);
         ObjectSetInteger(0, "_lCLOSE ALL SELL", OBJPROP_BGCOLOR, Gray);
        }

      if(ObjectGetInteger(0, "_lBUY", OBJPROP_STATE) && !(m_orders_count1 > 0 || !InpEnableEngineA))
        {
         BB("A", 1, 0, true, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
                      m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
                      m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
                      m_time_equityrisk1, profit1);
         //  Alert("BUY");
         ObjectSetInteger(0, "_lBUY", OBJPROP_STATE, false);
        }

      if(ObjectGetInteger(0, "_lSELL", OBJPROP_STATE) && !(m_orders_count2 > 0 || !InpEnableEngineA))
        {
         BB("B", -1, 0, true, InpMagic2, m_orders_count2, m_mediaprice2, m_hedging2,
                      m_target_filter2, m_direction2, m_current_day2, m_previous_day2,
                      m_level2, m_buyer2, m_seller2, m_target2, m_profit2, m_pip2,
                      m_size2, m_take2, m_datetime_ultcandleopen2,
                      m_time_equityrisk2, profit2);
         // Alert("SELL");
         ObjectSetInteger(0, "_lSELL", OBJPROP_STATE, false);
        }

      if(ObjectGetInteger(0, "_lCLOSE ALL SELL", OBJPROP_STATE))
        {
         // Alert("CLOSE ALL SELL");
         CloseThisSymbolAll(InpMagic2);
         ObjectSetInteger(0, "_lCLOSE ALL SELL", OBJPROP_STATE, false);
        }

      if(ObjectGetInteger(0, "_lCLOSE ALL BUY", OBJPROP_STATE))
        {
         //  Alert("CLOSE ALL BUY");
         CloseThisSymbolAll(InpMagic);
         ObjectSetInteger(0, "_lCLOSE ALL BUY", OBJPROP_STATE, false);
        }
     }

   if(CountTrades() == 0 && GetLastError() == ERR_NOT_ENOUGH_MONEY)
     {
      if(InpCloseRemoveEA)
        {
         ExpertRemove();
         ChartClose();
         return;
        }
     }

   if(InpUseEquityStop)
     {
      if(m_profit_all < 0.0 && MathAbs(m_profit_all) > InpTotalEquityRisk / 100.0 * AccountEquity())
        {
         if(InpCloseAllEquityLoss)
           {
            CloseThisSymbolAll(InpMagic);
            CloseThisSymbolAll(InpMagic2);
            SendNotification("Equity Protect Triggered for" + Symbol());
            Print("Closed All to Stop Out");

            if(InpCloseRemoveEA)
              {
               ExpertRemove();
               ChartClose();
               return;
              }
           }
         if(InpAlertPushEquityLoss) SendNotification("EquityLoss Alert " + (string)m_profit_all);
         m_time_equityriskstopall = iTime(NULL, PERIOD_MN1, 0);
         m_filters_on += "Filter UseEquityStop ON \n";
         return;
        }
      else
        {
         m_time_equityriskstopall = -1;
        }
     }

   if(InpChartDisplay) Informacoes();
   RefreshRates();

   if(m_time_equityriskstopall == iTime(NULL, PERIOD_MN1, 0) && (m_profit_all < 0.0 && MathAbs(m_profit_all) > InpTotalEquityRisk / 100.0 * AccountEquity()))
     {
      TradeNow = false;
     }


//FILTER SPREAD
   m_spreadX = (double)MarketInfo(Symbol(), MODE_SPREAD) * m_pip2;
   if((int)MarketInfo(Symbol(), MODE_SPREAD) > InpMaxSpread)
     {
      m_filters_on += "Filter InpMaxSpread ON \n";
      TradeNow = false;
     }

//FILTER DATETIME
   if(InpUtilizeTimeFilter && !TimeFilter())
     {
      m_filters_on += "Filter TimeFilter ON \n";
      TradeNow = false;
     }

   int Sinal = 0;

   int SinalMA = 0;
   int SinalHilo = 0;

   if(iClose(NULL, 0, 0) > iMA(NULL, InpMaFrame, InpMaPeriod, 0, InpMaMethod, InpMaPrice, InpMaShift))
      SinalMA = 1;
   if(iClose(NULL, 0, 0) < iMA(NULL, InpMaFrame, InpMaPeriod, 0, InpMaMethod, InpMaPrice, InpMaShift))
      SinalMA = -1;

   SinalHilo = GetSinalHILO();

   Sinal = (SinalHilo + SinalMA) / (1 + DivSinalHILO());

   double LotsHedge = 0;

//FILTER EquityCaution
   if(m_orders_count1 == 0)
      m_time_equityrisk1 = -1;

//Se todos Motores estiverem desabilitados
   if(!InpEnableEngineB && !InpEnableEngineA)
     {
      if(m_time_equityrisk1 == iTime(NULL, InpTimeframeEquityCaution, 0))
        {
         m_filters_on += "Filter EquityCaution S ON \n";
         TradeNow = false;
        }

      BB("S", Sinal, TradeNow, LotsHedge, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
                   m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
                   m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
                   m_time_equityrisk1, profit1);
     }
   else
     {
      if(!InpManualInitGrid)
        {
         if(m_time_equityrisk1 == iTime(NULL, InpTimeframeEquityCaution, 0) && m_time_equityrisk2 != iTime(NULL, InpTimeframeEquityCaution, 0))
           {
            m_filters_on += "Filter EquityCaution A ON \n";
            TradeNow = false;
           }

         // if(m_time_equityrisk2 == iTime(NULL, InpTimeframeEquityCaution, 0)) {
         if(m_orders_count2 > InpHedgex && InpHedgex != 0)
           {
            LotsHedge = m_lastlot2 / InpGridFactor;
           }

         if(Sinal == 1 && InpEnableEngineA)
            BB("A", 1, TradeNow, LotsHedge, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
                         m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
                         m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
                         m_time_equityrisk1, profit1);

         if(m_orders_count2 == 0)
            m_time_equityrisk2 = -1;

         if(m_time_equityrisk2 == iTime(NULL, InpTimeframeEquityCaution, 0) && m_time_equityrisk1 != iTime(NULL, InpTimeframeEquityCaution, 0))
           {
            m_filters_on += "Filter EquityCaution B ON \n";
            TradeNow = false;
           }

         // if(m_time_equityrisk1 == iTime(NULL, InpTimeframeEquityCaution, 0)) {
         if(m_orders_count1 > InpHedgex && InpHedgex != 0)
           {
            LotsHedge = m_lastlot1 / InpGridFactor;
           }

         if(Sinal == -1 && InpEnableEngineB)
            BB("B", -1, TradeNow, LotsHedge, InpMagic2, m_orders_count2, m_mediaprice2, m_hedging2,
                         m_target_filter2, m_direction2, m_current_day2, m_previous_day2,
                         m_level2, m_buyer2, m_seller2, m_target2, m_profit2, m_pip2,
                         m_size2, m_take2, m_datetime_ultcandleopen2,
                         m_time_equityrisk2, profit2);
        }
      else
        {

         BB("A", 0, TradeNow, LotsHedge, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
                      m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
                      m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
                      m_time_equityrisk1, profit1);

         BB("B", 0, TradeNow, LotsHedge, InpMagic2, m_orders_count2, m_mediaprice2, m_hedging2,
                      m_target_filter2, m_direction2, m_current_day2, m_previous_day2,
                      m_level2, m_buyer2, m_seller2, m_target2, m_profit2, m_pip2,
                      m_size2, m_take2, m_datetime_ultcandleopen2,
                      m_time_equityrisk2, profit2);
        }
     }
     
      if(EnableProfitClose) 
   {
   
      ProfitCloseTime2(m_symbol,maxTime2);  
      ProfitCloseTime(m_symbol,maxTime);
      ProfitClose(m_symbol);
      

   }
   
   int charts = ChartLimiter(m_symbol);
   
   string symb = m_symbol;
   Comment(
      "                        ", "\n\n",
      "                        ", "\n\n",
      "  TRADE MANAGEMENT:  ", "\n\n",
       "  Close Current Trades: ", "     = $   ", minProfit1, "\n\n",     
      "  Buys:                       " ,NumberOfTrades(symb,OP_BUY ),"\n\n",
      "    Buy Profit:                       $   ",DoubleToStr(CountCurrentProfit(symb,OP_BUY),1),"\n\n",
      "  Sells:                       ",NumberOfTrades(symb,OP_SELL),"\n\n",
      "    Sell Profit:                       $   ",DoubleToStr(CountCurrentProfit(symb,OP_SELL),1), "\n\n",
      "  ---------------------------------------------- ", "\n\n",
      "  Close Old Trades 1: ", "        = $  ", timeProfit,"\n\n",
      "    After Time Buys 1:   " ,NumberOfTradesTime(symb,maxTime,OP_BUY),"\n\n",
      "      Buy Profit 1:                   $   ",DoubleToStr(CountCurrentProfitTime(symb,maxTime,OP_BUY),1),"\n\n",
      "    After Time Sells 1:   ",NumberOfTradesTime(symb,maxTime,OP_SELL),"\n\n",
      "      Sell Profit 1:                   $  ",DoubleToStr(CountCurrentProfitTime(symb,maxTime,OP_SELL),1), "\n\n",
      "  ---------------------------------------------- ", "\n\n",  
      "  Close Old Trades 2: ", "        = $ ", timeProfit2,"\n\n",
      "    After Time Buys 2:   " ,NumberOfTradesTime(symb,maxTime2,OP_BUY),"\n\n",
      "      Buy Profit 1:                   $   ",DoubleToStr(CountCurrentProfitTime(symb,maxTime2,OP_BUY),1),"\n\n",
      "    After Time Sells 2:   ",NumberOfTradesTime(symb,maxTime2,OP_SELL),"\n\n",
      "      Sell Profit 2: $                 $  ",DoubleToStr(CountCurrentProfitTime(symb,maxTime2,OP_SELL),1), "\n\n" 
      );

   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BB(string Id, int Sinal, bool TradeNow, double LotsHedge, int vInpMagic, int &m_orders_count, double &m_mediaprice, bool &m_hedging, bool &m_target_filter,
                  int &m_direction, int &m_current_day, int &m_previous_day,
                  double &m_level, double &m_buyer, double &m_seller, double &m_target, double &m_profit,
                  double &m_pip, double &m_size, double &m_take, datetime &vDatetimeUltCandleOpen,
                  datetime &m_time_equityrisk, double &profit)
  {

//--- Variable Declaration
   int index, orders_total, order_ticket, order_type, ticket, hour;
   double volume_min, volume_max, volume_step, lots;
   double account_balance, margin_required, risk_balance;
   double order_open_price, order_lots;

//--- Variable Initialization
   int buy_ticket = 0, sell_ticket = 0, orders_count = 0, buy_ticket2 = 0, sell_ticket2 = 0;
   int buyer_counter = 0, seller_counter = 0;
   bool was_trade = false, close_filter = false;
   bool long_condition = false, short_condition = false;
   double orders_profit = 0.0, level = 0.0;
   double buyer_lots = 0.0, seller_lots = 0.0;
   double buyer_sum = 0.0, seller_sum = 0.0, sell_lot = 0, buy_lot = 0;
   ;
   double buy_price = 0.0, sell_price = 0.0;
   double bid_price = Bid, ask_price = Ask;
   double close_price = iClose(NULL, 0, 0);
   double open_price = iOpen(NULL, 0, 0);
   datetime time_current = TimeCurrent();
   bool res = false;
   m_spreadX = 2.0 * m_pip;

//--- Base Lot Size
   account_balance = AccountBalance();
   volume_min = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   volume_max = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   volume_step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   lots = volume_min;

   if(InpLotMode == LOT_MODE_FIXED)
    {
     lots = InpFixedLot;
      
    
   }
   else
      if(InpLotMode == LOT_MODE_PERCENT)
        {
         risk_balance = InpPercentLot * AccountBalance() / 100.0;
         margin_required = MarketInfo(m_symbol, MODE_MARGINREQUIRED);
         lots = MathRound(risk_balance / margin_required, volume_step);
         if(lots < volume_min)
            lots = volume_min;
         if(lots > volume_max)
            lots = volume_max;
        }

//--- Daily Calc
   m_current_day = TimeDayOfWeek(time_current);
   if(m_current_day != m_previous_day)
     {
      m_target_filter = false;
      m_target = 0.0;
     }
   m_previous_day = m_current_day;

//--- Calculation Loop
   orders_total = OrdersTotal();
   m_mediaprice = 0;
   double BuyProfit = 0;
   double SellProfit = 0;
   int countFirts = 0;
   double Firts2SellProfit = 0;
   double Firts2BuyProfit = 0;
   int Firtsticket[50];
   double LastSellProfit = 0;
   double LastBuyProfit = 0;
   int Lastticket = 0;

   for(index = orders_total - 1; index >= 0; index--)
     {
      if(!OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderMagicNumber() != vInpMagic || OrderSymbol() != m_symbol)
         continue;
      order_open_price = OrderOpenPrice();
      order_ticket = OrderTicket();
      order_type = OrderType();
      order_lots = OrderLots();

      //---
      if(order_type == OP_BUY)
        {

         //--- Set Last Buy Order
         if(order_ticket > buy_ticket)
           {

            buy_price = order_open_price;
            buy_ticket = order_ticket;
            LastBuyProfit = OrderProfit() + OrderCommission() + OrderSwap();
            Lastticket = order_ticket;
            buy_lot = order_lots;
           }

         buyer_sum += (order_open_price - m_spreadX) * order_lots;

         buyer_lots += order_lots;
         buyer_counter++;
         orders_count++;
         m_mediaprice += order_open_price * order_lots;
         if(OrderProfit() > 0)
            BuyProfit += OrderProfit() + OrderCommission() + OrderSwap();
        }

      //---
      if(order_type == OP_SELL)
        {


         //--- Set Last Sell Order
         if(order_ticket > sell_ticket)
           {

            sell_price = order_open_price;
            sell_ticket = order_ticket;
            LastSellProfit = OrderProfit() + OrderCommission() + OrderSwap();
            Lastticket = order_ticket;
            sell_lot = order_lots;
           }

         seller_sum += (order_open_price + m_spreadX) * order_lots;

         seller_lots += order_lots;
         seller_counter++;
         orders_count++;
         m_mediaprice += order_open_price * order_lots;
         if(OrderProfit() > 0)
            SellProfit += OrderProfit() + OrderCommission() + OrderSwap();
        }

      //---
      orders_profit += OrderProfit();
     }

//Close
   if(ProtectGridLastFist && orders_count > QtdTradesMinProfit)
     {
      int ordticket[100];

      Firts2BuyProfit  = FindFirstOrderTicket(vInpMagic, Symbol(), OP_BUY, QtdTradesMinProfit,  ordticket);


      if(LastBuyProfit > (Firts2BuyProfit * -1) + MinProfit)
        {
         CloseAllTicket(OP_BUY, Lastticket, vInpMagic);

         for(int i = 0; i < QtdTradesMinProfit; i++)
           {
            CloseAllTicket(OP_BUY, ordticket[i], vInpMagic);
           }
        }

      Firts2SellProfit = FindFirstOrderTicket(vInpMagic, Symbol(), OP_SELL, QtdTradesMinProfit,  ordticket);


      if(LastSellProfit > (Firts2SellProfit * -1) + MinProfit)
        {

         CloseAllTicket(OP_SELL, Lastticket, vInpMagic);

         for(int i = 0; i < QtdTradesMinProfit; i++)
           {
            CloseAllTicket(OP_SELL, ordticket[i], vInpMagic);
           }
        }
     }

   m_orders_count = orders_count;
   m_profit = orders_profit;
   
   //BreakEvenStart = InpTakeProfit * (InpBreakEvenStartPer / 100);   //   Break Even Start
   //BreakEvenStep = InpTakeProfit * (InpBreakEvenStopPer / 100);    //  Break Even Step
   
  
   if((seller_counter + buyer_counter) > 0)
      m_mediaprice = NormalizeDouble(m_mediaprice / (buyer_lots + seller_lots), Digits);

   color avgLine = Blue;
   if(seller_lots > 0)
      avgLine = Red;

   if(buyer_lots > 0 || seller_lots > 0)
      SetHLine(avgLine, "Avg" + Id, m_mediaprice, 0, 3);
   else
      ObjectDelete("Avg" + Id);

   if(InpUseTrailingStop)
      TrailingAlls(InpTrailStart, InpTrailStop, m_mediaprice, vInpMagic);

   if(InpUseBreakEven)
      BreakEvenAlls(InpBreakEvenStart, InpBreakEvenStop, m_mediaprice, vInpMagic);

//--- Calc
   if(orders_count == 0)
     {
      m_target += m_profit;
      m_hedging = false;
     }
   profit = m_target + orders_profit;

//--- Close Conditions
   if(InpDailyTarget > 0 && m_target + orders_profit >= InpDailyTarget)
      m_target_filter = true;
//--- This ensure that buy and sell positions close at the same time when hedging is enabled
   if(m_hedging && ((m_direction > 0 && bid_price >= m_level) || (m_direction < 0 && ask_price <= m_level)))
      close_filter = true;

//--- Close All Orders on Conditions
   if(m_target_filter || close_filter)
     {

      CloseThisSymbolAll(vInpMagic);

      // m_spread=0.0;
      return;
     }

//--- Open Trade Conditions
   if(!m_hedging)
     {
      if(orders_count > 0 && !GridAll)
        {
         if(OpenNewOrdersGrid == true && TradeNow)
           {
            if(m_time_equityrisk1 != iTime(NULL, InpTimeframeEquityCaution, 0))
              {
               if(GridAllDirect)
                 {
                  if(buyer_counter > 0 && ask_price - buy_price >= m_size)
                     long_condition = true;
                  if(seller_counter > 0 && sell_price - bid_price >= m_size)
                     short_condition = true;
                 }
               if(buyer_counter > 0 && buy_price - ask_price >= m_size)
                 {
                  long_condition = true;
                 
                 
               if(seller_counter > 0 && bid_price - sell_price >= m_size)
                 
                  short_condition = true;
                  Print("SELL " + m_size);
                 
              }
           }
        }
        }
      else
        {

         if(InpOpenNewOrders && TradeNow)
           {
            hour = TimeHour(time_current);
            if(InpManualInitGrid || (!InpUtilizeTimeFilter || (InpUtilizeTimeFilter && TimeFilter())))
              {

               if(Sinal == 1)
                  short_condition = true;
               if(Sinal == -1)
                  long_condition = true;
              }
           }
        }
     }
   else
     {
      if(m_direction > 0 && bid_price <= m_seller)
         long_condition = true;
      if(m_direction < 0 && ask_price >= m_buyer)
         short_condition = true;
     }
     

// CONTROL DRAWDOWN
   double vProfit = CalculateProfit(vInpMagic);

   if(vProfit < 0.0 && MathAbs(vProfit) > InpTotalEquityRiskCaution / 100.0 * AccountEquity())
     {
      m_time_equityrisk = iTime(NULL, InpTimeframeEquityCaution, 0);
     }
   else
     {
      m_time_equityrisk = -1;
     }

//--- Hedging
   if(InpHedge > 0 && !m_hedging)
     {
      if(long_condition && buyer_counter == InpHedge)
        {
         // m_spread = Spread * m_pip;
         m_seller = bid_price;
         m_hedging = true;

         return;
        }
      if(short_condition && seller_counter == InpHedge)
        {
         // m_spread= Spread * m_pip;
         m_buyer = ask_price;
         m_hedging = true;

         return;
        }
     }

//--- Lot Size
   if(LotsHedge != 0 && orders_count == 0)
     {
      lots = LotsHedge;
     }
   else
     {
      //lots = MathRound(lots * MathPow(InpGridFactor, orders_count), volume_step);

      double qtdLots = (sell_lot + buy_lot);
      if(long_condition)

         lots = MathRound(CalcLot(TypeGridLot, OP_BUY, orders_count, qtdLots, lots, InpGridFactor, InpGridStepLot), volume_step);
      if(short_condition)

         lots = MathRound(CalcLot(TypeGridLot, OP_SELL, orders_count, qtdLots, lots, InpGridFactor, InpGridStepLot), volume_step);

      if(m_hedging)
        {
         if(long_condition)
            lots = MathRound(seller_lots * 3, volume_step) - buyer_lots;
         if(short_condition)
            lots = MathRound(buyer_lots * 3, volume_step) - seller_lots;
        }
     }
   if(lots < volume_min)
      lots = volume_min;
   if(lots > volume_max)
      lots = volume_max;
   if(lots > InpMaxLot)
      lots = InpMaxLot;
   if(lots < InpMinLot)
      lots = InpMinLot;

//--- Open Trades Based on Conditions
   if((InpManualInitGrid && orders_count == 0) || (!InpOpenOneCandle || (InpOpenOneCandle && vDatetimeUltCandleOpen != iTime(NULL, InpTimeframeBarOpen, 0))) && ((RVOL_1min1 < RVOL_MAX && RVOL_ENABLE)|| !RVOL_ENABLE) )
      {
      vDatetimeUltCandleOpen = iTime(NULL, InpTimeframeBarOpen, 0);

      if(long_condition && !IsMaxTrade(OP_BUY))
         {
         if(buyer_lots + lots == seller_lots)
            lots = seller_lots + volume_min;
         //---
         double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT),
                sl = (HardSL > 0) ? ask_price - (HardSL * point) : 0;
         //---
         ticket = OpenTrade(OP_BUY, lots, ask_price, vInpMagic, Id, sl);
         if(ticket > 0)
            {
            if(HardSL > 0)
               UpdateSL(OP_BUY, vInpMagic, sl);
            res = OrderSelect(ticket, SELECT_BY_TICKET);
            order_open_price = OrderOpenPrice();
            buyer_sum += order_open_price * lots;
            buyer_lots += lots;
            m_level = NormalizeDouble((buyer_sum - seller_sum) / (buyer_lots - seller_lots), Digits) + m_take;
            if(!m_hedging)
               level = m_level;
            else
               level = m_level + m_take;
            if(buyer_counter == 0)
               m_buyer = order_open_price;
            m_direction = 1;
            was_trade = true;

            if(CountTradesBuy() >= InpGridStepActivationLayer)
               {
               m_size1 += InpGridStepMultiplier * InpGridSize * m_pip1;
               m_size2 += InpGridStepMultiplier * InpGridSize * m_pip2;
               }
            }
         }

      if(short_condition && !IsMaxTrade(OP_SELL))
         {
         if(seller_lots + lots == buyer_lots)
            lots = buyer_lots + volume_min;
         //---
         double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT),
                sl = (HardSL > 0) ? bid_price + (HardSL * point) : 0;
         //---
         ticket = OpenTrade(OP_SELL, lots, bid_price, vInpMagic, Id, sl);
         if(ticket > 0)
            {
            if(HardSL > 0)
               UpdateSL(OP_SELL, vInpMagic, sl);
            res = OrderSelect(ticket, SELECT_BY_TICKET);
            order_open_price = OrderOpenPrice();
            seller_sum += order_open_price * lots;
            seller_lots += lots;
            m_level = NormalizeDouble((seller_sum - buyer_sum) / (seller_lots - buyer_lots), Digits) - m_take;
            if(!m_hedging)
               level = m_level;
            else
               level = m_level - m_take;
            if(seller_counter == 0)
               m_seller = order_open_price;
            m_direction = -1;
            was_trade = true;

            if(CountTradesSell() >= InpGridStepActivationLayer)
               {
               m_size1 += InpGridStepMultiplier * InpGridSize * m_pip1;
               m_size2 += InpGridStepMultiplier * InpGridSize * m_pip2;
               }
            }
         }
      }
   if(InpEnableMinProfit && !ProtectGridLastFist)
      {
      if(BuyProfit >= MinProfit && buyer_counter >= QtdTradesMinProfit)
         CloseAllTicket(OP_BUY, buy_ticket, vInpMagic);

      if(SellProfit >= MinProfit && seller_counter >= QtdTradesMinProfit)
         CloseAllTicket(OP_SELL, sell_ticket, vInpMagic);
      }

//--- Setup Global Take Profit
   if(was_trade)
      {
      orders_total = OrdersTotal();
      for(index = orders_total - 1; index >= 0; index--)
         {
         if(!OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
            continue;
         if(OrderMagicNumber() != vInpMagic || OrderSymbol() != m_symbol)
            continue;
         order_type = OrderType();
         if(m_direction > 0)
            {
            if(order_type == OP_BUY)
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), level, 0);
            if(order_type == OP_SELL)
               res = OrderModify(OrderTicket(), OrderOpenPrice(), level, 0.0, 0);
            }
         if(m_direction < 0)
            {
            if(order_type == OP_BUY)
               res = OrderModify(OrderTicket(), OrderOpenPrice(), level, 0.0, 0);
            if(order_type == OP_SELL)
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), level, 0);
            }
         }
      }
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateSL(int type, int magic, double sl)
  {
   const int retries_max = 10;
   int ord_total = OrdersTotal();
   for(int i = ord_total - 1; i >= 0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == magic)
        {
         if(OrderType() == type && OrderSymbol() == m_symbol)
           {
            if(fabs(OrderStopLoss() - sl) > SymbolInfoDouble(m_symbol, SYMBOL_POINT))
              {
               int retry = 0;
               bool mod = false;
               while(retry < retries_max && !mod)
                 {
                  mod = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), 0);
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsMaxTrade(int signal)
  {
   if(signal == OP_BUY)
     {
      if(MaxBuy <= 0)
         return false;
      //---
      int buy = CountTradesBuy(InpMagic) + CountTradesBuy(InpMagic2);
      if(buy >= MaxBuy)
         return true;
     }
   else //OP_SELL
     {
      if(MaxSell <= 0)
         return false;
      //---
      int sell = CountTradesSell(InpMagic) + CountTradesSell(InpMagic2);
      if(sell >= MaxSell)
         return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
int OpenTrade(int cmd, double volume, double price, int vInpMagic, string coment, double stop = 0.0, double take = 0.0)
  {
   return OrderSend(m_symbol, cmd, volume, price, SlipPage, stop, take, " ", vInpMagic, 0);
  }
//+--------------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathRound(double x, double m)
  {
   return m * MathRound(x / m);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathFloor(double x, double m)
  {
   return m * MathFloor(x / m);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathCeil(double x, double m)
  {
   return m * MathCeil(x / m);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTrades()
  {
   int l_count_0 = 0;
   for(int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
     {
      if(!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || (OrderMagicNumber() != InpMagic && OrderMagicNumber() != InpMagic2))
         continue;
      if(OrderSymbol() == Symbol() && (OrderMagicNumber() == InpMagic || OrderMagicNumber() == InpMagic2))
         if(OrderType() == OP_SELL || OrderType() == OP_BUY)
            l_count_0++;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTrades(int vInpMagic)
  {
   int l_count_0 = 0;
   for(int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
     {
      if(!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
         continue;
      if(OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
         if(OrderType() == OP_SELL || OrderType() == OP_BUY)
            l_count_0++;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTradesSell()
  {
   int l_count_0 = 0;
   for(int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; --l_pos_4)
     {
      if(!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || (OrderMagicNumber() != InpMagic && OrderMagicNumber() != InpMagic2))
         continue;
      if(OrderSymbol() == Symbol() && (OrderMagicNumber() == InpMagic || OrderMagicNumber() == InpMagic2))
         if(OrderType() == OP_SELL)
            ++l_count_0;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTradesSell(int vInpMagic)
  {
   int l_count_0 = 0;
   for(int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
     {
      if(!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
         continue;
      if(OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
         if(OrderType() == OP_SELL)
            l_count_0++;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTradesBuy()
  {
   int l_count_0 = 0;
   for(int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; --l_pos_4)
     {
      if(!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || (OrderMagicNumber() != InpMagic && OrderMagicNumber() != InpMagic2))
         continue;
      if(OrderSymbol() == Symbol() && (OrderMagicNumber() == InpMagic || OrderMagicNumber() == InpMagic2))
         if(OrderType() == OP_BUY)
            ++l_count_0;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTradesBuy(int vInpMagic)
  {
   int l_count_0 = 0;
   for(int l_pos_4 = OrdersTotal() - 1; l_pos_4 >= 0; l_pos_4--)
     {
      if(!OrderSelect(l_pos_4, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
         continue;
      if(OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
         if(OrderType() == OP_BUY)
            l_count_0++;
     }
   return (l_count_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateProfit()
  {
   double ld_ret_0 = 0;
   for(int g_pos_344 = OrdersTotal() - 1; g_pos_344 >= 0; g_pos_344--)
     {
      if(!OrderSelect(g_pos_344, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || (OrderMagicNumber() != InpMagic && OrderMagicNumber() != InpMagic2))
         continue;
      if(OrderSymbol() == Symbol() && (OrderMagicNumber() == InpMagic || OrderMagicNumber() == InpMagic2))
         if(OrderType() == OP_BUY || OrderType() == OP_SELL)
            ld_ret_0 += OrderProfit();
     }
   return (ld_ret_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateProfit(int vInpMagic)
  {
   double ld_ret_0 = 0;
   for(int g_pos_344 = OrdersTotal() - 1; g_pos_344 >= 0; g_pos_344--)
     {
      if(!OrderSelect(g_pos_344, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || (OrderMagicNumber() != vInpMagic))
         continue;
      if(OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
         if(OrderType() == OP_BUY || OrderType() == OP_SELL)
            ld_ret_0 += OrderProfit();
     }
   return (ld_ret_0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TimeFilter()
  {

   bool _res = false;
   datetime _time_curent = TimeCurrent();
   datetime _time_start = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpStartHour);
   datetime _time_start1 = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpStartHour1);
   datetime _time_stop = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpEndHour);
   datetime _time_stop1 = StrToTime(DoubleToStr(Year(), 0) + "." + DoubleToStr(Month(), 0) + "." + DoubleToStr(Day(), 0) + " " + InpEndHour1);
   if(((InpTrade_in_Monday == true) && (TimeDayOfWeek(Time[0]) == 1)) ||
         ((InpTrade_in_Tuesday == true) && (TimeDayOfWeek(Time[0]) == 2)) ||
         ((InpTrade_in_Wednesday == true) && (TimeDayOfWeek(Time[0]) == 3)) ||
         ((InpTrade_in_Thursday == true) && (TimeDayOfWeek(Time[0]) == 4)) ||
         ((InpTrade_in_Friday == true) && (TimeDayOfWeek(Time[0]) == 5)))

      if(_time_start > _time_stop)
        {
         if(_time_curent >= _time_start || _time_curent <= _time_stop)
            _res = true;
        }
      else 
         if(_time_curent >= _time_start && _time_curent <= _time_stop)
         _res = true;
      else
         if(_time_start1 > _time_stop1)
        {
         if(_time_curent >= _time_start1 || _time_curent <= _time_stop1)
            _res = true;
        }
      else 
         if(_time_curent >= _time_start1 && _time_curent <= _time_stop1)
         _res = true;

   return (_res);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isCloseLastOrderNotProfit(int MagicNumber)
  {
   datetime t = 0;
   double ocp, osl, otp;
   int i, j = -1, k = OrdersHistoryTotal();
   for(i = 0; i < k; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
         if(OrderType() == OP_BUY || OrderType() == OP_SELL)
           {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
              {
               if(t < OrderCloseTime())
                 {
                  t = OrderCloseTime();
                  j = i;
                 }
              }
           }
        }
     }
   if(OrderSelect(j, SELECT_BY_POS, MODE_HISTORY))
     {
      ocp = NormalizeDouble(OrderClosePrice(), Digits);
      osl = NormalizeDouble(OrderStopLoss(), Digits);
      otp = NormalizeDouble(OrderTakeProfit(), Digits);
      if(OrderProfit() < 0)
         return (true);
     }
   return (false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FindLastSellLot(int MagicNumber)
  {
   double l_lastLote = 0;
   int l_ticket_8;
//double ld_unused_12 = 0;
   int l_ticket_20 = 0;
   for(int l_pos_24 = OrdersTotal() - 1; l_pos_24 >= 0; l_pos_24--)
     {
      if(!OrderSelect(l_pos_24, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_SELL)
        {
         l_ticket_8 = OrderTicket();
         if(l_ticket_8 > l_ticket_20)
           {
            l_lastLote += OrderLots();
            //ld_unused_12 = l_ord_open_price_0;
            l_ticket_20 = l_ticket_8;
           }
        }
     }
   return (l_lastLote);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FindLastBuyLot(int MagicNumber)
  {
   double l_lastorder = 0;
   int l_ticket_8;
//double ld_unused_12 = 0;
   int l_ticket_20 = 0;
   for(int l_pos_24 = OrdersTotal() - 1; l_pos_24 >= 0; l_pos_24--)
     {
      if(!OrderSelect(l_pos_24, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
         continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == OP_BUY)
        {
         l_ticket_8 = OrderTicket();
         if(l_ticket_8 > l_ticket_20)
           {
            l_lastorder += OrderLots();
            //ld_unused_12 = l_ord_open_price_0;
            l_ticket_20 = l_ticket_8;
           }
        }
     }
   return (l_lastorder);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowError(int error, string complement)
  {

   if(error == 1 || error == 130)
     {
      return;
     }

//string ErrorText=ErrorDescription(error);
// StringToUpper(ErrorText);
   Print(complement, ": Ordem: ", OrderTicket(), ". Falha ao tentar alterar ordem: ", error, " ");
   ResetLastError();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingAlls(int ai_0, int ai_4, double a_price_8, int MagicNumber)
  {
   int li_16;

   double m_pip = 1.0 / MathPow(10, Digits - 1);
   if(Digits == 3 || Digits == 5)
      m_pip = 1.0 / MathPow(10, Digits - 1);
   else
      m_pip = Point;

   double l_ord_stoploss_20;
   double l_price_28;
   bool foo = false;
   if(ai_4 != 0)
     {
      for(int l_pos_36 = OrdersTotal() - 1; l_pos_36 >= 0; l_pos_36--)
        {
         if(OrderSelect(l_pos_36, SELECT_BY_POS, MODE_TRADES))
           {
            if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
               continue;
            if(OrderSymbol() == Symbol() || OrderMagicNumber() == MagicNumber)
              {
               if(OrderType() == OP_BUY)
                 {
                  li_16 = (int)NormalizeDouble((Bid - a_price_8) / Point, 0);
                  if(li_16 < (ai_0 * m_pip))
                     continue;
                  l_ord_stoploss_20 = OrderStopLoss();
                  l_price_28 = Bid - (ai_4 * m_pip);
                  l_price_28 = ValidStopLoss(OP_BUY, Bid, l_price_28);
                  if(l_ord_stoploss_20 == 0.0 || (l_ord_stoploss_20 != 0.0 && l_price_28 > l_ord_stoploss_20))
                    {
                     // Somente ajustar a ordem se ela estiver aberta
                     if(CanModify(OrderTicket()) && a_price_8 < l_price_28)
                       {
                        ResetLastError();
                        foo = OrderModify(OrderTicket(), a_price_8, l_price_28, OrderTakeProfit(), 0, Aqua);
                        if(!foo)
                          {
                           ShowError(GetLastError(), "Normal");
                          }
                       }
                    }
                 }
               if(OrderType() == OP_SELL)
                 {
                  li_16 = (int)NormalizeDouble((a_price_8 - Ask) / Point, 0);
                  if(li_16 < (ai_0 * m_pip))
                     continue;
                  l_ord_stoploss_20 = OrderStopLoss();
                  l_price_28 = Ask + (ai_4 * m_pip);
                  l_price_28 = ValidStopLoss(OP_SELL, Ask, l_price_28);
                  if(l_ord_stoploss_20 == 0.0 || (l_ord_stoploss_20 != 0.0 && l_price_28 < l_ord_stoploss_20))
                    {
                     // Somente ajustar a ordem se ela estiver aberta
                     if(CanModify(OrderTicket()) && a_price_8 > l_price_28)
                       {
                        ResetLastError();
                        foo = OrderModify(OrderTicket(), a_price_8, l_price_28, OrderTakeProfit(), 0, Red);
                        if(!foo)
                          {
                           ShowError(GetLastError(), "Normal");
                          }
                       }
                    }
                 }
              }
            Sleep(1000);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseThisSymbolAll(int vInpMagic)
  {
   bool foo = false;
   for(int l_pos_0 = OrdersTotal() - 1; l_pos_0 >= 0; l_pos_0--)
     {
      if(!OrderSelect(l_pos_0, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() == Symbol())
        {
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() == vInpMagic))
           {
            if(OrderType() == OP_BUY)
               foo = OrderClose(OrderTicket(), OrderLots(), Bid, SlipPage, Blue);

            if(OrderType() == OP_SELL)
               foo = OrderClose(OrderTicket(), OrderLots(), Ask, SlipPage, Red);
           }
         Sleep(1000);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseThisSymbolAll()
  {
   bool foo = false;
   for(int l_pos_0 = OrdersTotal() - 1; l_pos_0 >= 0; l_pos_0--)
     {
      if(!OrderSelect(l_pos_0, SELECT_BY_POS, MODE_TRADES))
        {
         continue;
        }
      if(OrderSymbol() == Symbol())
        {
         if(OrderSymbol() == Symbol() && (OrderMagicNumber() == InpMagic || OrderMagicNumber() == InpMagic2))
           {
            if(OrderType() == OP_BUY)
               foo = OrderClose(OrderTicket(), OrderLots(), Bid, SlipPage, Blue);

            if(OrderType() == OP_SELL)
               foo = OrderClose(OrderTicket(), OrderLots(), Ask, SlipPage, Red);
           }
         Sleep(1000);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CanModify(int ticket)
  {

   return OrdersTotal() > 0;
   /*
     if( OrderType() == OP_BUY || OrderType() == OP_SELL)
        return OrderCloseTime() == 0;

     return false;

     /*
     bool result = false;

     OrderSelect(ticket, SELECT_BY_TICKET
     for(int i=OrdersHistoryTotal()-1;i>=0;i--){
        if( !OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ){ continue; }
        if(OrderTicket()==ticket){
           result=true;
           break;
        }
     }

     return result;
     */
  }
// Function to check if it is news time
/*void NewsHandling()
  {
   static int PrevMinute = -1;

   if(Minute() != PrevMinute)
     {
      PrevMinute = Minute();

      // Use this call to get ONLY impact of previous event
      int impactOfPrevEvent =
         (int)iCustom(NULL, 0, "FFCal", true, true, false, true, true, 2, 0);

      // Use this call to get ONLY impact of nexy event
      int impactOfNextEvent =
         (int)iCustom(NULL, 0, "FFCal", true, true, false, true, true, 2, 1);

      int minutesSincePrevEvent =
         (int)iCustom(NULL, 0, "FFCal", true, true, false, true, false, 1, 0);

      int minutesUntilNextEvent =
         (int)iCustom(NULL, 0, "FFCal", true, true, false, true, false, 1, 1);

      m_news_time = false;
      if((minutesUntilNextEvent <= InpMinsBeforeNews) ||
         (minutesSincePrevEvent <= InpMinsAfterNews))
        {
         m_news_time = true;
        }
     }
  } //newshandling*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllTicket(int aType, int ticket, int MagicN)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
      if(OrderSelect(i, SELECT_BY_POS))
         if(OrderSymbol() == Symbol())
            if(OrderMagicNumber() == MagicN)
              {
               if(OrderType() == aType && OrderType() == OP_BUY)
                  if(OrderProfit() > 0 || OrderTicket() == ticket)
                     if(!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Bid, Digits()), SlipPage, clrRed))
                        Print(" OrderClose OP_BUY Error N", GetLastError());

               if(OrderType() == aType && OrderType() == OP_SELL)
                  if(OrderProfit() > 0 || OrderTicket() == ticket)
                     if(!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Ask, Digits()), SlipPage, clrRed))
                        Print(" OrderClose OP_SELL Error N", GetLastError());
              }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawRects(int xPos, int yPos, color clr, int width = 150, int height = 17, string Texto = "")
  {

   string id = "_l" + Texto;

   ObjectDelete(0, id);

   ObjectCreate(0, id, OBJ_BUTTON, 0, 100, 100);
   ObjectSetInteger(0, id, OBJPROP_XDISTANCE, xPos);
   ObjectSetInteger(0, id, OBJPROP_YDISTANCE, yPos);
   ObjectSetInteger(0, id, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, id, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, id, OBJPROP_XSIZE, 150);
   ObjectSetInteger(0, id, OBJPROP_YSIZE, 35);

   ObjectSetInteger(0, id, OBJPROP_WIDTH, 0);
   ObjectSetString(0, id, OBJPROP_FONT, "Arial");
   ObjectSetString(0, id, OBJPROP_TEXT, Texto);
   ObjectSetInteger(0, id, OBJPROP_SELECTABLE, 0);

   ObjectSetInteger(0, id, OBJPROP_BACK, 0);
   ObjectSetInteger(0, id, OBJPROP_SELECTED, 0);
   ObjectSetInteger(0, id, OBJPROP_HIDDEN, 1);
   ObjectSetInteger(0, id, OBJPROP_ZORDER, 1);

   ObjectSetInteger(0, id, OBJPROP_STATE, false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetHLine(color vColorSetHLine, string vNomeSetHLine = "", double vBidSetHLine = 0.0, int vStyleSetHLine = 0, int vTamanhoSetHLine = 1)
  {
   if(vNomeSetHLine == "")
      vNomeSetHLine = DoubleToStr(Time[0], 0);
   if(vBidSetHLine <= 0.0)
      vBidSetHLine = Bid;
   if(ObjectFind(vNomeSetHLine) < 0)
      ObjectCreate(vNomeSetHLine, OBJ_HLINE, 0, 0, 0);
   ObjectSet(vNomeSetHLine, OBJPROP_PRICE1, vBidSetHLine);
   ObjectSet(vNomeSetHLine, OBJPROP_COLOR, vColorSetHLine);
   ObjectSet(vNomeSetHLine, OBJPROP_STYLE, vStyleSetHLine);
   ObjectSet(vNomeSetHLine, OBJPROP_WIDTH, vTamanhoSetHLine);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ValidStopLoss(int type, double price, double SL)
  {

   double mySL;
   double minstop;

   minstop = MarketInfo(Symbol(), MODE_STOPLEVEL);
   if(Digits == 3 || Digits == 5)
      minstop = minstop / 10;

   mySL = SL;
   if(type == OP_BUY)
     {
      if((price - mySL) < minstop * Point)
         // mySL = price - minstop * Point;
         mySL = 0;
     }
   if(type == OP_SELL)
     {
      if((mySL - price) < minstop * Point)
         //mySL = price + minstop * Point;
         mySL = 0;
     }

   return (NormalizeDouble(mySL, (int)MarketInfo(Symbol(), MODE_DIGITS)));
  }
/*
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{

  //sparam: Name of the graphical object, on which the event occurred

  // did user click on the chart ?
  if (id == CHARTEVENT_OBJECT_CLICK)
  {
    // and did he click on on of our objects
    if (StringSubstr(sparam, 0, 2) == "_l")
    {

      // did user click on the name of a pair ?
      int len = StringLen(sparam);
      // Alert(sparam);
      //
      if (StringSubstr(sparam, len - 3, 3) == "BUY" || StringSubstr(sparam, len - 3, 3) == "ELL")
      {
        if (InpManualInitGrid)
        {

          //Aciona 1ª Ordem do Grid
          if (StringSubstr(sparam, len - 3, 3) == "sBUY" && !(m_orders_count1 > 0 || !InpEnableEngineA))
          {
            //BUY
            BB("A", 1, 0, InpMagic, m_orders_count1, m_mediaprice1, m_hedging1, m_target_filter1,
                  m_direction1, m_current_day1, m_previous_day1, m_level1, m_buyer1, m_seller1,
                  m_target1, m_profit1, m_pip1, m_size1, m_take1, m_datetime_ultcandleopen1,
                  m_time_equityrisk1);
            //  Alert("BUY");
          }
          if (StringSubstr(sparam, len - 3, 3) == "sELL" && !(m_orders_count2 > 0 || !InpEnableEngineA))
          {
            //SELL
            BB("B", -1, 0, InpMagic2, m_orders_count2, m_mediaprice2, m_hedging2,
                  m_target_filter2, m_direction2, m_current_day2, m_previous_day2,
                  m_level2, m_buyer2, m_seller2, m_target2, m_profit2, m_pip2,
                  m_size2, m_take2, m_datetime_ultcandleopen2,
                  m_time_equityrisk2);
            //  Alert("SELL");
          }
        }
      }
    }
  }
} */
//-----------------------------------------------
int DivSinalHILO()
  {
   if(!EnableSinalHILO)
      return (0);
   else
      return (1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetSinalHILO()
  {
   int vRet = 0;

   if(!EnableSinalHILO)
      vRet = 0;

   indicator_low = iMA(NULL, InpHILOFrame, InpHILOPeriod, 0, InpHILOMethod, PRICE_LOW, InpHILOShift);
   indicator_high = iMA(NULL, InpHILOFrame, InpHILOPeriod, 0, InpHILOMethod, PRICE_HIGH, InpHILOShift);

   diff_highlow = indicator_high - indicator_low;
   isbidgreaterthanima = Bid >= indicator_low + diff_highlow / 2.0;

   if(Bid < indicator_low)
      vRet = -1;
   else if(Bid > indicator_high)
      vRet = 1;

   if(InpHILOFilterInverter)
      vRet = vRet * -1;

   return vRet;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ToStr(double ad_0, int ai_8)
  {
   return (DoubleToStr(ad_0, ai_8));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BreakEvenAlls(int ai_0, int ai_4, double MediaPrice, int MagicNumber)
  {
   int PipsDiffMedia;

   double m_pip = 1.0 / MathPow(10, Digits - 1);
   if(Digits == 3 || Digits == 5)
      m_pip = 1.0 / MathPow(10, Digits - 1);
   else
      m_pip = Point;

   double l_ord_stoploss_20;
   double l_price_28;
   bool foo = false;
   if(ai_0 != 0)
     {
      for(int l_pos_36 = OrdersTotal() - 1; l_pos_36 >= 0; l_pos_36--)
        {
         if(OrderSelect(l_pos_36, SELECT_BY_POS, MODE_TRADES))
           {
            if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
               continue;
            if(OrderSymbol() == Symbol() || OrderMagicNumber() == MagicNumber)
              {
               if(OrderType() == OP_BUY)
                 {
                  PipsDiffMedia = (int)NormalizeDouble((Bid - MediaPrice) / Point, 0);
                  // Comment(PipsDiffMedia);
                  if(PipsDiffMedia <= (ai_0 * m_pip))
                     continue;
                  l_ord_stoploss_20 = OrderStopLoss();
                  l_price_28 = MediaPrice + (ai_4 * m_pip);
                  l_price_28 = ValidStopLoss(OP_BUY, Bid, l_price_28);
                  if(Bid >= (MediaPrice + (ai_4 * m_pip)) && (l_ord_stoploss_20 == 0.0 || (l_ord_stoploss_20 != 0.0 && l_price_28 > l_ord_stoploss_20)))
                    {
                     // Somente ajustar a ordem se ela estiver aberta
                     if(CanModify(OrderTicket()))
                       {
                        ResetLastError();
                        foo = OrderModify(OrderTicket(), MediaPrice, l_price_28, OrderTakeProfit(), 0, Aqua);
                        if(!foo)
                          {
                           ShowError(GetLastError(), "Normal");
                          }
                       }
                    }
                 }
               if(OrderType() == OP_SELL)
                 {
                  PipsDiffMedia = (int)NormalizeDouble((MediaPrice - Ask) / Point, 0);
                  if(PipsDiffMedia <= (ai_0 * m_pip))
                     continue;
                  l_ord_stoploss_20 = OrderStopLoss();
                  l_price_28 = MediaPrice - (ai_4 * m_pip);
                  l_price_28 = ValidStopLoss(OP_SELL, Ask, l_price_28);
                  if(Ask <= (MediaPrice - (ai_4 * m_pip)) && (l_ord_stoploss_20 == 0.0 || (l_ord_stoploss_20 != 0.0 && l_price_28 < l_ord_stoploss_20)))
                    {
                     // Somente ajustar a ordem se ela estiver aberta
                     if(CanModify(OrderTicket()))
                       {
                        ResetLastError();
                        foo = OrderModify(OrderTicket(), MediaPrice, l_price_28, OrderTakeProfit(), 0, Red);
                        if(!foo)
                          {
                           ShowError(GetLastError(), "Normal");
                          }
                       }
                    }
                 }
              }
            Sleep(1000);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Visor1Handling()
  {
   if(Visor1_Show_the_Price == true)
     {
      string Market_Price = DoubleToStr(Bid, Digits);

      //ObjectCreate("Market_Price_Label", OBJ_LABEL, 0, 0, 0);

      if(Bid > Visor1_Old_Price)
         ObjectSetText("Market_Price_Label", Market_Price, Visor1_Price_Size, "Comic Sans MS", Visor1_Price_Up_Color);
      if(Bid < Visor1_Old_Price)
         ObjectSetText("Market_Price_Label", Market_Price, Visor1_Price_Size, "Comic Sans MS", Visor1_Price_Down_Color);
      Visor1_Old_Price = Bid;

      ObjectSet("Market_Price_Label", OBJPROP_XDISTANCE, Visor1_Price_X_Position);
      ObjectSet("Market_Price_Label", OBJPROP_YDISTANCE, Visor1_Price_Y_Position);
      ObjectSet("Market_Price_Label", OBJPROP_CORNER, 1);
     }

   if(Bid > iClose(Symbol(), 1440, 1))
     {
      Visor1_FontColor = LawnGreen;
      Visor1_Sinal = 1;
     }

   if(Bid < iClose(Symbol(), 1440, 1))
     {
      Visor1_FontColor = Tomato;
      Visor1_Sinal = -1;
     }

   double pp1 = iClose(Symbol(), 1440, 0), pp2 = iClose(Symbol(), 1440, 1);
   if(pp1 <= 0) pp1 = 1;
   if(pp2 <= 0) pp2 = 1; //Avoid zero divide
//string Porcent_Price = DoubleToStr(((iClose(Symbol(), 1440, 0) / iClose(Symbol(), 1440, 1)) - 1) * 100, 3) + " %";
   string Porcent_Price = DoubleToStr(((pp1 / pp2) - 1) * 100, 3) + " %";
//----
   //ObjectCreate("Porcent_Price_Label", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("Porcent_Price_Label", Porcent_Price, Visor1_Porcent_Size, "Arial", Visor1_FontColor);
   ObjectSet("Porcent_Price_Label", OBJPROP_CORNER, 1);
   ObjectSet("Porcent_Price_Label", OBJPROP_XDISTANCE, Visor1_Porcent_X_Position);
   ObjectSet("Porcent_Price_Label", OBJPROP_YDISTANCE, Visor1_Porcent_Y_Position);

   string Symbol_Price = Symbol();

   ObjectCreate("Simbol_Price_Label", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("Simbol_Price_Label", InpADXtext, Visor1_Symbol_Size, "Arial", DeepSkyBlue);
   ObjectSet("Simbol_Price_Label", OBJPROP_CORNER, 1);
   ObjectSet("Simbol_Price_Label", OBJPROP_XDISTANCE, Visor1_Symbol_X_Position);
   ObjectSet("Simbol_Price_Label", OBJPROP_YDISTANCE, Visor1_Symbol_Y_Position);

   string Spreead = "Spread : " + (string)(MarketInfo(Symbol(), MODE_SPREAD)) + " pips";
   ObjectCreate("Spread_Price_Label", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("Spread_Price_Label", Spreead, Visor1_Spread_Size, "Arial", White);
   ObjectSet("Spread_Price_Label", OBJPROP_CORNER, 1);
   ObjectSet("Spread_Price_Label", OBJPROP_XDISTANCE, Visor1_Spread_X_Position);
   ObjectSet("Spread_Price_Label", OBJPROP_YDISTANCE, Visor1_Spread_Y_Position);
//----------------------------------

   if(Visor1_Show_the_Time == true)
     {
      int MyHour = TimeHour(TimeCurrent());
      int MyMinute = TimeMinute(TimeCurrent());
      int MyDay = TimeDay(TimeCurrent());
      int MyMonth = TimeMonth(TimeCurrent());
      int MyYear = TimeYear(TimeCurrent());
      string MySemana = (string)TimeDayOfWeek(TimeCurrent());
      string NewMinute = "";

      if(MyMinute < 10)
        {
         NewMinute = ("0" + (string)MyMinute);
        }
      else
        {
         NewMinute = DoubleToStr(TimeMinute(TimeCurrent()), 0);
        }

      string NewHour = DoubleToStr(MyHour + Visor1_Chart_Timezone, 0);

      ObjectCreate("Time_Label", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("Time_Label", (string)MyDay + "-" + (string)MyMonth + "-" + (string)MyYear + " " + NewHour + ":" + NewMinute, Visor1_Time_Size, "Comic Sans MS", Visor1_Time_Color);

      ObjectSet("Time_Label", OBJPROP_XDISTANCE, Visor1_Time_X_Position);
      ObjectSet("Time_Label", OBJPROP_YDISTANCE, Visor1_Time_Y_Position);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcLot(int TypeLot, int TypeOrder, int vQtdTrades, double LastLot, double StartLot, double GridFactor, int GridStepLot)
  {
   double rezult = 0;
   switch(TypeLot)
     {
      case 0: // Standart lot
         if(TypeOrder == OP_BUY || TypeOrder == OP_SELL)
            rezult = StartLot;
         break;

      case 1: // Summ lot
         rezult = StartLot * vQtdTrades;

         break;

      case 2: // Martingale lot
         // rezult = StartLot * MathPow(GridFactor, vQtdTrades);
         rezult = MathRound(StartLot * MathPow(InpGridFactor, vQtdTrades), SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP));
         break;

      case 3: // Step lot
         if(vQtdTrades == 0)
            rezult = StartLot;
         if(vQtdTrades % GridStepLot == 0)
            rezult = LastLot + StartLot;
         else
            rezult = LastLot;

         break;
     }
   return rezult;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FindFirstOrderTicket(int magic, string Symb, int Type, int QtdProfit, int &tickets[])
  {
   int Ticket = 0;
   double profit = 0;
   datetime EarliestOrder = D'2099/12/31';
   int c = 0;
   double ordprofit[100];
   ArrayInitialize(ordprofit, 0);
   for(int i = 0; i < OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderType() == Type && OrderSymbol() == Symb && OrderMagicNumber() == magic)
           {
            if(EarliestOrder > OrderOpenTime())
              {
               EarliestOrder = OrderOpenTime();
               Ticket = OrderTicket();
               profit = OrderProfit() + OrderCommission() + OrderSwap();
               if(profit < 0)
                 {
                  tickets[c] = Ticket;
                  ordprofit[c] = profit;
                  c++;
                 }
              }
           }
        }
     }

   for(int i = 0; i < QtdProfit; i++)
     {
      profit += ordprofit[i];
     }

   return profit; // Returns 0 if no matching orders
  }
  
  //+------------------------------------------------------------------+
void ProfitClose(string symb)
{
   if(NumberOfTrades(symb,OP_BUY )>=minTrades && CountCurrentProfit(symb,OP_BUY )>=minProfit1) CloseAllOrders(symb,OP_BUY);
   if(NumberOfTrades(symb,OP_SELL)>=minTrades && CountCurrentProfit(symb,OP_SELL)>=minProfit1) CloseAllOrders(symb,OP_SELL);
}

//+------------------------------------------------------------------+
void ProfitCloseTime(string symb, int minutes)
{
   if(NumberOfTradesTime(symb,minutes,OP_BUY )>=1 && CountCurrentProfitTime(symb,minutes,OP_BUY )>=timeProfit) CloseAllOrdersTime(symb,minutes,OP_BUY);
   if(NumberOfTradesTime(symb,minutes,OP_SELL)>=1 && CountCurrentProfitTime(symb,minutes,OP_SELL)>=timeProfit) CloseAllOrdersTime(symb,minutes,OP_SELL);
}

void ProfitCloseTime2(string symb, int minutes)
{
   if(NumberOfTradesTime(symb,minutes,OP_BUY )>=1 && CountCurrentProfitTime(symb,minutes,OP_BUY )>=timeProfit2) CloseAllOrdersTime(symb,minutes,OP_BUY);
   if(NumberOfTradesTime(symb,minutes,OP_SELL)>=1 && CountCurrentProfitTime(symb,minutes,OP_SELL)>=timeProfit2) CloseAllOrdersTime(symb,minutes,OP_SELL);
}

//--------------------+
int ChartLimiter(string symb)
{
   long currChart,prevChart=ChartFirst();
   int i=0,limit=100;
   int count = 0;
   
   while(i<limit)// We have certainly not more than 100 open charts
   {
      if(ChartSymbol(currChart)==symb) count++;
      if(count>maxCharts) ChartClose(currChart);
      
      currChart=ChartNext(prevChart); // Get the new chart ID by using the previous chart ID
      if(currChart<0) break;          // Have reached the end of the chart list
      
      prevChart=currChart;// let's save the current chart ID for the ChartNext()
      i++;// Do not forget to increase the counter
   }
   
   return count;
}

// Account Manager Code Start
//+------------------------------------------------------------------+
bool KillTicket(int Ticket,string reason="")
{
   if(OrderSelect(Ticket,SELECT_BY_TICKET) && OrderType()<=OP_SELL && OrderCloseTime()==0)
   {
      bool Closing=false;
      double Price=0;

      color arrow_color=0;if(OrderType()==OP_BUY)arrow_color=Blue;if(OrderType()==OP_SELL)arrow_color=Green;
      if(HandleTradingEnvironment())
      {
         if(OrderType()==OP_BUY)
            Price=MarketInfo(OrderSymbol(),MODE_BID);
         if(OrderType()==OP_SELL)
            Price=MarketInfo(OrderSymbol(),MODE_ASK);

         Closing=OrderClose(Ticket,OrderLots(),Price,slippage,arrow_color);
      }
      if(!Closing)Print("ERROR: "+IntegerToString(GetLastError()));
      if(Closing)Print("Position successfully closed. "+reason);
      return(Closing);
   }
   if(OrderSelect(Ticket,SELECT_BY_TICKET) && OrderType()>OP_SELL && OrderCloseTime()==0)
   {
      bool Delete=false;
      Print("Kill Ticket: Trying to delete pending order "+IntegerToString(Ticket)+" ... "+reason);
      if(HandleTradingEnvironment())
         Delete=OrderDelete(Ticket,CLR_NONE);
      if(!Delete)Print("ERROR: "+IntegerToString(GetLastError()));
      if(Delete)Print("Order successfully deleted. "+reason);
      return(Delete);
   }
   return(true);
} 
//+------------------------------------------------------------------+
void CloseAllOrders(string symb, int orderType=-1)
{
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
   { 
      if (OrderSelect(pos, SELECT_BY_POS) &&  OrderSymbol()==symb )
      { 
         if(OrderType()==orderType || orderType==-1)
         {
            KillTicket(OrderTicket());
         }  
      }
   }
} 
//+------------------------------------------------------------------+
void CloseAllOrdersTime(string symb, int minutes, int orderType=-1)
{
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
   { 
      if (OrderSelect(pos, SELECT_BY_POS) &&  OrderSymbol()==symb )
      { 
         if(OrderType()==orderType || orderType==-1)
         {
            if((TimeCurrent()-OrderOpenTime())/60 >= minutes)
               KillTicket(OrderTicket());
         }  
      }
   }
} 

//+------------------------------------------------------------------+
bool HandleTradingEnvironment()
{
   if(IsTradeAllowed())return(true);
   if(!IsConnected())
   {
      Print("Terminal is not connected to server...");
      return(false);
   }
   if(!IsTradeAllowed() && !IsTradeContextBusy())
      Print("Trade is not alowed for some reason...");
   if(IsConnected() && !IsTradeAllowed())
   {
      while(IsTradeContextBusy())
      {
         Print("Trading context is busy... Will wait a bit...");
         Sleep(500);
      }
   }
   if(IsTradeAllowed())
   {
      RefreshRates();
      return(true);
   }
   else
      return(false);
}
//+------------------------------------------------------------------+
int NumberOfTrades(string symb, int orderType=-1)
{
   int positions=0;
   for(int i=0;i<OrdersTotal();i++)
      if (OrderSelect(i, SELECT_BY_POS)   &&  OrderSymbol()==symb )
         if(OrderType()== orderType || orderType==-1)
            positions++;
        
   return positions;
}
//+------------------------------------------------------------------+
int NumberOfTradesTime(string symb, int minutes, int orderType=-1)
{
   int positions=0;
   for(int i=0;i<OrdersTotal();i++)
      if (OrderSelect(i, SELECT_BY_POS)   &&  OrderSymbol()==symb )
         if(OrderType()== orderType || orderType==-1)
            if((TimeCurrent()-OrderOpenTime())/60 >= minutes)
               positions++;
        
   return positions;
}

//+------------------------------------------------------------------+
double TotalProfit(string symb, int orderType=-1)
{
   double profit=0;
   int orders=OrdersTotal()-1;
   for(int i=orders; i>=0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) &&  OrderSymbol()==symb)
         if(orderType==-1 || OrderType()==orderType)
            profit+=OrderProfit()+OrderSwap()+OrderCommission();
   }
   return(profit);
}
//+------------------------------------------------------------------+
double CountCurrentProfit(string symb, int orderType)
{
   double Profit=0;
   int orders=OrdersTotal()-1;
   for(int i=orders; i>=0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==symb && OrderType()==orderType)
         Profit+=OrderProfit()+OrderSwap()+OrderCommission();
   }
   return(Profit);
}
//+------------------------------------------------------------------+
double CountCurrentProfitTime(string symb, int minutes, int orderType)
{
   double Profit=0;
   int orders=OrdersTotal()-1;
   for(int i=orders; i>=0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol()==symb && OrderType()==orderType)
         if((TimeCurrent()-OrderOpenTime())/60 >= minutes)
            Profit+=OrderProfit()+OrderSwap()+OrderCommission();
   }
   return(Profit);
}     

//+------------------------------------------------------------------+
double GetOrderProfit(int Ticket)
{
   if(OrderSelect(Ticket,SELECT_BY_TICKET))
   {
      return OrderProfit()+OrderSwap()+OrderCommission();
   }
   return 0;
}

//+------------------------------------------------------------------+
bool isTradeOpened(string symb)
{
   for(int pos = OrdersTotal()-1; pos >= 0 ; pos--)
   { 
      if (OrderSelect(pos, SELECT_BY_POS)  && OrderSymbol()==symb)
      { 
         if(OrderType()==OP_BUY || OrderType()==OP_SELL|| OrderType()==OP_SELLSTOP|| OrderType()==OP_BUYSTOP)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Price Functions                                                  |
//+------------------------------------------------------------------+
double PriceToPips(double price)
{
   double PointValue;
   if (Digits == 5 || Digits == 3) PointValue = 10.0 * Point;
   else PointValue = Point;
   if (Symbol() == "GOLD" || Symbol() == "SILVER" || Digits==2) 
   {
      return price*10;
      PointValue = Point*10;// / 100.0;
   }
   if (Symbol() == "GOLDEURO"|| Symbol() == "SILVEREURO")
   {
      PointValue = Point;
   }

   return price/PointValue;

   double P=1;
   if(Digits==5 || Digits==3)P=10;else P=1;
   return price/(Point*P);
}
//+------------------------------------------------------------------+
double PipsToPrice(double pips)
{
   double PointValue;
   if (Digits == 5 || Digits == 3) PointValue = 10.0 * Point;
   else PointValue = Point;
   if (Symbol() == "GOLD" || Symbol() == "SILVER" || Digits==2) 
   {
      return pips/10;
      PointValue = Point*10;// / 100.0;
   }
   if (Symbol() == "GOLDEURO"|| Symbol() == "SILVEREURO")
   {
      PointValue = Point;
   }
   return pips*PointValue;

   double P=1;
   if(Digits==5 || Digits==3)P=10;else P=1;
   return pips*(Point*P);
}
//+------------------------------------------------------------------+
string OrderTypeToString(int type)
{
   switch(type)
   {
      case OP_BUY: return "Buy";
      case OP_SELL: return "Sell";
      case OP_BUYLIMIT: return "Buy Limit";
      case OP_BUYSTOP: return "Buy Stop";
      case OP_SELLLIMIT: return "Sell Limit";
      case OP_SELLSTOP: return "Sell Stop";
      default: return "None";
   }
}
//+------------------------------------------------------------------+
string TFtoString(int period)
{
   switch(period)
   {
      case 0: return TFtoString(Period());
      case PERIOD_M1: return "M1";
      case PERIOD_M5: return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1: return "H1";
      case PERIOD_H4: return "H4";
      case PERIOD_D1: return "D1";
      case PERIOD_W1: return "W1";
      case PERIOD_MN1: return "MN1";
   }
   return "";
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Array Functions                                                  |
//+------------------------------------------------------------------+
template<typename T>
int AddInArray(T &array[],T data)
{
   int size = ArraySize(array);
   ArrayResize(array,size+1);
   array[size] = data;
   return size;
} 

bool IsNull(double val)
{
   return val==INT_MAX || val==0;
}


// Account Manager Code END




//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void ShowAlert(string objname, string text, int xcod, int ycod)
  {
   ObjectDelete(objname);
   ObjectCreate(objname, OBJ_LABEL, 0, 0, 0);
   ObjectSet(objname, OBJPROP_ANCHOR, ANCHOR_CENTER);
   ObjectSet(objname, OBJPROP_XDISTANCE, xcod);
   ObjectSet(objname, OBJPROP_YDISTANCE, ycod);
   ObjectSetText(objname, text, 20, "Calibri", clrAqua);
  }
//+------------------------------------------------------------------+
