/************************************************************************************
 *																					*
 * Extended event session for Query Memory (memory grant feedback)					*
 *																					*
 * @author			James Randell <jamesrandell@me.com>								*
 * @datemodified	23rd September, 2022											*
 *			05/2022	Created															*
 *																					*
 * Configures then reads from the session.											*
 *																					*
 * Now autoamtically pulls back data from the most recent .xel file, so no need to	*
 * manually identify the file for each server you use this on!						*
 *																					*
 ************************************************************************************/
 
DECLARE		@event varchar(26) = 'uxe_query_memory'
DECLARE		@fileName varchar(128)

--CREATE EVENT SESSION [uxe_query_memory] ON SERVER 
--ADD EVENT sqlserver.query_memory_grant_usage(
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)),
--ADD EVENT sqlserver.rpc_completed(
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)
--	WHERE ([duration]>=(1000000))),
--ADD EVENT sqlserver.sp_statement_completed(
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)
--	WHERE ([duration]>=(1000000))),
--ADD EVENT sqlserver.sql_batch_completed(
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.sql_text)
--	WHERE ([duration]>=(1000000)))
--ADD TARGET package0.event_file(SET filename=N'D:\uxe_query_memory.xel',max_file_size=(100),max_rollover_files=(10))
--WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
--GO

--ALTER EVENT SESSION [uxe_query_memory] ON SERVER 
--	STATE = START;
--GO



;WITH [t] AS (

SELECT		 [full_filesystem_path] AS 'path'
						,[file_or_directory_name] AS 'name'
						,[is_directory] AS 'isdirectory'
						,[last_write_time] AS 'datemodified'
						,ROW_NUMBER() OVER (PARTITION BY SUBSTRING([file_or_directory_name], 0, CHARINDEX('_0_', [file_or_directory_name])) ORDER BY [last_write_time] DESC) as 'row'
						,SUBSTRING([file_or_directory_name], 0, CHARINDEX('_0_', [file_or_directory_name])) as [name_base]
			FROM sys.dm_os_enumerate_filesystem('D:\', '*.xel')
)

SELECT		@fileName = [path]
FROM		[t]
WHERE		[row] = 1
		AND [name_base] = @event


;WITH [t] AS (
SELECT
    [XML Data],
    [XML Data].value('(/event[@name=''sql_batch_completed'']/@timestamp)[1]','DATETIME')							 AS [timestamp],
	[XML Data].value('(/event/action[@name=''database_name'']/value)[1]','nvarchar(128)')							AS [database],
    CAST([XML Data].value('(/event/data[@name=''cpu_time'']/value)[1]','numeric(18,2)') / 1000000 AS numeric(18,2))	AS [cpu_time],
    CAST([XML Data].value('(/event/data[@name=''duration'']/value)[1]','numeric(18,2)') / 1000000 AS numeric(18,2))	AS [duration],
	[XML Data].value('(/event/action[@name=''physical_reads'']/value)[1]','bigint')									AS [physical_reads],
	[XML Data].value('(/event/action[@name=''logical_reads'']/value)[1]','bigint')									AS [logical_reads],
	[XML Data].value('(/event/action[@name=''row_count'']/value)[1]','bigint')										AS [row_count],
	[XML Data].value('(/event/data[@name=''granted_memory_kb'']/value)[1]','bigint')								AS [Grant],
	[XML Data].value('(/event/data[@name=''used_memory_kb'']/value)[1]','bigint')									AS [Used],
	[XML Data].value('(/event/data[@name=''ideal_additional_memory_before_kb'']/value)[1]','bigint')				AS [ideal_additional_memory_before_kb],
	[XML Data].value('(/event/data[@name=''ideal_additional_memory_after_kb'']/value)[1]','bigint')					AS [ideal_additional_memory_after_kb],
	[XML Data].value('(/event/data[@name=''ideal_additional_memory_after_kb'']/value)[1]','bigint')					AS [history_current_execution_count],
	[XML Data].value('(/event/data[@name=''history_update_count'']/value)[1]','bigint')								AS [history_update_count],
    [XML Data].value('(/event/action[@name=''sql_text'']/value)[1]','varchar(max)')									AS [Statement]

FROM
    (SELECT
        OBJECT_NAME              AS [Event], 
        CONVERT(XML, event_data) AS [XML Data]
    FROM
        sys.fn_xe_file_target_read_file
    (@fileName,NULL,NULL,NULL)) as FailedQueries
)

SELECT * FROM [t]
WHERE 1=1
	AND [database] NOT IN ('master','msdb','model','tempdb')
	--AND [Grant] IS NOT NULL




--ALTER EVENT SESSION [uxe_query_memory] ON SERVER 
--	STATE = STOP;
--GO
