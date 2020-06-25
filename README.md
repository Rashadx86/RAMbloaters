# RAMbloaters

### Description
Identify jobs that requested a larger amount of RAM than the job actually used (sensitivity is customizable). Output the job details into a file for parsing or identifying certain jobs. Print a summary of unused ram.

#### MemMultiple and MemBuffer 

*MemMultiple* is the multiple by which a job requested X multiple amount of RAM than the job actually used. Default=2

*MemBuffer* is the buffer used to exempt jobs whose unused RAM is less than the set amount. Default=8192 (MB)

#### Example 
If MemMultiple is set to 2 and MemBuffer is set to 8192 (MB), then a user will be an offender if they requested over 2x their effective (actual used) RAM as well as at least 8192MB above their effective RAM.

The MemBuffer is to filter out smaller jobs that could have used over double the requested RAM but are not detrimental to the cluster. i.e. A job that requested 4GB but used 500MB will not be listed as an offender.


### Usage

`bash RAMbloaters/MemCheck.sh`

MemOffenders.txt will contain the list of all jobs that match the criteria set by MemMultiple and MemBuffer.

### Sample Output

```
bash RAMbloaters/MemCheck.sh 

Total RAM unused by offenders:	13539 GBs
Total RAM unused 		16908 GBs
```

From MemOffenders.txt
```
userA|5185136|Example_jobname|92160|29379
userB|5188731|Example_job324|256000|30678
userC|5188783|Example_job_abcd|16384|7404
...
```
The fourth and fifth fields being the requested RAM and effective RAM, respectively.
