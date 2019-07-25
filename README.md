#Performance Testing for Buck nodes Addition

**_Requirement_:** 

- To find the optimum way to add hardware bulk in number to a production cluster without causing SLA miss 
- Hardware could be either compute type or storage type
- To arrive a maximum threshold number of nodes which could be added to live cluster without impacting SLA

**_Metrics to Collect Automation_:** 

- Job average running time compared with Benchmark, any job 30% slow needs to analyze the application log.
- Namenode JMX slow nodes report and correlate with Datanode metrics.
- SAR report for new added nodes and slow nodes . (New nodes CPU, Memory and I/O) , compared result for old nodes. 
- Dmesg log for new nodes.
- netstat log, SYNs to Listen sockets dropped  (slow nodes and new nodes) 
- Grafana monitoring for cluster level  (Need to identify charts) 

