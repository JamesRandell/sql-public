/************************************************************************************
 *																					*
 * Returns all the info about AG seeding in a cluster								*
 *																					*
 * 03: Switches database names and sorts out AG stuff when making a database live	*
 *																					*
 * @author			James Randell <jamesrandell@me.com>								*
 * @datemodified																	*
 *			08/2022	Created															*
 *																					*
 * One of my better scripts :)														*
 * Really useful, shows you the % complete, how many DBs have been moved, left,		*
 * estimated completion date and any errors											*
 *																					*
 ************************************************************************************/

SELECT			 local_database_name
				,remote_machine_name
				,role_desc
				,internal_state_desc
				,transfer_rate_bytes_per_second
				,CASE	WHEN transfer_rate_bytes_per_second < POWER(Convert(bigint,1024), 1) THEN CAST(transfer_rate_bytes_per_second AS varchar(14)) + ' bytes'
						WHEN transfer_rate_bytes_per_second < POWER(Convert(bigint,1024), 2) THEN CAST(transfer_rate_bytes_per_second / POWER(1024,1) AS varchar(14)) + ' KB'
						WHEN transfer_rate_bytes_per_second < POWER(Convert(bigint,1024), 3) THEN CAST(transfer_rate_bytes_per_second / POWER(1024,2) AS varchar(14)) + ' MB'
						WHEN transfer_rate_bytes_per_second < POWER(Convert(bigint,1024), 4) THEN CAST(transfer_rate_bytes_per_second / POWER(1024,3) AS varchar(14)) + ' GB'
						WHEN transfer_rate_bytes_per_second < POWER(Convert(bigint,1024), 5) THEN CAST(transfer_rate_bytes_per_second / POWER(CAST(1024 as float),4) AS varchar(14)) + ' TB'
				END AS 'transfer_rate'
				,CASE	WHEN transferred_size_bytes < POWER(Convert(bigint,1024), 1) THEN CAST(transferred_size_bytes AS varchar(14)) + ' bytes'
						WHEN transferred_size_bytes < POWER(Convert(bigint,1024), 2) THEN CAST(transferred_size_bytes / POWER(1024,1) AS varchar(14)) + ' KB'
						WHEN transferred_size_bytes < POWER(Convert(bigint,1024), 3) THEN CAST(transferred_size_bytes / POWER(1024,2) AS varchar(14)) + ' MB'
						WHEN transferred_size_bytes < POWER(Convert(bigint,1024), 4) THEN CAST(transferred_size_bytes / POWER(1024,3) AS varchar(14)) + ' GB'
						WHEN transferred_size_bytes < POWER(Convert(bigint,1024), 5) THEN CAST(transferred_size_bytes / POWER(CAST(1024 as float),4) AS varchar(14)) + ' TB'
				END AS 'transferred_size'
				,CASE	WHEN database_size_bytes < POWER(Convert(bigint,1024), 1) THEN CAST(database_size_bytes AS varchar(14)) + ' bytes'
						WHEN database_size_bytes < POWER(Convert(bigint,1024), 2) THEN CAST(database_size_bytes / POWER(1024,1) AS varchar(14)) + ' KB'
						WHEN database_size_bytes < POWER(Convert(bigint,1024), 3) THEN CAST(database_size_bytes / POWER(1024,2) AS varchar(14)) + ' MB'
						WHEN database_size_bytes < POWER(Convert(bigint,1024), 4) THEN CAST(database_size_bytes / POWER(1024,3) AS varchar(14)) + ' GB'
						WHEN database_size_bytes < POWER(Convert(bigint,1024), 5) THEN CAST(database_size_bytes / POWER(CAST(1024 as float),4) AS varchar(14)) + ' TB'
				END AS 'database_size'
				,CASE	WHEN (database_size_bytes - transferred_size_bytes) < POWER(Convert(bigint,1024), 1) THEN CAST((database_size_bytes - transferred_size_bytes) AS varchar(14)) + ' bytes'
						WHEN (database_size_bytes - transferred_size_bytes) < POWER(Convert(bigint,1024), 2) THEN CAST((database_size_bytes - transferred_size_bytes) / POWER(1024,1) AS varchar(14)) + ' KB'
						WHEN (database_size_bytes - transferred_size_bytes) < POWER(Convert(bigint,1024), 3) THEN CAST((database_size_bytes - transferred_size_bytes) / POWER(1024,2) AS varchar(14)) + ' MB'
						WHEN (database_size_bytes - transferred_size_bytes) < POWER(Convert(bigint,1024), 4) THEN CAST((database_size_bytes - transferred_size_bytes) / POWER(1024,3) AS varchar(14)) + ' GB'
						WHEN (database_size_bytes - transferred_size_bytes) < POWER(Convert(bigint,1024), 5) THEN CAST((database_size_bytes - transferred_size_bytes) / POWER(CAST(1024 as float),4) AS varchar(14)) + ' TB'
				END AS 'size_left'
				,ROUND(CAST(transferred_size_bytes AS float) / CAST(database_size_bytes AS float) * 100, 2) AS 'percent_complete'
				,start_time_utc
				,end_time_utc
				,estimate_time_complete_utc
				,total_disk_io_wait_time_ms
				,total_network_wait_time_ms
				,failure_code
				,failure_message
				,failure_time_utc
FROM			sys.dm_hadr_physical_seeding_stats
WHERE			internal_state_desc <> 'Success'
