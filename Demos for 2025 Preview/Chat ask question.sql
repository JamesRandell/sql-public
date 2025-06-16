DBCC TRACEON(466, 474, 13981, -1)

USE [rag]
GO



SET NOCOUNT ON

DECLARE @question nvarchar(max)
DECLARE @question_embedding vector(1024)
DECLARE @rag_string nvarchar(max)

SET @question = 'is it raining today??'

EXEC [usp_get_embedding] @string = @question, @result = @question_embedding OUTPUT

SELECT 
   @rag_string = STRING_AGG([string], '.')
   --@rag_string = [string]
FROM
    VECTOR_SEARCH(
        TABLE = [dbo].[vectors] as t, 
        COLUMN = [embedding], 
        SIMILAR_TO = @question_embedding, 
        METRIC = 'cosine', 
        TOP_N = 3
    ) AS s
WHERE       s.distance > 0.3
--GROUP BY    s.[distance]




SET @question = @question

DECLARE     @response nvarchar(max)
print @question
EXEC [usp_chat] @string = @question, @context = @rag_string, @result = @response OUTPUT

print ''
PRINT @response
