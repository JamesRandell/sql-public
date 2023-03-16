--CREATE EVENT SESSION [uxe_memory_grant_feedback] ON SERVER
--ADD EVENT sqlserver.memory_grant_feedback_loop_disabled(
--ACTION(sqlserver.database_name,sqlserver.plan_handle,sqlserver.sql_text)),
--ADD EVENT sqlserver.memory_grant_updated_by_feedback(
--ACTION(sqlserver.database_name,sqlserver.plan_handle,sqlserver.sql_text))
--ADD TARGET package0.event_file(SET filename=N'D:\uxe_memory_grant_feedback.xel',metadatafile=N'D:\uxe_memory_grant_feedback.xem')
--WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30
-- SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
--GO


--ALTER EVENT SESSION [uxe_memory_grant_feedback] ON SERVER 
--	STATE = START;
--GO


WITH [t] AS (
SELECT
    [XML Data],
    [XML Data].value('(/event[@name=''memory_grant_updated_by_feedback'']/data[@name=''ideal_additional_memory_before_kb'')[1]','bigint')	AS [ideal_additional_memory_before_kb],
    [XML Data].value('(/event[@name=''memory_grant_updated_by_feedback'']/data[@name=''ideal_additional_memory_before_kb'')[1]','bigint')	AS [ideal_additional_memory_after_kb],
	[XML Data].value('(/event[@name=''memory_grant_updated_by_feedback'']/data[@name=''history_current_execution_count'')[1]','int')		AS [history_current_execution_count],
    [XML Data].value('(/event[@name=''memory_grant_updated_by_feedback'']/data[@name=''history_update_count'')[1]','int')					AS [history_update_count],
	[XML Data].value('(/event[@name=''memory_grant_updated_by_feedback'']/action[@name=''database_name'']/value)[1]','nvarchar(128)')		AS [database],
    COALESCE([XML Data].value('(/event/action[@name=''sql_text'']/value)[1]','varchar(max)'), [XML Data].value('(/event/data[@name=''statement'']/value)[1]','varchar(max)')) AS [Statement],
	[XML Data].value('(/event[@name=''memory_grant_updated_by_feedback'']/data[@name=''plan_handle'')[1]','int')							AS [plan_handle]

FROM
    (SELECT
        OBJECT_NAME              AS [Event], 
        CONVERT(XML, event_data) AS [XML Data]
    FROM
        sys.fn_xe_file_target_read_file
    ('D:\uxe_memory_grant_feedback_0_133083253642960000.xel',NULL,NULL,NULL)) as FailedQueries
)

SELECT * FROM [t]
WHERE 1=1
	--AND [nt_username] <> 'NT AUTHORITY\SYSTEM'
	--AND [nt_username] <> 'NT SERVICE\SQLTELEMETRY'
	--AND [Databaseid] > 4
	--AND [client_hostname] NOT IN ('SQL-DIST-01','SQL-DIST-02','SQL-DIST-03','SQL-DIST-04','SQL-DIST-05','SQLCMD')
	--AND [client_app_name] NOT IN ('SQLCMD')
	----AND [Message] LIKE 'Could not find server%'
	--AND [duration] > 3
	----AND [duration] < 4
	--AND [Timestamp] > '2022-09-05 11:00:00.000'
	--AND [XML Data].value('(/event/data[@name=''result'']/text)[1]','varchar(10)') = 'Abort'

GO



--ALTER EVENT SESSION [uxe_memory_grant_feedback] ON SERVER 
--	STATE = STOP; 
