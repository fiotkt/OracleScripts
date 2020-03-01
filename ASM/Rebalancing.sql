sys@XESB: select NAME, TOTAL_MB  from v$asm_diskgroup;
NAME                             TOTAL_MB
------------------------------ ----------
DATA                               300000
FRA                                 60000
OCF                                  4000
ONLINE1                             15000
ONLINE2                             15000

sys@XESB: select PATH, HEADER_STATUS from v$asm_disk;

PATH                                                         HEADER_STATU
------------------------------------------------------------ ------------
/dev/rhdisk10                                                MEMBER
/dev/rhdisk3                                                 MEMBER
/dev/rhdisk4                                                 MEMBER
/dev/rhdisk5                                                 MEMBER
/dev/rhdisk6                                                 MEMBER
/dev/rhdisk7                                                 MEMBER
/dev/rhdisk8                                                 MEMBER
/dev/rhdisk9                                                 MEMBER
/dev/rhdisk13                                                CANDIDATE<<--------------Add this
/dev/rhdisk12                                                CANDIDATE<<--------------Add this



sys@XESB: !ls -ltr /dev/rhdisk* <<--CHECK ON BOTH SIDES OF THE RAC CLUSTER

Rob didn't do correctly first time, some of the disks were visible on one node but not the other so you need to check else you'll get an error when adding

crw-------    2 root     system       18,  0 19 Jan 12:10 /dev/rhdisk0
crw-------    1 root     system       18,  4 20 Jan 15:43 /dev/rhdisk2
crw-------    1 root     system       18,  5 20 Jan 15:43 /dev/rhdisk1
crw-rw----    1 grid     asmadmin     18,  8 28 Mar 10:40 /dev/rhdisk9
crw-rw----    1 grid     asmadmin     18, 13 27 Jun 11:24 /dev/rhdisk13
crw-rw----    1 grid     asmadmin     18, 12 27 Jun 11:24 /dev/rhdisk12
crw-------    1 root     system       18, 11 27 Jun 11:24 /dev/rhdisk11
crw-rw----    1 grid     asmadmin     18,  6 27 Jun 14:09 /dev/rhdisk6
crw-rw----    1 grid     asmadmin     18,  2 27 Jun 14:09 /dev/rhdisk5
crw-rw----    1 grid     asmadmin     18,  3 27 Jun 14:09 /dev/rhdisk4
crw-rw----    1 grid     asmadmin     18,  1 27 Jun 14:09 /dev/rhdisk3
crw-rw----    1 grid     asmadmin     18,  7 27 Jun 14:09 /dev/rhdisk8
crw-rw----    1 grid     asmadmin     18,  9 27 Jun 14:09 /dev/rhdisk7
crw-rw----    1 grid     asmadmin     18, 10 27 Jun 14:09 /dev/rhdisk10


Check the size of the Disks (As ROOT)

root@asebo101:root# bootinfo -s hdisk16
150000
root@asebo101:root# bootinfo -s hdisk17
961824

   #                     #####  ######    ###   ######
  # #     ####          #     # #     #    #    #     #
 #   #   #              #       #     #    #    #     #
#     #   ####          #  #### ######     #    #     #
#######       #         #     # #   #      #    #     #
#     #  #    #         #     # #    #     #    #     #
#     #   ####           #####  #     #   ###   ######



sqlplus / as sysasm
set timing on
ALTER DISKGROUP DATA ADD DISK '/dev/rhdisk17' REBALANCE POWER 5 WAIT;

As GRID, you can see how the rebalancing is going
sys@+ASM1:  select * from  GV$ASM_OPERATION ;

   INST_ID GROUP_NUMBER OPERA STAT      POWER     ACTUAL      SOFAR   EST_WORK   EST_RATE EST_MINUTES ERROR_CODE
---------- ------------ ----- ---- ---------- ---------- ---------- ---------- ---------- ----------- --------------------------------------------
         2            1 REBAL WAIT          5
         1            1 REBAL RUN           5          5      11499      63302       4767          10
