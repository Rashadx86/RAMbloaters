#!/bin/bash

#Customizable variables
export MemMultiple=2
export MemBuffer=8192
export TodayDate=$(date -d today +%D)
export YestDate=$(date -d yesterday +%D)
export RawLoc="$HOME/SacctAnalysis.txt"
export ParsedLoc="$HOME/ParsedMemAnalysis.txt"
export OffendersLoc="$HOME/MemOffenders.txt"
#Uncomment to select specific partition/s to query. All partitions are queried if unset
#export Partition='--partition=xyz_queue,abc_queue'




#Below not intended for customization

#Collect Data
/usr/bin/sacct -a -S $YestDate -E $TodayDate -P $Partition --state=cd --noconvert --noheader -o 'user,JobID,JobName,NCPUS,ReqMem,MaxRSS' > $RawLoc


#Analyze batch jobs. Integrate info from batch subjob, then remove these duplicate lines. Convert units. Remove MemPerCore & srun requests as different calculations are needed.
grep -v '^[a-zA-Z].*[a-zA-Z]$' $RawLoc |
        awk 'BEGIN{OFS=FS="|"} NR%2==1 { prev=$0 }; $3=="batch" { print prev $6 }' |
        awk '$6 ~ /[0-9\.]+K/ { $6 = int($6 / 1024) } 1' OFS="|" FS="|" |
        awk '$5 ~ /[0-9\.]+Mn/ { $5 = int($5) } 1' OFS="|" FS="|" |
        awk '$5!~/Mc/' OFS="|" FS="|" |
        awk '{print $1,$2,$3,$5,$6}' OFS="|" FS="|" \
        > $ParsedLoc


#Analyze MemPerCore jobs
grep -v '^[a-zA-Z].*[a-zA-Z]$' $RawLoc |
        awk 'BEGIN{OFS=FS="|"} NR%2==1 { prev=$0 }; $3=="batch" { print prev $6 }' |
        awk '$6 ~ /[0-9\.]+K/ { $6 = int($6 / 1024) } 1' OFS="|" FS="|" |
        awk '$5~/Mc/' OFS="|" FS="|" |
        awk '$5 ~ /[0-9\.]+Mc/ { $5 = int($5 * $4) } 1' OFS="|" FS="|" |
        awk '{print $1,$2,$3,$5,$6}' OFS="|" FS="|" \
        >> $ParsedLoc


#Analyze srun jobs, convert units
grep '^[a-zA-Z].*[a-zA-Z]$' $RawLoc |
        awk '$6 ~ /[0-9\.]+K/ { $6 = int($6 / 1024) } 1' OFS="|" FS="|" |
        awk '$5 ~ /[0-9\.]+Mn/ { $5 = int($5) } 1' OFS="|" FS="|" |
        awk '{print $1,$2,$3,$5,$6}' OFS="|" FS="|" \
        >> $ParsedLoc

#Identify Offenders

awk -v Multiple=$MemMultiple -v Buffer=$MemBuffer \
        '{ if ($4 > $5 * Multiple && $4 > $5 + Buffer ) print $0 }' \
        OFS="|" FS="|" $ParsedLoc > $OffendersLoc


#Summaries
TotalRamWasteByOffenders=$(awk '{ $6 = int($4 - $5) } 1' OFS="|" FS="|" $OffendersLoc | 
        awk '{print $6}'  OFS="|" FS="|" | paste -sd+ - |
        bc | 
        awk '{print int($1/1000)" GBs"}')

TotalRamWaste=$(awk '{ $6 = int($4 - $5) } 1' OFS="|" FS="|" $ParsedLoc | 
        awk '{print $6}'  OFS="|" FS="|" | 
        paste -sd+ - | 
        bc | 
        awk '{print int($1/1000)" GBs"}')



# Print summary
printf "Total RAM unused by offenders:  %s %s\n" $TotalRamWasteByOffenders
printf "Total RAM unused                %s %s\n" $TotalRamWaste


rm $RawLoc $ParsedLoc
