DECLARE @text NVARCHAR(MAX) = N'This is a test sentence.';
DECLARE @json NVARCHAR(MAX) = N'{
  "model": "llama3.2:latest",
  "prompt": "' + @text + N'"
}';

DECLARE @result NVARCHAR(MAX);

-- Make the HTTP call to Ollama
EXEC sp_invoke_external_rest_endpoint  
    @url = N'https://ollama.digitaltalc.com/api/embeddings',
    @method = 'POST',
    @headers = N'{"Content-Type": "application/json"}',
    @payload = @json,
    @response = @result OUTPUT;

-- Extract the embedding from the JSON response
-- You may need to adapt this depending on the model output format
-- Assume @result looks like: { "response": "[0.123, 0.234, ..., 0.567]" }

DECLARE @embeddingJson NVARCHAR(MAX);
print @result

--SELECT @embeddingJson = JSON_VALUE(@result, '$.response');