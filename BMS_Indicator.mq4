//+------------------------------------------------------------------+
//|                                              BMS Order Boxes.mq4 |
//|                                                Sebastijan Koščak |
//|           https://www.upwork.com/freelancers/~012f6640e05a15d214 |
//+------------------------------------------------------------------+
#property copyright "Sebastijan Koščak"
#property link      "https://www.upwork.com/freelancers/~012f6640e05a15d214"
#property version   "1.00"
#property strict
#property indicator_chart_window

#property indicator_buffers 7
#property indicator_plots 4

#define up 1
#define down -1

enum ALERT_TYPE
  {
   LONG,       // Only Long
   SHORT,      // Only Short
   LONG_SHORT  // Long & Short
  };

input int InpDepth=12;     // Depth
input int InpDeviation=5;  // Deviation
input int InpBackstep=3;   // Backstep

#define AI(buff) ArrayInitialize(buff,EMPTY_VALUE)
#define AS(buff) ArraySetAsSeries(buff,true)

string BMSNameUp = "Upwards BMS";
string BMSNameDown = "Downwards BMS";

enum cenum_bool
  {
   cb0 = TRUE, // Yes
   cb1 = FALSE // No
  };

input color BMSColorUp = clrPaleGreen;    // Color Long Order Box
input color BMSColorDown = clrLightPink;  // Color Short Order Box
input int BMSHistory = 2;                 // View BMS History
input bool AlertPopup = true;             // Popup Alert
input bool AlertNotification = false;     // Notification Alert
input bool AlertEmail = false;            // Email Alert
input ALERT_TYPE AlertType = LONG_SHORT;  // Alert Type
input cenum_bool inp_alert = cb0;         // Enable BMS alert
input bool ZoneTouch=true;                // Zone touch
input ALERT_TYPE ZoneTouchAlertType=LONG_SHORT;//Zone touch Alert Type

input int MaxTouchAlert=1;                // Max touch alert number
input string EnabledTimeFrames="M1,M5,M15,M30,H1,H4,D1,W1,MN";//Enabled TimeFrame ex:[M1,M5,..]

input bool CandleReverseFromZone=true;//Candle reverse from zone
input ALERT_TYPE CandleReverseAlertType=LONG_SHORT;//Candle Reverse Alert Type
input bool FilterByEngulfingCandle=true;//Filter By Engulfing Candle
input int MaximumBarsToSearchForEngulfing=1;//Maximum Bars To Search For Engulfing

struct StructZZ
  {
   double            value;
   datetime          time;
   bool              used;
  };

struct zzStruct
  {
   StructZZ          Upper;
   StructZZ          Lower;
   StructZZ          Last;
   int               Dir;
  } zz;

double FirstZZ=0;
datetime FirstTime=0;

struct boxStruct
  {
   datetime          time;
   double            valueUp;
   double            valueDown;
   datetime          touch_time;
   datetime          reverse_touch_time;
   int               touch_number;
   datetime          break_time;
  };

struct boxesStruct
  {
   boxStruct         Up[2000];
   boxStruct         Down[2000];
  } box;

double BUpLower[],BUpUpper[],BDownUpper[],BDownLower[];
int upwards, downwards = 0;
datetime lastAlert;

double bms_signal[],zone_signal[],reverse_touch_signal[];
bool locked = false;
string expired = "2022.9.7 23:59";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(locked)
     {
      if(TimeCurrent() >= StringToTime(expired))
        {
         Alert("This copy of indicator has been expired!");
         return(INIT_FAILED);
        }
      else
         Print("This copy of indicator will be expired on "+expired);
     }
//--- indicator buffers mapping
   ZeroMemory(zz);
   ZeroMemory(box);
   FirstZZ=0;
   FirstTime=0;

   SetIndexBuffer(0,BUpUpper);
   SetIndexStyle(0,DRAW_NONE,STYLE_SOLID,1,clrLime);
   SetIndexLabel(0,"Up Upper");
   SetIndexBuffer(1,BUpLower);
   SetIndexStyle(1,DRAW_NONE,STYLE_SOLID,1,clrLime);
   SetIndexLabel(1,"Up Lower");
   SetIndexBuffer(2,BDownUpper);
   SetIndexStyle(2,DRAW_NONE,STYLE_SOLID,1,clrRed);
   SetIndexLabel(2,"Down Upper");
   SetIndexBuffer(3,BDownLower);
   SetIndexStyle(3,DRAW_NONE,STYLE_SOLID,1,clrRed);
   SetIndexLabel(3,"Down Lower");
   SetIndexBuffer(4,bms_signal);
   SetIndexStyle(4,DRAW_NONE);
   SetIndexBuffer(5,zone_signal);
   SetIndexStyle(5,DRAW_NONE);
   SetIndexBuffer(6,reverse_touch_signal);
   SetIndexStyle(6,DRAW_NONE);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,BMSNameDown);
   ObjectsDeleteAll(0,BMSNameUp);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(!CheckEnabledTimeFrames())
      return rates_total;

   AS(close);
   AS(high);
   AS(low);
   AS(time);
   AS(open);
   int limit = 0;
   bool use_alert_long  = (AlertType==LONG_SHORT || AlertType==LONG)&&inp_alert==cb0;
   bool use_alert_short = (AlertType==LONG_SHORT || AlertType==SHORT)&&inp_alert==cb0;

   if(prev_calculated==0)
     {
      ZeroMemory(zz);
      ZeroMemory(box);
      FirstZZ=0;
      FirstTime=0;
      limit = rates_total-InpDepth-5;
     }
   for(int i=limit; i>=0; i--)
     {
      if(i>=(rates_total-5))
         continue;
      double ZigZag = iCustom(_Symbol,_Period,"ZigZag",InpDepth,InpDeviation,InpBackstep,0,i);
      //alert_down[i] = alert_up[i] = -1;
      // ZigZag Code ############################################################################################################
      // ZigZag Code ############################################################################################################
      if(ZigZag != EMPTY_VALUE && ZigZag != 0)
        {
         if(FirstZZ == 0)
           {
            FirstZZ=ZigZag;
            FirstTime = time[i];
            continue;
           }
         if(FirstZZ != -1)
           {
            if(ZigZag > FirstZZ)
              {
               zz.Lower.value = FirstZZ;
               zz.Lower.time = FirstTime;
               zz.Lower.used = false;

               zz.Upper.value = ZigZag;
               zz.Upper.time = time[i];
               zz.Upper.used = false;
               zz.Dir = up;
              }
            else
               if(ZigZag < FirstZZ)
                 {
                  zz.Upper.value = FirstZZ;
                  zz.Upper.time = FirstTime;
                  zz.Upper.used = false;

                  zz.Lower.value = ZigZag;
                  zz.Lower.time = time[i];
                  zz.Lower.used = false;
                  zz.Dir = down;
                 }
            FirstZZ = -1;
           }

         if(zz.Dir == up)
           {
            if(ZigZag > zz.Upper.value)
              {
               zz.Upper.value = ZigZag;
               zz.Upper.time = time[i];
              }
            else
               if(ZigZag < zz.Upper.value)
                 {
                  zz.Last = zz.Lower;

                  zz.Lower.value = ZigZag;
                  zz.Lower.time = time[i];
                  zz.Lower.used = false;
                  zz.Dir = down;
                 }
           }
         else
            if(zz.Dir == down)
              {
               if(ZigZag < zz.Lower.value)
                 {
                  zz.Lower.value = ZigZag;
                  zz.Lower.time = time[i];
                 }
               else
                  if(ZigZag > zz.Lower.value)
                    {
                     zz.Last = zz.Upper;

                     zz.Upper.value = ZigZag;
                     zz.Upper.time = time[i];
                     zz.Upper.used = false;
                     zz.Dir = up;
                    }
              }
        }
      // ZigZag Code ############################################################################################################
      // ZigZag Code ############################################################################################################

      // BMS and Box Code ############################################################################################################
      // BMS and Box Code ############################################################################################################
      if(zz.Dir == up)
        {
         if(!zz.Last.used)
           {
            //if(high[i]>zz.Upper.value) alert_up[i] = 1;
            if(close[i] > zz.Last.value)
              {
               TrendCreate(0,BMSNameUp+" Line "+string(upwards),0,zz.Last.time,zz.Last.value,time[i],zz.Last.value,clrRed,STYLE_SOLID,2);
               TextCreate(0,BMSNameUp+" Label "+string(upwards++),0,zz.Last.time,zz.Last.value,BMSNameUp,"Arial",10,clrRed,0,ANCHOR_LOWER);
               int bi = GetLastBox(box.Up);
               int ci = GetLastBear(i,close,open);
               box.Up[bi].valueDown = low[iLowest(_Symbol,_Period,MODE_LOW,3,ci-1)];
               box.Up[bi].valueUp = high[ci];
               box.Up[bi].time = time[ci];
               box.Up[bi].break_time=time[i];

               //RectangleCreate(0,BMSNameUp+" Box"+(string)bi,0,box.Up[bi].time,box.Up[bi].valueDown,time[i],box.Up[bi].valueUp,BMSColorUp,STYLE_SOLID,1,true,true);
               zz.Last.used = true;
               if(upwards >= BMSHistory)
                  upwards=0;
               // alert_up[i] = 1;
               bms_signal[i]=1;
               if(lastAlert != time[i] && i<5)
                 {
                  if(use_alert_long)
                    {
                     string alert_text=_Symbol+" "+GetTfString(PERIOD_CURRENT)+" "+BMSNameUp;
                     DoAlert(alert_text);
                    }
                  lastAlert = time[i];
                 }
              }
           }
         //if(low[i]<zz.Lower.used) alert_down[i] = 1;
         if(!zz.Lower.used)
           {
            if(close[i] < zz.Lower.value)
              {
               TrendCreate(0,BMSNameDown+" Line "+string(downwards),0,zz.Lower.time,zz.Lower.value,time[i],zz.Lower.value,clrRed,STYLE_SOLID,2);
               TextCreate(0,BMSNameDown+" Label "+string(downwards++),0,zz.Lower.time,zz.Lower.value,BMSNameDown,"Arial",10,clrRed,0,ANCHOR_UPPER);
               int bi = GetLastBox(box.Down);
               int ci = GetLastBull(i,close,open);
               box.Down[bi].valueUp = high[iHighest(_Symbol,_Period,MODE_HIGH,3,ci-1)];
               box.Down[bi].valueDown = low[ci];
               box.Down[bi].time = time[ci];
               box.Down[bi].break_time=time[i];

               //RectangleCreate(0,BMSNameDown+" Box"+(string)bi,0,box.Down[bi].time,box.Down[bi].valueDown,time[i],box.Down[bi].valueUp,BMSColorDown,STYLE_SOLID,1,true,true);
               zz.Lower.used = true;
               //alert_down[i] = 1;
               bms_signal[i]=-1;
               if(downwards >= BMSHistory)
                  downwards=0;
               if(lastAlert != time[i] && i<5)
                 {
                  if(use_alert_short)
                    {
                     string alert_text=_Symbol+" "+GetTfString(PERIOD_CURRENT)+" "+BMSNameDown;
                     DoAlert(alert_text);
                    }
                  lastAlert = time[i];
                 }
              }
           }
        }
      if(zz.Dir == down)
        {
         if(!zz.Upper.used)
           {
            //if(high[i]>zz.Upper.value) alert_up[i] = 1;
            if(close[i] > zz.Upper.value)
              {
               TrendCreate(0,BMSNameUp+" Line "+string(upwards),0,zz.Upper.time,zz.Upper.value,time[i],zz.Upper.value,clrRed,STYLE_SOLID,2);
               TextCreate(0,BMSNameUp+" Label "+string(upwards++),0,zz.Upper.time,zz.Upper.value,BMSNameUp,"Arial",10,clrRed,0,ANCHOR_LOWER);
               int bi = GetLastBox(box.Up);
               int ci = GetLastBear(i,close,open);
               box.Up[bi].valueDown = low[iLowest(_Symbol,_Period,MODE_LOW,3,ci-1)];
               box.Up[bi].valueUp = high[ci];
               box.Up[bi].time = time[ci];
               box.Up[bi].break_time=time[i];
               //RectangleCreate(0,BMSNameUp+" Box"+(string)bi,0,box.Up[bi].time,box.Up[bi].valueDown,time[i],box.Up[bi].valueUp,BMSColorUp,STYLE_SOLID,1,true,true);
               zz.Upper.used = true;
               if(upwards >= BMSHistory)
                  upwards=0;
               // alert_up[i] = 1;
               bms_signal[i]=1;
               if(lastAlert != time[i] && i<5)
                 {
                  if(use_alert_long)
                    {
                     string alert_text=_Symbol+" "+GetTfString(PERIOD_CURRENT)+" "+BMSNameUp;
                     DoAlert(alert_text);
                    }
                  lastAlert = time[i];
                 }
              }
           }
         if(!zz.Last.used)
           {
            //if(low[i]<zz.Last.value) alert_down[i] = 1;
            if(close[i] < zz.Last.value)
              {
               TrendCreate(0,BMSNameDown+" Line "+string(downwards),0,zz.Last.time,zz.Last.value,time[i],zz.Last.value,clrRed,STYLE_SOLID,2);
               TextCreate(0,BMSNameDown+" Label "+string(downwards++),0,zz.Last.time,zz.Last.value,BMSNameDown,"Arial",10,clrRed,0,ANCHOR_UPPER);
               int bi = GetLastBox(box.Down);
               int ci = GetLastBull(i,close,open);
               box.Down[bi].valueUp = high[iHighest(_Symbol,_Period,MODE_HIGH,3,ci-1)];
               box.Down[bi].valueDown = low[ci];
               box.Down[bi].time = time[ci];
               box.Down[bi].break_time=time[i];
               //RectangleCreate(0,BMSNameDown+" Box"+(string)bi,0,box.Down[bi].time,box.Down[bi].valueDown,time[i],box.Down[bi].valueUp,BMSColorDown,STYLE_SOLID,1,true,true);
               zz.Last.used = true;
               if(downwards >= BMSHistory)
                  downwards=0;
               // alert_down[i] = 1;
               bms_signal[i]=-1;
               if(lastAlert != time[i] && i<5)
                 {
                  if(use_alert_short)
                    {
                     string alert_text=_Symbol+" "+GetTfString(PERIOD_CURRENT)+" "+BMSNameDown;
                     DoAlert(alert_text);
                    }
                  lastAlert = time[i];
                 }
              }
           }
        }
      // BMS and Box Code ############################################################################################################
      // BMS and Box Code ############################################################################################################
      CheckIfBrokenBox(i,close);
     }
   CreateBoxes(time);
   CheckBoxesTouchAlert();
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLastBox(boxStruct &tbox[])
  {
   for(int i=0; i<1000; i++)
     {
      if(tbox[i].time == 0 && tbox[i].valueDown == 0)
         return i;
     }
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLastBear(int i,const double &close[],const double &open[])
  {
   for(int o=i; o<Bars-5; o++)
     {
      if(close[o] < open[o])
         return o;
     }
   return i-1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLastBull(int i,const double &close[],const double &open[])
  {
   for(int o=i; o<Bars-5; o++)
     {
      if(close[o] > open[o])
         return o;
     }
   return i-1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateBoxes(const datetime & time[])
  {
   static datetime timee;
   if(timee==Time[0])
      return;
   timee=Time[0];

   ObjectsDeleteAll(0, BMSNameDown + " Box");
   ObjectsDeleteAll(0, BMSNameUp + " Box");
   for(int i = 0; i < 2000; i++)
     {
      if(box.Up[i].valueDown == 0)
         break;
      if(!IsBulishEngulfing(box.Up[i]))
         continue;
      RectangleCreate(0, BMSNameUp + " Box" + (string)i, 0, box.Up[i].time, box.Up[i].valueDown, time[0], box.Up[i].valueUp, BMSColorUp, STYLE_SOLID, 1, true, true);
     }
   for(int i = 0; i < 2000; i++)
     {
      if(box.Down[i].valueUp == 0)
         break;

      if(!IsBearishEngulfing(box.Up[i]))
         continue;
      RectangleCreate(0, BMSNameDown + " Box" + (string)i, 0, box.Down[i].time, box.Down[i].valueDown, time[0], box.Down[i].valueUp, BMSColorDown, STYLE_SOLID, 1, true, true);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBulishEngulfing(boxStruct &box_struct)
  {
   if(!FilterByEngulfingCandle)
      return true;
   int start_bar_shift=iBarShift(Symbol(),PERIOD_CURRENT,box_struct.time);
   int end_bar_shift=start_bar_shift-1-MathMax(MaximumBarsToSearchForEngulfing,1);
   for(int i=start_bar_shift-1; i>end_bar_shift; i--)
     {
      if(Close[i]>Open[i]&&Close[i]>High[start_bar_shift])
        {
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBearishEngulfing(boxStruct &box_struct)
  {
   if(!FilterByEngulfingCandle)
      return true;
   int start_bar_shift=iBarShift(Symbol(),PERIOD_CURRENT,box_struct.time);
   int end_bar_shift=start_bar_shift-1-MathMax(MaximumBarsToSearchForEngulfing,1);
   for(int i=start_bar_shift-1; i>end_bar_shift; i--)
     {
      if(Close[i]<Open[i]&&Close[i]<Low[start_bar_shift])
        {
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool is_gap_between(int alert_type,datetime break_time,double price)
  {
   int bar_shift=iBarShift(Symbol(),PERIOD_CURRENT,break_time);
   for(int i=1; i<=bar_shift; i++)
     {
      if(alert_type==1)
        {
         if(Low[i]>price)
            return true;
        }
      if(alert_type==-1)
        {
         if(High[i]<price)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBoxesTouchAlert()
  {
   for(int i=0; i<2000; i++)
     {
      if(box.Up[i].valueDown == 0)
         break;


      if(CandleReverseFromZone&&CandleReverseAlertType!=SHORT)
        {
         if(Low[1]<=box.Up[i].valueUp&&Close[1]>box.Up[i].valueUp&&Close[1]>Open[1]&&Time[0]!=box.Up[i].reverse_touch_time
            &&Time[0]>box.Up[i].break_time&&is_gap_between(1,box.Up[i].break_time,box.Up[i].valueUp))
           {
            if(!IsBulishEngulfing(box.Up[i]))
               continue;
            //bms_signal[0]=1;
            reverse_touch_signal[0]=1;
            box.Up[i].reverse_touch_time=Time[0];
            string alert_text=_Symbol+" "+GetTfString(PERIOD_CURRENT)+" Candle from Demand";
            DoAlert(alert_text);
           }
        }
      if(ZoneTouch&&ZoneTouchAlertType!=SHORT)
        {
         if(Open[1]>box.Up[i].valueUp&&Close[1]>box.Up[i].valueUp&&Close[0]<=box.Up[i].valueUp&&Close[0]>=box.Up[i].valueDown&&Time[0]!=box.Up[i].touch_time&&box.Up[i].touch_number<MaxTouchAlert)
           {
            if(!IsBulishEngulfing(box.Up[i]))
               continue;
            zone_signal[0]=1;
            box.Up[i].touch_time=Time[0];
            box.Up[i].touch_number++;

            string alert_text=_Symbol+" "+GetTfString(PERIOD_CURRENT)+" Touches Support";
            DoAlert(alert_text);
           }
        }
     }
   for(int i=0; i<2000; i++)
     {
      if(box.Down[i].valueUp == 0)
         break;

      if(CandleReverseFromZone&&CandleReverseAlertType!=LONG)
        {

         if(High[1]>=box.Down[i].valueDown&&Close[1]<box.Down[i].valueDown&&Close[1]<Open[1]&&Time[0]!=box.Down[i].reverse_touch_time
            &&Time[0]>box.Down[i].break_time&&is_gap_between(-1,box.Down[i].break_time,box.Down[i].valueDown))
           {
            if(!IsBearishEngulfing(box.Down[i]))
               continue;
            //bms_signal[0]=-1;
            reverse_touch_signal[0]=-1;
            box.Down[i].reverse_touch_time=Time[0];
            string alert_text=_Symbol+" "+GetTfString(PERIOD_CURRENT)+" Candle from Supply";
            DoAlert(alert_text);
           }
        }

      if(ZoneTouch&&ZoneTouchAlertType!=LONG)
        {

         if(Open[1]<box.Down[i].valueDown&&Close[1]<box.Down[i].valueDown&&Close[0]>=box.Down[i].valueDown&&Close[0]<=box.Down[i].valueUp&&Time[0]!=box.Down[i].touch_time&&box.Down[i].touch_number<MaxTouchAlert)
           {
            if(!IsBearishEngulfing(box.Down[i]))
               continue;
            zone_signal[0]=-1;
            box.Down[i].touch_time=Time[0];
            box.Down[i].touch_number++;
            string alert_text=_Symbol+" "+GetTfString(PERIOD_CURRENT)+" Touches Resistance";
            DoAlert(alert_text);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoAlert(string text)
  {

   if(AlertPopup)
     {
      PlaySound("alert.wav");
      Alert(text);
     }
   if(AlertNotification)
      SendNotification(text);
   if(AlertEmail)
      SendMail("Alert",text);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckIfBrokenBox(int o,const double &close[])
  {
   BUpLower[o] = 0;
   BUpUpper[o] = 0;
   BDownLower[o] = 1000000000;
   BDownUpper[o] = 1000000000;
   for(int i=0; i<2000; i++)
     {
      if(box.Up[i].valueDown == 0)
         break;
      if(box.Up[i].valueUp > BUpUpper[o])
        {
         BUpLower[o] = box.Up[i].valueDown;
         BUpUpper[o] = box.Up[i].valueUp;
        }
      if(close[o] < box.Up[i].valueDown)
        {
         MoveArray(box.Up,i);
        }
     }
   for(int i=0; i<2000; i++)
     {
      if(box.Down[i].valueUp == 0)
         break;
      if(box.Down[i].valueDown < BDownLower[o])
        {
         BDownLower[o] = box.Down[i].valueDown;
         BDownUpper[o] = box.Down[i].valueUp;
        }
      if(close[o] > box.Down[i].valueUp)
        {
         MoveArray(box.Down,i);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveArray(boxStruct &array[], int o)
  {
   for(int i=o; i<ArraySize(array)-1; i++)
     {
      if(array[o].time == 0 && array[o].valueDown == 0)
         break;
      array[o] = array[o+1];
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Create a trend line by the given coordinates                     |
//+------------------------------------------------------------------+
bool TrendCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="TrendLine",  // line name
                 const int             sub_window=0,      // subwindow index
                 datetime              time1=0,           // first point time
                 double                price1=0,          // first point price
                 datetime              time2=0,           // second point time
                 double                price2=0,          // second point price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=false,    // highlight to move
                 const bool            ray_right=false,   // line's continuation to the right
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {
//--- set anchor points' coordinates if they are not set
//--- reset the error value
   ResetLastError();
//--- create a trend line by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2))
     {

     }
//--- set line color
   ObjectSetDouble(chart_ID,name,OBJPROP_PRICE1,price1);
   ObjectSetDouble(chart_ID,name,OBJPROP_PRICE2,price2);
   ObjectSetInteger(chart_ID,name,OBJPROP_TIME1,time1);
   ObjectSetInteger(chart_ID,name,OBJPROP_TIME2,time2);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Creating Text object                                             |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // chart's ID
                const string            name="Text",              // object name
                const int               sub_window=0,             // subwindow index
                datetime                time=0,                   // anchor point time
                double                  price=0,                  // anchor point price
                const string            text="Text",              // the text itself
                const string            font="Arial",             // font
                const int               font_size=10,             // font size
                const color             clr=clrRed,               // color
                const double            angle=0.0,                // text slope
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                const bool              back=false,               // in the background
                const bool              selection=false,          // highlight to move
                const bool              hidden=true,              // hidden in the object list
                const long              z_order=0)                // priority for mouse click
  {
//--- set anchor point coordinates if they are not set
//--- reset the error value
   ResetLastError();
//--- create Text object
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
     }
//--- set the text
   ObjectSetDouble(chart_ID,name,OBJPROP_PRICE1,price);
   ObjectSetInteger(chart_ID,name,OBJPROP_TIME1,time);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Create rectangle by the given coordinates                        |
//+------------------------------------------------------------------+
bool RectangleCreate(const long            chart_ID=0,        // chart's ID
                     const string          name="Rectangle",  // rectangle name
                     const int             sub_window=0,      // subwindow index
                     datetime              time1=0,           // first point time
                     double                price1=0,          // first point price
                     datetime              time2=0,           // second point time
                     double                price2=0,          // second point price
                     const color           clr=clrRed,        // rectangle color
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines
                     const int             width=1,           // width of rectangle lines
                     const bool            fill=false,        // filling rectangle with color
                     const bool            back=false,        // in the background
                     const bool            selection=false,    // highlight to move
                     const bool            hidden=true,       // hidden in the object list
                     const long            z_order=0)         // priority for mouse click
  {
//--- set anchor points' coordinates if they are not set
//--- reset the error value
   ResetLastError();
//--- create a rectangle by the given coordinates
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2))
     {
     }
//--- set rectangle color
   ObjectSetDouble(chart_ID,name,OBJPROP_PRICE1,price1);
   ObjectSetDouble(chart_ID,name,OBJPROP_PRICE2,price2);
   ObjectSetInteger(chart_ID,name,OBJPROP_TIME1,time1);
   ObjectSetInteger(chart_ID,name,OBJPROP_TIME2,time2);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_FILL,fill);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetTfString(ENUM_TIMEFRAMES _tf)
  {
   if(_tf==PERIOD_CURRENT)
      _tf = (ENUM_TIMEFRAMES)Period();
   string str = EnumToString((ENUM_TIMEFRAMES)_tf);
   string list[];
   int n = StringSplit(str,'_',list);
   string text = n>0? list[n-1] : "";
   return(text);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckEnabledTimeFrames()
  {
   if(EnabledTimeFrames=="")
      return true;
   if(Period()==PERIOD_M1&&StringFind(EnabledTimeFrames,"M1",0)>=0)
      return true;
   if(Period()==PERIOD_M5&&StringFind(EnabledTimeFrames,"M5",0)>=0)
      return true;
   if(Period()==PERIOD_M15&&StringFind(EnabledTimeFrames,"M15",0)>=0)
      return true;
   if(Period()==PERIOD_M30&&StringFind(EnabledTimeFrames,"M30",0)>=0)
      return true;
   if(Period()==PERIOD_H1&&StringFind(EnabledTimeFrames,"H1",0)>=0)
      return true;
   if(Period()==PERIOD_H4&&StringFind(EnabledTimeFrames,"H4",0)>=0)
      return true;
   if(Period()==PERIOD_D1&&StringFind(EnabledTimeFrames,"D",0)>=0)
      return true;
   if(Period()==PERIOD_W1&&StringFind(EnabledTimeFrames,"W",0)>=0)
      return true;
   if(Period()==PERIOD_MN1&&StringFind(EnabledTimeFrames,"MN",0)>=0)
      return true;
   return false;
  }
//+------------------------------------------------------------------+
