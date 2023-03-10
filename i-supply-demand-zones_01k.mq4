#property copyright "Copyright © 2008, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Black
#property indicator_color2 Black

extern int forcedtf = 0;
extern bool usenarrowbands = TRUE;
extern bool killretouch = TRUE;
extern color TopColor = OldLace;
extern color BotColor = PowderBlue;
extern int Price_Width = 1;
double G_ibuf_100[];
double G_ibuf_104[];
double Gd_108 = 13.0;
int Gi_116 = 8;
int Gi_120 = 5;
int G_datetime_124;
int G_time_128;
double Gd_140;
string G_symbol_148;
double Gd_156;
int G_digits_164;
int G_timeframe_168;
string Gs_172;
double Gd_180;
double Gd_188;
int G_datetime_196 = 0;

// E37F0136AA3FFAF149B351F6A4C948E9
int init() {
   SetIndexBuffer(1, G_ibuf_100);
   SetIndexEmptyValue(1, 0.0);
   SetIndexStyle(1, DRAW_NONE);
   SetIndexBuffer(0, G_ibuf_104);
   SetIndexEmptyValue(0, 0.0);
   SetIndexStyle(0, DRAW_NONE);
   if (forcedtf != 0) G_timeframe_168 = forcedtf;
   else G_timeframe_168 = Period();
   Gd_156 = Point;
   G_digits_164 = Digits;
   if (G_digits_164 == 3 || G_digits_164 == 5) Gd_156 = 10.0 * Gd_156;
   Gs_172 = "II_SupDem" + G_timeframe_168;
   return (0);
}

// 52D46093050F38C27267BCE42543EF60
int deinit() {
   f0_2(Gs_172);
   Comment("");
   return (0);
}

// EA2B2676C28C0DB26D39331A336C6B92
int start() {
   if (f0_0() == 1) {
      f0_3(G_ibuf_100, G_ibuf_104, Gd_108, Gi_116, Gi_120);
      f0_4();
      f0_1();
   }
   return (0);
}

// 2D03C2D5A7EC65EF4619E0582C272EC2
void f0_1() {
   string name_4;
   f0_2(Gs_172);
   for (int Li_0 = 0; Li_0 < iBars(G_symbol_148, G_timeframe_168); Li_0++) {
      if (G_ibuf_104[Li_0] > 0.0) {
         G_datetime_124 = iTime(G_symbol_148, G_timeframe_168, Li_0);
         G_time_128 = Time[0];
         if (usenarrowbands) Gd_140 = MathMax(iClose(G_symbol_148, G_timeframe_168, Li_0), iOpen(G_symbol_148, G_timeframe_168, Li_0));
         else Gd_140 = MathMin(iClose(G_symbol_148, G_timeframe_168, Li_0), iOpen(G_symbol_148, G_timeframe_168, Li_0));
         Gd_140 = MathMax(Gd_140, MathMax(iLow(G_symbol_148, G_timeframe_168, Li_0 - 1), iLow(G_symbol_148, G_timeframe_168, Li_0 + 1)));
         name_4 = Gs_172 + "UPAR" + G_timeframe_168 + Li_0;
         ObjectCreate(name_4, OBJ_ARROW, 0, 0, 0);
         ObjectSet(name_4, OBJPROP_ARROWCODE, SYMBOL_RIGHTPRICE);
         ObjectSet(name_4, OBJPROP_TIME1, G_time_128);
         ObjectSet(name_4, OBJPROP_PRICE1, Gd_140);
         ObjectSet(name_4, OBJPROP_COLOR, TopColor);
         ObjectSet(name_4, OBJPROP_WIDTH, Price_Width);
         name_4 = Gs_172 + "UPFILL" + G_timeframe_168 + Li_0;
         ObjectCreate(name_4, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
         ObjectSet(name_4, OBJPROP_TIME1, G_datetime_124);
         ObjectSet(name_4, OBJPROP_PRICE1, G_ibuf_104[Li_0]);
         ObjectSet(name_4, OBJPROP_TIME2, G_time_128);
         ObjectSet(name_4, OBJPROP_PRICE2, Gd_140);
         ObjectSet(name_4, OBJPROP_COLOR, TopColor);
      }
      if (G_ibuf_100[Li_0] > 0.0) {
         G_datetime_124 = iTime(G_symbol_148, G_timeframe_168, Li_0);
         G_time_128 = Time[0];
         if (usenarrowbands) Gd_140 = MathMin(iClose(G_symbol_148, G_timeframe_168, Li_0), iOpen(G_symbol_148, G_timeframe_168, Li_0));
         else Gd_140 = MathMax(iClose(G_symbol_148, G_timeframe_168, Li_0), iOpen(G_symbol_148, G_timeframe_168, Li_0));
         if (Li_0 > 0) Gd_140 = MathMin(Gd_140, MathMin(iHigh(G_symbol_148, G_timeframe_168, Li_0 + 1), iHigh(G_symbol_148, G_timeframe_168, Li_0 - 1)));
         name_4 = Gs_172 + "DNAR" + G_timeframe_168 + Li_0;
         ObjectCreate(name_4, OBJ_ARROW, 0, 0, 0);
         ObjectSet(name_4, OBJPROP_ARROWCODE, SYMBOL_RIGHTPRICE);
         ObjectSet(name_4, OBJPROP_TIME1, G_time_128);
         ObjectSet(name_4, OBJPROP_PRICE1, Gd_140);
         ObjectSet(name_4, OBJPROP_COLOR, BotColor);
         ObjectSet(name_4, OBJPROP_WIDTH, Price_Width);
         name_4 = Gs_172 + "DNFILL" + G_timeframe_168 + Li_0;
         ObjectCreate(name_4, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
         ObjectSet(name_4, OBJPROP_TIME1, G_datetime_124);
         ObjectSet(name_4, OBJPROP_PRICE1, Gd_140);
         ObjectSet(name_4, OBJPROP_TIME2, G_time_128);
         ObjectSet(name_4, OBJPROP_PRICE2, G_ibuf_100[Li_0]);
         ObjectSet(name_4, OBJPROP_COLOR, BotColor);
      }
   }
}

// 09470FB701C11F8B07320EA009403A60
int f0_0() {
   if (iTime(G_symbol_148, G_timeframe_168, 0) != G_datetime_196) {
      G_datetime_196 = iTime(G_symbol_148, G_timeframe_168, 0);
      return (1);
   }
   return (0);
}

// 3B6B0C1FF666CC49A2DCBDC950C224CE
void f0_2(string As_0) {
   string name_16;
   int str_len_8 = StringLen(As_0);
   int Li_12 = 0;
   while (Li_12 < ObjectsTotal()) {
      name_16 = ObjectName(Li_12);
      if (StringSubstr(name_16, 0, str_len_8) != As_0) Li_12++;
      else ObjectDelete(name_16);
   }
}

// 3CA4C22A90227AC4A7684A00FAEE2BA5
int f0_3(double &Ada_0[], double &Ada_4[], int Ai_8, int Ai_12, int Ai_16) {
   double Ld_36;
   double Ld_44;
   double Ld_52;
   double Ld_60;
   double Ld_68;
   double Ld_76;
   int Li_84 = iBars(G_symbol_148, G_timeframe_168) - Ai_8;
   for (int Li_20 = Li_84; Li_20 >= 0; Li_20--) {
      Ld_36 = iLow(G_symbol_148, G_timeframe_168, iLowest(G_symbol_148, G_timeframe_168, MODE_LOW, Ai_8, Li_20));
      if (Ld_36 == Ld_76) Ld_36 = 0.0;
      else {
         Ld_76 = Ld_36;
         if (iLow(G_symbol_148, G_timeframe_168, Li_20) - Ld_36 > Ai_12 * Point) Ld_36 = 0.0;
         else {
            for (int Li_24 = 1; Li_24 <= Ai_16; Li_24++) {
               Ld_44 = Ada_0[Li_20 + Li_24];
               if (Ld_44 != 0.0 && Ld_44 > Ld_36) Ada_0[Li_20 + Li_24] = 0.0;
            }
         }
      }
      Ada_0[Li_20] = Ld_36;
      Ld_36 = iHigh(G_symbol_148, G_timeframe_168, iHighest(G_symbol_148, G_timeframe_168, MODE_HIGH, Ai_8, Li_20));
      if (Ld_36 == Ld_68) Ld_36 = 0.0;
      else {
         Ld_68 = Ld_36;
         if (Ld_36 - iHigh(G_symbol_148, G_timeframe_168, Li_20) > Ai_12 * Point) Ld_36 = 0.0;
         else {
            for (Li_24 = 1; Li_24 <= Ai_16; Li_24++) {
               Ld_44 = Ada_4[Li_20 + Li_24];
               if (Ld_44 != 0.0 && Ld_44 < Ld_36) Ada_4[Li_20 + Li_24] = 0.0;
            }
         }
      }
      Ada_4[Li_20] = Ld_36;
   }
   Ld_68 = -1;
   int Li_28 = -1;
   Ld_76 = -1;
   int Li_32 = -1;
   for (Li_20 = Li_84; Li_20 >= 0; Li_20--) {
      Ld_52 = Ada_0[Li_20];
      Ld_60 = Ada_4[Li_20];
      if (Ld_52 == 0.0 && Ld_60 == 0.0) continue;
      if (Ld_60 != 0.0) {
         if (Ld_68 > 0.0) {
            if (Ld_68 < Ld_60) Ada_4[Li_28] = 0;
            else Ada_4[Li_20] = 0;
         }
         if (Ld_68 < Ld_60 || Ld_68 < 0.0) {
            Ld_68 = Ld_60;
            Li_28 = Li_20;
         }
         Ld_76 = -1;
      }
      if (Ld_52 != 0.0) {
         if (Ld_76 > 0.0) {
            if (Ld_76 > Ld_52) Ada_0[Li_32] = 0;
            else Ada_0[Li_20] = 0;
         }
         if (Ld_52 < Ld_76 || Ld_76 < 0.0) {
            Ld_76 = Ld_52;
            Li_32 = Li_20;
         }
         Ld_68 = -1;
      }
   }
   for (Li_20 = iBars(G_symbol_148, G_timeframe_168) - 1; Li_20 >= 0; Li_20--) {
      if (Li_20 >= Li_84) Ada_0[Li_20] = 0.0;
      else {
         Ld_44 = Ada_4[Li_20];
         if (Ld_44 != 0.0) Ada_4[Li_20] = Ld_44;
      }
   }
   return (0);
}

// 9F1BFF196B458CFDFF8DE3A24AAFEA26
void f0_4() {
   Gd_180 = 0;
   int Li_0 = 0;
   Gd_188 = 0;
   int Li_4 = 0;
   double Ld_8 = 0;
   double Ld_16 = 0;
   double Ld_24 = 0;
   double Ld_32 = 0;
   double Ld_40 = 0;
   double Ld_48 = 0;
   for (int Li_56 = 0; Li_56 < iBars(G_symbol_148, G_timeframe_168); Li_56++) {
      if (G_ibuf_100[Li_56] > 0.0) {
         Gd_180 = G_ibuf_100[Li_56];
         Ld_16 = G_ibuf_100[Li_56];
         Ld_24 = Ld_16;
         break;
      }
   }
   for (Li_56 = 0; Li_56 < iBars(G_symbol_148, G_timeframe_168); Li_56++) {
      if (G_ibuf_104[Li_56] > 0.0) {
         Gd_188 = G_ibuf_104[Li_56];
         Ld_8 = G_ibuf_104[Li_56];
         Ld_32 = Ld_8;
         break;
      }
   }
   for (Li_56 = 0; Li_56 < iBars(G_symbol_148, G_timeframe_168); Li_56++) {
      if (G_ibuf_104[Li_56] >= Ld_32) {
         Ld_32 = G_ibuf_104[Li_56];
         Li_4 = Li_56;
      } else G_ibuf_104[Li_56] = 0.0;
      if (G_ibuf_104[Li_56] <= Gd_188 && G_ibuf_100[Li_56] > 0.0) G_ibuf_104[Li_56] = 0.0;
      if (G_ibuf_100[Li_56] <= Ld_24 && G_ibuf_100[Li_56] > 0.0) {
         Ld_24 = G_ibuf_100[Li_56];
         Li_0 = Li_56;
      } else G_ibuf_100[Li_56] = 0.0;
      if (G_ibuf_100[Li_56] > Gd_180) G_ibuf_100[Li_56] = 0.0;
   }
   if (killretouch) {
      if (usenarrowbands) {
         Ld_40 = MathMax(iOpen(G_symbol_148, G_timeframe_168, Li_4), iClose(G_symbol_148, G_timeframe_168, Li_4));
         Ld_48 = MathMin(iOpen(G_symbol_148, G_timeframe_168, Li_0), iClose(G_symbol_148, G_timeframe_168, Li_0));
      } else {
         Ld_40 = MathMin(iOpen(G_symbol_148, G_timeframe_168, Li_4), iClose(G_symbol_148, G_timeframe_168, Li_4));
         Ld_48 = MathMax(iOpen(G_symbol_148, G_timeframe_168, Li_0), iClose(G_symbol_148, G_timeframe_168, Li_0));
      }
      for (Li_56 = MathMax(Li_0, Li_4); Li_56 >= 0; Li_56--) {
         if (G_ibuf_104[Li_56] > Ld_40 && G_ibuf_104[Li_56] != Ld_32) G_ibuf_104[Li_56] = 0.0;
         else {
            if (usenarrowbands && G_ibuf_104[Li_56] > 0.0) {
               Ld_40 = MathMax(iOpen(G_symbol_148, G_timeframe_168, Li_56), iClose(G_symbol_148, G_timeframe_168, Li_56));
               Ld_32 = G_ibuf_104[Li_56];
            } else {
               if (G_ibuf_104[Li_56] > 0.0) {
                  Ld_40 = MathMin(iOpen(G_symbol_148, G_timeframe_168, Li_56), iClose(G_symbol_148, G_timeframe_168, Li_56));
                  Ld_32 = G_ibuf_104[Li_56];
               }
            }
         }
         if (G_ibuf_100[Li_56] <= Ld_48 && G_ibuf_100[Li_56] > 0.0 && G_ibuf_100[Li_56] != Ld_24) G_ibuf_100[Li_56] = 0.0;
         else {
            if (usenarrowbands && G_ibuf_100[Li_56] > 0.0) {
               Ld_48 = MathMin(iOpen(G_symbol_148, G_timeframe_168, Li_56), iClose(G_symbol_148, G_timeframe_168, Li_56));
               Ld_24 = G_ibuf_100[Li_56];
            } else {
               if (G_ibuf_100[Li_56] > 0.0) {
                  Ld_48 = MathMax(iOpen(G_symbol_148, G_timeframe_168, Li_56), iClose(G_symbol_148, G_timeframe_168, Li_56));
                  Ld_24 = G_ibuf_100[Li_56];
               }
            }
         }
      }
   }
}
