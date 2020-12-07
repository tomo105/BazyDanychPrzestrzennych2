--2b
/*
DROP TABLE IF EXISTS AdventureWorksDW2019.dbo.stg_dimemp  
DROP TABLE IF EXISTS AdventureWorksDW2019.dbo.scd_dimemp  
--2a

SELECT dm.FirstName,dm.EmployeeKey, dm.LastName,dm.Title	
INTO stg_dimemp
FROM DimEmployee as dm
WHERE dm.EmployeeKey BETWEEN 270 AND 275;
*/
--2c
/*
DROP TABLE IF EXISTS AdventureWorksDW2019.dbo.scd_dimemp  
CREATE TABLE AdventureWorksDW2019.dbo.scd_dimemp 
(EmployeeKey INT, 
FirstName NVARCHAR(50),
LastName NVARCHAR(50),
Title NVARCHAR(50),
StartDate DATETIME,
EndDate DATETIME);
*/
 /*
update stg_dimemp
set LastName = 'Nowak'
where EmployeeKey = 270;
update stg_dimemp
set TITLE = 'Senior Design Engineer'
where EmployeeKey = 274;
*/
/*
update stg_dimemp
set FIRSTNAME = 'Ryszard'
where EmployeeKey = 275
*/
/*
update Stg_DimEmp
set FIRSTNAME = 'Ryszard'
where EmployeeKey = 275;
*/
SELECT * FROM stg_dimemp;
SELECT * FROM scd_dimemp;
