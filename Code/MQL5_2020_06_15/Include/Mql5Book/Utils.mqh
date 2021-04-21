//+------------------------------------------------------------------+
//|                                                        Utils.mqh |
//|                                 Copyright 2018, Marco Fisichella |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Marco Fisichella"
#property link      "https://www.mql5.com"

#include <errordescription.mqh>


//+------------------------------------------------------------------+
//| Position Tickets & Counts                                        |
//+------------------------------------------------------------------+
enum ENUM_CHECK_RETCODE
{
	CHECK_RETCODE_OK,
	CHECK_RETCODE_ERROR,
	CHECK_RETCODE_RETRY
};

// Return code check
int CheckReturnCode(uint pRetCode)
{
	int status;
	switch(pRetCode)
	{
		case TRADE_RETCODE_REQUOTE:
		case TRADE_RETCODE_CONNECTION:
		case TRADE_RETCODE_PRICE_CHANGED:
		case TRADE_RETCODE_TIMEOUT:
		case TRADE_RETCODE_PRICE_OFF:
		case TRADE_RETCODE_REJECT:
		case TRADE_RETCODE_ERROR:
		
			status = CHECK_RETCODE_RETRY;
			break;
			
		case TRADE_RETCODE_DONE:
		case TRADE_RETCODE_DONE_PARTIAL:
		case TRADE_RETCODE_PLACED:
		case TRADE_RETCODE_NO_CHANGES:
		
			status = CHECK_RETCODE_OK;
			break;
			
		default: status = CHECK_RETCODE_ERROR;
	}
	
	return(status);
}
//+------------------------------------------------------------------+
//| Stop Loss & Take Profit Calculation Functions                                                             |
//+------------------------------------------------------------------+

double BuyStopLoss(string pSymbol,int pStopPoints, double pOpenPrice = 0)
{
	if(pStopPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLoss = openPrice - (pStopPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	stopLoss = NormalizeDouble(stopLoss,(int)digits);
	
	return(stopLoss);
}


double SellStopLoss(string pSymbol,int pStopPoints, double pOpenPrice = 0)
{
	if(pStopPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLoss = openPrice + (pStopPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	stopLoss = NormalizeDouble(stopLoss,(int)digits);
	
	return(stopLoss);
}


double BuyTakeProfit(string pSymbol,int pProfitPoints, double pOpenPrice = 0)
{
	if(pProfitPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double takeProfit = openPrice + (pProfitPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	takeProfit = NormalizeDouble(takeProfit,(int)digits);
	return(takeProfit);
}


double SellTakeProfit(string pSymbol,int pProfitPoints, double pOpenPrice = 0)
{
	if(pProfitPoints <= 0) return(0);
	
	double openPrice;
	if(pOpenPrice > 0) openPrice = pOpenPrice;
	else openPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double takeProfit = openPrice - (pProfitPoints * point);
	
	long digits = SymbolInfoInteger(pSymbol,SYMBOL_DIGITS);
	takeProfit = NormalizeDouble(takeProfit,(int)digits);
	return(takeProfit);
}

//+------------------------------------------------------------------+
//| Stop Level Verification                                          |
//+------------------------------------------------------------------+


// Check stop level (no adjust)
bool CheckAboveStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice + stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice >= stopPrice + addPoints) return(true);
	else return(false);
}


bool CheckBelowStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice - stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice <= stopPrice - addPoints) return(true);
	else return(false);
}


// Adjust stop level
double AdjustAboveStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice + stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice > stopPrice + addPoints) return(pPrice);
	else
	{
		double newPrice = stopPrice + addPoints;
		Print("Price adjusted above stop level to "+DoubleToString(newPrice));
		return(newPrice);
	}
}


double AdjustBelowStopLevel(string pSymbol, double pPrice, int pPoints = 10)
{
	double currPrice = SymbolInfoDouble(pSymbol,SYMBOL_BID);
	double point = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double stopLevel = SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL) * point;
	double stopPrice = currPrice - stopLevel;
	double addPoints = pPoints * point;
	
	if(pPrice < stopPrice - addPoints) return(pPrice);
	else
	{
		double newPrice = stopPrice - addPoints;
		Print("Price adjusted below stop level to "+DoubleToString(newPrice));
		return(newPrice);
	}
}


//+------------------------------------------------------------------+
//| Open position information                                          |
//+------------------------------------------------------------------+

class CPositions
{
   protected:
      ulong BuyTickets[];
      ulong SellTickets[];
      ulong Tickets[];
      int BuyCount;
      int SellCount;
      int TotalCount;
      
      void GetOpenPositions(ulong pMagicNumber = 0);
      int ResizeArray(ulong &array[]);   
   
   
   public:
      //return the number of BUY/SELL/Total positions 
      int Buy(ulong pMagicNumber);
      int Sell(ulong pMagicNumber);
      int TotalPositions(ulong pMagicNumber);
      
      void GetBuyTickets(ulong pMagicNumber, ulong &pTickets[]);
      void GetSellTickets(ulong pMagicNumber, ulong &pTickets[]);
      void GetTickets(ulong pMagicNumber, ulong &pTickets[]);
};

// Get open positions
void CPositions::GetOpenPositions(ulong pMagicNumber = 0)
{  
   BuyCount = 0;
   SellCount = 0;
   TotalCount = 0;
   
   ArrayResize(BuyTickets, 1);
   ArrayInitialize(BuyTickets, 0);
   
   ArrayResize(SellTickets, 1);
   ArrayInitialize(SellTickets, 0);
   
   ArrayResize(Tickets, 1);
   ArrayInitialize(Tickets, 0);
   
   for(int i = 0; i < PositionsTotal(); i++)
	{
	   ulong ticket = PositionGetTicket(i);
	   PositionSelectByTicket(ticket);
	   
	   if(PositionGetInteger(POSITION_MAGIC) != pMagicNumber && pMagicNumber > 0) continue;
	   
	   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
	   {
	      BuyCount++;
	      if (BuyCount == 1)
	         BuyTickets[0] = PositionGetInteger(POSITION_TICKET);
	      else{
	         int arrayIndex = ResizeArray(BuyTickets);
	         BuyTickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	      }    
	   }
	   else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
	   {
	      SellCount++;
	      if (SellCount == 1)
	         SellTickets[0] = PositionGetInteger(POSITION_TICKET);
	      else{
	         int arrayIndex = ResizeArray(SellTickets);
	         SellTickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	      }
	   }
	   
	   TotalCount++; 
	   if (TotalCount == 1)
	         Tickets[0] = PositionGetInteger(POSITION_TICKET);
	      else{
	         int arrayIndex = ResizeArray(Tickets);
	         Tickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	      }
	}
}

int CPositions::ResizeArray(ulong &array[])
{
   int arrayIndex = 0;
   if(ArraySize(array) >= 1)
   {
      int newSize = ArrayResize(array, ArraySize(array) + 1);
      arrayIndex = newSize - 1;
   }
   
   return arrayIndex;
}

int CPositions::Buy(ulong pMagicNumber)
{
   GetOpenPositions(pMagicNumber);
   return(BuyCount);
}

int CPositions::Sell(ulong pMagicNumber)
{
   GetOpenPositions(pMagicNumber);
   return(SellCount);
}

int CPositions::TotalPositions(ulong pMagicNumber)
{
   GetOpenPositions(pMagicNumber);
   return(TotalCount);
}

void CPositions::GetBuyTickets(ulong pMagicNumber,ulong &pTickets[])
{
   GetOpenPositions(pMagicNumber);
   ArrayCopy(pTickets, BuyTickets);
   return;
}

void CPositions::GetSellTickets(ulong pMagicNumber,ulong &pTickets[])
{
   GetOpenPositions(pMagicNumber);
   ArrayCopy(pTickets, SellTickets);
   return;
}

void CPositions::GetTickets(ulong pMagicNumber,ulong &pTickets[])
{
   GetOpenPositions(pMagicNumber);
   ArrayCopy(pTickets, Tickets);
   return;
}


//+------------------------------------------------------------------+
//| Position Information Functions                                   |
//+------------------------------------------------------------------+


string PositionComment(ulong pTicket = 0)
{
	bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetString(POSITION_COMMENT));
	else return(NULL);
}


long PositionType(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetInteger(POSITION_TYPE));
	else return(WRONG_VALUE);
}


long PositionIdentifier(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetInteger(POSITION_IDENTIFIER));
	else return(WRONG_VALUE);
}


double PositionOpenPrice(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_PRICE_OPEN));
	else return(WRONG_VALUE);
}


long PositionOpenTime(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetInteger(POSITION_TIME));
	else return(WRONG_VALUE);
}


double PositionVolume(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_VOLUME));
	else return(WRONG_VALUE);
}


double PositionStopLoss(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_SL));
	else return(WRONG_VALUE);
}


double PositionTakeProfit(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_TP));
	else return(WRONG_VALUE);
}


double PositionProfit(ulong pTicket = 0)
{
	bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetDouble(POSITION_PROFIT));
	else return(WRONG_VALUE);
}

long PositionMagicNumber(ulong pTicket = 0)
{
   bool select = false;
   if(pTicket > 0) select = PositionSelectByTicket(pTicket);
	
	if(select == true) return(PositionGetInteger(POSITION_MAGIC));
	else return(NULL);
}
