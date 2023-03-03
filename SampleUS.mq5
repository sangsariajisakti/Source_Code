//+------------------------------------------------------------------+
 
//+------------------------------------------------------------------+

#property copyright ""
#property link      ""    
#property strict

#include <Expert/Expert.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/TerminalInfo.mqh>    
#include <Object.mqh>
#include <MovingAverages.mqh>

const int SLPTTYPE_RANGE = 0;
const int SLPTTYPE_LEVEL = 1;

const ENUM_ORDER_TYPE_FILLING preferredFillingType = ORDER_FILLING_FOK;         //preferred filling type - will be applied if available
const bool forceFillingType = false;                                            //if set to true, it will force using preferredFillingType when opening orders

//+------------------------------------------------------------------+
// -- Variables
//+------------------------------------------------------------------+
input string CustomComment = "OrielSQ";

input int MagicNumber = 14432;        //MagicNumber
bool LongEntrySignal = false;        //LongEntrySignal
bool ShortEntrySignal = false;        //ShortEntrySignal
bool LongExitSignal = false;        //LongExitSignal
bool ShortExitSignal = false;        //ShortExitSignal
input int ATRFallingPeriod = 20;        //ATRFallingPeriod
input int ProfitTarget = 175;        //ProfitTarget
input int StopLoss = 60;        //StopLoss

//+------------------------------------------------------------------+
// Money Management variables
//+------------------------------------------------------------------+

input string smm = "----------- Money Management - Fixed size -----------";
input double mmLots = 0.1;  
  
//+------------------------------------------------------------------+
// Trading Options variables
//+------------------------------------------------------------------+

input string seod = "----------- Exit At End Of Day -----------";
input bool ExitAtEndOfDay = false;
input string EODExitTime = "23:04";

input string seof = "----------- Exit On Friday -----------";
input bool ExitOnFriday = true;
input string FridayExitTime = "20:40";

input string sltr = "----------- Limit Time Range -----------";
input bool LimitTimeRange = false;
input string SignalTimeRangeFrom = "08:00";
input string SignalTimeRangeTo = "16:00";
input bool ExitAtEndOfRange = false;
input int OrderTypeToExit = 0;

input string smtpd = "----------- Max Trades Per Day -----------";
input int MaxTradesPerDay = 0;
input string smmslpt = "----------- Min/Max SL/PT -----------";
input int MinimumSL = 0;   //Minimum SL in pips
input int MinimumPT = 0;   //Minimum PT in pips
input int MaximumSL = 0;   //Maximum SL in pips
input int MaximumPT = 0;   //Maximum PT in pips


      
input string slts = "----------- Use Tick size (for CFDs) -----------";
// For exotic pairs (usually non forex CFDs) the default method of computing 
// tick size in EA might not work correctly.
// By turning this on and specifying MainChartTickSizeSQ value you can let EA 
// use the correct tick size          
input bool UseSQTickSize = false;                                                              
input double MainChartTickSizeSQ = 1.0E-4;

//+------------------------------------------------------------------+
// -- SQ Variables
// - add word "input" in front of the variable you want
//   to make configurable
//+------------------------------------------------------------------+
                                                                               
int sqMaxEntrySlippage = 5;          //Max tolerated entry slippage in pips. Zero means unlimited slippage
int sqMaxCloseSlippage = 0;          //Max tolerated close slippage in pips. Zero means unlimited slippage       
bool autoCorrectMaxSlippage = true;  //If set to true, it will automatically adjust max slippage according to symbol digits (*10 for 3 and 5 digit symbols)  

//Some brokers have problems with updating position counts. Set this timeout to non-zero value if you experience this.
//For example EnterReverseAtMarket doesn't work well for Admiral Markets, because PositionsTotal() returns 1 even after the order has been closed.
uint orderSelectTimeout = 0;         //in ms

double sqMinDistance = 0.0; //Stop orders min distance from current price

bool tradeInSessionHoursOnly = false;

//+------------------------------------------------------------------+
// Verbose mode values:
// 0 - don't print messages to log at all
// 1 - print messages to terminal log 
// 2 - print messages to file
//+------------------------------------------------------------------+      

int sqVerboseMode = 1;

input int OpenBarDelay = 0; //Open bar delay in minutes
// it can be used for Daily strategies to trigger trading a few minutes later -
// because brokers sometimes have technical delay after midnight and we have to postpone order execution

input string slex = "----------- Order expiration time (for stocks) -----------";
input int ExpirationTime = 0; //Order expiration time in minutes    

int magicNumber;
int minBars = 30;
int sqMaxRetries = 5;           
bool openingOrdersAllowed = true;      
        
bool sqDisplayInfoPanel = MQLInfoInteger(MQL_TESTER) == 0 && MQLInfoInteger(MQL_OPTIMIZATION) == 0;
int sqLabelCorner = 1;
int sqOffsetHorizontal = 5;
int sqOffsetVertical = 20;
color sqLabelColor = clrWhite;

////////
int indicatorHandles[];

//Indicator buffer indexes definitions
#define ATR_1 0     //iCustom(NULL,0, "SqATR", ATRFallingPeriod)
#define HEIKENASHI_1 1     //iCustom(NULL,0, "SqHeikenAshi")

struct LastClosedTrade {
   string symbol;
   int magicNumber;
   datetime closeTime;
};

LastClosedTrade lastClosedTrades[];

#define ATM_EXIT_TYPE_LEVEL 1
#define ATM_EXIT_TYPE_TIME 2
#define ATM_EXIT_TYPE_TRAILING 3

struct ExitOrderInfo {
   ulong ticket;
   int type;
   int bars;
   double size;
   double fixedPips;
   double ATRMultiplicator;
   uchar ATRIndyIndex;
   double lastTrailingPrice;
};

struct OrderExitLevel {
   string symbol;
   int magicNumber;
   ulong mainOrderTicket;
   ExitOrderInfo exits[10];
};

OrderExitLevel orderExits[10];

MqlTradeRequest mrequest;  // Used for sending our trade requests
MqlTradeResult mresult;    // Used to get our trade results
MqlRates mrate[];          // Used to store the prices, volumes and spread of each bar
CTerminalInfo terminalInfo;
                       
string sqStrategyName = "OrielSQ";
datetime startTime = TimeCurrent();
datetime lastCheckedTradeTime = startTime;
                
double gPointCoef = 0;                  

int sqTicket = 1;
datetime lastBarTime;
bool _sqIsBarOpen;
bool cond[100];

double initialBalance = 0;

string valueIdentificationSymbol = "";      
string StrategyID = "masichax";

bool firstCall = true;     
bool timerInitialized = false;

//+------------------------------------------------------------------+
// -- Functions
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    
   //--- Do we have enough bars to work with?
   if(Bars(_Symbol,_Period) < minBars) {   // if total bars is less than minBars
      Alert(StringFormat("NOT ENOUGH DATA: Less Bars than %d", minBars));
      return;
   }

   //--- Get the details of the latest 2 bars
   if(CopyRates(_Symbol, _Period, 0, 2, mrate) < 2) {
      Alert("Error copying rates/history data - error:", GetLastError(), "!!");
      ResetLastError();
      return;
   }
     
   ZeroMemory(mrequest);      // Initialization of mrequest structure
 
   if(!timerInitialized) initTimer();

   checkBarOpen();
   
   if(sqDisplayInfoPanel) {
      sqTextFillOpens();
      if(_sqIsBarOpen) {
         sqTextFillTotals();   
      }  
   }
    
   sqManagePositions(MagicNumber);
   
   openingOrdersAllowed = sqHandleTradingOptions();
   
   ulong _ticket;                    
   double openPrice;  
   double sl, pt;
   double size;
   
//------------------------
// Rule: Trading signals
//------------------------
if (_sqIsBarOpen == true) {
     // init signals only on bar open 
     LongEntrySignal = sqIsFalling(ATR_1, 2, false, 3);

     ShortEntrySignal = sqIsFalling(ATR_1, 2, false, 3);

     LongExitSignal = false;

     ShortExitSignal = false;

   }


//------------------------
// Rule: Long entry
//------------------------
   if (_sqIsBarOpen == true
      &&   LongEntrySignal
)
   {
      // Action #1
        // Enter at Stop
      openPrice = sqFixMarketPrice(sqDaily(NULL,0, "Low", 2), "Current");
      sl = sqFixMarketPrice(sqGetSLLevel("Current", ORDER_TYPE_BUY_STOP, openPrice, 1, StopLoss), "Current");
      pt = sqFixMarketPrice(sqGetPTLevel("Current", ORDER_TYPE_BUY_STOP, openPrice, 1, ProfitTarget), "Current");
      size = mmLots;
      
      _ticket = openPosition(
         ORDER_TYPE_BUY_STOP, // Order type
         "Current", // Symbol
         size, // Size
         openPrice, // Price
         sl, // Stop Loss
         pt, // Profit Target   
         correctSlippage(sqMaxEntrySlippage, "Current"), // Max deviation
         "", // Comment
         MagicNumber, // MagicNumber
         ExpirationTime, // Expiration time
         true, // Replace existing order (if it exists)
         false  // Allow duplicate trades
      );

      if(_ticket > 0) {
         // order was successfuly placed, set or initialize all its exit methods (SL, PT, Trailing Stop, Exit After Bars, etc.)
         sqSetOrderExpiration(_ticket, 176);

         //Check StopLoss & ProfitTarget
         //sqCheckSLPT(_ticket, sl, pt);


      }
  }


//------------------------
// Rule: Short entry
//------------------------
   if (_sqIsBarOpen == true
      &&   (ShortEntrySignal
      &&   (!(LongEntrySignal)))
)
   {
      // Action #1
        // Enter at Stop
      openPrice = sqFixMarketPrice(sqDaily(NULL,0, "High", 2), "Current");
      sl = sqFixMarketPrice(sqGetSLLevel("Current", ORDER_TYPE_SELL_STOP, openPrice, 1, StopLoss), "Current");
      pt = sqFixMarketPrice(sqGetPTLevel("Current", ORDER_TYPE_SELL_STOP, openPrice, 1, ProfitTarget), "Current");
      size = mmLots;
      
      _ticket = openPosition(
         ORDER_TYPE_SELL_STOP, // Order type
         "Current", // Symbol
         size, // Size
         openPrice, // Price
         sl, // Stop Loss
         pt, // Profit Target   
         correctSlippage(sqMaxEntrySlippage, "Current"), // Max deviation
         "", // Comment
         MagicNumber, // MagicNumber
         ExpirationTime, // Expiration time
         true, // Replace existing order (if it exists)
         false  // Allow duplicate trades
      );

      if(_ticket > 0) {
         // order was successfuly placed, set or initialize all its exit methods (SL, PT, Trailing Stop, Exit After Bars, etc.)
         sqSetOrderExpiration(_ticket, 176);

         //Check StopLoss & ProfitTarget
         //sqCheckSLPT(_ticket, sl, pt);


      }





  }


//------------------------
// Rule: Long exit
//------------------------
   if (_sqIsBarOpen == true
      &&   ((LongExitSignal
      &&   (!(LongEntrySignal)))
      &&   sqMarketPositionIsLong(MagicNumber, "Any", ""))
)
   {
      // Action #1
      sqCloseFirstTrade(MagicNumber, "Any", 1, "");


  }


//------------------------
// Rule: Short exit
//------------------------
   if (_sqIsBarOpen == true
      &&   ((ShortExitSignal
      &&   (!(ShortEntrySignal)))
      &&   sqMarketPositionIsShort(MagicNumber, "Any", ""))
)
   {
      // Action #1
      sqCloseFirstTrade(MagicNumber, "Any", -1, "");


  }



   if (_sqIsBarOpen == true && isNettingMode()){    
      checkOpenPositions();
   }
}      

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   
   VerboseLog("--------------------------------------------------------");
   VerboseLog("Starting the EA");

   //initMagicNumber();
   if(!initIndicators()) return(INIT_FAILED);
   
   gPointCoef = calculatePointCoef(Symbol());

   //VerboseLog("Broker stop level: ", SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL));

   VerboseLog("--------------------------------------------------------");          
   
   if(sqDisplayInfoPanel) {
     sqInitInfoPanel();
   }
   
   SQTime = new CSQTime();
    
   if(MQLInfoInteger(MQL_TESTER) == 0 && MQLInfoInteger(MQL_OPTIMIZATION) == 0){
      initTimer();   
   }         
   else {
      timerInitialized = true;
   }
   
   initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   objExitAtEndOfDay = new CExitAtEndOfDay();
   objExitOnFriday = new CExitOnFriday();
   objLimitTimeRange = new CLimitTimeRange();
   objMaxTradesPerDay = new CMaxTradesPerDay();
   objMinMaxSLPT = new CMinMaxSLPT();
   
   
   double minDistanceMT = NormalizeDouble(SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(Symbol(), SYMBOL_POINT), Digits());
   double minDistanceSQ = NormalizeDouble(sqMinDistance * sqGetPointCoef(Symbol()), Digits());
   
   if(minDistanceSQ < minDistanceMT){
      VerboseLog("--------------------------------------------------------");
      VerboseLog("Warning! Min distance of this symbol is greater than min distance set in SQ! The backtest results may differ");
      VerboseLog("MT min distance: ", DoubleToString(minDistanceMT), ", SQ min distance: ", DoubleToString(minDistanceSQ));
      VerboseLog("--------------------------------------------------------");
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   
   sqDeinitInfoPanel();
  
                                    
   writeReportFile();  
                              
   delete SQTime;
   delete objExitAtEndOfDay;
   delete objExitOnFriday;
   delete objLimitTimeRange;
   delete objMaxTradesPerDay;
   delete objMinMaxSLPT;
   
}
         
//+------------------------------------------------------------------+

void initTimer(){
   int period = 20 * 3600;                //20 hours
   period += MathRand() % (10 * 3600);    //add another 0-10 hours randomly
   
   if(!EventSetTimer(period)){
      VerboseLog("Cannot set timer. Error code: ", IntegerToString(GetLastError()));
   }      
   else {
      timerInitialized = true;
   }
}

//+------------------------------------------------------------------+

void OnTimer(){
   //clear unused variables
   int deletedCount = 0;
   
   VerboseLog("Clearing variables...");
   
   for(int a=GlobalVariablesTotal() - 1; a>=0; a--){
      string variableName = GlobalVariableName(a);
      
      if(GlobalVariableCheck(variableName)){
         string variableNameParts[];
         int parts = StringSplit(variableName, '_', variableNameParts);
         
         if(parts != 3 || StringFind(variableNameParts[0], getVariablePrefix()) != 0) continue;
         
         long ticketNo = StringToInteger(variableNameParts[1]);

         bool variableUsed = false;
         
         if(PositionSelectByTicket(ticketNo)) {    // check if position with this ticket exists
            variableUsed = true;    
         }
         else {                                    // check if pending order with this ticket exists
            for (int i = 0; i < OrdersTotal(); i++) {
               if(OrderGetTicket(i) == ticketNo){
                  variableUsed = true;
                  break;
               }
            }
         }
         
         ResetLastError();
         
         if(!variableUsed){
            if(GlobalVariableDel(variableName)){
               deletedCount++;
            }
            else {
               VerboseLog("Cannot delete variable. Error code: ", IntegerToString(GetLastError()));
            }
         }
      }
   }
   
   VerboseLog(IntegerToString(deletedCount), " variables cleared");
}

//+------------------------------------------------------------------+

bool sqHandleTradingOptions() {
   bool continueWithBarUpdate = true;

   if(!objExitAtEndOfDay.onBarUpdate()) continueWithBarUpdate = false;
   if(!objExitOnFriday.onBarUpdate()) continueWithBarUpdate = false;
   if(!objLimitTimeRange.onBarUpdate()) continueWithBarUpdate = false;
   if(!objMaxTradesPerDay.onBarUpdate()) continueWithBarUpdate = false;
   if(!objMinMaxSLPT.onBarUpdate()) continueWithBarUpdate = false;

   return(continueWithBarUpdate);
}

//+------------------------------------------------------------------+

bool checkMagicNumber(ulong magicNo){
    if(magicNo == MagicNumber){
         return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Trade transaction event                                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void updateLastTrades(){
    HistorySelect(lastCheckedTradeTime, TimeCurrent());
    lastCheckedTradeTime = TimeCurrent();
    
    for(int i=HistoryDealsTotal() - 1; i>=0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        string dealSymbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
        int dealMagic = (int) HistoryDealGetInteger(ticket, DEAL_MAGIC);
        datetime dealTime = (datetime) HistoryDealGetInteger(ticket, DEAL_TIME);
      
        if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
        
        int lastTradeIndex = getLastTradeIndex(dealSymbol, dealMagic);
        if(lastTradeIndex >= 0){
           if(dealTime > lastClosedTrades[lastTradeIndex].closeTime){
               lastClosedTrades[lastTradeIndex].closeTime = dealTime;
           }
        }
        else {
           int prevSize = ArraySize(lastClosedTrades);
           ArrayResize(lastClosedTrades, prevSize + 1, 10);
           
           lastClosedTrades[prevSize].symbol = dealSymbol;
           lastClosedTrades[prevSize].magicNumber = dealMagic;
           lastClosedTrades[prevSize].closeTime = dealTime;
        }
    }
}

//+------------------------------------------------------------------+

bool sqTradeRecentlyClosed(string symbol, int magicNo, bool checkThisBar, bool checkThisMinute) {         
    updateLastTrades();
    
    string tradeSymbol = correctSymbol(symbol);
    int lastTradeIndex = -1;
    
    if(tradeSymbol == "Any" || magicNo == 0){ 
        for(int a=0; a<ArraySize(lastClosedTrades); a++){
            if((tradeSymbol == "Any" || lastClosedTrades[a].symbol == tradeSymbol) && (magicNo == 0 || lastClosedTrades[a].magicNumber == magicNo)){
                if(lastTradeIndex < 0 || lastClosedTrades[a].closeTime > lastClosedTrades[lastTradeIndex].closeTime){
                    lastTradeIndex = a;
                }
            }
        }
    }
    else {
        lastTradeIndex = getLastTradeIndex(tradeSymbol, magicNo);
    }
    
    if(lastTradeIndex >= 0) {
        if(checkThisBar) {
           if(lastClosedTrades[lastTradeIndex].closeTime >= getTime(0)) {
              // order finished this bar
              return true;
           }
        }
  
        if(checkThisMinute) {
            string strCurrentsqTimeMinutes = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES);
            string strClosesqTimeMinutes = TimeToString(lastClosedTrades[lastTradeIndex].closeTime, TIME_DATE | TIME_MINUTES);
  
            if(strCurrentsqTimeMinutes == strClosesqTimeMinutes) {
                // order finished this minute
                return true;
            }
        }
    }
    
    return false;
}
   
//+------------------------------------------------------------------+

int getLastTradeIndex(string symbol, int magicNo){
    for(int a=0; a<ArraySize(lastClosedTrades); a++){
        if(lastClosedTrades[a].symbol == symbol && lastClosedTrades[a].magicNumber == magicNo) return a;
    }
    
    return -1;
}
   
//+------------------------------------------------------------------+

bool initIndicators(){
   
   ArrayResize(indicatorHandles, ArraySize(indicatorHandles) + 1, 10);
   indicatorHandles[ATR_1] = iCustom(NULL,0, "SqATR", ATRFallingPeriod);
   
   ArrayResize(indicatorHandles, ArraySize(indicatorHandles) + 1, 10);
   indicatorHandles[HEIKENASHI_1] = iCustom(NULL,0, "SqHeikenAshi");
   
   
   for(int a=0; a<ArraySize(indicatorHandles); a++){
      //--- if the handle is not created 
      if(indicatorHandles[a] == INVALID_HANDLE) { 
         //--- tell about the failure and output the error code 
         Print("Failed to create handle of the indicator, error code %d", GetLastError()); 
         //--- the indicator is stopped early 
         return(false); 
      }
   }
   
   return(true);
}             

//+------------------------------------------------------------------+
 
bool isFibo(uchar indyIndex){
   return false;
}

//+------------------------------------------------------------------+

uchar getHeikenAshiIndex(string symbol, ENUM_TIMEFRAMES timeframe){
   symbol = correctSymbol(symbol);
   
   if(symbol == Symbol() && (timeframe == Period() || timeframe == 0)){
      return HEIKENASHI_1;
   }
   else {
   }

   return 255;
}

//+------------------------------------------------------------------+

double sqGetMarketTickSize(string symbol){
   if(!UseSQTickSize) return -1;
   symbol = correctSymbol(symbol);
    
      if(symbol == Symbol()){
         return MainChartTickSizeSQ;
      }
    
   
   return -1;
}

//+------------------------------------------------------------------+

double sqGetGlobalSL(string symbol, int orderType, double price) {
   return(sqGetSLLevel(symbol, orderType, price, 1, 0));
}

//+------------------------------------------------------------------+

double sqGetGlobalPT(string symbol, int orderType, double price) {
   return(sqGetPTLevel(symbol, orderType, price, 1, 0));
}

//+------------------------------------------------------------------+

double sqGetValueByIdentification(int idHash) {
   string symbol = valueIdentificationSymbol;
   
   if(idHash == sqStringHash("ProfitTarget")) {
      return (sqConvertToRealPips(PositionGetString(POSITION_SYMBOL), ProfitTarget));
   }
   if(idHash == sqStringHash("StopLoss")) {
      return (sqConvertToRealPips(PositionGetString(POSITION_SYMBOL), StopLoss));
   }
   if(idHash == sqStringHash("ProfitTarget")) {
      return (sqConvertToRealPips(PositionGetString(POSITION_SYMBOL), ProfitTarget));
   }
   if(idHash == sqStringHash("StopLoss")) {
      return (sqConvertToRealPips(PositionGetString(POSITION_SYMBOL), StopLoss));
   }

   return(0);
}

//+------------------------------------------------------------------+

double sqGetExpressionByIdentification(string id, int shift) {
   
   return(0);
}

//+------------------------------------------------------------------+

bool sqIsExpression(string id) {
   
   return(false);
}
  
//+------------------------------------------------------------------+
    
void sqManagePositions(int magicNo) {
   if(_sqIsBarOpen){
     for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
        ulong positionTicket = PositionGetTicket(cc);
     
        if (PositionSelectByTicket(positionTicket)) {
           if(PositionGetInteger(POSITION_MAGIC) != magicNo || !IsMarketOpen(PositionGetString(POSITION_SYMBOL))) {      
              continue;
           }
           
           sqManageSL2BE(positionTicket);
           sqManageTrailingStop(positionTicket);
           sqManageExitAfterXBars(positionTicket);
        }
        
        if(PositionsTotal() <= 0) break;
     }
     
     sqManageOrderExpirations(magicNo);
   }
}                                                                                     

//+------------------------------------------------------------------+

/*
void initMagicNumber(){
    int Period_ID = 0;
    switch ( Period() )
    {
        case PERIOD_MN1: Period_ID = 9; break;
        case PERIOD_W1:  Period_ID = 8; break;
        case PERIOD_D1:  Period_ID = 7; break;
        case PERIOD_H4:  Period_ID = 6; break;
        case PERIOD_H1:  Period_ID = 5; break;
        case PERIOD_M30: Period_ID = 4; break;
        case PERIOD_M15: Period_ID = 3; break;
        case PERIOD_M5:  Period_ID = 2; break;
        case PERIOD_M1:  Period_ID = 1; break;
    }
    magicNumber = MagicNumber * 10 + Period_ID;//Expert_ID * 10 + Period_ID;
}
*/

//+------------------------------------------------------------------+

void checkBarOpen(){
   datetime currentBarTime = mrate[0].time;   
   _sqIsBarOpen = false;
   
   if(lastBarTime == 0){
      _sqIsBarOpen = true;          
      lastBarTime = currentBarTime;
   }
   else if(currentBarTime != lastBarTime){
      bool processBarOpen = true;

      if(OpenBarDelay > 0) {
         // set bar to open after X minutes from real open
         processBarOpen = false;

         int diffInSeconds = (int) (TimeCurrent() - currentBarTime);
         if(diffInSeconds >= OpenBarDelay * 60) {
            processBarOpen = true;
         }
      }

      if(processBarOpen) {
         _sqIsBarOpen = true;
         lastBarTime = currentBarTime;      
      } 
   }
}

//+------------------------------------------------------------------+

bool indyCrossesAbove(uchar indyIndex1, uchar indyIndex2, int shift1, int shift2, int bufferIndex1=0, int bufferIndex2=0) {
   double buffer1[], buffer2[];
   if(!loadIndicatorValues(buffer1, indyIndex1, 2, shift1, true, bufferIndex1) || !loadIndicatorValues(buffer2, indyIndex2, 2, shift2, true, bufferIndex2)) return false;
   
   return sqIndyCrossedAbove(buffer1, buffer2);
}   

//+------------------------------------------------------------------+

bool indyCrossesAbove(string expression, uchar indyIndex2, int shift1, int shift2, int bufferIndex1=0, int bufferIndex2=0) {
   double buffer1[], buffer2[];
   if(!loadIndicatorValues(buffer1, expression, 2, shift1, true, bufferIndex1) || !loadIndicatorValues(buffer2, indyIndex2, 2, shift2, true, bufferIndex2)) return false;
   
   return sqIndyCrossedAbove(buffer1, buffer2);
}

//+------------------------------------------------------------------+

bool indyCrossesAbove(uchar indyIndex1, string expression, int shift1, int shift2, int bufferIndex1=0, int bufferIndex2=0) {
   double buffer1[], buffer2[];
   if(!loadIndicatorValues(buffer1, indyIndex1, 2, shift1, true, bufferIndex1) || !loadIndicatorValues(buffer2, expression, 2, shift2, true, bufferIndex2)) return false;
   
   return sqIndyCrossedAbove(buffer1, buffer2);
}

//+------------------------------------------------------------------+

bool indyCrossesAbove(string expression1, string expression2, int shift1, int shift2, int bufferIndex1=0, int bufferIndex2=0) {
   double buffer1[], buffer2[];
   if(!loadIndicatorValues(buffer1, expression1, 2, shift1, true, bufferIndex1) || !loadIndicatorValues(buffer2, expression2, 2, shift2, true, bufferIndex2)) return false;
   
   return sqIndyCrossedAbove(buffer1, buffer2);
}

//+------------------------------------------------------------------+

bool sqIndyCrossedAbove(double &buffer1[], double &buffer2[]){
   return (!sqDoublesAreEqual(buffer1[0], buffer2[0], false) && buffer1[0] < buffer2[0]) && (!sqDoublesAreEqual(buffer1[1], buffer2[1], false) && buffer1[1] > buffer2[1]);
}

//+------------------------------------------------------------------+

bool indyCrossesBelow(uchar indyIndex1, uchar indyIndex2, int shift1, int shift2, int bufferIndex1=0, int bufferIndex2=0) {
   double buffer1[], buffer2[];
   if(!loadIndicatorValues(buffer1, indyIndex1, 2, shift1, true, bufferIndex1) || !loadIndicatorValues(buffer2, indyIndex2, 2, shift2, true, bufferIndex2)) return false;
   return sqIndyCrossedBelow(buffer1, buffer2);
}       
   
//+------------------------------------------------------------------+

bool indyCrossesBelow(string expression, uchar indyIndex2, int shift1, int shift2, int bufferIndex1=0, int bufferIndex2=0) {
   double buffer1[], buffer2[];
   if(!loadIndicatorValues(buffer1, expression, 2, shift1, true, bufferIndex1) || !loadIndicatorValues(buffer2, indyIndex2, 2, shift2, true, bufferIndex2)) return false;
   return sqIndyCrossedBelow(buffer1, buffer2);
}

//+------------------------------------------------------------------+

bool indyCrossesBelow(uchar indyIndex1, string expression, int shift1, int shift2, int bufferIndex1=0, int bufferIndex2=0) {
   double buffer1[], buffer2[];
   if(!loadIndicatorValues(buffer1, indyIndex1, 2, shift1, true, bufferIndex1) || !loadIndicatorValues(buffer2, expression, 2, shift2, true, bufferIndex2)) return false;
   return sqIndyCrossedBelow(buffer1, buffer2);
}

//+------------------------------------------------------------------+

bool indyCrossesBelow(string expression1, string expression2, int shift1, int shift2, int bufferIndex1=0, int bufferIndex2=0) {
   double buffer1[], buffer2[];
   if(!loadIndicatorValues(buffer1, expression1, 2, shift1, true, bufferIndex1) || !loadIndicatorValues(buffer2, expression2, 2, shift2, true, bufferIndex2)) return false;
   return sqIndyCrossedBelow(buffer1, buffer2);
}

//+------------------------------------------------------------------+

bool sqIndyCrossedBelow(double &buffer1[], double &buffer2[]){
   return (!sqDoublesAreEqual(buffer1[0], buffer2[0], false) && buffer1[0] > buffer2[0]) && (!sqDoublesAreEqual(buffer1[1], buffer2[1], false) && buffer1[1] < buffer2[1]);
}

//+------------------------------------------------------------------+

bool crossesAbove(uchar indyIndex, int shift, double value, int bufferIndex=0) {
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, 2, shift, true, bufferIndex)) return false;
   return sqValuesCrossedAbove(buffer, value);
}      

//+------------------------------------------------------------------+

bool crossesAbove(string expression, int shift, double value, int bufferIndex=0) {
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, 2, shift, true, bufferIndex)) return false;
   return sqValuesCrossedAbove(buffer, value);
}  

//+------------------------------------------------------------------+

bool sqValuesCrossedAbove(double &buffer[], double value){
   return (buffer[0] < value || sqDoublesAreEqual(buffer[0], value, false)) && (buffer[1] > value && !sqDoublesAreEqual(buffer[1], value, false));
}

//+------------------------------------------------------------------+

bool crossesBelow(uchar indyIndex, int shift, double value, int bufferIndex=0) {
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, 2, shift, true, bufferIndex)) return false;
   return sqValuesCrossedBelow(buffer, value);
}     

//+------------------------------------------------------------------+

bool crossesBelow(string expression, int shift, double value, int bufferIndex=0) {
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, 2, shift, true, bufferIndex)) return false;
   return sqValuesCrossedBelow(buffer, value);
} 

//+------------------------------------------------------------------+

bool sqValuesCrossedBelow(double &buffer[], double value){
   return (buffer[0] > value || sqDoublesAreEqual(buffer[0], value, false)) && (buffer[1] < value && !sqDoublesAreEqual(buffer[1], value, false));
}

//+------------------------------------------------------------------+

bool crossesUp(uchar indyIndex, int shift, double value, int bufferIndex=0) {
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, 2, shift, true, bufferIndex)) return false;
   return sqValuesCrossedUp(buffer, value);
}        

//+------------------------------------------------------------------+

bool crossesUp(string expression, int shift, double value, int bufferIndex=0) {
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, 2, shift, true, bufferIndex)) return false;
   return sqValuesCrossedUp(buffer, value);
}     
    
//+------------------------------------------------------------------+

bool sqValuesCrossedUp(double &buffer[], double value){
   return (buffer[0] < value && !sqDoublesAreEqual(buffer[0], value, false)) && (buffer[1] > value && !sqDoublesAreEqual(buffer[1], value, false));
}

//+------------------------------------------------------------------+

bool crossesDown(uchar indyIndex, int shift, double value, int bufferIndex=0) {
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, 2, shift, true, bufferIndex)) return false;
   return sqValuesCrossedDown(buffer, value);
}      

//+------------------------------------------------------------------+

bool crossesDown(string expression, int shift, double value, int bufferIndex=0) {
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, 2, shift, true, bufferIndex)) return false;
   return sqValuesCrossedDown(buffer, value);
}     
        
//+------------------------------------------------------------------+

bool sqValuesCrossedDown(double &buffer[], double value){
   return (buffer[0] > value && !sqDoublesAreEqual(buffer[0], value, false)) && (buffer[1] < value && !sqDoublesAreEqual(buffer[1], value, false));
}

//+------------------------------------------------------------------+

bool changesUp(uchar indyIndex, int shift, int bufferIndex=0){
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, 3, shift, true, bufferIndex)) return false;
   return sqValuesChangedUp(buffer);
}     

//+------------------------------------------------------------------+

bool changesUp(string expression, int shift, int bufferIndex=0){
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, 3, shift, true, bufferIndex)) return false;
   return sqValuesChangedUp(buffer);
}   
        
//+------------------------------------------------------------------+

bool sqValuesChangedUp(double &buffer[]){
   return (buffer[0] > buffer[1] && !sqDoublesAreEqual(buffer[0], buffer[1], false)) && (buffer[1] < buffer[2] && !sqDoublesAreEqual(buffer[1], buffer[2], false));
}

//+------------------------------------------------------------------+

bool changesDown(uchar indyIndex, int shift, int bufferIndex=0){
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, 3, shift, true, bufferIndex)) return false;
   return sqValuesChangedDown(buffer);
}       

//+------------------------------------------------------------------+

bool changesDown(string expression, int shift, int bufferIndex=0){
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, 3, shift, true, bufferIndex)) return false;
   return sqValuesChangedDown(buffer);
}
        
//+------------------------------------------------------------------+

bool sqValuesChangedDown(double &buffer[]){
   return (buffer[0] < buffer[1] && !sqDoublesAreEqual(buffer[0], buffer[1], false)) && (buffer[1] > buffer[2] && !sqDoublesAreEqual(buffer[1], buffer[2], false));
}
         
//+------------------------------------------------------------------+

bool sqIsFalling(uchar indyIndex, int bars, bool allowSameValues, int shift, int bufferIndex=0){
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, bars, shift, true, bufferIndex)) return false;
   return sqValuesFalling(buffer, allowSameValues);
}

//+------------------------------------------------------------------+

bool sqIsFalling(string expression, int bars, bool allowSameValues, int shift, int bufferIndex=0){
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, bars, shift, true, bufferIndex)) return false;
   return sqValuesFalling(buffer, allowSameValues);
}

//+------------------------------------------------------------------+

bool sqValuesFalling(double &buffer[], bool allowSameValues){             
   bool atLeastOnce = false;       
   double lastValue = buffer[0];
   
   for(int a=1; a<ArraySize(buffer); a++){
      if((buffer[a] > lastValue && !sqDoublesAreEqual(buffer[a], lastValue, false)) || (!allowSameValues && sqDoublesAreEqual(buffer[a], lastValue, false))) {
          return false;
      }
      
      if(buffer[a] < lastValue && !sqDoublesAreEqual(buffer[a], lastValue, false)){
         atLeastOnce = true;
      }
      
      lastValue = buffer[a];
   }
   
   return atLeastOnce;
}

//+------------------------------------------------------------------+

bool sqIsRising(uchar indyIndex, int bars, bool allowSameValues, int shift, int bufferIndex=0){
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, bars, shift, true, bufferIndex)) return false;
   return sqValuesRising(buffer, allowSameValues);
}

//+------------------------------------------------------------------+

bool sqIsRising(string expression, int bars, bool allowSameValues, int shift, int bufferIndex=0){
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, bars, shift, true, bufferIndex)) return false;
   return sqValuesRising(buffer, allowSameValues);
}

//+------------------------------------------------------------------+

bool sqValuesRising(double &buffer[], bool allowSameValues){
   bool atLeastOnce = false;
   double lastValue = buffer[0];
   
   for(int a=1; a<ArraySize(buffer); a++){
      if((buffer[a] < lastValue && !sqDoublesAreEqual(buffer[a], lastValue, false)) || (!allowSameValues && sqDoublesAreEqual(buffer[a], lastValue, false))) {
          return false;
      }
      
      if(buffer[a] > lastValue && !sqDoublesAreEqual(buffer[a], lastValue, false)){
         atLeastOnce = true;
      }
      
      lastValue = buffer[a];
   }
   
   return atLeastOnce;
}
       
//+------------------------------------------------------------------+

double sqGetIndicatorValue(string expression, int shift, bool doRounding=true) {
   double buffer[];
   if(!loadIndicatorValues(buffer, expression, 1, shift, doRounding)) return 0;
   
   return buffer[0];
}

//+------------------------------------------------------------------+

double sqGetIndicatorValue(uchar indyIndex, int shift, bool doRounding=true) {
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, 1, shift, doRounding)) return 0;
   
   return buffer[0];
}
  
//+------------------------------------------------------------------+

double sqGetIndicatorValue(uchar indyIndex, int bufferIndex, int shift, bool doRounding=true) {
   double buffer[];
   if(!loadIndicatorValues(buffer, indyIndex, 1, shift, doRounding, bufferIndex)) return 0;
   
   return buffer[0];
}

//+------------------------------------------------------------------+

/* Waits until indicator data become available */
void waitForData(int handle, int bufferIndex, int shift){
   double buffer[];
   int i, copied = CopyBuffer(handle, bufferIndex, shift, 1, buffer); 
   
   if(copied <= 0){ 
      Sleep(10);
       
      for(i=0; i<100; i++){ 
         if(BarsCalculated(handle) > 0) break; 
         Sleep(10); 
      } 
   }
}

//+------------------------------------------------------------------+

bool loadIndicatorValues(double& buffer[], uchar indyIndex, int bars, int shift, bool doRounding=true, int bufferIndex=0){
   //--- reset error code 
   ResetLastError(); 
   //--- fill a part of the Buffer array with values from the indicator buffer that has 0 index 

   bool isFiboIndicator = isFibo(indyIndex);
   if(isFiboIndicator){
      shift = 0;
   }

   if(indyIndex < 255) {
      if(CopyBuffer(indicatorHandles[indyIndex], bufferIndex, shift, bars, buffer) < 0) { 
         //--- if the copying fails, tell the error code 
         PrintFormat("Failed to copy data from the indicator with index %d, error code %d", indyIndex, GetLastError());  
         //--- quit with zero result - it means that the indicator is considered as not calculated 
         return(false); 
      } 
      
      //for Fibo indicator use the current value only 
      if(isFiboIndicator){
         double curValue = buffer[bars-1];
         
         for(int a=0; a<bars; a++){
            buffer[a] = curValue;
         }
      }
     
      if(doRounding){
         roundValues(buffer);
      }
      return(true); 
   }           
   
   return(false);
}
  
//+------------------------------------------------------------------+

bool loadIndicatorValues(double& buffer[], string expression, int bars, int shift, bool doRounding=true, int bufferIndex=0){
   //--- reset error code 
   ResetLastError(); 
   //--- fill a part of the Buffer array with values from the indicator buffer that has 0 index 

   ArrayResize(buffer, bars);
      
   //check for expressions (indicator values combined with +,- etc.)
   if(sqIsExpression(expression)){
      for(int a=0; a<bars; a++){
         int curShift = shift + bars - 1 - a;
         buffer[a] = sqGetExpressionByIdentification(expression, curShift);
      }
     
      if(doRounding){
         roundValues(buffer);
      }
      return(true);
   }
  
   return(false);
}
 
//+------------------------------------------------------------------+

void roundValues(double &buffer[]){
    for(int a=0; a<ArraySize(buffer); a++){
        buffer[a] = NormalizeDouble(buffer[a] + 0.0000000001, 6);
    }
}

//+------------------------------------------------------------------+

bool extractParams(string wholeString, string &buffer[]){
   int bracketPos = StringFind(wholeString, "(") + 1;
   if(bracketPos < 0) return(false);
   
   string paramsStr = StringSubstr(wholeString, bracketPos, StringLen(wholeString) - bracketPos - 1);
         
   StringSplit(paramsStr, StringGetCharacter(",", 0), buffer);
   
   for(int a=0; a<ArraySize(buffer); a++){
      StringTrimLeft(buffer[a]);
      StringTrimRight(buffer[a]);
   }
   
   return(true);
}

//+------------------------------------------------------------------+

string correctSymbol(string symbol){
    if(symbol == NULL || symbol == "NULL" || symbol == "Current" || symbol == "0" || symbol == "Same as main chart") {
        return Symbol();
    }
        else return symbol;
}

//+------------------------------------------------------------------+

bool sqIchimokuChikouSpanCross(int bullishOrBearish, string symbol, int timeframe, uchar indyIndex, int shift, int SignalStrength) {
   double chikouSpan1 = sqGetIndicatorValue(indyIndex, 4, shift + 1, true);
	double chikouSpan0 = sqGetIndicatorValue(indyIndex, 4, shift, true);
	double c = sqClose(symbol, timeframe, shift);
	double kumoTop = sqGetIndicatorValue(indyIndex, 2, shift, true);
	double kumoBottom = sqGetIndicatorValue(indyIndex, 3, shift, true);
	if(kumoBottom > kumoTop) {
		double temp = kumoBottom;
		kumoBottom = kumoTop;
		kumoTop = temp;
	}
		
	bool signal;
	
	SignalStrength = SignalStrength >= 0 && SignalStrength <= 2 ? SignalStrength : 1;
	
	if(bullishOrBearish == -1) {
	   // bearish;
	   signal = (chikouSpan1 >= c) && (chikouSpan0 < c) && (chikouSpan1 > chikouSpan0);
		
		if(SignalStrength == 2) {
			// for strong signal the cross should happen below kumo cloud
			signal = signal && (c < kumoBottom);
			
		} else if(SignalStrength == 1) {
			// for neutral signal the cross should happen in kumo cloud
			signal = signal && (c < kumoTop);
			
		} else if(SignalStrength == 0) {
			// do nothing, if there is cross signal is always at least weak
			
		} else {
			return false;;
		}
		
		return signal;
		
	} else if(bullishOrBearish == 1) { 
	   // bullish
	   signal = (chikouSpan1 <= c) && (chikouSpan0 > c) && (chikouSpan1 < chikouSpan0);
	   
	   if(SignalStrength == 2) {
			// for strong signal the cross should happen above kumo cloud
			signal = signal && (c > kumoTop);
			
		} else if(SignalStrength == 1) {
			// for neutral signal the cross should happen in kumo cloud
			signal = signal && (c > kumoBottom);
			
		} else if(SignalStrength == 0) {
			// do nothing, if there is cross signal is always at least weak
			
		} else {
			return false;
		}

		return signal;
		
	} else {
			return false;
	}
}

//+------------------------------------------------------------------+

bool sqIchimokuSenkouSpanCross(int bullishOrBearish, string symbol, int timeframe, uchar indyIndex, int shift, int SignalStrength) {
	double senkouSpanA1 = sqGetIndicatorValue(indyIndex, 2, shift + 1, true);
	double senkouSpanA0 = sqGetIndicatorValue(indyIndex, 2, shift, true);
	double senkouSpanB1 = sqGetIndicatorValue(indyIndex, 3, shift + 1, true);
	double senkouSpanB0 = sqGetIndicatorValue(indyIndex, 3, shift, true);
	double c = sqClose(symbol, timeframe, shift);
			
	double kumoTop = MathMax(senkouSpanA0,  senkouSpanB0); 
	double kumoBottom = MathMin(senkouSpanA0,  senkouSpanB0); 
		
	bool signal;
	
	SignalStrength = SignalStrength >= 0 && SignalStrength <= 2 ? SignalStrength : 1;
	
	if(bullishOrBearish == -1) {
	   // bearish;
	   signal = (senkouSpanA1 > senkouSpanB1) && (senkouSpanA0 < senkouSpanB0);
		
		if(SignalStrength == 2) {
			// for strong signal the cross should happen below kumo cloud
			signal = signal && (c < kumoBottom);
			
		} else if(SignalStrength == 1) {
			// for neutral signal the cross should happen in kumo cloud
			signal = signal && (c < kumoTop);
			
		} else if(SignalStrength == 0) {
			// do nothing, if there is cross signal is always at least weak
			
		} else {
			return false;;
		}
		
		return signal;
		
	} else if(bullishOrBearish == 1) { 
	   // bullish
	   signal = (senkouSpanA1 < senkouSpanB1) && (senkouSpanA0 > senkouSpanB0);
	   
	   if(SignalStrength == 2) {
			// for strong signal the cross should happen above kumo cloud
			signal = signal && (c > kumoTop);
			
		} else if(SignalStrength == 1) {
			// for neutral signal the cross should happen in kumo cloud
			signal = signal && (c > kumoBottom);
			
		} else if(SignalStrength == 0) {
			// do nothing, if there is cross signal is always at least weak
			
		} else {
			return false;
		}

		return signal;
		
	} else {
			return false;
	}
}

//+------------------------------------------------------------------+

bool sqIchimokuKijunSenCross(int bullishOrBearish, string symbol, int timeframe, uchar indyIndex, int shift, int SignalStrength) {
	double o = sqOpen(symbol, timeframe, shift);
	double c = sqClose(symbol, timeframe, shift);
	double kijun = sqGetIndicatorValue(indyIndex, 1, shift, true);

	double kumoTop = sqGetIndicatorValue(indyIndex, 2, shift, true);
	double kumoBottom = sqGetIndicatorValue(indyIndex, 3, shift, true);
	if(kumoBottom > kumoTop) {
		double temp = kumoBottom;
		kumoBottom = kumoTop;
		kumoTop = temp;
	}
		
	bool signal;
	
	SignalStrength = SignalStrength >= 0 && SignalStrength <= 2 ? SignalStrength : 1;
	
	if(bullishOrBearish == -1) {
	   // bearish;
	   signal = (o > kijun) && c < kijun;
		
		if(SignalStrength == 2) {
			// for strong signal the cross should happen below kumo cloud
			signal = signal && (kijun < kumoBottom);
			
		} else if(SignalStrength == 1) {
			// for neutral signal the cross should happen in kumo cloud
			signal = signal && (kijun < kumoTop);
			
		} else if(SignalStrength == 0) {
			// do nothing, if there is cross signal is always at least weak
			
		} else {
			return false;;
		}
		
		return signal;
		
	} else if(bullishOrBearish == 1) { 
	   // bullish
	   signal = (o < kijun) && c > kijun;
	   
		if(SignalStrength == 2) {
			// for strong signal the cross should happen above kumo cloud
			signal = signal && (kijun > kumoTop);
			
		} else if(SignalStrength == 1) {
			// for neutral signal the cross should happen in kumo cloud
			signal = signal && (kijun > kumoBottom);
			
		} else if(SignalStrength == 0) {
			// do nothing, if there is cross signal is always at least weak
			
		} else {
			return false;
		}

		return signal;
		
	} else {
			return false;
	}
}

//+------------------------------------------------------------------+

bool sqIchimokuTenkanKijunCross(int bullishOrBearish, string symbol, int timeframe, uchar indyIndex, int shift, int SignalStrength) {
	double tenkan1 = sqGetIndicatorValue(indyIndex, 0, shift + 1, true);
	double tenkan0 = sqGetIndicatorValue(indyIndex, 0, shift, true);

	double kijun1 = sqGetIndicatorValue(indyIndex, 1, shift + 1, true);
	double kijun0 = sqGetIndicatorValue(indyIndex, 1, shift, true);

	double kumoTop = sqGetIndicatorValue(indyIndex, 2, shift, true);
	double kumoBottom = sqGetIndicatorValue(indyIndex, 3, shift, true);
	if(kumoBottom > kumoTop) {
		double temp = kumoBottom;
		kumoBottom = kumoTop;
		kumoTop = temp;
	}
		
	bool signal;
	
	SignalStrength = SignalStrength >= 0 && SignalStrength <= 2 ? SignalStrength : 1;
	
	if(bullishOrBearish == -1) {
	   // bearish;
	   signal = (tenkan1 > kijun1) && tenkan0 < kijun0;
		
		if(SignalStrength == 2) {
			// for strong signal the cross should happen below kumo cloud
			signal = signal && (tenkan0 < kumoBottom);
			
		} else if(SignalStrength == 1) {
			// for neutral signal the cross should happen in kumo cloud
			signal = signal && (tenkan0 < kumoTop);
			
		} else if(SignalStrength == 0) {
			// do nothing, if there is cross signal is always at least weak
			
		} else {
			return false;;
		}
		
		return signal;
		
	} else if(bullishOrBearish == 1) { 
	   // bullish
	   signal = (tenkan1 < kijun1) && tenkan0 > kijun0;
	   
		if(SignalStrength == 2) {
			// for strong signal the cross should happen above kumo cloud
			signal = signal && (tenkan0 > kumoTop);
			
		} else if(SignalStrength == 1) {
			// for neutral signal the cross should happen in kumo cloud
			signal = signal && (tenkan0 > kumoBottom);
			
		} else if(SignalStrength == 0) {
			// do nothing, if there is cross signal is always at least weak
			
		} else {
			return false;
		}

		return signal;
		
	} else {
			return false;
	}
}

//+------------------------------------------------------------------+

bool sqIchimokuKumoBreakout(int bullishOrBearish, string symbol, int timeframe, uchar indyIndex, int shift) {
	double o = sqOpen(symbol, timeframe, shift);
	double c = sqClose(symbol, timeframe, shift);

	double kumoTop = sqGetIndicatorValue(indyIndex, 2, shift, true);
	double kumoBottom = sqGetIndicatorValue(indyIndex, 3, shift, true);
	if(kumoBottom > kumoTop) {
		double temp = kumoBottom;
		kumoBottom = kumoTop;
		kumoTop = temp;
	}
		
	bool signal;
	
	if(bullishOrBearish == -1) {
	   // bearish;
	   signal = (o > kumoBottom) && c < kumoBottom;
		
		return signal;
		
	} else if(bullishOrBearish == 1) { 
	   // bullish
	   signal = (o < kumoTop) && c > kumoTop;
		
		return signal;
		
	} else {
			return false;
	}
}

//+------------------------------------------------------------------+

ulong openPosition(ENUM_ORDER_TYPE type, string symbol, double volume, const double price = 0, const double slPrice = 0, const double ptPrice = 0, const int deviation = 100, const string comment = "", const int magicNo = -1, const int expiration = 0, const bool replaceExisting = true, const bool allowDuplicateTrades = true, const bool isExitLevel = false){  
   if(volume <= 0) return (0);

   int correctedMagicNo = magicNo;// > 0 ? magicNo : MagicNumber;
   string correctedSymbol = correctSymbol(symbol);
   int direction = sqGetDirectionFromOrderType(type);

   if(!IsMarketOpen(correctedSymbol)) return 0;
   
   openingOrdersAllowed = openingOrdersAllowed && sqHandleTradingOptions();
   
   if(!openingOrdersAllowed) return(0);                          
   
   // check if live order exists
   if(!isExitLevel && !allowDuplicateTrades && sqSelectPosition(correctedMagicNo, correctedSymbol, 0, comment)) {
      Verbose("Order with these parameters already exists, cannot open another one!");
      Verbose("----------------------------------");
      return(0);
   }
   
   // check if pending order exists
   if(!isExitLevel){
      while(sqSelectOrder(correctedMagicNo, correctedSymbol, direction, comment, false)) {
         if(!replaceExisting) {
            Verbose("Pending Order with these parameters already exists, and replace is not allowed!", " ----------------");
            return(0);
         }

         // close pending order
         Verbose("Deleting previous pending order");
         sqDeletePendingOrder(OrderGetInteger(ORDER_TICKET));
      } 
   }
   
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   
   MqlTick lastTick;
   if(!getLastTick(correctedSymbol, lastTick)) {
      Print("Opening position failed. Cannot get last tick info");
      return 0;
   }
   
   double marketPrice = isLongOrder(type) ? lastTick.ask : lastTick.bid;
   double curPrice = price > 0 ? price : marketPrice;
                          
   //check free margin
	double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin = 0.0;
   bool ret = OrderCalcMargin(isLongOrder(type) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, correctedSymbol, volume, curPrice, margin);

   if(freeMargin - margin <= 0.0 || ret != true){
       Alert("Not enough money to send order with ", DoubleToString(volume), " lot or Margin Calculation Error");
       return 0;
   }

   mrequest.action = (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_SELL_STOP) ? TRADE_ACTION_PENDING : TRADE_ACTION_DEAL;                                       // immediate order execution
   mrequest.price = sqFixMarketPrice(curPrice, correctedSymbol);              // latest price
   mrequest.sl = sqFixMarketPrice(slPrice, correctedSymbol); // Stop Loss
   mrequest.tp = sqFixMarketPrice(ptPrice, correctedSymbol); // Take Profit
   mrequest.symbol = correctedSymbol;                                     
   mrequest.volume = volume;                                                  // number of lots to trade
   mrequest.magic = correctedMagicNo;                                         // Order Magic Number
   mrequest.type = type;                                                      // Buy Order
   mrequest.type_filling = forceFillingType ? preferredFillingType : GetFilling(correctedSymbol, preferredFillingType);          // Order execution type
   mrequest.deviation = deviation;                                            // Deviation from current price
   
   if(expiration > 0){
      mrequest.type_time = ORDER_TIME_SPECIFIED;
      mrequest.expiration = TimeCurrent() + expiration * 60;  
   }
   else {
      mrequest.expiration = 0;
   }

   string commentToUse = "";
   if(comment != ""){
      commentToUse = comment;
   }
   else {
      commentToUse = CustomComment;
      StringReplace(commentToUse, "Optimization", "Opt.");     //shorten the name of optimized strategies
   }
   commentToUse = StringSubstr(commentToUse, 0, 30);           //limit the length to 30 characters

   mrequest.comment = commentToUse;
      
   if(!checkOrderPriceValid(mrequest.type, mrequest.symbol, mrequest.price, marketPrice) ||
       (mrequest.sl != 0 && !checkSLPTValid(mrequest.type, true, mrequest.symbol, mrequest.sl, mrequest.price)) ||
       (mrequest.tp != 0 && !checkSLPTValid(mrequest.type, false, mrequest.symbol, mrequest.tp, mrequest.price))
   ){
      return 0;
   }
   
   //--- send order
   bool success = OrderSend(mrequest,mresult);
   // get the result code
   if(success && (mresult.retcode==10009 || mresult.retcode==10008)) //Request is completed or order placed
     {
      sqResetGlobalVariablesForTicket(mresult.order);
      VerboseLog("The order has been successfully placed with Ticket#:", IntegerToString(mresult.order), "!!");
      return mresult.order;
     }
   else {
      Alert("The order request could not be completed. Error no.: ", GetLastError());
      Alert("Error description: " + ErrorDescription(GetLastError()));
      ResetLastError();           
      return 0;
     }
}          

//----------------------------------------------------------------------------

bool checkOrderPriceValid(ENUM_ORDER_TYPE orderType, string symbol, double price, double marketPrice){
   if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL){
      if(sqDoublesAreEqual(marketPrice, price)){
         return true;
      }
      else {
         VerboseLog("Based on its logic, the strategy tried to place market order at incorrect price. Market price: ", DoubleToString(marketPrice), ", order price: ", DoubleToString(price), " (this is NOT an error)");
         return false;
      }
   }
   
   return checkStopPriceValid(orderType, symbol, price, marketPrice, "stop/limit order");
}

//----------------------------------------------------------------------------

bool checkStopPriceValid(ENUM_ORDER_TYPE orderType, string symbol, double price, double marketPrice, string name){
   int stopLevel = (int) SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double minDistance = point * stopLevel;
   double minDistanceSQ = sqMinDistance * sqGetPointCoef(symbol);
   
   if(minDistanceSQ > minDistance){
      minDistance = minDistanceSQ;
   }
   
   if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_STOP){
      double priceLevel = marketPrice - minDistance;
      
      if(price < priceLevel || sqDoublesAreEqual(price, priceLevel)){
         return true;
      }
      else {
         VerboseLog("Based on its logic, the strategy tried to place ", name, " at incorrect price. Market price: ", DoubleToString(marketPrice), ", max. price allowed: ", DoubleToString(priceLevel), ", ", name, " price: ", DoubleToString(price), " (this is NOT an error)");
         return false;
      }
   }
   else if(orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_SELL_LIMIT){
      double priceLevel = marketPrice + minDistance;
      
      if(price > priceLevel || sqDoublesAreEqual(price, priceLevel)){
         return true;
      }
      else {
         VerboseLog("Based on its logic, the strategy tried to place ", name, " at incorrect price. Market price: ", DoubleToString(marketPrice), ", min. price allowed: ", DoubleToString(priceLevel), ", ", name," price: ", DoubleToString(price));
         return false;
      }
   }
   else return true;
}

//----------------------------------------------------------------------------

bool checkSLPTValid(ENUM_ORDER_TYPE orderType, bool isSL, string symbol, double price, double openPrice){
   int stopLevel = (int) SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double minDistance = point * stopLevel;
   
   bool isBuyOrder = orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_BUY_STOP_LIMIT;
   bool shortDirection = (isBuyOrder && isSL) || (!isBuyOrder && !isSL);
   
   if(shortDirection){
      double priceLevel = openPrice - minDistance;
      
      if(price < priceLevel || sqDoublesAreEqual(price, priceLevel)){
         return true;
      }
      else {
         VerboseLog("Based on its logic, the strategy tried to place ", isSL ? "SL" : "PT", " at incorrect price. Open price: ", DoubleToString(openPrice), ", max. price allowed: ", DoubleToString(priceLevel), ", price used: ", DoubleToString(price), " (this is NOT an error)");
         return false;
      }
   }
   else {
      double priceLevel = openPrice + minDistance;
      
      if(price > priceLevel || sqDoublesAreEqual(price, priceLevel)){
         return true;
      }
      else {
         VerboseLog("Based on its logic, the strategy tried to place ", isSL ? "SL" : "PT", " at incorrect price. Open price: ", DoubleToString(openPrice), ", min. price allowed: ", DoubleToString(priceLevel), ", price used: ", DoubleToString(price), " (this is NOT an error)");
         return false;
      }
   }
}

//----------------------------------------------------------------------------

void sqResetGlobalVariablesForTicket(ulong ticket) {
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-OrderExpiration_"+IntegerToString(ticket), 0);    
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-ExitAfterXBars_"+IntegerToString(ticket), 0);
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-MoveSL2BE_"+IntegerToString(ticket), 0);
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-MoveSL2BEType_"+IntegerToString(ticket), 0);    
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-SL2BEAddPips_"+IntegerToString(ticket), 0);
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-TrailingStop_"+IntegerToString(ticket), 0);
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-TrailingStopType_"+IntegerToString(ticket), 0);
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-TSActivation_"+IntegerToString(ticket), 0);
}

//+------------------------------------------------------------------+

bool isLongOrder(ENUM_ORDER_TYPE orderType){
   return orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP;
}

//+------------------------------------------------------------------+

void closeAllPositions(){
   for (int i=PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      
      if(!checkMagicNumber(PositionGetInteger(POSITION_MAGIC))) continue;
      
      if(sqClosePositionAtMarket(ticket)){
         Print(StringFormat("Cannot close position with ticket %d", IntegerToString(ticket)));
      }
   }
} 

//+------------------------------------------------------------------+

bool closePosition(const ulong ticket, const ulong deviation = 100, const string comment = "", const int magicNo = -1) {
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   
   if(!PositionSelectByTicket(ticket)) return(false);
   
   string symbol = PositionGetString(POSITION_SYMBOL);

   MqlTick lastTick;
   getLastTick(symbol, lastTick);

   if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
      //--- prepare request for close BUY position
      mrequest.type = ORDER_TYPE_SELL;
      mrequest.price = NormalizeDouble(lastTick.bid, _Digits);
   }
   else {
      //--- prepare request for close SELL position
      mrequest.type = ORDER_TYPE_BUY;
      mrequest.price = NormalizeDouble(lastTick.ask, _Digits);
   }
   
   //--- setting request
   mrequest.action   = TRADE_ACTION_DEAL;
   mrequest.position = ticket;
   mrequest.symbol   = symbol;
   mrequest.volume   = PositionGetDouble(POSITION_VOLUME);
   mrequest.magic    = magicNo > 0 ? magicNo : PositionGetInteger(POSITION_MAGIC);
   mrequest.deviation = deviation; 
   mrequest.type_filling = forceFillingType ? preferredFillingType : GetFilling(symbol, preferredFillingType);          // Order execution type
   mrequest.comment = StringLen(comment) > 0 ? comment : PositionGetString(POSITION_COMMENT);
                             
   ResetLastError();         
   //--- close position    
   bool success = OrderSend(mrequest, mresult);
   
   // get the result code
   if(success && (mresult.retcode==10009 || mresult.retcode==10008)) //Request is completed or order placed
     {
      VerboseLog("A Buy order has been successfully placed with Ticket#:",IntegerToString(mresult.order),"!!");
      return true;
     }
   else
     {
      Alert("The Buy order request could not be completed -error:",GetLastError());
      return false;
     }
     
}

//+------------------------------------------------------------------+

bool closeOrder(long ticket){
    ZeroMemory(mrequest);
    ZeroMemory(mresult);
      
    mrequest.action = TRADE_ACTION_REMOVE;                  
    mrequest.order = ticket;                       
    
    return OrderSend(mrequest, mresult);
}

//+------------------------------------------------------------------+

bool OrderModify(ulong ticket, double stopLoss, double profitTarget){
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   
   if(!PositionSelectByTicket(ticket)){
      VerboseLog("Cannot modify SL/PT of position with Ticket#:", IntegerToString(ticket)," - Position not found!");
      return false;
   }
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   int stops_level = (int) SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      
      if(stopLoss > 0 && (bid - stopLoss <= stops_level * _Point)){
         VerboseLog("Cannot modify SL of position with Ticket#:", IntegerToString(ticket), " - SL (", DoubleToString(stopLoss), ") is too close to current price (", DoubleToString(bid), ")!");
         return false;
      }
      if(profitTarget > 0 && (profitTarget - bid <= stops_level * _Point)){
         VerboseLog("Cannot modify PT of position with Ticket#:", IntegerToString(ticket), " - PT (", DoubleToString(profitTarget), ") is too close to current price (", DoubleToString(bid), ")!");
         return false;
      }
   }
   else {
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      
      if(stopLoss > 0 && (stopLoss - ask <= stops_level * _Point)){
         VerboseLog("Cannot modify SL of position with Ticket#:", IntegerToString(ticket), " - SL (", DoubleToString(stopLoss), ") is too close to current price (", DoubleToString(ask), ")!");
         return false;
      }
      if(profitTarget > 0 && (ask - profitTarget <= stops_level * _Point)){
         VerboseLog("Cannot modify PT of position with Ticket#:", IntegerToString(ticket), " - PT (", DoubleToString(profitTarget), ") is too close to current price (", DoubleToString(ask), ")!");
         return false;
      }
   }
   
   //--- setting request
   mrequest.action = TRADE_ACTION_SLTP;
   mrequest.symbol = PositionGetString(POSITION_SYMBOL);
   mrequest.magic = PositionGetInteger(POSITION_MAGIC);
   mrequest.position = ticket;
   mrequest.sl = stopLoss != 0 ? sqFixMarketPrice(stopLoss, mrequest.symbol) : PositionGetDouble(POSITION_SL);
   mrequest.tp = profitTarget != 0 ? sqFixMarketPrice(profitTarget, mrequest.symbol) : PositionGetDouble(POSITION_TP);
   
   //--- action and return the result
   return OrderSend(mrequest, mresult);
}
         
//+------------------------------------------------------------------+
     
bool OrderModifyOpenPrice(ulong ticket, double openPrice){
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   
   if(PositionSelectByTicket(ticket)){
      VerboseLog("Cannot modify open price of order #", IntegerToString(ticket), " - it is an open position");
      return false;
   }
   
   //--- setting request
   mrequest.action = TRADE_ACTION_MODIFY;
   mrequest.order = ticket;
   mrequest.price = openPrice;
   
   //--- action and return the result
   return OrderSend(mrequest, mresult);
}
        
//+------------------------------------------------------------------+

bool getLastTick(string symbol, MqlTick &tick){
   if(!SymbolInfoTick(symbol, tick)) {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+

ENUM_ORDER_TYPE_FILLING GetFilling( const string Symb, const ENUM_ORDER_TYPE_FILLING Type = ORDER_FILLING_FOK ) {
   const ENUM_SYMBOL_TRADE_EXECUTION ExeMode = (ENUM_SYMBOL_TRADE_EXECUTION)::SymbolInfoInteger(Symb, SYMBOL_TRADE_EXEMODE);
   const int FillingMode = (int)::SymbolInfoInteger(Symb, SYMBOL_FILLING_MODE);
   
   if(FillingMode == 0 || (Type >= ORDER_FILLING_RETURN) || ((FillingMode & (Type + 1)) != Type + 1)) {
      if((ExeMode == SYMBOL_TRADE_EXECUTION_EXCHANGE) || (ExeMode == SYMBOL_TRADE_EXECUTION_INSTANT)) {
         return ORDER_FILLING_RETURN;
      } 
      else {
         if(FillingMode == SYMBOL_FILLING_IOC) {
            return ORDER_FILLING_IOC;
         } 
         else {
            return ORDER_FILLING_FOK;
         }
      }
   } 
   else {
      return Type;
   }
}

//+------------------------------------------------------------------+

double getDealCurrentProfit(long dealTicket) {
   long orderTicket = HistoryDealGetInteger(dealTicket, DEAL_ORDER);
   return getOrderCurrentProfit(orderTicket);
}

//+------------------------------------------------------------------+

double getDealCurrentPriceDifference(long dealTicket){
   long orderTicket = HistoryDealGetInteger(dealTicket, DEAL_ORDER);
   return getOrderCurrentPriceDifference(orderTicket);
}

//+------------------------------------------------------------------+

double getOrderCurrentProfit(long orderTicket){
   if(!OrderSelect(orderTicket)) return(0);
   
   ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
   string orderSymbol = OrderGetString(ORDER_SYMBOL);
   double orderVolume = OrderGetDouble(ORDER_VOLUME_INITIAL);
   double orderOpenPrice = OrderGetDouble(ORDER_PRICE_OPEN);
   double orderCurrentPrice = OrderGetDouble(ORDER_PRICE_CURRENT);
   
   double profit = 0;
   
   if(!OrderCalcProfit(orderType, orderSymbol, orderVolume, orderOpenPrice, orderCurrentPrice, profit)){
      return(0);
   }
   
   return profit;
}

//+------------------------------------------------------------------+

double getOrderCurrentPriceDifference(long orderTicket){
   if(!OrderSelect(orderTicket)) return(0);
   
   ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
   double orderOpenPrice = OrderGetDouble(ORDER_PRICE_OPEN);
   double orderCurrentPrice = OrderGetDouble(ORDER_PRICE_CURRENT);
   
   return orderType == ORDER_TYPE_BUY ? orderCurrentPrice - orderOpenPrice : orderOpenPrice - orderCurrentPrice;
}
  
//+------------------------------------------------------------------+
//| old SQ.mqh functions                                                 |
//+------------------------------------------------------------------+

double sqOpen(string symbol,int tf,int index){
   if(index < 0) return(-1);
   double Arr[];     
   string correctedSymbol = correctSymbol(symbol);
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   if(CopyOpen(correctedSymbol,timeframe, index, 1, Arr)>0) 
        return(NormalizeDouble(Arr[0], (int) SymbolInfoInteger(correctedSymbol, SYMBOL_DIGITS)));
   else return(-1);
}

//+------------------------------------------------------------------+

double sqHigh(string symbol,int tf,int index){
   if(index < 0) return(-1);
   double Arr[];           
   string correctedSymbol = correctSymbol(symbol);
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   if(CopyHigh(correctedSymbol,timeframe, index, 1, Arr)>0) 
        return(NormalizeDouble(Arr[0], (int) SymbolInfoInteger(correctedSymbol, SYMBOL_DIGITS)));
   else return(-1);
}

//+------------------------------------------------------------------+

double sqLow(string symbol,int tf,int index)
{
   if(index < 0) return(-1);
   double Arr[];      
   string correctedSymbol = correctSymbol(symbol);
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   if(CopyLow(correctedSymbol,timeframe, index, 1, Arr)>0)
        return(NormalizeDouble(Arr[0], (int) SymbolInfoInteger(correctedSymbol, SYMBOL_DIGITS)));
   else return(-1);
}

//+------------------------------------------------------------------+

double sqClose(string symbol,int tf,int index){
   if(index < 0) return(-1);
   double Arr[];
   string correctedSymbol = correctSymbol(symbol);
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   if(CopyClose(correctedSymbol,timeframe, index, 1, Arr)>0) 
        return(NormalizeDouble(Arr[0], (int) SymbolInfoInteger(correctedSymbol, SYMBOL_DIGITS)));
   else return(-1);
}

//+------------------------------------------------------------------+

datetime sqTime(string symbol,int tf,int index)
{
   if(index < 0) return(-1);
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   datetime Arr[];
   if(CopyTime(correctSymbol(symbol), timeframe, index, 1, Arr)>0)
        return(Arr[0]);
   else return(-1);
}

//+------------------------------------------------------------------+

long sqVolume(string symbol,int tf,int index)
{
   if(index < 0) return(-1);
   long Arr[];
   ENUM_TIMEFRAMES timeframe=TFMigrate(tf);
   if(CopyTickVolume(correctSymbol(symbol), timeframe, index, 1, Arr)>0)
        return(Arr[0]);
   else return(-1);
}

//+------------------------------------------------------------------+

double getOpen(int shift){
   return sqOpen(_Symbol, _Period, shift);
}

//+------------------------------------------------------------------+

double getHigh(int shift){
   return sqHigh(_Symbol, _Period, shift);
}

//+------------------------------------------------------------------+

double getLow(int shift){
   return sqLow(_Symbol, _Period, shift);
}

//+------------------------------------------------------------------+

double getClose(int shift){
   return sqClose(_Symbol, _Period, shift);
}

//+------------------------------------------------------------------+

datetime getTime(int shift){
   return sqTime(_Symbol, _Period, shift);
}

//+------------------------------------------------------------------+

int sqTimeHour(datetime date)
{
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.hour);
}

//+------------------------------------------------------------------+

int sqTimeMinute(datetime date)
{
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.min);
}  

//+------------------------------------------------------------------+

int sqTimeDay(datetime date){
   MqlDateTime tm;
   TimeToStruct(date, tm);
   return(tm.day);
}

//+------------------------------------------------------------------+

int sqTimeDayOfWeek(datetime date){
   MqlDateTime tm;
   TimeToStruct(date, tm);
   return(tm.day_of_week);
}  

//+------------------------------------------------------------------+

int sqTimeMonth(datetime date){
   MqlDateTime tm;
   TimeToStruct(date, tm);
   return(tm.mon);
}  

//+------------------------------------------------------------------+

int sqTimeDayOfYear(datetime date){
   MqlDateTime tm;
   TimeToStruct(date, tm);
   return(tm.day_of_year);
}

//+------------------------------------------------------------------+

ENUM_TIMEFRAMES TFMigrate(int tf)
  {
   switch(tf)
     {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);      
      default: return(PERIOD_CURRENT);
     }
}

//+------------------------------------------------------------------+

void sqCloseWorstPosition(string symbol, int magicNo, int direction, string comment) {
   double minPL = 100000000;
   ulong ticket = 0;
   
   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }
   
   for(int cc = PositionsTotal() - 1; cc >= 0; cc--) {
      ulong positionTicket = PositionGetTicket(cc);
   
      if(PositionSelectByTicket(positionTicket)) {
         double positionProfit = PositionGetDouble(POSITION_PROFIT);
         
         if(positionProfit < minPL) {
            // found order with worse profit
            minPL = positionProfit;
            ticket = positionTicket;
            Verbose("Worse position found, ticket: ", IntegerToString(ticket), ", PL: ", DoubleToString(minPL));
         }
      }
   }

   if(ticket > 0) {
      sqClosePositionAtMarket(ticket);
   }
}

//+------------------------------------------------------------------+

bool sqClosePositionAtMarket(ulong positionTicket) {
   Verbose("Closing order with ticket: ", IntegerToString(positionTicket));

   ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
   string positionSymbol = PositionGetString(POSITION_SYMBOL);

   if(!sqCheckConnected()) {
      return(false);
   }

   GetLastError(); // clear the global variable.
   int error = 0;
   int retries = 0;

   while (true) {
      if (IsTradeAllowed()) {
         if(closePosition(positionTicket, correctSlippage(sqMaxCloseSlippage, positionSymbol))) {
            Verbose("Order deleted successfuly");
            return(true);
         }
      }

      retries++;
      
      if(!sqProcessErrors(retries, GetLastError())) {
         return(false);
      }
   }
}
             
//----------------------------------------------------------------------------

int correctSlippage(int slippage, string symbol = NULL){
    if(slippage <= 0) return 100000;
    
    if(autoCorrectMaxSlippage){
       int realDigits = (int) SymbolInfoInteger(correctSymbol(symbol), SYMBOL_DIGITS);
       if(realDigits > 0 && realDigits != 2 && realDigits != 4) {
          return slippage * 10;
       }
    }
    
    return slippage;
}

//+------------------------------------------------------------------+

bool IsTradeAllowed(){
   return terminalInfo.IsTradeAllowed();
}

//+------------------------------------------------------------------+

bool sqCheckConnected() {
   if (!terminalInfo.IsConnected()) {
      Verbose("Not connected!");
      return(false);
   }
   if (IsStopped()) {
      Verbose("EA stopped!");
      return(false);
   }

   return(true);
}

//+------------------------------------------------------------------+

double sqGetAsk(string symbol) {
   symbol = correctSymbol(symbol);
   return(NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), _Digits));
}

//+------------------------------------------------------------------+

double sqGetBid(string symbol) {
   symbol = correctSymbol(symbol);
   return(NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), _Digits));
}

//+------------------------------------------------------------------+

bool sqProcessErrors(int retries, int error) {
   if (retries > sqMaxRetries) {
      Verbose("Maximum retries ", IntegerToString(sqMaxRetries), " reached. Error: ", IntegerToString(error), " : " + ErrorDescription(error));
      return(false);
   }
   
   if(error == TRADE_RETCODE_PRICE_CHANGED || error == TRADE_RETCODE_REQUOTE) {
      // continue immediately
      return(true);

   } else if(error == TRADE_RETCODE_CONNECTION || error == TRADE_RETCODE_INVALID_PRICE || error == TRADE_RETCODE_TIMEOUT || error == ERR_TRADE_SEND_FAILED
         /*error == ERR_OFF_QUOTES || error == ERR_BROKER_BUSY || error == ERR_TRADE_CONTEXT_BUSY*/)
   {
      Verbose("Retrying #", IntegerToString(retries),", Error: ", IntegerToString(error), " : " + ErrorDescription(error));
      sqSleep();
      return(true);

   } else {
      // too serious error
      Verbose("Non-retriable error. Error: ", IntegerToString(error), " : " + ErrorDescription(error));
      return(false);
   }
}

//+------------------------------------------------------------------+

void sqManageOrderExpirations(int magicNo) {
   int tempValue = 0;
   int barsOpen = 0;
   
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong orderTicket = OrderGetTicket(i);
      if(!OrderSelect(orderTicket)) continue;

      //check magic number       
      int orderMagicNumber = (int) OrderGetInteger(ORDER_MAGIC);
      if(orderMagicNumber != magicNo) continue;

      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
      datetime openTime = (datetime) OrderGetInteger(ORDER_TIME_SETUP);
   
      // Stop/Limit Order Expiration
      if(orderType != ORDER_TYPE_BUY && orderType != ORDER_TYPE_SELL) {
         // handle only pending orders
         tempValue = sqGetOrderExpiration(orderTicket);
         if(tempValue > 0) {
            barsOpen = sqGetOpenBarsForOrder(tempValue + 10, openTime);
            if(barsOpen >= tempValue) {
               Verbose("Order with ticket: ", IntegerToString(orderTicket), " expired");
               sqDeletePendingOrder(orderTicket);
            }
         }
      }
   }
}

//----------------------------------------------------------------------------

double sqIndicatorHighest(int period, int nthValue, string expression) {
    if(period > 1000) {
        Alert("Period used for sqIndicatorHighest function is too high. Max value is 1000");
        period = 1000;
   }
   
   if(nthValue < 0 || nthValue >= period) {
	   return(-1);
   }
   
   double indicatorValues[1000];
   int i;

   if(nthValue < 0 || nthValue >= period) {
      return(-1);
   }

   for(i=0; i<1000; i++) {
      indicatorValues[i] = -2147483647;
   }

   for(i=0; i<period; i++) {
      indicatorValues[i] = sqGetIndicatorValue(expression, i);
   }

   ArraySort(indicatorValues);      //ascending order

   return(indicatorValues[1000 - nthValue - 1]);
}

//----------------------------------------------------------------------------

double sqIndicatorLowest(int period, int nthValue, string expression) {
   if(period > 1000) {
        Alert("Period used for sqIndicatorLowest function is too high. Max value is 1000");
        period = 1000;
   }
   
   if(nthValue < 0 || nthValue >= period) {
	   return(-1);
   }
   
   double indicatorValues[1000];
   int i;

   if(nthValue < 0 || nthValue >= period) {
      return(-1);
   }
   
   for(i=0; i<1000; i++) {
      indicatorValues[i] = 2147483647;
   }

   for(i=0; i<period; i++) {
      indicatorValues[i] = sqGetIndicatorValue(expression, i);
   }

   ArraySort(indicatorValues);

   return(indicatorValues[nthValue]);
}

//----------------------------------------------------------------------------

double sqIndicatorAverage(int period, int maMethod, string expression) {
   double indicatorValues[10000];

   for(int i=0; i<period; i++) {
      indicatorValues[i] = sqGetIndicatorValue(expression, i);
   }
   
   double maValue = iMAOnArray(indicatorValues, period, period, 0, maMethod, 0);

   return(maValue);
}
  
//----------------------------------------------------------------------------

double iMAOnArray(double &array[], int total, int period, int ma_shift, int ma_method, int shift) {
   double buf[],arr[];
   
   if(total==0) total=ArraySize(array);
   if(total>0 && total<=period) return(0);
   if(shift>total-period-ma_shift) return(0);
   
   switch(ma_method)
     {
      case MODE_SMA :
        {
         total=ArrayCopy(arr,array,0,shift+ma_shift,period);
         if(ArrayResize(buf,total)<0) return(0);
         double sum=0;
         int    i,pos=total-1;
         for(i=1;i<period;i++,pos--)
            sum+=arr[pos];
         while(pos>=0)
           {
            sum+=arr[pos];
            buf[pos]=sum/period;
            sum-=arr[pos+period-1];
            pos--;
           }
         return(buf[0]);
        }
      case MODE_EMA :
        {
         if(ArrayResize(buf,total)<0) return(0);
         double pr=2.0/(period+1);
         int    pos=total-2;
         while(pos>=0)
           {
            if(pos==total-2) buf[pos+1]=array[pos+1];
            buf[pos]=array[pos]*pr+buf[pos+1]*(1-pr);
            pos--;
           }
         return(buf[shift+ma_shift]);
        }
      case MODE_SMMA :
        {
         if(ArrayResize(buf,total)<0) return(0);
         double sum=0;
         int    i,k,pos;
         pos=total-period;
         while(pos>=0)
           {
            if(pos==total-period)
              {
               for(i=0,k=pos;i<period;i++,k++)
                 {
                  sum+=array[k];
                  buf[k]=0;
                 }
              }
            else sum=buf[pos+1]*(period-1)+array[pos];
            buf[pos]=sum/period;
            pos--;
           }
         return(buf[shift+ma_shift]);
        }
      case MODE_LWMA :
        {
         if(ArrayResize(buf,total)<0) return(0);
         double sum=0.0,lsum=0.0;
         double price;
         int    i,weight=0,pos=total-1;
         for(i=1;i<=period;i++,pos--)
           {
            price=array[pos];
            sum+=price*i;
            lsum+=price;
            weight+=i;
           }
         pos++;
         i=pos+period;
         while(pos>=0)
           {
            buf[pos]=sum/weight;
            if(pos==0) break;
            pos--;
            i--;
            price=array[pos];
            sum=sum-lsum+price*period;
            lsum-=array[i];
            lsum+=price;
           }
         return(buf[shift+ma_shift]);
        }
      default: return(0);
     }
   return(0);
  }

//----------------------------------------------------------------------------

double sqIndicatorRecent(int barsBack, string indicatorIdentification) {
   return(sqGetIndicatorValue(indicatorIdentification, barsBack));
}

//+------------------------------------------------------------------+

string getVariablePrefix(){
   return IsTesting() ? "SQX(Test)" : "SQX";
}

//+------------------------------------------------------------------+

int sqGetOrderExpiration(ulong ticket) {
   return ((int) GlobalVariableGet(getVariablePrefix() + StrategyID + "-OrderExpiration_"+IntegerToString(ticket)));
}

//+------------------------------------------------------------------+

void sqSetOrderExpiration(ulong ticket, int bars) {
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-OrderExpiration_"+IntegerToString(ticket), bars);
}

//+------------------------------------------------------------------+

int sqGetExitAfterXBars(ulong ticket) {
   return ((int) GlobalVariableGet(getVariablePrefix() + StrategyID + "-ExitAfterXBars_"+IntegerToString(ticket)));
}

//+------------------------------------------------------------------+

void sqSetExitAfterXBars(ulong ticket, int bars) {
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-ExitAfterXBars_"+IntegerToString(ticket), bars);
}

//+------------------------------------------------------------------+

int sqGetMoveSL2BE(ulong ticket) {
   return ((int) GlobalVariableGet(getVariablePrefix() + StrategyID + "-MoveSL2BE_"+IntegerToString(ticket)));
}

//+------------------------------------------------------------------+

int sqGetMoveSL2BEType(ulong ticket) {
   return ((int) GlobalVariableGet(getVariablePrefix() + StrategyID + "-MoveSL2BEType_"+IntegerToString(ticket)));
}

//+------------------------------------------------------------------+

void sqSetMoveSL2BE(ulong ticket, string value, int type) {
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-MoveSL2BE_"+IntegerToString(ticket), sqStringHash(value));
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-MoveSL2BEType_"+IntegerToString(ticket), type);
}

//+------------------------------------------------------------------+

int sqGetSL2BEAddPips(ulong ticket) {
   return ((int) GlobalVariableGet(getVariablePrefix() + StrategyID + "-SL2BEAddPips_"+IntegerToString(ticket)));
}

//+------------------------------------------------------------------+

void sqSetSL2BEAddPips(ulong ticket, string value) {
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-SL2BEAddPips_"+IntegerToString(ticket), sqStringHash(value));
}


//+------------------------------------------------------------------+

int sqGetTrailingStop(ulong ticket) {
   return ((int) GlobalVariableGet(getVariablePrefix() + StrategyID + "-TrailingStop_"+IntegerToString(ticket)));
}

//+------------------------------------------------------------------+

int sqGetTrailingStopType(ulong ticket) {
   return ((int) GlobalVariableGet(getVariablePrefix() + StrategyID + "-TrailingStopType_"+IntegerToString(ticket)));
}

//+------------------------------------------------------------------+

void sqSetTrailingStop(ulong ticket, string value, int type) {
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-TrailingStop_"+IntegerToString(ticket), sqStringHash(value));
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-TrailingStopType_"+IntegerToString(ticket), type);
}

//+------------------------------------------------------------------+

int sqGetTSActivation(ulong positionTicket) {
   return ((int) GlobalVariableGet(getVariablePrefix() + StrategyID + "-TSActivation_"+IntegerToString(positionTicket)));
}

//+------------------------------------------------------------------+

void sqSetTSActivation(ulong ticket, string value) {
   GlobalVariableSet(getVariablePrefix() + StrategyID + "-TSActivation_"+IntegerToString(ticket), sqStringHash(value));
}

//+------------------------------------------------------------------+

int sqStringHash(string str){
   int i, h = 0, k = 0;
   for (i=0; i<StringLen(str); i++){
      k = StringGetCharacter(str, i);
      h = (h << 5) + h + k;
   }
   return(h);
}

//+------------------------------------------------------------------+

void sqClosePosition(double size, int magicNo, string symbol, int direction, string comment) {
   Verbose("Closing order with Magic Number: ", IntegerToString(magicNo), ", symbol: ", symbol, ", direction: ", IntegerToString(direction), ", comment: ", comment);

   if(!sqSelectPosition(magicNo, symbol, direction, comment)) {
      Verbose("Position cannot be found");
   } else {
      ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
      if(positionType == POSITION_TYPE_BUY || positionType == POSITION_TYPE_SELL) {
         sqClosePositionAtMarket(PositionGetInteger(POSITION_TICKET));
      } else {
         //sqDeletePendingOrder(OrderTicket());
      }
   }

   Verbose("Closing order finished ----------------");
}

//+------------------------------------------------------------------+
                   
void sqCloseFirstTrade(int magicNo, string symbol, int direction, string comment){
   ulong positionTicket = ULONG_MAX;
   ulong orderTicket = ULONG_MAX;
   
   if(sqSelectPosition(magicNo, symbol, direction, comment, false)) {
       positionTicket = PositionGetInteger(POSITION_TICKET);
   }
    
   if(sqSelectOrder(magicNo, symbol, direction, comment, false)) {
       orderTicket = OrderGetInteger(ORDER_TICKET);
   }
   
   if(positionTicket < orderTicket){
      sqClosePositionAtMarket(positionTicket);   
   }
   else if(orderTicket < positionTicket){
      closeOrder(orderTicket);
   }
}

//+------------------------------------------------------------------+

void sqClosePendingOrder(int magicNo, string symbol, int direction, string comment) {
   Verbose("Closing pending order with Magic Number: ", IntegerToString(magicNo), ", symbol: ", symbol, ", direction: ", IntegerToString(direction), ", comment: ", comment);

   if(!sqSelectOrder(magicNo, symbol, direction, comment, false)) {
      Verbose("Order cannot be found");
   } else {
      sqDeletePendingOrder(OrderGetInteger(ORDER_TICKET));
   }

   Verbose("Closing pending order finished ----------------");
}

//+------------------------------------------------------------------+

void sqCloseAllPendingOrders(int magicNo, string symbol, int direction, string comment) {
   Verbose("Closing pending orders with Magic Number: ", IntegerToString(magicNo), ", symbol: ", symbol, ", direction: ", IntegerToString(direction), ", comment: ", comment);

   while(sqSelectOrder(magicNo, symbol, direction, comment, false)) {
      sqDeletePendingOrder(OrderGetInteger(ORDER_TICKET));
   }

   Verbose("Closing pending orders finished ----------------");
}

//+------------------------------------------------------------------+

int sqGetOpenBarsForOrder(int expBarsPeriod, datetime openTime) {
   datetime Time[];
   int length = CopyTime(_Symbol, _Period, 0, expBarsPeriod+10, Time);
   
   if(length <= 0) return 0;
   
   int numberOfBars = 0;
   for(int i=length-1; i>=0; i--) {
      if(openTime < Time[i]) {
         numberOfBars++;
      }
      else break;
   }

   return(numberOfBars);
}

//+------------------------------------------------------------------+

void Verbose(string st1, string st2="", string s3="", string s4="", string s5="", string s6="", string s7="", string s8="", string s9="", string s10="", string s11="", string s12="", string s13="", string s14="" ) {
   if(sqVerboseMode == 1) {
      // log to standard log
      Print("---VERBOSE--- ", TimeToString(TimeCurrent()), " ", st1, st2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14);

   } else if(sqVerboseMode == 2) {
      // log to special file
      int handle = FileOpen("EAW_VerboseLog.txt", FILE_READ | FILE_WRITE);
      if(handle>0) {
         FileSeek(handle,0,SEEK_END);
         FileWrite(handle, TimeToString(TimeCurrent()), " VERBOSE: ", st1, st2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12);
         FileClose(handle);
      }
   }
}

//+------------------------------------------------------------------+

void VerboseLog(string s1, string s2="", string s3="", string s4="", string s5="", string s6="", string s7="", string s8="", string s9="", string s10="", string s11="", string s12="" ) {
   if(sqVerboseMode != 1) {
      Log(s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12);
   }

   Verbose(s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12);
}

//+------------------------------------------------------------------+

void Log(string s1, string s2="", string s3="", string s4="", string s5="", string s6="", string s7="", string s8="", string s9="", string s10="", string s11="", string s12="" ) {
   Print(TimeToString(TimeCurrent()), " ", s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12);
}

//+------------------------------------------------------------------+

void sqLog(string st1, string st2="", string s3="", string s4="", string s5="", string s6="", string s7="", string s8="", string s9="", string s10="", string s11="", string s12="" ) {
   Print(TimeToString(TimeCurrent()), " ", st1, st2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12);
}


//+------------------------------------------------------------------+

void sqLogToFile(string fileName, string st1, string st2="", string s3="", string s4="", string s5="", string s6="", string s7="", string s8="", string s9="", string s10="", string s11="", string s12="" ) {
   int handle = FileOpen(fileName, FILE_READ | FILE_WRITE, ";");
   if(handle>0) {
      FileSeek(handle,0,SEEK_END);
      FileWrite(handle, TimeToString(TimeCurrent()), " ", st1, st2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12);
      FileClose(handle);
   }
}

//+------------------------------------------------------------------+

bool sqSelectPosition(int magicNo, string symbol, int direction, string comment, bool goFromNewest=true) {
   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }

   if(goFromNewest){
      for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
         ulong ticket = PositionGetTicket(cc);
    
         if (PositionSelectByTicket(ticket) && positionFits(ticket, symbol, magicNo, direction, comment)) {
            return(true);
         }
      }
   }
   else {
      for (int cc = 0; cc < PositionsTotal(); cc++) {
         ulong ticket = PositionGetTicket(cc);
    
         if (PositionSelectByTicket(ticket) && positionFits(ticket, symbol, magicNo, direction, comment)) {
            return(true);
         }
      }
   }
   
   return(false);
}        

//+------------------------------------------------------------------+

bool sqSelectOrder(int magicNo, string symbol, int direction, string comment, bool goFromNewest=true) {
  if(orderSelectTimeout > 0){
      Sleep(orderSelectTimeout);
  }
  
  if(goFromNewest){
      for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
        ulong ticket = OrderGetTicket(cc);
   
        if (!isExitLevelOrder(ticket) && OrderSelect(ticket) && orderFits(ticket, symbol, magicNo, direction, comment)) {
           return(true);
        }
     }
   }
   else {
      for (int cc = 0; cc < OrdersTotal(); cc++) {
         ulong ticket = OrderGetTicket(cc);
    
         if (!isExitLevelOrder(ticket) && OrderSelect(ticket) && orderFits(ticket, symbol, magicNo, direction, comment)) {
            return(true);
         }
      }
   }

   return(false);
}

//+------------------------------------------------------------------+

bool sqSelectPendingOrderByDir(int magicNo, string symbol, int direction, string comment) {
    if(orderSelectTimeout > 0){
        Sleep(orderSelectTimeout);
    }
    
    for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
        ulong ticket = OrderGetTicket(cc);
   
        if (OrderSelect(ticket) && orderFits(ticket, symbol, magicNo, direction, comment)) {
           return(true);
        }
    }
    
    return(false);
}

//+------------------------------------------------------------------+

bool positionFits(ulong ticket, string symbol, int magicNo, int direction, string comment){
   ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);  
   string positionSymbol = PositionGetString(POSITION_SYMBOL);         
   string positionComment = PositionGetString(POSITION_COMMENT);    
   int positionMagicNumber = (int) PositionGetInteger(POSITION_MAGIC);
   
   if(direction != 0) {
      if(direction > 0 && positionType != POSITION_TYPE_BUY) return(false);
      if(direction < 0 && positionType != POSITION_TYPE_SELL) return(false);
   }

   if(magicNo != 0) {
      if(!checkMagicNumber(positionMagicNumber) || positionMagicNumber != magicNo) return(false);
   }

   if(symbol != "Any" && positionSymbol != correctSymbol(symbol)) return(false);

   if(comment != "") {
      if(StringFind(positionComment, comment) == -1) return(false);
   }
   
   return(true);
}

//+------------------------------------------------------------------+

bool dealFits(ulong ticket, string symbol, int magicNo, int direction, string comment){
   ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE) HistoryDealGetInteger(ticket, DEAL_TYPE);
   string dealSymbol = HistoryDealGetString(ticket, DEAL_SYMBOL);      
   string dealComment = HistoryDealGetString(ticket, DEAL_COMMENT);   
   int dealMagicNumber = (int) HistoryDealGetInteger(ticket, DEAL_MAGIC);
   
   if(direction != 0) {
      if(direction > 0 && dealType != DEAL_TYPE_BUY) return(false);
      if(direction < 0 && dealType != DEAL_TYPE_SELL) return(false);
   }

   if(magicNo != 0) {
      if(!checkMagicNumber(dealMagicNumber) || dealMagicNumber != magicNo) return(false);
   }

   if(symbol != "Any" && dealSymbol != correctSymbol(symbol)) return(false);

   if(comment != "") {
      if(StringFind(dealComment, comment) == -1) return(false);
   }
   
   return(true);
}

//+------------------------------------------------------------------+

bool orderFits(ulong ticket, string symbol, int magicNo, int direction, string comment){
   ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
   int orderDirection = getOrderDirection(orderType);
   string orderSymbol = OrderGetString(ORDER_SYMBOL);      
   string orderComment = OrderGetString(ORDER_COMMENT);   
   int orderMagicNumber = (int) OrderGetInteger(ORDER_MAGIC);
   
   if(direction != 0) {
      if(direction != orderDirection) return(false);
   }

   if(magicNo != 0) {
      if(!checkMagicNumber(orderMagicNumber) || orderMagicNumber != magicNo) return(false);
   }

   if(symbol != "Any" && orderSymbol != correctSymbol(symbol)) return(false);

   if(comment != "") {
      if(StringFind(orderComment, comment) == -1) return(false);
   }
   
   return(true);
}

//+------------------------------------------------------------------+

int getOrderDirection(ENUM_ORDER_TYPE orderType){
   if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_BUY_STOP_LIMIT){
      return 1;
   }
   else {
      return -1;
   }
}

//+------------------------------------------------------------------+

void sqCloseAllPositions(string symbol, int magicNo, int direction, string comment) {
   int count = 100; // maximum number of positions to close
   ulong lastTicket = -1;

   //close open positions
   while(count > 0) {
      count--;
      if(!sqSelectPosition(magicNo, symbol, direction, comment)) {
         // no position found
         break;
      }
      
      ulong positionTicket = PositionGetInteger(POSITION_TICKET);
      
      if(lastTicket == positionTicket) {
         // trying to close the same position one more time, there must be some error
         break;
      }
      
      lastTicket = positionTicket;
      
      sqClosePositionAtMarket(positionTicket);
   }
   
   count = 100; 
   lastTicket = -1;
   
   //close pending orders
   while(count > 0) {
      count--;
      if(!sqSelectOrder(magicNo, symbol, direction, comment)) {
         // no order found
         break;
      }
      
      ulong orderTicket = OrderGetInteger(ORDER_TICKET);
      
      if(orderTicket == lastTicket) {
         // trying to close the same order one more time, there must be some error
         break;
      }
      
      lastTicket = orderTicket;
      
      closeOrder(orderTicket);
   }
}

//+------------------------------------------------------------------+

void sqCloseBestPosition(string symbol, int magicNo, int direction, string comment) {
   double maxPL = -100000000;
   ulong ticket = 0;
   
   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }
   
   for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
      ulong positionTicket = PositionGetTicket(cc);
 
      if(PositionSelectByTicket(positionTicket) && positionFits(positionTicket, symbol, magicNo, direction, comment)) {
          double positionProfit = PositionGetDouble(POSITION_PROFIT); 
           
          if(positionProfit > maxPL) {
            // found order with better profit
            maxPL = positionProfit;
            ticket = positionTicket;
            Verbose("Better position found, ticket: ", IntegerToString(positionTicket),", PL: ", DoubleToString(maxPL));
          }
      }
   }

   if(ticket > 0) {
      PositionSelectByTicket(ticket);
      sqClosePositionAtMarket(ticket);
   }
}

//+------------------------------------------------------------------+

int sqGetMarketPosition(string symbol, int magicNo, string comment) {
   if(sqSelectPosition(magicNo, symbol, 0, comment, false)) {
      ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
      if(positionType == POSITION_TYPE_BUY) {
         return(1);
      } else {
         return(-1);
      }
   }
   return(0);
}

//+------------------------------------------------------------------+

bool sqMarketPositionIsShort(int magicNo, string symbol, string comment){
   return sqSelectPosition(magicNo, symbol, -1, comment, false);
}    

//+------------------------------------------------------------------+

bool sqMarketPositionIsNotShort(int magicNo, string symbol, string comment){
   if(sqSelectOrder(magicNo, symbol, -1, comment, false)) {
      return false; 	
	}
	else return true;
} 

//+------------------------------------------------------------------+

bool sqMarketPositionIsLong(int magicNo, string symbol, string comment){
   return sqSelectPosition(magicNo, symbol, 1, comment, false);
}     

//+------------------------------------------------------------------+

bool sqMarketPositionIsNotLong(int magicNo, string symbol, string comment){
   if(sqSelectOrder(magicNo, symbol, 1, comment, false)) {
      return false; 	
	}
	else return true;
} 

//+------------------------------------------------------------------+

bool sqMarketPositionIsFlat(int magicNo, string symbol, string comment){
   return sqGetMarketPosition(symbol, magicNo, comment) == 0;
}

//+------------------------------------------------------------------+

double sqGetPositionOpenPrice(string symbol, int magicNo, int direction, string comment) {
   if(sqSelectPosition(magicNo, symbol, direction, comment, false)) {
      return(PositionGetDouble(POSITION_PRICE_OPEN));
   }
   return(-1);
}

//+------------------------------------------------------------------+

double sqGetOrderStopLoss(string symbol, int magicNo, int direction, string comment) {
   if(sqSelectPosition(magicNo, symbol, direction, comment, false)) {
      return(PositionGetDouble(POSITION_SL));
   }
   return(-1);
}

//+------------------------------------------------------------------+

double sqGetOrderProfitTarget(string symbol, int magicNo, int direction, string comment) {
   if(sqSelectPosition(magicNo, symbol, direction, comment, false)) {
      return(PositionGetDouble(POSITION_TP));
   }
   return(-1);
}

//+------------------------------------------------------------------+

double sqGetMarketPositionSize(string symbol, int magicNo, int direction, string comment) {
   double lots = 0;
   
   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }
   
   for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
      ulong positionTicket = PositionGetTicket(cc);
 
      if(PositionSelectByTicket(positionTicket) && positionFits(positionTicket, symbol, magicNo, direction, comment)) {
         lots += PositionGetDouble(POSITION_VOLUME);
      }
   }

   return(lots);
}

//+------------------------------------------------------------------+

double sqGetOpenPL(string symbol, int magicNo, int direction, string comment) {
   double pl = 0;
   
   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }
   
   for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
      ulong positionTicket = PositionGetTicket(cc);
 
      if(PositionSelectByTicket(positionTicket) && positionFits(positionTicket, symbol, magicNo, direction, comment)) {
         pl += PositionGetDouble(POSITION_PROFIT);
      }
   }

   return(pl);
}

//+------------------------------------------------------------------+

double sqGetOpenPLInPips(string symbol, int magicNo, int direction, string comment) {
   double pips = 0;
   
   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }
   
   for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
      ulong positionTicket = PositionGetTicket(cc);
 
      if(PositionSelectByTicket(positionTicket) && positionFits(positionTicket, symbol, magicNo, direction, comment)) {
         ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         string positionSymbol = PositionGetString(POSITION_SYMBOL);
         double ticksize = calculatePointCoef(positionSymbol);
         
         MqlTick lastTick;
         if(!getLastTick(positionSymbol, lastTick)){
            Print("Error: Cannot get latest tick of symbol '" + positionSymbol + "'!");
            continue;
         }
         
         if(positionType == POSITION_TYPE_BUY){
            pips += (lastTick.bid - positionOpenPrice) / ticksize;
         }
         else {
            pips += (positionOpenPrice - lastTick.ask) / ticksize;
         }
      }
   }
   
   return(pips);
}

//+------------------------------------------------------------------+

double sqGetClosedPLInMoney(string symbol, int magicNo, int direction, string comment, int shift) {
   int index = 0;
   
   HistorySelect(startTime, getTime(0));

   for(int i=HistoryDealsTotal(); i>=0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      
      if(dealFits(ticket, symbol, magicNo, direction, comment)) {
         if(index == shift) {
            return(HistoryDealGetDouble(ticket, DEAL_PROFIT));
         }

         index++;
      }
   }

   return(0);
}

//+------------------------------------------------------------------+

int sqGetMarketPositionCount(string symbol, int magicNo, int direction, string comment) {
   int count = 0;
   
   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }
   
   for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
      ulong positionTicket = PositionGetTicket(cc);
   
      if(PositionSelectByTicket(positionTicket) && positionFits(positionTicket, symbol, magicNo, direction, comment)) {
         count++;
      }
   }

   return(count);
}

//+------------------------------------------------------------------+

int sqGetBarsSinceOpen(string symbol, int magicNo, int direction, string comment) {
   datetime openTime = 0;
   
   if(sqSelectOrder(magicNo, symbol, direction, comment, false)){
      openTime = (datetime) OrderGetInteger(ORDER_TIME_SETUP);
   }
   
   if(sqSelectPosition(magicNo, symbol, direction, comment)) {
      datetime positionOpenTime = (datetime) PositionGetInteger(POSITION_TIME);
      
      if(positionOpenTime > openTime){
          openTime = positionOpenTime;
      }
   }
   
   return openTime > 0 ? sqGetOpenBarsForOrder(1000, openTime) : -1;
}

//+------------------------------------------------------------------+

int sqGetBarsSinceClose(string symbol, int magicNo, int direction, string comment) {
   ulong ticket = sqSelectOutDeal(magicNo, symbol, direction, comment);
   if(ticket > 0) {
      datetime clTime = (datetime) HistoryDealGetInteger(ticket, DEAL_TIME);
      
      datetime Time[];
      int length = CopyTime(_Symbol, _Period, 0, 10000, Time);
      if(length <= 0) return 0;
      
      ArraySetAsSeries(Time, true);
      
      int numberOfBars = 0;
      for(int i=0; i<length; i++) {
         if(clTime < Time[i]) {
            numberOfBars++;
         }
         else break;
      }

      return(numberOfBars);
   }

   return(-1);
}


//+------------------------------------------------------------------+

int sqGetLastOrderType(string symbol, int magicNo, string comment) {
   ulong ticket = sqSelectDeal(magicNo, symbol, 0, comment);
   if(ticket > 0) {
      ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE) HistoryDealGetInteger(ticket, DEAL_TYPE);
      
      if(dealType == DEAL_TYPE_BUY) {
         return(1);
      } else {
         return(-1);
      }
   }

   return(0);
}

//+------------------------------------------------------------------+

ulong sqSelectDeal(int magicNo, string symbol, int direction, string comment) {
   HistorySelect(startTime, TimeCurrent());
                                                                                                                           
   for(int i=HistoryDealsTotal() - 1; i>=0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      
      if (dealFits(ticket, symbol, magicNo, direction, comment)) {
         return(ticket);
      }
   }

   return(0);
}

//+------------------------------------------------------------------+

ulong sqSelectOutDeal(int magicNo, string symbol, int direction, string comment) {
   HistorySelect(startTime, TimeCurrent());

   for(int i=HistoryDealsTotal() - 1; i>=0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      
      if (dealFits(ticket, symbol, magicNo, direction, comment) && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         return(ticket);
      }
   }

   return(0);
}

//+------------------------------------------------------------------+

double sqConvertToPips(string symbol, double value) {
   if(symbol == "NULL" || symbol == "Current") {
      return(value / gPointCoef);
   }

   // recognize point coeficient         
   double ticksize = sqGetMarketTickSize(symbol);
   if(ticksize < 0){
      ticksize = calculatePointCoef(correctSymbol(symbol));
   }

   return(value / ticksize);
}

//+------------------------------------------------------------------+

bool sqSelectPendingOrderByType(int magicNo, string symbol, int direction, string comment) {
   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }
   
   for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
      ulong ticket = OrderGetTicket(cc);
      
      if (OrderSelect(ticket)) {
         ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
         int orderDirection = sqGetDirectionFromOrderType(orderType);
         string orderSymbol = OrderGetString(ORDER_SYMBOL);         
         string orderComment = OrderGetString(ORDER_COMMENT);
         int orderMagicNumber = (int) OrderGetInteger(ORDER_MAGIC);
         
         if(direction != 0) {
            if(orderDirection != direction) continue;
         }

         if(magicNo > 0) {
            if(orderMagicNumber != magicNo) continue;
         }
         else if(!checkMagicNumber(orderMagicNumber)) continue;
        
         if(symbol != "Any") {
            if(orderSymbol != correctSymbol(symbol)) continue;
         }
   
         if(comment != "" && comment != NULL) {
           if(StringFind(orderComment, comment) == -1) continue;
          }

         // otherwise we found the order
         return(true);
      }
   }

   return(false);
}

//+------------------------------------------------------------------+

bool sqDeletePendingOrder(ulong ticket) {
   Verbose(" Deleting pending order, ticket: " + IntegerToString(ticket));

   ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);

   if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL) {
      Verbose("Trying to delete non-pending order");
      return(false);
   }
   if(!sqCheckConnected()) {
      return(false);
   }

   GetLastError(); // clear the global variable.
   int error = 0;
   int retries = 0;
   bool result;

   while (true) {
      if (IsTradeAllowed()) {
         result = OrderDelete(ticket);                                  
         if(result) {
            Verbose("Order deleted successfuly");
            return(true);
         }
      }

      retries++;
      if(!sqProcessErrors(retries, GetLastError())) {
         return(false);
      }
   }
}

//+------------------------------------------------------------------+

bool OrderDelete(ulong ticket){
   ZeroMemory(mrequest);      
   ZeroMemory(mresult);
   
   mrequest.action = TRADE_ACTION_REMOVE;
   mrequest.magic = magicNumber;
   mrequest.order = ticket;
   //--- action and return the result
   return(OrderSend(mrequest, mresult));
}

//+------------------------------------------------------------------+

bool IsTesting(){
   return (bool) MQLInfoInteger(MQL_TESTER);
}

//+------------------------------------------------------------------+

int sleepPeriod = 500; // 0.5 s
int maxSleepPeriod = 20000; // 20 s.

void sqSleep() {
   if(IsTesting()) return;

   Sleep(sleepPeriod);

   int periods = maxSleepPeriod / sleepPeriod;

   for(int i=0; i<periods; i++) {
      if (MathRand() > 16383) {
         // 50% chance of quitting
         break;
      }

      Sleep(sleepPeriod);
   }
}

//+------------------------------------------------------------------+

int sqGetDirectionFromOrderType(int orderType) {
   if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_BUY_LIMIT) {
      return(1);
   } else {
      return(-1);
   }
}

//+------------------------------------------------------------------+

bool sqIsPendingOrder(int orderType) {
   if(orderType != ORDER_TYPE_BUY && orderType != ORDER_TYPE_SELL) {
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+

string sqGetOrderTypeAsString(int type) {
   switch(type) {
      case ORDER_TYPE_BUY: return("Buy");
      case ORDER_TYPE_SELL: return("Sell");
      case ORDER_TYPE_BUY_LIMIT: return("Buy Limit");
      case ORDER_TYPE_BUY_STOP: return("Buy Stop");
      case ORDER_TYPE_SELL_LIMIT: return("Sell Limit");
      case ORDER_TYPE_SELL_STOP: return("Sell Stop");
   }

   return("Unknown");
}

//+------------------------------------------------------------------+

void sqInitInfoPanel() {
      ObjectCreate(ChartID(), "line1", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), "line1", OBJPROP_CORNER, sqLabelCorner);
      ObjectSetInteger(ChartID(), "line1", OBJPROP_YDISTANCE, sqOffsetVertical + 0);
      ObjectSetInteger(ChartID(), "line1", OBJPROP_XDISTANCE, sqOffsetHorizontal);
      setupLabel("line1", sqStrategyName, "Tahoma", 9);

      ObjectCreate(ChartID(), "linec", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), "linec", OBJPROP_CORNER, sqLabelCorner);
      ObjectSetInteger(ChartID(), "linec", OBJPROP_YDISTANCE, sqOffsetVertical + 16 );
      ObjectSetInteger(ChartID(), "linec", OBJPROP_XDISTANCE, sqOffsetHorizontal);
      setupLabel("linec", "Created By: SQX");

      ObjectCreate(ChartID(), "line2", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), "line2", OBJPROP_CORNER, sqLabelCorner);
      ObjectSetInteger(ChartID(), "line2", OBJPROP_YDISTANCE, sqOffsetVertical + 28);
      ObjectSetInteger(ChartID(), "line2", OBJPROP_XDISTANCE, sqOffsetHorizontal);
      setupLabel("line2", "------------------------------------------");

      ObjectCreate(ChartID(), "lines", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), "lines", OBJPROP_CORNER, sqLabelCorner);
      ObjectSetInteger(ChartID(), "lines", OBJPROP_YDISTANCE, sqOffsetVertical + 44);
      ObjectSetInteger(ChartID(), "lines", OBJPROP_XDISTANCE, sqOffsetHorizontal);
      setupLabel("lines", "Last Signal:  -", "Tahoma", 9);

      ObjectCreate(ChartID(), "lineopl", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), "lineopl", OBJPROP_CORNER, sqLabelCorner);
      ObjectSetInteger(ChartID(), "lineopl", OBJPROP_YDISTANCE, sqOffsetVertical + 60);
      ObjectSetInteger(ChartID(), "lineopl", OBJPROP_XDISTANCE, sqOffsetHorizontal);
      setupLabel("lineopl", "Open P/L: -");

      ObjectCreate(ChartID(), "linea", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), "linea", OBJPROP_CORNER, sqLabelCorner);
      ObjectSetInteger(ChartID(), "linea", OBJPROP_YDISTANCE, sqOffsetVertical + 76);
      ObjectSetInteger(ChartID(), "linea", OBJPROP_XDISTANCE, sqOffsetHorizontal);
      setupLabel("linea", "Account Balance: -");

      ObjectCreate(ChartID(), "lineto", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), "lineto", OBJPROP_CORNER, sqLabelCorner);
      ObjectSetInteger(ChartID(), "lineto", OBJPROP_YDISTANCE, sqOffsetVertical + 92);
      ObjectSetInteger(ChartID(), "lineto", OBJPROP_XDISTANCE, sqOffsetHorizontal);
      setupLabel("lineto", "Total Profit/Losses so far: -/-");

      ObjectCreate(ChartID(), "linetp", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), "linetp", OBJPROP_CORNER, sqLabelCorner);
      ObjectSetInteger(ChartID(), "linetp", OBJPROP_YDISTANCE, sqOffsetVertical + 108);
      ObjectSetInteger(ChartID(), "linetp", OBJPROP_XDISTANCE, sqOffsetHorizontal);
      setupLabel("linetp", "Total P/L so far: -");
}

//+------------------------------------------------------------------+

void sqDeinitInfoPanel() {
   ObjectDelete(ChartID(), "line1");
   ObjectDelete(ChartID(), "linec");
   ObjectDelete(ChartID(), "line2");
   ObjectDelete(ChartID(), "lines");
   ObjectDelete(ChartID(), "lineopl");
   ObjectDelete(ChartID(), "linea");
   ObjectDelete(ChartID(), "lineto");
   ObjectDelete(ChartID(), "linetp");
}

//+------------------------------------------------------------------+

void sqTextFillOpens() {
   setupLabel("lineopl", "Open P/L: "+DoubleToString(sqGetOpenPLInMoney(0), 2));
   setupLabel("linea", "Account Balance: "+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
}

//+------------------------------------------------------------------+

void setupLabel(string objectName, string text, const string font = "Tahoma", const int fontSize = 8, const color objColor = NULL){
   color clr = objColor == NULL ? sqLabelColor : objColor;
   
   ObjectSetString(ChartID(), objectName, OBJPROP_TEXT, text);
   ObjectSetString(ChartID(), objectName, OBJPROP_FONT, font);
   ObjectSetInteger(ChartID(), objectName, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(ChartID(), objectName, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+

void sqTextFillTotals() {
   int maxTradesPL = 100;
   int maxTradesTotalPL = 1000;
   
   int count = 0;
   int profits = 0;
   int losses = 0;
   double pl = 0;
   
   HistorySelect(startTime, getTime(0));

   for(int i=HistoryDealsTotal(); i>=0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      
      if (HistoryDealGetString(ticket, DEAL_SYMBOL) == Symbol() && HistoryDealGetInteger(ticket,DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         int magic = (int) HistoryDealGetInteger(ticket, DEAL_MAGIC);
         
         if(checkMagicNumber(magic)) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;

            pl = pl + HistoryDealGetDouble(ticket, DEAL_PROFIT);

            if(count >= maxTradesTotalPL) break;
            if(count >= maxTradesPL) continue;
            
            if(HistoryDealGetDouble(ticket, DEAL_PROFIT) > 0) {
               profits++;
            }
            else if(HistoryDealGetDouble(ticket, DEAL_PROFIT) < 0) {
               losses++;
            }
         }
      }
   }

   setupLabel("lineto", "Total profits/losses so far: " + IntegerToString(profits) + "/" + IntegerToString(losses));
   setupLabel("linetp", "Total P/L so far: "+DoubleToString(pl, 2));
}

//+------------------------------------------------------------------+

double sqGetOpenPLInMoney(int orderMagicNumber) {
   double pl = 0;

   if(orderSelectTimeout > 0){
       Sleep(orderSelectTimeout);
   }
   
   for(int i=PositionsTotal(); i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      
      if(PositionSelectByTicket(ticket)){ 
         int magic = (int) PositionGetInteger(POSITION_MAGIC);
         double profit = PositionGetDouble(POSITION_PROFIT);
         
         if(orderMagicNumber != 0 && magic != orderMagicNumber) continue;
         
         pl += profit;
      }
   }

   return(pl);
}

//+------------------------------------------------------------------+

int sqGetTotalProfits(int orderMagicNumber, int numberOfLastOrders) {
   int count = 0;
   int profits = 0;

   HistorySelect(startTime, getTime(0));

   for(int i=HistoryDealsTotal(); i>=0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      
      if (HistoryDealGetString(ticket, DEAL_SYMBOL) == Symbol() && HistoryDealGetInteger(ticket,DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         int magic = (int) HistoryDealGetInteger(ticket, DEAL_MAGIC);
         
         if((orderMagicNumber == 0 && checkMagicNumber(orderMagicNumber))|| magic == orderMagicNumber) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;

            if(HistoryDealGetDouble(ticket, DEAL_PROFIT) > 0) {
               profits++;
            }

            if(count >= numberOfLastOrders) break;
         }
      }
   }

   return(profits);
}

//+------------------------------------------------------------------+

int sqGetTotalLosses(int orderMagicNumber, int numberOfLastOrders) {
   int count = 0;
   int losses = 0;
   
   HistorySelect(startTime, getTime(0));

   for(int i=HistoryDealsTotal(); i>=0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      
      if (HistoryDealGetString(ticket, DEAL_SYMBOL) == Symbol() && HistoryDealGetInteger(ticket,DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         int magic = (int) HistoryDealGetInteger(ticket, DEAL_MAGIC);
         
         if((orderMagicNumber == 0 && checkMagicNumber(orderMagicNumber)) || magic == orderMagicNumber) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;
            
            if(HistoryDealGetDouble(ticket, DEAL_PROFIT) < 0) {
               losses++;
            }

            if(count >= numberOfLastOrders) break;
         }
      }
   }

   return(losses);
}


//+------------------------------------------------------------------+

double sqGetTotalClosedPLInMoney(int orderMagicNumber, int numberOfLastOrders) {
   double pl = 0;
   int count = 0;
   
   HistorySelect(startTime, getTime(0));

   for(int i=HistoryDealsTotal(); i>=0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      
      if (HistoryDealGetString(ticket, DEAL_SYMBOL) == Symbol() && HistoryDealGetInteger(ticket,DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         int magic = (int) HistoryDealGetInteger(ticket, DEAL_MAGIC);
         
         if((orderMagicNumber == 0 && checkMagicNumber(orderMagicNumber)) || magic == orderMagicNumber) {
            // return the P/L of last order or the P/L of last order with given Magic Number
            
            count++;
            pl = pl + HistoryDealGetDouble(ticket, DEAL_PROFIT);

            if(count >= numberOfLastOrders) break;
         }
      }
   }
   
   return(pl);
}

//+------------------------------------------------------------------+

double sqGetSLLevel(string symbol, int orderType, double price, int valueInPips, double value) {
   return(sqGetSLPTLevel(-1.0, symbol, orderType, price, valueInPips, value));
}

//+------------------------------------------------------------------+

double sqGetPTLevel(string symbol, int orderType, double price, int valueInPips, double value) {
   return(sqGetSLPTLevel(1.0, symbol, orderType, price, valueInPips, value));
}

//+------------------------------------------------------------------+

/**
* valueType: 1 - pips, 2 - real pips (ATR range), 3 - price level
*/
double sqGetSLPTLevel(double SLorPT, string symbol, int orderType, double price, int valueType, double value) {
   string correctedSymbol = correctSymbol(symbol);
   double pointCoef = sqGetPointCoef(symbol);

   if(valueType == 1) {
      // convert from pips to real points
      value = sqConvertToRealPips(correctedSymbol, value);
   }
   
   if(price == 0) {
      // price can be zero for market order
      if(orderType == ORDER_TYPE_BUY) {
         price = sqGetAsk(correctedSymbol);
      } else {
         price = sqGetBid(correctedSymbol);
      }
   }
   
   double slptValue = value;
   
   if(valueType != 3) {
      if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_BUY_LIMIT) {
         slptValue = price + (SLorPT * value);
      } else {
         slptValue = price - (SLorPT * value);
      }
   }

   // check that SL / PT is within predefined boundaries
   double minSLPTValue, maxSLPTValue;
   
   if(SLorPT < 0) {
      // it is SL
      
      if(MinimumSL <= 0) {
         minSLPTValue = slptValue;
      } else {
         if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_BUY_LIMIT) {
            minSLPTValue = price + (SLorPT * MinimumSL * pointCoef);
            slptValue = MathMin(slptValue, minSLPTValue);
            
         } else {
         
            minSLPTValue = price - (SLorPT * MinimumSL * pointCoef);
            slptValue = MathMax(slptValue, minSLPTValue);
         }
   
      }
      
      if(MaximumSL <= 0) {
         maxSLPTValue = slptValue;
      } else {
         if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_BUY_LIMIT) {
            maxSLPTValue = price + (SLorPT * MaximumSL * pointCoef);
            slptValue = MathMax(slptValue, maxSLPTValue);

         } else {
            maxSLPTValue = price - (SLorPT * MaximumSL * pointCoef);
            slptValue = MathMin(slptValue, maxSLPTValue);
         }

      }
      
   } else {
      // it is PT

      if(MinimumPT <= 0) {
         minSLPTValue = slptValue;
      } else {
         if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_BUY_LIMIT) {
            minSLPTValue = price + (SLorPT * MinimumPT * pointCoef);
            slptValue = MathMax(slptValue, minSLPTValue);
            
         } else {
            minSLPTValue = price - (SLorPT * MinimumPT * pointCoef);
            slptValue = MathMin(slptValue, minSLPTValue);
         }

      }
      
      if(MaximumPT <= 0) {
         maxSLPTValue = slptValue;
      } else {

         if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_BUY_LIMIT) {
            maxSLPTValue = price + (SLorPT * MaximumPT * pointCoef);
            slptValue = MathMin(slptValue, maxSLPTValue);

         } else {
         
            maxSLPTValue = price - (SLorPT * MaximumPT * pointCoef);
            slptValue = MathMax(slptValue, maxSLPTValue);
         }
      }
   }
               
   return (slptValue);
}  

//+------------------------------------------------------------------+

double sqBarRange(string symbol, int timeframe, int shift) {
   string curSymbol = correctSymbol(symbol);
  
   return(sqHigh(curSymbol, timeframe, shift) - sqLow(curSymbol, timeframe, shift));
}

//+------------------------------------------------------------------+

double sqConvertToRealPips(string symbol, double value) {
   if(symbol == "NULL" || symbol == "Current") {
      return NormalizeDouble(gPointCoef * value, 6);
   }

   double pointCoef = sqGetPointCoef(symbol);

   return NormalizeDouble(pointCoef * value, 6);
}

//+------------------------------------------------------------------+

double sqGetPointCoef(string symbol) {
   string correctedSymbol = correctSymbol(symbol);
   
   if(correctedSymbol == _Symbol) {
      return(gPointCoef);
   }

   return calculatePointCoef(correctedSymbol);
}

//+------------------------------------------------------------------+

double calculatePointCoef(string symbol){
   double ticksize = sqGetMarketTickSize(symbol);
   if(ticksize >= 0){
      return ticksize;
   }
   else {
      if(SymbolInfoInteger(Symbol(), SYMBOL_TRADE_CALC_MODE) == SYMBOL_CALC_MODE_FOREX || SymbolInfoInteger(Symbol(), SYMBOL_TRADE_CALC_MODE) == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE){
         //forex calculation       
         double realDigits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         if(realDigits > 0 && realDigits != 2 && realDigits != 4) {
            realDigits -= 1;
         }
         return 1.0 / MathPow(10, realDigits);
      } 
      else {
         //futures/stocks/cfds
         return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);         
      } 
   }
}

//+------------------------------------------------------------------+

double sqFixMarketPrice(double price, string symbol){             
   symbol = correctSymbol(symbol);
   
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(tickSize == 0){
      return price;
   }
   
   int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double finalPrice = tickSize * MathRound(NormalizeDouble(price, digits) / tickSize);
   return NormalizeDouble(finalPrice, digits);
}

//+------------------------------------------------------------------+

bool sqDoublesAreEqual(double n1, double n2, bool price=true) {
   if(price){
      string st1 = DoubleToString(n1, _Digits);
      string st2 = DoubleToString(n2, _Digits);
   
      return (st1 == st2);
   }
   else {
      return MathAbs(n1 - n2) < 0.00000001;
   }
}

//+------------------------------------------------------------------+

double sqHighest(string symbol, int timeframe, int computedFrom, int period, int shift) {
   double maxnum = -100000000;
   double val;

   for(int i=shift; i<shift+period; i++) {
      val = sqGetValue(symbol, timeframe, computedFrom, i);

      if(val > maxnum) {
         maxnum = val;
      }
   }

   return(maxnum);
}

//+------------------------------------------------------------------+

double sqHighestIndex(string symbol, int timeframe, int computedFrom, int period, int shift) {
   double maxnum = -100000000;
   int index = -1;
   double val;

   for(int i=shift; i<shift+period; i++) {
      val = sqGetValue(symbol, timeframe, computedFrom, i);

      if(val > maxnum) {
         maxnum = val;
         index = i;
      }
   }

   return(index);
}

//+------------------------------------------------------------------+

double sqLowest(string symbol, int timeframe, int computedFrom, int period, int shift) {
   double minnum = 100000000;
   double val;

   for(int i=shift; i<shift+period; i++) {
      val = sqGetValue(symbol, timeframe, computedFrom, i);

      if(val < minnum) {
         minnum = val;
      }
   }

   return(minnum);
}

//+------------------------------------------------------------------+

double sqLowestIndex(string symbol, int timeframe, int computedFrom, int period, int shift) {
   double minnum = 100000000;
   int index = -1;
   double val;

   for(int i=shift; i<shift+period; i++) {
      val = sqGetValue(symbol, timeframe, computedFrom, i);

      if(val < minnum) {
         minnum = val;
         index = i;
      }
   }

   return(index);
}       

//+------------------------------------------------------------------+

double sqGetValue(string symbol, int timeframe, int computedFrom, int shift) {
   string correctedSymbol = correctSymbol(symbol); 
   if(symbol == "NULL" || symbol == "Current") {
      switch(computedFrom) {
         case PRICE_OPEN: return sqOpen(correctedSymbol, timeframe, shift);
         case PRICE_HIGH: return sqHigh(correctedSymbol, timeframe, shift);
         case PRICE_LOW: return sqLow(correctedSymbol, timeframe, shift);
         case PRICE_CLOSE: return sqClose(correctedSymbol, timeframe, shift);
         case PRICE_MEDIAN: return (sqHigh(correctedSymbol, timeframe, shift)+sqLow(correctedSymbol, timeframe, shift))/2;
         case PRICE_TYPICAL: return (sqHigh(correctedSymbol, timeframe, shift)+sqLow(correctedSymbol, timeframe, shift)+sqClose(correctedSymbol, timeframe, shift))/3;
         case PRICE_WEIGHTED: return (sqHigh(correctedSymbol, timeframe, shift)+sqLow(correctedSymbol, timeframe, shift)+sqClose(correctedSymbol, timeframe, shift)+sqClose(correctedSymbol, timeframe, shift))/4;
      }

   } 

   return 0;
}

//+------------------------------------------------------------------+

double sqBiggestRange(string symbol, int timeframe, int period, int shift) {
   double maxnum = -100000000;
   double range;           
   string correctedSymbol = correctSymbol(symbol);

   for(int i=shift; i<shift+period; i++) {
      range = NormalizeDouble(sqHigh(correctedSymbol, timeframe, i) - sqLow(correctedSymbol, timeframe, i), 8);

      if(range > maxnum) {
         maxnum = range;
      }
   }

   return(maxnum);
}


//+------------------------------------------------------------------+

double sqSmallestRange(string symbol, int timeframe, int period, int shift) {
   double minnum = 100000000;
   double range;
   string correctedSymbol = correctSymbol(symbol);

   for(int i=shift; i<shift+period; i++) {
      range = NormalizeDouble(sqHigh(correctedSymbol, timeframe, i) - sqLow(correctedSymbol, timeframe, i), 8);

      if(range < minnum) {
         minnum = range;
      }
   }

   return(minnum);
}

//+------------------------------------------------------------------+

void sqDrawUpArrow(int shift) {
   string name;
   StringConcatenate(name, "Arrow_", MathRand());

   ObjectCreate(ChartID(), name, OBJ_ARROW_UP, 0, getTime(shift), getLow(shift) - 100 * _Point); //draw an up arrow
   ObjectSetInteger(ChartID(), name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrGreen);
}

//+------------------------------------------------------------------+

void sqDrawDownArrow(int shift) {
   string name;
   StringConcatenate(name, "Arrow_", MathRand());

   ObjectCreate(ChartID(), name, OBJ_ARROW_DOWN, 0, getTime(shift), getHigh(shift) + 100 * _Point); //draw an down arrow
   ObjectSetInteger(ChartID(), name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrRed);
}            

//+------------------------------------------------------------------+

void sqDrawVerticalLine(int shift) {
   string name;
   StringConcatenate(name, "VerticalLine_", MathRand());

   ObjectCreate(ChartID(), name, OBJ_VLINE, 0, getTime(shift), 0);                       //draw a vertical line
   ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(ChartID(), name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(ChartID(), name, OBJPROP_STYLE, STYLE_DOT);
}

//+------------------------------------------------------------------+

double sqHeikenAshi(string symbol, ENUM_TIMEFRAMES timeframe, string mode, int shift) {
   uchar indyIndex = getHeikenAshiIndex(symbol, timeframe);
   if(indyIndex == 255){
      Print("HeikenAshi indicator error. Handle for symbol ", symbol, " and timeframe ", timeframe, " was not found");
      return(-1);
   }
   
   if(mode == "Open") {
      return(sqGetIndicatorValue(indyIndex, 0, shift));
   }
   else if(mode == "Close") {
      return(sqGetIndicatorValue(indyIndex, 3, shift));
   }
   else if(mode == "High") {
      return(MathMax(sqGetIndicatorValue(indyIndex, 0, shift), sqGetIndicatorValue(indyIndex, 1, shift)));
   }
   else if(mode == "Low") {
      return(MathMin(sqGetIndicatorValue(indyIndex, 0, shift), sqGetIndicatorValue(indyIndex, 2, shift)));
   }

   return(-1);
}

//+------------------------------------------------------------------+

double sqDaily(string symbol, int tf, string mode, int shift) {
   return sqGetOHLC(symbol, PERIOD_D1, mode, shift);
}                

//+------------------------------------------------------------------+

double sqWeekly(string symbol, int tf, string mode, int shift) {
   return sqGetOHLC(symbol, PERIOD_W1, mode, shift);
}

//+------------------------------------------------------------------+

double sqMonthly(string symbol, int tf, string mode, int shift) {
   return sqGetOHLC(symbol, PERIOD_MN1, mode, shift);
}     

//+------------------------------------------------------------------+

double sqGetOHLC(string symbol, int tf, string mode, int shift){
   if(symbol == "NULL" || symbol == "Current") {
      if(mode == "Open") {
         return(sqOpen(NULL, tf, shift));
      }
      if(mode == "Close") {
         return(sqClose(NULL, tf, shift));
      }
      if(mode == "High") {
         return(sqHigh(NULL, tf, shift));
      }
      if(mode == "Low") {
         return(sqLow(NULL, tf, shift));
      }

   } else {
      if(mode == "Open") {
         return(sqOpen(symbol, tf, shift));
      }
      if(mode == "Close") {
         return(sqClose(symbol, tf, shift));
      }
      if(mode == "High") {
         return(sqHigh(symbol, tf, shift));
      }
      if(mode == "Low") {
         return(sqLow(symbol, tf, shift));
      }
   }

   return(-1);
}

//+------------------------------------------------------------------+

double sqHighestInRange(string symbol, int timeframe, string timeFrom, string timeTo) {     
   string correctedSymbol = correctSymbol(symbol);
   int indexTo = -1;
   int indexFrom = -1;
   int i;

   int timeFromHHMM = getHHMM(timeFrom);
   int timeToHHMM = getHHMM(timeTo);
   
   int bars = Bars(correctedSymbol, (ENUM_TIMEFRAMES) timeframe);
   int max = bars <= 2000 ? (bars - 1) : 2000;
   
   // find index of bar for timeTo
   for(i=0; i<max; i++) {
      if(getHHMM(TimeToString(getTime(i), TIME_MINUTES)) == timeToHHMM || (getHHMM(TimeToString(getTime(i), TIME_MINUTES)) >= timeToHHMM && getHHMM(TimeToString(getTime(i+1), TIME_MINUTES)) < timeToHHMM)) {
         //Log("Found timeTo: ", TimeToStr(Time[i]));
         indexTo = i;
         break;
      }
   }

   if(indexTo == -1) {
      Log("Highest In Range error - 'Time to' not found");
      return(-1);
   }

   // find index of bar for timeFrom
   for(i=indexTo+1; i<max; i++) {
      if(getHHMM(TimeToString(getTime(i), TIME_MINUTES)) == timeFromHHMM || (getHHMM(TimeToString(getTime(i), TIME_MINUTES)) >= timeFromHHMM && getHHMM(TimeToString(getTime(i+1), TIME_MINUTES)) < timeFromHHMM)) {
         //Log("Found timeFrom: ", TimeToStr(Time[i]));
         indexFrom = i;
         break;
      }
   }
   
   if(indexFrom == -1) {
      Log("Highest In Range error - 'Time from' not found");
      return(-1);
   }

   double value = -100000000.0;

   for(i=indexTo; i<=indexFrom; i++) {
      value = MathMax(value, sqHigh(correctedSymbol, timeframe, i));
   }

   return(value);
}

//+------------------------------------------------------------------+

double sqLowestInRange(string symbol, int timeframe, string timeFrom, string timeTo) {
   string correctedSymbol = correctSymbol(symbol);
   int indexTo = -1;
   int indexFrom = -1;
   int i;
   
   int timeFromHHMM = getHHMM(timeFrom);
   int timeToHHMM = getHHMM(timeTo);         
   
   int bars = Bars(correctedSymbol, (ENUM_TIMEFRAMES) timeframe);
   int max = bars <= 2000 ? (bars - 1) : 2000;

   // find index of bar for timeTo
   for(i=0; i<max; i++) {
      if(getHHMM(TimeToString(getTime(i), TIME_MINUTES)) == timeToHHMM || (getHHMM(TimeToString(getTime(i), TIME_MINUTES)) >= timeToHHMM && getHHMM(TimeToString(getTime(i+1), TIME_MINUTES)) < timeToHHMM)) {
         //Log("Found timeTo: ", TimeToString(getTime(i)));
         indexTo = i;
         break;
      }
   }

   if(indexTo == -1) {
      Log("Lowest In Range error - 'Time to' not found");
      return(-1);
   }

   // find index of bar for timeFrom
   for(i=indexTo+1; i<max; i++) {
      if(getHHMM(TimeToString(getTime(i), TIME_MINUTES)) == timeFromHHMM || (getHHMM(TimeToString(getTime(i), TIME_MINUTES)) >= timeFromHHMM && getHHMM(TimeToString(getTime(i+1), TIME_MINUTES)) < timeFromHHMM)) {
         //Log("Found timeFrom: ", TimeToString(getTime(i)));
         indexFrom = i;
         break;
      }
   }

   if(indexFrom == -1) {
      Log("Lowest In Range error - 'Time from' not found");
      return(-1);
   }

   double value = 100000000.0;

   for(i=indexTo; i<=indexFrom; i++) {
      value = MathMin(value, sqLow(correctedSymbol, timeframe, i));
   }

   return(value);
}

//+------------------------------------------------------------------+

int getHHMM(string time){
   string result[];           
   int k = StringSplit(time, ':', result);
   
   if(k == 2){
      int hour = (int) StringToInteger(StringSubstr(result[0], 0, 1) == "0" ? StringSubstr(result[0], 1, 1) : result[0]);
      int minute = (int) StringToInteger(StringSubstr(result[1], 0, 1) == "0" ? StringSubstr(result[1], 1, 1) : result[1]);
      return (hour * 100) + minute;
   }
   else {
      Print("Incorrect time value format. Value: '" + time + "'");
      return 0;
   }
}

//+------------------------------------------------------------------+

int sqGetDate(int day, int month, int year) {
   return (year - 1900) * 10000 + month * 100 + day;
}

//+------------------------------------------------------------------+

int sqGetBarDate(datetime dt){
   MqlDateTime tm;
   TimeToStruct(dt,tm);
   
   return sqGetDate(tm.day, tm.mon, tm.year);
}

//+------------------------------------------------------------------+

double sqGetTime(int hour, int minute, int second) {
   return 100 * hour + minute + 0.01 * second;
}

//+------------------------------------------------------------------+

int getSQTime(datetime time){
   int minutesToday = (((int) time) / 60) % (24 * 60);
   int hours = minutesToday / 60;
   int minutes = minutesToday % 60;
   
   return hours*100 + minutes;
}

//+------------------------------------------------------------------+

double sqSafeDivide(double var1, double var2) {
   if(var2 == 0) return(100000000);
   return(var1/var2);
}

//+------------------------------------------------------------------+

bool sqIsGreaterThanZero(double value) {
   double diff = value - 0;
   if(diff > 0.0000000001) {
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+

bool sqIsLowerThanZero(double value) {
   double diff = 0 - value;
   if(diff > 0.0000000001) {
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//+ Candle Pattern functions
//+------------------------------------------------------------------+

bool sqBearishEngulfing(string symbol, int timeframe, int shift) {
   string correctedSymbol = correctSymbol(symbol);
   
   double O = sqOpen(correctedSymbol, timeframe, shift);
   double O1 = sqOpen(correctedSymbol, timeframe, shift+1);
   double C = sqClose(correctedSymbol, timeframe, shift);
   double C1 = sqClose(correctedSymbol, timeframe, shift+1);

   if ((C1>O1)&&(O>C)&&(O>=C1)&&(O1>=C)&&((O-C)>(C1-O1))) {
      return(true);
   }

   return(false);
}

//+------------------------------------------------------------------+

bool sqBullishEngulfing(string symbol, int timeframe, int shift) {
   string correctedSymbol = correctSymbol(symbol);       
   
   double O = sqOpen(correctedSymbol, timeframe, shift);
   double O1 = sqOpen(correctedSymbol, timeframe, shift+1);
   double C = sqClose(correctedSymbol, timeframe, shift);
   double C1 = sqClose(correctedSymbol, timeframe, shift+1);

   if ((O1>C1)&&(C>O)&&(C>=O1)&&(C1>=O)&&((C-O)>(O1-C1))) {
      return(true);
   }

   return(false);
}

//+------------------------------------------------------------------+

bool sqDarkCloudCover(string symbol, int timeframe, int shift) {
   string correctedSymbol = correctSymbol(symbol);               
   
   double L = sqLow(correctedSymbol, timeframe, shift);
   double H = sqHigh(correctedSymbol, timeframe, shift);

   double O = sqOpen(correctedSymbol, timeframe, shift);
   double O1 = sqOpen(correctedSymbol, timeframe, shift+1);
   double C = sqClose(correctedSymbol, timeframe, shift);
   double C1 = sqClose(correctedSymbol, timeframe, shift+1);
   
 	double tickSize = sqGetPointCoef(correctedSymbol);

 	double Piercing_Line_Ratio = 0.5f;
 	double Piercing_Candle_Length = 10.0f;
 	
 	double HL = NormalizeDouble(H-L, _Digits);
 	double OC = NormalizeDouble(O-C, _Digits);
 	double OC_HL = HL != 0 ? NormalizeDouble(OC/HL, 6) : 0;
 	double O1C1_D2 = NormalizeDouble((O1+C1)/2, _Digits);
 	double PCL_MTS = NormalizeDouble(Piercing_Candle_Length*tickSize, _Digits);
 			
 	if(C1 > O1 && O1C1_D2 > C && O > C && C > O1 && OC_HL > Piercing_Line_Ratio && HL >= PCL_MTS) {
 		return true;
 	}

   return(false);
}

//+------------------------------------------------------------------+

bool sqDoji(string symbol, int timeframe, int shift) {
   string correctedSymbol = correctSymbol(symbol);     
   
   double priceDiff = NormalizeDouble(MathAbs(sqOpen(correctedSymbol, timeframe, shift) - sqClose(correctedSymbol, timeframe, shift)), _Digits);
	double maxValue = NormalizeDouble(0.6 * sqGetPointCoef(symbol), _Digits);

   if(priceDiff < maxValue) {
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+

bool sqHammer(string symbol, int timeframe, int shift) {
   string correctedSymbol = correctSymbol(symbol);      
   
   double H = sqHigh(correctedSymbol, timeframe, shift);
   double L = sqLow(correctedSymbol, timeframe, shift);
   double L1 = sqLow(correctedSymbol, timeframe, shift+1);
   double L2 = sqLow(correctedSymbol, timeframe, shift+2);
   double L3 = sqLow(correctedSymbol, timeframe, shift+3);

   double O = sqOpen(correctedSymbol, timeframe, shift);
   double C = sqClose(correctedSymbol, timeframe, shift);
   double CL = H-L;

   double BodyLow, BodyHigh;
   double Candle_WickBody_Percent = 0.9;
   double CandleLength = 12;

   if (O > C) {
      BodyHigh = O;
      BodyLow = C;
   } else {
      BodyHigh = C;
      BodyLow = O;
   }

   double LW = NormalizeDouble(BodyLow - L, _Digits);
   double UW = NormalizeDouble(H - BodyHigh, _Digits);
   double BLa = NormalizeDouble(MathAbs(O - C), _Digits);
   double BL90 = NormalizeDouble(BLa * Candle_WickBody_Percent, _Digits);
   
   double pipValue = sqGetPointCoef(correctedSymbol);
   
   double LW_D2 = NormalizeDouble(LW / 2, _Digits);
   double LW_D3 = NormalizeDouble(LW / 3, _Digits);
   double LW_D4 = NormalizeDouble(LW / 4, _Digits);
   double BL90_M2 = NormalizeDouble(2 * BL90, _Digits);
   double CL_MPV = NormalizeDouble(CandleLength * pipValue, _Digits);
     
   if(L <= L1 && L < L2 && L < L3)  {
 		if(LW_D2 > UW && LW > BL90_M2 && CL >= CL_MPV && O != C && LW_D3 <= UW && LW_D4 <= UW)  {
    	  	return(true);
      }
      if(LW_D3 > UW && LW > BL90_M2 && CL >= CL_MPV && O != C && LW_D4 <= UW)  {
      	return(true);
      }
      if(LW_D4 > UW && LW > BL90_M2 && CL >= CL_MPV && O != C)  {
    	  	return(true);
      }
   }
     
   return(false);
}

//+------------------------------------------------------------------+

bool sqPiercingLine(string symbol, int timeframe, int shift) {
   string correctedSymbol = correctSymbol(symbol);       
   
   double L = sqLow(correctedSymbol, timeframe, shift);
   double H = sqHigh(correctedSymbol, timeframe, shift);

   double O = sqOpen(correctedSymbol, timeframe, shift);
   double O1 = sqOpen(correctedSymbol, timeframe, shift+1);
   double C = sqClose(correctedSymbol, timeframe, shift);
   double C1 = sqClose(correctedSymbol, timeframe, shift+1);
   
 	double tickSize = sqGetPointCoef(correctedSymbol);

 	double Piercing_Line_Ratio = 0.5f;
 	double Piercing_Candle_Length = 10.0f;
 	
 	double HL = NormalizeDouble(H-L, _Digits);
 	double CO = NormalizeDouble(C-O, _Digits);
 	double CO_HL = HL != 0 ? NormalizeDouble(CO/HL, 6) : 0;
 	double O1C1_D2 = NormalizeDouble((O1+C1)/2, _Digits);
 	double PCL_MTS = NormalizeDouble(Piercing_Candle_Length*tickSize, _Digits);
 			
 	if(C1 < O1 && O1C1_D2 < C && O < C && C < O1 && CO_HL > Piercing_Line_Ratio && HL >= PCL_MTS) {
 		return true;
 	}

   return(false);
}

//+------------------------------------------------------------------+

bool sqShootingStar(string symbol, int timeframe, int shift) {
   string correctedSymbol = correctSymbol(symbol);           
   
   double L = sqLow(correctedSymbol, timeframe, shift);
   double H = sqHigh(correctedSymbol, timeframe, shift);
   double H1 = sqHigh(correctedSymbol, timeframe, shift + 1);
   double H2 = sqHigh(correctedSymbol, timeframe, shift + 2);
   double H3 = sqHigh(correctedSymbol, timeframe, shift + 3);

   double O = sqOpen(correctedSymbol, timeframe, shift);
   double C = sqClose(correctedSymbol, timeframe, shift);
   double CL = NormalizeDouble(H - L, _Digits);

   double BodyLow, BodyHigh;
   double Candle_WickBody_Percent = 0.9;
   double CandleLength = 12;

   if (O > C) {
      BodyHigh = O;
      BodyLow = C;
   } else {
      BodyHigh = C;
      BodyLow = O;
   }

   double LW = NormalizeDouble(BodyLow - L, _Digits);
   double UW = NormalizeDouble(H - BodyHigh, _Digits);
   double BLa = NormalizeDouble(MathAbs(O - C), _Digits);
   double BL90 = NormalizeDouble(BLa * Candle_WickBody_Percent, _Digits);
   
   double pipValue = sqGetPointCoef(symbol);
   
   double UW_D2 = NormalizeDouble(UW / 2, _Digits);
   double UW_D3 = NormalizeDouble(UW / 3, _Digits);
   double UW_D4 = NormalizeDouble(UW / 4, _Digits);
   double BL90_M2 = NormalizeDouble(2 * BL90, _Digits);
   double CL_MPV = NormalizeDouble(CandleLength * pipValue, _Digits);

   if(H >= H1 && H > H2 && H > H3)  {
      if(UW_D2 > LW && UW > BL90_M2 && CL >= CL_MPV && O != C && UW_D3 <= LW && UW_D4 <= LW)  {
         return(true);
      }
      if(UW_D3 > LW && UW > BL90_M2 && CL >= CL_MPV && O != C && UW_D4 <= LW)  {
         return(true);
      }
      if(UW_D4 > LW && UW > BL90_M2 && CL >= CL_MPV && O != C)  {
         return(true);
      }
   }

   return(false);
} 

//+------------------------------------------------------------------+
//| returns runtime error code description                           |
//+------------------------------------------------------------------+
string ErrorDescription(int err_code)
  {
//---
   switch(err_code)
     {
      //--- Constant Description
      case ERR_SUCCESS:                      return("The operation completed successfully");
      case ERR_INTERNAL_ERROR:               return("Unexpected internal error");
      case ERR_WRONG_INTERNAL_PARAMETER:     return("Wrong parameter in the inner call of the client terminal function");
      case ERR_INVALID_PARAMETER:            return("Wrong parameter when calling the system function");
      case ERR_NOT_ENOUGH_MEMORY:            return("Not enough memory to perform the system function");
      case ERR_STRUCT_WITHOBJECTS_ORCLASS:   return("The structure contains objects of strings and/or dynamic arrays and/or structure of such objects and/or classes");
      case ERR_INVALID_ARRAY:                return("Array of a wrong type, wrong size, or a damaged object of a dynamic array");
      case ERR_ARRAY_RESIZE_ERROR:           return("Not enough memory for the relocation of an array, or an attempt to change the size of a static array");
      case ERR_STRING_RESIZE_ERROR:          return("Not enough memory for the relocation of string");
      case ERR_NOTINITIALIZED_STRING:        return("Not initialized string");
      case ERR_INVALID_DATETIME:             return("Invalid date and/or time");
      case ERR_ARRAY_BAD_SIZE:               return("Requested array size exceeds 2 GB");
      case ERR_INVALID_POINTER:              return("Wrong pointer");
      case ERR_INVALID_POINTER_TYPE:         return("Wrong type of pointer");
      case ERR_FUNCTION_NOT_ALLOWED:         return("System function is not allowed to call");
      //--- Charts	
      case ERR_CHART_WRONG_ID:               return("Wrong chart ID");
      case ERR_CHART_NO_REPLY:               return("Chart does not respond");
      case ERR_CHART_NOT_FOUND:              return("Chart not found");
      case ERR_CHART_NO_EXPERT:              return("No Expert Advisor in the chart that could handle the event");
      case ERR_CHART_CANNOT_OPEN:            return("Chart opening error");
      case ERR_CHART_CANNOT_CHANGE:          return("Failed to change chart symbol and period");
      case ERR_CHART_WRONG_PARAMETER:        return("Wrong parameter");
      case ERR_CHART_CANNOT_CREATE_TIMER:    return("Failed to create timer");
      case ERR_CHART_WRONG_PROPERTY:         return("Wrong chart property ID");
      case ERR_CHART_SCREENSHOT_FAILED:      return("Error creating screenshots");
      case ERR_CHART_NAVIGATE_FAILED:        return("Error navigating through chart");
      case ERR_CHART_TEMPLATE_FAILED:        return("Error applying template");
      case ERR_CHART_WINDOW_NOT_FOUND:       return("Subwindow containing the indicator was not found");
      case ERR_CHART_INDICATOR_CANNOT_ADD:   return("Error adding an indicator to chart");
      case ERR_CHART_INDICATOR_CANNOT_DEL:   return("Error deleting an indicator from the chart");
      case ERR_CHART_INDICATOR_NOT_FOUND:    return("Indicator not found on the specified chart");
      //--- Graphical Objects	
      case ERR_OBJECT_ERROR:                 return("Error working with a graphical object");
      case ERR_OBJECT_NOT_FOUND:             return("Graphical object was not found");
      case ERR_OBJECT_WRONG_PROPERTY:        return("Wrong ID of a graphical object property");
      case ERR_OBJECT_GETDATE_FAILED:        return("Unable to get date corresponding to the value");
      case ERR_OBJECT_GETVALUE_FAILED:       return("Unable to get value corresponding to the date");
      //--- MarketInfo	
      case ERR_MARKET_UNKNOWN_SYMBOL:        return("Unknown symbol");
      case ERR_MARKET_NOT_SELECTED:          return("Symbol is not selected in MarketWatch");
      case ERR_MARKET_WRONG_PROPERTY:        return("Wrong identifier of a symbol property");
      case ERR_MARKET_LASTTIME_UNKNOWN:      return("Time of the last tick is not known (no ticks)");
      case ERR_MARKET_SELECT_ERROR:          return("Error adding or deleting a symbol in MarketWatch");
      //--- History Access	
      case ERR_HISTORY_NOT_FOUND:            return("Requested history not found");
      case ERR_HISTORY_WRONG_PROPERTY:       return("Wrong ID of the history property");
      //--- Global_Variables	
      case ERR_GLOBALVARIABLE_NOT_FOUND:     return("Global variable of the client terminal is not found");
      case ERR_GLOBALVARIABLE_EXISTS:        return("Global variable of the client terminal with the same name already exists");
      case ERR_MAIL_SEND_FAILED:             return("Email sending failed");
      case ERR_PLAY_SOUND_FAILED:            return("Sound playing failed");
      case ERR_MQL5_WRONG_PROPERTY:          return("Wrong identifier of the program property");
      case ERR_TERMINAL_WRONG_PROPERTY:      return("Wrong identifier of the terminal property");
      case ERR_FTP_SEND_FAILED:              return("File sending via ftp failed");
      case ERR_NOTIFICATION_SEND_FAILED:     return("Error in sending notification");
      //--- Custom Indicator Buffers
      case ERR_BUFFERS_NO_MEMORY:            return("Not enough memory for the distribution of indicator buffers");
      case ERR_BUFFERS_WRONG_INDEX:          return("Wrong indicator buffer index");
      //--- Custom Indicator Properties
      case ERR_CUSTOM_WRONG_PROPERTY:        return("Wrong ID of the custom indicator property");
      //--- Account
      case ERR_ACCOUNT_WRONG_PROPERTY:       return("Wrong account property ID");
      case ERR_TRADE_WRONG_PROPERTY:         return("Wrong trade property ID");
      case ERR_TRADE_DISABLED:               return("Trading by Expert Advisors prohibited");
      case ERR_TRADE_POSITION_NOT_FOUND:     return("Position not found");
      case ERR_TRADE_ORDER_NOT_FOUND:        return("Order not found");
      case ERR_TRADE_DEAL_NOT_FOUND:         return("Deal not found");
      case ERR_TRADE_SEND_FAILED:            return("Trade request sending failed");
      //--- Indicators	
      case ERR_INDICATOR_UNKNOWN_SYMBOL:     return("Unknown symbol");
      case ERR_INDICATOR_CANNOT_CREATE:      return("Indicator cannot be created");
      case ERR_INDICATOR_NO_MEMORY:          return("Not enough memory to add the indicator");
      case ERR_INDICATOR_CANNOT_APPLY:       return("The indicator cannot be applied to another indicator");
      case ERR_INDICATOR_CANNOT_ADD:         return("Error applying an indicator to chart");
      case ERR_INDICATOR_DATA_NOT_FOUND:     return("Requested data not found");
      case ERR_INDICATOR_WRONG_HANDLE:       return("Wrong indicator handle");
      case ERR_INDICATOR_WRONG_PARAMETERS:   return("Wrong number of parameters when creating an indicator");
      case ERR_INDICATOR_PARAMETERS_MISSING: return("No parameters when creating an indicator");
      case ERR_INDICATOR_CUSTOM_NAME:        return("The first parameter in the array must be the name of the custom indicator");
      case ERR_INDICATOR_PARAMETER_TYPE:     return("Invalid parameter type in the array when creating an indicator");
      case ERR_INDICATOR_WRONG_INDEX:        return("Wrong index of the requested indicator buffer");
      //--- Depth of Market	
      case ERR_BOOKS_CANNOT_ADD:             return("Depth Of Market can not be added");
      case ERR_BOOKS_CANNOT_DELETE:          return("Depth Of Market can not be removed");
      case ERR_BOOKS_CANNOT_GET:             return("The data from Depth Of Market can not be obtained");
      case ERR_BOOKS_CANNOT_SUBSCRIBE:       return("Error in subscribing to receive new data from Depth Of Market");
      //--- File Operations
      case ERR_TOO_MANY_FILES:               return("More than 64 files cannot be opened at the same time");
      case ERR_WRONG_FILENAME:               return("Invalid file name");
      case ERR_TOO_LONG_FILENAME:            return("Too long file name");
      case ERR_CANNOT_OPEN_FILE:             return("File opening error");
      case ERR_FILE_CACHEBUFFER_ERROR:       return("Not enough memory for cache to read");
      case ERR_CANNOT_DELETE_FILE:           return("File deleting error");
      case ERR_INVALID_FILEHANDLE:           return("A file with this handle was closed, or was not opening at all");
      case ERR_WRONG_FILEHANDLE:             return("Wrong file handle");
      case ERR_FILE_NOTTOWRITE:              return("The file must be opened for writing");
      case ERR_FILE_NOTTOREAD:               return("The file must be opened for reading");
      case ERR_FILE_NOTBIN:                  return("The file must be opened as a binary one");
      case ERR_FILE_NOTTXT:                  return("The file must be opened as a text");
      case ERR_FILE_NOTTXTORCSV:             return("The file must be opened as a text or CSV");
      case ERR_FILE_NOTCSV:                  return("The file must be opened as CSV");
      case ERR_FILE_READERROR:               return("File reading error");
      case ERR_FILE_BINSTRINGSIZE:           return("String size must be specified, because the file is opened as binary");
      case ERR_INCOMPATIBLE_FILE:            return("A text file must be for string arrays, for other arrays - binary");
      case ERR_FILE_IS_DIRECTORY:            return("This is not a file, this is a directory");
      case ERR_FILE_NOT_EXIST:               return("File does not exist");
      case ERR_FILE_CANNOT_REWRITE:          return("File can not be rewritten");
      case ERR_WRONG_DIRECTORYNAME:          return("Wrong directory name");
      case ERR_DIRECTORY_NOT_EXIST:          return("Directory does not exist");
      case ERR_FILE_ISNOT_DIRECTORY:         return("This is a file, not a directory");
      case ERR_CANNOT_DELETE_DIRECTORY:      return("The directory cannot be removed");
      case ERR_CANNOT_CLEAN_DIRECTORY:       return("Failed to clear the directory (probably one or more files are blocked and removal operation failed)");
      case ERR_FILE_WRITEERROR:              return("Failed to write a resource to a file");
      //--- String Casting	
      case ERR_NO_STRING_DATE:               return("No date in the string");
      case ERR_WRONG_STRING_DATE:            return("Wrong date in the string");
      case ERR_WRONG_STRING_TIME:            return("Wrong time in the string");
      case ERR_STRING_TIME_ERROR:            return("Error converting string to date");
      case ERR_STRING_OUT_OF_MEMORY:         return("Not enough memory for the string");
      case ERR_STRING_SMALL_LEN:             return("The string length is less than expected");
      case ERR_STRING_TOO_BIGNUMBER:         return("Too large number, more than ULONG_MAX");
      case ERR_WRONG_FORMATSTRING:           return("Invalid format string");
      case ERR_TOO_MANY_FORMATTERS:          return("Amount of format specifiers more than the parameters");
      case ERR_TOO_MANY_PARAMETERS:          return("Amount of parameters more than the format specifiers");
      case ERR_WRONG_STRING_PARAMETER:       return("Damaged parameter of string type");
      case ERR_STRINGPOS_OUTOFRANGE:         return("Position outside the string");
      case ERR_STRING_ZEROADDED:             return("0 added to the string end, a useless operation");
      case ERR_STRING_UNKNOWNTYPE:           return("Unknown data type when converting to a string");
      case ERR_WRONG_STRING_OBJECT:          return("Damaged string object");
      //--- Operations with Arrays	
      case ERR_INCOMPATIBLE_ARRAYS:          return("Copying incompatible arrays. String array can be copied only to a string array, and a numeric array - in numeric array only");
      case ERR_SMALL_ASSERIES_ARRAY:         return("The receiving array is declared as AS_SERIES, and it is of insufficient size");
      case ERR_SMALL_ARRAY:                  return("Too small array, the starting position is outside the array");
      case ERR_ZEROSIZE_ARRAY:               return("An array of zero length");
      case ERR_NUMBER_ARRAYS_ONLY:           return("Must be a numeric array");
      case ERR_ONEDIM_ARRAYS_ONLY:           return("Must be a one-dimensional array");
      case ERR_SERIES_ARRAY:                 return("Timeseries cannot be used");
      case ERR_DOUBLE_ARRAY_ONLY:            return("Must be an array of type double");
      case ERR_FLOAT_ARRAY_ONLY:             return("Must be an array of type float");
      case ERR_LONG_ARRAY_ONLY:              return("Must be an array of type long");
      case ERR_INT_ARRAY_ONLY:               return("Must be an array of type int");
      case ERR_SHORT_ARRAY_ONLY:             return("Must be an array of type short");
      case ERR_CHAR_ARRAY_ONLY:              return("Must be an array of type char");
      //--- Operations with OpenCL	
      case ERR_OPENCL_NOT_SUPPORTED:         return("OpenCL functions are not supported on this computer");
      case ERR_OPENCL_INTERNAL:              return("Internal error occurred when running OpenCL");
      case ERR_OPENCL_INVALID_HANDLE:        return("Invalid OpenCL handle");
      case ERR_OPENCL_CONTEXT_CREATE:        return("Error creating the OpenCL context");
      case ERR_OPENCL_QUEUE_CREATE:          return("Failed to create a run queue in OpenCL");
      case ERR_OPENCL_PROGRAM_CREATE:        return("Error occurred when compiling an OpenCL program");
      case ERR_OPENCL_TOO_LONG_KERNEL_NAME:  return("Too long kernel name (OpenCL kernel)");
      case ERR_OPENCL_KERNEL_CREATE:         return("Error creating an OpenCL kernel");
      case ERR_OPENCL_SET_KERNEL_PARAMETER:  return("Error occurred when setting parameters for the OpenCL kernel");
      case ERR_OPENCL_EXECUTE:               return("OpenCL program runtime error");
      case ERR_OPENCL_WRONG_BUFFER_SIZE:     return("Invalid size of the OpenCL buffer");
      case ERR_OPENCL_WRONG_BUFFER_OFFSET:   return("Invalid offset in the OpenCL buffer");
      case ERR_OPENCL_BUFFER_CREATE:         return("Failed to create and OpenCL buffer");
      //--- User-Defined Errors	
      default: if(err_code>=ERR_USER_ERROR_FIRST && err_code<ERR_USER_ERROR_LAST)
                                             return("User error "+string(err_code-ERR_USER_ERROR_FIRST));
     }
//---
   return("Unknown error");
  }

//+------------------------------------------------------------------+

double roundDown(double value, int decimals) {
  	double p = 0;
  	
  	switch(decimals) {
  		case 0: return (int) value; 
  		case 1: p = 10; break;
  		case 2: p = 100; break;
  		case 3: p = 1000; break;
  		case 4: p = 10000; break;
  		case 5: p = 100000; break;
  		case 6: p = 1000000; break;
  		default: p = MathPow(10, decimals);
  	}

  	value = value * p;
  	double tmp = MathFloor(value + 0.00000001);
  	return NormalizeDouble(tmp/p, decimals);
}

//+------------------------------------------------------------------+

class CSQTime {
public:

   datetime setHHMM(datetime time, string hhmm) {
      string date = TimeToString(time,TIME_DATE);//"yyyy.mm.dd"
      return (StringToTime(date + " " + hhmm));
   }

   //+------------------------------------------------------------------+

   datetime correctDayStart(datetime time) {
      MqlDateTime strTime;
      TimeToStruct(time, strTime);
      strTime.hour = 0;
      strTime.min = 0;
      strTime.sec = 0;
      return (StructToTime(strTime));
   }
   
   //+------------------------------------------------------------------+

   datetime getDateInMs(datetime time) {
      MqlDateTime strTime;
      TimeToStruct(time, strTime);
      strTime.hour = 0;
      strTime.min = 0;
      strTime.sec = 0;
      return (StructToTime(strTime));
   }

   //+------------------------------------------------------------------+

   datetime correctDayEnd(datetime time) {
      MqlDateTime strTime;
      TimeToStruct(time, strTime);
      strTime.hour = 23;
      strTime.min = 59;
      strTime.sec = 59;
      return (StructToTime(strTime));
   }
   
   //+------------------------------------------------------------------+

   datetime setDayOfMonth(datetime time, int day) {
		MqlDateTime strTime;
		TimeToStruct(time, strTime);
		strTime.day = day;
		return (StructToTime(strTime));
   }
   
   //+------------------------------------------------------------------+

   int getDaysInMonth(datetime time) {
      MqlDateTime strTime;
      TimeToStruct(time, strTime);
	  if(strTime.mon==2) {
		return  28+isLeapYear(strTime.year);
	  }
	  
	  return 31-((strTime.mon-1)%7)%2;
   }
   
   //+------------------------------------------------------------------+

	bool isLeapYear(const int _year){
	   if(_year%4 == 0){
		  if(_year%400 == 0)return true;
		  if(_year%100 > 0)return true;
	   }
	   return false;
	}
   
   //+------------------------------------------------------------------+

   datetime addDays(datetime time, int days) {
      int oneDay = 60 * 60 * 24;
      
      return (time + (days * oneDay));
   }
   
   //+------------------------------------------------------------------+

   datetime setDayOfWeek(datetime time, int desiredDow) {
      int dow = convertToSQDOW(sqTimeDayOfWeek(time));
      desiredDow = convertToSQDOW(desiredDow);
      
      int diffInDays = desiredDow - dow;
      
      //Print("DiffInDays: ", diffInDays, ", dow: ", dow, ", desiredDow: ", desiredDow);
      
      return addDays(time, diffInDays);
   }  
   
   //+------------------------------------------------------------------+

   /**
    * converts from MT DOW format: 0 = Sunday, 1 = Monday ... 6 = Saturday
    * to SQ DOW format: 1 = Monday, 2 = Tuesday ... 7 = Sunday
   */
   int convertToSQDOW(int dow) {
      if(dow == 0) dow = 7;
      
      return(dow);
   } 
};

// create variable for class instance (required)
CSQTime* SQTime;
           
//+------------------------------------------------------------------+

void writeReportFile(){
   string terminalDataPath = TerminalInfoString(TERMINAL_DATA_PATH); 
   StringReplace(terminalDataPath, "Tester", "Terminal");
   int agentIndex = StringFind(terminalDataPath, "Agent-", 0);
   terminalDataPath = StringSubstr(terminalDataPath, 0, agentIndex); 
   
   string filename = MQLInfoString(MQL_PROGRAM_NAME) + ".csv";
   
   Print(filename);
   
   int handle = FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_READ, ";");
   if(handle <= 0){
      Print("Cannot write strategy results to file");
      return;
   }
   
   HistorySelect(startTime, TimeCurrent());
   
   FileWrite(handle, "- List of canceled orders -------------------------------------");
   FileWrite(handle, "");
   
   for(int i=0; i<HistoryOrdersTotal(); i++){
       ulong orderTicket = HistoryOrderGetTicket(i);
       
       if(HistoryOrderSelect(orderTicket) && HistoryOrderGetInteger(orderTicket, ORDER_STATE) == ORDER_STATE_CANCELED){
          string orderSymbol = HistoryOrderGetString(orderTicket, ORDER_SYMBOL);        
          datetime orderTime = (datetime) HistoryOrderGetInteger(orderTicket, ORDER_TIME_SETUP);       
          datetime executionTime = (datetime) HistoryOrderGetInteger(orderTicket, ORDER_TIME_DONE);
          
          ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE) HistoryOrderGetInteger(orderTicket, ORDER_TYPE);
          double originalOpenPrice = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_OPEN);    
          double volume = HistoryOrderGetDouble(orderTicket, ORDER_VOLUME_INITIAL);
          
          FileWrite(handle, orderTicket, 0, orderSymbol, orderTime, executionTime, originalOpenPrice, 0, getOrderType(orderType), 0, volume, 0, 0, 0, "canceled");
       }
   }
                                 
   FileWrite(handle, "");
   FileWrite(handle, "- List of deals ---------------------------------------------");         
   FileWrite(handle, "");
   
   //write deals
   for(int i=0; i<HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if (HistoryDealSelect(ticket)){
         datetime dealTime = (datetime) HistoryDealGetInteger(ticket, DEAL_TIME);
         string dealSymbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY) HistoryDealGetInteger(ticket, DEAL_ENTRY);
         double dealVolume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
         double dealCommission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         double dealSwap = HistoryDealGetDouble(ticket, DEAL_SWAP);
         double dealProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);      
         double dealPrice = HistoryDealGetDouble(ticket, DEAL_PRICE);
         ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON) HistoryDealGetInteger(ticket, DEAL_REASON);  
         ulong positionId = (ulong) HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
         ulong orderId = (ulong) HistoryDealGetInteger(ticket, DEAL_ORDER);
         
         datetime orderTime;
         double originalOpenPrice;
         ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY;
         
         if(HistoryOrderSelect(orderId)){
             orderTime = (datetime) HistoryOrderGetInteger(orderId, ORDER_TIME_SETUP);
             orderType = (ENUM_ORDER_TYPE) HistoryOrderGetInteger(orderId, ORDER_TYPE);
             originalOpenPrice = HistoryOrderGetDouble(orderId, ORDER_PRICE_OPEN);
         }
 
         FileSeek(handle,0,SEEK_END);
         FileWrite(handle, orderId, positionId, dealSymbol, orderTime, dealTime, originalOpenPrice, dealPrice, getOrderType(orderType), getDealEntry(dealEntry), dealVolume, dealCommission, dealSwap, dealProfit, getDealReason(reason));
      } 
   }
   
   FileClose(handle);
}

//+------------------------------------------------------------------+

string getOrderType(ENUM_ORDER_TYPE orderType){
   switch(orderType){
      case ORDER_TYPE_BUY: return "buy";
      case ORDER_TYPE_SELL: return "sell";
      case ORDER_TYPE_BUY_LIMIT: return "buy limit";
      case ORDER_TYPE_SELL_LIMIT: return "sell limit";
      case ORDER_TYPE_BUY_STOP: return "buy stop";   
      case ORDER_TYPE_SELL_STOP: return "sell stop";
      case ORDER_TYPE_BUY_STOP_LIMIT: return "buy stop limit";
      case ORDER_TYPE_SELL_STOP_LIMIT: return "sell stop limit";
      case ORDER_TYPE_CLOSE_BY: return "close by";
      default: return "";
   }
}

//+------------------------------------------------------------------+

string getDealEntry(ENUM_DEAL_ENTRY dealEntry){
   switch(dealEntry){
      case DEAL_ENTRY_IN: return "in";
      case DEAL_ENTRY_OUT: return "out";
      case DEAL_ENTRY_INOUT: return "reverse";
      case DEAL_ENTRY_OUT_BY: return "closed by opposite";
      default: return "";
   }
}
 
//+------------------------------------------------------------------+

string getDealReason(ENUM_DEAL_REASON reason){
   switch(reason){
      case DEAL_REASON_SL: return "sl";
      case DEAL_REASON_TP: return "tp";
      case DEAL_REASON_SO: return "stop out";
      default: return "";
   }
}

//+------------------------------------------------------------------+

bool sqEvaluateFuzzySignal(int conditionsCount, int minTrueConditions) {

  bool signalValue = false;
  int trueConditionsCount = 0;
   
  if(minTrueConditions <= 0) {
  	minTrueConditions = 1;
  }
	   
	for(int i=0; i<conditionsCount; i++) {
	   bool value = cond[i];
				
		if(value) {
			trueConditionsCount++;
		}
				
		if(trueConditionsCount >= minTrueConditions) {
			signalValue = true;
			break;
		}
	}
			
	return(signalValue);
}

//+------------------------------------------------------------------+

bool sqIsUptrend(string symbol, int timeframe, int method, uchar indyIndex) {
   if(method == 0) {
      return (sqClose(symbol, timeframe, 1) > sqGetIndicatorValue(indyIndex, 1));      
   }
   return(false);	
}

//+------------------------------------------------------------------+

bool sqIsDowntrend(string symbol, int timeframe, int method, uchar indyIndex) {
   if(method == 0) {
      return (sqClose(symbol, timeframe, 1) < sqGetIndicatorValue(indyIndex, 1));      
   }
   return(false);	
}

//+------------------------------------------------------------------+

int sqGetMonthLastTradingDay(string symbol, int timeframe, bool includeWeekends) {
	datetime barTime = sqTime(symbol, timeframe, 0);
    datetime lastTradingDate = SQTime.setDayOfMonth(barTime, SQTime.getDaysInMonth(barTime));

	if(!includeWeekends) {
		if(sqTimeDayOfWeek(lastTradingDate) == 6) {
			lastTradingDate = SQTime.addDays(lastTradingDate, -1);
		
		} else if(sqTimeDayOfWeek(lastTradingDate) == 0) {
			lastTradingDate = SQTime.addDays(lastTradingDate, -2);
		}
	}

    return sqTimeDay(lastTradingDate);
}

//+------------------------------------------------------------------+

int sqGetMonthFirstTradingDay(string symbol, int timeframe, bool includeWeekends) {
	datetime barTime = sqTime(symbol, timeframe, 0);
	datetime firstTradingDate = SQTime.setDayOfMonth(barTime, 1);

	if(!includeWeekends) {
		if(sqTimeDayOfWeek(firstTradingDate) == 6) {
			firstTradingDate = SQTime.addDays(firstTradingDate, 2);
		
		} else if(sqTimeDayOfWeek(firstTradingDate) == 0) {
			firstTradingDate = SQTime.addDays(firstTradingDate, 1);
		}
	}

    return sqTimeDay(firstTradingDate);
}

//+------------------------------------------------------------------+

datetime monthFirstTradingDay = 0;

bool sqIsMonthFirstTradingDay(string symbol, int timeframe, bool includeWeekends) {
	datetime date = SQTime.getDateInMs(sqTime(symbol, timeframe, 0));
	
	if(monthFirstTradingDay == 0) {
		monthFirstTradingDay = date;
	}

	if(sqTimeMonth(monthFirstTradingDay)!=sqTimeMonth(date)) {
		if(!includeWeekends) {
			if(sqTimeDayOfWeek(date) != 6 && sqTimeDayOfWeek(date) != 0) {
				monthFirstTradingDay = date;
			}
		} else {
			monthFirstTradingDay = date;
		}
	}

	return monthFirstTradingDay==date;
}
  
//+------------------------------------------------------------------+

// Checks if market is currently open for specified symbol
bool IsMarketOpen(const string symbol, const bool debug = false) {
    if(!tradeInSessionHoursOnly) return true;
    
    datetime from = NULL;
    datetime to = NULL;
    datetime serverTime = TimeTradeServer();

    // Get the day of the week
    MqlDateTime dt;
    TimeToStruct(serverTime,dt);
    const ENUM_DAY_OF_WEEK day_of_week = (ENUM_DAY_OF_WEEK) dt.day_of_week;

    // Get the time component of the current datetime
    const int time = (int) MathMod(serverTime, PeriodSeconds(PERIOD_D1));

    if ( debug ) PrintFormat("%s(%s): Checking %s", __FUNCTION__, symbol, EnumToString(day_of_week));

    // Brokers split some symbols between multiple sessions.
    // One broker splits forex between two sessions (Tues thru Thurs on different session).
    // 2 sessions (0,1,2) should cover most cases.
    int session=2;
    while(session > -1)
    {
        if(SymbolInfoSessionTrade(symbol,day_of_week,session,from,to ))
        {
            if ( debug ) PrintFormat(    "%s(%s): Checking %d>=%d && %d<=%d",
                                        __FUNCTION__,
                                        symbol,
                                        time,
                                        from,
                                        time,
                                        to );
            
            const int sessionFrom = (int) MathMod(from, PeriodSeconds(PERIOD_D1));
            const int sessionTo = (int) MathMod(to, PeriodSeconds(PERIOD_D1));
            
            if(sessionFrom < sessionTo){
               if(time >= sessionFrom && time <= sessionTo )
               {
                   if ( debug ) PrintFormat("%s Market is open", __FUNCTION__);
                   return true;
               }
            }
            else {
               if(time >= sessionFrom || time <= sessionTo)
               {
                   if ( debug ) PrintFormat("%s Market is open", __FUNCTION__);
                   return true;
               }
            }
        }
        session--;
    }
    if ( debug ) PrintFormat("%s Market not open", __FUNCTION__);
    return false;
}

//+------------------------------------------------------------------+

bool isNettingMode(){
   return ((ENUM_ACCOUNT_MARGIN_MODE) AccountInfoInteger(ACCOUNT_MARGIN_MODE)) == ACCOUNT_MARGIN_MODE_RETAIL_NETTING;
}

//+------------------------------------------------------------------+

void addOrderExit(string symbol, int magicNo, ulong mainTicket, ulong ticket, int type, int bars, double size, double fixedPips, double ATRMultiplicator, uchar ATRIndyIndex){
   int firstEmptyIndex = -1;
   
   for(int a=0; a<ArraySize(orderExits); a++){
      OrderExitLevel exit = orderExits[a];
      
      if(firstEmptyIndex < 0 && exit.mainOrderTicket == 0) {
         firstEmptyIndex = a;
      }
      
      if(exit.symbol == symbol && exit.magicNumber == magicNo && exit.mainOrderTicket == mainTicket){
         for(int i=0; i<ArraySize(exit.exits); i++){
            if(orderExits[a].exits[i].type <= 0){
               orderExits[a].exits[i].ticket = ticket;
               orderExits[a].exits[i].type = type;
               orderExits[a].exits[i].bars = bars;
               orderExits[a].exits[i].size = size;
               orderExits[a].exits[i].fixedPips = fixedPips;
               orderExits[a].exits[i].ATRMultiplicator = ATRMultiplicator;
               orderExits[a].exits[i].ATRIndyIndex = ATRIndyIndex;
               return;
            }
         }
      }
   }
   
   if(firstEmptyIndex >= 0){
      orderExits[firstEmptyIndex].symbol = symbol;
      orderExits[firstEmptyIndex].magicNumber = magicNo;
      orderExits[firstEmptyIndex].mainOrderTicket = mainTicket;
      orderExits[firstEmptyIndex].exits[0].ticket = ticket;
      orderExits[firstEmptyIndex].exits[0].type = type;
      orderExits[firstEmptyIndex].exits[0].bars = bars;
      orderExits[firstEmptyIndex].exits[0].size = size;
      orderExits[firstEmptyIndex].exits[0].fixedPips = fixedPips;
      orderExits[firstEmptyIndex].exits[0].ATRMultiplicator = ATRMultiplicator;
      orderExits[firstEmptyIndex].exits[0].ATRIndyIndex = ATRIndyIndex;
   }
   else {
      Print("----------- Order exits array is full --------------");
   }
}

//+------------------------------------------------------------------+

void checkOpenPositions(){  
   for(int a=0; a<ArraySize(orderExits); a++){
      OrderExitLevel exit = orderExits[a];
      
      if(orderExits[a].mainOrderTicket == 0) continue;

      if(PositionSelectByTicket(orderExits[a].mainOrderTicket)){
         //position is open - manage exit orders
         
         for(int i=0; i<ArraySize(orderExits[a].exits); i++){
            if(orderExits[a].exits[i].type <= 0) continue;

            PositionSelectByTicket(orderExits[a].mainOrderTicket);

            if(orderExits[a].exits[i].type == ATM_EXIT_TYPE_TIME){
               if (sqGetOpenBarsForOrder(orderExits[a].exits[i].bars + 10, PositionGetInteger(POSITION_TIME)) >= orderExits[a].exits[i].bars) {
                  Verbose("Time based exit #", IntegerToString(i+1), " - after ", IntegerToString(orderExits[a].exits[i].bars), " bars / size: ", DoubleToString(orderExits[a].exits[i].size));
                  ulong exitTicket = openPosition(
                     isLongOrder((ENUM_ORDER_TYPE) PositionGetInteger(POSITION_TYPE)) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY,
                     orderExits[a].symbol, // Symbol
                     orderExits[a].exits[i].size, // Size
                     0, // Price
                     0, // Stop Loss
                     0, // Profit Target   
                     correctSlippage(sqMaxEntrySlippage, orderExits[a].symbol), // Max deviation
                     "", // Comment
                     orderExits[a].magicNumber, // MagicNumber
                     ExpirationTime, // Expiration time
                     false, // Replace existing (only for pending orders)
                     false,  // Allow duplicate trades
                     true
                  );

                  if(exitTicket > 0){
                     ZeroMemory(orderExits[a].exits[i]);
                  }
                  else {
                     Verbose("Exit order #", IntegerToString(i+1), " failed: ", IntegerToString(GetLastError()), " - ", ErrorDescription(GetLastError()));
                  }
               }
            }
            else if(orderExits[a].exits[i].type == ATM_EXIT_TYPE_TRAILING){
               bool isLong = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
               double trailingPrice = 0;
               if(isLong){
                  if(orderExits[a].exits[i].fixedPips > 0){
                     trailingPrice = sqFixMarketPrice(sqGetBid(orderExits[a].symbol) - sqConvertToRealPips(orderExits[a].symbol, orderExits[a].exits[i].fixedPips), orderExits[a].symbol);
                  }
                  else {
                     trailingPrice = sqFixMarketPrice(sqGetBid(orderExits[a].symbol) - orderExits[a].exits[i].ATRMultiplicator * sqGetIndicatorValue(orderExits[a].exits[i].ATRIndyIndex, 1), orderExits[a].symbol);
                  }
                  if(trailingPrice <= PositionGetDouble(POSITION_PRICE_OPEN) || (trailingPrice <= PositionGetDouble(POSITION_SL) && PositionGetDouble(POSITION_SL) > 0) || (trailingPrice <= orderExits[a].exits[i].lastTrailingPrice && orderExits[a].exits[i].lastTrailingPrice > 0) || !checkOrderPriceValid(ORDER_TYPE_SELL_STOP, orderExits[a].symbol, trailingPrice, sqGetBid(orderExits[a].symbol))){
                     continue;
                  }
               }
               else {
                  if(orderExits[a].exits[i].fixedPips > 0){
                     trailingPrice = sqFixMarketPrice(sqGetAsk(orderExits[a].symbol) + sqConvertToRealPips(orderExits[a].symbol, orderExits[a].exits[i].fixedPips), orderExits[a].symbol);
                  }
                  else {
                     trailingPrice = sqFixMarketPrice(sqGetAsk(orderExits[a].symbol) + orderExits[a].exits[i].ATRMultiplicator * sqGetIndicatorValue(orderExits[a].exits[i].ATRIndyIndex, 1), orderExits[a].symbol);
                  }
                  if(trailingPrice >= PositionGetDouble(POSITION_PRICE_OPEN) || (trailingPrice >= PositionGetDouble(POSITION_SL) && PositionGetDouble(POSITION_SL) > 0) || (trailingPrice >= orderExits[a].exits[i].lastTrailingPrice && orderExits[a].exits[i].lastTrailingPrice > 0) || !checkOrderPriceValid(ORDER_TYPE_BUY_STOP, orderExits[a].symbol, trailingPrice, sqGetAsk(orderExits[a].symbol))){
                     continue;
                  }
               }

               ulong exitTicket = orderExits[a].exits[i].ticket;
               if(exitTicket == 0){
                   Verbose("Opening order for exit #", IntegerToString(i+1), " - trailing stop...");
                   exitTicket = openPosition(
                     isLong ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_BUY_STOP, // Order type
                     orderExits[a].symbol, // Symbol
                     orderExits[a].exits[i].size,  //Size
                     trailingPrice, // Price
                     0, // Stop Loss
                     0, // Profit Target
                     correctSlippage(sqMaxEntrySlippage, orderExits[a].symbol), // Max deviation          
                     "", // Comment
                     MagicNumber, // MagicNumber
                     ExpirationTime, // Expiration time
                     false, // Replace existing order (if it exists)
                     false,  // Allow duplicate trades
                     true
                  );

                  if(exitTicket != 0) {
                     orderExits[a].exits[i].ticket = exitTicket;
                     orderExits[a].exits[i].lastTrailingPrice = trailingPrice;
                  }
                  else {
                     Verbose("Cannot open order for exit #", IntegerToString(i+1), ": ", IntegerToString(GetLastError()), " - ", ErrorDescription(GetLastError()));
                  }
               }
               else {
                  if (OrderSelect(exitTicket)){
                     double lastOpenPrice = OrderGetDouble(ORDER_PRICE_OPEN);
                     
                     if((isLong && lastOpenPrice < trailingPrice) || (!isLong && lastOpenPrice > trailingPrice)){
                        Verbose("Updating ATM trailing exit #", IntegerToString(i+1), " with ticket ", IntegerToString(exitTicket), " - new opening price: ", DoubleToString(trailingPrice));
                        OrderModifyOpenPrice(exitTicket, trailingPrice);
                        orderExits[a].exits[i].lastTrailingPrice = trailingPrice;
                     }
                  }
                  else {
                     if(!HistoryOrderSelect(exitTicket) || HistoryOrderGetInteger(exitTicket, ORDER_STATE) != ORDER_STATE_FILLED){
                        Verbose("Cannot update order for exit #", IntegerToString(i+1), " - order with ticket #", IntegerToString(exitTicket), " not found");
                     }
                  }
               }
            }
            else {
               //Other exit types are handled by setting profit target
            }
         }
      }
      else if(!OrderSelect(orderExits[a].mainOrderTicket)) {
         //position no longer exists
         
         Verbose("Position ", IntegerToString(orderExits[a].mainOrderTicket), " no longer exists - Closing remaining ATM exits...");
         
         for(int i=0; i<ArraySize(orderExits[a].exits); i++){
            ulong exitTicket = orderExits[a].exits[i].ticket;
            if(exitTicket > 0){
               Verbose("Deleting ATM exit with ticket ", IntegerToString(exitTicket));
               if (OrderSelect(exitTicket)){
                  sqDeletePendingOrder(exitTicket);
               }
               else if(PositionSelectByTicket(exitTicket)){
                  sqClosePositionAtMarket(exitTicket);
               }
            }
         }
         
         ZeroMemory(orderExits[a]);
      }
   }
}

//+------------------------------------------------------------------+

bool isExitLevelOrder(ulong ticket){
   
   for(int a=0; a<ArraySize(orderExits); a++){
      OrderExitLevel exit = orderExits[a];
      
      for(int i=0; i<ArraySize(exit.exits); i++){
         ulong exitTicket = exit.exits[i].ticket;
         if(exitTicket == ticket) return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+

double fixLotSize(string symbol, double size){
   string correctedSymbol = correctSymbol(symbol);
   double Smallest_Lot = SymbolInfoDouble(correctedSymbol, SYMBOL_VOLUME_MIN);
   double Largest_Lot = SymbolInfoDouble(correctedSymbol, SYMBOL_VOLUME_MAX);    
   double LotStep = SymbolInfoDouble(correctedSymbol, SYMBOL_VOLUME_STEP);

   double mod = MathMod(size, LotStep);
   double finalSize = size;
   
   if(MathAbs(mod - LotStep) > 0.000001){
      finalSize -= mod;
   } 

   if(finalSize < Smallest_Lot){
      Verbose("Calculated lot size (", DoubleToString(finalSize), ") is lower than minimum possible (", DoubleToString(Smallest_Lot), "). Using minimum lot size...");
      return Smallest_Lot;
   }
   else if(finalSize > Largest_Lot){
      Verbose("Calculated lot size (", DoubleToString(finalSize), ") is larger than maximum possible (", DoubleToString(Largest_Lot), "). Using maximum lot size...");
      return Largest_Lot;
   }
   else {
      return finalSize;
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// ExitMethods includes
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+


void sqCheckSLPT(ulong ticket, double sl, double pt){
   if(sl == 0 && pt == 0) return;
   
   double orderSL = 0;
   double orderPT = 0;
   
   bool found = false;
   
   if(PositionSelectByTicket(ticket)) {
      orderSL = PositionGetDouble(POSITION_SL);
      orderPT = PositionGetDouble(POSITION_TP);
      found = true;
   }
   else if(OrderSelect(ticket)){
      orderSL = OrderGetDouble(ORDER_SL);
      orderPT = OrderGetDouble(ORDER_TP);
      found = true;
   }
   else {
      //Check current position (used in netting mode)
      HistorySelect(startTime, TimeCurrent());
      
      if(HistoryDealSelect(ticket)){
          long positionTicket = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
          
          if(PositionSelectByTicket(positionTicket)){
              ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
              ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE) HistoryDealGetInteger(ticket, DEAL_TYPE);
              
              if((positionType == POSITION_TYPE_BUY && dealType == DEAL_TYPE_BUY) || 
                  (positionType == POSITION_TYPE_SELL && dealType == DEAL_TYPE_SELL)
              ){
                  orderSL = PositionGetDouble(POSITION_SL);
                  orderPT = PositionGetDouble(POSITION_TP);
                  found = true;
              }
          }
      }
   }
          
   if(!found){
      Print(StringFormat("No order or position with ticket %d found", IntegerToString(ticket)));
      return;
   }
   
   if(orderSL != sl || orderPT != pt){
      Print(StringFormat("SL or PT of order %d not set correctly. Order SL: %f (should be %f), Order PT: %f (should be %f). Modifying order...", ticket, orderSL, sl, orderPT, pt));
      
      sqSetSLPT(ticket, sl, pt);
   }
}

//+------------------------------------------------------------------+

void sqSetSLPT(ulong ticket, double sl, double pt){
   if(sl == 0 && pt == 0) return;
   
   ZeroMemory(mrequest);
   
   double openPrice = 0;
   bool isPosition = false;
   
   if(PositionSelectByTicket(ticket)) {
      isPosition = true;
      
      mrequest.position = ticket;
      mrequest.action = TRADE_ACTION_SLTP;
      mrequest.sl = sl > 0 ? sl : PositionGetDouble(POSITION_SL);
      mrequest.tp = pt > 0 ? pt : PositionGetDouble(POSITION_TP);
      
      openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   }
   else if(OrderSelect(ticket)){
      mrequest.order = ticket;
      mrequest.action = TRADE_ACTION_MODIFY;
      mrequest.price = OrderGetDouble(ORDER_PRICE_OPEN);
      mrequest.sl = sl > 0 ? sl : OrderGetDouble(ORDER_SL);
      mrequest.tp = pt > 0 ? pt : OrderGetDouble(ORDER_TP);
      
      openPrice = OrderGetDouble(ORDER_PRICE_OPEN);
   }
   else {
      //Check current position (used in netting mode)
      HistorySelect(startTime, TimeCurrent());
      
      if(HistoryDealSelect(ticket)){
          long positionTicket = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
          
          if(PositionSelectByTicket(positionTicket)){
              ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
              ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE) HistoryDealGetInteger(ticket, DEAL_TYPE);
              
              if((positionType == POSITION_TYPE_BUY && dealType == DEAL_TYPE_BUY) || 
                  (positionType == POSITION_TYPE_SELL && dealType == DEAL_TYPE_SELL)
              ){
                  isPosition = true;
      
                  mrequest.position = ticket;
                  mrequest.action = TRADE_ACTION_SLTP;
                  mrequest.sl = sl > 0 ? sl : PositionGetDouble(POSITION_SL);
                  mrequest.tp = pt > 0 ? pt : PositionGetDouble(POSITION_TP);
                  
                  openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
              }
          }
      }
          
      if(!isPosition){
         Print(StringFormat("No order or position with ticket %d found", IntegerToString(ticket)));
         return;
      }
   }
   
   if(!isPosition && mrequest.sl == openPrice) {
      Print("SL is as same as order price, cannot set it, so we'll delete the order!");
      if(!closeOrder(ticket)) {
         Print("Warning! Cannot delete order and SL/PT was not set! Error: ", IntegerToString(GetLastError()));
      }

      return;
   }
   
   //--- setting request
   mrequest.symbol = isPosition ? PositionGetString(POSITION_SYMBOL) : OrderGetString(ORDER_SYMBOL);
   mrequest.magic = isPosition ? PositionGetInteger(POSITION_MAGIC) : OrderGetInteger(ORDER_MAGIC);   
   mrequest.sl = sqFixMarketPrice(mrequest.sl, mrequest.symbol);   
   mrequest.tp = sqFixMarketPrice(mrequest.tp, mrequest.symbol);
   
   //--- action and return the result
   if(!OrderSend(mrequest, mresult)){
      Print("Cannot set order SL/PT. Error: ", IntegerToString(GetLastError()));
      
      if(sl > 0){
          if(isPosition){
              if(!sqClosePositionAtMarket(ticket)){
                  Print("Cannot close position and SL is not set! Error: ", IntegerToString(GetLastError()));
              }
          }  
          else {
              if(!closeOrder(ticket)){
                  Print("Cannot close order and SL is not set! Error: ", IntegerToString(GetLastError()));
              }
          }
      }
   }
}

double getOrderOpenPrice(ulong ticket, double requestedPrice){
   if(OrderSelect(ticket)){
      return OrderGetDouble(ORDER_PRICE_OPEN);
   }
   else if(PositionSelectByTicket(ticket)){
      return PositionGetDouble(POSITION_PRICE_OPEN);
   }
   else return requestedPrice;
}

// Move Stop Loss to Break Even
void sqManageSL2BE(ulong ticket) {
   if(!PositionSelectByTicket(ticket)){
       Verbose("Cannot select position with ticket ", IntegerToString(ticket));
       return;
   }
                                                                         
   valueIdentificationSymbol = PositionGetString(POSITION_SYMBOL); 
   int symbolDigits = (int) SymbolInfoInteger(valueIdentificationSymbol, SYMBOL_DIGITS);
   double moveSLAtValue = NormalizeDouble(sqGetValueByIdentification( sqGetMoveSL2BE(ticket) ), symbolDigits);

   if(moveSLAtValue > 0) {
      double newSL = 0;
      int error;

      int valueType = sqGetMoveSL2BEType(ticket);
      ENUM_POSITION_TYPE orderType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);

      if(orderType == POSITION_TYPE_BUY) {
         if(valueType == SLPTTYPE_RANGE) {
            moveSLAtValue = NormalizeDouble(sqGetBid(NULL) - moveSLAtValue, symbolDigits);
         }
      } else {
         if(valueType == SLPTTYPE_RANGE) {
            moveSLAtValue = NormalizeDouble(sqGetAsk(NULL) + moveSLAtValue, symbolDigits);
         }
      }
      
      double addPips = NormalizeDouble(sqGetValueByIdentification(sqGetSL2BEAddPips(ticket)) + 0.0000000001, symbolDigits);
      double currentSL = NormalizeDouble(PositionGetDouble(POSITION_SL), symbolDigits);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN); 
      double takeProfit = PositionGetDouble(POSITION_TP);

      if(orderType == POSITION_TYPE_BUY) {
         newSL = NormalizeDouble(openPrice + addPips, symbolDigits);
         
         if (openPrice <= moveSLAtValue && (currentSL == 0 || currentSL < newSL)) {
            Verbose("Moving SL 2 BE for order with ticket: ", IntegerToString(ticket), " to :", DoubleToString(newSL));
            if(!OrderModify(ticket, newSL, takeProfit)) {
               error = GetLastError();
               Verbose("Failed, error: ", IntegerToString(error), " - ", ErrorDescription(error),", Ask: ", DoubleToString(sqGetAsk(NULL)), ", Bid: ", DoubleToString(sqGetBid(NULL)), " Current SL: ",  DoubleToString(currentSL));
            }
         }

      } else { // orderType == OP_SELL
         newSL = NormalizeDouble(openPrice - addPips, symbolDigits);
         
         if (openPrice >= moveSLAtValue && (currentSL == 0 || currentSL > newSL)) {
            Verbose("Moving SL 2 BE for order with ticket: ", IntegerToString(ticket), " to :", DoubleToString(newSL));
            if(!OrderModify(ticket, newSL, takeProfit)) {
               error = GetLastError();
                Verbose("Failed, error: ", IntegerToString(error), " - ", ErrorDescription(error),", Ask: ", DoubleToString(sqGetAsk(NULL)), ", Bid: ", DoubleToString(sqGetBid(NULL)), " Current SL: ",  DoubleToString(currentSL));
            }
         }
      }
   }
}
// Trailing Stop
void sqManageTrailingStop(ulong ticket) {
   if(!PositionSelectByTicket(ticket)){
       Verbose("Cannot select position with ticket ", IntegerToString(ticket));
       return;
   }
                                                                                            
   valueIdentificationSymbol = PositionGetString(POSITION_SYMBOL); 
   int symbolDigits = (int) SymbolInfoInteger(valueIdentificationSymbol, SYMBOL_DIGITS);

   double tsValue = NormalizeDouble(sqGetValueByIdentification( sqGetTrailingStop(ticket) ), symbolDigits);
   
   if(tsValue > 0) {
      double plValue;
      int error;

      int valueType = sqGetTrailingStopType(ticket);
      ENUM_POSITION_TYPE orderType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);

      if(orderType == POSITION_TYPE_BUY) {
         if(valueType == SLPTTYPE_RANGE) {
            tsValue = NormalizeDouble(sqGetBid(NULL) - tsValue, symbolDigits);
         }
      } else {
         if(valueType == SLPTTYPE_RANGE) {
            tsValue = NormalizeDouble(sqGetAsk(NULL) + tsValue, symbolDigits);
         }
      }
      
      double tsActivation = NormalizeDouble(sqGetValueByIdentification(sqGetTSActivation(ticket)), symbolDigits);
      double currentSL = NormalizeDouble(PositionGetDouble(POSITION_SL), symbolDigits);       
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN); 
      double takeProfit = PositionGetDouble(POSITION_TP);
      
      if(orderType == POSITION_TYPE_BUY) {
         plValue = NormalizeDouble(sqGetBid(NULL) - openPrice, symbolDigits);

         if (plValue >= tsActivation && (currentSL == 0 || currentSL < tsValue)) {
            Verbose("Moving trailing stop for order with ticket: ", IntegerToString(ticket), " to :", DoubleToString(tsValue));
            if(!OrderModify(ticket, tsValue, takeProfit)) {
               error = GetLastError();
               Verbose("Failed, error: ", IntegerToString(error), " - ", ErrorDescription(error),", Ask: ", DoubleToString(sqGetAsk(NULL)), ", Bid: ", DoubleToString(sqGetBid(NULL)), " Current SL: ",  DoubleToString(currentSL));
            }
         }
      } else { // orderType == OP_SELL
         plValue = NormalizeDouble(openPrice - sqGetAsk(NULL), symbolDigits);

         if (plValue >= tsActivation && (currentSL == 0 || currentSL > tsValue)) {
            Verbose("Moving trailing stop for order with ticket: ", IntegerToString(ticket), " to :", DoubleToString(tsValue));
            if(!OrderModify(ticket, tsValue, takeProfit)) {
               error = GetLastError();
               Verbose("Failed, error: ", IntegerToString(error), " - ", ErrorDescription(error),", Ask: ", DoubleToString(sqGetAsk(NULL)), ", Bid: ", DoubleToString(sqGetBid(NULL)), " Current SL: ",  DoubleToString(currentSL));
            }
         }
      }
   }
}
void sqManageExitAfterXBars(ulong ticket) {
   if(!PositionSelectByTicket(ticket)){
       Verbose("Exit after bars - Cannot select position with ticket ", IntegerToString(ticket));
       return;
   }

   int exitBars = sqGetExitAfterXBars(ticket);
   if(exitBars > 0) {
      if (sqGetOpenBarsForOrder(exitBars+10, PositionGetInteger(POSITION_TIME)) >= exitBars) {
         Verbose("Exit After ", IntegerToString(exitBars), " bars - closing order with ticket: ", IntegerToString(ticket));
         if(!sqClosePositionAtMarket(ticket)){
            Verbose("Closing position failed, error: ", IntegerToString(GetLastError()), " - ", ErrorDescription(GetLastError()));
         }
      }
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Trading Options includes
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

class CTradingOption {
public:
   virtual bool onBarUpdate() = 0;
};

//+------------------------------------------------------------------+


class CExitAtEndOfDay : public CTradingOption {
   private:
	  datetime dailyEODExitTime;
	  datetime EODTime;           
    bool closedThisDay;

   public:
      CExitAtEndOfDay() {
         dailyEODExitTime = D'1970.01.01';
         EODTime = D'1970.01.01';         
         closedThisDay = false;
      }

      //+----------------------------------------------+

      virtual bool onBarUpdate() {
        if(!ExitAtEndOfDay) {
		      return(true);
	      }                   
                             
        onTick();

        if(!_sqIsBarOpen) {
           return(true);
        }
        
	      datetime currentTime = TimeCurrent();

	      if(currentTime > EODTime) {
	         //it is a new day
		      initTimesForCurrentDay(currentTime);
	      }

	      if(currentTime >= dailyEODExitTime) {
		      // returning false means there will be no more processing on this tick
	        // this is what we want because we don't want to be trading after close of all positions
		      return(false); 
	      }

	      return(true);
      }       
        
	   //------------------------------------------------------------------------

     virtual void onTick() {
        if(!ExitAtEndOfDay) {
		      return;
	      }
        
        datetime currentTime = TimeCurrent();
        datetime currentTimeDayStart = SQTime.correctDayStart(currentTime);     
				datetime currentTimeDayEnd = SQTime.correctDayEnd(currentTime);
        
        if(!closedThisDay && currentTime >= dailyEODExitTime) {
          // we should close all positions at midnight, so close them at the first tick of a new day
          
          //Close open positions. If there was a gap at the end of a day, close only positions opened before current day start
          for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
             ulong positionTicket = PositionGetTicket(cc);
        
             if (PositionSelectByTicket(positionTicket) && 
                checkMagicNumber(PositionGetInteger(POSITION_MAGIC)) &&
                (currentTimeDayEnd == EODTime || PositionGetInteger(POSITION_TIME) < currentTimeDayStart)
             ) {
                 Verbose("Exit At End Of Day - Closing position...");
                 sqClosePositionAtMarket(positionTicket);
             }
          }
          
          //Close pending orders
          for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
            ulong orderTicket = OrderGetTicket(cc);
       
            if (OrderSelect(orderTicket) && 
                checkMagicNumber(OrderGetInteger(ORDER_MAGIC))
            ) {                                     
               Verbose("Exit At End Of Day - Closing order...");
               closeOrder(orderTicket);
            }
          } 
           
			    closedThisDay = true;
	      }
          
     }

      //+----------------------------------------------+

      void initTimesForCurrentDay(datetime currentTime) {
	      // set end time of the current day (so that we now when new day starts)
	      EODTime = SQTime.correctDayEnd(currentTime);

	      // set time of EOD
	      if(EODExitTime == "00:00" || EODExitTime == "0:00"){
	         dailyEODExitTime = EODTime;
	      }
	      else {
	         dailyEODExitTime = SQTime.setHHMM(currentTime, EODExitTime);
	      }
	      
	      closedThisDay = false;
      }
};

// create variable for class instance (required)
CExitAtEndOfDay* objExitAtEndOfDay;




class CExitOnFriday : public CTradingOption {
   private:
      datetime thisFridayExitTime;
      datetime thisSundayBeginTime;  
      datetime EOFDayTime;   
      bool closedThisWeek;

   public:
      CExitOnFriday() {
         thisFridayExitTime = D'1970.01.01';
         thisSundayBeginTime = D'1970.01.01';
         closedThisWeek = false;
      }

      //+----------------------------------------------+

      virtual bool onBarUpdate() {
         if(!ExitOnFriday) {
	  		    return true;
         }
         
         onTick();
         
         if(!_sqIsBarOpen) {
            return(true);
         }

         MqlDateTime timeStruct;
         datetime currentTime = TimeCurrent(timeStruct);

         if(thisFridayExitTime < 100) {
            initFridayExitTime(currentTime, 0);
         }
         
         if(currentTime < thisFridayExitTime) {
            // trade normally
            return true;
         }
         
         if(currentTime < thisSundayBeginTime) {
    		   // do not allow opening new positions until sunday.
   			   // returning false means there will be no more processing on this tick.
   			   // this is what we want because we don't want to be trading after close of all positions
   			   return false;
    		}
         else {
            // new week starting
            initFridayExitTime(currentTime, timeStruct.day_of_week == 0 ? 1 : 0); 
            return true;
         }
      }           
        
	   //------------------------------------------------------------------------

     virtual void onTick() {
        if(!ExitOnFriday) {
	  		    return;
        }
        
        datetime currentTime = TimeCurrent();            
        datetime currentTimeDayStart = SQTime.correctDayStart(currentTime);      
				datetime currentTimeDayEnd = SQTime.correctDayEnd(currentTime);

    		if(!closedThisWeek && currentTime >= thisFridayExitTime) {
   				 // time is over friday closing time, we should close the positions
   				 
           //Close open positions. If there was a gap at the end of a day, close only positions opened before current day start
          for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
             ulong positionTicket = PositionGetTicket(cc);
        
             if (PositionSelectByTicket(positionTicket) && 
                checkMagicNumber(PositionGetInteger(POSITION_MAGIC)) &&
                (currentTimeDayEnd == EOFDayTime || PositionGetInteger(POSITION_TIME) < currentTimeDayStart)
             ) {
                 Verbose("Exit On Friday - Closing position...");
                 sqClosePositionAtMarket(positionTicket);
             }
          }
          
          //Close pending orders
          for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
            ulong orderTicket = OrderGetTicket(cc);
       
            if (OrderSelect(orderTicket) && 
                checkMagicNumber(OrderGetInteger(ORDER_MAGIC))
            ) {
               Verbose("Exit On Friday - Closing order...");
               closeOrder(orderTicket);
            }
          } 
           
   				 closedThisWeek = true;
    		} 
     }

      //+----------------------------------------------+

      void initFridayExitTime(datetime currentTime, int addDays) {
         if(addDays > 0) {
			    thisFridayExitTime = SQTime.addDays(currentTime, addDays);
	      } else {
			    thisFridayExitTime = currentTime;
	      }
	
	      // set time of EOD 
	      thisFridayExitTime = SQTime.setDayOfWeek(thisFridayExitTime, (FridayExitTime == "00:00" || FridayExitTime == "0:00") ? SATURDAY : FRIDAY);
	      thisFridayExitTime = SQTime.setHHMM(thisFridayExitTime, FridayExitTime);	
	      
        EOFDayTime = SQTime.correctDayEnd(thisFridayExitTime);
       
	      thisSundayBeginTime = SQTime.setDayOfWeek(currentTime, SUNDAY);
	      thisSundayBeginTime = SQTime.correctDayStart(thisSundayBeginTime);
        
        closedThisWeek = false;
      }
};

// create variable for class instance (required)
CExitOnFriday* objExitOnFriday;

class CLimitTimeRange : public CTradingOption {
   private:
      datetime dailySignalTimeRangeFrom;
      datetime dailySignalTimeRangeTo;
      bool closedThisDay;
                                          
   public:
      CLimitTimeRange() {
         closedThisDay = false;
      }

      //+----------------------------------------------+

      virtual bool onBarUpdate() {     
	    if(!LimitTimeRange) {
		    return true;
	    }
                                
        onTick();
           
        if(!_sqIsBarOpen) {
           return true;
        }
        
	    datetime currentTime = TimeCurrent();
	
	    if(currentTime > dailySignalTimeRangeTo) {
		    // it is new day
		    initTimesForCurrentDay(currentTime);
	    }

	    if(currentTime < dailySignalTimeRangeFrom || currentTime >= dailySignalTimeRangeTo) {
		    // time is outside given range
		    // returning false means there will be no more processing on this tick
		   	// this is what we want because we don't want to be trading outside of this time range
		    
		    return false; 
	    }
	
	    return true;
     }
        
	 //------------------------------------------------------------------------

     virtual void onTick() {
        if(!LimitTimeRange) {
			    return;
		    }
        
        datetime currentTime = TimeCurrent();
        if(!closedThisDay && ExitAtEndOfRange && currentTime >= dailySignalTimeRangeTo) {
		  if(OrderTypeToExit != 2) { // not pending only
            //Close open positions
            for (int cc = PositionsTotal() - 1; cc >= 0; cc--) {
               ulong positionTicket = PositionGetTicket(cc);
         
               if (PositionSelectByTicket(positionTicket) && 
                  checkMagicNumber(PositionGetInteger(POSITION_MAGIC))
               ) {
                   Verbose("Limit Time Range - Closing position...");
                   sqClosePositionAtMarket(positionTicket);
               }
            }
          }
          
          if(OrderTypeToExit != 1) { // not live only
            //Close pending orders
            for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
              ulong orderTicket = OrderGetTicket(cc);
       
              if (OrderSelect(orderTicket) && 
                  checkMagicNumber(OrderGetInteger(ORDER_MAGIC))
              ) {
                 Verbose("Limit Time Range - Closing order...");
                 closeOrder(orderTicket);
              }
            }
          }  
		  
          closedThisDay = true;
		}
     }

	 //------------------------------------------------------------------------

	 void initTimesForCurrentDay(datetime currentTime) {
	   // set time of range open 
	   dailySignalTimeRangeFrom = SQTime.setHHMM(currentTime, SignalTimeRangeFrom);
		dailySignalTimeRangeTo = SQTime.setHHMM(currentTime, SignalTimeRangeTo);
      
      int timeFrom = getHHMM(SignalTimeRangeFrom);
      int timeTo = getHHMM(SignalTimeRangeTo);

      if(timeFrom >= timeTo){
         if(getSQTime(currentTime) < timeTo){
            dailySignalTimeRangeFrom = SQTime.addDays(dailySignalTimeRangeFrom, -1);
         }
         else {
            dailySignalTimeRangeTo = SQTime.addDays(dailySignalTimeRangeTo, 1);
         }
      }
      else {
         if(currentTime > dailySignalTimeRangeTo) {
				dailySignalTimeRangeFrom = SQTime.addDays(dailySignalTimeRangeFrom, 1);
				dailySignalTimeRangeTo = SQTime.addDays(dailySignalTimeRangeTo, 1);
			}
      }

	   closedThisDay = false;
	 }
};


// create variable for class instance (required)
CLimitTimeRange* objLimitTimeRange;



class CMaxTradesPerDay : public CTradingOption {
   private:
      datetime openTimeToday;
      datetime EODTime;
      bool reachedLimitToday;
      
   public:
      CMaxTradesPerDay() {
         EODTime = D'1970.01.01';
      }

      //+----------------------------------------------+

      virtual bool onBarUpdate() {
         if(MaxTradesPerDay <= 0) {
            return true;
         }
		
         datetime currentTime = TimeCurrent();

         if(currentTime > EODTime) {
            // it is new day
            initTimeForCurrentDay(currentTime);
         }		
		
		   if(reachedLimitToday) {
		      return false;
		   }
		   
         if(getNumberOfTradesToday() >= MaxTradesPerDay) {
            reachedLimitToday = true;
            return(false);
         }
		
         return true;
      }

      //------------------------------------------------------------------------

      void initTimeForCurrentDay(datetime currentTime) {
			// set end time of the current day (so that we now when new day starts)
         EODTime = SQTime.correctDayEnd(currentTime);

         openTimeToday = SQTime.correctDayStart(currentTime);
         
         reachedLimitToday = false;
      }
      
      //------------------------------------------------------------------------

		int getNumberOfTradesToday() {
			int todayTradesCount = 0;

			HistorySelect(openTimeToday, TimeCurrent());
			
       //History orders not filled
       for(int i=HistoryOrdersTotal() - 1; i>=0; i--) {
         ulong ticket = HistoryOrderGetTicket(i);
         ENUM_ORDER_STATE state = (ENUM_ORDER_STATE) HistoryOrderGetInteger(ticket, ORDER_STATE);
         
         if(HistoryOrderSelect(ticket) && 
             checkMagicNumber(HistoryOrderGetInteger(ticket, ORDER_MAGIC)) &&
             HistoryOrderGetInteger(ticket, ORDER_TIME_SETUP) >= openTimeToday &&
             (state != ORDER_STATE_FILLED && state != ORDER_STATE_PARTIAL)
         ) {
            todayTradesCount++;
         }
       }
                                   
       //History deals
       for(int i=HistoryDealsTotal() - 1; i>=0; i--) {
         ulong ticket = HistoryDealGetTicket(i);
         
         if(HistoryDealSelect(ticket) && 
            checkMagicNumber(HistoryDealGetInteger(ticket, DEAL_MAGIC)) &&
            HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN
         ){ 
            if(HistoryDealGetInteger(ticket, DEAL_TIME) >= openTimeToday){
               todayTradesCount++;
            }
         }
       }
       
       //Pending orders
       for(int i=OrdersTotal() - 1; i>=0; i--) {
         ulong ticket = OrderGetTicket(i);
         
         if(OrderSelect(ticket) && 
            checkMagicNumber(OrderGetInteger(ORDER_MAGIC)) &&
            OrderGetInteger(ORDER_TIME_SETUP) >= openTimeToday
         ){ 
            todayTradesCount++;
         }
       }
   
			return todayTradesCount;
		}      
};

// create variable for class instance (required)
CMaxTradesPerDay* objMaxTradesPerDay;


class CMinMaxSLPT : public CTradingOption {
   private:
      
   public:
      CMinMaxSLPT() {
      }

      //+----------------------------------------------+

      virtual bool onBarUpdate() {
         return true;
      }
};

// create variable for class instance (required)
CMinMaxSLPT* objMinMaxSLPT;

// Money Management - Fixed Size used

//+----------------------------- Include from /MetaTrader5/CustomFunctions/CustomFunctions.mq5 -------------------------------------+

//+------------------------------------------------------------------+
//+ Custom functions
//+
//+ Here you can define your own custom functions that can be used
//+ in Algo Wizard.
//+ The functions can perform some action (for example draw on chart
//+ or manipulate with orders) or they can return value that
//+ can be used in comparison.
//+
//+ Note! All the functions below must be in valid MQL code!
//+ Contents of this file will be appended to your EA code.
//+
//+------------------------------------------------------------------+

double exampleFunction(double value) {
   return(2 * value);
}

//+----------------------------- Include from /MetaTrader5/CustomFunctions/SessionOHLC.mq5 -------------------------------------+

double SessionOpen(int startHours, int startMinutes, int daysAgo){
   return getSessionPrice(1, startHours, startMinutes, startHours, startMinutes, daysAgo);
}

//+------------------------------------------------------------------+

double SessionHigh(int startHours, int startMinutes, int endHours, int endMinutes, int daysAgo){
   return getSessionPrice(2, startHours, startMinutes, endHours, endMinutes, daysAgo);
}

//+------------------------------------------------------------------+

double SessionLow(int startHours, int startMinutes, int endHours, int endMinutes, int daysAgo){
   return getSessionPrice(3, startHours, startMinutes, endHours, endMinutes, daysAgo);
}

//+------------------------------------------------------------------+

double SessionClose(int endHours, int endMinutes, int daysAgo){
   return getSessionPrice(4, endHours, endMinutes, endHours, endMinutes, daysAgo);
}

//+------------------------------------------------------------------+

double getSessionPrice(int type, int startHours, int startMinutes, int endHours, int endMinutes, int daysShift){
   int totalEndDaysShift = daysShift;
   int totalStartDaysShift = daysShift;
   
   datetime currentTime = mrate[1].time;
   
   MqlDateTime strTime;
   TimeToStruct(currentTime, strTime);
   
   int currentHHMM = strTime.hour * 100 + strTime.min;
   int startHHMM = startHours * 100 + startMinutes;
   int endHHMM = endHours * 100 + endMinutes;
   
   if(type == 1){
      if(currentHHMM < startHHMM){
         totalEndDaysShift++;
         totalStartDaysShift++;
      }
   }
   else if(type == 4){
      if(currentHHMM >= startHHMM){
         totalEndDaysShift--;
         totalStartDaysShift--;
      }
   }
   else {
      if(startHHMM < endHHMM){
         if(currentHHMM < startHHMM){
            totalEndDaysShift++;
            totalStartDaysShift++;
         }
      }
      else {
         if(currentHHMM < startHHMM){
            totalStartDaysShift++;
         }
         else {
            totalEndDaysShift--;
         }
      }
   }
   
   int totalBars = Bars(NULL, 0);
   int currentIndex = 0;
   int lastDayOfYear = strTime.day_of_year;
   int daysAgo = 0;
   
   datetime timeArray[1];
   double valueArray[1];
   
   double highest = -1000000000;
   double lowest = 1000000000;
   
   while(currentIndex < totalBars){
      CopyTime(NULL, 0, currentIndex, 1, timeArray);
      datetime time = timeArray[0];
      TimeToStruct(time, strTime);
      int hhmm = strTime.hour * 100 + strTime.min;
      int curDayOfYear = strTime.day_of_year;
      
      if(curDayOfYear != lastDayOfYear) {
			lastDayOfYear = curDayOfYear;
			daysAgo++;
		}
		
		if(type == 2 || type == 3){
		   if(totalStartDaysShift == totalEndDaysShift){
		      if(daysAgo == totalEndDaysShift && hhmm < endHHMM && hhmm >= startHHMM) {
      		   if(type == 2){
      		      CopyHigh(NULL, 0, currentIndex, 1, valueArray);
		            highest = MathMax(highest, valueArray[0]);
      		   }
      		   else {
      		      CopyLow(NULL, 0, currentIndex, 1, valueArray);
		            lowest = MathMin(lowest, valueArray[0]);
      		   }
      		}
		   }
		   else {
		      if((daysAgo == totalEndDaysShift && hhmm < endHHMM) || (daysAgo == totalStartDaysShift && hhmm >= startHHMM)) {
      		   if(type == 2){
      		      CopyHigh(NULL, 0, currentIndex, 1, valueArray);
		            highest = MathMax(highest, valueArray[0]);
      		   }
      		   else {
      		      CopyLow(NULL, 0, currentIndex, 1, valueArray);
		            lowest = MathMin(lowest, valueArray[0]);
      		   }
      		}
		   }
		}
		
		if(daysAgo > totalStartDaysShift || (daysAgo == totalStartDaysShift && ((type < 4 && hhmm <= startHHMM) || (type == 4 && hhmm < endHHMM)))) {
		   switch(type){
		      case 1: 
		         CopyOpen(NULL, 0, currentIndex, 1, valueArray);
		         return valueArray[0];
		      case 2: return highest != -1000000000 ? highest : 0;
		      case 3: return lowest != 1000000000 ? lowest : 0;
		      case 4:
		         CopyClose(NULL, 0, currentIndex, 1, valueArray);
		         return valueArray[0];
		      default: return 0;
		   }
		}
		
		currentIndex++;
   }
   
   switch(type){
      case 2: return highest != -1000000000 ? highest : 0;
      case 3: return lowest != 1000000000 ? lowest : 0;
      default: return 0;
   }
}
