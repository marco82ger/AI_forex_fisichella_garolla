//+------------------------------------------------------------------+
//|                                                   TradeHedge.mqh |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You may 
 modify it if necessary. You may even share it, provided the 
 copyright above is present. No commercial use is permitted. 
*/

#include <errordescription.mqh>
#include <Mql5Book\Trade.mqh>


//+----------------------------------------------------------------------+
//| CTradeHedge Class - Open, Close and Modify Orders for Hedging Accounts                                                           |
//+----------------------------------------------------------------------+

class CTradeHedge : public CTrade
{
	protected:	
		ulong OpenPosition(string pSymbol, ENUM_ORDER_TYPE pType, double pVolume, double pStop = 0, double pProfit = 0, string pComment = NULL);
		
	public:	
		ulong Buy(string pSymbol, double pVolume, double pStop = 0, double pProfit = 0, string pComment = NULL);
		ulong Sell(string pSymbol, double pVolume, double pStop = 0, double pProfit = 0, string pComment = NULL);
		
		bool ModifyPosition(ulong pTicket, double pStop, double pProfit = 0);
		bool Close(ulong pTicket, double pVolume = 0, string pComment = NULL);
};


// Open position
ulong CTradeHedge::OpenPosition(string pSymbol, ENUM_ORDER_TYPE pType, double pVolume, double pStop = 0, double pProfit = 0, string pComment = NULL)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	request.action = TRADE_ACTION_DEAL;
	request.symbol = pSymbol;
	request.type = pType;
	request.sl = pStop;
	request.tp = pProfit;
	request.comment = pComment;
	request.volume = pVolume;
	request.deviation = deviation;
	request.type_filling = fillType;
	request.magic = magicNumber;
	
	// Order loop
	int retryCount = 0;
	int checkCode = 0;
	
	do 
	{
		if(pType == ORDER_TYPE_BUY) request.price = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
		else if(pType == ORDER_TYPE_SELL) request.price = SymbolInfoDouble(pSymbol,SYMBOL_BID);
				
		bool sent = OrderSend(request,result);
		
		checkCode = CheckReturnCode(result.retcode);
		
		if(checkCode == CHECK_RETCODE_OK) break;
		else if(checkCode == CHECK_RETCODE_ERROR)
		{
			string errDesc = TradeServerReturnCodeDescription(result.retcode);
			Alert("Open market order: Error ",result.retcode," - ",errDesc);
			LogTradeRequest();
			break;
		}
		else
		{
			Print("Server error detected, retrying...");
			Sleep(RETRY_DELAY);
			retryCount++;
		}
	}
	while(retryCount < MAX_RETRIES);
	
	if(retryCount >= MAX_RETRIES)
	{
		string errDesc = TradeServerReturnCodeDescription(result.retcode);
		Alert("Max retries exceeded: Error ",result.retcode," - ",errDesc);
	}
	
	string orderType = CheckOrderType(pType);
	string errDesc = TradeServerReturnCodeDescription(result.retcode);
	
	Print("Open ",orderType," order #",result.order,": ",result.retcode," - ",errDesc,", Volume: ",result.volume,", Price: ",result.price);
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment(orderType," position #",result.order," opened at ",result.price," on ",pSymbol);
		return(result.order);
	}
	else return(0);
}


// Modify position
bool CTradeHedge::ModifyPosition(ulong pTicket, double pStop, double pProfit=0.000000)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	bool select = PositionSelectByTicket(pTicket);
	string symbol = PositionGetString(POSITION_SYMBOL);
	
	request.action = TRADE_ACTION_SLTP;
	request.sl = pStop;
	request.tp = pProfit;
	request.position = pTicket;
	request.symbol = symbol;
	
	// Order loop
	int retryCount = 0;
	int checkCode = 0;
	
	do 
	{
		bool sent = OrderSend(request,result);
		
		checkCode = CheckReturnCode(result.retcode);
		
		if(checkCode == CHECK_RETCODE_OK) break;
		else if(checkCode == CHECK_RETCODE_ERROR)
		{
			string errDesc = TradeServerReturnCodeDescription(result.retcode);
			Alert("Modify position: Error ",result.retcode," - ",errDesc);
			LogTradeRequest();
			break;
		}
		else
		{
			Print("Server error detected, retrying...");
			Sleep(RETRY_DELAY);
			retryCount++;
		}
	}
	while(retryCount < MAX_RETRIES);
	
	if(retryCount >= MAX_RETRIES)
	{
		string errDesc = TradeServerReturnCodeDescription(result.retcode);
		Alert("Max retries exceeded: Error ",result.retcode," - ",errDesc);
	}

	string errDesc = TradeServerReturnCodeDescription(result.retcode);
	Print("Modify position #",pTicket,": ",result.retcode," - ",errDesc,", SL: ",request.sl,", TP: ",request.tp,", Bid: ",SymbolInfoDouble(symbol,SYMBOL_BID),", Ask: ",SymbolInfoDouble(symbol,SYMBOL_ASK),", Stop Level: ",SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL));
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment("Position #",pTicket," modified on ",symbol,", SL: ",request.sl,", TP: ",request.tp);
		return(true);
	}
	else return(false);
}


// Close position
bool CTradeHedge::Close(ulong pTicket, double pVolume=0.000000, string pComment=NULL)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	request.action = TRADE_ACTION_DEAL;
	request.position = pTicket;
	request.deviation = deviation;
	request.type_filling = fillType;
			
	double closeVol = 0;
	long openType = WRONG_VALUE;
	string symbol;
	
	if(PositionSelectByTicket(pTicket) == true)
	{
		closeVol = PositionGetDouble(POSITION_VOLUME);
		openType = PositionGetInteger(POSITION_TYPE);
		symbol = PositionGetString(POSITION_SYMBOL);
	}
	else return(false);
	
	request.symbol = symbol;
	
	if(pVolume > closeVol || pVolume <= 0) request.volume = closeVol; 
	else request.volume = pVolume;
	
	// Order loop
	int retryCount = 0;
	int checkCode = 0;
	
	do 
	{
		if(openType == POSITION_TYPE_BUY)
		{
			request.type = ORDER_TYPE_SELL;
			request.price = SymbolInfoDouble(symbol,SYMBOL_BID);
		}
		else if(openType == POSITION_TYPE_SELL)
		{
			request.type = ORDER_TYPE_BUY;
			request.price = SymbolInfoDouble(symbol,SYMBOL_ASK);
		}

		bool sent = OrderSend(request,result);
		
		checkCode = CheckReturnCode(result.retcode);
		
		if(checkCode == CHECK_RETCODE_OK) break;
		else if(checkCode == CHECK_RETCODE_ERROR)
		{
			string errDesc = TradeServerReturnCodeDescription(result.retcode);
			Alert("Close position: Error ",result.retcode," - ",errDesc);
			LogTradeRequest();
			break;
		}
		else
		{
			Print("Server error detected, retrying...");
			Sleep(RETRY_DELAY);
			retryCount++;
		}
	}
	while(retryCount < MAX_RETRIES);
	
	if(retryCount >= MAX_RETRIES)
	{
		string errDesc = TradeServerReturnCodeDescription(result.retcode);
		Alert("Max retries exceeded: Error ",result.retcode," - ",errDesc);
	}
	
	string posType;
	if(openType == POSITION_TYPE_BUY) posType = "Buy";
	else if(openType == POSITION_TYPE_SELL) posType = "Sell";
	
	string errDesc = TradeServerReturnCodeDescription(result.retcode);
	Print("Close ",posType," position #",pTicket,": ",result.retcode," - ",errDesc,", Volume: ",result.volume,", Price: ",result.price);
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment(posType," position closed on ",symbol," at ",result.price);
		return(true);
	}
	else return(false);
}


// Trade opening shortcuts
ulong CTradeHedge::Buy(string pSymbol,double pVolume,double pStop=0.000000,double pProfit=0.000000,string pComment=NULL)
{
	ulong ticket = OpenPosition(pSymbol,ORDER_TYPE_BUY,pVolume,pStop,pProfit,pComment);
	return(ticket);
}

ulong CTradeHedge::Sell(string pSymbol,double pVolume,double pStop=0.000000,double pProfit=0.000000,string pComment=NULL)
{
	ulong ticket = OpenPosition(pSymbol,ORDER_TYPE_SELL,pVolume,pStop,pProfit,pComment);
	return(ticket);
}


//+------------------------------------------------------------------+
//| Position Tickets & Counts                                        |
//+------------------------------------------------------------------+


// Open position information
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
	      int arrayIndex = ResizeArray(BuyTickets);
	      BuyTickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	   }
	   else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
	   {
	      SellCount++;
	      int arrayIndex = ResizeArray(SellTickets);
	      SellTickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	   }
	   
	   TotalCount++; 
      int arrayIndex = ResizeArray(Tickets);
      Tickets[arrayIndex] = PositionGetInteger(POSITION_TICKET);
	}
}

int CPositions::ResizeArray(ulong &array[])
{
   int arrayIndex = 0;
   if(ArraySize(array) > 1)
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