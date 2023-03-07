//+------------------------------------------------------------------+
//|                                                    Structure.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 12
#property indicator_plots   10
//--- plot upper
#property indicator_label1  "upper"
#property indicator_type1   DRAW_NONE
//--- plot lower
#property indicator_label2  "lower"
#property indicator_type2   DRAW_NONE
//--- plot 50%
#property indicator_label3  "50%"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrWhite
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot TR
#property indicator_label4  "TR"
#property indicator_type4   DRAW_NONE
//--- plot ATR
#property indicator_label5  "ATR"
#property indicator_type5   DRAW_NONE
//--- plot DIR
#property indicator_label6  "Direction"
#property indicator_type6   DRAW_NONE
//--- plot upper
#property indicator_label7  "hl2"
#property indicator_type7   DRAW_NONE
//--- plot LongStop
#property indicator_label8  "Long Stop"
#property indicator_type8   DRAW_COLOR_LINE
#property indicator_color8  clrGreen, clrNONE
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1
//--- plot ShortStop
#property indicator_label9  "Short Stop"
#property indicator_type9   DRAW_COLOR_LINE
#property indicator_color9  clrNONE, clrRed
#property indicator_style9  STYLE_SOLID
#property indicator_width9  1
//--- indicator buffers

input int ATR_length = 14;
input double Factor = 1.5;

double upperBuffer[], lowerBuffer[], _50_Buffer[];
double Direction[], TR[], ATR[], high_low_2[], LongStop[], ShortStop[], LongStopColorBuffer[], ShortStopColorBuffer[];
int dir = 1;
int high_index = 0, low_index = 0;
double high_price = 0.0, low_price = 0.0;
bool accepting_bullish_pullback = false, accepting_bearish_pullback = false, firstloop_ran = false;
int market_structure_trend = 0;
int bars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, upperBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, lowerBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, _50_Buffer, INDICATOR_DATA);
   SetIndexBuffer(3, TR, INDICATOR_DATA);
   SetIndexBuffer(4, ATR, INDICATOR_DATA);
   SetIndexBuffer(5, Direction, INDICATOR_DATA);
   SetIndexBuffer(6, high_low_2, INDICATOR_DATA);
   SetIndexBuffer(7, LongStop, INDICATOR_DATA);
   SetIndexBuffer(8, LongStopColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(9, ShortStop, INDICATOR_DATA);
   SetIndexBuffer(10, ShortStopColorBuffer, INDICATOR_COLOR_INDEX);

   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
   ObjectsDeleteAll(0, 0, OBJ_ARROW_SELL);
   ObjectsDeleteAll(0, 0, OBJ_ARROW_BUY);
   ObjectsDeleteAll(0, 0, OBJ_TREND);
   ObjectsDeleteAll(0, 0, OBJ_TEXT);
   ObjectsDeleteAll(0, 0, OBJPROP_TEXT);
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
   //cleanArrays();
   int start = get_start(prev_calculated);
   int current_bar = iBars(_Symbol, PERIOD_CURRENT);
//--- first loop
   if(firstloop_ran == false)
     {
      for(int i = start; i < rates_total && !IsStopped(); i++)
        {
         //--- SuperTrend calculations
         super_trend(i, close, high, low);
         //--- Upper Lower and 50% Calculations
         upper_lower_50(i, close, high, low, time);
        }
      firstloop_ran = true;
      bars = current_bar;
     }
//---
   if (firstloop_ran && current_bar != bars)
   {
         //--- SuperTrend calculations
         super_trend(rates_total - 1, close, high, low);
         
         //--- Upper Lower and 50% Calculations
         upper_lower_50(rates_total - 1, close, high, low, time);
         bars = current_bar;
   }
   
   Comment("Trend on the " + _Symbol + " " + GetTimeFrame() + " is " + (market_structure_trend == 1 ? "Bullish" : market_structure_trend == -1 ? "Bearish" : ""));
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

void cleanArrays()
{
   ObjectsDeleteAll(0, 0, OBJ_ARROW_SELL);
   ObjectsDeleteAll(0, 0, OBJ_ARROW_BUY);
   ObjectsDeleteAll(0, 0, OBJ_TREND);
   ObjectsDeleteAll(0, 0, OBJ_TEXT);
   ObjectsDeleteAll(0, 0, OBJPROP_TEXT);
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int get_start(int prev_calculated)
  {
   int start;
   if(prev_calculated == 0)
      start = 0;
   else
      start = prev_calculated - 1;
   return start;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void super_trend(int i, const double& close[], const double& high[], const double& low[])
  {
   high_low_2[i] = (high[i] + low[i]) / 2;
   TR[i] = high[i] - low[i];
   if(i > ATR_length)
     {
      double sum = 0;
      for(int j = i - ATR_length; j <= i; j++)
        {
         sum = sum + TR[j];
        }
      ATR[i] = sum / ATR_length;
      LongStop[i] = high_low_2[i] - (ATR[i] * Factor);
      ShortStop[i] = high_low_2[i] + (ATR[i] * Factor);
      if(i > ATR_length + 1)
        {
         LongStop[i] = close[i - 1] > LongStop[i - 1] ? MathMax(LongStop[i], LongStop[i - 1]) : LongStop[i];
         ShortStop[i] = close[i - 1] < ShortStop[i - 1] ? MathMin(ShortStop[i], ShortStop[i - 1]) : ShortStop[i];
         dir = dir == -1 && close[i] > ShortStop[i] ? 1 : dir == 1 && close[i] < LongStop[i] ? -1 : dir;
         Direction[i] = dir;
         LongStopColorBuffer[i] = dir == 1 && accepting_bullish_pullback == true ? 0 : 1;
         ShortStopColorBuffer[i] = dir == -1 && accepting_bearish_pullback == true ? 1 : 0;
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void upper_lower_50(int i, const double& close[], const double& high[], const double& low[], const datetime& time[])
  {
   if(i <= 1)
     {
      upperBuffer[i] = high[i];
      lowerBuffer[i] = low[i];
      _50_Buffer[i] = (upperBuffer[i] + lowerBuffer[i]) / 2;
      high_index = 0;
      high_price = 0.0;
      low_index = 0;
      low_price = 0.0;
     }
   else
     {
      bool last_accepting_bullish_pullback = accepting_bullish_pullback;
      bool last_accepting_bearish_pullback = accepting_bearish_pullback;
      upperBuffer[i] = upperBuffer[i - 1];
      lowerBuffer[i] = lowerBuffer[i - 1];
      _50_Buffer[i] = (upperBuffer[i] + lowerBuffer[i]) / 2;
      if(close[i] > upperBuffer[i])
        {
         upperBuffer[i] = high[i];
         _50_Buffer[i] = (upperBuffer[i] + lowerBuffer[i]) / 2;
        }
      if(close[i] < lowerBuffer[i])
        {
         lowerBuffer[i] = low[i];
         _50_Buffer[i] = (upperBuffer[i] + lowerBuffer[i]) / 2;
        }
      if(Direction[i] != Direction[i - 1] && Direction[i] == 1 && high_index == 0)
        {
         high_index = find_highest_index(0, i, high);
         high_price = find_highest(0, i, high);
         ObjectCreate(0, "Initial High" + IntegerToString(high_index), OBJ_ARROW_SELL, 0, time[high_index], high_price);
        }
      if(Direction[i] != Direction[i - 1] && Direction[i] == -1 && low_index == 0)
        {
         low_index = find_lowest_index(0, i, low);
         low_price = find_lowest(0, i, low);
         ObjectCreate(0, "Initial Low" + IntegerToString(low_index), OBJ_ARROW_BUY, 0, time[low_index], low_price);
        }

      if(high_index != 0 && low_index != 0)
        {
         if(upperBuffer[i] > upperBuffer[i - 1])
           {
            market_structure_trend = 1;
            if(find_lowest_index(high_index, i, low) != low_index)
              {
               low_index = find_lowest_index(high_index, i, low);
               double last_low = low_price;
               low_price = find_lowest(high_index, i, low);
               string _text = low_price < last_low ? "LL" : "HL";
               ObjectCreate(0, "low" + IntegerToString(low_index), OBJ_TEXT, 0, time[low_index], low_price);
               ObjectSetString(0, "low" + IntegerToString(low_index), OBJPROP_TEXT, _text);
               lowerBuffer[i] = low_price;
               _50_Buffer[i] = (upperBuffer[i] + lowerBuffer[i]) / 2;
              }
            if(accepting_bullish_pullback == false)
              {
               accepting_bullish_pullback = true;
               accepting_bearish_pullback = false;
              }
           }
         if(lowerBuffer[i] < lowerBuffer[i - 1])
           {
            market_structure_trend = -1;
            if(find_highest_index(low_index, i, high) != high_index)
              {
               high_index = find_highest_index(low_index, i, high);
               double last_high = high_price;
               high_price = find_highest(low_index, i, high);
               string _text = high_price > last_high ? "HH" : "LH";
               ObjectCreate(0, "high" + IntegerToString(high_index), OBJ_TEXT, 0, time[high_index], high_price);
               ObjectSetString(0, "high" + IntegerToString(high_index), OBJPROP_TEXT, _text);
               upperBuffer[i] = high_price;
               _50_Buffer[i] = (upperBuffer[i] + lowerBuffer[i]) / 2;
              }
            if(accepting_bearish_pullback == false)
              {
               accepting_bullish_pullback = false;
               accepting_bearish_pullback = true;
              }
           }
         if(accepting_bullish_pullback && Direction[i] == -1)
           {
            accepting_bullish_pullback = false;
           }
         if(accepting_bearish_pullback && Direction[i] == 1)
           {
            accepting_bearish_pullback = false;
           }
         if(accepting_bullish_pullback == false && last_accepting_bullish_pullback == true)
           {
            high_index = find_highest_index(low_index, i, high);
            double last_high = high_price;
            high_price = find_highest(low_index, i, high);
            string _text = high_price > last_high ? "HH" : "LH";
            ObjectCreate(0, "high" + IntegerToString(high_index), OBJ_TEXT, 0, time[high_index], high_price);
            ObjectSetString(0, "high" + IntegerToString(high_index), OBJPROP_TEXT, _text);
            upperBuffer[i] = high_price;
            _50_Buffer[i] = (upperBuffer[i] + lowerBuffer[i]) / 2;
           }
         if(accepting_bearish_pullback == false && last_accepting_bearish_pullback == true)
           {
            low_index = find_lowest_index(high_index, i, low);
            double last_low = low_price;
            low_price = find_lowest(high_index, i, low);
            string _text = low_price < last_low ? "LL" : "HL";
            ObjectCreate(0, "low" + IntegerToString(low_index), OBJ_TEXT, 0, time[low_index], low_price);
            ObjectSetString(0, "low" + IntegerToString(low_index), OBJPROP_TEXT, _text);
            lowerBuffer[i] = low_price;
            _50_Buffer[i] = (upperBuffer[i] + lowerBuffer[i]) / 2;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int find_highest_index(const int starting_index, const int ending_index, const double& high[])
  {
   int High_index = 0;
   double High = 0;
   for(int i = starting_index; i <= ending_index; i++)
     {
      if(i == starting_index)
        {
         High_index = i;
         High = high[i];
        }
      else
        {
         if(high[i] > High)
           {
            High_index = i;
            High = high[i];
           }
        }
     }
   return High_index;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double find_highest(const int starting_index, const int ending_index, const double& high[])
  {
   double High = 0;
   for(int i = starting_index; i <= ending_index; i++)
     {
      if(i == starting_index)
        {
         High = high[i];
        }
      else
        {
         if(high[i] > High)
           {
            High = high[i];
           }
        }
     }
   return High;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int find_lowest_index(const int starting_index, const int ending_index, const double& low[])
  {
   int Low_index = 0;
   double Low = 0;
   for(int i = starting_index; i <= ending_index; i++)
     {
      if(i == starting_index)
        {
         Low_index = i;
         Low = low[i];
        }
      else
        {
         if(low[i] < Low)
           {
            Low_index = i;
            Low = low[i];
           }
        }
     }
   return Low_index;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double find_lowest(const int starting_index, const int ending_index, const double& low[])
  {
   double Low = 0;
   for(int i = starting_index; i <= ending_index; i++)
     {
      if(i == starting_index)
        {
         Low = low[i];
        }
      else
        {
         if(low[i] < Low)
           {
            Low = low[i];
           }
        }
     }
   return Low;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetTimeFrame()
  {
   const int seconds = PeriodSeconds(); // get the number of seconds in one bar
   switch(seconds) // compare with predefined constants
     {
      case 60:
         return("M1"); // 1 minute
      case 300:
         return("M5"); // 5 minutes
      case 900:
         return("M15"); // 15 minutes
      case 1800:
         return("M30"); // 30 minutes
      case 3600:
         return("H1"); // 1 hour
      case 14400:
         return("H4"); // 4 hours
      case 86400:
         return("D1"); // daily
      case 604800:
         return("W1"); // weekly
      case 2419200:
         return("MN1"); // monthly
      case 2628000:
         return("MN1"); // monthly
      case 2592000:
         return("MN1"); // monthly
     }
   return(""); // unknown time frame
  }
//+------------------------------------------------------------------+
