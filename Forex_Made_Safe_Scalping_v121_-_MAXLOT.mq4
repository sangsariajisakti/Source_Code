//+------------------------------------------------------------------+
//|                                              Scalping GUI EA.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.07"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <stdlib.mqh>

#define VERT_PANEL_MARGIN_Y 12
#define HORZ_PANEL_MARGIN_X 300
string ButtonTexts[] = {"Lot (%)", "0.1", "BUY", "  Breakeven  ", "Place SL", "CLOSE", "SELL"};



enum ENUM_STOPLOSS_OPTIONS
  {
   _sl_touch, //Touch
   _sl_close //Close
  };

struct STRUCT_HIDDEN_ORDER
  {
   int               ticket;
   int               trade;
   double            sl;
  };

struct  STRUCT_ORDER
  {
   int               ticket;
   datetime          time;
   double            pips;
   int               trade;
   double            sl;
   double            tp;
  };

enum ENUM_NEWS_IMPACT
  {
   _news_low, //Low
   _news_medium, //Medium
   _news_high //High
  };

struct CALENDAR_INFO
  {
   string            title;
   string            country;
   datetime          time;
   int               impact;
   string            obj;
   color             clr;
   bool              show;
  };

#import "news-ff.ex4"
int GetNews(CALENDAR_INFO& cals[]);
#import

input int FontSize = 9; //Font Size
input string Blank3 = ""; //-
input string StopLossSettings__ = "--------------------------------"; // ------ Setting for Stop Loss  ------
input bool StopLossHidden = false; //Hidden Stop Loss
input ENUM_STOPLOSS_OPTIONS StopLossOptions = _sl_touch; //Stop Loss Option
input int StopLossBar = 30; //Stop Loss Bars Back
input double TakeProfitDefault = 25; //Default Take Profit (pips)
double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);

input string Blank18__ = ""; //-
input string NewsSettings__ = "--------------------------------"; // ------ News Settings ------
input bool UseNews = true; //Use News
input string NewsList = "Non-Farm Payroll,FOMC,Cash Rate,Monetary Policy Meetings"; //List of News that Prevent Trade
input int NewsCountBefore = 2; //Display # of News before
input int NewsCountAfter = 3; //Display # of News after
input color LowImpactColor = clrYellow; //Low Impact
input color MediumImpactColor = clrOrange; //Medium Impact
input color HighImpactColor = clrRed; //High Impact
input color HolidayColor = clrGray; //Holiday
input color PositiveProfitColor = clrSkyBlue; //Positive P/L Color
input color NegativeProfitColor = clrRed; //Negative P/L Color
input string Blank9__ = ""; //-
input string GUISizeProperties__ = "--------------------------------"; // ------ GUI Size Settings ------
input int NewsRightMargin = 300; //News Title Right Margin
input int ButtonNewsSpace = 100; //Button and News Space

input int MaxPositions = 25; //Max Positions
input double MaxRisk = 1.0; //Max Risk (%)

input double MaxDailyLoss=-1000;
input short MaxPairPositions=23;

//////////////////////////////////////
bool Started=false;
datetime BarTime = 0;
bool NewBar = false;
double Pip;
bool LotIsPercent = false;
STRUCT_ORDER Orders2[];
STRUCT_HIDDEN_ORDER HiddenOrders[];
datetime PrevNewsTime = 0;
int TimeOffset = 0;
color NEWS_COLORS[4];
string LotText = "";
int Tickets[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Pip = _Point;
   if(_Digits == 3 || _Digits == 5)
     {
      Pip = 10*_Point;
     }

   NEWS_COLORS[0] = LowImpactColor;
   NEWS_COLORS[1] = MediumImpactColor;
   NEWS_COLORS[2] = HighImpactColor;
   NEWS_COLORS[3] = HolidayColor;

   TimeOffset = (int)(TimeLocal() - TimeGMT());
   TimeOffset = (int)round(1.0*TimeOffset/(30*60))*(30*60);

   DrawBottomPanel();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   PrevNewsTime = 0;
   EventKillTimer();
   ObjectsDeleteAll(0, WindowExpertName());
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(NewOrderClosed())
     {
      Print("New order closed!");
      TakeScreenshot();
     }
   NewBar = false;
   if(Time[0] > BarTime)
     {
      NewBar = BarTime > 0;
      BarTime = Time[0];
     }
   if(!Started)
     {
      Started = true;
      DrawLevel("SL", 0, false);
      DrawLevel("TP", 0, false);
     }
   if(StopLossHidden)
     {
      //if (StopLossOptions == _sl_close) {
      if(StopLossOptions == _sl_touch || (StopLossOptions == _sl_close && NewBar))
        {
         ManageHiddenSL();
        }
     }

   double profit;
   UpdateOrderList(profit);
   string obj = WindowExpertName()+"PL";
   ObjectSetString(0, obj, OBJPROP_TEXT, StringFormat("$ % 2.2f", profit));
   color clr = profit >= 0 ? PositiveProfitColor : NegativeProfitColor;
   ObjectSetInteger(0, obj, OBJPROP_COLOR, clr);
//amr
   double losses;
   totalLoss(losses);
   string objlosses = WindowExpertName()+"SL";
   ObjectSetString(0, objlosses, OBJPROP_TEXT, StringFormat("$ % 2.2f", losses));
   color clrlosses = losses >= 0 ? PositiveProfitColor : NegativeProfitColor;
   ObjectSetInteger(0, objlosses, OBJPROP_COLOR, clrlosses);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(StopLossHidden)
     {
      UpdateHiddenOrders();
     }
   datetime tlocal = TimeLocal();
   if(tlocal - PrevNewsTime >= 30)
     {
      PrevNewsTime = tlocal;
      if(UseNews)
        {
         CALENDAR_INFO cals[];
         int count = GetNews(cals);
         if(count > 0)
           {
            DrawNewsLine(cals);
           }
         else
           {
            Print("No news");
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(ObjectType(sparam) == OBJ_BUTTON)
        {
         string obj = StringSubstr(sparam, StringLen(WindowExpertName()));
         if(StringSubstr(obj, 0, 5) == "TRADE" || StringSubstr(obj, 0, 4) == "CONF" || StringSubstr(obj, 0, 5) == "CLOSE"
            ||obj == "PLUSONE")
           {
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            if(obj == "TRADE0")    //Lot option (% / fixed lot)
              {
               LotIsPercent = !LotIsPercent;
               string text;
               if(LotIsPercent)
                 {
                  text = "Lot (%)";
                 }
               else
                 {
                  text = "Lot (fixed)";
                 }
               ObjectSetString(0, sparam, OBJPROP_TEXT, text);
              }
            else
               if(obj == "PLUSONE")
                 {
                  if(OrdersTotal()==0 ||  AccountEquity()<AccountBalance())
                     return;
                  if(OrderType()==OP_BUY)
                     doBuy(false);
                  if(OrderType()==OP_SELL)
                     doSell(false);
                 }
               else
                  if(obj == "TRADE2")    //Buy
                    {
                     doBuy();
                    }
                  else
                     if(obj == "TRADE6")    //Sell
                       {
                        doSell();
                        /*

                        */
                       }
                     else
                        if(obj == "TRADE3")    //Breakeven
                          {
                           MoveBE();
                          }
                        else
                           if(obj == "TRADE4")    //PlaceTP
                             {
                              DrawSLPanel();
                              double sl = High[1]+ iATR(NULL, PERIOD_CURRENT, 14, 1);
                              DrawLevel("SL", sl, true);
                             }
                           else
                              if(obj == "TRADE5")
                                {
                                 Alert("Close All");
                                 CloseAllOrders();
                                }
                              else
                                 if(obj == "CONF0")
                                   {
                                    if(ObjectGetString(0, sparam, OBJPROP_TEXT) == "BUY")
                                      {
                                       double sl = ObjectGetDouble(0, WindowExpertName()+"VISSL", OBJPROP_PRICE);
                                       double lot = GetLotSize(Ask - sl);
                                       PrintFormat("sl %g, lot %g", sl, lot);
                                       if(CheckMaxPositions())
                                         {
                                          //if (CheckMaxRisk(lot, fabs(Ask - sl))) {
                                          int ticket = SendOrder(OP_BUY, Ask, lot, sl);
                                          if(ticket > 0)
                                            {
                                             AddHiddenOrders(ticket, sl, OP_BUY);
                                            }
                                          //}
                                         }

                                      }
                                    else
                                      {
                                       double sl = ObjectGetDouble(0, WindowExpertName()+"VISSL", OBJPROP_PRICE);
                                       double lot = GetLotSize(sl - Bid);
                                       PrintFormat("sl %g, lot %g", sl, lot);
                                       if(CheckMaxPositions())
                                         {
                                          //if (CheckMaxRisk(lot, fabs(sl - Bid))) {
                                          int ticket = SendOrder(OP_SELL, Bid, lot, sl);
                                          if(ticket > 0)
                                            {
                                             AddHiddenOrders(ticket, sl, OP_SELL);
                                            }
                                          //}
                                         }
                                      }
                                    DrawLevel("SL", 0, false);
                                    DrawBottomPanel();
                                   }
                                 else
                                    if(obj == "CONF1")
                                      {
                                       DrawLevel("SL", 0, false);
                                       DrawBottomPanel();
                                      }
                                    else
                                       if(obj == "CLOSE25")
                                         {
                                          PartialClose(25);
                                         }
                                       else
                                          if(obj == "CLOSE50")
                                            {
                                             PartialClose(50);
                                            }
                                          else
                                             if(obj == "CLOSE75")
                                               {
                                                PartialClose(75);
                                               }
                                             else
                                                if(obj == "CONF3")
                                                  {
                                                   double sl = ObjectGetDouble(0, WindowExpertName()+"VISSL", OBJPROP_PRICE);
                                                   bool res = OrderModify(OrderTicket(), OrderOpenPrice(), sl,0, 0, clrBlue);
                                                   MoveSL(sl);
                                                   DrawLevel("SL", 0, false);
                                                   DrawBottomPanel();
                                                  }

           }
        }
     }
   else
      if(id == CHARTEVENT_OBJECT_DRAG)
        {
         if(StringFind(sparam, WindowExpertName()+"SL") == 0)
           {
            int ticket = (int)StringToInteger(StringSubstr(sparam, StringLen(WindowExpertName()+"SL")));
            if(ticket > 0)
              {
               int trade;
               double sl;
               int idx = GetHiddenOrdersSL(ticket, trade, sl);
               if(idx >= 0 && sl > 0)
                 {
                  double price = ObjectGetDouble(0, sparam, OBJPROP_PRICE);
                  if((trade == OP_BUY && price < sl) || (trade == OP_SELL && price > sl))
                    {
                     ObjectSetDouble(0, sparam, OBJPROP_PRICE, sl);
                    }
                  else
                    {
                     HiddenOrders[idx].sl = price;
                    }
                 }
              }
           }
        }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doSell(bool confirm=true)
  {
  // Alert(confirm);
   if(countOfTradeOnCurSymbol()==MaxPairPositions)
     {
      Alert("Trading not allowad as there is already "+(string)MaxPairPositions+" trades running on "+Symbol()+" symbol");
      return;
     }
   if(DailyProfit()<MaxDailyLoss)
     {
      Alert("Trading not allowad as today losses= "+(string)DailyProfit()
            +" Your daily limit is: "+(string)MaxDailyLoss);
      return;
     }
   if(confirm)
     {
      DrawConfirmPanel(OP_SELL);
      double sl = High[iHighest(_Symbol, 0, MODE_HIGH, StopLossBar+1, 0)] + SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)*_Point;
      DrawLevel("SL", sl, true);
     }
   else
     {
     // double sl =High[iHighest(_Symbol, 0, MODE_HIGH, StopLossBar+1, 0)] + SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)*_Point;
    //get sl from current running trade
    bool r=OrderSelect(0,SELECT_BY_POS);
    double sl=OrderStopLoss();
  // ObjectGetDouble(0, WindowExpertName()+"VISSL", OBJPROP_PRICE);
      double lot = GetLotSize(sl - Bid);
      PrintFormat("sl %g, lot %g", sl, lot);
      if(CheckMaxPositions())
        {
         int ticket = SendOrder(OP_SELL, Bid, lot, sl);
         if(ticket > 0)
           {
            AddHiddenOrders(ticket, sl, OP_SELL);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doBuy(bool confirm=true)
  {
   //Alert(confirm);
   if(countOfTradeOnCurSymbol()==MaxPairPositions)
     {
      Alert("Trading not allowad as there is already "+(string)MaxPairPositions+" trades running on "+Symbol()+" symbol");
      return;
     }
   if(DailyProfit()<MaxDailyLoss)
     {
      Alert("Trading not allowad as today losses= "+(string)DailyProfit()
            +" Your daily limit is: "+(string)MaxDailyLoss);
      return;
     }
   if(confirm)
     {
      DrawConfirmPanel(OP_BUY);
      double sl = Low[iLowest(_Symbol, 0, MODE_LOW, StopLossBar+1, 0)];
      DrawLevel("SL", sl, true);
     }
   else
     {
    //  double sl = Low[iLowest(_Symbol, 0, MODE_LOW, StopLossBar+1, 0)];//ObjectGetDouble(0, WindowExpertName()+"VISSL", OBJPROP_PRICE);
    //get sl from current running trade
    bool r=OrderSelect(0,SELECT_BY_POS);
    double sl=OrderStopLoss();
      double lot = GetLotSize(Ask - sl);
      PrintFormat("sl %g, lot %g", sl, lot);
      if(CheckMaxPositions())
        {
         int ticket = SendOrder(OP_BUY, Ask, lot, sl);
         if(ticket > 0)
           {
            AddHiddenOrders(ticket, sl, OP_BUY);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawBottomPanel()
  {
   ObjectsDeleteAll(0, WindowExpertName()+"CONF");
   color clrs[] = {clrWhite, clrWhite, clrDodgerBlue, clrWhite, clrWhite, clrWhite, clrRed};
   TextSetFont("Tahoma", -10*FontSize);
   int w, h;
   TextGetSize("  "+ButtonTexts[3]+"  ", w, h);
   h = (int)(round(1.8*h));
   int space = (int)(round(0.1*w));
   int y = VERT_PANEL_MARGIN_Y+h;

   int w1, h1;
   TextGetSize(">>", w1, h1);
   int x = NewsRightMargin + ArraySize(ButtonTexts)*(w+space) - space + w1 + ButtonNewsSpace;
   TextSetFont("Tahoma", -2*10*FontSize);
   TextGetSize("$ -000.00", w1, h1);
   TextSetFont("Tahoma", -10*FontSize);
   int x2 = x + w1 + 2*space;
   for(int i=0; i<ArraySize(ButtonTexts); i++)
     {
      if(i == 0)
        {
         string text;
         if(LotIsPercent)
           {
            text = "Lot (%)";
           }
         else
           {
            text = "Lot (fixed)";
           }
         CreateButtton("TRADE"+(string)i, x, y, w, h, text, CORNER_RIGHT_LOWER, false, clrBlack, clrs[i]);
        }
      else
         if(i == 1)
           {
            string text;
            if(LotText != "")
              {
               text = LotText;
              }
            else
              {
               LotText = ButtonTexts[i];
              }
            CreateEdit("TRADE"+(string)i, x, y, w, h, LotText, CORNER_RIGHT_LOWER);
           }
         else
           {
            CreateButtton("TRADE"+(string)i, x, y, w, h, ButtonTexts[i], CORNER_RIGHT_LOWER, false, clrBlack, clrs[i]);
           }
      x-=w+space;
     }

//Draw P/L
   double profit = 0;
   string text = StringFormat("% 2.2f", profit);
   CreateLabel("PL", x2, y, "$ "+text, clrGreen, CORNER_RIGHT_LOWER, 1.5*FontSize);
   CreateLabel("SL", x2+150, y, "$ "+text, clrGreen, CORNER_RIGHT_LOWER, 1.5*FontSize);
   x = 4;
   TextGetSize(" X 75% ", w, h1); //preserve height
//   CreateButtton("CLOSE25", x, y, w, h, "X 25%", CORNER_LEFT_LOWER, false, clrBlack, clrSilver);
//   x += w + 4;
//   CreateButtton("CLOSE50", x, y, w, h, "X 50%", CORNER_LEFT_LOWER, false, clrBlack, clrSilver);
//   x += w + 4;
//   CreateButtton("CLOSE75", x, y, w, h, "X 75%", CORNER_LEFT_LOWER, false, clrBlack, clrSilver);
//   x += w + 50;
//   CreateButtton("PLUSONE", x, y, 50, h, "+ 1", CORNER_LEFT_LOWER, false, clrBlack, clrSilver);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawConfirmPanel(const int trade)
  {
   LotText = ObjectGetString(0, WindowExpertName()+"TRADE1", OBJPROP_TEXT);
   ObjectsDeleteAll(0, WindowExpertName()+"TRADE");
   TextSetFont("Tahoma", -10*FontSize);
   int w, h;
   TextGetSize("  Cancel  ", w, h);
   h = (int)(round(2*h));
   int space = (int)(round(0.1*w));
   int y = VERT_PANEL_MARGIN_Y+h;

//int x = NewsRightMargin + 2*(w+space) - space;
   int w1, h1;
   TextGetSize(">>", w1, h1);
   int x = NewsRightMargin + 2*(w+space) - space + w1 + ButtonNewsSpace;
   CreateButtton("CONF0", x, y+50, w, h, trade == OP_BUY ? "BUY" : "SELL", CORNER_RIGHT_LOWER, false, clrBlack, clrWhite);
   x-=w+space;
   CreateButtton("CONF1", x, y+50, w, h, "Cancel", CORNER_RIGHT_LOWER, false, clrBlack, clrWhite);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawSLPanel()
  {
   LotText = ObjectGetString(0, WindowExpertName()+"TRADE1", OBJPROP_TEXT);
   ObjectsDeleteAll(0, WindowExpertName()+"TRADE");
   TextSetFont("Tahoma", -10*FontSize);
   int w, h;
   TextGetSize("  Cancel  ", w, h);
   h = (int)(round(2*h));
   int space = (int)(round(0.1*w));
   int y = VERT_PANEL_MARGIN_Y+h;

//int x = NewsRightMargin + 2*(w+space) - space;
   int w1, h1;
   TextGetSize(">>", w1, h1);
   int x = NewsRightMargin + 2*(w+space) - space + w1 + ButtonNewsSpace;
   CreateButtton("CONF3", x, y+50, w, h, "Confirm", CORNER_RIGHT_LOWER, false, clrBlack, clrWhite);
   x-=w+space;
   CreateButtton("CONF1", x, y+50, w, h, "Cancel", CORNER_RIGHT_LOWER, false, clrBlack, clrWhite);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateButtton(const string name, const int x, const int y, const int width, const int height, const string text, const ENUM_BASE_CORNER corner, const bool state, const color clr, const color bgClr)
  {
   string obj = WindowExpertName()+name;
   if(ObjectFind(0, obj) < 0)
     {
      ObjectCreate(0, obj, OBJ_BUTTON, 0, 0, 0);
      ObjectSetString(0, obj, OBJPROP_TEXT, text);
      ObjectSetInteger(0, obj, OBJPROP_CORNER, corner);
      ObjectSetInteger(0, obj, OBJPROP_BORDER_COLOR, clrNONE);
      ObjectSetInteger(0, obj, OBJPROP_BACK, false);
      ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, obj, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, obj, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, obj, OBJPROP_ZORDER, 0);
      ObjectSetInteger(0, obj, OBJPROP_STATE, state);
     }

   ObjectSetInteger(0, obj, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, obj, OBJPROP_BGCOLOR, bgClr);

   ObjectSetString(0, obj, OBJPROP_TEXT,text);
   ObjectSetInteger(0, obj, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, obj, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, obj, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, obj, OBJPROP_YSIZE, height);
   ObjectSetString(0, obj, OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, obj, OBJPROP_FONTSIZE, FontSize);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateEdit(const string name, const int x, const int y, const int width, const int height, string text, const ENUM_BASE_CORNER corner)
  {
   string obj = WindowExpertName()+name;
   if(ObjectFind(0,  obj) < 0)
     {
      ObjectCreate(0, obj, OBJ_EDIT,0,0,0);
      ObjectSetString(0, obj, OBJPROP_TEXT,text);
     }

   ObjectSetInteger(0, obj, OBJPROP_ALIGN,ALIGN_RIGHT);
   ObjectSetInteger(0, obj, OBJPROP_READONLY, false);
   ObjectSetInteger(0, obj, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, obj, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, obj, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, obj, OBJPROP_BORDER_COLOR, clrWhite);
   ObjectSetInteger(0, obj, OBJPROP_BACK, false);
   ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, obj, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, obj, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, obj, OBJPROP_ZORDER, 0);
   ObjectSetInteger(0, obj, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, obj, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, obj, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, obj, OBJPROP_YSIZE, height);
   ObjectSetString(0, obj, OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, obj, OBJPROP_FONTSIZE, FontSize);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetHiddenOrdersSL(const int ticket, int& trade, double& sl)
  {
   int res = -1;
   for(int i=0; i<ArraySize(HiddenOrders); i++)
     {
      if(HiddenOrders[i].ticket == ticket)
        {
         res = i;
         sl = HiddenOrders[i].sl;
         trade = HiddenOrders[i].trade;
         break;
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int IndexByTicket2(const int ticket)
  {
   int res = -1;
   for(int i=0; i<ArraySize(HiddenOrders); i++)
     {
      if(HiddenOrders[i].ticket == ticket)
        {
         res = i;
         break;
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ManageHiddenSL()
  {
   for(int i=0; i<ArraySize(HiddenOrders); i++)
     {
      if(OrderSelect(HiddenOrders[i].ticket, SELECT_BY_TICKET))
        {
         string obj = WindowExpertName()+"SL"+(string)OrderTicket();
         if(OrderCloseTime() == 0)
           {
            double price;
            if(StopLossOptions == _sl_close)
              {
               price = Close[1];
              }
            else
              {
               price = OrderClosePrice();
              }
            if(ObjectFind(0, obj) >= 0)
              {
               bool doClose;
               color clr;
               double sl = ObjectGetDouble(0, obj, OBJPROP_PRICE);
               if(OrderType() == OP_BUY)
                 {
                  doClose = price < sl;
                  clr = clrBlue;
                 }
               else
                 {
                  doClose = price > sl;
                  clr = clrRed;
                 }

               if(doClose)
                 {
                  bool res = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 99, clr);
                  if(res)
                    {
                     ObjectDelete(0, obj);
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawSL(const int ticket, const double price)
  {
   string obj = WindowExpertName()+"SL"+(string)ticket;
   if(ObjectFind(0, obj) < 0)
     {
      ObjectCreate(0, obj, OBJ_HLINE, 0, 0, price);
     }
   else
     {
      ObjectSetDouble(0, obj, OBJPROP_PRICE, price);
     }
   ObjectSetInteger(0, obj, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, obj, OBJPROP_SELECTED, true);
   ObjectSetInteger(0, obj, OBJPROP_WIDTH, 2);
   ObjectSetString(0, obj, OBJPROP_TOOLTIP, "\n");
   ObjectSetInteger(0, obj, OBJPROP_ZORDER, 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddHiddenOrders(const int ticket, const double sl, const int trade)
  {
   int n = ArraySize(HiddenOrders);
   ArrayResize(HiddenOrders, n+1);
   HiddenOrders[n].ticket = ticket;
   HiddenOrders[n].trade = trade;
   HiddenOrders[n].sl = sl;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateHiddenOrders()
  {
   for(int i=0; i<ArraySize(HiddenOrders); i++)
     {
      if(OrderSelect(HiddenOrders[i].ticket, SELECT_BY_TICKET))
        {
         if(OrderCloseTime() > 0)
           {
            PrintFormat("Order closed #%d", OrderTicket());
            if(i < ArraySize(HiddenOrders)-1)
              {
               HiddenOrders[i] = HiddenOrders[ArraySize(HiddenOrders)-1];
              }
            ArrayResize(HiddenOrders, ArraySize(HiddenOrders)-1);
            string obj = WindowExpertName()+"SL"+(string)OrderTicket();
            if(ObjectFind(0, obj) >= 0)
              {
               ObjectDelete(0, obj);
              }
            i = -1;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SendOrder(const int trade, const double price, const double lot, const double sl)
  {
   double slx = StopLossHidden ? 0 : sl;
   int ticket = OrderSend(_Symbol, trade, lot, price, 99, slx, 0, WindowExpertName(), 0, 0, trade == OP_BUY ? clrBlue : clrRed);
   if(ticket > 0)
     {
      if(StopLossHidden)
        {
         DrawSL(ticket, sl);
        }
     }
   return ticket;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLotSize(const double sl)
  {
   double lot;
   double value = StringToDouble(LotText);
   Print("value ", value);
   if(LotIsPercent)
     {
      double valuePerLot = MarketInfo(_Symbol, MODE_TICKVALUE) / MarketInfo(Symbol(), MODE_TICKSIZE);
      if((value*AccountEquity()/100.0/sl/valuePerLot)< MaxLot)
         lot = value*AccountEquity()/100.0/sl/valuePerLot;
      else
         lot = MaxLot;
     }
   else
     {
      if (value< MaxLot)
      lot = value;
      else lot = MaxLot;
     }

//double LotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
//lot = MathFloor(lot / LotStep) * LotStep;
//lot = MathMax(lot, MarketInfo(Symbol(), MODE_MINLOT));
//lot = MathMin(lot, MarketInfo(Symbol(), MODE_MAXLOT));

   return lot;
  }
/**
 * This method calculates the profit or loss of a position in the home currency of the account
 * @param  string  sym
 * @param  int     type    0 = buy, 1 = sell
 * @param  double  entry
 * @param  double  exit
 * @param  double  lots
 * @result double          profit/loss in home currency
 */
double calcPL(string sym, int type, double entry, double exit, double lots)
  {
//amr function
   double result=0;
   if(type == 0)
     {
      result = (exit - entry) * lots * (1 / MarketInfo(sym, MODE_POINT)) * MarketInfo(sym, MODE_TICKVALUE);
     }
   else
      if(type == 1)
        {
         result = (entry - exit) * lots * (1 / MarketInfo(sym, MODE_POINT)) * MarketInfo(sym, MODE_TICKVALUE);
        }
   return (result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void totalLoss(double& losses) //amr function
  {
//to show me the Max loss value if all orders hit SL
   double slTotal=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == _Symbol)
           {
            if(OrderType() == OP_BUY)
               slTotal+=calcPL(_Symbol,0,OrderOpenPrice(),OrderStopLoss(),OrderLots());
            if(OrderType() ==  OP_SELL)
               slTotal+=calcPL(_Symbol,1,OrderOpenPrice(),OrderStopLoss(),OrderLots());
           }
        }
     }
   losses=slTotal;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateOrderList(double& profit)
  {
   profit=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == _Symbol)
           {
            if(OrderType() == OP_BUY || OrderType() == OP_SELL)
              {
               //amr added this */ || OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP|| OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP) {
               profit += OrderProfit()+OrderCommission()+OrderSwap();
               int k = IndexByTicket(OrderTicket());
               if(k == -1)
                 {
                  Print("Adding order #", OrderTicket());
                  OrdersAdd(OrderTicket(), OrderStopLoss());
                 }
               else
                 {
                  if(OrderType() == OP_BUY)
                    {
                     if(OrderStopLoss() < Orders2[k].sl)
                       {
                        Print("Move back to original SL, #", OrderTicket());
                        bool res = OrderModify(OrderTicket(), OrderOpenPrice(), Orders2[k].sl, OrderTakeProfit(), 0, clrBlue);
                       }
                     else
                       {
                        Orders2[k].sl = OrderStopLoss();
                       }
                    }
                  else
                     if(OrderType() == OP_SELL)
                       {
                        if(OrderStopLoss() > Orders2[k].sl)
                          {
                           Print("Move back to original SL, #", OrderTicket());
                           bool res = OrderModify(OrderTicket(), OrderOpenPrice(), Orders2[k].sl, OrderTakeProfit(), 0, clrRed);
                          }
                        else
                          {
                           Orders2[k].sl = OrderStopLoss();
                          }
                       }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int IndexByTicket(const int ticket)
  {
   int res = -1;
   for(int i=0; i<ArraySize(Orders2); i++)
     {
      if(Orders2[i].ticket == ticket)
        {
         res = i;
         break;
        }
     }
   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrdersAdd(const int ticket, const double sl)
  {
   if(OrderSelect(ticket, SELECT_BY_TICKET))
     {
      int n = ArraySize(Orders2);
      ArrayResize(Orders2, n+1);
      Orders2[n].ticket = ticket;
      Orders2[n].sl = sl;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrdersRemove(const int ticket)
  {
   int n = ArraySize(Orders2);
   for(int i=0; i<n; i++)
     {
      if(Orders2[i].ticket == ticket)
        {
         if(i < n-1)
           {
            Orders2[i] = Orders2[n-1];
           }
         ArrayResize(Orders2, n-1);
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders()
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == _Symbol)
           {
            if(OrderType() == OP_BUY || OrderType() == OP_SELL)
              {
               bool res = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 99, OrderType() == OP_BUY ? clrBlue : clrRed);
              }
            else
               if(OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP || OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT)
                 {
                  bool res = OrderDelete(OrderTicket(), (OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT) ? clrBlue : clrRed);
                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveSL(double sl)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == _Symbol)
           {
            if(OrderType() == OP_BUY)
              {
               bool res = OrderModify(OrderTicket(), OrderLots(), sl,OrderTakeProfit(), clrBlue);
              }
            else
               if(OrderType() == OP_SELL)
                 {
                  bool res = OrderModify(OrderTicket(), OrderLots(), sl,OrderTakeProfit(), clrRed);

                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveBE()
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == _Symbol)
           {
            if(OrderType() == OP_BUY)
              {
               double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point;
               if(OrderClosePrice() - OrderOpenPrice() > stopLevel)
                 {
                  if(StopLossHidden)
                    {
                     string obj = WindowExpertName()+"SL"+(string)OrderTicket();
                     if(ObjectFind(0, obj) >= 0)
                       {
                        ObjectSetDouble(0, obj, OBJPROP_PRICE, OrderOpenPrice());
                       }
                    }
                  else
                    {
                     if(OrderOpenPrice() - OrderStopLoss() > stopLevel)
                       {
                        bool res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, clrBlue);
                       }
                     else
                       {
                        PrintFormat("Move BE not done, current price is too close to order's price. Stop level is %g", stopLevel);
                       }
                    }
                 }
              }
            else
               if(OrderType() == OP_SELL)
                 {
                  double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point;
                  if(OrderOpenPrice() - OrderClosePrice() > stopLevel)
                    {
                     if(StopLossHidden)
                       {
                        string obj = WindowExpertName()+"SL"+(string)OrderTicket();
                        if(ObjectFind(0, obj) >= 0)
                          {
                           ObjectSetDouble(0, obj, OBJPROP_PRICE, OrderOpenPrice());
                          }
                       }
                     else
                       {
                        if(OrderStopLoss() - OrderOpenPrice() > stopLevel)
                          {
                           bool res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, clrRed);
                          }
                        else
                          {
                           PrintFormat("Move BE not done, current price is too close to order's price. Stop level is %g", stopLevel);
                          }
                       }
                    }
                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLevel(const string code, double price, const bool show)
  {
   if(!show)
     {
      price = 0;
     }
   string obj = WindowExpertName()+"VIS"+code;
   if(ObjectFind(0, obj) < 0)
     {
      ObjectCreate(0, obj, OBJ_HLINE, 0, 0, price);
     }
   else
     {
      ObjectSetDouble(0, obj, OBJPROP_PRICE, price);
      Print("BBB");
     }
   color clr;
   if(code == "ENTRY")
     {
      clr = clrOrange;
     }
   else
      if(code == "SL")
        {
         clr = clrRed;
        }
      else
        {
         clr = clrBlue;
        }
   ObjectSetInteger(0, obj, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, obj, OBJPROP_SELECTED, true);
   ObjectSetInteger(0, obj, OBJPROP_WIDTH, 2);
   ObjectSetString(0, obj, OBJPROP_TOOLTIP, "\n");
   ObjectSetInteger(0, obj, OBJPROP_ZORDER, 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawNewsLine(CALENDAR_INFO &cals[])
  {
   datetime gmt = TimeGMT();
//NewsCountBefore
//int beforeIndexes[], afterIndexes[];
   int highlightIndex = -1;
   datetime highlightTime = 0;

   int idxBegin = -1, idxEnd = -1;
   for(int i=0; i<ArraySize(cals); i++)
     {
      if(cals[i].time >= gmt)
        {
         if(idxBegin == -1)
           {
            //PrintFormat("Date %s, title %s", TimeToStr(cals[i].time), cals[i].title);
            idxBegin = (int)fmax(0, i-NewsCountBefore);
            highlightIndex = i;
           }
         idxEnd = (int)fmin(ArraySize(cals)-1, i+NewsCountAfter-1);
         break;
        }
     }

   if(idxBegin == -1)
     {
      idxBegin = ArraySize(cals)-NewsCountBefore;
      idxEnd = ArraySize(cals)-1;
     }


   int w,h;
   TextGetSize("A", w, h);
   int rowHeight = (int)round(1.2*h);
   int y=rowHeight+4;

   int w1,h1;
   TextGetSize(">>", w1, h1);
   ObjectsDeleteAll(0, WindowExpertName()+"NEWS", 0, OBJ_TEXT);
   int count=0;
//PrintFormat("idxBegin %d, idxEnd %d", idxBegin, idxEnd);
   for(int i=idxEnd; i>=idxBegin; i--)
     {
      string sTime = TimeToStr(cals[i].time+TimeOffset);
      if(cals[i].impact == 3)
        {
         sTime = "All Day";
        }
      CreateLabel("NEWS_"+(string)count, NewsRightMargin, y, sTime+" ["+cals[i].country+"] "+cals[i].title, NEWS_COLORS[cals[i].impact], CORNER_RIGHT_LOWER);
      if(i == highlightIndex)
        {
         CreateLabel("NEWS_HIGHLIGHT", NewsRightMargin+w1+4, y, ">>", clrLime, CORNER_RIGHT_LOWER);
        }
      //Print(TimeToStr(cals[k].time)+" "+cals[k].title);
      y+= rowHeight;
      count++;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabel(const string name, const int x, const int y, const string text, const color clr, const ENUM_BASE_CORNER corner, const int _fontSize=0)
  {
   string obj = WindowExpertName()+name;
   if(ObjectFind(0, obj) < 0)
     {
      ObjectCreate(0, obj, OBJ_LABEL,0,0,0);
     }

   int fontSize = _fontSize == 0 ? FontSize : _fontSize;

   ObjectSetInteger(0, obj, OBJPROP_ALIGN,ALIGN_LEFT);
   ObjectSetInteger(0, obj, OBJPROP_CORNER, corner);
   ObjectSetString(0, obj, OBJPROP_TEXT, text);
   ObjectSetInteger(0, obj, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, obj, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, obj, OBJPROP_COLOR, clr);
   ObjectSetString(0, obj, OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, obj, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, obj, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, obj, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, obj, OBJPROP_HIDDEN, false);
   ObjectSetString(0, obj, OBJPROP_TOOLTIP, "\n");
  }

// void PlaceTP(double sl) {
// for (int i=0; i<OrdersTotal(); i++) {
//    if (OrderSelect(i, SELECT_BY_POS)) {
//       if (OrderSymbol() == _Symbol) {
//          if (OrderStopLoss() == 0) {
//             double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point;
//             if (OrderType() == OP_BUY) {
//             double sl = ObjectGetDouble(0, WindowExpertName()+"VISSL", OBJPROP_PRICE);
//                bool res = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), clrBlue);
//                }
//             else if (OrderType() == OP_SELL) {
//                double sl = ObjectGetDouble(0, WindowExpertName()+"VISSL", OBJPROP_PRICE);
//                   bool res = OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), clrRed);


//                }
//             }
//          }
//       }
//    }
// }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PartialClose(const double pctClose)
  {
   bool check=false;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == _Symbol && (OrderType() == OP_BUY || OrderType() == OP_SELL))
           {
            double lotToClose = NormalizeLot(pctClose/100*OrderLots());
            if(fabs(OrderLots() - lotToClose) > 0.001)
              {
               bool res = OrderClose(OrderTicket(), lotToClose, OrderClosePrice(), 99, OrderType() == OP_BUY ? clrBlue : clrRed);
               if(!res)
                 {
                  Alert(StringFormat("Partial closing order #%d failed with error %s", OrderTicket(), ErrorDescription(GetLastError())));
                 }
               else
                 {
                  check = true;
                 }
              }
            else
              {
               Alert(StringFormat("Cannot partial close #%d, lot size is too small!", OrderTicket()));
              }
           }
        }
     }

   if(check)
     {
      UpdateSLLine();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
  {
   if(lot > 0)
     {
      double LotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      lot = floor(lot / LotStep) * LotStep;
      lot = fmax(lot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
      lot = fmin(lot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
     }
   return lot;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckMaxPositions()
  {
   int count=0;
   bool res=true;
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == _Symbol && (OrderType() == OP_BUY || OrderType() == OP_SELL))
           {
            count++;
            if(count+1 > MaxPositions)
              {
               Alert("Max positions reached!");
               res = false;
               break;
              }
           }
        }
     }
   return res;
  }

//bool CheckMaxRisk(const double lot, const double riskSL) {
// double valuePerLot = MarketInfo(_Symbol, MODE_TICKVALUE) / MarketInfo(Symbol(), MODE_TICKSIZE);
// double riskMoney = lot*riskSL*valuePerLot;
// PrintFormat("Risk ($) %g, balance %g, risk (%%) %g, max risk %g %%", riskMoney, AccountBalance(), riskMoney/AccountBalance()*100, MaxRisk);
// bool res = riskMoney/AccountBalance() <= MaxRisk/100;
// if (!res) {
//    Alert("Risk is too high!");

//}
//return res;
//}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TakeScreenshot()
  {
   string file = WindowExpertName()+"\\"+StringFormat("%04d%02d%02d_%02d_%02d_%s.png", Year(), Month(), Day(), Hour(), Minute(), _Symbol);
   ChartScreenShot(0, file, 800, 600);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewOrderClosed()
  {
   bool res = false;

   for(int i=0; i<ArraySize(Tickets); i++)
     {
      if(OrderSelect(Tickets[i], SELECT_BY_TICKET))
        {
         if(OrderCloseTime() > 0)
           {
            res = true;
            break;
           }
        }
     }

   ArrayResize(Tickets, 0);
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i, SELECT_BY_POS))
        {
         if(OrderSymbol() == _Symbol)
           {
            int n = ArraySize(Tickets);
            ArrayResize(Tickets, n+1);
            Tickets[n] = OrderTicket();
           }
        }
     }

   return res;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateSLLine()
  {
   if(StopLossHidden)
     {
      for(int i=0; i<OrdersTotal(); i++)
        {
         if(OrderSelect(i, SELECT_BY_POS))
           {
            if(OrderSymbol() == _Symbol)
              {
               if(StringFind(OrderComment(), "from #") == 0)
                 {
                  string result[];
                  int count = StringSplit(OrderComment(), ' ', result);
                  if(count == 2)
                    {
                     if(StringGetCharacter(result[1], 0) == '#')
                       {
                        string tmp = StringSubstr(result[1], 1);
                        int ticket = (int)StringToInteger(tmp);
                        if(ticket > 0)
                          {
                           string obj = WindowExpertName()+"SL"+(string)ticket;
                           if(ObjectFind(0, obj) >= 0)
                             {
                              double sl = ObjectGetDouble(0, obj, OBJPROP_PRICE);
                              int k = IndexByTicket2(OrderTicket());
                              if(k < 0)
                                {
                                 AddHiddenOrders(OrderTicket(), sl, OrderType());
                                }
                              obj = WindowExpertName()+"SL"+(string)OrderTicket();
                              if(ObjectFind(0, obj) < 0)
                                {
                                 DrawSL(OrderTicket(), sl);
                                }
                             }
                          }
                       }
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
double DailyProfit()
  {
   double profit = 0;
   int i,hstTotal=OrdersHistoryTotal();
   for(i=0; i<hstTotal; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==TRUE)
        {
         if(TimeToStr(TimeLocal(),TIME_DATE) == TimeToStr(OrderCloseTime(),TIME_DATE))
           {
            profit += OrderProfit() + OrderSwap() + OrderCommission();
           }
        }
     }
   return(profit);
  }
//+------------------------------------------------------------------+
short countOfTradeOnCurSymbol()
  {
   short counter=0;
   for(int i = 0; i < OrdersTotal(); i++)
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         if(OrderSymbol() == Symbol())
            if(OrderType()==OP_BUY||OrderType()==OP_SELL)
               counter++;
   return counter;
  }
//+------------------------------------------------------------------+
