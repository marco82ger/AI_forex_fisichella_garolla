//+------------------------------------------------------------------+
//|                                                      Pending.mqh |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


//+------------------------------------------------------------------+
//| Pending Order Counts and Tickets                                 |
//+------------------------------------------------------------------+

class CPending
{
	private:
		void OrderCount(string pSymbol);
		int BuyLimitCount, SellLimitCount, BuyStopCount, SellStopCount, BuyStopLimitCount, SellStopLimitCount, TotalPendingCount;
		ulong PendingTickets[];
		
	public:
		int BuyLimit(string pSymbol);
		int SellLimit(string pSymbol);
		int BuyStop(string pSymbol);
		int SellStop(string pSymbol);
		int BuyStopLimit(string pSymbol);
		int SellStopLimit(string pSymbol);
		int TotalPending(string pSymbol);
		
		void GetTickets(string pSymbol, ulong &pTickets[]);
};


// Internal function to count orders and collect ticket numbers
void CPending::OrderCount(string pSymbol)
{
	BuyLimitCount = 0; SellLimitCount = 0; BuyStopCount = 0; SellStopCount = 0; BuyStopLimitCount = 0; SellStopLimitCount = 0; TotalPendingCount = 0;
	
	ArrayResize(PendingTickets, 1);
	ArrayInitialize(PendingTickets, 0);
	
	for(int i = 0; i < OrdersTotal(); i++)
	{
		ulong ticket = OrderGetTicket(i);
		if(OrderGetString(ORDER_SYMBOL) == pSymbol)
		{
			long type = OrderGetInteger(ORDER_TYPE);
			
			switch((int)type)
			{
				case ORDER_TYPE_BUY_STOP:
				BuyStopCount++; break;
				
				case ORDER_TYPE_SELL_STOP:
				SellStopCount++; break;
				
				case ORDER_TYPE_BUY_LIMIT:
				BuyLimitCount++; break;
				
				case ORDER_TYPE_SELL_LIMIT:
				SellLimitCount++; break;
				
				case ORDER_TYPE_BUY_STOP_LIMIT:
				BuyStopLimitCount++; break;
				
				case ORDER_TYPE_SELL_STOP_LIMIT:
				SellStopLimitCount++; break;
			}
			
			TotalPendingCount++;
			
			ArrayResize(PendingTickets,TotalPendingCount);
			PendingTickets[ArraySize(PendingTickets)-1] = ticket;
		}
	}
}


// Order counts
int CPending::BuyLimit(string pSymbol)
{
	OrderCount(pSymbol);
	return(BuyLimitCount);
}


int CPending::SellLimit(string pSymbol)
{
	OrderCount(pSymbol);
	return(SellLimitCount);
}


int CPending::BuyStop(string pSymbol)
{
	OrderCount(pSymbol);
	return(BuyStopCount);
}


int CPending::SellStop(string pSymbol)
{
	OrderCount(pSymbol);
	return(SellStopCount);
}


int CPending::BuyStopLimit(string pSymbol)
{
	OrderCount(pSymbol);
	return(BuyStopLimitCount);
}


int CPending::SellStopLimit(string pSymbol)
{
	OrderCount(pSymbol);
	return(SellStopLimitCount);
}


int CPending::TotalPending(string pSymbol)
{
	OrderCount(pSymbol);
	return(TotalPendingCount);
}


// Retrieve ticket numbers
void CPending::GetTickets(string pSymbol,ulong &pTickets[])
{
	OrderCount(pSymbol);
	ArrayCopy(pTickets,PendingTickets);
	return;
}



//+------------------------------------------------------------------+
//| Order Information                                                |
//+------------------------------------------------------------------+

long OrderType(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetInteger(ORDER_TYPE));
	else return(WRONG_VALUE);
}


long OrderExpirationTime(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetInteger(ORDER_TIME_EXPIRATION));
	else return(WRONG_VALUE);
}


long OrderExpirationType(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetInteger(ORDER_TYPE_TIME));
	else return(WRONG_VALUE);
}


long OrderMagicNumber(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetInteger(ORDER_MAGIC));
	else return(WRONG_VALUE);
}


double OrderVolume(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetDouble(ORDER_VOLUME_CURRENT));
	else return(WRONG_VALUE);
}


double OrderOpenPrice(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetDouble(ORDER_PRICE_OPEN));
	else return(WRONG_VALUE);
}


double OrderStopLimit(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetDouble(ORDER_PRICE_STOPLIMIT));
	else return(WRONG_VALUE);
}


double OrderStopLoss(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetDouble(ORDER_SL));
	else return(WRONG_VALUE);
}


double OrderTakeProfit(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetDouble(ORDER_TP));
	else return(WRONG_VALUE);
}


string OrderComment(ulong pTicket)
{
	bool select = OrderSelect(pTicket);
	if(select == true) return(OrderGetString(ORDER_COMMENT));
	else return(NULL);
}