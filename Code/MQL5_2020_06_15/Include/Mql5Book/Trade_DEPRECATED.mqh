//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
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


#define MAX_RETRIES 5		// Max retries on error
#define RETRY_DELAY 3000	// Retry delay in ms

#include <errordescription.mqh>
//Added by Marco
#include "SymbolInfo.mqh"


//+------------------------------------------------------------------+
//| CTrade Class - Open, Close and Modify Orders                                                           |
//+------------------------------------------------------------------+

class CTrade
{
	protected:
		MqlTradeRequest request;
		
		bool OpenPosition(string pSymbol, ENUM_ORDER_TYPE pType, double pVolume, double pStop = 0, double pProfit = 0, string pComment = NULL);
		bool OpenPending(string pSymbol, ENUM_ORDER_TYPE pType, double pVolume, double pPrice, double pStop = 0, double pProfit = 0, double pStopLimit = 0, datetime pExpiration = 0, string pComment = NULL);
		void LogTradeRequest();
		bool FillingCheck(const string symbol);
		bool ExpirationCheck(const string symbol);
		
		ulong magicNumber;
		ulong deviation;
		ENUM_ORDER_TYPE_FILLING fillType;
		
	public:
		MqlTradeResult result;
	
		bool Buy(string pSymbol, double pVolume, double pStop = 0, double pProfit = 0, string pComment = NULL);
		bool Sell(string pSymbol, double pVolume, double pStop = 0, double pProfit = 0, string pComment = NULL);
		bool BuyStop(string pSymbol, double pVolume, double pPrice, double pStop = 0, double pProfit = 0, datetime pExpiration = 0, string pComment = NULL);
		bool SellStop(string pSymbol, double pVolume, double pPrice, double pStop = 0, double pProfit = 0, datetime pExpiration = 0, string pComment = NULL);
		bool BuyLimit(string pSymbol, double pVolume, double pPrice, double pStop = 0, double pProfit = 0, datetime pExpiration = 0, string pComment = NULL);
		bool SellLimit(string pSymbol, double pVolume, double pPrice, double pStop = 0, double pProfit = 0, datetime pExpiration = 0, string pComment = NULL);
		bool BuyStopLimit(string pSymbol, double pVolume, double pPrice, double pStopLimit, double pStop = 0, double pProfit = 0,  datetime pExpiration = 0, string pComment = NULL);
		bool SellStopLimit(string pSymbol, double pVolume, double pPrice, double pStopLimit, double pStop = 0, double pProfit = 0,  datetime pExpiration = 0, string pComment = NULL);
		
		bool ModifyPosition(string pSymbol, double pStop, double pProfit = 0);
		bool ModifyPending(ulong pTicket, double pPrice, double pStop, double pProfit, datetime pExpiration = 0);
		bool Close(string pSymbol, double pVolume = 0, string pComment = NULL);
		bool Delete(ulong pTicket);
			
		void MagicNumber(ulong pMagic);
		void Deviation(ulong pDeviation);
		void FillType(ENUM_ORDER_TYPE_FILLING pFill);
};


// Open position
bool CTrade::OpenPosition(string pSymbol, ENUM_ORDER_TYPE pType, double pVolume, double pStop = 0, double pProfit = 0, string pComment = NULL)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	//added by Marco since problem on filling mode
	//fillType=(ENUM_ORDER_TYPE_FILLING)SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
	
	request.action = TRADE_ACTION_DEAL;
	request.symbol = pSymbol;
	request.type = pType;
	request.sl = pStop;
	request.tp = pProfit;
	request.comment = pComment;
	request.deviation = deviation;
	request.type_filling = fillType;
	request.magic = magicNumber;
	
	// Calculate lot size
	double positionVol = 0;
	long positionType = WRONG_VALUE;
	
	if(PositionSelect(pSymbol) == true)
	{
		positionVol = PositionGetDouble(POSITION_VOLUME);
		positionType = PositionGetInteger(POSITION_TYPE);
	}
		
	if((pType == ORDER_TYPE_BUY && positionType == POSITION_TYPE_SELL) || (pType == ORDER_TYPE_SELL && positionType == POSITION_TYPE_BUY)) 
	{
		request.volume = pVolume + positionVol;
	}
	else request.volume = pVolume;
	
	// Order loop
	int retryCount = 0;
	int checkCode = 0;
	
	do 
	{
		if(pType == ORDER_TYPE_BUY) request.price = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
		else if(pType == ORDER_TYPE_SELL) request.price = SymbolInfoDouble(pSymbol,SYMBOL_BID);
		
		//Added by Marco 
		//--- check filling
      if(!FillingCheck(_Symbol))
      return(false);
      //
      
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
	Print("Open ",orderType," order #",result.order,": ",result.retcode," - ",errDesc,", Volume: ",result.volume,", Price: ",result.price,", Bid: ",result.bid,", Ask: ",result.ask);
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment(orderType," position opened at ",result.price," on ",pSymbol);
		return(true);
	}
	else return(false);
}


// Open pending order
bool CTrade::OpenPending(string pSymbol,ENUM_ORDER_TYPE pType,double pVolume,double pPrice,double pStop=0.000000,double pProfit=0.000000,double pStopLimit = 0,datetime pExpiration=0,string pComment=NULL)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	request.action = TRADE_ACTION_PENDING;
	request.symbol = pSymbol;
	request.type = pType;
	request.sl = pStop;
	request.tp = pProfit;
	request.comment = pComment;
	request.price = pPrice;
	request.volume = pVolume;
	request.stoplimit = pStopLimit;
	request.deviation = deviation;
	request.type_filling = fillType;
	request.magic = magicNumber;
	
	if(pExpiration > 0)
	{
		request.expiration = pExpiration;
		request.type_time = ORDER_TIME_SPECIFIED;
	}
	else request.type_time = ORDER_TIME_GTC;
	
	// Order loop
	int retryCount = 0;
	int checkCode = 0;
	
	do 
	{
	   //Added by Marco 
		//--- check filling
      if(!FillingCheck(_Symbol))
      return(false);
      //
	
		bool sent = OrderSend(request,result);
		
		checkCode = CheckReturnCode(result.retcode);
		
		if(checkCode == CHECK_RETCODE_OK) break;
		else if(checkCode == CHECK_RETCODE_ERROR)
		{
			string errDesc = TradeServerReturnCodeDescription(result.retcode);
			Alert("Open pending order: Error ",result.retcode," - ",errDesc);
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
	
	Print("Open ",orderType," order #",result.order,": ",result.retcode," - ",errDesc,", Volume: ",result.volume,", Price: ",request.price,
		", Bid: ",SymbolInfoDouble(pSymbol,SYMBOL_BID),", Ask: ",SymbolInfoDouble(pSymbol,SYMBOL_ASK),", SL: ",request.sl,", TP: ",request.tp,
		", Stop Limit: ",request.stoplimit,", Expiration: ",request.expiration);
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment(orderType," order opened at ",request.price," on ",pSymbol);
		return(true);
	}
	else return(false);
}


// Modify position
bool CTrade::ModifyPosition(string pSymbol,double pStop,double pProfit=0.000000)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	request.action = TRADE_ACTION_SLTP;
	request.symbol = pSymbol;
	request.sl = pStop;
	request.tp = pProfit;
	
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
	Print("Modify position: ",result.retcode," - ",errDesc,", SL: ",request.sl,", TP: ",request.tp,", Bid: ",SymbolInfoDouble(pSymbol,SYMBOL_BID),", Ask: ",SymbolInfoDouble(pSymbol,SYMBOL_ASK),", Stop Level: ",SymbolInfoInteger(pSymbol,SYMBOL_TRADE_STOPS_LEVEL));
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment("Position modified on ",pSymbol,", SL: ",request.sl,", TP: ",request.tp);
		return(true);
	}
	else return(false);
}


// Modify pending order
bool CTrade::ModifyPending(ulong pTicket,double pPrice,double pStop,double pProfit,datetime pExpiration=0)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	request.action = TRADE_ACTION_MODIFY;
	request.order = pTicket;
	request.sl = pStop;
	request.tp = pProfit;
	
	bool select = OrderSelect(pTicket);
	
	if(pPrice > 0) request.price = pPrice;
	else request.price = OrderGetDouble(ORDER_PRICE_OPEN);
	
	if(pExpiration > 0)
	{
		request.expiration = pExpiration;
		request.type_time = ORDER_TIME_SPECIFIED;
	}
	else request.type_time = ORDER_TIME_GTC;
	
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
			Alert("Modify pending order: Error ",result.retcode," - ",errDesc);
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
	
	select = OrderSelect(pTicket);
	
	string errDesc = TradeServerReturnCodeDescription(result.retcode);
	Print("Modify pending order #",pTicket,": ",result.retcode," - ",errDesc,", Price: ",OrderGetDouble(ORDER_PRICE_OPEN),", SL: ",request.sl,", TP: ",request.tp,", Expiration: ",request.expiration);
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment("Pending order ",pTicket," modified,"," Price: ",OrderGetDouble(ORDER_PRICE_OPEN),", SL: ",request.sl,", TP: ",request.tp);
		return(true);
	}
	else return(false);
}


// Close position
bool CTrade::Close(string pSymbol,double pVolume=0.000000,string pComment=NULL)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	request.action = TRADE_ACTION_DEAL;
	request.symbol = pSymbol;
	request.deviation = deviation;
	request.type_filling = fillType;
	request.magic = magicNumber;
			
	double closeVol = 0;
	long openType = WRONG_VALUE;
	
	if(PositionSelect(pSymbol) == true)
	{
		closeVol = PositionGetDouble(POSITION_VOLUME);
		openType = PositionGetInteger(POSITION_TYPE);
	}
	else return(false);
	
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
			request.price = SymbolInfoDouble(pSymbol,SYMBOL_BID);
		}
		else if(openType == POSITION_TYPE_SELL)
		{
			request.type = ORDER_TYPE_BUY;
			request.price = SymbolInfoDouble(pSymbol,SYMBOL_ASK);
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
	Print("Close ",posType," position #",result.order,": ",result.retcode," - ",errDesc,", Volume: ",result.volume,", Price: ",result.price,", Bid: ",result.bid,", Ask: ",result.ask);
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment(posType," position closed on ",pSymbol," at ",result.price);
		return(true);
	}
	else return(false);
}


// Delete pending order
bool CTrade::Delete(ulong pTicket)
{
	ZeroMemory(request);
	ZeroMemory(result);
	
	request.action = TRADE_ACTION_REMOVE;
	request.order = pTicket;
	
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
			Alert("Delete order: Error ",result.retcode," - ",errDesc);
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
	Print("Delete order #",pTicket,": ",result.retcode," - ",errDesc);
	
	if(checkCode == CHECK_RETCODE_OK) 
	{
		Comment("Pending order ",pTicket," deleted");
		return(true);
	}
	else return(false);
}

//Function added by Marco
//+------------------------------------------------------------------+
//| Checks and corrects type of filling policy                       |
//+------------------------------------------------------------------+
bool CTrade::FillingCheck(const string symbol)
  {
//--- get execution mode of orders by symbol
   ENUM_SYMBOL_TRADE_EXECUTION exec=(ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE);
//--- check execution mode
   if(exec==SYMBOL_TRADE_EXECUTION_REQUEST || exec==SYMBOL_TRADE_EXECUTION_INSTANT)
     {
      //--- neccessary filling type will be placed automatically
      return(true);
     }
//--- get possible filling policy types by symbol
   uint filling=(uint)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
//--- check execution mode again
   if(exec==SYMBOL_TRADE_EXECUTION_MARKET)
     {
      //--- for the MARKET execution mode
      //--- analyze order
      if(request.action!=TRADE_ACTION_PENDING)
        {
         //--- in case of instant execution order
         //--- if the required filling policy is supported, add it to the request
         if((filling&SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
           {
            fillType=ORDER_FILLING_FOK;
            request.type_filling=fillType;
            return(true);
           }
         if((filling&SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
           {
            fillType=ORDER_FILLING_IOC;
            request.type_filling=fillType;
            return(true);
           }
         //--- wrong filling policy, set error code
         result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
        }
      return(true);
     }
//--- EXCHANGE execution mode
   switch(fillType)
     {
      case ORDER_FILLING_FOK:
         //--- analyze order
         if(request.action==TRADE_ACTION_PENDING)
           {
            //--- in case of pending order
            //--- add the expiration mode to the request
            if(!ExpirationCheck(symbol))
               request.type_time=ORDER_TIME_DAY;
            //--- stop order?
            if(request.type==ORDER_TYPE_BUY_STOP || request.type==ORDER_TYPE_SELL_STOP ||
               request.type==ORDER_TYPE_BUY_LIMIT || request.type==ORDER_TYPE_SELL_LIMIT)
              {
               //--- in case of stop order
               //--- add the corresponding filling policy to the request
               request.type_filling=ORDER_FILLING_RETURN;
               return(true);
              }
           }
         //--- in case of limit order or instant execution order
         //--- if the required filling policy is supported, add it to the request
         if((filling&SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
           {
            request.type_filling=fillType;
            return(true);
           }
         //--- wrong filling policy, set error code
         result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
      case ORDER_FILLING_IOC:
         //--- analyze order
         if(request.action==TRADE_ACTION_PENDING)
           {
            //--- in case of pending order
            //--- add the expiration mode to the request
            if(!ExpirationCheck(symbol))
               request.type_time=ORDER_TIME_DAY;
            //--- stop order?
            if(request.type==ORDER_TYPE_BUY_STOP || request.type==ORDER_TYPE_SELL_STOP ||
               request.type==ORDER_TYPE_BUY_LIMIT || request.type==ORDER_TYPE_SELL_LIMIT)
              {
               //--- in case of stop order
               //--- add the corresponding filling policy to the request
               request.type_filling=ORDER_FILLING_RETURN;
               return(true);
              }
           }
         //--- in case of limit order or instant execution order
         //--- if the required filling policy is supported, add it to the request
         if((filling&SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
           {
            request.type_filling=fillType;
            return(true);
           }
         //--- wrong filling policy, set error code
         result.retcode=TRADE_RETCODE_INVALID_FILL;
         return(false);
      case ORDER_FILLING_RETURN:
         //--- add filling policy to the request
         request.type_filling=fillType;
         return(true);
     }
//--- unknown execution mode, set error code
   result.retcode=TRADE_RETCODE_ERROR;
   return(false);
}

//Added by Marco
//+------------------------------------------------------------------+
//| Check expiration type of pending order                           |
//+------------------------------------------------------------------+
bool CTrade::ExpirationCheck(const string symbol)
  {
   CSymbolInfo sym;
//--- check symbol
   if(!sym.Name((symbol==NULL)?Symbol():symbol))
      return(false);
//--- get flags
   int flags=sym.TradeTimeFlags();
//--- check type
   switch(request.type_time)
     {
      case ORDER_TIME_GTC:
         if((flags&SYMBOL_EXPIRATION_GTC)!=0)
         return(true);
         break;
      case ORDER_TIME_DAY:
         if((flags&SYMBOL_EXPIRATION_DAY)!=0)
         return(true);
         break;
      case ORDER_TIME_SPECIFIED:
         if((flags&SYMBOL_EXPIRATION_SPECIFIED)!=0)
         return(true);
         break;
      case ORDER_TIME_SPECIFIED_DAY:
         if((flags&SYMBOL_EXPIRATION_SPECIFIED_DAY)!=0)
         return(true);
         break;
      default:
         Print(__FUNCTION__+": Unknown expiration type");
         break;
     }
//--- failed
   return(false);
}

void CTrade::LogTradeRequest()
{
   Print("MqlTradeRequest - action:",request.action,", comment:",request.comment,", deviation:",request.deviation,", expiration:",request.expiration,", magic:",request.magic,", order:",request.order,", position:",request.position,", position_by:",request.position_by,", price:",request.price,", ls:",request.sl,", stoplimit:",request.stoplimit,", symbol:",request.symbol,", tp:",request.tp,", type:",request.type,", type_filling:",request.type_filling,", type_time:",request.type_time,", volume:",request.volume);
   Print("MqlTradeResult - ask:",result.ask,", bid:",result.bid,", comment:",result.comment,", deal:",result.deal,", order:",result.order,", price:",result.price,", request_id:",result.request_id,", retcode:",result.retcode,", retcode_external:",result.retcode_external,", volume:",result.volume);
}


// Trade opening shortcuts
bool CTrade::Buy(string pSymbol,double pVolume,double pStop=0.000000,double pProfit=0.000000,string pComment=NULL)
{
	bool success = OpenPosition(pSymbol,ORDER_TYPE_BUY,pVolume,pStop,pProfit,pComment);
	return(success);
}

bool CTrade::Sell(string pSymbol,double pVolume,double pStop=0.000000,double pProfit=0.000000,string pComment=NULL)
{
	bool success = OpenPosition(pSymbol,ORDER_TYPE_SELL,pVolume,pStop,pProfit,pComment);
	return(success);
}

bool CTrade::BuyLimit(string pSymbol,double pVolume,double pPrice,double pStop=0.000000,double pProfit=0.000000,datetime pExpiration=0,string pComment=NULL)
{
	bool success = OpenPending(pSymbol,ORDER_TYPE_BUY_LIMIT,pVolume,pPrice,pStop,pProfit,0,pExpiration,pComment);
	return(success);
}

bool CTrade::SellLimit(string pSymbol,double pVolume,double pPrice,double pStop=0.000000,double pProfit=0.000000,datetime pExpiration=0,string pComment=NULL)
{
	bool success = OpenPending(pSymbol,ORDER_TYPE_SELL_LIMIT,pVolume,pPrice,pStop,pProfit,0,pExpiration,pComment);
	return(success);
}

bool CTrade::BuyStop(string pSymbol,double pVolume,double pPrice,double pStop=0.000000,double pProfit=0.000000,datetime pExpiration=0,string pComment=NULL)
{
	bool success = OpenPending(pSymbol,ORDER_TYPE_BUY_STOP,pVolume,pPrice,pStop,pProfit,0,pExpiration,pComment);
	return(success);
}

bool CTrade::SellStop(string pSymbol,double pVolume,double pPrice,double pStop=0.000000,double pProfit=0.000000,datetime pExpiration=0,string pComment=NULL)
{
	bool success = OpenPending(pSymbol,ORDER_TYPE_SELL_STOP,pVolume,pPrice,pStop,pProfit,0,pExpiration,pComment);
	return(success);
}

bool CTrade::BuyStopLimit(string pSymbol,double pVolume,double pPrice,double pStopLimit,double pStop=0.000000,double pProfit=0.000000,datetime pExpiration=0,string pComment=NULL)
{
	bool success = OpenPending(pSymbol,ORDER_TYPE_BUY_STOP_LIMIT,pVolume,pPrice,pStop,pProfit,pStopLimit,pExpiration,pComment);
	return(success);
}

bool CTrade::SellStopLimit(string pSymbol,double pVolume,double pPrice,double pStopLimit,double pStop=0.000000,double pProfit=0.000000,datetime pExpiration=0,string pComment=NULL)
{
	bool success = OpenPending(pSymbol,ORDER_TYPE_SELL_STOP_LIMIT,pVolume,pPrice,pStop,pProfit,pStopLimit,pExpiration,pComment);
	return(success);
}


// Set magic number
void CTrade::MagicNumber(ulong pMagic)
{
	magicNumber = pMagic;
}


// Set deviation
void CTrade::Deviation(ulong pDeviation)
{
	deviation = pDeviation;
}


// Set fill type
void CTrade::FillType(ENUM_ORDER_TYPE_FILLING pFill)
{
	fillType = pFill;
}


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
//| Position Information                                             |
//+------------------------------------------------------------------+


string PositionComment(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetString(POSITION_COMMENT));
	else return(NULL);
}


long PositionType(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetInteger(POSITION_TYPE));
	else return(WRONG_VALUE);
}


long PositionIdentifier(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetInteger(POSITION_IDENTIFIER));
	else return(WRONG_VALUE);
}


double PositionOpenPrice(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetDouble(POSITION_PRICE_OPEN));
	else return(WRONG_VALUE);
}


long PositionOpenTime(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetInteger(POSITION_TIME));
	else return(WRONG_VALUE);
}


double PositionVolume(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetDouble(POSITION_VOLUME));
	else return(WRONG_VALUE);
}


double PositionStopLoss(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetDouble(POSITION_SL));
	else return(WRONG_VALUE);
}


double PositionTakeProfit(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetDouble(POSITION_TP));
	else return(WRONG_VALUE);
}


double PositionProfit(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetDouble(POSITION_PROFIT));
	else return(WRONG_VALUE);
}


//+------------------------------------------------------------------+
//| Miscellaneous Functions & Enumerations                                                            |
//+------------------------------------------------------------------+


enum ENUM_CHECK_RETCODE
{
	CHECK_RETCODE_OK,
	CHECK_RETCODE_ERROR,
	CHECK_RETCODE_RETRY
};


string CheckOrderType(ENUM_ORDER_TYPE pType)
{
	string orderType;
	if(pType == ORDER_TYPE_BUY) orderType = "buy";
	else if(pType == ORDER_TYPE_SELL) orderType = "sell";
	else if(pType == ORDER_TYPE_BUY_STOP) orderType = "buy stop";
	else if(pType == ORDER_TYPE_BUY_LIMIT) orderType = "buy limit";
	else if(pType == ORDER_TYPE_SELL_STOP) orderType = "sell stop";
	else if(pType == ORDER_TYPE_SELL_LIMIT) orderType = "sell limit";
	else if(pType == ORDER_TYPE_BUY_STOP_LIMIT) orderType = "buy stop limit";
	else if(pType == ORDER_TYPE_SELL_STOP_LIMIT) orderType = "sell stop limit";
	else orderType = "invalid order type";
	return(orderType);
}