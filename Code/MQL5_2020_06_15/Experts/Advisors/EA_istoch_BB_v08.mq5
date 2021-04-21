//+------------------------------------------------------------------+
//|                                         LowSToch/BB CounterTrend |
//|                          Marco Fisichella extending Andrew Young |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Marco Fisichella extending Andrew Young"
#property description "My first trading system using Bollinger Bands and Slow Stochastic"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/

//Added by Marco - Important for placing order
#include <Trade\Trade.mqh>
CTrade Trade;
//To easy include checkresultcode, Cpositions, check StopLoss, Stop Loss & Take Profit Calculation
#include <MQL5Book\Utils.mqh>
CPositions Positions;

// Price
#include <Mql5Book\Price.mqh>
CBars Bar, BarDaily;

// Money management
#include <Mql5Book\MoneyManagement.mqh>

// Trailing stops
#include <Mql5Book\TrailingStops.mqh>
CTrailing Trail;

// Timer
#include <Mql5Book\Timer.mqh>
CTimer Timer;
CNewBar NewBar, NewDailyBar;

// Indicators 
#include <Mql5Book\Indicators.mqh>
CiBollinger Bands;
CiBollinger BandsBreakout;
CiRSI RSI;
CiStochastic Stoch;
CiSAR SAR;
CiHeikenAshi HA;

//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
sinput string CANDLEandMARKET;    // BAR & MARKET
input ulong Slippage=3; // Deviation
input ulong MagicNumber=573; // Magic Number
input bool TradeOnNewBar= true;  // Trade on new Bar settings
input int MaxBarExtension =1400; // Definition of Bar too extended
input int MinBarExtension=250;// Definition of doji bar
input int MarketMovingHoriz=400; //Definition of Market moving orizzontally
input int MinConsDoji=10; //Min consecutive doji

sinput string CandleHA;    // Heiken Ashi
input bool UseHA=true;
input int MinHAExtension=200;// Definition of HA doji bar

sinput string MM;    // Money Management. Max Risk can be 10%, set in MoneyManagement
input bool UseMoneyManagement=true;
input double BigRiskPercent=4;
input double RiskPercent = 2;
input double FixedVolume = 0.1;

sinput string SL;    // Stop Loss & Take Profit
input int IntervalSL=5; //Num of Bars to look in the past to take the min/max for SL
input int StopLoss = 400; //SL: Initial fixed SL
input int MaxSL = 600; //SL: Max fixed SL
input double TP_XSL=2; //TP: it is X times the SL. If 0 is not taken

sinput string TS;      // Trailing Stop. If used almost cancel TP
input bool UseTrailingStop=true;
//UseDynamicTS is only checked if UseTrailigStop is true
input bool UseDynamicTS=false;//UseDynamicTS: only checked if UseTS is True
// TrailingStop is used only if TS is NOT dynamic
input int TrailingStop=600;
input int MinimumProfit=700;
input int Step=10; //Step, if it is <10, it is set to 10 in TrailingStop

sinput string BE;      // Break Even
input bool UseBreakEven=false;
input int BreakEvenProfit=0;
input int LockProfit=0;

sinput string BB;      // Bollinger Bands
input bool UseBB=false;
input int BandsPeriod= 5;
input int BandsShift = 0;
input double BandsDeviation=1.8;
input ENUM_APPLIED_PRICE BandsPrice=PRICE_CLOSE;

sinput string BBBreakout;      // Bollinger Bands for Breakout, only on daily!
input bool UseDailyBBBreakout=true;
input int IntervalBBBreakout=20; //Number of Bars to look ahead in the past to take the min for bandwidth in BB
input int BBB_TPfactorSL=1; //BBB: TP = factor*SL
//min bandwidth interval: when the min bandwidth happened, upper bound
input int minBandwidthInterval_upper=1;

sinput string STO;   // Stochastic
input int KPeriod = 10;
input int DPeriod = 3;
input int Slowing = 6;
input ENUM_MA_METHOD StochMethod= MODE_SMA;
input ENUM_STO_PRICE StochPrice = STO_CLOSECLOSE;

/*sinput string RS;	// RSI
input int RSIPeriod = 8;
input ENUM_APPLIED_PRICE RSIPrice = PRICE_CLOSE;*/

sinput string PSAR;   //Parabolic Stop and Reverse 
input double SARStep=0.2;
input double SARMaximum=0.02;

sinput string TI;    // Timer
input bool UseTimer = false;
input int StartHour = 0;
input int StartMinute=0;
input int EndHour=0;
input int EndMinute=0;
input bool UseLocalTime=false;


//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

bool glBuyPlaced, glSellPlaced;
//Used for signal declaration
enum Signal
  {
   SIGNAL_NONE,
   SIGNAL_BUY,
   SIGNAL_SELL,
  };
//Used for Market movement declaration
enum MarketMov
  {
   MARKET_NONE,
   MARKET_DOJI_UP,
   MARKET_DOJI_DOWN,
   MARKET_HORIZ,
  };
//Used fot bar declaration
enum BarType
  {
   BAR_NONE,
   BAR_BULL,
   BAR_BEAR,
   BAR_TOO_EXTENDED,
   BAR_DOJI,
   BAR_ENGULFING_BEARISH,
   BAR_ENGULFING_BULLISH,
  };

Signal glSignal,glBBSignal, glBBBreakoutSignal;
int glBBCount=0, glConsDojiCount=0;
BarType glBarType, glHAType;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {

   Bands.Init(_Symbol,_Period,BandsPeriod,BandsShift,BandsDeviation,BandsPrice);
   //RSI.Init(_Symbol,_Period,RSIPeriod,RSIPrice);
   if (UseDailyBBBreakout==true)
      //Boiler Band calculated for the breakout only on Day Period
      BandsBreakout.Init(_Symbol,PERIOD_D1, 20, 0, 1.8, PRICE_CLOSE);
   Stoch.Init(_Symbol,_Period,KPeriod,DPeriod,Slowing,StochMethod,StochPrice);
   SAR.Init(_Symbol,_Period,SARStep,SARMaximum);
   if (UseHA==true)
      HA.Init(_Symbol,_Period); //Heiken Ashi

   Trade.SetDeviationInPoints(Slippage);
   Trade.SetExpertMagicNumber(MagicNumber);
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
  {
// Check for new bar
   bool newBar=true, newDailyBar=true;
   MarketMov marketMov = MARKET_HORIZ;
   int barShift=0;
   if(TradeOnNewBar==true)
     {
      newBar=NewBar.CheckNewBar(_Symbol,_Period);
      newDailyBar=NewDailyBar.CheckNewBar(_Symbol,PERIOD_D1);
      barShift=1;
     }
// Check for correcting closing position before opening
   bool statusClose = true;
// Timer
   bool timerOn= true;
   if(UseTimer == true)
     {
      timerOn=Timer.DailyTimer(StartHour,StartMinute,EndHour,EndMinute,UseLocalTime);
     }

// Update prices, last 100
   Bar.Update(_Symbol,_Period);
   BarDaily.Update(_Symbol,PERIOD_D1);

// Order placement
   if(newBar==true && timerOn==true)
     {
      // Money management
      double tradeSize=VerifyVolume(_Symbol,FixedVolume);

      //Check Bar Type
      glBarType=GetBarType(barShift);
      //Check HA Type
      if (UseHA == true)
         glHAType=GetHAType(barShift);

      //If bar too extended put prev signals to null 
      switch(glBarType)
        {
         case BAR_TOO_EXTENDED:
            glSignal=SIGNAL_NONE;
            glBBSignal=SIGNAL_NONE;
            glBBBreakoutSignal=SIGNAL_NONE;
            break;
        }
      //Slow Stochastic
      if(Stoch.Main(barShift)<=25 && Stoch.Signal(barShift)<=25 && Stoch.Main(barShift)>=Stoch.Signal(barShift)
         && Stoch.Main(barShift+1) <= Stoch.Signal(barShift+1)) glSignal = SIGNAL_BUY;
      else if(Stoch.Main(barShift) >= 75 && Stoch.Signal(barShift) >= 75 && Stoch.Main(barShift) <= Stoch.Signal(barShift)
         && Stoch.Main(barShift+1) >= Stoch.Signal(barShift+1)) glSignal = SIGNAL_SELL;

      //Bollinger
      if(UseBB==true)
         //Give a signal on glBBSignal and modifies glBBCount using BB
         InUseBB(barShift);
         
      //Bollinger for Breakout
      if(newDailyBar==true && UseDailyBBBreakout==true)
         //Give a signal on glBBBreakoutSignal and on the general glSignal
         InUseBBBreakout(barShift);
        
      int buyPosCount = Positions.Buy(MagicNumber);
      int sellPosCount = Positions.Sell(MagicNumber);
      
      //Count how many consecutive dojy candles are there
      if(glSignal==SIGNAL_BUY || glSignal==SIGNAL_SELL){
         if (glBarType==BAR_DOJI)
            glConsDojiCount++;
         else glConsDojiCount=0;
      }else glConsDojiCount=0;
      
      if (glConsDojiCount >= MinConsDoji)
         marketMov = IsMarketMovingHoriz(barShift);
      
      // Open buy order and close all SELL positions
      if(glSignal==SIGNAL_BUY)
        {
         //Close SELL position
         if (sellPosCount > 0){
            if (UseHA == false)
               CloseAllSellPosition();
            else if(glHAType==BAR_BULL || (glHAType==BAR_DOJI && (glBarType==BAR_BULL || marketMov==MARKET_DOJI_UP)))
               CloseAllSellPosition();
               else
                  statusClose = false;
         }
         //With HA control on sell and buy
         //if(statusClose==true && (UseHA == false || (glHAType==BAR_BULL || glHAType==BAR_DOJI)) && (glBarType==BAR_BULL || glBBBreakoutSignal==SIGNAL_BUY || marketMov==MARKET_DOJI_UP))
         //Without HA control on sell and buy
         if(statusClose==true && (glBarType==BAR_BULL|| glBBBreakoutSignal==SIGNAL_BUY || marketMov==MARKET_DOJI_UP))
           {
            //Do not open another BUY if there is a similar BUY open
            double lastPriceBuyOpenPosition=LastPriceBuyOpenPosition();
            if(Bar.Close(barShift) > (lastPriceBuyOpenPosition + (MarketMovingHoriz/2)*_Point) ||
               Bar.Close(barShift) < (lastPriceBuyOpenPosition - (MarketMovingHoriz/2))*_Point)
              {
               if(UseMoneyManagement==true) 
                 {
                  double buyStop=LowestLow(_Symbol,_Period,IntervalSL,barShift);
                  if(buyStop>0) AdjustBelowStopLevel(_Symbol,buyStop);
                  double currentPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
                  double stopLossDistance=StopPriceToPoints(_Symbol,buyStop,currentPrice);
                  //SL expresses as Points
                  stopLossDistance = MathMax(stopLossDistance, StopLoss);
                  if(glBBSignal==SIGNAL_BUY)
                     tradeSize = MoneyManagement(_Symbol,FixedVolume,BigRiskPercent,stopLossDistance);
                  else
                     tradeSize=MoneyManagement(_Symbol,FixedVolume,RiskPercent,stopLossDistance);
                 }
               //if ((Stoch.Main(barShift) < 75) && ((UseHA == false)||((glHAType==BAR_BULL)||(glHAType==BAR_DOJI))))
               if ((Stoch.Main(barShift) < 75) && (IsCurrentBuyPriceLowest())){
                  glBuyPlaced=Trade.Buy(tradeSize,_Symbol);
               }
               else
                  glSignal=SIGNAL_NONE;
              }
            if(glBuyPlaced==true)
              {
               //define the interval for SL
               double buyStopFix = BuyStopLoss(_Symbol,StopLoss);
               double buyStopMaxFix = BuyStopLoss(_Symbol,MaxSL);
               //Compute the support for SL
               double buyStop = LowestLow(_Symbol,_Period,IntervalSL,barShift);
               //SL expresses as Prices
               buyStop = MathMin(buyStop, buyStopFix);
               buyStop = MathMax(buyStop, buyStopMaxFix);
               if(buyStop>0) AdjustBelowStopLevel(_Symbol,buyStop);
               //TP
               double currentPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
               double stopLossDistance=StopPriceToPoints(_Symbol,buyStop,currentPrice);
               double takeProfit_XSL = TP_XSL*stopLossDistance;
               double BBBreakout_takeProfit = BBB_TPfactorSL*stopLossDistance;
               
               //Takeprofit is x times SL. If it is zero it is not considered
               double buyProfit = BuyTakeProfit(_Symbol,takeProfit_XSL,currentPrice);
               
               if (glBBBreakoutSignal==SIGNAL_BUY)
                  buyProfit = BuyTakeProfit(_Symbol,BBBreakout_takeProfit,currentPrice);
               
               if(buyProfit>0) AdjustAboveStopLevel(_Symbol,buyProfit);
               if(buyStop>0 || buyProfit>0) Trade.PositionModify(_Symbol,buyStop,buyProfit);

               glSignal=SIGNAL_NONE;
               glBBSignal= SIGNAL_NONE;
               glBBCount = 0;
               glBBBreakoutSignal=SIGNAL_NONE;
              }
           }
        }

      // Open sell order and close all BUY positions
      if(glSignal==SIGNAL_SELL)
        {      
         //Close BUY position
         if (buyPosCount > 0){
            if (UseHA == false)
               CloseAllBuyPosition();
            else if(glHAType==BAR_BEAR || (glHAType==BAR_DOJI && (glBarType==BAR_BEAR || marketMov==MARKET_DOJI_DOWN)))
                  CloseAllBuyPosition();
               else
                  statusClose = false;
         }
         //With HA control on sell and buy
         //if(statusClose==true && (UseHA == false || (glHAType==BAR_BEAR || glHAType==BAR_DOJI)) &&  (glBarType==BAR_BEAR || glBBBreakoutSignal==SIGNAL_SELL || marketMov==MARKET_DOJI_DOWN))
         //Without HA control on sell and buy
         if(statusClose==true && (glBarType==BAR_BEAR || glBBBreakoutSignal==SIGNAL_SELL || marketMov==MARKET_DOJI_DOWN))
           {
            //Do not open another SELL if there is a similar SELL open
            double lastPriceSellOpenPosition=LastPriceSellOpenPosition();
            if(Bar.Close(barShift) > (lastPriceSellOpenPosition + (MarketMovingHoriz/2)*_Point) ||
               Bar.Close(barShift) < (lastPriceSellOpenPosition - (MarketMovingHoriz/2)*_Point))
              {
               if(UseMoneyManagement==true) 
                 {
                  double sellStop=HighestHigh(_Symbol,_Period,IntervalSL,barShift);
                  
                  if(sellStop>0) sellStop=AdjustAboveStopLevel(_Symbol,sellStop);
                  double currentPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
                  double stopLossDistance=StopPriceToPoints(_Symbol,sellStop,currentPrice);
                  //SL expresses as Points
                  stopLossDistance = MathMax(stopLossDistance, StopLoss);
                  if(glBBSignal== SIGNAL_SELL)
                     tradeSize = MoneyManagement(_Symbol,FixedVolume,BigRiskPercent,stopLossDistance);
                  else
                     tradeSize=MoneyManagement(_Symbol,FixedVolume,RiskPercent,stopLossDistance);
                 }
               //if ((Stoch.Main(barShift) > 25) && ((UseHA == false)||((glHAType==BAR_BEAR)||(glHAType==BAR_DOJI))))
               if ((Stoch.Main(barShift) > 25) && (IsCurrentSellPriceHighest()))
                  glSellPlaced=Trade.Sell(tradeSize,_Symbol);
               else
                  glSignal=SIGNAL_NONE;
              }
            if(glSellPlaced==true)
              {
               //define the interval for SL
               double sellStopFix = SellStopLoss(_Symbol,StopLoss);
               double sellStopMaxFix = SellStopLoss(_Symbol,MaxSL);
               //Compute the support for SL
               double sellStop = HighestHigh(_Symbol,_Period,IntervalSL,barShift);
               //SL expresses as Price
               sellStop = MathMax(sellStop, sellStopFix);
               sellStop = MathMin(sellStop, sellStopMaxFix);
               if(sellStop>0) sellStop=AdjustAboveStopLevel(_Symbol,sellStop);
               
               //Takeprofit is x times SL. If it is zero it is not considered
               double currentPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
               double stopLossDistance=StopPriceToPoints(_Symbol,sellStop,currentPrice);
               double takeProfit_XSL = TP_XSL*stopLossDistance;
               double BBBreakout_takeProfit = BBB_TPfactorSL*stopLossDistance;
               
               double sellProfit = SellTakeProfit(_Symbol,takeProfit_XSL,currentPrice);

               if (glBBBreakoutSignal==SIGNAL_SELL)
                  sellProfit = SellTakeProfit(_Symbol,BBBreakout_takeProfit,currentPrice);
                     
               if(sellProfit>0) sellProfit=AdjustBelowStopLevel(_Symbol,sellProfit);          
               if(sellStop>0 || sellProfit>0) Trade.PositionModify(_Symbol,sellStop,sellProfit);
               
               glSignal=SIGNAL_NONE;
               glBBSignal= SIGNAL_NONE;
               glBBCount = 0;
               glBBBreakoutSignal=SIGNAL_NONE;
              }
           }
        }

     }   // Order placement end

// Get position tickets
   ulong tickets[];
   int numTickets=0;
   if(PositionsTotal()>0)
     {
      Positions.GetTickets(MagicNumber,tickets);
      numTickets=ArraySize(tickets);
     }

// Break even
   if(UseBreakEven==true && numTickets>0)
     {
      for(int i=0; i<numTickets; i++)
        {
         Trail.BreakEven(tickets[i],BreakEvenProfit,LockProfit);
        }
     }

// Trailing stop
   if(UseTrailingStop==true && numTickets>0)
     {
      //We use PSAR for the trailing stop dynamic
      if(UseDynamicTS==true)
        {
         for(int i=0; i<numTickets; i++)
           {
            if(PositionSelectByTicket(tickets[i])==true)
               if((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && SAR.Main(barShift) < Bar.Close(barShift)) ||
                  (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && SAR.Main(barShift) > Bar.Close(barShift)))
                  Trail.TrailingStop(tickets[i],SAR.Main(barShift),MinimumProfit,Step);
           }
           }else{
         for(int i=0; i<numTickets; i++)
           {
            Trail.TrailingStop(tickets[i],TrailingStop,MinimumProfit,Step);
           }
        }
     }

  }
//+------------------------------------------------------------------+
//|Marco Fisichella - Utility                        |
//+------------------------------------------------------------------+
//Get bar Type
BarType GetBarType(int barShift)
  {
   if(MathAbs(Bar.Close(barShift)-Bar.Open(barShift))>=MaxBarExtension*_Point)
      return BAR_TOO_EXTENDED;
/*if (Bar.Close(barShift+2) < Bar.Open(barShift+2) && Bar.Close(barShift+1) > Bar.Open(barShift+2) 
      && Bar.Close(barShift) > Bar.Open(barShift) && MathAbs(Bar.High(barShift+1) - Bar.Low(barShift+1)) < MaxBarExtension*_Point)
      return BAR_ENGULFING_BULLISH;
   if (Bar.Close(barShift+2) > Bar.Open(barShift+2) && Bar.Close(barShift+1) < Bar.Open(barShift+2) 
      && Bar.Close(barShift) < Bar.Open(barShift) && MathAbs(Bar.High(barShift+1) - Bar.Low(barShift+1)) < MaxBarExtension*_Point)
      return BAR_ENGULFING_BEARISH;*/
   if(Bar.Close(barShift)>(Bar.Open(barShift)+MinBarExtension*_Point))
      return BAR_BULL;
   if(Bar.Close(barShift)<(Bar.Open(barShift)-MinBarExtension*_Point))
      return BAR_BEAR;
   if(Bar.Close(barShift)<=(Bar.Open(barShift)+MinBarExtension*_Point)
      || Bar.Close(barShift)>=(Bar.Open(barShift)-MinBarExtension*_Point))
      return BAR_DOJI;
   else
      return BAR_NONE;
  }
//Get Heiken Aschi BarType  
BarType GetHAType(int barShift)
  {
   if(HA.HAClose(barShift)>(HA.HAOpen(barShift)+MinHAExtension*_Point))
      return BAR_BULL;
   if(HA.HAClose(barShift)<(HA.HAOpen(barShift)-MinHAExtension*_Point))
      return BAR_BEAR;
   if(HA.HAClose(barShift)<=(HA.HAOpen(barShift)+MinHAExtension*_Point)
      || HA.HAClose(barShift)>=(HA.HAOpen(barShift)-MinHAExtension*_Point))
      return BAR_DOJI;
   else
      return BAR_NONE;
  }
//Give a signal on glBBSignal and modifies glBBCount using BB
void InUseBB(int barShift){
   //Verify that only the low shadow is below the LowerBB and not the high higher than the UpperBB
   if((Bar.Low(barShift)<Bands.Lower(barShift)) && (Bar.High(barShift)<=Bands.Upper(barShift))){
      glBBSignal= SIGNAL_BUY;
      glBBCount = 2;
     }
   //Verify that only the high shadow is above the UpperBB and not the low lower than the LowerBB
   else if((Bar.High(barShift)>Bands.Upper(barShift)) && (Bar.Low(barShift)>=Bands.Lower(barShift))){
         glBBSignal= SIGNAL_SELL;
         glBBCount = 2;
        }
      //check how old is the signal		   
      else if(glBBCount>0){ 
         glBBCount--;
         if (glBBCount==1 && (glBBSignal == SIGNAL_BUY) && (glBarType==BAR_BULL))
            glSignal = SIGNAL_BUY;
         if (glBBCount==1 && (glBBSignal == SIGNAL_SELL) && (glBarType==BAR_BEAR))
            glSignal = SIGNAL_SELL;
         
         if(glBBCount==0){
            glBBSignal=SIGNAL_NONE;
            glSignal=SIGNAL_NONE;
            }
        }
  }
//Give a signal on glBBBreakoutSignal and on the general glSignal
void InUseBBBreakout(int barShift){
 //Check the index of the min bandwidth of the last 20 (default) bars
   int idxMinBandwidth = BandsBreakout.IdxMinBandwidth(IntervalBBBreakout);
   //if the min bandwidt happened recently
   if (idxMinBandwidth<=minBandwidthInterval_upper && idxMinBandwidth>=0){
      //Highest High in the last 10 candles
      int idxHH = IdxHighestHigh(_Symbol,PERIOD_D1, 10, barShift);
      //Lowest low in the last 10 candles
      int idxLL = IdxLowestLow(_Symbol,PERIOD_D1, 10, barShift);
      double avgRange = AvgRange(_Symbol,PERIOD_D1, 5, barShift);
      double avgVolume = AvgVolume(_Symbol,PERIOD_D1, 5, barShift);
      double currentRange = BarDaily.High(barShift) - BarDaily.Low(barShift);
      double currentHighSideRange = NormalizeDouble(BarDaily.High(barShift) - (currentRange/2), _Digits);
      long currentVolume = BarDaily.Volume(barShift);
         
      if (avgRange != -1 && avgVolume != -1){
         //if current max price is higher of the last 10 candles, if current range is higher than the avg of the last 5 candles
         //if volume are higher than the avg of the last 5 candles, if current close is in the higher side of current range 
         if (idxHH == 0 && currentRange >= avgRange && currentVolume >= avgVolume && 
         BarDaily.Close(barShift) >= currentHighSideRange){
            glBBBreakoutSignal = SIGNAL_BUY;
            glSignal = SIGNAL_BUY;
         }             
         else if (idxLL == 0 && currentRange >= avgRange && currentVolume >= avgVolume && 
         BarDaily.Close(barShift) <= currentHighSideRange){
            glBBBreakoutSignal =SIGNAL_SELL;
            glSignal = SIGNAL_SELL;
         }
         else glBBBreakoutSignal = SIGNAL_NONE;
      } 
   }
   else glBBBreakoutSignal = SIGNAL_NONE;
}
MarketMov IsMarketMovingHoriz(int barShift){
   //LowestOpenClose
   double gapLL = MathAbs(LowestLow(_Symbol,_Period,glConsDojiCount,barShift) - Bar.Close(barShift));
   //HighestOpenClose
   double gapHH = MathAbs(HighestHigh(_Symbol,_Period,glConsDojiCount,barShift) - Bar.Close(barShift));
   double maxgap = 0;
   MarketMov marketMov = MARKET_HORIZ;
   if (gapLL >= gapHH){
      maxgap = gapLL;
      marketMov = MARKET_DOJI_UP;
   }
   else {
      maxgap = gapHH;
      marketMov = MARKET_DOJI_DOWN;
   }
   if (maxgap > MarketMovingHoriz*_Point)
      return marketMov;
   return MARKET_HORIZ;
}
//+------------------------------------------------------------------+
