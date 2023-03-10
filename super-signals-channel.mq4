//+------------------------------------------------------------------+
//|                                        super-signals-channel.mq4 |
//|                Copyright © 2006, Nick Bilak, beluck[AT]gmail.com |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2006, Nick Bilak"
#property link      "http://www.forex-tsd.com/"

// hacked into a channel ind. by t_david sometime in early 2007

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Red
#property indicator_width1 1
#property indicator_color2 Lime
#property indicator_width2 1
#property indicator_color3 Red
#property indicator_width3 1
#property indicator_color4 Lime
#property indicator_width4 1

extern int SignalGap = 0;
extern int ShowBars = 500;

int dist=24;

double b1[];
double b2[];
double b3[];
double b4[];

int init()  {
   
   
   
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1);
   SetIndexBuffer(0,b1);
   SetIndexEmptyValue(0,0.0);
   
   SetIndexBuffer(1,b2);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1);
   SetIndexEmptyValue(1,0.0);
   
   
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID,1);
   SetIndexArrow(2,234);
   SetIndexBuffer(2,b3);
   SetIndexEmptyValue(2,0.0);
   
   SetIndexStyle(3,DRAW_ARROW,STYLE_SOLID,1);
   SetIndexArrow(3,233);
   SetIndexBuffer(3,b4);
   SetIndexEmptyValue(3,0.0);
   
   return(0);
}

int start() {
   
   int i,hhb,llb;
   
   if (ShowBars >= Bars) ShowBars = Bars;
   
   for (i=0;i<ShowBars;i++)   {
   
      b1[i]=0;
      b2[i]=0;
      b3[i]=0;
      b4[i]=0;
      
      hhb = iHighest(Symbol(),0,MODE_HIGH,dist,i-dist/2);
      llb = iLowest(Symbol(),0,MODE_LOW,dist,i-dist/2);

      
      if (i==hhb)
         b3[i]=High[hhb]+SignalGap*Point;
      
      if (i==llb)
         b4[i]=Low[llb]-SignalGap*Point;
         
         b1[i]=High[hhb];//+SignalGap*Point;
         b2[i]=Low[llb];//-SignalGap*Point;
   
   }
   return(0);
}


