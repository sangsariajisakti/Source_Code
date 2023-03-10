#property copyright    "Copyright, EA "
#property link         "NOT FOR PUBLIC "
#property description "TREND Trading System"
#property strict

enum LOT_TYPE {
   FIXED,
   PERCENT
};

enum Conditions {
   Condition_1,
   Condition_2,
   Condition_3,
   Condition_4
};

datetime time_d;
datetime Candle_Time;
int timeframe;
bool New_Bar=false;
bool upward_filter, downward_filter;
int pos_108;

sinput string  INFO1_0;                                  //. 
sinput string  INFO1_1;                                  // VOLUME
bool           Virtual_Pending_Stop       = true;        // Virtual Pending Stop
extern         Conditions Trading_Pattern = Condition_1;
extern bool    Virtual_Stop_Loss          = false;       // Virtual Stop Loss
extern int     Time_To_Wait               = 0;           // Time to wait:
extern double  Time_to_Delete_Orders      = 1.0;         // Time to delete Order:
extern int     Filter                     = 50;          // Filter:
extern int     PullBack                   = 10;          // Pull Back:
extern double  LotsSize                   = 0.1;         // Lote Size:

sinput string  INFO2_0;                                  //. 
sinput string  INFO2_1;                                  //PROTECTION 
input LOT_TYPE lot_type                   = FIXED;       //Lot Type:
input double   lot                        = 0.01;        //Lots:
extern double  LotsPer1000=0.0;
//extern double MinLots = 0.01;
extern double  MaxLots                    = 15.0;
extern double  def_MaxSpread              = 100;         //Max Spread:

sinput string  INFO3_0;                                  //. 
sinput string  INFO3_1;                                  //CONFIRMATION(Super Trend) 
extern int     SignalGap                  = 0;           //Signal Gap:
extern int     ShowBars                   = 500;         //Show Bars:
extern double  def_SL                     = 10.0;
extern int     MyMagicNumber              = 68000;
extern string  Comment_                   ="Waygrow";
extern int     delay_seconds              = 0;


sinput string  INFO4_0;                                  //. 
sinput string  INFO4_1;                                  //TRAILING SETTINGS  
input int      trail_start                = 20;          //Trailing Start              
input int      trail_step                 = 10;          //Trailing Step                
double tste,trade,tsta;

//yiyi-int Gi_180=0;
//yiyi-double G_pips_184= 0.0;
int G_digits_192 = 0;
double G_point_196=0.0;
int Gi_204;
double Gd_208;
double Gd_216;
double Gd_224;
double Gd_232;
double Gd_240;
double Gd_248;
double Gd_256;
int G_slippage_264=3;
bool Gi_268;
double Gd_272;
double Gda_280[30];
int Gi_284=0;
string Gs_dummy_288;
string Gs_unused_316 = "";
string Gs_unused_324 = "";
double Gd_336;
double Gd_344;
int G_time_352;
int Gi_356;
int G_datetime_360;
string Gs_364 = "000,000,000";
string Gs_372 = "000,000,255";
int Gi_380;
int Gi_384;
int StopLoss;
double Risk;
bool UseMM;
double MaxSpreadPlusCommission=10000.0;
extern double Limit=50;
extern double Distance = 21;
int MAPeriod = 3;
int MAMethod = 3;
string TimeFilter="----------Time Filter";
int StartHour=0;
int StartMinute=0;
int EndHour=23;
int EndMinute=59;
int Gi_388;
int Gi_392=40;
double G_timeframe_396=240.0;
bool Gi_404=TRUE;
color G_color_408 = DimGray;
string G_name_412 = "SpreadIndikatorObj";
double Gd_420;
color G_color_428 = Red;
color G_color_432 = DarkGray;
color G_color_436 = SpringGreen;
bool Gi_440=TRUE;
double G_ihigh_444;
double G_ilow_452;
double Gd_460;
int G_datetime_468;
int Delay2;
datetime delay_;
datetime HL_time;
int Del_Line;

string HL_BS="V_BS";
string HL_SS="V_SS";

double HL_BS_Value;
double HL_SS_Value;
// E37F0136AA3FFAF149B351F6A4C948E9
int init()
  {
   if(Period()==PERIOD_M1)
     {
         timeframe = 1 * 60;
     }
   else if(Period()==PERIOD_M5)
     {
         timeframe = 5 * 60;
     }
   else if(Period()==PERIOD_M15)
     {
         timeframe = 15 * 60;
     }
   else if(Period()==PERIOD_M30)
     {
         timeframe = 30 * 60;
     }
   else if(Period()==PERIOD_H1)
     {
         timeframe = 1 * 60 * 60;
     }
   else if(Period()==PERIOD_H4)
     {
         timeframe = 4 * 60 * 60;
     }
   else if(Period()==PERIOD_D1)
     {
         timeframe = 24 * 60 * 60;
     }
  
  
  
   Chart_Properties();
   StopLoss=def_SL*10.0;
   def_MaxSpread=def_MaxSpread*10;
   if(LotsSize==0.0)
     {
      UseMM=TRUE;
     }
   else
     {
      UseMM=FALSE;
     }
   Risk=LotsPer1000*20;
   int timeframe_8;
   ArrayInitialize(Gda_280,0);
   G_digits_192= Digits;//updated*Yiyi
   G_point_196 = Point;//updated*Yiyi
   Print("Digits: "+(string)Digits+" Point: "+DoubleToStr(Point,Digits));
   double lotstep_0=MarketInfo(Symbol(),MODE_LOTSTEP);
   Gi_204 = MathLog(lotstep_0) / MathLog(0.1);
   Gd_208 = MathMax(trade, MarketInfo(Symbol(), MODE_MINLOT));
   Gd_216 = MathMin(MaxLots, MarketInfo(Symbol(), MODE_MAXLOT));
   Gd_224 = Risk / 100.0;
   Gd_232 = NormalizeDouble(MaxSpreadPlusCommission * Point, Digits + 1);
   Gd_240 = NormalizeDouble(Limit * Point, Digits);
   Gd_248 = NormalizeDouble(Distance * Point, Digits);
   Gd_256 = NormalizeDouble(Point * Filter, Digits);
   Gi_268 = FALSE;
   Gd_272 = NormalizeDouble(0.0 * Point, Digits + 1);
   if(!IsTesting())
     {
//      f0_8();
      if(Gi_404)
        {
         timeframe_8=Period();
         switch(timeframe_8)
           {
            case PERIOD_M1:
               G_timeframe_396=5;
               break;
            case PERIOD_M5:
               G_timeframe_396=15;
               break;
            case PERIOD_M15:
               G_timeframe_396=30;
               break;
            case PERIOD_M30:
               G_timeframe_396=60;
               break;
            case PERIOD_H1:
               G_timeframe_396=240;
               break;
            case PERIOD_H4:
               G_timeframe_396=1440;
               break;
            case PERIOD_D1:
               G_timeframe_396=10080;
               break;
            case PERIOD_W1:
               G_timeframe_396=43200;
               break;
            case PERIOD_MN1:
               G_timeframe_396=43200;
           }
        }
      Gd_420=0.0001;
      f0_7();
      f0_2();
      f0_0();
      f0_3();
     }
   return (0);
  }
// 52D46093050F38C27267BCE42543EF60
int deinit()
  {
   if(!IsTesting())
     {
      for(int Li_0=1; Li_0<=Gi_392; Li_0++) ObjectDelete("Padding_rect"+(string)Li_0);
      for(int count_4=0; count_4<10; count_4++)
        {
         ObjectDelete("BD"+(string)count_4);
         ObjectDelete("SD"+(string)count_4);
        }
      ObjectDelete("time");
      ObjectDelete(G_name_412);
     }
   Comment("");
   ObjectDelete("B3LLogo");
   ObjectDelete("B3LCopy");
   ObjectDelete("FiboUp");
   ObjectDelete("FiboDn");
   ObjectDelete("FiboIn");
   return (0);
  }
// EA2B2676C28C0DB26D39331A336C6B92
int start()
  {
  
   static datetime New_Time=0;                  // Time of the current bar
   New_Bar=false;                               // No new bar
   if(New_Time!=Time[0])                        // Compare time
     {
      New_Time=Time[0];                         // Now time is so
      New_Bar=true;                             // A new bar detected
      
      time_d = TimeCurrent() + timeframe;
     }
  
  
   if (trail_start>0)   
       ts();

   int Account = 0;//Enter account to lock number here
   datetime Expiry=D'15.05.2052';
   if(TimeCurrent()>Expiry)
     {
      Alert(WindowExpertName()+" Trial Expired");
      ExpertRemove();
     } else {
   if(Account>0&&AccountNumber()!=Account)
     {
      Alert((string)AccountNumber()+" is not Linked to the EA");
      ExpertRemove();
     } else    
   if(Account==0||AccountNumber()==Account){

//StopLoss = StopLoss + MarketInfo(Symbol(),MODE_SPREAD);
   int error_8;
   string Ls_12;
   int ticket_20;
   double price_24;
   double Price_25;
   bool bool_32;
   double Ld_36;
//   double Ld_44;
   double price_60;
   double Ld_112;
   int Li_180;
   int cmd_188;
   double Ld_196;
   double Ld_204;
   double ihigh_68= iHigh(NULL,0,0);
   double ilow_76 = iLow(NULL,0,0);
   
   double ss_red   = iCustom(NULL, 0, "super-signals-channel", SignalGap, ShowBars, 2,0);
   double ss_green = iCustom(NULL, 0, "super-signals-channel", SignalGap, ShowBars, 3,0);
   
   upward_filter = false;
   downward_filter = false;
   
   if (High[0]==ss_red /*&& Close[0]>Open[0]*/ && ((High[0]- Close[0])>=(PullBack*Point)))
      {
         upward_filter = true;
         if (delay_==0)delay_ = TimeCurrent();
         //Comment(upward_filter,", ", ((High[0]- Close[0])/Point), ", ", ((ihigh_68-ilow_76)/Point), ", ", Delay2);
         
      }
   
   if (Low[0]==ss_green /*&& Close[0]<Open[0]*/ && ((Close[0]- Low[0])>=(PullBack*Point)))
      {
         downward_filter = true;
         if (delay_==0) delay_ = TimeCurrent();
         //Comment(downward_filter, ", ", ((Close[0]- Low[0])/Point), ", ", ((ihigh_68-ilow_76)/Point), ", ", Delay2);
      }   
      
     if (upward_filter==false && downward_filter==false) 
         {
            Delay2 = 0;
            delay_ = 0;
         }
     else Delay2 = TimeCurrent() - delay_;
    
      //Comment(downward_filter, ", ", upward_filter, ", ", TimeToStr(delay_), ", ",TimeToStr(TimeCurrent()), ", ",  Delay2, ", ",  delay_seconds);
   
   
   //Comment(ss_red,": ",Bid,": ","\n",ss_green,": ",Bid);

//   double irsi_96=iRSI(Symbol(),Period(),RSI_PARAM,PRICE_CLOSE,0);

   if(!Gi_268)
     {
      for(pos_108=OrdersHistoryTotal()-1; pos_108>=0; pos_108--)
        {
         if(OrderSelect(pos_108,SELECT_BY_POS,MODE_HISTORY))
           {
            if(OrderProfit()!=0.0)
              {
               if(OrderClosePrice()!=OrderOpenPrice())
                 {
                  if(OrderSymbol()==Symbol())
                    {
                     Gi_268 = TRUE;
                     Ld_112 = MathAbs(OrderProfit() / (OrderClosePrice() - OrderOpenPrice()));
                     Gd_272 = (-OrderCommission()) / Ld_112;
                     break;
                    }
                 }
              }
           }
        }
     }

   double Ld_120=Ask-Bid;
   ArrayCopy(Gda_280,Gda_280,0,1,29);
   Gda_280[29]=Ld_120;
   if(Gi_284<30) Gi_284++;
   double Ld_128=0;
   pos_108=29;
   for(int count_136=0; count_136<Gi_284; count_136++)
     {
      Ld_128+=Gda_280[pos_108];
      pos_108--;
     }
   double Ld_140 = Ld_128 / Gi_284;
   double Ld_148 = NormalizeDouble(Ask + Gd_272, Digits);
   double Ld_156 = NormalizeDouble(Bid - Gd_272, Digits);
   double Ld_164 = NormalizeDouble(Ld_140 + Gd_272, Digits + 1);
   double Ld_172 = ihigh_68 - ilow_76;
   //Comment("\n","\n","\n"," Diff: ",Ld_172," Filter: ",Gd_256);
   if((Ld_172>Gd_256 && Filter>0) || Filter==0)
     {
      //Comment("\n","\n","\n","\n","\n"," Diff: ",Ld_172," Filter: ",Gd_256," True");
      if(downward_filter==true && Delay2>=delay_seconds) Li_180=-1;
      else
         if(upward_filter==true && Delay2>=delay_seconds) Li_180=1;
     }
   int count_184=0;
   for(pos_108=0; pos_108<OrdersTotal(); pos_108++)
     {
      if(OrderSelect(pos_108,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderMagicNumber()==MyMagicNumber)
           {
            cmd_188=OrderType();
            if(cmd_188==OP_BUYLIMIT || cmd_188==OP_SELLLIMIT) continue;
            if(OrderSymbol()==Symbol())
              {
               count_184++;
               switch(cmd_188)
                 {
/*                  case OP_BUY:
                     if(Distance<0) break;
                     Ld_44=NormalizeDouble(OrderStopLoss(),Digits);
                     price_60=NormalizeDouble(Bid-Gd_248,Digits);
                     if(!(Bid > (OrderOpenPrice() + tsta)&&OrderStopLoss()<OrderOpenPrice())) break;
                     bool_32=OrderModify(OrderTicket(),OrderOpenPrice(),price_60,OrderTakeProfit(),0,Lime);
                     if(!(!bool_32)) break;
                     error_8=GetLastError();
                     Print("BUY Modify Error Code: "+error_8+" Message: "+Ls_12+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+DoubleToStr(price_60,Digits)+
                           " Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                     break;
                  case OP_SELL:
                     if(Distance<0) break;
                     Ld_44=NormalizeDouble(OrderStopLoss(),Digits);
                     price_60=NormalizeDouble(Ask+Gd_248,Digits);
                     if(!((Ld_44==0.0 || price_60<Ld_44))) break;
                     bool_32=OrderModify(OrderTicket(),OrderOpenPrice(),price_60,OrderTakeProfit(),0,Orange);
                     if(!(!bool_32)) break;
                     error_8=GetLastError();
                     Print("SELL Modify Error Code: "+error_8+" Message: "+Ls_12+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+DoubleToStr(price_60,Digits)+
                           " Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                     break;
*/                  case OP_BUYSTOP:
                     if (Virtual_Stop_Loss==false)
                        {
                           Ld_36=NormalizeDouble(OrderOpenPrice(),Digits);
                           //Comment("Buy: ",Ld_36);
                           price_24=NormalizeDouble(Ask+Gd_240,Digits);
                           if(!((price_24<Ld_36))) break;
                           price_60= NormalizeDouble(price_24 -(StopLoss+MarketInfo(Symbol(),MODE_SPREAD)) * Point,Digits);
                           bool_32 = OrderModify(OrderTicket(),price_24,price_60,OrderTakeProfit(),0,Lime);
                           if(!(!bool_32)) break;
                           error_8=GetLastError();
                           Print("BUYSTOP Modify Error Code: "+(string)error_8+" Message: "+Ls_12+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+DoubleToStr(price_60,Digits)+
                                 " Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                           break;
                        }
                    else if (Virtual_Stop_Loss==true)
                        {
                           Ld_36=NormalizeDouble(OrderOpenPrice(),Digits);
                           //Comment("Buy: ",Ld_36);
                           price_24=NormalizeDouble(Ask+Gd_240,Digits);
                           if(!((price_24<Ld_36))) break;
                           price_60=0;
                           bool_32 = OrderModify(OrderTicket(),price_24,price_60,OrderTakeProfit(),0,Lime);
                           if(!(!bool_32)) break;
                           error_8=GetLastError();
                           Print("BUYSTOP Modify Error Code: "+(string)error_8+" Message: "+Ls_12+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+DoubleToStr(price_60,Digits)+
                                 " Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                           break;
                        }
                  case OP_SELLSTOP:
                      if (Virtual_Stop_Loss==false)
                        {
                           Ld_36=NormalizeDouble(OrderOpenPrice(),Digits);
                           //Comment("Sell: ",Ld_36);
                           price_24=NormalizeDouble(Bid-Gd_240,Digits);
                           if(!((price_24>Ld_36))) break;
                           price_60= NormalizeDouble(price_24+(StopLoss+MarketInfo(Symbol(),MODE_SPREAD)) * Point,Digits);
                           bool_32 = OrderModify(OrderTicket(),price_24,price_60,OrderTakeProfit(),0,Orange);
                           if(!(!bool_32)) break;
                           error_8=GetLastError();
                           Print("SELLSTOP Modify Error Code: "+(string)error_8+" Message: "+Ls_12+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+DoubleToStr(price_60,Digits)+
                                 " Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                        }
                      else if (Virtual_Stop_Loss==true)
                        {
                           Ld_36=NormalizeDouble(OrderOpenPrice(),Digits);
                           //Comment("Sell: ",Ld_36);
                           price_24=NormalizeDouble(Bid-Gd_240,Digits);
                           if(!((price_24>Ld_36))) break;
                           price_60=0;
                           bool_32 = OrderModify(OrderTicket(),price_24,price_60,OrderTakeProfit(),0,Orange);
                           if(!(!bool_32)) break;
                           error_8=GetLastError();
                           Print("SELLSTOP Modify Error Code: "+(string)error_8+" Message: "+Ls_12+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+DoubleToStr(price_60,Digits)+
                                 " Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                        }
                 }
              }
           }
        }
     }
   if(count_184==0 && Li_180!=0 && Ld_164<=Gd_232 && f0_4())
     {
      trade = lot;
      if(lot_type == PERCENT) {
          trade = lot / 100 * AccountBalance() / 1000;
   } else {
          trade = lot;
          }

      Ld_196=AccountBalance()*AccountLeverage()*Gd_224;
      if(!UseMM) Ld_196=LotsSize;
      Ld_204 = NormalizeDouble(Ld_196 / MarketInfo(Symbol(), MODE_LOTSIZE), Gi_204);
      Ld_204 = MathMax(Gd_208, Ld_204);
      Ld_204 = MathMin(Gd_216, Ld_204);
      if(Li_180<0)
        {
         price_24 = NormalizeDouble(Ask + Gd_240, Digits);
         if (Virtual_Stop_Loss==false) price_60 = NormalizeDouble(price_24 - (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
         else if (Virtual_Stop_Loss==true) price_60=0;

         if(MarketInfo(Symbol(),MODE_SPREAD)<def_MaxSpread && Virtual_Pending_Stop==false) ticket_20=OrderSend(Symbol(),OP_BUYSTOP,trade,price_24,G_slippage_264,price_60,0,Comment_,MyMagicNumber,0,Lime);   
         else if(MarketInfo(Symbol(),MODE_SPREAD)<def_MaxSpread && Virtual_Pending_Stop==true && (Trading_Pattern==Condition_1 || Trading_Pattern==Condition_2) && HL_BS_Value==0) 
               {
                  ObjectCreate(0,HL_BS,OBJ_HLINE,0,TimeCurrent(),price_24);
                  ObjectSetInteger(0, HL_BS, OBJPROP_STYLE, STYLE_SOLID);
                  ObjectSetInteger(0, HL_BS, OBJPROP_COLOR, Lime);
                  ObjectSetInteger(0, HL_BS, OBJPROP_BACK, TRUE);
                  ObjectSetInteger(0, HL_BS, OBJPROP_WIDTH, 2);
                  
                  HL_time = TimeCurrent();    
               }
         else if(MarketInfo(Symbol(),MODE_SPREAD)<def_MaxSpread && Virtual_Pending_Stop==true && (Trading_Pattern==Condition_3 || Trading_Pattern == Condition_4)  && HL_SS_Value==0) 
               {
                  Price_25 = NormalizeDouble(Bid - Gd_240, Digits);
                  ObjectCreate(0,HL_SS,OBJ_HLINE,0,TimeCurrent(),Price_25);
                  ObjectSetInteger(0, HL_SS, OBJPROP_STYLE, STYLE_SOLID);
                  ObjectSetInteger(0, HL_SS, OBJPROP_COLOR, Crimson);
                  ObjectSetInteger(0, HL_SS, OBJPROP_BACK, TRUE);
                  ObjectSetInteger(0, HL_SS, OBJPROP_WIDTH, 2);  
                  
                  HL_time = TimeCurrent();  
               }
         if(Virtual_Pending_Stop==false && ticket_20<=0)
           {
            error_8=GetLastError();
            Print("BUYSTOP Send Error Code: "+(string)error_8+" Message: "+Ls_12+" LT: "+DoubleToStr(Ld_204,Gi_204)+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+
                  DoubleToStr(price_60,Digits)+" Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
           }
           
           } 
           else {
         price_24 = NormalizeDouble(Bid - Gd_240, Digits);
         if (Virtual_Stop_Loss==false) price_60 = NormalizeDouble(price_24 + (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
         else if (Virtual_Stop_Loss==true) price_60=0;
         //Print("HHHHHHHHHH");
         if(MarketInfo(Symbol(),MODE_SPREAD)<def_MaxSpread && Virtual_Pending_Stop==false) ticket_20=OrderSend(Symbol(),OP_SELLSTOP,trade,price_24,G_slippage_264,price_60,0,Comment_,MyMagicNumber,0,Orange);
         else if(MarketInfo(Symbol(),MODE_SPREAD)<def_MaxSpread && Virtual_Pending_Stop==true && (Trading_Pattern==Condition_1 || Trading_Pattern==Condition_2) && HL_SS_Value==0)
               {
                  ObjectCreate(0,HL_SS,OBJ_HLINE,0,TimeCurrent(),price_24);
                  ObjectSetInteger(0, HL_SS, OBJPROP_STYLE, STYLE_SOLID);
                  ObjectSetInteger(0, HL_SS, OBJPROP_COLOR, Crimson);
                  ObjectSetInteger(0, HL_SS, OBJPROP_BACK, TRUE);
                  ObjectSetInteger(0, HL_SS, OBJPROP_WIDTH, 2);  
                  
                  HL_time = TimeCurrent();  
               }
         else if(MarketInfo(Symbol(),MODE_SPREAD)<def_MaxSpread && Virtual_Pending_Stop==true && (Trading_Pattern==Condition_3 || Trading_Pattern == Condition_4) && HL_BS_Value==0) 
               {
                  Price_25 = NormalizeDouble(Ask + Gd_240, Digits);
                  ObjectCreate(0,HL_BS,OBJ_HLINE,0,TimeCurrent(),Price_25);
                  ObjectSetInteger(0, HL_BS, OBJPROP_STYLE, STYLE_SOLID);
                  ObjectSetInteger(0, HL_BS, OBJPROP_COLOR, Lime);
                  ObjectSetInteger(0, HL_BS, OBJPROP_BACK, TRUE);
                  ObjectSetInteger(0, HL_BS, OBJPROP_WIDTH, 2);  
                  
                  HL_time = TimeCurrent();  
               }
         if(Virtual_Pending_Stop==false && ticket_20<=0)
           {
            error_8=GetLastError();
            Print("BUYSELL Send Error Code: "+(string)error_8+" Message: "+Ls_12+" LT: "+DoubleToStr(Ld_204,Gi_204)+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+
                  DoubleToStr(price_60,Digits)+" Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
           }
        }
     }
//Comment("Time: ", TimeToString(HL_time), " Time Current: ", TimeToString(TimeCurrent()),  " Diff: ", (((double)(TimeCurrent() - HL_time))/60));
     
if((((double)(TimeCurrent() - HL_time))/60) >= Time_to_Delete_Orders && (HL_BS_Value>0 || HL_SS_Value>0))
  {
      ObjectDelete(0, HL_SS);
      ObjectDelete(0, HL_BS);
      
      Sleep((time_d - TimeCurrent()) * 1000);
  }     
     
HL_BS_Value = ObjectGetDouble(0,HL_BS, OBJPROP_PRICE);
HL_SS_Value = ObjectGetDouble(0,HL_SS, OBJPROP_PRICE);

BS(HL_BS_Value);
SS(HL_SS_Value);

Check_SL(MyMagicNumber);

delay();

//Comment(trade);
if (count_184==0) Sell_Stop(HL_SS_Value);
if (count_184==0) Buy_Stop(HL_BS_Value);
     
   string Ls_212="AvgSpread:"+DoubleToStr(Ld_140,Digits)+"  Commission rate:"+DoubleToStr(Gd_272,Digits+1)+"  Real avg. spread:"+DoubleToStr(Ld_164,
                                          Digits+1);
   if(Ld_164>Gd_232)
     {
      Ls_212=Ls_212
             +"\n"
             +"The EA can not run with this spread ( "+DoubleToStr(Ld_164,Digits+1)+" > "+DoubleToStr(Gd_232,Digits+1)+" )";
     }
   if(count_184!=0 || Li_180!=0)
     {
     }
   if(!IsTesting())
     {
      f0_2();
      f0_7();
      f0_0();
      f0_3();
//      f0_8();
     }
  }}
     return (0);
}
// 3B8B9927CE5F3E077818404E64D1C252
//+------------------------------------------------------------------+
void ts() 
  {
   tsta = (trail_start+0.2)*Point()*10 ;
   tste = (trail_step+0.2)*Point()*10;
//   tsto = trailsto*Point();

 for(int i = OrdersTotal()-1; i>=0; i--){
      if(OrderSelect(i,SELECT_BY_POS)){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MyMagicNumber){
            if(OrderType()==OP_BUY){
              if (Bid > (OrderOpenPrice() + tsta)&&OrderStopLoss()<OrderOpenPrice()&&trail_start>0){
                if(!OrderModify(OrderTicket(),OrderOpenPrice(), Bid - tsta, OrderTakeProfit(), 0, clrGreen)){
                  Print("Order Start Modify Error: ",GetLastError());
                 }
               }
              if (Bid > (OrderStopLoss() + 2*tste)&&OrderStopLoss()>OrderOpenPrice()&&trail_step>0){
                if(!OrderModify(OrderTicket(),OrderOpenPrice(), OrderStopLoss() + tste, OrderTakeProfit(), 0, clrGreen)){
                  Print("Order Step Modify Error: ",GetLastError());
                 }
               }
/*              if (Bid > (OrderOpenPrice() + tsto)){
                 if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), slippage)) {
                  Print("Order Close Error: ", GetLastError());
                }
              }
*/            }
            if(OrderType()==OP_SELL){
              if (Ask < (OrderOpenPrice() - tsta)&&OrderStopLoss()>=OrderOpenPrice()&&trail_start>0){
                if(!OrderModify(OrderTicket(),OrderOpenPrice(), Ask + tsta, OrderTakeProfit(), 0, clrRed)){
                  Print("Order Start Modify Error: ",GetLastError());
                 }
               }
              if (Ask < (OrderStopLoss() - 2*tste)&&OrderStopLoss()<=OrderOpenPrice()&&trail_step>0){
                if(!OrderModify(OrderTicket(),OrderOpenPrice(), OrderStopLoss() - tste, OrderTakeProfit(), 0, clrRed)){
                  Print("Order Step Modify Error: ",GetLastError());
                 }
               }
/*              if (Ask < (OrderOpenPrice() - tsto)){
                 if(!OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), slippage)) {
                  Print("Order Close Error: ", GetLastError());
                }
              }
*/            }
          }
        }
     }
}
int f0_4()
  {
   if((Hour() > StartHour && Hour() < EndHour) || (Hour() == StartHour && Minute() >= StartMinute) || (Hour() == EndHour && Minute() < EndMinute)) return (1);
   return (0);
  }
// DFF63C921B711879B02EDBCAFB9A05B0
/*void f0_8()
  {
   Gd_336 = WindowPriceMax();
   Gd_344 = WindowPriceMin();
   G_time_352=Time[WindowFirstVisibleBar()];
   Gi_356=WindowFirstVisibleBar()-WindowBarsPerChart();
   if(Gi_356<0) Gi_356=0;
   G_datetime_360=Time[Gi_356]+60*Period();
   for(int Li_0=1; Li_0<=Gi_392; Li_0++)
     {
      if(ObjectFind("Padding_rect"+Li_0)==-1) ObjectCreate("Padding_rect"+Li_0,OBJ_RECTANGLE,0,G_time_352,Gd_336 -(Gd_336-Gd_344)/Gi_392 *(Li_0-1),G_datetime_360,Gd_336 -(Gd_336-Gd_344)/Gi_392*Li_0);
      ObjectSet("Padding_rect"+Li_0,OBJPROP_TIME1,G_time_352);
      ObjectSet("Padding_rect"+Li_0,OBJPROP_TIME2,G_datetime_360-1);
      ObjectSet("Padding_rect"+Li_0,OBJPROP_PRICE1,Gd_336 -(Gd_336-Gd_344)/Gi_392 *(Li_0-1));
      ObjectSet("Padding_rect"+Li_0,OBJPROP_PRICE2,Gd_336 -(Gd_336-Gd_344)/Gi_392*Li_0);
      ObjectSet("Padding_rect"+Li_0,OBJPROP_BACK,TRUE);
      ObjectSet("Padding_rect"+Li_0,OBJPROP_COLOR,f0_9(Gs_364,Gs_372,Gi_392,Li_0));
     }
   WindowRedraw();
  }*/
// F7E068A881FC08598B50EAA72BECD80C
int f0_9(string As_0,string As_8,int Ai_16,int Ai_20)
  {
   int str2int_24 = StrToInteger(StringSubstr(As_0, 0, 3));
   int str2int_28 = StrToInteger(StringSubstr(As_0, 4, 3));
   int str2int_32 = StrToInteger(StringSubstr(As_0, 8, 3));
   int str2int_36 = StrToInteger(StringSubstr(As_8, 0, 3));
   int str2int_40 = StrToInteger(StringSubstr(As_8, 4, 3));
   int str2int_44 = StrToInteger(StringSubstr(As_8, 8, 3));
   if(str2int_24 > str2int_36) Gi_380 = str2int_24 + (str2int_36 - str2int_24) / Ai_16 * Ai_20;
   if(str2int_24 < str2int_36) Gi_380 = str2int_24 - (str2int_24 - str2int_36) / Ai_16 * Ai_20;
   if(str2int_28 > str2int_40) Gi_384 = str2int_28 + (str2int_40 - str2int_28) / Ai_16 * Ai_20;
   if(str2int_28 < str2int_40) Gi_384 = str2int_28 - (str2int_28 - str2int_40) / Ai_16 * Ai_20;
   if(str2int_32 > str2int_44) Gi_388 = str2int_32 + (str2int_44 - str2int_32) / Ai_16 * Ai_20;
   if(str2int_32 < str2int_44) Gi_388 = str2int_32 - (str2int_32 - str2int_44) / Ai_16 * Ai_20;
   Gi_384 *= 256;
   Gi_388<<= 16;
   return (Gi_380 + Gi_384 + Gi_388);
  }
// 2795031E32D1FE85C9BD72823A8B4142
void f0_2()
  {
   double Lda_0[10];
   double Lda_4[10];
   double Lda_8[10];
   double Lda_12[10];
   int Li_16;
   int Li_20;
   int Li_24;
   int Li_32;
   if(Period()<G_timeframe_396)
     {
      ArrayCopySeries(Lda_0,2,Symbol(),G_timeframe_396);
      ArrayCopySeries(Lda_4,1,Symbol(),G_timeframe_396);
      ArrayCopySeries(Lda_8,0,Symbol(),G_timeframe_396);
      ArrayCopySeries(Lda_12,3,Symbol(),G_timeframe_396);
      Li_32=3;
      for(int Li_28=2; Li_28>=0; Li_28--)
        {
         Li_20 = Time[0] + Period() * (90 * Li_32);
         Li_24 = Time[0] + 90 * (Period() * (Li_32 + 1));
         if(ObjectFind("BD"+(string)Li_28)==-1)
           {
            if(Lda_8[Li_28]>Lda_12[Li_28]) Li_16=170;
            else Li_16=43520;
            f0_6("D"+(string)Li_28,Li_20,Li_24,Lda_8[Li_28],Lda_12[Li_28],Lda_4[Li_28],Lda_0[Li_28],Li_16);
              } else {
            if(Lda_8[Li_28]>Lda_12[Li_28]) Li_16=170;
            else Li_16=43520;
            f0_5("D"+(string)Li_28,Li_20,Li_24,Lda_8[Li_28],Lda_12[Li_28],Lda_4[Li_28],Lda_0[Li_28],Li_16);
           }
         Li_32++;
         Li_32++;
        }
     }
  }
// 9F92396C933453E2D1202389D9EFB0E5
void f0_6(string As_0,int A_datetime_8,int A_datetime_12,double A_price_16,double A_price_24,double A_price_32,double A_price_40,color A_color_48)
  {
   if(A_price_16==A_price_24) A_color_48=Gray;
   ObjectCreate("B"+As_0,OBJ_RECTANGLE,0,A_datetime_8,A_price_16,A_datetime_12,A_price_24);
   ObjectSet("B"+As_0,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSet("B"+As_0,OBJPROP_COLOR,A_color_48);
   ObjectSet("B"+As_0,OBJPROP_BACK,TRUE);
   int datetime_52=A_datetime_8+(A_datetime_12-A_datetime_8)/2;
   ObjectCreate("S"+As_0,OBJ_TREND,0,datetime_52,A_price_32,datetime_52,A_price_40);
   ObjectSet("S"+As_0,OBJPROP_COLOR,A_color_48);
   ObjectSet("S"+As_0,OBJPROP_BACK,TRUE);
   ObjectSet("S"+As_0,OBJPROP_RAY,FALSE);
   ObjectSet("S"+As_0,OBJPROP_WIDTH,2);
  }
// 88F07BF2A3E2A04159AC984719B3F549
void f0_5(string As_0,int A_datetime_8,int A_datetime_12,double Ad_16,double Ad_24,double Ad_32,double Ad_40,color A_color_48)
  {
   if(Ad_16==Ad_24) A_color_48=Gray;
   ObjectSet("B"+As_0,OBJPROP_TIME1,A_datetime_8);
   ObjectSet("B"+As_0,OBJPROP_PRICE1,Ad_16);
   ObjectSet("B"+As_0,OBJPROP_TIME2,A_datetime_12);
   ObjectSet("B"+As_0,OBJPROP_PRICE2,Ad_24);
   ObjectSet("B"+As_0,OBJPROP_BACK,TRUE);
   ObjectSet("B"+As_0,OBJPROP_COLOR,A_color_48);
   int datetime_52=A_datetime_8+(A_datetime_12-A_datetime_8)/2;
   ObjectSet("S"+As_0,OBJPROP_TIME1,datetime_52);
   ObjectSet("S"+As_0,OBJPROP_PRICE1,Ad_32);
   ObjectSet("S"+As_0,OBJPROP_TIME2,datetime_52);
   ObjectSet("S"+As_0,OBJPROP_PRICE2,Ad_40);
   ObjectSet("S"+As_0,OBJPROP_BACK,TRUE);
   ObjectSet("S"+As_0,OBJPROP_WIDTH,2);
   ObjectSet("S"+As_0,OBJPROP_COLOR,A_color_48);
  }
// CDF7118C61A4AA4E389CF2547874D314
void f0_7()
  {
   double Ld_0=(Ask-Bid)/Gd_420;
   string text_8="Spread: "+DoubleToStr(Ld_0,1)+" pips";
   if(ObjectFind(G_name_412)<0)
     {
      ObjectCreate(G_name_412,OBJ_LABEL,0,0,0);
      ObjectSet(G_name_412,OBJPROP_CORNER,1);
      ObjectSet(G_name_412,OBJPROP_YDISTANCE,260);
      ObjectSet(G_name_412,OBJPROP_XDISTANCE,10);
      ObjectSetText(G_name_412,text_8,13,"Arial",G_color_408);
     }
   ObjectSetText(G_name_412,text_8);
   WindowRedraw();
  }
// 39C409D2E4985FE63B2929843BE560CF
void f0_3()
  {
   int Li_8=Time[0]+60*Period()-TimeCurrent();
   double Ld_0=Li_8/60.0;
   int Li_12=Li_8%60;
   Li_8=(Li_8-Li_8%60)/60;
   Comment((string)Li_8+" minutes "+(string)Li_12+" seconds left to bar end");
Comment("Robot_HAHA_EA ©"
+ "\n"
+(string)Li_8+" minutes "+(string)Li_12+" seconds left to bar end"
+ "\n"
+ "_______________________________________"
+ "\n"
+ "HAHA_EA_2022 ©"
+ "\n"
+ "_______________________________________"
+ "\n"
+ "Broker: " + AccountCompany()
+ "\n"
+ "Actual Server Time: " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS)
+ "\n"
+ "_______________________________________"
+ "\n"
+ "Name: " + AccountName()
+ "\n"
+ "Account Number: " + (string)AccountNumber()
+ "\n"
+ "Account Currency: " + (string)AccountCurrency()
+ "\n"
+ "Account Leverage: " + DoubleToStr(AccountLeverage(), 0)
+ "\n"
+ "Account Type: " + (string)AccountServer()
+ "\n"
+ "Broker Spread : " + (string)(MarketInfo(Symbol(), MODE_SPREAD))
+ "\n"
+ "_______________________________________"
+ "\n"
+ "ALL ORDERS: " + (string)OrdersTotal()
+ "\n"
+ "_______________________________________"
+ "\n"
+ "Account BALANCE: " + DoubleToStr(AccountBalance(), 2)
+ "\n"
+ "PROFIT+/-: " + (string)AccountProfit()
+ "\n"
+ "Account EQUITY: " + DoubleToStr(AccountEquity(), 2)
+ "\n"
+ "Free MARGIN: " + DoubleToStr(AccountFreeMargin(), 2)
+ "\n"
+ "Used MARGIN: " + DoubleToStr(AccountMargin(), 2)
+ "\n"
+ "_______________________________________"
+ "\n"
+ "Copyright © 2022 by ExpertAdvisor.com");
   ObjectDelete("time");
   if(ObjectFind("time")!=0)
     {
      ObjectCreate("time",OBJ_TEXT,0,Time[0],Close[0]+0.0005);
      ObjectSetText("time","                                 <--"+(string)Li_8+":"+(string)Li_12,13,"Verdana",Yellow);
      return;
     }
   ObjectMove("time",0,Time[0],Close[0]+0.0005);
  }
// 0D09CCEE6F8BC2AF782594ED51D3E1A7
void f0_0()
  {
   int Li_0=iBarShift(NULL,PERIOD_D1,Time[0])+1;
   G_ihigh_444= iHigh(NULL,PERIOD_D1,Li_0);
   G_ilow_452 = iLow(NULL,PERIOD_D1,Li_0);
   G_datetime_468=iTime(NULL,PERIOD_D1,Li_0);
   if(TimeDayOfWeek(G_datetime_468)==0)
     {
      G_ihigh_444= MathMax(G_ihigh_444,iHigh(NULL,PERIOD_D1,Li_0+1));
      G_ilow_452 = MathMin(G_ilow_452,iLow(NULL,PERIOD_D1,Li_0+1));
     }
   Gd_460=G_ihigh_444-G_ilow_452;
   f0_1();
  }
// 177469F06A7487E6FDDCBE94FDB6FD63
int f0_1()
  {
   if(ObjectFind("FiboUp")==-1) ObjectCreate("FiboUp",OBJ_FIBO,0,G_datetime_468,G_ihigh_444+Gd_460,G_datetime_468,G_ihigh_444);
   else
     {
      ObjectSet("FiboUp",OBJPROP_TIME2,G_datetime_468);
      ObjectSet("FiboUp",OBJPROP_TIME1,G_datetime_468);
      ObjectSet("FiboUp",OBJPROP_PRICE1,G_ihigh_444+Gd_460);
      ObjectSet("FiboUp",OBJPROP_PRICE2,G_ihigh_444);
     }
   ObjectSet("FiboUp",OBJPROP_LEVELCOLOR,G_color_428);
   ObjectSet("FiboUp",OBJPROP_FIBOLEVELS,13);
   ObjectSet("FiboUp",OBJPROP_FIRSTLEVEL,0.0);
   ObjectSetFiboDescription("FiboUp",0,"(100.0%) -  %$");
   ObjectSet("FiboUp",211,0.236);
   ObjectSetFiboDescription("FiboUp",1,"(123.6%) -  %$");
   ObjectSet("FiboUp",212,0.382);
   ObjectSetFiboDescription("FiboUp",2,"(138.2%) -  %$");
   ObjectSet("FiboUp",213,0.5);
   ObjectSetFiboDescription("FiboUp",3,"(150.0%) -  %$");
   ObjectSet("FiboUp",214,0.618);
   ObjectSetFiboDescription("FiboUp",4,"(161.8%) -  %$");
   ObjectSet("FiboUp",215,0.764);
   ObjectSetFiboDescription("FiboUp",5,"(176.4%) -  %$");
   ObjectSet("FiboUp",216,1.0);
   ObjectSetFiboDescription("FiboUp",6,"(200.0%) -  %$");
   ObjectSet("FiboUp",217,1.236);
   ObjectSetFiboDescription("FiboUp",7,"(223.6%) -  %$");
   ObjectSet("FiboUp",218,1.5);
   ObjectSetFiboDescription("FiboUp",8,"(250.0%) -  %$");
   ObjectSet("FiboUp",219,1.618);
   ObjectSetFiboDescription("FiboUp",9,"(261.8%) -  %$");
   ObjectSet("FiboUp",220,2.0);
   ObjectSetFiboDescription("FiboUp",10,"(300.0%) -  %$");
   ObjectSet("FiboUp",221,2.5);
   ObjectSetFiboDescription("FiboUp",11,"(350.0%) -  %$");
   ObjectSet("FiboUp",222,3.0);
   ObjectSetFiboDescription("FiboUp",12,"(400.0%) -  %$");
   ObjectSet("FiboUp",223,3.5);
   ObjectSetFiboDescription("FiboUp",13,"(450.0%) -  %$");
   ObjectSet("FiboUp",224,4.0);
   ObjectSetFiboDescription("FiboUp",14,"(500.0%) -  %$");
   ObjectSet("FiboUp",OBJPROP_RAY,TRUE);
   ObjectSet("FiboUp",OBJPROP_BACK,TRUE);
   if(ObjectFind("FiboDn")==-1) ObjectCreate("FiboDn",OBJ_FIBO,0,G_datetime_468,G_ilow_452-Gd_460,G_datetime_468,G_ilow_452);
   else
     {
      ObjectSet("FiboDn",OBJPROP_TIME2,G_datetime_468);
      ObjectSet("FiboDn",OBJPROP_TIME1,G_datetime_468);
      ObjectSet("FiboDn",OBJPROP_PRICE1,G_ilow_452-Gd_460);
      ObjectSet("FiboDn",OBJPROP_PRICE2,G_ilow_452);
     }
   ObjectSet("FiboDn",OBJPROP_LEVELCOLOR,G_color_436);
   ObjectSet("FiboDn",OBJPROP_FIBOLEVELS,19);
   ObjectSet("FiboDn",OBJPROP_FIRSTLEVEL,0.0);
   ObjectSetFiboDescription("FiboDn",0,"(0.0%) -  %$");
   ObjectSet("FiboDn",211,0.236);
   ObjectSetFiboDescription("FiboDn",1,"(-23.6%) -  %$");
   ObjectSet("FiboDn",212,0.382);
   ObjectSetFiboDescription("FiboDn",2,"(-38.2%) -  %$");
   ObjectSet("FiboDn",213,0.5);
   ObjectSetFiboDescription("FiboDn",3,"(-50.0%) -  %$");
   ObjectSet("FiboDn",214,0.618);
   ObjectSetFiboDescription("FiboDn",4,"(-61.8%) -  %$");
   ObjectSet("FiboDn",215,0.764);
   ObjectSetFiboDescription("FiboDn",5,"(-76.4%) -  %$");
   ObjectSet("FiboDn",216,1.0);
   ObjectSetFiboDescription("FiboDn",6,"(-100.0%) -  %$");
   ObjectSet("FiboDn",217,1.236);
   ObjectSetFiboDescription("FiboDn",7,"(-123.6%) -  %$");
   ObjectSet("FiboDn",218,1.382);
   ObjectSetFiboDescription("FiboDn",8,"(-138.2%) -  %$");
   ObjectSet("FiboDn",219,1.5);
   ObjectSetFiboDescription("FiboDn",9,"(-150.0%) -  %$");
   ObjectSet("FiboDn",220,1.618);
   ObjectSetFiboDescription("FiboDn",10,"(-161.8%) -  %$");
   ObjectSet("FiboDn",221,1.764);
   ObjectSetFiboDescription("FiboDn",11,"(-176.4%) -  %$");
   ObjectSet("FiboDn",222,2.0);
   ObjectSetFiboDescription("FiboDn",12,"(-200.0%) -  %$");
   ObjectSet("FiboDn",223,2.5);
   ObjectSetFiboDescription("FiboDn",13,"(-250.0%) -  %$");
   ObjectSet("FiboDn",224,3.0);
   ObjectSetFiboDescription("FiboDn",14,"(-300.0%) -  %$");
   ObjectSet("FiboDn",225,3.5);
   ObjectSetFiboDescription("FiboDn",15,"(-350.0%) -  %$");
   ObjectSet("FiboDn",226,4.0);
   ObjectSetFiboDescription("FiboDn",16,"(-400.0%) -  %$");
   ObjectSet("FiboDn",227,4.5);
   ObjectSetFiboDescription("FiboDn",17,"(-450.0%) -  %$");
   ObjectSet("FiboDn",228,5.0);
   ObjectSetFiboDescription("FiboDn",18,"(-500.0%) -  %$");
   ObjectSet("FiboDn",OBJPROP_RAY,TRUE);
   ObjectSet("FiboDn",OBJPROP_BACK,TRUE);
   if(Gi_440)
     {
      if(ObjectFind("FiboIn")==-1) ObjectCreate("FiboIn",OBJ_FIBO,0,G_datetime_468,G_ihigh_444,G_datetime_468+86400,G_ilow_452);
      else
        {
         ObjectSet("FiboIn",OBJPROP_TIME2,G_datetime_468);
         ObjectSet("FiboIn",OBJPROP_TIME1,G_datetime_468+86400);
         ObjectSet("FiboIn",OBJPROP_PRICE1,G_ihigh_444);
         ObjectSet("FiboIn",OBJPROP_PRICE2,G_ilow_452);
        }
      ObjectSet("FiboIn",OBJPROP_LEVELCOLOR,G_color_432);
      ObjectSet("FiboIn",OBJPROP_FIBOLEVELS,7);
      ObjectSet("FiboIn",OBJPROP_FIRSTLEVEL,0.0);
      ObjectSetFiboDescription("FiboIn",0,"Daily LOW (0.0) -  %$");
      ObjectSet("FiboIn",211,0.236);
      ObjectSetFiboDescription("FiboIn",1,"(23.6) -  %$");
      ObjectSet("FiboIn",212,0.382);
      ObjectSetFiboDescription("FiboIn",2,"(38.2) -  %$");
      ObjectSet("FiboIn",213,0.5);
      ObjectSetFiboDescription("FiboIn",3,"(50.0) -  %$");
      ObjectSet("FiboIn",214,0.618);
      ObjectSetFiboDescription("FiboIn",4,"(61.8) -  %$");
      ObjectSet("FiboIn",215,0.764);
      ObjectSetFiboDescription("FiboIn",5,"(76.4) -  %$");
      ObjectSet("FiboIn",216,1.0);
      ObjectSetFiboDescription("FiboIn",6,"Daily HIGH (100.0) -  %$");
      ObjectSet("FiboIn",OBJPROP_RAY,TRUE);
      ObjectSet("FiboIn",OBJPROP_BACK,TRUE);
     }
   else ObjectDelete("FiboIn");
   return (0);
  }
//+------------------------------------------------------------------+
//|                  CHART PROPERTIES                                |
//+------------------------------------------------------------------+
void Chart_Properties()
{
ChartSetInteger(ChartID(), CHART_MODE, CHART_CANDLES);
ChartSetInteger(ChartID(), CHART_SHOW_ASK_LINE, true);
ChartSetInteger(ChartID(), CHART_SHOW_BID_LINE, true);
ChartSetInteger(ChartID(), CHART_SHOW_OHLC, true);
ChartSetInteger(ChartID(), CHART_SHOW_GRID, false);
ChartSetInteger(ChartID(), CHART_SHOW_TRADE_LEVELS, true);
ChartSetInteger(ChartID(), CHART_COLOR_BACKGROUND, White);
ChartSetInteger(ChartID(), CHART_COLOR_FOREGROUND, Black);
ChartSetInteger(ChartID(), CHART_COLOR_CHART_DOWN, Black);
ChartSetInteger(ChartID(), CHART_COLOR_CHART_UP, Black);
ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BULL, DarkGreen);
ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BEAR, Crimson);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BS(double bs)
{
if (Virtual_Pending_Stop==true){
double Ld_36=NormalizeDouble(bs,Digits);
//Print("Buy: ",Ld_36);
double price_24=NormalizeDouble(Ask+Gd_240,Digits);
double price_60 = NormalizeDouble(Ask - (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
if(price_24<Ld_36)
   {
      ObjectDelete(0,HL_BS);
      
      ObjectCreate(0,HL_BS,OBJ_HLINE,0,TimeCurrent(),price_24);
      ObjectSetInteger(0, HL_BS, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, HL_BS, OBJPROP_COLOR, Lime);
      ObjectSetInteger(0, HL_BS, OBJPROP_BACK, TRUE);
      ObjectSetInteger(0, HL_BS, OBJPROP_WIDTH, 2);   
      
      
      //double price_60= NormalizeDouble(price_24 -(StopLoss+MarketInfo(Symbol(),MODE_SPREAD)) * Point,Digits);
      //bool_32 = OrderModify(OrderTicket(),price_24,price_60,OrderTakeProfit(),0,Lime);
   }
}}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Buy_Stop(double bs)
{
if (Virtual_Pending_Stop==true){
int ticket_20;
double price_24=NormalizeDouble(Ask+Gd_240,Digits);
double price_60 = NormalizeDouble(Ask - (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
double price_24_Sell=NormalizeDouble(Bid-Gd_240,Digits);
double price_60_Sell = NormalizeDouble(Bid + (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
if (Trading_Pattern==Condition_1)
         {
            if (bs>0 && (Ask==bs || Ask>bs))
               {
                  ticket_20=OrderSend(Symbol(),OP_BUY,trade,Ask,G_slippage_264,price_60,0,Comment_,MyMagicNumber,0,Lime);
                  ObjectDelete(0,HL_BS);
                  
                  if(Virtual_Pending_Stop==true && ticket_20<=0)
                       {
                        Print("BUYSTOP Send Error Code: "+(string)GetLastError()+" OP: "+DoubleToStr(price_24_Sell,Digits)+" SL: "+
                              DoubleToStr(price_60_Sell,Digits)+" Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                       }
               }
         }
else if (Trading_Pattern==Condition_2 || Trading_Pattern==Condition_4)
         {
            if (bs>0 && (Bid==bs || Bid>bs))
               {
                  ticket_20=OrderSend(Symbol(),OP_SELL,trade,Bid,G_slippage_264,price_60_Sell,0,Comment_,MyMagicNumber,0,Lime);
                  ObjectDelete(0,HL_BS);
                  
                  if(ticket_20<=0)
                       {
                        Print("SELLLIMIT Send Error Code: "+(string)GetLastError()+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+
                              DoubleToStr(price_60,Digits)+" Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                       }
               }
         }
if (Trading_Pattern==Condition_3)
         {
            if (bs>0 && (Ask==bs || Ask>bs))
               {
                  ticket_20=OrderSend(Symbol(),OP_BUY,trade,Ask,G_slippage_264,price_60,0,Comment_,MyMagicNumber,0,Lime);
                  ObjectDelete(0,HL_BS);
                  
                  if(Virtual_Pending_Stop==true && ticket_20<=0)
                       {
                        Print("BUYSTOP Send Error Code: "+(string)GetLastError()+" OP: "+DoubleToStr(price_24_Sell,Digits)+" SL: "+
                              DoubleToStr(price_60_Sell,Digits)+" Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                       }
               }
         }
}}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SS(double ss)
{
if (Virtual_Pending_Stop==true){
double Ld_36=NormalizeDouble(ss,Digits);
//Print("Buy: ",Ld_36);
double price_24=NormalizeDouble(Bid-Gd_240,Digits);
double price_60 = NormalizeDouble(Bid + (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
if(ss>0 && price_24>Ld_36)
   {
      ObjectDelete(0,HL_SS);
      
      ObjectCreate(0,HL_SS,OBJ_HLINE,0,TimeCurrent(),price_24);
      ObjectSetInteger(0, HL_SS, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, HL_SS, OBJPROP_COLOR, Crimson);
      ObjectSetInteger(0, HL_SS, OBJPROP_BACK, TRUE);
      ObjectSetInteger(0, HL_SS, OBJPROP_WIDTH, 2);   
      
      
      //double price_60= NormalizeDouble(price_24 -(StopLoss+MarketInfo(Symbol(),MODE_SPREAD)) * Point,Digits);
      //bool_32 = OrderModify(OrderTicket(),price_24,price_60,OrderTakeProfit(),0,Lime);
   }
}}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Sell_Stop(double ss)
{
if (Virtual_Pending_Stop==true){
int ticket_20;
double price_24=NormalizeDouble(Bid-Gd_240,Digits);
double price_60 = NormalizeDouble(Bid + (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
double price_24_Buy=NormalizeDouble(Ask+Gd_240,Digits);
double price_60_Buy = NormalizeDouble(Ask - (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
if (Trading_Pattern==Condition_1)
         {
            if (ss>0 && (Bid==ss || Bid<ss))
               {
                  ticket_20=OrderSend(Symbol(),OP_SELL,trade,Bid,G_slippage_264,price_60,0,Comment_,MyMagicNumber,0,Lime);
                  ObjectDelete(0,HL_SS);
                  
                  if(ticket_20<=0)
                       {
                        Print("SELLSTOP Send Error Code: "+(string)GetLastError()+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+
                              DoubleToStr(price_60,Digits)+" Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                       }
               }
        }
else if (Trading_Pattern==Condition_2 || Trading_Pattern==Condition_4)
        {
            if (ss>0 && (Ask==ss || Ask<ss))
               {
                  ticket_20=OrderSend(Symbol(),OP_BUY,trade,Ask,G_slippage_264,price_60_Buy,0,Comment_,MyMagicNumber,0,Lime);
                  ObjectDelete(0,HL_SS);
            
                  if(ticket_20<=0)
                 {
                  Print("BUYLIMIT Send Error Code: "+(string)GetLastError()+" OP: "+DoubleToStr(price_24_Buy,Digits)+" SL: "+
                        DoubleToStr(price_60_Buy,Digits)+" Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                 }
               }
        }
if (Trading_Pattern==Condition_3)
         {
            if (ss>0 && (Bid==ss || Bid<ss))
               {
                  ticket_20=OrderSend(Symbol(),OP_SELL,trade,Bid,G_slippage_264,price_60,0,Comment_,MyMagicNumber,0,Lime);
                  ObjectDelete(0,HL_SS);
                  
                  if(ticket_20<=0)
                       {
                        Print("SELLSTOP Send Error Code: "+(string)GetLastError()+" OP: "+DoubleToStr(price_24,Digits)+" SL: "+
                              DoubleToStr(price_60,Digits)+" Bid: "+DoubleToStr(Bid,Digits)+" Ask: "+DoubleToStr(Ask,Digits));
                       }
               }
        }
}}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Check_SL(int Magic)
{
   for(int i = 0; i < OrdersTotal(); i++)   ///It means go through the code until 0 is less than the open trades (that is 1).
     {
        if(OrderSelect(i,SELECT_BY_POS) == true)
          {
            if(OrderMagicNumber() == Magic)   ////If there is a position already opened by the EA...
              {
                  if (OrderType()==OP_BUY)
                      {
                        //double price_60 = NormalizeDouble(OrderOpenPrice() - (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
                        if (OrderStopLoss()==0) 
                            {
                              if (OrderModify(OrderTicket(),OrderOpenPrice(),(NormalizeDouble(OrderOpenPrice() - (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits)),OrderTakeProfit(),0,Lime))
                                  {
                                  
                                  }
                            }
                      }
                  if (OrderType()==OP_SELL)
                      {
                         //double price_60 = NormalizeDouble(OrderOpenPrice() + (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits);
                        if (OrderStopLoss()==0) 
                           {
                              if (OrderModify(OrderTicket(), OrderOpenPrice(), (NormalizeDouble(OrderOpenPrice() + (StopLoss+ MarketInfo(Symbol(),MODE_SPREAD)) * Point, Digits)), OrderTakeProfit(), 0, Red))
                                 {
                                 
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
void delay()
{
datetime _opened_last_time = TimeCurrent() ;
for(int pos=0;pos<OrdersHistoryTotal();pos++){  // Current orders -----------------------
     if(OrderSelect(pos,SELECT_BY_POS,MODE_HISTORY)==false) continue;
     if(OrderCloseTime() < _opened_last_time) continue;
     
     DeleteOrders();
     Sleep(Time_To_Wait*1000);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteOrders()
{
for(int i=(OrdersTotal()-1);i>=0;i--)
 { 
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    if(OrderType()==OP_BUYSTOP|| OrderType()==OP_SELLSTOP || OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT)
        {
            if (OrderSymbol()==Symbol() && OrderMagicNumber()==MyMagicNumber)
               {
                  bool res=OrderDelete(OrderTicket());
                  if(res == false)  Print("Error in Deleting Order. Error code: ", + GetLastError());
               }
        }
                 
 }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteOrders_()
{

for(int i=(OrdersTotal()-1);i>=0;i--)
 { 
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    if(OrderType()==OP_BUYSTOP|| OrderType()==OP_SELLSTOP || OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT)
        {
            Comment(int(TimeCurrent() - OrderOpenTime()));
            if (OrderSymbol()==Symbol() && OrderMagicNumber()==MyMagicNumber)
               {
                  bool res=OrderDelete(OrderTicket());
                  if(res == false)  Print("Error in Deleting Order. Error code: ", + GetLastError());
               }
        }
                 
 }
 
}