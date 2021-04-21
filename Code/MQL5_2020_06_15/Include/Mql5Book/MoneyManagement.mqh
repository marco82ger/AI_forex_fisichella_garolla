//+------------------------------------------------------------------+
//|                                              MoneyManagement.mqh |
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


#define MAX_PERCENT 10		// Maximum balance % used in money management


// Risk-based money management
double MoneyManagement(string pSymbol,double pFixedVol,double pPercent,int pStopPoints)
{
	double tradeSize;
	
	if(pPercent > 0 && pStopPoints > 0)
	{
		if(pPercent > MAX_PERCENT) pPercent = MAX_PERCENT;
		
		double margin = AccountInfoDouble(ACCOUNT_BALANCE) * (pPercent / 100);
		double tickSize = SymbolInfoDouble(pSymbol,SYMBOL_TRADE_TICK_VALUE);
		
		tradeSize = (margin / pStopPoints) / tickSize;
		tradeSize = VerifyVolume(pSymbol,tradeSize);
		
		return(tradeSize);
	}
	else
	{
		tradeSize = pFixedVol;
		tradeSize = VerifyVolume(pSymbol,tradeSize);
		
		return(tradeSize);
	}
}


// Verify and adjust trade volume
double VerifyVolume(string pSymbol,double pVolume)
{
	double minVolume = SymbolInfoDouble(pSymbol,SYMBOL_VOLUME_MIN);
	double maxVolume = SymbolInfoDouble(pSymbol,SYMBOL_VOLUME_MAX);
	double stepVolume = SymbolInfoDouble(pSymbol,SYMBOL_VOLUME_STEP);
	
	double tradeSize;
	if(pVolume < minVolume) tradeSize = minVolume;
	else if(pVolume > maxVolume) tradeSize = maxVolume;
	else tradeSize = MathRound(pVolume / stepVolume) * stepVolume;
	
	if(stepVolume >= 0.1) tradeSize = NormalizeDouble(tradeSize,1);
	else tradeSize = NormalizeDouble(tradeSize,2);
	
	return(tradeSize);
}


// Calculate distance between order price and stop loss in points
double StopPriceToPoints(string pSymbol,double pStopPrice, double pOrderPrice)
{
	double stopDiff = MathAbs(pStopPrice - pOrderPrice);
	double getPoint = SymbolInfoDouble(pSymbol,SYMBOL_POINT);
	double priceToPoint = stopDiff / getPoint;
	return(priceToPoint);
}


//+------------------------------------------------------------------+
//| Martingale Class                                                 |
//+------------------------------------------------------------------+
/*
#define HISTORY_DAYS 30

// Undocumented and untested - Use at your own risk
class CMartingale
{
	private:
		int ConsecutiveCount(string pSymbol, long pMagic, int pDays);
		int ConsWins, ConsLoss;
	
	public:
		enum ENUM_PROGRESSION {Martingale,Anti_Martingale};
		double Martingale(string pSymbol, long pMagic, double pBaseVol, double pMultiplier = 2, ENUM_PROGRESSION pProgress = Martingale);
};


double CMartingale::Martingale(string pSymbol, long pMagic, double pBaseVol, double pMultiplier = 2, ENUM_PROGRESSION pProgress = 0)
{
	double tradeSize;
	int consCount = ConsecutiveCount(pSymbol,pMagic,HISTORY_DAYS);
	
	if(((pProgress == Martingale) && (ConsLoss > 0)) || ((pProgress == Anti_Martingale) && (ConsWins > 0)))
	{
		tradeSize = pBaseVol * MathPow(pMultiplier,consCount);
	}
	else tradeSize = pBaseVol;
	
	tradeSize = VerifyVolume(pSymbol,tradeSize);
	
	return(tradeSize);
}


int CMartingale::ConsecutiveCount(string pSymbol, long pMagic, int pDays)
{
	long days = 86400 * pDays;
	HistorySelect(TimeCurrent() - days,TimeCurrent());

	int winCount = 0, lossCount = 0;
	
	for(int i=HistoryDealsTotal()-1; i>=0; i--)
	{
		ulong ticket = HistoryDealGetTicket(i);
		long entry = HistoryDealGetInteger(ticket,DEAL_ENTRY);
		double profit = HistoryDealGetDouble(ticket,DEAL_PROFIT);
		long magic = HistoryDealGetInteger(ticket,DEAL_MAGIC);
		string symbol = HistoryDealGetString(ticket,DEAL_SYMBOL);
		
		if((entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT) && magic == pMagic && symbol == pSymbol)
		{
			if(profit > 0 && lossCount == 0) winCount++;
			else if(profit < 0 && winCount == 0) lossCount++;
			else break;
		}
	}
	
	ConsWins = winCount;
	ConsLoss = lossCount;
		
	if(winCount > 0) return(winCount);
	else return(lossCount);
}
*/