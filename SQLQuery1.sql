--8. Napisz kwerend� SQL, kt�ra zwr�ci t� sam� analiz� co zrobiony wcze�niej pakiet SSIS.
--a) poka� jedynie dni (wraz z liczb� zam�wie�) w kt�rych by�o mniej ni� 100 zam�wie�,
--b) dla ka�dego dnia wy�wietl 3 produkty, kt�rych cena jednostkowa (UnitPrice) by�a najwi�ksza

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
	
