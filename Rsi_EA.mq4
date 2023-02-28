//+------------------------------------------------------------------+
//|                                    Strategy: Investec Rsi EA.mq4 |
//|                                       Created with EABuilder.com |
//|                                        https://www.eabuilder.com |
//+------------------------------------------------------------------+
#property copyright "Created with EABuilder.com"
#property link      "https://www.eabuilder.com"
#property version   "1.00"
#property description ""


#include <stdlib.mqh>
#include <stderror.mqh>

int LotDigits; //initialized in OnInit
int MagicNumber = 1210138;
int NextOpenTradeAfterBars = 1; //next open trade after time
int TOD_From_Hour = 02; //time of the day (from hour)
int TOD_From_Min = 00; //time of the day (from min)
int TOD_To_Hour = 22; //time of the day (to hour)
int TOD_To_Min = 30; //time of the day (to min)
double TradeSize = AccountBalance()/10000;
int MaxSlippage = 3; //slippage, adjusted in OnInit
int MaxOpenTrades = 1;
int MaxLongTrades = 1;
int MaxShortTrades = 1;
int MaxPendingOrders = 1000;
int MaxLongPendingOrders = 1000;
int MaxShortPendingOrders = 1000;
bool Hedging = true;
int OrderRetry = 10; //# of retries if sending order returns error
int OrderWait = 1; //# of seconds to wait if sending order returns error
double myPoint; //initialized in OnInit

bool inTimeInterval(datetime t, int From_Hour, int From_Min, int To_Hour, int To_Min)
  {
   string TOD = TimeToString(t, TIME_MINUTES);
   string TOD_From = StringFormat("%02d", From_Hour)+":"+StringFormat("%02d", From_Min);
   string TOD_To = StringFormat("%02d", To_Hour)+":"+StringFormat("%02d", To_Min);
   return((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, TOD_To) <= 0)
     || (StringCompare(TOD_From, TOD_To) > 0
       && ((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, "23:59") <= 0)
         || (StringCompare(TOD, "00:00") >= 0 && StringCompare(TOD, TOD_To) <= 0))));
  }



void myAlert(string type, string message)
  {
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
     }
   else if(type == "order")
     {
      Print(type+" | Rsi EA @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "modify")
     {
     }
  }

int TradesCount(int type) //returns # of open trades for order type, current symbol and magic number
  {
   int result = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      result++;
     }
   return(result);
  }

bool SelectLastHistoryTrade()
  {
   int lastOrder = -1;
   int total = OrdersHistoryTotal();
   for(int i = total-1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
         lastOrder = i;
         break;
        }
     } 
   return(lastOrder >= 0);
  }

datetime LastCloseTime()
  {
   if(SelectLastHistoryTrade())
     {
      return(OrderCloseTime());
     }
   return(0);
  }


int myOrderSend(int type, double price, double volume, string ordername) //send order, return ticket ("price" is irrelevant for market orders)
  {
   if(!IsTradeAllowed()) 
   return(-1);
   int ticket = -1;
   int retries = 0;
   int err = 0;
   int long_trades = TradesCount(OP_BUY);
   int short_trades = TradesCount(OP_SELL);
   int long_pending = TradesCount(OP_BUYLIMIT) + TradesCount(OP_BUYSTOP);
   int short_pending = TradesCount(OP_SELLLIMIT) + TradesCount(OP_SELLSTOP);
   string ordername_ = ordername;
   if(ordername != "")
      ordername_ = "("+ordername+")";
   //test Hedging
   if(!Hedging && ((type % 2 == 0 && short_trades + short_pending > 0) || (type % 2 == 1 && long_trades + long_pending > 0)))
     {
      myAlert("print", "Order"+ordername_+" not sent, hedging not allowed");
      return(-1);
     }
   //test maximum trades
   if((type % 2 == 0 && long_trades >= MaxLongTrades)
   || (type % 2 == 1 && short_trades >= MaxShortTrades)
   || (long_trades + short_trades >= MaxOpenTrades)
   || (type > 1 && type % 2 == 0 && long_pending >= MaxLongPendingOrders)
   || (type > 1 && type % 2 == 1 && short_pending >= MaxShortPendingOrders)
   || (type > 1 && long_pending + short_pending >= MaxPendingOrders)
   
   )
     {
      myAlert("print", "Order"+ordername_+" not sent, maximum reached");
      return(-1);
     }
   //prepare to send order
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   if(type == OP_BUY)
      price = Ask;
   else if(type == OP_SELL)
      price = Bid;
   else if(price < 0) //invalid price for pending order
     {
      myAlert("order", "Order"+ordername_+" not sent, invalid price for pending order");
	  return(-1);
     }
   int clr = (type % 2 == 1) ? clrRed : clrBlue;
   while(ticket < 0 && retries < OrderRetry+1)
     {
      ticket = OrderSend(Symbol(), type, NormalizeDouble(volume, LotDigits), NormalizeDouble(price, Digits()), MaxSlippage, 0, 0, ordername, MagicNumber, 0, clr);
      if(ticket < 0)
        {
         err = GetLastError();
         myAlert("print", "OrderSend"+ordername_+" error #"+IntegerToString(err)+" "+ErrorDescription(err));
         Sleep(OrderWait*1000);
        }
      retries++;
     }
   if(ticket < 0)
     {
      myAlert("error", "OrderSend"+ordername_+" failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};
   myAlert("order", "Order sent"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+IntegerToString(MagicNumber));
   return(ticket);
  }

int myOrderModifyRel(int ticket, double SL, double TP) //modify SL and TP (relative to open price), zero targets do not modify
  {
   if(!IsTradeAllowed()) return(-1);
   bool success = false;
   int retries = 0;
   int err = 0;
   SL = NormalizeDouble(SL, Digits());
   TP = NormalizeDouble(TP, Digits());
   if(SL < 0) SL = 0;
   if(TP < 0) TP = 0;
   //prepare to select order
   while(IsTradeContextBusy()) Sleep(100);
   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
     {
      err = GetLastError();
      myAlert("error", "OrderSelect failed; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   //prepare to modify order
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   //convert relative to absolute
   if(OrderType() % 2 == 0) //buy
     {
      if(NormalizeDouble(SL, Digits()) != 0)
         SL = OrderOpenPrice() - SL;
      if(NormalizeDouble(TP, Digits()) != 0)
         TP = OrderOpenPrice() + TP;
     }
   else //sell
     {
      if(NormalizeDouble(SL, Digits()) != 0)
         SL = OrderOpenPrice() + SL;
      if(NormalizeDouble(TP, Digits()) != 0)
         TP = OrderOpenPrice() - TP;
     }
   if(CompareDoubles(SL, 0)) SL = OrderStopLoss(); //not to modify
   if(CompareDoubles(TP, 0)) TP = OrderTakeProfit(); //not to modify
   if(CompareDoubles(SL, OrderStopLoss()) && CompareDoubles(TP, OrderTakeProfit())) return(0); //nothing to do
   while(!success && retries < OrderRetry+1)
     {
      success = OrderModify(ticket, NormalizeDouble(OrderOpenPrice(), Digits()), NormalizeDouble(SL, Digits()), NormalizeDouble(TP, Digits()), OrderExpiration(), CLR_NONE);
      if(!success)
        {
         err = GetLastError();
         myAlert("print", "OrderModify error #"+IntegerToString(err)+" "+ErrorDescription(err));
         Sleep(OrderWait*1000);
        }
      retries++;
     }
   if(!success)
     {
      myAlert("error", "OrderModify failed "+IntegerToString(OrderRetry+1)+" times; error #"+IntegerToString(err)+" "+ErrorDescription(err));
      return(-1);
     }
   string alertstr = "Order modified: ticket="+IntegerToString(ticket);
   if(!CompareDoubles(SL, 0)) alertstr = alertstr+" SL="+DoubleToString(SL);
   if(!CompareDoubles(TP, 0)) alertstr = alertstr+" TP="+DoubleToString(TP);
   myAlert("modify", alertstr);
   return(0);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {   
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
      MaxSlippage *= 10;
     }
   //initialize LotDigits
   double LotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(NormalizeDouble(LotStep, 3) == round(LotStep))
      LotDigits = 0;
   else if(NormalizeDouble(10*LotStep, 3) == round(10*LotStep))
      LotDigits = 1;
   else if(NormalizeDouble(100*LotStep, 3) == round(100*LotStep))
      LotDigits = 2;
   else LotDigits = 3;
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int ticket = -1;
   double price;   
   double TP;
   
   
   //Open Buy Order (Rsi)
   if(iRSI(NULL, PERIOD_H1, 3, PRICE_MEDIAN, 0) > iRSI(NULL, PERIOD_H1, 3, PRICE_MEDIAN, 1) //Relative Strength Index > Relative Strength Index
   && iRSI(NULL, PERIOD_M30, 3, PRICE_MEDIAN, 0) > iRSI(NULL, PERIOD_M30, 3, PRICE_MEDIAN, 1) //Relative Strength Index > Relative Strength Index
   && iRSI(NULL, PERIOD_M15, 3, PRICE_MEDIAN, 0) > iRSI(NULL, PERIOD_M15, 3, PRICE_MEDIAN, 1) //Relative Strength Index > Relative Strength Index
   && iRSI(NULL, PERIOD_M5, 3, PRICE_MEDIAN, 0) > iRSI(NULL, PERIOD_M5, 3, PRICE_MEDIAN, 1) //Relative Strength Index > Relative Strength Index
   && iRSI(NULL, PERIOD_M1, 3, PRICE_MEDIAN, 0) > iRSI(NULL, PERIOD_M1, 3, PRICE_MEDIAN, 1) //Relative Strength Index > Relative Strength Index
   )
     {
      RefreshRates();
      price = Ask;
      TP = 3 * myPoint; //Take Profit = value in points (relative to price)
      if(TradesCount(OP_BUY) + TradesCount(OP_SELL) > 0 || TimeCurrent() - LastCloseTime() < NextOpenTradeAfterBars * PeriodSeconds()) return; //next open trade after time after previous trade's close
      if(!inTimeInterval(TimeCurrent(), TOD_From_Hour, TOD_From_Min, TOD_To_Hour, TOD_To_Min)) return; //open trades only at specific times of the day   
      if(IsTradeAllowed())
        {
         ticket = myOrderSend(OP_BUY, price, AccountBalance()/10000, "Rsi");
         if(ticket <= 0) return;
        }
      else //not autotrading => only send alert
         myAlert("order", "Rsi");
      myOrderModifyRel(ticket, 0, TP);
     }
   
   //Open Sell Order (Rsi)
   if(iRSI(NULL, PERIOD_H1, 3, PRICE_MEDIAN, 0) < iRSI(NULL, PERIOD_H1, 3, PRICE_MEDIAN, 1) //Relative Strength Index < Relative Strength Index
   && iRSI(NULL, PERIOD_M30, 3, PRICE_MEDIAN, 0) < iRSI(NULL, PERIOD_M30, 3, PRICE_MEDIAN, 1) //Relative Strength Index < Relative Strength Index
   && iRSI(NULL, PERIOD_M15, 3, PRICE_MEDIAN, 0) < iRSI(NULL, PERIOD_M15, 3, PRICE_MEDIAN, 1) //Relative Strength Index < Relative Strength Index
   && iRSI(NULL, PERIOD_M5, 3, PRICE_MEDIAN, 0) < iRSI(NULL, PERIOD_M5, 3, PRICE_MEDIAN, 1) //Relative Strength Index < Relative Strength Index
   && iRSI(NULL, PERIOD_M1, 3, PRICE_MEDIAN, 0) < iRSI(NULL, PERIOD_M1, 3, PRICE_MEDIAN, 1) //Relative Strength Index < Relative Strength Index
   )
     {
      RefreshRates();
      price = Bid;
      TP = 3 * myPoint; //Take Profit = value in points (relative to price)
      if(TradesCount(OP_BUY) + TradesCount(OP_SELL) > 0 || TimeCurrent() - LastCloseTime() < NextOpenTradeAfterBars * PeriodSeconds()) return; //next open trade after time after previous trade's close
      if(!inTimeInterval(TimeCurrent(), TOD_From_Hour, TOD_From_Min, TOD_To_Hour, TOD_To_Min)) return; //open trades only at specific times of the day   
      if(IsTradeAllowed())
        {
         ticket = myOrderSend(OP_SELL, price, AccountBalance()/10000, "Rsi");
         if(ticket <= 0) return;
        }
      else //not autotrading => only send alert
         myAlert("order", "Rsi");
      myOrderModifyRel(ticket, 0, TP);
     }
  }
//+------------------------------------------------------------------+