CREATE OR ALTER PROCEDURE [usp_chat] (
    @string nvarchar(max)

    ,@context nvarchar(max) = NULL
    ,@result  nvarchar(max) OUTPUT
)
AS
BEGIN



SET @context = COALESCE(' ' + @context, '')

DECLARE @json nvarchar(max)
DECLARE @jsonResponse nvarchar(max)
DECLARE @history nvarchar(max)


SELECT  @history = STRING_AGG(',{"role":"' + IIF([type] = 'user','user','assistant') 
    + '","content":"' + [response] + '"}', '')
FROM       [dbo].[history]
WHERE       [session] = @@SPID


--llama3.2:latest
SET @json = N'{
  "model": "gemma3:1b",
  "messages": [
    {
      "role": "system",
      "content": "Given a chat history and the latest user question which might reference context in the chat history, formulate a standalone question which can be understood without the chat history. Do NOT answer the question, just reformulate it if needed and otherwise return it as is."
    }
    ' + @history + N'
  ],
  "stream": false
}';






IF (@history IS NOT NULL and 1=2)
BEGIN
-- Make the HTTP call to Ollama
EXEC sp_invoke_external_rest_endpoint  
    @url = N'https://ollama.digitaltalc.com/api/chat',
    @method = 'POST',
    @headers = N'{"Content-Type": "application/json"}',
    @payload = @json,
    @response = @jsonResponse OUTPUT;


--SELECT @string = JSON_VALUE(@jsonResponse, '$.result.message.content' );
print 'Retrieval response: ' + @string
END

SET @string = REPLACE(REPLACE(REPLACE(@string, '\r', ''),'\n',''),'\t','');
SET @history = REPLACE(REPLACE(REPLACE(@history, '\r', ''),'\n',''),'\t','');

SET @string = REPLACE(REPLACE(@string, CHAR(13), ''), CHAR(10), '')
SET @history = REPLACE(REPLACE(@history, CHAR(13), ''), CHAR(10), '')

SET @json = CONCAT('{
  "model": "gemma3:1b",
  "messages": [
    {
      "role": "system",
      "content": "You are an assistant for question-answering tasks. If you do not know the answer, just say that you do not know. Use three sentences maximum and keep the answer concise. Disregard any context that does not directly relate to the question."
    }'
    ,@history
    ,',{
      "role": "user",
      "content": "'
    ,REPLACE(@string, '"', '''')
    ,'. Use the following pieces of retrieved context to answer the question, and begin after the next colon:' + @context + '"
    }
  ],
  "stream": false
}');
print @json
print 'Question: ' + @string

-- Make the HTTP call to Ollama
EXEC sp_invoke_external_rest_endpoint  
    @url = N'https://ollama.digitaltalc.com/api/chat',
    @method = 'POST',
    @headers = N'{"Content-Type": "application/json"}',
    @payload = @json,
    @response = @jsonResponse OUTPUT;



SELECT @result = JSON_VALUE(@jsonResponse, '$.result.message.content' );

INSERT INTO [dbo].[history] ([session],[type],[response],[rag]) VALUES 
 (@@SPID, 'user', @string, NULL)
,(@@SPID, 'llm', @result, @context)
END
GO


