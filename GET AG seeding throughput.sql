IF OBJECT_ID('tempdb..#Seeding') IS NOT NULL DROP TABLE #Seeding;

SELECT  GETDATE() AS CollectionTime,
        instance_name,
        cntr_value
INTO    #Seeding
FROM    sys.dm_os_performance_counters
WHERE   counter_name = 'Backup/Restore Throughput/sec';

WAITFOR DELAY '00:00:05'

SELECT  LTRIM(RTRIM(p2.instance_name)) AS [DatabaseName],
        (p2.cntr_value - p1.cntr_value) / (DATEDIFF(SECOND,p1.CollectionTime,GETDATE())) AS ThroughputBytesSec
FROM    sys.dm_os_performance_counters AS p2
        INNER JOIN #Seeding AS p1
            ON p2.instance_name = p1.instance_name
WHERE   p2.counter_name LIKE 'Backup/Restore Throughput/sec%'
ORDER BY
        ThroughputBytesSec DESC;
			
