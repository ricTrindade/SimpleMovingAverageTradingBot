//+------------------------------------------------------------------+
//|                                       Simple MA crossover EA.mq4 |
//|                                                 Ricardo Trindade |
//|                                        https://www.idontknow.com |
//+------------------------------------------------------------------+
#property copyright "Ricardo Trindade"
#property link      "https://www.idontknow.com"
#property version   "1.00"
#property strict


//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+

//Strategy Inputs 
input int    atrPeriod = 14;
input double atrStopMultiplier = 1.5;
input double riskPerTrade = 2;
input bool   UseTP = true; //Use Take Profit?

int order_long; double long_lot; double pip_l;
int order_short; double short_lot;double pip_s;

//Indicator Inputs 
input int slow_ma = 21;
input int fast_ma = 5;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

   //===============================
   //Confirmation indicator 
   //===============================
   //Simple Moving Average SLOW
   double ma_slow_1 = iMA(NULL, 0, slow_ma, 0, MODE_SMA, PRICE_CLOSE, 1);
   double ma_slow_2 = iMA(NULL, 0, slow_ma, 0, MODE_SMA, PRICE_CLOSE, 2);
   
   //Simple Moving Average FAST
   double ma_fast_1 = iMA(NULL, 0, fast_ma, 0, MODE_SMA, PRICE_CLOSE, 1);
   double ma_fast_2 = iMA(NULL, 0, fast_ma, 0, MODE_SMA, PRICE_CLOSE, 2);
   
   //===============================
   //Trade Signal & Entry  
   //===============================
   //Signal 
   bool long_entry = (ma_fast_1 > ma_slow_1) && (ma_fast_2 <= ma_slow_2);
   bool short_entry = (ma_fast_1 < ma_slow_1) && (ma_fast_2 >= ma_slow_2);
   //Entry 
   if (IsNewCandle()) {
   
      if (long_entry) {  
      
         //ATR
         double atr = iATR(NULL, 0, atrPeriod, 0);
         double LongATRstop = Ask - (atr * atrStopMultiplier);
         double LongATRprofit = UseTP ? Ask + (atr * atrStopMultiplier) : 0;
      
         //Pips for Lot Size Calculation
         double lot_l = PosSizeCalculator(riskPerTrade, Ask, LongATRstop);
         //double lot_l = Auto_Contract_Size(riskPerTrade, Ask, LongATRstop);
      
         //Comment StopLoss to trade
         order_long = OrderSend(NULL, OP_BUY, lot_l, Ask, 10, LongATRstop, LongATRprofit, NULL, 1);
      } 
      
      if (short_entry) {
      
         //ATR
         double atr = iATR(NULL, 0, atrPeriod, 0);
         double ShortATRstop = Bid + (atr * atrStopMultiplier);
         double ShortATRprofit = UseTP ? Bid - (atr * atrStopMultiplier) : 0;
      
         //Pips for Lot Size Calculation
         double lot_s = PosSizeCalculator(riskPerTrade, Bid, ShortATRstop);
         //double lot_s = Auto_Contract_Size(riskPerTrade, Bid, ShortATRstop);
         
         //Comment StopLoss to trade
         order_short = OrderSend(NULL, OP_SELL, lot_s, Bid, 10, ShortATRstop, ShortATRprofit, NULL, 2);
      }
   }
   
   if (OrderSelect(order_long, SELECT_BY_TICKET)) long_lot = OrderLots(); 
   if (OrderSelect(order_short, SELECT_BY_TICKET)) short_lot = OrderLots(); 
    
   if (long_entry) int order_close_s = OrderClose(order_short, short_lot, Ask, 100000); 
   if (short_entry) int order_close_l = OrderClose(order_long, long_lot, Bid, 1000000);  
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Position Size Calculator function                                |
//+------------------------------------------------------------------+
double PosSizeCalculator(double Risk_, double EntryPrice_, double ExitPrice_) {

   // General Variables
   double AccountSize = AccountInfoDouble(ACCOUNT_BALANCE);
   string AccountCurr = AccountCurrency();
   double SL_ = MathAbs(EntryPrice_ - ExitPrice_) / SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE);
   double SL = SL_ * SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE);
   
   // Symbol Information
   string Base_ = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE);
   string Profit_ = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT);
   
   //Conversion Rate
   bool accountSameAsCounterCurrency = AccountCurr == Profit_;
   
   string ConversitionSymb = accountSameAsCounterCurrency ? Symbol() :
                             AccountCurr + Profit_;
                             
   double ConversitionRate = iClose(ConversitionSymb, PERIOD_D1, 1);
   if (ConversitionRate == 0.0) {
      ConversitionRate = 1/iClose(Profit_ + AccountCurr, PERIOD_D1, 1);
   }
   if (ConversitionRate == 0.0) {
      Alert("Could not find Converstion Symbol!");
   }
   
   //Calculation
   double riskAmount = AccountSize * (Risk_/100) * 
                       (accountSameAsCounterCurrency ? 1.0 : ConversitionRate);
                       
   double units = riskAmount/SL;
   
   double contractsize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
   
   double positionSize = units/contractsize;

   return positionSize;
}

//+------------------------------------------------------------------+
//|Only send order when a candle just formed                         |
//+------------------------------------------------------------------+
bool IsNewCandle()
{
   static int BarsOnChart=0; //This could be equal to 0 or I can just declare the variable
   if (Bars == BarsOnChart) return false;
   BarsOnChart = Bars;
   return true;
}