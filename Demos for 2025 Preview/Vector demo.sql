-- table creation works
DROP TABLE IF EXISTS dbo.TextEmbeddings
CREATE TABLE dbo.TextEmbeddings (
Embedding VECTOR(3)
);

-- either of these methods cause a crash report and a dump
DECLARE @vec NVARCHAR(MAX) = '[0.123, 0.234, 0.345]'; 
INSERT INTO dbo.TextEmbeddings (Embedding)
VALUES (@vec);

INSERT INTO dbo.TextEmbeddings (Embedding)
VALUES ( CAST(@vec AS VECTOR(3) ))