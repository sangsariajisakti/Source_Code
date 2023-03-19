//+------------------------------------------------------------------+
//|                                           Perfect-investment.mq4 |
//|                                                            Jehan |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright " JEHANZAIB.EXNESS@GMAIL.COM"
#property link      "https://one.exness-track.com/a/uqg67l1d"
#property version   "3.0"
#property description "MANAGEMENT ACCOUNT ONLY WHATSAPP +923041704371/ 30% PROFIT SHARE"
#property strict


extern string __c1="----------------------------------";
extern string __lotsize = "Money management";
extern bool   MM        = FALSE;               
extern double Risk      = 2;                
extern double Lots      = 0.01;              
extern double LotDigits = 2;   


extern string __c2="----------------------------------";
extern double multiplier      = 1.5;
extern double inp12_ProfitAmountMoney = 0.4;
extern double maximaloss      = 0;
extern int    tradesperday    = 99;
extern bool   openonnewcandle = false;

  
extern string __c3="----------------------------------";
extern double spacePips       = 180;
extern int    spaceOrders     = 9;
extern double spaceLots       = 0.01;


extern string __c4="----------------------------------";
extern int     magicbuy        = 1;
extern string  buycomment      = "@ForexExpert99%Accuracy  ";
extern int     magicsell       = 2;
extern string  sellcomment     = " +923041704371  ";
   

extern string __c5="----------------------------------";
extern string __timeFilter="Timer filter (Hour 0-24 Minute 0-59)";
extern int     Start_Hour      = 0;
extern int     Start_Minute    = 1;
extern int     Finish_Hour     = 24;
extern int     Finish_Minute   = 0;

extern string __c6="----------------------------------";
extern string __entry1="Determine entry based on BOLLINGER";
extern bool    iaccEntry = false;

extern string __c7="----------------------------------";
extern bool    suspendtrades     = false;
extern bool    closeallsellsnow  = false;
extern bool    closeallbuysnow   = false;
extern bool    closeallnow       = false;

extern string __c8="----------------------------------";
extern bool    KeepTextOnTop     = true;//Disable the chart in foreground CrapTx setting so the candles do not obscure the text
extern int     DisplayX          = 50;
extern int     DisplayY          = 50;
extern int     fontSise          = 8;
extern string  fontName          = "Courier New";
extern color   colour            = White;
 
double totalprofit; 
bool   sellallowed=false;
bool   buyallowed=false;
bool   firebuy=true;
bool   firesell=true;
string stoptrading="0"; 
bool   validSetup=true;
string error;
int    DisplayCount      = 0;
int G_period_328 = 9;
int G_period_329 = 9;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if (Digits==3 || Digits==5)
   
   RemoveAllObjects();   
   validSetup=false;
   double minLots = MarketInfo(Symbol(),MODE_MINLOT) ;
   double maxLots = MarketInfo(Symbol(),MODE_MAXLOT) ;
   if (MM == true)
   {
      if (LotDigits<1 || LotDigits>3)
      {
         error="Invalid LotDigits";
         return 0;
      }
      
      if (Risk < 0.01 || Risk >100)
      {
         error="Invalid Risk";
         return 0;
      }
   }   
   
   if (Lots < minLots || Lots > maxLots  )
   {
      error="invalid LotSize";
      return 0;
   }
   if (multiplier < 0)
   {
      error="invalid multiplier";
      return 0;
   }
   
   
   if (Start_Hour < 0 || Start_Hour > 24)
   {
         error="Start_Hour invalid";
         return 0;
   }
   
   if (Start_Minute < 0 || Start_Minute > 59)
   {
         error="Start_Minute invalid";
         return 0;
   }
   if (Finish_Hour < 0 || Finish_Hour > 24)
   {
         error="Finish_Hour invalid";
         return 0;
   }
   if (Finish_Minute < 0 || Finish_Minute > 59)
   {
         error="Finish_Minute invalid";
         return 0;
   
   
      }
   
   
   validSetup=true;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void RemoveAllObjects()
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      if (StringFind(ObjectName(i),"EA-",0) > -1)  ObjectDelete(ObjectName(i));
   }
}

//+------------------------------------------------------------------+
//| Display                               |
//+------------------------------------------------------------------+
void Display(string text)
{
  string lab_str = "EA-" + IntegerToString(DisplayCount);  
  double ofset = -30;  
  
  ObjectCreate("EA-BG",OBJ_RECTANGLE_LABEL,0,0,0);
  ObjectSet("EA-BG", OBJPROP_XDISTANCE, DisplayX-100);
  ObjectSet("EA-BG", OBJPROP_YDISTANCE, DisplayY-100);
  ObjectSet("EA-BG", OBJPROP_XSIZE,0);
  ObjectSet("EA-BG", OBJPROP_YSIZE,0);
  ObjectSet("EA-BG", OBJPROP_BGCOLOR,C'50,50,50');
  ObjectSet("EA-BG", OBJPROP_BORDER_TYPE,BORDER_SUNKEN);
  ObjectSet("EA-BG", OBJPROP_CORNER,CORNER_LEFT_UPPER);
  ObjectSet("EA-BG", OBJPROP_STYLE,STYLE_SOLID);
  ObjectSet("EA-BG", OBJPROP_COLOR,clrWhite);
  ObjectSet("EA-BG", OBJPROP_WIDTH,1);
  ObjectSet("EA-BG", OBJPROP_BACK,false);

  ObjectCreate(lab_str, OBJ_LABEL, 0, 0, 0);
  ObjectSet(lab_str, OBJPROP_CORNER, 0);
  ObjectSet(lab_str, OBJPROP_XDISTANCE, DisplayX + ofset);
  ObjectSet(lab_str, OBJPROP_YDISTANCE, DisplayY+DisplayCount*(fontSise+5));
  ObjectSet(lab_str, OBJPROP_BACK, false);
  ObjectSetText(lab_str, text, fontSise, fontName, colour);
    
}

//------------------------------------------------------------------+
//------------------------------------------------------------------+
void SM(string message)
{
   DisplayCount++;
   Display(message);
      
}//End void SM()


//------------------------------------------------------------------+
// Draw error screen
//------------------------------------------------------------------+
void DisplayErrors()
{
   DisplayCount=0;
   colour=Red;
   SM("Trading turned OFF");
   SM("");
   SM("Invalid settings:");
   SM(error);
}
//------------------------------------------------------------------+
// Draw info screen
//------------------------------------------------------------------+
void ShowStatus()
{
   if(IsOptimization()) return;
  // if(IsTesting()) return;
   
   DisplayCount=0;
   
 
   double lotsTrading=0;
   int openTrades=0;
   double profitLoss=0; 
   for (int k = OrdersTotal();k >=0 ;k--)
   {  
      if (OrderSelect(k, SELECT_BY_POS))
      {
          if ( OrderSymbol() == Symbol() )
          {
               if (OrderMagicNumber() == magicbuy || OrderMagicNumber() == magicsell) 
               {
                  lotsTrading+=OrderLots();
                  openTrades=openTrades+1;
                  profitLoss += (OrderProfit() + OrderSwap() + OrderCommission());
               }
          }
      }
   }
   
   
   int wonTrades=0;
   int lostTrades=0;
   double profitToday=0;
   double profitYesterday=0;   
   double profitTotal=0;  
   double totalLotsTraded=0;
   double maxLotsizeUsed=0;
   double profitFactor=-1;
   double totalAmountWon=0;
   double totalAmountLost=0;
   datetime today     = TimeCurrent() ;
   datetime yesterday = TimeCurrent() - (60 * 60 * 24);
   for (int l=OrdersHistoryTotal();l >= 0;l--)
   {
      if(OrderSelect(l, SELECT_BY_POS,MODE_HISTORY))
      {
        if ( OrderSymbol() == Symbol() )
        {
           if ( OrderMagicNumber() == magicbuy || OrderMagicNumber() == magicsell )
           {
               totalLotsTraded += OrderLots();
               maxLotsizeUsed   = MathMax(maxLotsizeUsed, OrderLots());
               if (OrderProfit() > 0) wonTrades++;
               else lostTrades++;
               
               double orderProfit = (OrderProfit() + OrderSwap() + OrderCommission());
               if (orderProfit<0) totalAmountLost += orderProfit;
               else totalAmountWon += orderProfit;
               
               profitTotal += orderProfit;
               
               if( TimeDay   (OrderCloseTime()) == TimeDay(today) &&
                   TimeMonth (OrderCloseTime()) == TimeMonth(today) &&
                   TimeYear  (OrderCloseTime()) == TimeYear(today) )
               {
                  profitToday += orderProfit;
               }
               
               if( TimeDay  (OrderCloseTime()) == TimeDay(yesterday) &&
                   TimeMonth(OrderCloseTime()) == TimeMonth(yesterday) &&
                   TimeYear (OrderCloseTime()) == TimeYear(yesterday) )
               {
                  profitYesterday += orderProfit;
               }
            }
        }
      }
   }
   if (totalAmountWon!=0 && totalAmountLost!=0)
   {
      profitFactor=MathAbs(totalAmountWon / totalAmountLost);
   }
   
   double totalTradeCount=(wonTrades+lostTrades);
   
   SM("Account balance         : " + DoubleToString(AccountBalance(),2) +" " + AccountCurrency());
   SM("Account equity          : " + DoubleToString(AccountEquity(),2) +" " + AccountCurrency());
   SM("Account free margin     : " + DoubleToString(AccountFreeMargin(),2) +" " + AccountCurrency());
   SM("Account margin          : " + DoubleToString(AccountMargin(),2) +" " + AccountCurrency());
   
   SM("");
   SM("Open trades             : " + (GetBuyOrderCount()+GetSellOrderCount()) + " ( "+DoubleToString(profitLoss,2)+" "+AccountCurrency()+" )" );
   SM("         buy trades     : " + GetBuyOrderCount());
   SM("         sell trades    : " + GetSellOrderCount() );
   SM("         lots in trades : " + DoubleToString(lotsTrading, 2) + " lots");
   
   SM("");
   SM("Total trades today      : " + TradesToday()+" / "+tradesperday);
   SM("Total trades all time   : " + (wonTrades+lostTrades) + ", Won:"+wonTrades+" / Lost:"+lostTrades);
   double percentage=0;
   if (totalTradeCount >0) percentage=(wonTrades / totalTradeCount) * 100;
   SM("                winrate : " + DoubleToString( percentage, 2)+"%");
   SM("");
   SM("Profit today            : " + DoubleToString(profitToday, 2)+ " " + AccountCurrency() );
   SM("Profit yesterday        : " + DoubleToString(profitYesterday,2 )+ " " + AccountCurrency() );
   SM("Profit all time         : " + DoubleToString(profitTotal, 2)+ " " + AccountCurrency() );
   
   double payoff=0;
   if (totalTradeCount>0 ) payoff=profitTotal/totalTradeCount;
   SM("Payoff expectancy/trade : " + DoubleToString(payoff, 2)+ " " + AccountCurrency() );
   if (profitFactor>=0)
      SM("Profit factor           : " + DoubleToString(profitFactor, 2));
   else SM("");
   SM("");
   
   double averageLots=0;
   if (totalTradeCount >0) averageLots = totalLotsTraded / totalTradeCount;
   SM("Overall volume traded   : " + DoubleToString(totalLotsTraded, 2) +" lots");
   SM("Average volume/trade    : " + DoubleToString(averageLots, 2) +" lots");
   SM("Max volume traded       : " + DoubleToString(maxLotsizeUsed, 2) +" lots");
}



//------------------------------------------------------------------+
// Generic Money management code
//------------------------------------------------------------------+
double GetLotSize()
{
   double minlot    = MarketInfo(Symbol(), MODE_MINLOT);
   double maxlot    = MarketInfo(Symbol(), MODE_MAXLOT);
   double leverage  = AccountLeverage();
   double lotsize   = MarketInfo(Symbol(), MODE_LOTSIZE);
   double stoplevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
   double MinLots = 0.01; 
   double MaximalLots = 0.05;
   double lots = Lots;

   if(MM)
   {
      lots = NormalizeDouble(AccountFreeMargin() * Risk/100 / 1000.0, LotDigits);
      if(lots < minlot) lots = minlot;
      if (lots > MaximalLots) lots = MaximalLots;
      if (AccountFreeMargin() < Ask * lots * lotsize / leverage) 
      {
         Print("We have no money. Lots = ", lots, " , Free Margin = ", AccountFreeMargin());
         Comment("We have no money. Lots = ", lots, " , Free Margin = ", AccountFreeMargin());
      }
   }
   else lots=NormalizeDouble(Lots, Digits);
   return(lots);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
//Variables Globales 



class _externs
{
		public:
	static double inp12_ProfitAmountMoney;
};
double _externs::inp12_ProfitAmountMoney;




datetime        Fecha                   = D'2060.07.17 00:00';



void OnTick() {

        if(   TimeCurrent() >= Fecha ) {
 
        
                Alert(" La version demo ha caducado Acuda al vendedor +923041704371 ");
                return; 
}

   if (!validSetup) 
   {
      DisplayErrors();
      return;
   }
   
   int  ticketBuyOrder       =  GetTicketOfLargestBuyOrder();
   int  ticketSellOrder      =  GetTicketOfLargestSellOrder();
   bool isNewBar             =  IsNewBar();
   int  totalTradesDoneToday =  TradesToday();
   int  index;
   
   ShowStatus();
   
   if (GlobalVariableGet(stoptrading) == 1 && OrdersTotal() == 0 && CheckTradingTime() == true)
   {
      GlobalVariableSet(stoptrading,0);  
   }
   
   if (!iaccEntry)
   {
      if (iaccEntry == true)
      {
         firesell = true;
         firebuy  = true;  
      } 
   }
   
   // determine entry based on bollinger
   if (iaccEntry)
   {
      if (isNewBar==false)
      {
         firebuy  = false;
         firesell = false; 
        
        
          double icci = iCCI(NULL,PERIOD_M1,30,PRICE_CLOSE,0);
        double irsi = iRSI(NULL,PERIOD_M1,16,PRICE_CLOSE,0);
        double iwill = iWPR(NULL,PERIOD_CURRENT,110,0);
        double idemak = iDeMarker(NULL,PERIOD_M1,40,0);
        double istoch1 = iStochastic(NULL,PERIOD_M1,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
         double istoch2 = iStochastic(NULL,PERIOD_M1,5,3,3,MODE_SMA,0,MODE_MAIN,0);
        double iao = iAO(NULL,PERIOD_CURRENT,0);
        double iacc = iAC(NULL,PERIOD_M1,0);
        double iacc2 = iAC(NULL,PERIOD_M5,0);
        double ibulls = iBullsPower(NULL,PERIOD_M1,14,PRICE_OPEN,0);
         double ibears = iBearsPower(NULL,PERIOD_M1,14,PRICE_OPEN,0);
          double ibulls2 = iBullsPower(NULL,PERIOD_M5,14,PRICE_OPEN,0);
         double ibears2 = iBearsPower(NULL,PERIOD_M5,14,PRICE_OPEN,0);
         double ibulls3 = iBullsPower(NULL,PERIOD_M15,14,PRICE_OPEN,0);
         double ibears3 = iBearsPower(NULL,PERIOD_M15,14,PRICE_OPEN,0);
        
        
        
                 
      
            
       
        if(   ibears  < 0 && ibears2 < 0  )
         {
           firesell = true;
            firebuy = false;
        }
         if(   ibulls  > 0 && ibulls2 > 0  )
         {
           firesell = false;
            firebuy = true;
        }
       
        if(   ibears  < 0 && ibulls < 0  )
         {
           firesell = true;
            firebuy = false;
        }
         if(   ibulls  > 0 && ibears > 0   )
         {
           firesell = false;
            firebuy = true;
        }
         if(   ibears2  < 0 && ibulls2 < 0  )
         {
           firesell = true;
            firebuy = false;
        }
         if(   ibulls2  > 0 && ibears2 > 0  )
         {
           firesell = false;
            firebuy = true;
        }
      
       
      
        
      }
   }
   
   if (tradesperday > totalTradesDoneToday && CheckTradingTime() && ticketBuyOrder==0 && suspendtrades==false && firebuy && closeallnow==false && GlobalVariableGet(stoptrading)==0)
   {
     index = OrderSend (Symbol(),OP_BUY, GetLotSize() , Ask , 3, 0, 0, buycomment, magicbuy, 0, Blue); 
     if (index >= 0)
     {
         firebuy = true; 
     }
   }         

   if ((openonnewcandle == 1 && isNewBar == true && ticketBuyOrder != 0)|| (openonnewcandle == 0 && ticketBuyOrder != 0))
   {
      if ( OrderSelect(ticketBuyOrder, SELECT_BY_TICKET))
      {
         double orderLots  = OrderLots();
         double orderPrice = OrderOpenPrice(); 
         if( Ask <= orderPrice - spacePips * Point() && GetBuyOrderCount() < spaceOrders)
         {
            if (multiplier  > 0) 
            {
               index = OrderSend (Symbol(), OP_BUY, NormalizeDouble(orderLots * multiplier,2 ), Ask, 3, 0, 0, buycomment, magicbuy, 0, Blue); 
            }
            else if (multiplier == 0) 
            {
              index = OrderSend (Symbol(), OP_BUY, spaceLots, Ask, 1, 0, 0, buycomment, magicbuy, 0, Blue);
            }
         }  
         
        
       
      }
   }
    
   // --------------------------------------------
   // sell orders
   // --------------------------------------------
   totalTradesDoneToday = TradesToday();
   if (tradesperday > totalTradesDoneToday && CheckTradingTime() == true && ticketSellOrder == 0 && suspendtrades == false && firesell == true && closeallnow == false && GlobalVariableGet(stoptrading) == 0)
   {
     index = OrderSend (Symbol(), OP_SELL, GetLotSize(), Bid, 3, 0, 0, sellcomment, magicsell, 0, Red);  
     if (index >= 0)
     {
         firesell = true;
     }
   }

   // manage sell order
   if ((openonnewcandle == 1 && isNewBar==true && ticketSellOrder !=0 )|| (openonnewcandle == 0 && ticketSellOrder != 0))
   {
      if ( OrderSelect(ticketSellOrder, SELECT_BY_TICKET))
      {
         double orderLots  = OrderLots();
         double orderPrice = OrderOpenPrice(); 
         if( Bid >= orderPrice + spacePips * Point() && GetSellOrderCount() < spaceOrders)
         {
           if (multiplier  > 0) 
            {
               index = OrderSend(Symbol(), OP_SELL, NormalizeDouble(orderLots * multiplier, 2), Bid, 3, 0, 0, sellcomment, magicsell, 0, Red); 
            }
            else if (multiplier == 0)
            {
                index = OrderSend(Symbol(), OP_SELL, spaceLots, Bid, 3, 0, 0, sellcomment, magicsell, 0, Red);
            
          
        
            }
         } 
      }
   } 
   
   double profitBuyOrders=0;
   for(int k=OrdersTotal()-1; k >=0; k--)
   {
      if ( OrderSelect(k,SELECT_BY_POS))
      {
         if (Symbol()==OrderSymbol() && OrderType()==OP_BUY && OrderMagicNumber() == magicbuy)
         {
            profitBuyOrders = profitBuyOrders + OrderProfit() + OrderSwap() + OrderCommission();
         }
      }
   }

   
   
   double profitSellOrders=0;
   for(int j=OrdersTotal()-1; j>=0; j--)
   {
      if (OrderSelect(j,SELECT_BY_POS))
      { 
         if (Symbol() == OrderSymbol() && OrderType()==OP_SELL && OrderMagicNumber() == magicsell)
         {
            profitSellOrders = profitSellOrders + OrderProfit() + OrderSwap() + OrderCommission();
         }
      }
   }
   
   
   

   double totalglobalprofit = TotalProfit();
   if((inp12_ProfitAmountMoney > 0 && totalglobalprofit >= inp12_ProfitAmountMoney) || (maximaloss < 0 && totalglobalprofit <= maximaloss))
   {
      GlobalVariableSet(stoptrading, 1);
      CloseAllOrders();
      firebuy  = true;
      firesell = true;
   }
}
  
   
//+------------------------------------------------------------------+
int GetBuyOrderCount()
{
   int count=0;

   // find all open orders of today
   for (int k = OrdersTotal();k >=0 ;k--)
   {  
      if (OrderSelect(k, SELECT_BY_POS))
      {
         if (OrderType()==OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber() == magicbuy) 
         {
             count=count+1;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
int GetSellOrderCount()
{
   int count=0;

   // find all open orders of today
   for (int k = OrdersTotal(); k >=0 ;k--)
   {  
      if (OrderSelect(k, SELECT_BY_POS))
      {
         if (OrderType() == OP_SELL && OrderSymbol() == Symbol() && OrderMagicNumber() == magicsell) 
         {
            count=count+1;
         }
      }
   }
   return count;
}
  
//+------------------------------------------------------------------+
// GetTicketOfLargestBuyOrder()
// returns the ticket of the largest open buy order 
//+------------------------------------------------------------------+

int GetTicketOfLargestBuyOrder()
{
   double maxLots=0;
   int    orderTicketNr=0;

   for (int i=0;i < OrdersTotal();i++)
   {
      if ( OrderSelect(i,SELECT_BY_POS)) 
      {
         if( OrderType()==OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber()==magicbuy)
         {
            
            double orderLots = OrderLots();  
            if (orderLots >= maxLots) 
            {
               maxLots       = orderLots; 
               orderTicketNr = OrderTicket();
            }   
         } 
      } 
   }
   return orderTicketNr;
}


//+------------------------------------------------------------------+
// GetTicketOfLargestSellOrder()
// returns the ticket of the largest open sell order 
//+------------------------------------------------------------------+
int GetTicketOfLargestSellOrder()
{
   double maxLots=0;
   int orderTicketNr=0;

   for (int l=0;l<=OrdersTotal();l++)
   {
      if ( OrderSelect(l,SELECT_BY_POS) )
      {
         if(OrderType() == OP_SELL && OrderSymbol() == Symbol() && OrderMagicNumber() == magicsell)
         {
            double orderLots = OrderLots();  
            if (orderLots >= maxLots) 
            {
               maxLots = orderLots; 
               orderTicketNr = OrderTicket();
            }   
         }
      }  
   }
   return orderTicketNr;
}


//+------------------------------------------------------------------+
// CloseAllBuyOrders()
// closes all open buy orders
//+------------------------------------------------------------------+
void CloseAllBuyOrders()
{
   for (int m=OrdersTotal(); m>=0; m--)
   {
      if ( OrderSelect(m, SELECT_BY_POS))
      {
         if(OrderType() == OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber() == magicbuy)
         {
            RefreshRates();
            bool success = OrderClose(OrderTicket(), OrderLots(), Bid, 0, Blue);
         }
      }
    }
}


//+------------------------------------------------------------------+
// CloseAllSellOrders()
// closes all open sell orders
//+------------------------------------------------------------------+
void CloseAllSellOrders()
{
   for (int h=OrdersTotal();h>=0;h--)
   {
      if ( OrderSelect(h,SELECT_BY_POS) )
      {
         if(OrderType() == OP_SELL && OrderSymbol() == Symbol() && OrderMagicNumber() == magicsell)
         {
            RefreshRates();
            bool success =OrderClose(OrderTicket(), OrderLots(), Ask, 0, Red);
         }
      }
   }
}


//+------------------------------------------------------------------+
// CloseAllOrders()
// closes all orders
//+------------------------------------------------------------------+
void CloseAllOrders()
{
   CloseAllBuyOrders();
   CloseAllSellOrders();
}


//+------------------------------------------------------------------+
// TotalProfit()
// returns the total profit for all open orders
//+------------------------------------------------------------------+
double TotalProfit()
{
   double totalProfit = 0;
   for (int j=OrdersTotal();j >= 0; j--)
   {
      if( OrderSelect(j,SELECT_BY_POS))
      {
         if(OrderSymbol() == Symbol() )
         {
            if (OrderMagicNumber() == magicsell || OrderMagicNumber() == magicbuy)
            {
               RefreshRates();
         
               totalProfit = totalProfit + OrderProfit() + OrderSwap() + OrderCommission();
            }
         }
      }      
   }
   return totalProfit;
}


//+------------------------------------------------------------------+
// IsNewBar()
// returns if new bar has started
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime time = Time[0];
   if(Time[0] > time)
   {
      time = Time[0]; //newbar, update time
      return (true);
   } 
   return(false);
}

//+------------------------------------------------------------------+
// CheckTradingTime()
// returns true if we are allowed to trade
//+------------------------------------------------------------------+
bool CheckTradingTime()
{
   int min  = TimeMinute( TimeCurrent() );
   int hour = TimeHour( TimeCurrent() );
   
   // check if we can trade from 00:00 - 24:00
   if (Start_Hour == 0 && Finish_Hour == 24)
   {
      if (Start_Minute==0 && Finish_Minute==0)
      {
         // yes then return true
         return true; 
      } 
   } 
   
   if (Start_Hour > Finish_Hour) 
   {
      return(true);
   } 
    
   // suppose we're allowed to trade from 14:15 - 19:30
   
   // 1) check if hour is < 14 or hour > 19
   if ( hour < Start_Hour || hour > Finish_Hour ) 
   {   
      // if so then we are not allowed to trade
      return false;
   }
   
   // if hour is 14, then check if minute < 15
   if ( hour == Start_Hour && min < Start_Minute )
   {
      // if so then we are not allowed to trade
      return false;
   } 
   
   // if hour is 19, then check  minute > 30
   if ( hour == Finish_Hour && min > Finish_Minute )
   {
      // if so then we are not allowed to trade
      return false;
   }
   return true;
 }
   
//--------------------------------------------------------------------------------
// TradesToday()
// return total number of trades done today (closed and still open)
//--------------------------------------------------------------------------------
int TradesToday()
{
   int count=0;

   // find all open orders of today
   for (int k = OrdersTotal();k >=0 ;k--)
   {  
      if (OrderSelect(k,SELECT_BY_POS))
      {
         if (OrderSymbol() == Symbol() )
         {
             if(OrderLots() == Lots)
             {
                  if (OrderMagicNumber() == magicbuy || OrderMagicNumber() == magicsell) 
                  {
                     if( TimeDay(OrderOpenTime()) == TimeDay(TimeCurrent()))
                     { 
                        count=count+1;
                     }
                  }
             }
         }
      }
   }
   
   // find all closed orders of today
   for (int l=OrdersHistoryTotal();l >= 0;l--)
   {
      if(OrderSelect(l, SELECT_BY_POS,MODE_HISTORY))
      {
         if (OrderSymbol() == Symbol() )
         {
             if(OrderLots() == Lots)
             {
               if (OrderMagicNumber() != magicbuy && OrderMagicNumber() !=magicsell) 
               {
                  if(OrdersHistoryTotal() != 0 && TimeDay(OrderOpenTime()) == TimeDay(TimeCurrent()))
                  {
                     count = count + 1;
                  }
               }
             }
         }
      }
   }
   return(count);
   
}