use [rag]
go

SET NOCOUNT ON


DROP TABLE IF EXISTS dbo.vectors
CREATE TABLE dbo.vectors (
[id] int IDENTITY(1,1) PRIMARY KEY
,[string] nvarchar(max)
,[embedding] VECTOR(1024) NOT NULL
);

go


DROP TABLE IF EXISTS dbo.[history]
CREATE TABLE dbo.[history] (
    [id] int IDENTITY(1,1) PRIMARY KEY
    ,[session] int
    ,[type] varchar(10)
    ,[response] nvarchar(max)
    ,[rag] nvarchar(max)
)

DECLARE     @sql nvarchar(max)
            ,@count int = 1
            ,@i int = 1
            ,@loop_string nvarchar(max)
            ,@loop_result nvarchar(max)





/**
    Create some data

**/
DECLARE @source_data TABLE (
    [row] int IDENTITY(1,1)
    ,[string] nvarchar(max)
)


INSERT INTO @source_data ([string]) VALUES
 ('There are 6 pigeons in the sky')
,('Two pigeons have one foot')
,('There are 3 childerend playing in the field')
,('17 kittens are stuck in a tree')
,('1 kitten is blind')
,('It''s raining today')
,('The forecast is cloudy tomorrow, and sunny the day after')



SELECT @count = COUNT(*) FROM @source_data

WHILE (@i <= @count)
BEGIN


    SELECT  @loop_string = [string]
    FROM    @source_data
    WHERE   @i = [row]
    
    EXEC [usp_get_embedding] @string = @loop_string, @result = @loop_result OUTPUT


    PRINT @loop_result

    INSERT INTO [vectors] ([string],[embedding]) VALUES (
        @loop_string
        ,@loop_result
    )


    SET @i = @i + 1
END
-- createing a vector index changes the table to read only
--Data modification statement failed because table 'vectors' has a vector index on it.
CREATE VECTOR INDEX vec_idx ON [dbo].[vectors](embedding)
WITH (metric = 'cosine', type = 'diskann');




GO

CREATE OR ALTER PROCEDURE [usp_get_embedding] (
    @string nvarchar(max)
    ,@result  nvarchar(max) OUTPUT
)
AS
BEGIN

DECLARE @json NVARCHAR(MAX) = N'{
  "model": "mxbai-embed-large:latest",
  "prompt": "' + @string + N'"
}';


DECLARE @jsonResponse nvarchar(max)

-- Make the HTTP call to Ollama
EXEC sp_invoke_external_rest_endpoint  
    @url = N'https://ollama.digitaltalc.com/api/embeddings',
    @method = 'POST',
    @headers = N'{"Content-Type": "application/json"}',
    @payload = @json,
    @response = @jsonResponse OUTPUT;

--PRINT @jsonResponse

SELECT @result = JSON_QUERY(@jsonResponse, '$.result.embedding' );

--SELECT count(*) FROM OPENJSON (@jsonResponse, N'$.result.embedding')
  



END
GO