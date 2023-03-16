--CREATE EVENT SESSION [uxe_capture_errors] ON SERVER 
--ADD EVENT sqlserver.error_reported(
--    ACTION(sqlserver.client_hostname,sqlserver.database_id,sqlserver.nt_username,
--sqlserver.sql_text,sqlserver.tsql_stack,sqlserver.username)
--    WHERE ([severity]>=(10)))
--ADD TARGET package0.event_file(SET filename=N'D:\uxe_capture_errors.xel',metadatafile=N'D:\uxe_capture_errors.xem')
--WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=1 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
--GO

--ALTER EVENT SESSION [uxe_capture_errors] ON SERVER 
--	STATE = START;
--GO

WITH [t] AS (
SELECT
    [XML Data],
    [XML Data].value('(/event[@name=''error_reported'']/@timestamp)[1]','DATETIME')             AS [Timestamp],
    [XML Data].value('(/event/action[@name=''database_id'']/value)[1]','smallint')			     AS [Database],
    [XML Data].value('(/event/data[@name=''message'']/value)[1]','varchar(max)')                AS [Message],
    [XML Data].value('(/event/action[@name=''sql_text'']/value)[1]','varchar(max)')             AS [Statement],
	[XML Data].value('(/event/data[@name=''error_number'']/value)[1]','int')					AS [error_number],
	[XML Data].value('(/event/data[@name=''severity'']/value)[1]','int')						AS [severity],
	[XML Data].value('(/event/action[@name=''nt_username'']/value)[1]','nvarchar(100)')			AS [nt_username],
	[XML Data].value('(/event/action[@name=''username'']/value)[1]','nvarchar(100)')			AS [username]
FROM
    (SELECT
        OBJECT_NAME              AS [Event], 
        CONVERT(XML, event_data) AS [XML Data]
    FROM
        sys.fn_xe_file_target_read_file
    ('D:\uxe_capture_errors_0_133079605775460000.xel',NULL,NULL,NULL)) as FailedQueries
)

SELECT * FROM [t]
WHERE 1=1
	AND [username] <> 'NT AUTHORITY\SYSTEM'
	AND [username] <> 'NT SERVICE\SQLTELEMETRY'
	AND [Database] > 4
	--AND [severity] < 11
	AND [error_number] NOT IN (
		2528, -- DBCC execution completed. If DBCC printed error messages, contact your system administrator.
		5701, -- Changed database context to 'ChamGenReplicas'.
		5703, -- Changed language setting to us_english.
		2714, -- There is already an object named 'xxx' in the database.
		2759, -- CREATE SCHEMA failed due to previous errors.
		1750, -- Could not create constraint or index. See previous errors.
		1779, -- Table 'xxx' already has a primary key defined on it.
		6299, -- AppDomain xxxx (SCMReplica.dbo[runtime].xxxx) created.
		9002, -- The transaction log for database 'ICEChameleonReplica' is full due to 'AVAILABILITY_REPLICA'.
		5901, -- One or more recovery units belonging to database xxx failed to generate a checkpoint.
		3619, -- Could not write a checkpoint record in database xxx because the log is out of space.
		9605, -- Conversation Priorities analyzed: XXX
		9667, -- Services analyzed: xxx
		9668, -- Service Queues analyzed: xxx
		9669, -- Conversation Endpoints analyzed: xxx
		9670, -- Remote Service Bindings analyzed: xxx
		9674, -- Conversation Groups analyzed: xxx
		9675, -- Message Types analyzed: xxx
		9676, -- Service Contracts analyzed: xxx
		5277, -- Internal database snapshot has split point...
		8957, -- DBCC CHECKDB xxx ...
		8153, -- Warning: Null value is eliminated by an aggregate or other SET operation.
		3615, -- Table 'xxx'. Scan count x, logical reads x, physical reads x, page server reads x...
		3612, -- SQL Server Execution Times:    CPU time = x ms,  elapsed time = x ms.
		3613, -- SQL Server parse and compile time:     CPU time = x ms, elapsed time = x ms.
		9104, -- auto statistics internal
		15650, -- Updating [sys].[sqlagent_jobsteps]
		15651, --     0 index(es)/statistic(s) have been updated, 2 did not require update.
		15653, --     [PK__Location_Rooms__26CFC035], update is not necessary...
		49930, -- Parallel redo is started for database 'xxx' with worker pool size [x].
		50000 -- random
	)
	AND [Timestamp] > '2022-10-20 14:00:00.000'
	AND [username] NOT IN (
		'CMMC\James.Randell'
	)

	--AND [Message] LIKE 'Could not find server%'
	--AND [Timestamp] > '2022-10-20 12:00:00.000'
GO

--ALTER EVENT SESSION uxe_capture_errors ON SERVER 
--	STATE = STOP;
