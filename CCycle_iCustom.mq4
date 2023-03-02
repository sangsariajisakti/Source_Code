//+------------------------------------------------------------------+
//|                                                  BB Macd nrp.mq4 |
//|                                                      Mql4 Version |
//|                                              Copyright 2022, XYZ |
//|                                        https://www.example.com/  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, XYZ"
#property link      "https://www.example.com/"
#property version   "1.00"
#property description "BB Macd nrp modified version by XYZ"

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_color1  clrGray
#property indicator_color2  clrGray
#property indicator_color3  clrLime
#property indicator_color4  clrRed
#property indicator_color5  clrRed

// input parameters
extern int FastLen    = 12;
extern int SlowLen    = 26;
extern int Length     = 10;
extern double StDv    = 1.0;
extern bool DrawDots  = false;

// buffers
double UpperBandBuffer[];
double LowerBandBuffer[];
double BBMacdBuffer[];
double ArrowUpBuffer[];
double ArrowDownBuffer[];

int OnInit()
{

   IndicatorBuffers(5);
   SetIndexBuffer(0, UpperBandBuffer);
   SetIndexBuffer(1, LowerBandBuffer);
   SetIndexBuffer(2, BBMacdBuffer);
   SetIndexBuffer(3, ArrowUpBuffer);
   SetIndexBuffer(4, ArrowDownBuffer);

   // set indicator labels
   SetIndexLabel(0, "Upper Band");
   SetIndexLabel(1, "Lower Band");
   SetIndexLabel(2, "BB Macd");
   SetIndexLabel(3, "");
   SetIndexLabel(4, "");

   // set indicator styles
   SetIndexStyle(0, DRAW_LINE);
   SetIndexStyle(1, DRAW_LINE);
   SetIndexStyle(2, DrawDots ? DRAW_ARROW : DRAW_LINE);
   SetIndexArrow(2, 159);
   SetIndexStyle(3, DrawDots ? DRAW_ARROW : DRAW_NONE);
   SetIndexArrow(3, 159);
   SetIndexStyle(4, DRAW_NONE);

   // set indicator digits
   IndicatorDigits(MarketInfo(Symbol(), MODE_DIGITS) + 1);

   // set indicator short name
   IndicatorShortName("BB Macd (" + FastLen + "," + SlowLen + "," + Length + ")");

   return(INIT_SUCCEEDED);
}

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
   int limit = 0;
   if(prev_calculated > 0)
      limit = prev_calculated - 1;

   double alpha = 2.0 / (Length + 1.0);

   for(int i = limit; i < rates_total; i++)
   {
      // calculate CCycle
      double ccycle = iCustom(NULL, 0, "CCycle", 240, 1, "1", 8, i);

      // calculate BBMacd
      double fast_ma = iMA(NULL, 0, FastLen * 2, 0, MODE_EMA, PRICE_CLOSE, i);
      double slow_ma = iMA(NULL, 0, SlowLen, 0, MODE_EMA, PRICE_CLOSE, i);
      double bb_macd = fast_ma - slow_ma;

      // calculate BBMacdaverage
// calculate BBMacd average
      double bb_macd_avg = 0;
      for (int j1 = 0; j1 < Length; j1++) {
         bb_macd_avg += bb_macd;
      }
      bb_macd_avg = bb_macd_avg / Length;

      // calculate BBMacd standard deviation
      double bb_macd_stdev = 0;
      for (int j2 = 0; j2 < Length; j2++) {
         double diff = bb_macd - bb_macd_avg;
         bb_macd_stdev += diff * diff;
      }
      bb_macd_stdev = MathSqrt(bb_macd_stdev / Length);


      // calculate BBMacd upper and lower bands
      UpperBandBuffer[i] = bb_macd_avg + StDv * bb_macd_stdev;
      LowerBandBuffer[i] = bb_macd_avg - StDv * bb_macd_stdev;

      // set BBMacd value
      BBMacdBuffer[i] = bb_macd;

      // plot arrow
      if (DrawDots) {
         ArrowUpBuffer[i] = EMPTY_VALUE;
         ArrowDownBuffer[i] = EMPTY_VALUE;

         if (bb_macd > UpperBandBuffer[i]) {
            ArrowUpBuffer[i] = bb_macd;
         } else if (bb_macd < LowerBandBuffer[i]) {
            ArrowDownBuffer[i] = bb_macd;
         }
      }
   }

   return(rates_total);
}
