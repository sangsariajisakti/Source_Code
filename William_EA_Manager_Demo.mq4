//+------------------------------------------------------------------+
//|                                              William_Manager.mq4 |
//|                                                       William B. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "William B."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//--- input parameters
input int      Magic=080223;//Magic Number For This EA
input string   Comment="William_Manager";//Comment
input bool     EquityProtect=true;//Set True to Protect Account Equity
input double   EquityProtectLevel=5;//Don't Let Equity Drop by {Percentage}


double protectAmount,equityNow,eqStart,dailyPL;
string pushed;
bool sent, closed;
   datetime serverTime;
   datetime midnight;
   datetime midnightTomorrow;
   //datetime thawTime=midnightTomorrow+startHour*3600;
   //datetime freezeTime=midnight+stopHour*3600;
datetime d1=D'2023.01.22 12:30:27';  // Year Month Day Hours Minutes Seconds
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   eqStart = AccountBalance();
   protectAmount = AccountBalance()*(EquityProtectLevel/100);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   serverTime = TimeCurrent(); //last known server time
   midnight=serverTime-(serverTime%(PERIOD_D1*60));
   midnightTomorrow=midnight+PERIOD_D1*60;
  
  
  
  
  
//---
  dailyPL = totalHistPL()//loop historical orders from day start
          + floatingPL(); //loop open orders
   
   
   if(AccountBalance() > eqStart){eqStart = AccountBalance();}
   protectAmount = eqStart*(EquityProtectLevel/100);
   
   
  Comment("Equity Protection at ",protectAmount*-1, " current Balance ",AccountBalance(), "\nDaily PL ",dailyPL,"\ntotalHistPL ",totalHistPL(), " floatingPL ",floatingPL(), "\nreset time ", midnightTomorrow+60);
  if(EquityProtect &&  dailyPL < (protectAmount*-1)){  // stop all trading
   CloseAllOrders(); 
    closed = true;    
   } 
   
   
   if(TimeCurrent() == midnight+60 && closed) closed = false;
         
  }

//+------------------------------------------------------------------+
//| Calculate HISTORY Profit                                       |
//+------------------------------------------------------------------+
double totalHistPL (){

   double totalPL = 0;
   for(int i=OrdersHistoryTotal()-1; i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) {
            if(OrderCloseTime() >= midnight)
            totalPL += OrderProfit()+OrderSwap()+OrderCommission();
      }
   }// end for

   
   return(totalPL);

}

//+------------------------------------------------------------------+
//| Calculate FLOATING Profit                                        |
//+------------------------------------------------------------------+
double floatingPL()
  {

   double floatPl = 0;
   for(int pos = OrdersTotal() - 1; pos >= 0; pos --)

      if(OrderSelect(pos,SELECT_BY_POS)){
         floatPl +=  OrderProfit()+OrderSwap()+OrderCommission();
        }

   return(floatPl);
  }
  
void CloseAllOrders(){}