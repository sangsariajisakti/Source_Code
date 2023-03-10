//+------------------------------------------------------------------+
//|                                            killaogbobby_1i01.mq5 |
//|                                                          valeryk |
//|                            https://www.mql5.com/ru/users/valeryk |
//+------------------------------------------------------------------+
#property copyright "valeryk"
#property link      "https://www.mql5.com/ru/users/valeryk"
#property version   "1.00"
//---
#define _dat D'10.10.2217' // Максимальная дата работы советника, если 0=откл.
#define _acc 0             // Номер счёта, если 0=откл.
#define _key 0             // Ключ, если 0=откл.
//---
#property indicator_chart_window

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1 "Lower"
#property indicator_type1  DRAW_ARROW
#property indicator_color1 clrLime
#property indicator_width1 2

#property indicator_label2 "Upper"
#property indicator_type2  DRAW_ARROW
#property indicator_color2 clrRed
#property indicator_width2 2

#property indicator_label3 "iMA"
#property indicator_type3  DRAW_LINE
#property indicator_color3 clrRed
#property indicator_style3 STYLE_SOLID
#property indicator_width3 1
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input    int                  Luft        =10;           // min. distance at points
sinput   string               Sound       ="ok.wav";     // sound file
input    ENUM_TIMEFRAMES      WorkTF      =PERIOD_H4;    // timeframes
input    int                  MAperiod    =21;           // averaging period 
input    int                  MAshift     =0;            // shift 
input    ENUM_MA_METHOD       MAmethod    =MODE_SMA;     // averaging method 
input    ENUM_APPLIED_PRICE   MAapplied   =PRICE_CLOSE;  // price type
sinput   color                UpCol       =clrGoldenrod; // higth color
sinput   color                DnCol       =clrViolet;    // low color
input    int                  History     =1000;         // history
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string   expname,compos;
int      tf;
double   Lower[],Upper[],MA[],_point;
bool     rulang,isinit;
//---
#include <Indicators\Trend.mqh>
#include <Charts\Chart.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>
//---
CiMA              ma;
CChart            ch;
CChartObjectTrend up,dn;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Comment("");
   ObjectsDeleteAll(0,expname);
   if(!LicenseValidation())
      return(INIT_FAILED);
   string pref=(MQLInfoInteger(MQL_TESTER)) ? "test" : "";
   expname=pref+" "+MQLInfoString(MQL_PROGRAM_NAME);
   compos=expname+" ["+Symbol()+"]";
   _point=SymbolInfoDouble(NULL,SYMBOL_POINT);
   tf=int(ceil((double)PeriodSeconds(WorkTF)/PeriodSeconds()));

   int count=0;
   SetIndexBuffer(count,Lower,INDICATOR_DATA);
   PlotIndexSetDouble(count,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(count,PLOT_ARROW,233);
   ArraySetAsSeries(Lower,true);
   count++;
   SetIndexBuffer(count,Upper,INDICATOR_DATA);
   PlotIndexSetDouble(count,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetInteger(count,PLOT_ARROW,234);
   ArraySetAsSeries(Upper,true);
   count++;
   SetIndexBuffer(count,MA,INDICATOR_DATA);
   PlotIndexSetDouble(count,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(MA,true);

   ma.Create(NULL,PERIOD_CURRENT,MAperiod,MAshift,MAmethod,MAapplied);
   isinit=true;

   string name=expname+" "+EnumToString(WorkTF)+" "+IntegerToString(MAperiod)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,name);
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ch.Detach();
   if(!MQLInfoInteger(MQL_OPTIMIZATION) && !MQLInfoInteger(MQL_TESTER))
     {
      Comment("");
      int   ur=UninitializeReason();
      if(ur==1 || ur==6) { ObjectsDeleteAll(0,expname); string name=NULL; StringConcatenate(name,compos," Button"); GlobalVariableDel(name); }
     }
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
   if(rates_total==prev_calculated)
      return(rates_total);
   int limit=(rates_total-prev_calculated)+2;
   static double  sh,upper,lower;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   if(prev_calculated==0 || isinit)
     {
      ch.Attach();
      sh=(ch.PriceMax(0)-ch.PriceMin(0))/20.0;
      ch.Detach();
      upper=NULL;
      lower=NULL;
      limit=(History>0) ? fmin(rates_total-MAperiod,History) : rates_total-MAperiod;
      if(History>0)
        {
         PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,rates_total-History);
         PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,rates_total-History);
         PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,rates_total-History);
        }
     }
   ma.Refresh();
   MA[0]=ma.Main(0);
   Lower[0]=EMPTY_VALUE;
   Upper[0]=EMPTY_VALUE;
   for(int i=limit; i>0 && !IsStopped(); i--)
     {
      MA[i]=ma.Main(i);
      Lower[i]=EMPTY_VALUE;
      Upper[i]=EMPTY_VALUE;
      if(upper>NULL && (close[i]>MA[i]) && (close[i]>upper+Luft*_point))
        {
         upper=NULL;
         Lower[i]=low[i]-sh;
        }
      if(lower>NULL && (close[i]<MA[i]) && (close[i]<lower-Luft*_point))
        {
         lower=NULL;
         Upper[i]=high[i]+sh;
        }
      if(fmod(i,tf)==0.0)
        {
         datetime tim[];
         double   hi[],lo[];
         if(CopyHigh(NULL,PERIOD_CURRENT,i,tf,hi)!=tf || CopyLow(NULL,PERIOD_CURRENT,i,tf,lo)!=tf || CopyTime(NULL,PERIOD_CURRENT,i,tf,tim)!=tf)
            return(0);
         ArraySetAsSeries(hi,true);
         ArraySetAsSeries(lo,true);
         ArraySetAsSeries(tim,true);
         upper=hi[ArrayMaximum(hi)];
         lower=lo[ArrayMinimum(lo)];
         up.Create(0,expname+" up "+TimeToString(tim[0]),0,tim[0],upper,tim[tf-1],upper);
         up.RayRight(false);
         up.RayLeft(false);
         up.Tooltip("upper "+DoubleToString(upper,Digits()));
         up.Color(UpCol);
         up.Detach();

         dn.Create(0,expname+" dn "+TimeToString(tim[0]),0,tim[0],lower,tim[tf-1],lower);
         dn.RayRight(false);
         dn.RayLeft(false);
         dn.Tooltip("lower "+DoubleToString(lower,Digits()));
         dn.Color(DnCol);
         dn.Detach();
        }
     }
   if(Lower[1]!=EMPTY_VALUE || Upper[1]!=EMPTY_VALUE)
      PlaySound(Sound);
   ChartRedraw();
   if(isinit)
      isinit=false;
   return(rates_total);
  }
//+------------------------------------------------------------------+
//---
//---
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LicenseValidation(int control_key=0)
  {
   bool     res=true;
   string   txt;
   rulang=false;
   if(_dat>0 && TimeLocal()>_dat)
     {
      if(rulang) StringConcatenate(txt,"Время демонстрации истекло!","\n");
      else        StringConcatenate(txt,"The demonstration has expired!","\n");
      res=false;
     }
   if(_key>0 && _key!=control_key)
     {
      if(rulang) StringConcatenate(txt,"Неверный ключ лицензии!","\n");
      else        StringConcatenate(txt,"Invalid license key!","\n");
      res=false;
     }
//if(_acc>0 && ac.Login()!=_acc)
//  {
//   if(rulang) StringConcatenate(txt,"Нелицензированный аккаунт!","\n");
//   else        StringConcatenate(txt,"Invalid account number!","\n");
//   res=false;
//  }
   if(!res) Alert(txt);
   return(res);
  }
//+------------------------------------------------------------------+
