//+------------------------------------------------------------------+
//|                                                        Price.mqh |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young and Marco Fisichella"
#property link      "http://www.expertadvisorbook.com"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


#define MAX_BARS 100			// Max bars of rate data to retrieve


//+------------------------------------------------------------------+
//| Bar Data (OHLC, Volume, Time)                                    |
//+------------------------------------------------------------------+

class CBars
{
	public:
		CBars(void);
		MqlRates bar[];
		void Update(string pSymbol, ENUM_TIMEFRAMES pPeriod);
		double Close(int pShift);
		double High(int pShift);
		double Low(int pShift);
		double Open(int pShift);
		datetime Time(int pShift);
		long TickVolume(int pShift);
		long Volume(int pShift);
};


CBars::CBars(void)
{
	ArraySetAsSeries(bar,true);
}


void CBars::Update(string pSymbol,ENUM_TIMEFRAMES pPeriod)
{
	CopyRates(pSymbol,pPeriod,0,MAX_BARS,bar);
}


double CBars::Close(int pShift=0)
{
	return(bar[pShift].close);
}


double CBars::High(int pShift=0)
{
	return(bar[pShift].high);
}


double CBars::Low(int pShift=0)
{
	return(bar[pShift].low);
}


double CBars::Open(int pShift=0)
{
	return(bar[pShift].open);
}


long CBars::TickVolume(int pShift=0)
{
	return(bar[pShift].tick_volume);
}


datetime CBars::Time(int pShift=0)
{
	return(bar[pShift].time);
}


long CBars::Volume(int pShift=0)
{
	return(bar[pShift].real_volume);
}


//+------------------------------------------------------------------+
//| Current Price Information                                                                |
//+------------------------------------------------------------------+

double Ask(string pSymbol=NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	return(SymbolInfoDouble(pSymbol,SYMBOL_ASK));
}


double Bid(string pSymbol=NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	return(SymbolInfoDouble(pSymbol,SYMBOL_BID));
}


long Spread(string pSymbol=NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	return(SymbolInfoInteger(pSymbol,SYMBOL_SPREAD));
}


long StopLevel(string pSymbol=NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	long stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL);
	return(stopLevel);
}


//+------------------------------------------------------------------+
//| Highest & Lowest                                         |
//+------------------------------------------------------------------+
double HighestOpenClose(string pSymbol, ENUM_TIMEFRAMES pPeriod, int pBars, int pStart = 0)
{
   double open[], close[];
	ArraySetAsSeries(open,true);
	ArraySetAsSeries(close,true);
	int copied = CopyOpen(pSymbol,pPeriod,pStart,pBars,open);
	if(copied == -1) return(copied);
	copied = CopyClose(pSymbol,pPeriod,pStart,pBars,close);
	if(copied == -1) return(copied);
	
	int maxOpenIdx = ArrayMaximum(open);
	double highestOpen = open[maxOpenIdx];

	int maxCloseIdx = ArrayMaximum(close);
	double highestClose = close[maxCloseIdx];
	
	if (highestOpen >= highestClose)
	   return highestOpen;
	else 
	   return highestClose;
}

double HighestHigh(string pSymbol, ENUM_TIMEFRAMES pPeriod, int pBars, int pStart = 0)
{
	double high[];
	ArraySetAsSeries(high,true);
	
	int copied = CopyHigh(pSymbol,pPeriod,pStart,pBars,high);
	if(copied == -1) return(copied);
	
	int maxIdx = ArrayMaximum(high);
	double highest = high[maxIdx];
	
	return(highest);
}

int IdxHighestHigh(string pSymbol, ENUM_TIMEFRAMES pPeriod, int pBars, int pStart = 0)
{
	double high[];
	ArraySetAsSeries(high,true);
	
	int copied = CopyHigh(pSymbol,pPeriod,pStart,pBars,high);
	if(copied == -1) return(copied);
	
	int maxIdx = ArrayMaximum(high);
	
	return(maxIdx);
}

double AvgRange(string pSymbol, ENUM_TIMEFRAMES pPeriod, int pBars, int pStart = 0)
{
	double high[], low[];
	ArraySetAsSeries(high,true);
	ArraySetAsSeries(low,true);
	int copied = CopyHigh(pSymbol,pPeriod,pStart,pBars,high);
	if(copied == -1) return(copied);
	copied = CopyLow(pSymbol,pPeriod,pStart,pBars,low);
	if(copied == -1) return(copied);
	
	double totRanges =0;
	for (int i=(pBars-1); i>=0; i--){
	   totRanges += (high[i]-low[i]);
	}
	double avgRange = totRanges/pBars;
	return avgRange;
}

double AvgVolume(string pSymbol, ENUM_TIMEFRAMES pPeriod, int pBars, int pStart = 0)
{
	long volume[];
	ArraySetAsSeries(volume,true);
	int copied = CopyRealVolume(pSymbol,pPeriod,pStart,pBars,volume);
	if(copied == -1) return(copied);
	
	long totVolumes =0;
	for (int i=(pBars-1); i>=0; i--){
	   totVolumes += volume[i];
	}
	double avgVolume = totVolumes/pBars;
	return avgVolume;
}

double LowestOpenClose(string pSymbol, ENUM_TIMEFRAMES pPeriod, int pBars, int pStart = 0)
{
   double open[], close[];
	ArraySetAsSeries(open,true);
	ArraySetAsSeries(close,true);
	int copied = CopyOpen(pSymbol,pPeriod,pStart,pBars,open);
	if(copied == -1) return(copied);
	copied = CopyClose(pSymbol,pPeriod,pStart,pBars,close);
	if(copied == -1) return(copied);
	
	int minOpenIdx = ArrayMinimum(open);
	double lowestOpen = open[minOpenIdx];

	int minCloseIdx = ArrayMinimum(close);
	double lowestClose = close[minCloseIdx];
	
	if (lowestClose <= lowestOpen)
	   return lowestClose;
	else 
	   return lowestOpen;
}

double LowestLow(string pSymbol, ENUM_TIMEFRAMES pPeriod, int pBars, int pStart = 0)
{
	double low[];
	ArraySetAsSeries(low,true);
	
	int copied = CopyLow(pSymbol,pPeriod,pStart,pBars,low);
	if(copied == -1) return(copied);
	
	int minIdx = ArrayMinimum(low);
	double lowest = low[minIdx];
	
	return(lowest);
}

int IdxLowestLow(string pSymbol, ENUM_TIMEFRAMES pPeriod, int pBars, int pStart = 0)
{
	double low[];
	ArraySetAsSeries(low,true);
	
	int copied = CopyLow(pSymbol,pPeriod,pStart,pBars,low);
	if(copied == -1) return(copied);
	
	int minIdx = ArrayMinimum(low);
	
	return(minIdx);
}


//+------------------------------------------------------------------+
//| Marco Fisichella - Check Position Opened                                 |
//+------------------------------------------------------------------+


//Check that the current BUY price is the lowest of the existing open Buy positions
bool IsCurrentBuyPriceLowest(){
   int buyPosCount = Positions.Buy(MagicNumber);
   ulong buyTickets[];
   double posOpenPrice;
   if(buyPosCount > 0){
      Positions.GetBuyTickets(MagicNumber,buyTickets);
      int numBuyTickets=ArraySize(buyTickets);
      double currentPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      for (int i=0; i<numBuyTickets; i++){
         posOpenPrice = PositionOpenPrice(buyTickets[i]);
         if (currentPrice > posOpenPrice)
            return false;
      }
   }
   return true;
}
//Check that the current SELL price is the highest of the existing open Buy positions
bool IsCurrentSellPriceHighest(){
   int sellPosCount = Positions.Sell(MagicNumber);
   ulong  sellTickets[];
   double posOpenPrice;
   if(sellPosCount > 0){
      Positions.GetSellTickets(MagicNumber,sellTickets);
      int numSellTickets=ArraySize(sellTickets);
      double currentPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      for (int i=0; i<numSellTickets; i++){
         posOpenPrice = PositionOpenPrice(sellTickets[i]);
         if (currentPrice < posOpenPrice)
            return false;
      }
   }
   return true;
}
//Calculate the price of last open BUY position
double LastPriceBuyOpenPosition(){
   //look at all positions
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      //identify currency pair
      string currencyPair=PositionGetSymbol(i);
      //get position type
      int positionDirection=PositionGetInteger(POSITION_TYPE);
      //if symbol on chart equals position symbol
      if(_Symbol==currencyPair && positionDirection==POSITION_TYPE_BUY)
         return  PositionGetDouble(POSITION_PRICE_OPEN);
     }
   return 0.0;
  }
//Calculate the price of last open SELL position
double LastPriceSellOpenPosition(){
   //look at all positions
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      //identify currency pair
      string currencyPair=PositionGetSymbol(i);
      //get position type
      int positionDirection=PositionGetInteger(POSITION_TYPE);
      //if symbol on chart equals position symbol
      if(_Symbol==currencyPair && positionDirection==POSITION_TYPE_SELL)
         return  PositionGetDouble(POSITION_PRICE_OPEN);
     }
   return 0.0;
  }
//Close all BUY positions
void CloseAllBuyPosition(){
   //count until there are no positions left
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      //get ticket number
      int ticket=PositionGetTicket(i);
      //get symbol
      string currencyPair=PositionGetSymbol(i);
      //get position direction
      int posDirection=PositionGetInteger(POSITION_TYPE);

      //if it is a BUY position
      if(posDirection==POSITION_TYPE_BUY && _Symbol==currencyPair)
        {
         Trade.PositionClose(ticket);
         Print("Close a BUY position");
        }
     }
  }
//Close all SELL positions
void CloseAllSellPosition(){
   //count until there are no positions left
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      //get ticket number
      int ticket=PositionGetTicket(i);
      //get symbol
      string currencyPair=PositionGetSymbol(i);

      //get position direction
      int posDirection=PositionGetInteger(POSITION_TYPE);

      //if it is a BUY position
      if(posDirection==POSITION_TYPE_SELL && _Symbol==currencyPair)
        {
         Trade.PositionClose(ticket);
         Print("Close a SELL position");
        }
     }
  }