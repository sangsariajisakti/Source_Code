//+------------------------------------------------------------------+
//|                                                  BB Macd nrp.mq4 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_color1  DimGray
#property indicator_color2  DimGray
#property indicator_color3  Lime
#property indicator_color4  Red
#property indicator_color5  Red

//
//
//
//
//

extern int    FastLen         = 12;
extern int    SlowLen         = 26;
extern int    Length          = 10;
extern double StDv            = 1.0;
extern bool   drawDots        = False;

//
//
//
//
//

double buffer1[];
double buffer2[];
double bbMacd[],bbMacd2[];
double buffer4[];
double buffer5[];
double buffer6[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
{
   IndicatorBuffers(6);
   SetIndexBuffer(0, buffer1);
   SetIndexBuffer(1, buffer2);
   SetIndexBuffer(2, bbMacd);
   SetIndexBuffer(3, buffer4);
   SetIndexBuffer(4, buffer5);
   SetIndexBuffer(5, buffer6);
      if (drawDots) {
            SetIndexStyle(2, DRAW_ARROW); SetIndexArrow(2, 159);
            SetIndexStyle(3, DRAW_ARROW); SetIndexArrow(3, 159);
            SetIndexStyle(4, DRAW_NONE);
         }
      else
         {
            SetIndexStyle(2, DRAW_LINE);
            SetIndexStyle(3, DRAW_LINE);
            SetIndexStyle(4, DRAW_LINE);
         }

   //
   //
   //
   //
   //
     
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);
   IndicatorShortName("BB Macd (" + FastLen + "," + SlowLen + "," + Length+")");
      SetIndexLabel(0, "Upperband");
      SetIndexLabel(1, "Lowerband");  
      SetIndexLabel(2, "BB Macd");
      SetIndexLabel(3, NULL);
      SetIndexLabel(4, NULL);
   return(0);
}

int deinit()
{
   return(0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int start()
{
   int counted_bars = IndicatorCounted();
   int limit,i;


   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
       limit = Bars - counted_bars;

      if (!drawDots)
      if (bbMacd[limit]<bbMacd[limit+1]) CleanPoint(limit,buffer4,buffer5);

   //
   //
   //
   //
   //
   
   double alpha = 2.0 / (Length + 1.0);
   for(i = limit; i >= 0 ; i--)
   {
         bbMacd[i]  = iCustom(NULL,0,"CCycle",240,1,"1",8,i);
         
                       
        // bbMacd2[i]  = iMA(NULL,0,FastLen*2,0,MODE_EMA,PRICE_CLOSE,i)- iMA(NULL,0,SlowLen,0,MODE_EMA,PRICE_CLOSE,i);
        
      buffer6[i] = buffer6[i+1] + alpha*(bbMacd[i]-buffer6[i+1]);
        
       
               double sDev = iDeviation(bbMacd, buffer6[i], Length, i);
         buffer1[i] = buffer6[i] + (StDv * sDev);
         buffer2[i] = buffer6[i] - (StDv * sDev);
         buffer4[i] = EMPTY_VALUE;
         buffer5[i] = EMPTY_VALUE;
               
         //
         //
         //
         //
         //
               
         if (bbMacd[i]<bbMacd[i+1])
            if (drawDots)     buffer4[i] = bbMacd[i];
            else  PlotPoint(i,buffer4,buffer5,bbMacd);
   }

   //
   //
   //
   //
   //
   
   return(0);
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double iDeviation(double& array[],double dMA, int period,int shift)
{
   double dSum = 0.00;
   int    i;

   for(i=0; i<period; i++) dSum += (array[shift+i]-dMA)*(array[shift+i]-dMA);
   
   return(MathSqrt(dSum/period));
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

void CleanPoint(int i,double& first[],double& second[])
{
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i]   = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

//
//
//
//
//

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (first[i+1] == EMPTY_VALUE)
      {
         if (first[i+2] == EMPTY_VALUE) {
                first[i]   = from[i];
                first[i+1] = from[i+1];
                second[i]  = EMPTY_VALUE;
            }
         else {
                second[i]   =  from[i];
                second[i+1] =  from[i+1];
                first[i]    = EMPTY_VALUE;
            }
      }
   else
      {
         first[i]   = from[i];
         second[i]  = EMPTY_VALUE;
      }
}