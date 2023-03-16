/************************************************************************************
 *																					*
 * Extended event session for Slow Queries											*
 *																					*
 * @author			James Randell <jamesrandell@me.com>								*
 * @datemodified	23rd September, 2022											*
 *			05/2022	Created															*
 *																					*
 * Configures then reads from the session.
 *																					*
 * Now autoamtically pulls back data from the most recent .xel file, so no need to	*
 * manually identify the file for each server you use this on!						*
 *																					*
 ************************************************************************************/
 
DECLARE		@event varchar(26) = 'uxe_slow_queries'
DECLARE		@fileName varchar(128)

--CREATE EVENT SESSION [uxe_slow_queries] ON SERVER 
--ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
--    WHERE ([duration]>=(2500000))),
--ADD EVENT sqlserver.sp_statement_completed(
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_name,sqlserver.nt_username,sqlserver.server_principal_name,sqlserver.session_id)
--    WHERE ([duration]>=(2500000))),
--ADD EVENT sqlserver.sql_batch_completed(
--    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
--    WHERE ([duration]>=(2500000))),
--ADD EVENT sqlserver.memory_grant_feedback_loop_disabled(
--	ACTION(sqlserver.database_name,sqlserver.plan_handle,sqlserver.sql_text)),
--ADD EVENT sqlserver.memory_grant_updated_by_feedback(
--	ACTION(sqlserver.database_name,sqlserver.plan_handle,sqlserver.sql_text))
--ADD TARGET package0.event_file(SET filename=N'D:\uxe_slow_queries.xel',metadatafile=N'D:\uxe_slow_queries.xem')
--WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=ON)
--GO

--ALTER EVENT SESSION [uxe_slow_queries] ON SERVER 
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
    [XML Data].value('(/event[@name=''rpc_completed'']/@timestamp)[1]','DATETIME')									AS [timestamp],
    [XML Data].value('(/event/action[@name=''database_id'']/value)[1]','smallint')									AS [databaseid],
	[XML Data].value('(/event/action[@name=''database_name'']/value)[1]','nvarchar(128)')							AS [database],
    CAST([XML Data].value('(/event/data[@name=''cpu_time'']/value)[1]','numeric(18,2)') / 1000000 AS numeric(18,2))	AS [cpu_time],
    CAST([XML Data].value('(/event/data[@name=''duration'']/value)[1]','numeric(18,2)') / 1000000 AS numeric(18,2))	AS [duration],
	[XML Data].value('(/event/action[@name=''physical_reads'']/value)[1]','bigint')									AS [physical_reads],
	[XML Data].value('(/event/action[@name=''logical_reads'']/value)[1]','bigint')									AS [logical_reads],
	[XML Data].value('(/event/action[@name=''row_count'']/value)[1]','bigint')										AS [row_count],
    COALESCE([XML Data].value('(/event/action[@name=''sql_text'']/value)[1]','varchar(max)'), [XML Data].value('(/event/data[@name=''statement'']/value)[1]','varchar(max)')) AS [Statement],
	[XML Data].value('(/event/action[@name=''nt_username'']/value)[1]','nvarchar(100)')								AS [nt_username],
	[XML Data].value('(/event/action[@name=''attach_activity_id'']/value)[1]','varchar(40)')						AS [attach_activity_id],
	[XML Data].value('(/event/action[@name=''client_app_name'']/value)[1]','varchar(128)')							AS [client_app_name],
	[XML Data].value('(/event/action[@name=''client_hostname'']/value)[1]','varchar(128)')							AS [client_hostname]

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
	AND [nt_username] <> 'NT AUTHORITY\SYSTEM'
	AND [nt_username] <> 'NT SERVICE\SQLTELEMETRY'
	AND [Databaseid] > 4
	AND [database] <> 'ReportServer'
	AND [client_hostname] NOT IN ('SQL-DIST-01','SQL-DIST-02','SQL-DIST-03','SQL-DIST-04','SQL-DIST-05','SQLCMD')
	AND [client_app_name] NOT IN ('SQLCMD')
	--AND [Message] LIKE 'Could not find server%'
	AND [duration] > 3
	AND [Timestamp] > '2022-10-20 11:00:00.000'
	--AND [database] IN ( '<database>')
	--AND [XML Data].value('(/event/data[@name=''result'']/text)[1]','varchar(10)') = 'Abort'

GO

--SELECT	 FORMAT ([timestamp], 'yyyy-MM-dd hh') AS 'Time (hour)'
--		,COUNT(*)FROM [t]
--WHERE 1=1
--	AND [nt_username] <> 'NT AUTHORITY\SYSTEM'
--	AND [nt_username] <> 'NT SERVICE\SQLTELEMETRY'
--	AND [Databaseid] > 4
--	AND [client_hostname] NOT IN ('SQL-DIST-01','SQL-DIST-02','SQL-DIST-03','SQL-DIST-04','SQL-DIST-05','SQLCMD')
--	AND [client_app_name] NOT IN ('SQLCMD')
--	--AND [Message] LIKE 'Could not find server%'
--	AND [duration] > 3
--	AND [Timestamp] > '2022-08-01 12:00:00.000'
--GROUP BY FORMAT ([timestamp], 'yyyy-MM-dd hh')
--GO



--ALTER EVENT SESSION [uxe_slow_queries] ON SERVER 
--	STATE = STOP; 
