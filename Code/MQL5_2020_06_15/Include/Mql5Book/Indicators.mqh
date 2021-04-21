//+------------------------------------------------------------------+
//|                                                   Indicators.mqh |
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


#define MAX_COUNT 100
#define BIG_NUMBER 100
#define MAX_COUNT_BANDWIDTH 20


//+------------------------------------------------------------------+
//| Base Class                                                       |
//+------------------------------------------------------------------+

class CIndicator
{
	protected:
		int handle;
		double main[];
		
	public:
		CIndicator(void);
		double Main(int pShift=0);
		void Release();
		virtual int Init() { return(handle); }
};

CIndicator::CIndicator(void)
{
	ArraySetAsSeries(main,true);
}

double CIndicator::Main(int pShift=0)
{
	CopyBuffer(handle,0,0,MAX_COUNT,main);
	double value = NormalizeDouble(main[pShift],_Digits);
	return(value);
}

void CIndicator::Release(void)
{
	IndicatorRelease(handle);
}


//+------------------------------------------------------------------+
//| Moving Average                                                   |
//+------------------------------------------------------------------+

/*

CiMA MA;

sinput string MA;		// Moving Average
input int MAPeriod = 10;
input ENUM_MA_METHOD MAMethod = 0;
input int MAShift = 0;
input ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE;

MA.Init(_Symbol,_Period,MAPeriod,MAShift,MAMethod,MAPrice);

MA.Main()

*/

class CiMA : public CIndicator
{
	public:
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pMAPeriod,int pMAShift,ENUM_MA_METHOD pMAMethod,ENUM_APPLIED_PRICE pMAPrice);
};

int CiMA::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pMAPeriod,int pMAShift,ENUM_MA_METHOD pMAMethod,ENUM_APPLIED_PRICE pMAPrice)
{
	handle = iMA(pSymbol,pTimeframe,pMAPeriod,pMAShift,pMAMethod,pMAPrice);
	return(handle);
}


//+------------------------------------------------------------------+
//| RSI                                                              |
//+------------------------------------------------------------------+

/*

CiRSI RSI;

sinput string RS;	// RSI
input int RSIPeriod = 8;
input ENUM_APPLIED_PRICE RSIPrice = PRICE_CLOSE;

RSI.Init(_Symbol,_Period,RSIPeriod,RSIPrice);

RSI.Main()

*/

class CiRSI : public CIndicator
{
	public:
		int Init(string pSymbol, ENUM_TIMEFRAMES pTimeframe, int pRSIPeriod, ENUM_APPLIED_PRICE pRSIPrice);
};

int CiRSI::Init(string pSymbol, ENUM_TIMEFRAMES pTimeframe, int pRSIPeriod, ENUM_APPLIED_PRICE pRSIPrice)
{
	handle = iRSI(pSymbol,pTimeframe,pRSIPeriod,pRSIPrice);
	return(handle);
}


//+------------------------------------------------------------------+
//| Stochastic                                                       |
//+------------------------------------------------------------------+

/*

CiStochastic Stoch;

sinput string STO;	// Stochastic
input int KPeriod = 10;
input int DPeriod = 3;
input int Slowing = 3;
input ENUM_MA_METHOD StochMethod = MODE_SMA;
input ENUM_STO_PRICE StochPrice = STO_LOWHIGH;

Stoch.Init(_Symbol,_Period,KPeriod,DPeriod,Slowing,StochMethod,StochPrice);

Stoch.Main()
Stoch.Signal()

*/

class CiStochastic : public CIndicator
{
	private:
		double signal[];
	
	public:
		int Init(string pSymbol, ENUM_TIMEFRAMES pTimeframe, int pKPeriod, int pDPeriod, int pSlowing, ENUM_MA_METHOD pMAMethod, ENUM_STO_PRICE pPrice);
		double Signal(int pShift=0);
		CiStochastic(void);
};

CiStochastic::CiStochastic(void)
{
	ArraySetAsSeries(signal,true);
}

int CiStochastic::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pKPeriod,int pDPeriod,int pSlowing,ENUM_MA_METHOD pMAMethod,ENUM_STO_PRICE pPrice)
{
	handle = iStochastic(pSymbol,pTimeframe,pKPeriod,pDPeriod,pSlowing,pMAMethod,pPrice);
	return(handle);
}

double CiStochastic::Signal(int pShift=0)
{
	CopyBuffer(handle,1,0,MAX_COUNT,signal);
	double value = NormalizeDouble(signal[pShift],_Digits);
	return(value);
}


//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+

/*

CiBollinger Bands;

sinput string BB;		// Bollinger Bands
input int BandsPeriod = 20;
input int BandsShift = 0;
input double BandsDeviation = 2;
input ENUM_APPLIED_PRICE BandsPrice = PRICE_CLOSE; 

Bands.Init(_Symbol,_Period,BandsPeriod,BandsShift,BandsDeviation,BandsPrice);

Bands.Upper()
Bands.Lower()

*/

class CiBollinger : public CIndicator
{
	private:
		double upper[], lower[];
		
	public:
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pPeriod,int pShift,double pDeviation,ENUM_APPLIED_PRICE pPrice);
		double Upper(int pShift=0);
		double Lower(int pShift=0);
		double Bandwidth (int pShift=0);
		int IdxMinBandwidth (int pIntervalBBBreakout=20);
		CiBollinger();
};

CiBollinger::CiBollinger(void)
{
	ArraySetAsSeries(upper,true);
	ArraySetAsSeries(lower,true);
}

int CiBollinger::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pPeriod,int pShift,double pDeviation,ENUM_APPLIED_PRICE pPrice)
{
	handle = iBands(pSymbol,pTimeframe,pPeriod,pShift,pDeviation,pPrice);
	return(handle);
}

double CiBollinger::Lower(int pShift=0)
{
	CopyBuffer(handle,2,0,MAX_COUNT,lower);
	double value = NormalizeDouble(lower[pShift],_Digits);
	return(value);
}

double CiBollinger::Upper(int pShift=0)
{
	CopyBuffer(handle,1,0,MAX_COUNT,upper);
	double value = NormalizeDouble(upper[pShift],_Digits);
	return(value);
}

double CiBollinger::Bandwidth(int pShift=0)
{
   int copied = CopyBuffer(handle,0,0,MAX_COUNT,main);
   if(copied == -1) return(BIG_NUMBER);
   copied = CopyBuffer(handle,1,0,MAX_COUNT,upper);
   if(copied == -1) return(BIG_NUMBER);
	copied = CopyBuffer(handle,2,0,MAX_COUNT,lower);
	if(copied == -1) return(BIG_NUMBER);
	//Bandwidth
	double value = NormalizeDouble((upper[pShift]-lower[pShift])/main[pShift],_Digits);
	return(value);
}

int CiBollinger::IdxMinBandwidth(int pIntervalBBBreakout=20)
{
   double bandwidth[];
   ArrayResize(bandwidth, pIntervalBBBreakout);
	ArraySetAsSeries(bandwidth,true);
	
	for (int i=0; i<pIntervalBBBreakout; i++){
	   bandwidth[i] = Bandwidth(i);
	}
	
	int minIdx = ArrayMinimum(bandwidth);
	return minIdx;
}
//+------------------------------------------------------------------+
//| MACD                                                             |
//+------------------------------------------------------------------+

/*

CiMACD MACD;

sinput string MACDSettings;	// MACD Settings
input int MACDFastPeriod = 12;
input int MACDSlowPeriod = 26;
input int MACDSignalPeriod = 9;
input ENUM_APPLIED_PRICE MACDPrice = PRICE_CLOSE; 

MACD.Init(_Symbol,_Period,MACDFastPeriod,MACDSlowPeriod,MACDSignalPeriod,MACDPrice);

MACD.Main();
MACD.Signal();

*/


class CiMACD : public CIndicator
{
	private:
		double signal[];
		
	public:
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pFastPeriod,int pSlowPeriod,int pSignalPeriod,ENUM_APPLIED_PRICE pPrice);
		double Signal(int pShift=0);
		CiMACD();
}; 

CiMACD::CiMACD()
{
	ArraySetAsSeries(signal,true);
}

int CiMACD::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pFastPeriod,int pSlowPeriod,int pSignalPeriod,ENUM_APPLIED_PRICE pPrice)
{
	handle = iMACD(pSymbol,pTimeframe,pFastPeriod,pSlowPeriod,pSignalPeriod,pPrice);
	return(handle);
}

double CiMACD::Signal(int pShift=0)
{
	CopyBuffer(handle,1,0,MAX_COUNT,signal);
	double value = NormalizeDouble(signal[pShift],_Digits);
	return(value); 
}



//+------------------------------------------------------------------+
//| PSAR                                                             |
//+------------------------------------------------------------------+

/*

CiSAR SAR;

sinput string SARSet; 	// SAR Settings
input double SARStep = 0.02;
input double SARMaximum = 0.2;

SAR.Init(_Symbol,_Period,SARStep,SARMaximum);

SAR.Main();

*/


class CiSAR : public CIndicator
{
	public:
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,double pStep,double pMaximum);
}; 


int CiSAR::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,double pStep,double pMaximum)
{
	handle = iSAR(pSymbol,pTimeframe,pStep,pMaximum);
	return(handle);
}



//+------------------------------------------------------------------+
//| ADX                                                              |
//+------------------------------------------------------------------+

/*
CiADX ADX;

sinput string ADXSet;	// ADX Settings
input int ADXPeriod = 10;

ADX.Init(_Symbol,_Period,ADXPeriod);

ADX.Plus();
ADX.Minus();
*/


class CiADX : public CIndicator
{
	private:
		double plus[];
		double minus[];
		
	public:
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pPeriod);
		double Plus(int pShift=0);
		double Minus(int pShift=0);
		CiADX();
}; 


CiADX::CiADX()
{
	ArraySetAsSeries(plus,true);
	ArraySetAsSeries(minus,true);
}


int CiADX::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,int pPeriod)
{
	handle = iADX(pSymbol,pTimeframe,pPeriod);
	return(handle);
}


double CiADX::Plus(int pShift=0)
{
	CopyBuffer(handle,1,0,MAX_COUNT,plus);
	double value = NormalizeDouble(plus[pShift],_Digits);
	return(value); 
} 


double CiADX::Minus(int pShift=0)
{
	CopyBuffer(handle,2,0,MAX_COUNT,minus);
	double value = NormalizeDouble(minus[pShift],_Digits);
	return(value); 
} 

//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+

/*

CiHeikenAshi HA;

HA.Init(_Symbol,_Period);

HA.HAOpen()
HA.HAClose()
HA.HALow()
HA.HAHigh()

*/

class CiHeikenAshi : public CIndicator
{
	private:
		double haOpen[], haClose[], haHigh[], haLow[];
		
	public:
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe);
		double HAOpen(int pShift=0);
		double HAClose(int pShift=0);
		double HALow(int pShift=0);
		double HAHigh(int pShift=0);
		CiHeikenAshi();
};

CiHeikenAshi::CiHeikenAshi(void)
{
	ArraySetAsSeries(haOpen,true);
	ArraySetAsSeries(haClose,true);
	ArraySetAsSeries(haHigh,true);
	ArraySetAsSeries(haLow,true);
}

int CiHeikenAshi::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe)
{
	handle = iCustom(pSymbol,pTimeframe,"Examples\\Heiken_Ashi");
	return(handle);
}

double CiHeikenAshi::HAOpen(int pShift=0)
{
	CopyBuffer(handle,0,0,MAX_COUNT,haOpen);
	double value = NormalizeDouble(haOpen[pShift],_Digits);
	return(value);
}

double CiHeikenAshi::HAHigh(int pShift=0)
{
	CopyBuffer(handle,1,0,MAX_COUNT,haHigh);
	double value = NormalizeDouble(haHigh[pShift],_Digits);
	return(value);
}

double CiHeikenAshi::HALow(int pShift=0)
{
	CopyBuffer(handle,2,0,MAX_COUNT,haLow);
	double value = NormalizeDouble(haLow[pShift],_Digits);
	return(value);
}

double CiHeikenAshi::HAClose(int pShift=0)
{
	CopyBuffer(handle,3,0,MAX_COUNT,haClose);
	double value = NormalizeDouble(haClose[pShift],_Digits);
	return(value);
}
//+------------------------------------------------------------------+
//| Blank Indicator Class Templates                                  |
//+------------------------------------------------------------------+

/* 

Replace _INDNAME_ with the name of the indicator.
Replace _INDFUNC_ with the name of the correct technical indicator function.
Add appropriate input parameters (...) to Init() function.
Rename Buffer1(), Buffer2(), etc. to something user-friendly.
Add or remove buffer arrays and functions as necessary.



// Single Buffer Indicator

class Ci_INDNAME_ : public CIndicator
{
	public:
		int Init(string pSymbol, ENUM_TIMEFRAMES pTimeframe, ... );
}; 


int Ci_INDNAME_::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe, ... )
{
	handle = _INDFUNC_(pSymbol,pTimeframe, ... );
	return(handle);
}



// Multi-Buffer Indicator

class Ci_INDNAME_ : public CIndicator
{
	private:
		double buffer1[];
		double buffer2[];
		
	public:
		int Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe, ... );
		double Buffer1(int pShift=0);
		double Buffer2(int pShift=0);
		Ci_INDNAME_();
}; 


Ci_INDNAME_::Ci_INDNAME_()
{
	ArraySetAsSeries(buffer1,true);
	ArraySetAsSeries(buffer2,true);
}


int Ci_INDNAME_::Init(string pSymbol,ENUM_TIMEFRAMES pTimeframe,...)
{
	handle = _INDFUNC_(pSymbol,pTimeframe,...);
	return(handle);
}


double Ci_INDNAME_::Buffer1(int pShift=0)
{
	CopyBuffer(handle,1,0,MAX_COUNT,buffer1);
	double value = NormalizeDouble(buffer1[pShift],_Digits);
	return(value); 
} 


double Ci_INDNAME_::Buffer2(int pShift=0)
{
	CopyBuffer(handle,1,0,MAX_COUNT,buffer2);
	double value = NormalizeDouble(buffer2[pShift],_Digits);
	return(value); 
} 


*/