On solaris:
number of physical cpu: "psrinfo -p"
number of cores: "kstat cpu_info|grep core_id|sort -u|wc -l"  ##If this returns 0 they're single-core so is the same as the No.of processors## 
number of threads: "psrinfo -pv"


On AIX:

It certainly makes sense when we look at the output of the two different commands:

1) prtconf
2) lsdev -Cc processor

and understand the output as relating to cores and not the entire chip itself.


1.lsdev -Cc processor
proc0 Available 00-00 Processor
proc2 Available 00-02 Processor
proc4 Available 00-04 Processor
proc6 Available 00-06 Processor

Taking the above example, all the four above are cores from a single cpu that you can use. I think this is the number oracle are interested in,
should return the same as lparstat -i|grep "Maximum Virtual CPUs" (maybe, this might be the number of threads per core  so it might be Physical not virtual :-/)

#prtconf

System Model: IBM,9110-51A
Machine Serial Number: 0666B0F
Processor Type: PowerPC_POWER5
Number Of Processors: 4
Processor Clock Speed: 1648 MHz

The 'Number of Processors' : 4 is really the number of cores that you can use (at the moment, i.e. the online amount). The term 'processor' is misleading.

#lparstat -i
..
...
Maximum Physical CPUs in system : 4
Active Physical CPUs in system : 4

lparstat -i is also telling you the total number of cores that are possible in 
the system (Maximum physical CPUs) since you have a single quad core chip, and 
also the number of cores that are active (available for use): which is again 4.

Even here, the term "physical CPU" is misleading, it really means the number of cores, "Logical CPU" usually the means the number 
of threads....which for licensing, Oracle don;t care about.

However, note that lparstat -i gives you the total number of cores (max phy CPUs/ active phy CPUs) 
on the entire managed system (and not just on your LPAR), which explains the observation on my managed system:

#lparstat -i 
Maximum Physical CPUs in system : 16
Active Physical CPUs in system : 12

#prtconf
Number Of Processors: 3 // my LPAR uses three cores.

#lsdev -Cc processor // my LPAR uses three cores.
proc0 Available 00-00 Processor
proc2 Available 00-02 Processor
proc4 Available 00-04 Processor

Regd the numbering, not sure what the tags 00-00 mean but all we can say for sure is that our lpar 
uses three cores from the total available 12 cores on the managed system
###################################################################################################

Example of apewo101:

lparstat: 
System configuration: type=Shared mode=Capped smt=4 lcpu=8 mem=12288MB psize=64 ent=2.00
("The number of online logical processors")
SQL> show parameter cpu
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
cpu_count                            integer     8
parallel_threads_per_cpu             integer     2
resource_manager_cpu_allocation      integer     8


lsdev -Cc processor
proc0 Available 00-00 Processor
proc4 Available 00-04 Processor

prtconf
Number Of Processors: 2
+ proc0                                                                           Processor
+ proc4                                                                           Processor

lparstat -i
Mode                                       : Capped
Entitled Capacity                          : 2.00
Online Virtual CPUs                        : 2
Maximum Virtual CPUs                       : 3
Minimum Virtual CPUs                       : 1
Maximum Physical CPUs in system            : 64
Active Physical CPUs in system             : 64
Active CPUs in Pool                        : 64
Shared Physical CPUs in system             : 64
Desired Virtual CPUs                       : 2
