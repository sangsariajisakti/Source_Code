//+------------------------------------------------------------------+
//|                                          NonDirectionOptions.mq5 |
//|                                                        Dan Leman |
//|                                                                  |
//+------------------------------------------------------------------+
// This is usefull
// https://optionstrat.com/optimize

#property copyright "Dan Leman"
#property link      ""
#property version   "1.00"

void OnDeinit(const int reason){  }
int OnInit() {   return(INIT_SUCCEEDED); }


enum buy_or_sell //enum for results to optimize on
{
   bsBuy,
   bsSell
};

enum put_or_call //enum for results to optimize on
{
   pcPut,
   pcCall
};

class OptionsTrade
{

public:
   double         dStrikeDistFromCurrent;
   buy_or_sell    enBuyOrSell;
   put_or_call    enPutOrCall;
   double         dPremium; //Always Positive
   double         dTradingFees;
      
   double getTradeResult(double dPriceMovement)
   {
      double dAns = 0.0;
      
      if ((enBuyOrSell == bsSell) && (enPutOrCall == pcCall))
      {
         if (dPriceMovement < dStrikeDistFromCurrent) dAns = 0.0 + dPremium - dTradingFees;
         else  dAns = dPriceMovement - dStrikeDistFromCurrent + dPremium - dTradingFees;
      }
      else if ((enBuyOrSell == bsSell) && (enPutOrCall == pcPut))
      {
         if (dPriceMovement > dStrikeDistFromCurrent) dAns = 0.0 + dPremium - dTradingFees;
         else  dAns =  dStrikeDistFromCurrent - dPriceMovement + dPremium - dTradingFees;
      }
      else if ((enBuyOrSell == bsBuy) && (enPutOrCall == pcCall))
      {
         if (dPriceMovement < dStrikeDistFromCurrent) dAns = 0.0 - dPremium - dTradingFees;
         else  dAns = dStrikeDistFromCurrent - dPriceMovement - dPremium - dTradingFees;
      }
      else if ((enBuyOrSell == bsBuy) && (enPutOrCall == pcPut))
      {
         if (dPriceMovement > dStrikeDistFromCurrent) dAns = 0.0 - dPremium - dTradingFees;
         else  dAns =  dPriceMovement - dStrikeDistFromCurrent - dPremium - dTradingFees;
      }
      return(dAns);
   }
};

//////////////////////////////////////////////////////
// START HERE
//////////////////////////////////////////////////////

//This part is written is pseudo code, because I don't know how to do it otherwise
Every X Milliseconds()
{
   double         dProfitPercent; 
   OptionsTrade   trades[2];
   
   for (each symbol in our list)
   {   
      for (each expiry > 1 day, and < 8 days)
      {
         if (Last_Price_Of_Underlying Is Exactly On a Strike Price) && (We have not logged anything with this pair in the last 15 mins)
         {
            trades[0].dStrikeDistFromCurrent = 0.0;
            trades[0].enBuyOrSell = bsBuy;
            trades[0].enPutOrCall = bsPut;
            trades[0].dPremium = Put Ask Price At The Money;
            trades[0].dTradingFees = whatever the trading fees are;
            
            trades[1].dStrikeDistFromCurrent = 0.0;
            trades[1].enBuyOrSell = bsBuy;
            trades[1].enPutOrCall = bsPut;
            trades[1].dPremium = Call Ask Price At The Money;
            trades[1].dTradingFees = whatever the trading fees are;
            
            dProfitPercent = getWeightedHistoric(strSymbol, getBarsTillExpiry(), trades);        
            Record(strSymbol, DateAndTime, BarsTillExpiry, Underlying_Price, Total_Premiums, dProfitPercent);
         }
      }
   }      
}


double getWeightedHistoric(string strSymbol, int nBarsTillExpiry, OptionsTrade &trade[])
{
   int      nTradeNum, nPreviousBar, nLastBarPreviousDay, nDayCount;
   double   dTotalResultThisPeriod, dPriceMovement, dAns;
   double   dResults[];
   double   dTotalPremiums = 0.0;
   
   nPreviousBar = 0;
   
   for (nDayCount = 0; nDayCount < 130; nDayCount++)
   {
      nLastBarPreviousDay = findLastBarPreviousDay(strSymbol, nPreviousBar);
      dPriceMovement = iClose(strSymbol, PERIOD_H1, nLastBarPreviousDay) - iOpen(strSymbol, PERIOD_H1, nLastBarPreviousDay + nBarsTillExpiry);
      
      dTotalResultThisPeriod = 0.0;
      for (nTradeNum = 0; nTradeNum < ArraySize(trade); nTradeNum++)
      {
         dTotalResultThisPeriod = dTotalResultThisPeriod + trade[nTradeNum].getTradeResult(dPriceMovement);
      }
      dResults[nDayCount] = dTotalResultThisPeriod;
      nPreviousBar = nLastBarPreviousDay;
   }

   for (nTradeNum = 0; nTradeNum < ArraySize(trade); nTradeNum++)
   {
      dTotalPremiums = dTotalPremiums + trade[nTradeNum].dPremium;
   }

   dAns = (getWeightedAverage(dResults) / dTotalPremiums);
   
   return(dAns);
}


double getWeightedAverage(double &dArray[])
{
   int      n, nWeightingMultiplier, nSumOfMultiplier;
   double   dWeightedSum;
   int      nElements = ArraySize(dArray);
   
   nSumOfMultiplier = 0;
   dWeightedSum = 0;
   
   for (n = 0; n < nElements; n++)
   {
      nWeightingMultiplier = nElements * 2 - n;
      nSumOfMultiplier = nSumOfMultiplier + nWeightingMultiplier;
      dWeightedSum = dWeightedSum + dArray[n] * nWeightingMultiplier;
   }
   return(dWeightedSum / nSumOfMultiplier);
}

int findLastBarPreviousDay(string strSymbol, int nLast)
{
   MqlDateTime    mqlCurrentBarTime;
   int            nThisBarDayOfWeek, nInitialDayOfWeek, nBar;
   
   TimeToStruct(iTime(strSymbol, PERIOD_H1, nLast), mqlCurrentBarTime);
   nInitialDayOfWeek = mqlCurrentBarTime.day_of_week;
   nThisBarDayOfWeek = nInitialDayOfWeek;
   nBar = nLast + 1;
   
   while (nInitialDayOfWeek == nThisBarDayOfWeek)
   {
      TimeToStruct(iTime(strSymbol, PERIOD_H1, nBar), mqlCurrentBarTime);
      nThisBarDayOfWeek = mqlCurrentBarTime.day_of_week;
      nBar++;
   }
   return(nBar);
}

