//+------------------------------------------------------------------+
//|                                       Simple MA crossover EA.mq4 |
//|                                                 Ricardo Trindade |
//|                                        https://www.idontknow.com |
//+------------------------------------------------------------------+
#property copyright "Ricardo Trindade"
#property link      "https://www.idontknow.com"
#property version   "1.00"
#property strict
#include "SupportingFunctions.mqh" 

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
   bool long_entry = (ma_fast_1 > ma_slow_1) && (ma_fast_2 <= ma_slow_2) && checkIfOpenOrdersByMagicNB(1) == false;
   bool short_entry = (ma_fast_1 < ma_slow_1) && (ma_fast_2 >= ma_slow_2) && checkIfOpenOrdersByMagicNB(2) == false;
   
   //Entry 
   if (IsNewCandle()) {
   
      if (long_entry) {  
      
         //ATR
         double atr = iATR(NULL, 0, atrPeriod, 0);
         double LongATRstop = Ask - (atr * atrStopMultiplier);
         double LongATRprofit = UseTP ? Ask + (atr * atrStopMultiplier) : 0;
      
         //Pips for Lot Size Calculation
         pip_l = (Ask - LongATRstop) * Pip_Multiplier();
         double lot_l = imp_LotSize(riskPerTrade, pip_l);
         //double lot_l = Auto_Contract_Size(riskPerTrade, Ask, LongATRstop);
      
         //Comment StopLoss to trade
         string sllc = DoubleToString(LongATRstop); //Store Original SL in string form inside a comment 
         order_long = OrderSend(NULL, OP_BUY, lot_l, Ask, 10, LongATRstop, LongATRprofit, sllc, 1);
         if (order_long < 0) {
            Alert(Symbol(), ": Order Rejected");
            Alert(ErrorHandling(GetLastError(), true, lot_l, LongATRstop, 0));
         }
      } 
      
      if (short_entry) {
      
         //ATR
         double atr = iATR(NULL, 0, atrPeriod, 0);
         double ShortATRstop = Bid + (atr * atrStopMultiplier);
         double ShortATRprofit = UseTP ? Bid - (atr * atrStopMultiplier) : 0;
      
         //Pips for Lot Size Calculation
         pip_s = (ShortATRstop - Bid) * Pip_Multiplier();
         double lot_s = imp_LotSize(riskPerTrade, pip_s);
         //double lot_s = Auto_Contract_Size(riskPerTrade, Bid, ShortATRstop);
         
         //Comment StopLoss to trade
         string slsc = DoubleToString(ShortATRstop);
         order_short = OrderSend(NULL, OP_SELL, lot_s, Bid, 10, ShortATRstop, ShortATRprofit, slsc, 2);
         if (order_short < 0) {
            Alert(Symbol(), ": Order Rejected");
            Alert(ErrorHandling(GetLastError(), false, lot_s, ShortATRstop, 0));
         }
      }
      
      AdjustTrail(1,2); //Trailling Stop, I have to cal it here because the IsNewCandle can only be called once per file
   }
   
   if (OrderSelect(order_long, SELECT_BY_TICKET)) long_lot = OrderLots(); 
   if (OrderSelect(order_short, SELECT_BY_TICKET)) short_lot = OrderLots(); 
    
   if (long_entry && checkIfOpenOrdersByMagicNB(2)) int order_close_s = OrderClose(order_short, short_lot, Ask, 100000); 
   if (short_entry && checkIfOpenOrdersByMagicNB(1)) int order_close_l = OrderClose(order_long, long_lot, Bid, 1000000);  
   
   MoveToBreakeven(1,2);
}
//+------------------------------------------------------------------+
