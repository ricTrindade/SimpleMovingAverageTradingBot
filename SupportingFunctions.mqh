#property copyright "Ricardo Trindade"
#property link      "none"
#property strict
//+------------------------------------------------------------------+
//| Pip Value Calculation                                            |
//+------------------------------------------------------------------+
double GetPipValueMyWay()
  {
   string Currency_Profit = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT);
   double PipValue = Currency_Profit == "JPY" ? 0.01 : 0.0001;
   return PipValue;
  }

//+------------------------------------------------------------------+
//| Pip Multiplier                                                   |
//+------------------------------------------------------------------+
int Pip_Multiplier()
{
   string Currency_Profit = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT);
   return Currency_Profit == "JPY" ? 100 : 10000; // If I comment out the two libnes below, this line need to be deleted or commented out 
   
   //double Pip_Multiplier_ = Currency_Profit == "JPY" ? 100 : 10000;
   //return Pip_Multiplier_;
}

//+------------------------------------------------------------------+
//|StopLoss and TakeProfit MyWay                                     |
//+------------------------------------------------------------------+
// StopLoss
double CalculateStopLoss_Price(bool Long_or_Short, double MaxLossPips)
  {
   if(Long_or_Short == true)  // If I am long
     {
      double StopLossPrices = Ask - (MaxLossPips * GetPipValueMyWay());
      return StopLossPrices;
     }
   else // When Long_or_Short == False, Iam going short
     {
      double StopLossPrices = Bid + (MaxLossPips * GetPipValueMyWay());
      return StopLossPrices;
     }
  }

// TakeProfit
double CalculateTakeProfit_Price(bool Long_or_Short, double MaxGainPips)
  {
   if(Long_or_Short == true)  // If I am long
     {
      double TakeProfitPrices = Ask + (MaxGainPips* GetPipValueMyWay());
      return TakeProfitPrices;
     }
   else // When Long_or_Short == False, Iam going short
     {
      double TakeProfitPrices = Bid - (MaxGainPips* GetPipValueMyWay());
      return TakeProfitPrices;
     }
  }
  
//+------------------------------------------------------------------+
//|StopLoss and TakeProfit The Instructor Way                        |
//+------------------------------------------------------------------+
// StopLoss
double CalculateStopLossTheInstructorWay(bool Long_or_Short, double EntryPrice, double MaxLossPips)
  {
   if(Long_or_Short == true)  // If I am long
     {
      double StopLossPrices = EntryPrice - MaxLossPips * GetPipValueMyWay();
      return StopLossPrices;
     }
   else // When Long_or_Short == False, Iam going short
     {
      double StopLossPrices = EntryPrice + MaxLossPips * GetPipValueMyWay();
      return StopLossPrices;
     }
  }

// TakeProfit
double CalculateTakeProfitTheInstructorWay(bool Long_or_Short, double EntryPrice, double MaxGainPips)
  {
   if(Long_or_Short == true)  // If I am long
     {
      double TakeProfitPrices = EntryPrice + MaxGainPips* GetPipValueMyWay();
      return TakeProfitPrices;
     }
   else // When Long_or_Short == False, Iam going short
     {
      double TakeProfitPrices = EntryPrice - MaxGainPips* GetPipValueMyWay();
      return TakeProfitPrices;
     }
  }
  
//+------------------------------------------------------------------+
//|Am I Allow to Trade Function                                      | 
//+------------------------------------------------------------------+
//I still need to know some things, is the makert colosed or not,
//Is it just the Auto Trading not being on ?

bool IsTradingAllowed()
{
   if (!IsTradeAllowed())
   {
      Alert("Expert Advisor is NOT ALLOWED to trade. Check AutoTrading.");
      return false;
   }
   
   if (!IsTradeAllowed(Symbol(), TimeCurrent()))
   {
      Alert("Trading NOT Allowed for Current Symbol and Time.");
      return false;   
   }
   
   Alert("Trading is Allowed.");
   return true;
} 
 
//+------------------------------------------------------------------+
//|//What is the Lot Size of my Account? (With Alert)                | 
//+------------------------------------------------------------------+

void WhatIsTheAccountLotSize ()
{
   double idk = SymbolInfoDouble(NULL, SYMBOL_TRADE_CONTRACT_SIZE);
   
   if (idk == 100000)
   {Alert("Standard Lot");}
   else if (idk == 10000)
   {Alert("Mini Lot");}
   else if (idk == 1000)
   {Alert("Micro Lot");}
}

//+------------------------------------------------------------------+
//| Has the EA Open a position?                                      |
//+------------------------------------------------------------------+
/*In this function I feed the magic number and then check if an order with this number exits or not 
I do not really understand this, I have to check loops, order select*/
bool checkIfOpenOrdersByMagicNB (int magicNumber)
{
   //How to check how many orders this script has sent ( I have in my notes that I need to study the for and while loops more)
   for (int i = 0; i < OrdersTotal(); i++)// This statement is saying that for as long I have an open order the Loop is going to run 
   {
      if (OrderSelect(i, SELECT_BY_POS))//This function selects an order for further processing.Still need to understand exactly how it works 
      {
         if (OrderMagicNumber() == magicNumber) 
         {/*Alert("The EA has already sent an order");*/
         return true;}
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Position Size Calculator (from the instructor)                   |
//+------------------------------------------------------------------+
// This function seems to be more effective and it works on this new broker FXCM

double Lot_Size(double maxRisk, double maxLossInPips)
{
   double maxRiskPrc = maxRisk/100;
   
   double accEquity = AccountEquity();
   
   double lotSize = MarketInfo(NULL,MODE_LOTSIZE);
   
   double tickValue = MarketInfo(NULL,MODE_TICKVALUE);
   if(Digits <= 3)
   {tickValue = tickValue /100;}
   
   double maxLossDollar = accEquity * maxRiskPrc;
   
   double maxLossInQuoteCurr = maxLossDollar / tickValue;
   
   double optimalLotSize = NormalizeDouble(maxLossInQuoteCurr /(maxLossInPips * GetPipValueMyWay())/lotSize,2);
   
   return optimalLotSize;
}

//+------------------------------------------------------------------+
//| Position Size Calculator_V2 (My way)                             |
//+------------------------------------------------------------------+
double Auto_Contract_Size(double maxRiskPrc, double EntryPrice, double ExitPrice)
{
   //Size of the Account 
   double AccEquity = AccountEquity();
   
   //Account Currency 
   string AccDepositCurrency =  AccountInfoString(ACCOUNT_CURRENCY);
   
   //Stop Loss Size in Points 
   double stopLossSize = MathAbs(EntryPrice - ExitPrice);
   
   // Check if our account currency is the same as the base or quote currency (for risk $ conversion purposes)                                                |
   bool accountSameAsCounterCurrency = AccDepositCurrency == SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT);
   bool accountSameAsBaseCurrency = AccDepositCurrency == SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE); 
   
   // Check if our account currency is neither the base or quote currency (for risk $ conversion purposes)
   bool accountNeitherCurrency = !accountSameAsCounterCurrency && !accountSameAsBaseCurrency;
   
   // Get currency conversion rates if applicable
   string conversionCurrencyPair = accountSameAsCounterCurrency ? Symbol() : AccDepositCurrency + SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT);
   
   double conversionCurrencyRate = iClose(conversionCurrencyPair, PERIOD_D1, 0);
   
   if (conversionCurrencyPair == "USDEUR")
   {conversionCurrencyRate = 1 / (iClose("EURUSD", PERIOD_D1, 0));}
   
   else if (conversionCurrencyPair == "USDGBP")
   {conversionCurrencyRate = 1 / (iClose("GBPUSD", PERIOD_D1, 0));}
   
   else if (conversionCurrencyPair == "USDAUD")
   {conversionCurrencyRate = 1 / (iClose("AUDUSD", PERIOD_D1, 0));}
   
   else if (conversionCurrencyPair == "USDNZD") 
   {conversionCurrencyRate = 1 / (iClose("NZDUSD", PERIOD_M1, 0));}

   double riskAmount = (AccEquity * (maxRiskPrc/100)) * (accountSameAsBaseCurrency || accountNeitherCurrency ? conversionCurrencyRate : 1);
   double positionSize = (riskAmount / stopLossSize);
   double positionSizeLots_ = positionSize / 100000;
   double positionSizeLots = NormalizeDouble(positionSizeLots_,2);

   return positionSizeLots;
}  // By the way, I can create functions with different names if they have different arguments, Version 1 version 2 ect 

//+------------------------------------------------------------------+
//|Ramdom PositionSize found on Google                               |
//+------------------------------------------------------------------+
double CalculateLotSize(double MaxRiskPerTrade, double SL)// Calculate the position size.
{
   double LotSize = 0;
   // We get the value of a tick.
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   // If the digits are 3 or 5, we normalize multiplying by 10.
   if ((Digits == 3) || (Digits == 5)){
      nTickValue = nTickValue * 10;}
      
   // We apply the formula to calculate the position size and assign the value to the variable.
   LotSize = (AccountEquity() * MaxRiskPerTrade / 100) / (SL * nTickValue);
   LotSize = MathRound(LotSize / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
   return LotSize;
}

//+------------------------------------------------------------------+
//|Ramdom PositionSize found on Google V2 (NZD pairs imporved)       |
//+------------------------------------------------------------------+
double imp_LotSize(double MaxRiskPerTrade, double SL)
{

   string Currency_Profit = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE);
   if (Currency_Profit != "NZD")
   {
      double LotSize = 0;
      // We get the value of a tick.
      double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
      // If the digits are 3 or 5, we normalize multiplying by 10.
      if ((Digits == 3) || (Digits == 5)){
         nTickValue = nTickValue * 10;}
         
      // We apply the formula to calculate the position size and assign the value to the variable.
      LotSize = (AccountEquity() * MaxRiskPerTrade / 100) / (SL * nTickValue);
      LotSize = MathRound(LotSize / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
      return LotSize;
   }
   else
   {  
      double stopLossSizePoints = SL * 10;
      double conversionCurrencyRate = 1/(iClose("NZDUSD", PERIOD_M1, 0));
      double riskAmount = (AccountEquity() * (MaxRiskPerTrade/100)) * conversionCurrencyRate;
      double riskPerPoint = stopLossSizePoints;
      double positionSize = (riskAmount/riskPerPoint) / 0.00001;
      double positionSizeLots_ = positionSize/100000;
      double positionSizeLots = NormalizeDouble(positionSizeLots_,2);
   
      return positionSizeLots;
   }   
   return 0.0;
}

//+------------------------------------------------------------------+
//|Ramdom PositionSize given to me on Discord by @Kaza007            |
//+------------------------------------------------------------------+
double autoLots(double RiskPercent, double RiskStopLoss)  
{
   double pipValue = MarketInfo(Symbol(),MODE_TICKVALUE); if (Digits==3 || Digits==5) pipValue *= 10;
   double step     = MarketInfo(Symbol(),MODE_LOTSTEP);
   int norm     = 0;
   if (step==1)    norm = 0;
   if (step==0.1)  norm = 1;
   if (step==0.01) norm = 2;
   
   double autoLots = (AccountBalance()*(RiskPercent/100.0))/(RiskStopLoss*pipValue);
   
   if(autoLots>MarketInfo(Symbol(),MODE_MAXLOT)) {autoLots=MarketInfo(Symbol(),MODE_MAXLOT);}
   if(autoLots<MarketInfo(Symbol(),MODE_MINLOT)) {autoLots=MarketInfo(Symbol(),MODE_MINLOT);}
   autoLots   = NormalizeDouble(autoLots,norm);

   return(autoLots);
}

//+------------------------------------------------------------------+
//|Error Handling Function, it describes the error when sending order|
//+------------------------------------------------------------------+
string ErrorHandling(int errorID, bool isLong, double Lots, double SLprice, double TPprice)
{  
   double TPpips = isLong ? TPprice - Ask : Bid - TPprice;
   double SLpips = isLong ? Ask - SLprice : SLprice - Bid;
   
   string Currency_Profit = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT);
   double min_Pip_distance = Currency_Profit == "JPY" ? 0.05 : 0.0005;
   
   if ((errorID == 130) && (isLong) && (SLprice > Ask)) return "SL Higher than Entry on a Long Trade";
   if ((errorID == 130) && (!isLong) && (SLprice < Bid))return "SL Lower than Entry on a Short Trade";
   if ((errorID == 130) && (isLong) && (TPprice < Ask)) return "TP Lower than Entry on a Long Trade";
   if ((errorID == 130) && (!isLong) && (TPprice > Bid))return "TP Higher than Entry on a Short Trade"; 
   if ((errorID == 130) && (TPpips < min_Pip_distance))  return "Take Profit too Tight";
   if ((errorID == 130) && (SLpips < min_Pip_distance))  return "Stop Loss too Tight";
   if (errorID == 131)  return "Invalid trade volume"; 
   if (errorID == 134)  return "Not Enough Funds (Position too large for account size)";  
   if (errorID == 138)  return "Requote (what ever that means)";  
   if (errorID == 4051) return "Invalid function parameter value";
   if (errorID == 4051 && Lots >= 0) return "Invalid Lot Size Value";
   
   return "Unknown Error: " + IntegerToString(errorID, 4);  
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

//+------------------------------------------------------------------+
//|Does this Pair currently have an open Order?                      |
//+------------------------------------------------------------------+
int OpenOrdersThisPair (string pair)
{
   int total = 0;
   for (int i=OrdersTotal()-1; i>=0; i--)
   {
      bool g = OrderSelect(i, SELECT_BY_POS, MODE_TRADES); //I can eliminate the "bool g", but there would be a warning 
      if (OrderSymbol() == pair) total ++;
   }
   return total;
}

//+------------------------------------------------------------------+
//| Break Even Function                                              |
//+------------------------------------------------------------------+
void MoveToBreakeven(int MagicNumber_BUY, int MagicNumber_SELL)
{
   //Adjust Buy Order
   int ml;
   for(int b=OrdersTotal()-1; b >= 0; b--)
   {
      if(OrderSelect(b, SELECT_BY_POS, MODE_TRADES)) 
         if(OrderMagicNumber() == MagicNumber_BUY)
            if(OrderSymbol() == Symbol())
               if(OrderType() == OP_BUY)
                  if(Bid - OrderOpenPrice() > OrderOpenPrice() - OrderStopLoss())
                  {
                     string sll = OrderComment(); 
                     double d_sll = StringToDouble(sll); 
                     double risk_l = OrderOpenPrice() - d_sll; 
                     double ts_p_l = risk_l * 2; 
                     double tsl_trigger = OrderOpenPrice() + ts_p_l;
                     
                     int barsince_l_entry = Bars(Symbol(), PERIOD_CURRENT, OrderOpenTime(), TimeCurrent());
                     int highest_shift = iHighest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_l_entry, 1);
                     double highest_close = iHigh(Symbol(), PERIOD_CURRENT, highest_shift);
                     
                     if(NormalizeDouble(d_sll, Digits) == OrderStopLoss())
                        {ml = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(),0,clrNONE);}
                  }                   
   }  
   //Adjust Sell Order
   int ms;
   for (int s=OrdersTotal()-1; s >= 0; s--) 
   {
      if(OrderSelect(s, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == MagicNumber_SELL)
            if(OrderSymbol() == Symbol())
               if(OrderType() == OP_SELL)
                  if(OrderOpenPrice() - Ask > OrderStopLoss() - OrderOpenPrice())
                  {
                     string sls = OrderComment();
                     double d_sls = StringToDouble(sls); 
                     double risk_s = d_sls - OrderOpenPrice(); 
                     double ts_p_s = risk_s * 2; 
                     double tss_trigger = OrderOpenPrice() - ts_p_s; 
                     
                     int barsince_s_entry = Bars(Symbol(), PERIOD_CURRENT, OrderOpenTime(), TimeCurrent());
                     int lowest_shift = iLowest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_s_entry, 1);
                     double lowest_close = iClose(Symbol(), PERIOD_CURRENT, lowest_shift);
                     
                     if(NormalizeDouble(d_sls, Digits) == OrderStopLoss()) 
                      {ms = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(),0,clrNONE);}
                  }                    
   }                  
}




//+------------------------------------------------------------------+
//| Break Even Function and take half of the trade off               |
//+------------------------------------------------------------------+
void MoveToBreakeven_half_trade_off(int MagicNumber_BUY, int MagicNumber_SELL)
{
   //Adjust Buy Order
   int ml;
   for(int b=OrdersTotal()-1; b >= 0; b--)
   {
      if(OrderSelect(b, SELECT_BY_POS, MODE_TRADES)) 
         if(OrderMagicNumber() == MagicNumber_BUY)
            if(OrderSymbol() == Symbol())
               if(OrderType() == OP_BUY)
                  if(Bid - OrderOpenPrice() > OrderOpenPrice() - OrderStopLoss())
                  {
                     string sll = OrderComment(); 
                     double d_sll = StringToDouble(sll); 
                     double risk_l = OrderOpenPrice() - d_sll; 
                     double ts_p_l = risk_l * 2; 
                     double tsl_trigger = OrderOpenPrice() + ts_p_l;
                     
                     int barsince_l_entry = Bars(Symbol(), PERIOD_CURRENT, OrderOpenTime(), TimeCurrent());
                     int highest_shift = iHighest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_l_entry, 1);
                     double highest_close = iHigh(Symbol(), PERIOD_CURRENT, highest_shift);
                     
                     if(NormalizeDouble(d_sll, Digits) == OrderStopLoss())
                     {
                        ml = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(),0,clrNONE);
                        int close_l_half = OrderClose(OrderTicket(), OrderLots()/2, Bid, 1000000);
                     }
                  }                   
   }  
   //Adjust Sell Order
   int ms;
   for (int s=OrdersTotal()-1; s >= 0; s--) 
   {
      if(OrderSelect(s, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == MagicNumber_SELL)
            if(OrderSymbol() == Symbol())
               if(OrderType() == OP_SELL)
                  if(OrderOpenPrice() - Ask > OrderStopLoss() - OrderOpenPrice())
                  {
                     string sls = OrderComment();
                     double d_sls = StringToDouble(sls); 
                     double risk_s = d_sls - OrderOpenPrice(); 
                     double ts_p_s = risk_s * 2; 
                     double tss_trigger = OrderOpenPrice() - ts_p_s; 
                     
                     int barsince_s_entry = Bars(Symbol(), PERIOD_CURRENT, OrderOpenTime(), TimeCurrent());
                     int lowest_shift = iLowest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_s_entry, 1);
                     double lowest_close = iClose(Symbol(), PERIOD_CURRENT, lowest_shift);
                     
                     if(NormalizeDouble(d_sls, Digits) == OrderStopLoss()) 
                     {
                        ms = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(),0,clrNONE);
                        int close_s_half = OrderClose(OrderTicket(), OrderLots()/2, Ask, 100000);
                     }
                  }                    
   }                  
}


//+------------------------------------------------------------------+
//| Trailling Stop Function_V2                                       |
//+------------------------------------------------------------------+
void AdjustTrail_V2(int MagicNumber_BUY, int MagicNumber_SELL, double LongATRstop1, double ShortATRstop1)
{
   //Adjust Buy Order
   for(int b=OrdersTotal()-1; b>=0; b--)
   {
      double tsl_trigger = 0;
      double risk_l = 0;
      
      if(OrderSelect(b, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == MagicNumber_BUY)
            if(OrderSymbol()==Symbol())
               if(OrderType()==OP_BUY)
               {
                  double sll = LongATRstop1; 
                  double d_sll = NormalizeDouble(sll, Digits); 
                  risk_l = OrderOpenPrice() - d_sll; 
                  double ts_p_l = risk_l * 2; 
                  tsl_trigger = OrderOpenPrice() + ts_p_l; 
                  
                  if(iClose(Symbol(), 0, 1) >= tsl_trigger)
                  {
                        int barsince_l_entry = Bars(Symbol(), PERIOD_CURRENT, OrderOpenTime(), TimeCurrent());
                        int highest_shift = iHighest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_l_entry, 1);
                        double highest_close = iClose(Symbol(), PERIOD_CURRENT, highest_shift);
                        
                        int highest_shift_2 = iHighest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_l_entry, 2);
                        double highest_close_2 = iClose(Symbol(), PERIOD_CURRENT, highest_shift_2);
                        
                        if(highest_close != highest_close_2)
                           int mtl = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - risk_l, OrderTakeProfit(),0,clrNONE);
                  }         
               }
    }
   
   //Adjust Sell Order
   for(int s=OrdersTotal()-1; s>=0; s--)
   {
      double tss_trigger = 0;
      double risk_s = 0;
      
      if(OrderSelect(s, SELECT_BY_POS, MODE_TRADES))
         if(OrderMagicNumber() == MagicNumber_SELL)
            if(OrderSymbol()==Symbol())
               if(OrderType()==OP_SELL)
               {
                  double sls = ShortATRstop1;
                  double d_sls = NormalizeDouble(sls, Digits); 
                  risk_s = d_sls - OrderOpenPrice(); 
                  double ts_p_s = risk_s * 2; 
                  tss_trigger = OrderOpenPrice() - ts_p_s; 
                  
                  if(iClose(Symbol(), 0, 1) <= tss_trigger)
                  {
                        int barsince_s_entry = Bars(Symbol(), PERIOD_CURRENT, OrderOpenTime(), TimeCurrent());
                        int lowest_shift = iLowest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_s_entry, 1);
                        double lowest_close = iClose(Symbol(), PERIOD_CURRENT, lowest_shift);
                        
                        int lowest_shift_2 = iLowest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_s_entry, 2);
                        double lowest_close_2 = iClose(Symbol(), PERIOD_CURRENT, lowest_shift_2);
                        
                        if(lowest_close != lowest_close_2)
                           int mtl = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + risk_s, OrderTakeProfit(),0,clrNONE);
                  }                    
               }
    }
}

//+------------------------------------------------------------------+
//| Trailling Stop Function                                          |
//+------------------------------------------------------------------+
void AdjustTrail(int MagicNumber_BUY, int MagicNumber_SELL)
{
   //Adjust Buy Order
   for(int b=OrdersTotal()-1; b>=0; b--)
   {
      double tsl_trigger = 0;
      double risk_l = 0;
      
      if(OrderSelect(b, SELECT_BY_POS, MODE_TRADES))
         //if(OrderMagicNumber() == MagicNumber_BUY)
            if(OrderSymbol()==Symbol())
               if(OrderType()==OP_BUY)
               {
                  string sll = OrderComment(); 
                  double d_sll = NormalizeDouble(StringToDouble(sll), Digits); 
                  risk_l = OrderOpenPrice() - d_sll; 
                  double ts_p_l = risk_l * 2; 
                  tsl_trigger = OrderOpenPrice() + ts_p_l; 
                  
                  if(iClose(Symbol(), 0, 1) >= tsl_trigger)
                  {
                        int barsince_l_entry = Bars(Symbol(), PERIOD_CURRENT, OrderOpenTime(), TimeCurrent());
                        int highest_shift = iHighest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_l_entry, 1);
                        double highest_close = iClose(Symbol(), PERIOD_CURRENT, highest_shift);
                        
                        int highest_shift_2 = iHighest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_l_entry, 2);
                        double highest_close_2 = iClose(Symbol(), PERIOD_CURRENT, highest_shift_2);
                        
                        if(highest_close != highest_close_2)
                           int mtl = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - risk_l, OrderTakeProfit(),0,clrNONE);
                  }         
               }
    }
   
   //Adjust Sell Order
   for(int s=OrdersTotal()-1; s>=0; s--)
   {
      double tss_trigger = 0;
      double risk_s = 0;
      
      if(OrderSelect(s, SELECT_BY_POS, MODE_TRADES))
         //if(OrderMagicNumber() == MagicNumber_SELL)
            if(OrderSymbol()==Symbol())
               if(OrderType()==OP_SELL)
               {
                  string sls = OrderComment();
                  double d_sls = NormalizeDouble(StringToDouble(sls), Digits); 
                  risk_s = d_sls - OrderOpenPrice(); 
                  double ts_p_s = risk_s * 2; 
                  tss_trigger = OrderOpenPrice() - ts_p_s; 
                  
                  if(iClose(Symbol(), 0, 1) <= tss_trigger)
                  {
                        int barsince_s_entry = Bars(Symbol(), PERIOD_CURRENT, OrderOpenTime(), TimeCurrent());
                        int lowest_shift = iLowest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_s_entry, 1);
                        double lowest_close = iClose(Symbol(), PERIOD_CURRENT, lowest_shift);
                        
                        int lowest_shift_2 = iLowest(Symbol(), PERIOD_CURRENT, MODE_CLOSE, barsince_s_entry, 2);
                        double lowest_close_2 = iClose(Symbol(), PERIOD_CURRENT, lowest_shift_2);
                        
                        if(lowest_close != lowest_close_2)
                           int mtl = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + risk_s, OrderTakeProfit(),0,clrNONE);
                  }                    
               }
    }
}

//+------------------------------------------------------------------+
//| #n of bars since C1 signal                                       |
//+------------------------------------------------------------------+
int barsince_c1_signal(int Index, bool isLong, int C1_Type, string C1_NAME, 
double inp1, double inp2, double inp3, double inp4, double inp5, double inp6, double inp7)

{
   int Index_0 = 0;
   int Index_1 = 0; 
   
   //Loop for when I want to get bar since last C1 signal (int Index == 0)   
   for (int i=0; i < Bars; i++)
   {
      bool long_c1_;
      bool short_c1_;
   
      double up1_ = iCustom(NULL, PERIOD_CURRENT, C1_NAME, inp1, inp2, inp3, inp4, inp5, inp6, inp7, 0, i+1);
      double up2_ = iCustom(NULL, PERIOD_CURRENT, C1_NAME, inp1, inp2, inp3, inp4, inp5, inp6, inp7, 0, i+2);
      
      double down1_ = iCustom(NULL, PERIOD_CURRENT, C1_NAME, inp1, inp2, inp3, inp4, inp5, inp6, inp7, 1, i+1);
      double down2_ = iCustom(NULL, PERIOD_CURRENT, C1_NAME, inp1, inp2, inp3, inp4, inp5, inp6, inp7, 1, i+2);
      
      if (C1_Type == 0)
      {
         long_c1_   = (up1_ > 0) && (up2_ <= 0);
         short_c1_  = (up1_ < 0) && (up2_ >= 0);
      }
      else if (C1_Type == 1)
      {
         long_c1_   = (up1_ > down1_) && (up2_ <= down2_);
         short_c1_  = (up1_ < down1_) && (up2_ >= down2_);
      }
      
      if (isLong) // Bar since long entry
      {
         if (long_c1_)
         {
            Index_0 = i;
            break;
         }
      }   
      
      if (isLong == false)// Bar since short entry
      {   
         if (short_c1_)
         {
            Index_0 = i;
            break;
         }
      }   
   }
   
   //Loop for when I want to get bar since C1 signal previous to the last one (int Index == 1)       
   for (int i = Index_0 + 1; i < Bars; i++)
   {
      bool long_c1_;
      bool short_c1_;
   
      double up1_ = iCustom(NULL, PERIOD_CURRENT, C1_NAME, inp1, inp2, inp3, inp4, inp5, inp6, inp7, 0, i+1);
      double up2_ = iCustom(NULL, PERIOD_CURRENT, C1_NAME, inp1, inp2, inp3, inp4, inp5, inp6, inp7, 0, i+2);
      
      double down1_ = iCustom(NULL, PERIOD_CURRENT, C1_NAME, inp1, inp2, inp3, inp4, inp5, inp6, inp7, 1, i+1);
      double down2_ = iCustom(NULL, PERIOD_CURRENT, C1_NAME, inp1, inp2, inp3, inp4, inp5, inp6, inp7, 1, i+2);
      
      if (C1_Type == 0)
      {
         long_c1_   = (up1_ > 0) && (up2_ <= 0);
         short_c1_  = (up1_ < 0) && (up2_ >= 0);
      }
      else if (C1_Type == 1)
      {
         long_c1_   = (up1_ > down1_) && (up2_ <= down2_);
         short_c1_  = (up1_ < down1_) && (up2_ >= down2_);
      }
      
      if (isLong) // Bar since long entry
      {
         if (long_c1_)
         {
            Index_1 = i;
            break;
         }
      }   
        
      if (isLong == false)// Bar since short entry
      {  
         if (short_c1_)
         {
            Index_1 = i;
            break;
         }
      }   
   }
   return Index == 0 ? Index_0 : Index_1;     
}

//+------------------------------------------------------------------+
//| Newest Position Size Calculator                                  |
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