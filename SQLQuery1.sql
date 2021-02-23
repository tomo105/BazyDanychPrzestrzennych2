--8. Napisz kwerendê SQL, która zwróci tê sam¹ analizê co zrobiony wczeœniej pakiet SSIS.
--a) poka¿ jedynie dni (wraz z liczb¹ zamówieñ) w których by³o mniej ni¿ 100 zamówieñ,
--b) dla ka¿dego dnia wyœwietl 3 produkty, których cena jednostkowa (UnitPrice) by³a najwiêksza

-- takie samo jak w poprzed
SELECT COUNT(OrderDateKey) as cnt , OrderDateKey FROM FactInternetSales GROUP BY OrderDateKey ORDER BY cnt DESC ;
-- a
SELECT COUNT(OrderDateKey) as cnt , OrderDateKey FROM FactInternetSales  GROUP BY OrderDateKey  HAVING  COUNT(OrderDateKey) < 100 ORDER BY cnt  DESC ;
-- b
SELECT * FROM (
	SELECT
		OrderDateKey,
		UnitPrice,
		ProductKey,

	ROW_NUMBER() OVER ( 

		PARTITION BY OrderDateKey 
			ORDER BY UnitPrice DESC ) nr_produktu

		FROM FactInternetSales) res WHERE nr_produktu <=3  ;
	
