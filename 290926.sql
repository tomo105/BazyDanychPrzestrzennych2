CREATE PROCEDURE s290926(@YearsAgo as DECIMAL)
AS
BEGIN
    SELECT 
        fcr.CurrencyKey,
		fcr.AverageRate,
		fcr.Date,
		fcr.DateKey,
		fcr.EndOfDayRate,
		dc.CurrencyAlternateKey,
		dc.CurrencyName
    FROM 
        FactCurrencyRate as fcr 
		join  DimCurrency as dc on
		fcr.CurrencyKey = dc.CurrencyKey

	WHERE 
		(dc.CurrencyAlternateKey = 'EUR' OR dc.CurrencyAlternateKey = 'GBP' ) 
		AND DATEPART(DAY,fcr.Date) = DATEPART(DAY, Getdate()) 
		AND DATEPART(MONTH,fcr.Date) = DATEPART(MONTH, Getdate()) 
		AND DATEPART(YEAR,fcr.Date) = DATEPART(YEAR, Getdate()) - @YearsAgo
		;
 		
END;


