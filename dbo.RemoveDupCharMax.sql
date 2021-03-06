IF OBJECT_ID('dbo.RemoveDupCharMax') IS NOT NULL
DROP FUNCTION dbo.RemoveDupCharMax
GO
CREATE FUNCTION dbo.RemoveDupCharMax(@string varchar(max), @char char(1))
RETURNS TABLE WITH SCHEMABINDING AS RETURN
/****************************************************************************************
Purpose:
 Replaces two or more consecutive instances of any character (defined by @char) with one.

Compatibility: 
 SQL Server 2005+

Syntax:
 SELECT t.string, rd.newString
 FROM dbo.someTable t
 CROSS APPLY dbo.RemoveDupCharMax(@string) rd;

Parameters:
 @string - varchar(8000); the input string to clean duplicate spaces from

Return Types:
 inline Table Value Function returns:
 newString = varchar(max); 

Developer Notes:
 1. The code is based originated from the comments from this SQLServerCentral.com thread: 
    https://goo.gl/ZhYLJT but removes ANY character. After a lot of performance testing I
    concluded that there virtually no performance impact in modifying this code to accept
    a parameter the duplicate character to elimininate. 

 2. RemoveDupCharMaX is an Inline Table Valued Function (iTVF) that performs the same
    task as a scalar user defined function (UDF) except that it requires the APPLY table 
    operator. Note the usage examples below and See this article for more details: 
    http://www.sqlservercentral.com/articles/T-SQL/91724/
	
    As an iTVF, the function will be slightly more complicated to use than a scalar UDF 
    but will yeild much better performance. Also, unlike a scalar UDF, RemoveDupCharMaX
    doesn't prevent the query optimizer from generating a parallel execution plan. When
    testing against a scalar udf using identical logic, RemoveDupCharMaX was ~30% faster.
		
Examples:

--===== #1: Remove Duplicate Spaces
 DECLARE @string varchar(8000) = '1 space 2 space  whitespace    blue space     !'
 SELECT NewString FROM dbo.RemoveDupCharMax(@string, char(32));

--===== #2: Against a table
 DECLARE @sometable table (someText varchar(max));
 INSERT @sometable 
 SELECT 'AABBCC' UNION ALL SELECT 'Set-Based is great!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';

 SELECT t.someText, rd.newString
 FROM @sometable t
 CROSS APPLY dbo.RemoveDupCharMax(t.someText, '!') rd;
----------------------------------------------------------------------------------------
Revision History:
 Rev 00 - 20170907 - Initial Creation - Alan Burstein
****************************************************************************************/
SELECT NewString = 
 replace(replace(replace(replace(replace(replace(replace(
 @string COLLATE LATIN1_GENERAL_BIN,
  replicate(@char,33), @char), --33
  replicate(@char,17), @char), --17
  replicate(@char,9 ), @char), -- 9
  replicate(@char,5 ), @char), -- 5
  replicate(@char,3 ), @char), -- 3 
  replicate(@char,2 ), @char), -- 2
  replicate(@char,2 ), @char); -- 2
GO
