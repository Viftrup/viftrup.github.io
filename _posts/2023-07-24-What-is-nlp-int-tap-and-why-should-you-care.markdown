---
layout: post
title: "What is nlp_int_tap and why should you care?"
author: Alexander Viftrup Andersen
categories: [Secure Firewall, Security]
cover: /assets/pictures/SecureX-CSC-Cloud.png"
image: "/assets/pictures/SecureX-CSC-Cloud-big.png"
published: true
---
Do you actually know what all the interfaces present on your Cisco ASA or FTD installation is doing behind the scenes?

I'm sure you've seen some of them, or atleast you've stumpled accross the interface **<i>"nlp_int_tap" or "Internal-Data0/1</i>"** in recent times during troubleshooting or debugging.

(You might have noticed other interfaces like Internal-Control and other Internal-Data interfaces. These aren't covered in this post, but they mainly relate to internal interfacing for high-availibility and clustering functionailites)

I bet you at some point in time have been doing troubleshooting via packet captures and seen the nlp_int_tap being available for captures - but do you know what it is? And why it might be beneficial to capture on this interface in certain situtations?

<h3>What is the nlp_int_tap interface?</h3>
Non-LINA Process or NLP is in reaility "just" an internal backplace interfacing used for certain operations outside the scope of LINA functionalities. 
(If you're unfamiliar with the name "LINA" it is the codename for the Cisco ASA software, which is the fundament in handling all L1-L4 operations within ASA or FTD software)

Its the glue between many sub-processes, and is not highly documented anywhere as normally you shouldn't care about it. However there might be situtations which it will provide good information when using it as a capture interface during debug sessions.

The NLP is basiclly covering every process which is not run within the LINA process (FTD and SNORT acts a bit different, but still relies on the LINA-engine), this is not limited to but include linux processes like snmpd for SNMP polling and traps alerting, sftunnel for secure communications between FMC and FTD devices, sshd for secure shell, SFDataCollector, SNORT and many more.
The interface is a transport mechanism between these processes and the LINA process in order to operate with each other.
Actually the NLP interface acts "kind of" like a regular routed interface, it does have a static configured IP address which is used for communications between the respective processes and the LINA-engine.

Beware as of ASA/LINA version 9.16+ Cisco introduced some changes to the so called NAT Section 0 - which includes mandatory NAT statements for NLP operations to function properly. NAT Section 0 takes first priority of any NAT statement and cannot be overwritten. However if you do changes to NLP processes it might automaticly change NAT statements as needed. Example would be NAT statement 1 which is an automatic created NAT rule towards my snmpwalk/NMS - this was created since I have a snmp server configured within the ASA configuration. (sftunnel would also be present here, if you're using data-interface manager and/or remote-branch for tcp/8305)
This also gives administrators the possibility to look into these auto-created NLP rules.

```
ViftrupLAB01# show nat
Manual NAT Policies Implicit (Section 0)
1 (nlp_int_tap) to (management) source static nlp_server__snmp_10.1.100.10_intf4 interface  destination static 0_192.168.118.156_7 0_10.1.100.10_7 service udp snmp snmp 
    translate_hits = 3, untranslate_hits = 6
2 (nlp_int_tap) to (outside) source dynamic nlp_client_0_0.0.0.0_17proto53_intf3 interface  destination static nlp_client_0_ipv4_6 nlp_client_0_ipv4_6 service nlp_client_0_17svc53_5 nlp_client_0_17svc53_5
    translate_hits = 0, untranslate_hits = 0
3 (nlp_int_tap) to (management) source dynamic nlp_client_0_0.0.0.0_17proto53_intf4 interface  destination static nlp_client_0_ipv4_2 nlp_client_0_ipv4_2 service nlp_client_0_17svc53_1 nlp_client_0_17svc53_1
    translate_hits = 0, untranslate_hits = 0
4 (nlp_int_tap) to (management) source dynamic nlp_client_0_192.168.118.156_17proto162_intf4 interface  destination static nlp_client_0_ipv4_22 nlp_client_0_ipv4_22 service nlp_client_0_17svc162_21 nlp_client_0_17svc162_21
    translate_hits = 0, untranslate_hits = 0
5 (nlp_int_tap) to (outside) source dynamic nlp_client_0_ipv6_::_17proto53_intf3 interface ipv6  destination static nlp_client_0_ipv6_8 nlp_client_0_ipv6_8 service nlp_client_0_17svc53_7 nlp_client_0_17svc53_7
    translate_hits = 0, untranslate_hits = 0
6 (nlp_int_tap) to (management) source dynamic nlp_client_0_ipv6_::_17proto53_intf4 interface ipv6  destination static nlp_client_0_ipv6_4 nlp_client_0_ipv6_4 service nlp_client_0_17svc53_3 nlp_client_0_17svc53_3
    translate_hits = 0, untranslate_hits = 0
```

By executing the following command, you'll be able to dig into certain kernel details including proccesses and ifconfig of these internal interfaces and nlp_int_tap.
(Ultimately it is showing the ifconfig and all the processes running on the underlaying linux system - ex. going into expert mode on FTD-software and using the "<i>top</i>" or "<i>ifconfig</i>" command)

```
ViftrupLAB01# show kernel ifconfig

<--- Output Omitted --->
  tap_nlp   Link encap:Ethernet  HWaddr 3a:30:28:9b:b3:91  
          inet6 addr: fe80::3830:28ff:fe9b:b391/64 Scope:Link
          inet6 addr: fd00:0:0:1::2/64 Scope:Global
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:216 errors:0 dropped:0 overruns:0 frame:0
          TX packets:315 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:17449 (17.0 KiB)  TX bytes:25410 (24.8 KiB)

tap_nlp:1 Link encap:Ethernet  HWaddr 3a:30:28:9b:b3:91  
          inet addr:169.254.1.2  Bcast:169.254.1.7  Mask:255.255.255.248
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
<--- Output Omitted --->
```

Pay attention to the IP address assigned for the nlp_int_tap interface (169.254.1.2), we'll be getting back to this address as it will show up during our captures.

Also as mentioned earlier we're able to identifiy other kernel processes running on the system, if they communicate with the LINA-engine, they'll utilize the nlp_int_tap interface.
Through proccesses you can also identify if the snmpd (SNMP Daemon used for SNMP functions) is active and running, if the process isn't present on the list below, it either means no SNMP has been configured within LINA (snmpd isn't started if no SNMP configuration is present) or there might be other SNMP process problems - if thats the case, a Cisco TAC case is highly suggested.

<b>ASA</b>
```
ViftrupLAB01# show kernel process

 PID PPID PRI  NI       VSIZE      RSS                WCHAN STAT  RUNTIME    GTIME   CGTIME COMMAND
   1    0  20   0     2347008      748                    1    S      424        0        0 init
   2    0  20   0           0        0                    1    S        0        0        0 kthreadd
   3    2   0 -20           0        0                    1    I        0        0        0 rcu_gp
   4    2   0 -20           0        0                    1    I        0        0        0 rcu_par_gp
   6    2   0 -20           0        0                    1    I        0        0        0 kworker/0:0H-kblockd
   7    2  20   0           0        0                    1    I        0        0        0 kworker/u2:0-events_unbound
   8    2   0 -20           0        0                    1    I        0        0        0 mm_percpu_wq
   9    2  20   0           0        0                    1    S      157        0        0 ksoftirqd/0
  10    2  20   0           0        0                    1    I      949        0        0 rcu_sched
  11    2  20   0           0        0                    1    I        0        0        0 rcu_bh
  12    2  RT   0           0        0                    1    S        0        0        0 migration/0
  13    2  RT   0           0        0                    1    S       57        0        0 watchdog/0
  14    2  20   0           0        0                    1    S        0        0        0 cpuhp/0
  15    2  20   0           0        0                    1    S        0        0        0 kdevtmpfs
  16    2   0 -20           0        0                    1    I        0        0        0 netns
  17    2  20   0           0        0                    1    S        0        0        0 oom_reaper
  18    2   0 -20           0        0                    1    I        0        0        0 writeback
  19    2   0 -20           0        0                    1    I        0        0        0 crypto
  20    2   0 -20           0        0                    1    c        0        0        0 kworker/0:1-events_power_effi
  21    2   0 -20           0        0                    1    I        0        0        0 kblockd
  22    2   0 -20           0        0                    1    I        0        0        0 md
  23    2  RT   0           0        0                    1    S        0        0        0 watchdogd
  24    2  20   0           0        0                    1    S        0        0        0 kswapd0
  25    2   0 -20           0        0                    1    I        0        0        0 kworker/u3:0-kcryptd
  50    2   0 -20           0        0                    1    I        0        0        0 acpi_thermal_pm
  52    2   0 -20           0        0                    1    I        0        0        0 mpt_poll_0
  53    2   0 -20           0        0                    1    I        0        0        0 mpt/0
  54    2  20   0           0        0                    1    S        0        0        0 scsi_eh_0
  55    2   0 -20           0        0                    1    I        0        0        0 scsi_tmf_0
  56    2  20   0           0        0                    1    I      271        0        0 kworker/u2:2-flush-8:16
  57    2   0 -20           0        0                    1    I        0        0        0 ipv6_addrconf
  58    2  20   0           0        0                    1    I     1561        0        0 kworker/0:2-events
  94    1  20   0     5451776     3848                    1    S        5        0        0 udevd
 116    2   0 -20           0        0                    1    I       20        0        0 kworker/0:1H-kblockd
 126    1  20   0     2437120      144                    1    S     1253        0        0 bootlogd
 242    1  20   0    81350656     1556                    0    S      297        0        0 rngd
 441    2   0 -20           0        0                    1    S        0        0        0 loop0
 450    2   0 -20           0        0                    1    I        1        0        0 kworker/u3:1-kcryptd
 452    2   0 -20           0        0                    1    I        0        0        0 kdmflush
 453    2   0 -20           0        0                    1    I        0        0        0 kcryptd_io
 454    2   0 -20           0        0                    1    I        0        0        0 kcryptd
 455    2  20   0           0        0                    1    S        0        0        0 dmcrypt_write
 460    2  20   0           0        0                    1    S        0        0        0 jbd2/dm-0-8
 461    2   0 -20           0        0                    1    I        0        0        0 ext4-rsv-conver
1170    1  20   0     3682304     2648                    1    S        0        0        0 asa_cmd_init
1171    1  20   0     3682304     2736                    1    S     6408        0        0 auth_agent_init
1172    1  20   0     3682304     2556                    1    S        0        0        0 run_cmd
1173    1  20   0     3682304     1116                    1    S        0        0        0 run_adi
1174    1  20   0     3682304     2604                    1    S        0        0        0 run_dnsproxy
1175 1174  20   0    78098432      764                    0    S      519        0        0 dnsproxy-main
1177 1173  20   0   704688128    12056                    0    S    47564        0        0 start-adi
1179 1172  20   0    78319616     2008                    0    S       61        0        0 lina_monitor
1191 1170  20   0   468434944     9908                    0    S      690        0        0 asa_cmd_server.
1224 1179   0 -20  1468571648   776320                    0    S  1196485        0        0 lina
1250 1224   0 -20     3682304     2636                    1    S        0        0        0 sh
1252 1250   0 -20   768540672     5476                    0    S     2852        0        0 smart_agent
1487    1  20   0    12115968     5164                    1    S     2441        0        0 snmpd

```
<b>FTD</b>
```
> show kernel process 
 PID PPID PRI  NI       VSIZE      RSS                WCHAN STAT  RUNTIME    GTIME   CGTIME COMMAND
   1    0  20   0     2347008     1576                    1    S      476        0        0 init
   2    0  20   0           0        0                    1    S        0        0        0 kthreadd
   3    2   0 -20           0        0                    1    I        0        0        0 rcu_gp
   4    2   0 -20           0        0                    1    I        0        0        0 rcu_par_gp
   6    2   0 -20           0        0                    1    I        0        0        0 kworker/0:0H-kblockd
   7    2  20   0           0        0                    1    I        0        0        0 kworker/u8:0-events_unbound
   8    2   0 -20           0        0                    1    I        0        0        0 mm_percpu_wq
   9    2  20   0           0        0                    1    S      337        0        0 ksoftirqd/0
  10    2  20   0           0        0                    1    I     9372        0        0 rcu_sched
  11    2  20   0           0        0                    1    I        0        0        0 rcu_bh
  12    2  RT   0           0        0                    1    S        0        0        0 migration/0
  13    2  RT   0           0        0                    1    S       51        0        0 watchdog/0
  14    2  20   0           0        0                    1    S        0        0        0 cpuhp/0
  15    2  20   0           0        0                    1    S        0        0        0 cpuhp/1
  16    2  RT   0           0        0                    1    S       51        0        0 watchdog/1
  17    2  RT   0           0        0                    1    S        8        0        0 migration/1
  18    2  20   0           0        0                    1    S       62        0        0 ksoftirqd/1
  19    2  20   0           0        0                    1    I        0        0        0 kworker/1:0-mm_percpu_wq
  20    2   0 -20           0        0                    1    I        0        0        0 kworker/1:0H-events_highpri
  21    2  20   0           0        0                    1    S        0        0        0 cpuhp/2
  22    2  RT   0           0        0                    1    S       50        0        0 watchdog/2
  23    2  RT   0           0        0                    1    S        0        0        0 migration/2
  24    2  20   0           0        0                    1    S      180        0        0 ksoftirqd/2
  25    2  20   0           0        0                    1    I        0        0        0 kworker/2:0-mm_percpu_wq
  26    2   0 -20           0        0                    1    I        0        0        0 kworker/2:0H-events_highpri
  27    2  20   0           0        0                    1    S        0        0        0 cpuhp/3
  28    2  RT   0           0        0                    1    S       56        0        0 watchdog/3
  29    2  RT   0           0        0                    1    S        5        0        0 migration/3
  30    2  20   0           0        0                    1    S     5483        0        0 ksoftirqd/3
  31    2  20   0           0        0                    1    I        0        0        0 kworker/3:0-events
  32    2   0 -20           0        0                    1    I        0        0        0 kworker/3:0H-events_highpri
  33    2  20   0           0        0                    1    S        0        0        0 kdevtmpfs
  34    2   0 -20           0        0                    1    I        0        0        0 netns
  37    2  20   0           0        0                    1    S        0        0        0 oom_reaper
  38    2   0 -20           0        0                    1    I        0        0        0 writeback
  39    2   0 -20           0        0                    1    I        0        0        0 crypto
  40    2   0 -20           0        0                    1    I        0        0        0 kblockd
  41    2   0 -20           0        0                    1    I        0        0        0 md
  42    2  RT   0           0        0                    1    S        0        0        0 watchdogd
  43    2   0 -20           0        0                    1    I        0        0        0 rpciod
  45    2   0 -20           0        0                    1    I        0        0        0 xprtiod
  46    2  20   0           0        0                    1    I     1417        0        0 kworker/3:1-events
  47    2  20   0           0        0                    1    I     1512        0        0 kworker/1:1-events
  48    2  20   0           0        0                    1    I     1634        0        0 kworker/2:1-events
  49    2  20   0           0        0                    1    S        0        0        0 kswapd0
  50    2   0 -20           0        0                    1    I        0        0        0 nfsiod
  51    2   0 -20           0        0                    1    I        0        0        0 xfsalloc
  52    2   0 -20           0        0                    1    I        0        0        0 xfs_mru_cache
  73    2   0 -20           0        0                    1    I        0        0        0 kthrotld
  74    2   0 -20           0        0                    1    I        0        0        0 acpi_thermal_pm
  75    2  20   0           0        0                    1    I        0        0        0 kworker/u8:1-events_unbound
  76    2   0 -20           0        0                    1    I        0        0        0 mpt_poll_0
  77    2   0 -20           0        0                    1    I        0        0        0 mpt/0
  78    2  20   0           0        0                    1    S        0        0        0 scsi_eh_0
  79    2   0 -20           0        0                    1    I        0        0        0 scsi_tmf_0
  80    2   0 -20           0        0                    1    I        0        0        0 vfio-irqfd-clea
  81    2   0 -20           0        0                    1    I        0        0        0 ipv6_addrconf
 119    2   0 -20           0        0                    1    I        0        0        0 kworker/u11:0
 129    1  20   0     4120576     2604                    1    S        8        0        0 udevd
 171    2   0 -20           0        0                    1    I      282        0        0 kworker/0:1H-kblockd
 183    2   0 -20           0        0                    1    I        0        0        0 ena
 353    1  20   0   307855360     1652                    0    S     1730        0        0 rngd
 557    2  20   0           0        0                    1    S      299        0        0 jbd2/sda6-8
 558    2   0 -20           0        0                    1    I        0        0        0 ext4-rsv-conver
 563    2  20   0           0        0                    1    S     1433        0        0 jbd2/sda8-8
 564    2   0 -20           0        0                    1    I        0        0        0 ext4-rsv-conver
1562    1  20   0   381329408     6040                    0    S    17913        0        0 syslog-ng
1791    1  20   0   451616768     1932                    0    S     1981        0        0 nscd
2572    1  20   0   399511552    16368                    0    S    15349        0        0 fail2ban-server
3194    1  20   0     2453504     1604                    1    S      600        0        0 sfifd
3316    1  20   0     3338240      188                    1    S        0        0        0 dbus-daemon
3325    1  20   0     7929856     2436                    1    S        0        0        0 sshd
3329    1  20   0     2367488       92                    1    S        0        0        0 acpid
3348    1  20   0     2932736     1972                    1    S        0        0        0 xinetd
3350    1  20   0     6873088     2620                    1    S      109        0        0 crond
3353    1  20   0     3682304     2572                    1    S        0        0        0 asa_cmd_init
3354    1  20   0     3682304     2608                    1    S        0        0        0 init_scp_server
3357    1  20   0     3952640     2864                    1    S     2539        0        0 pmmon.sh
3362 3354  20   0     2342912      744                    1    S        0        0        0 sleep
3369    1  20   0     4247552     2340                    1    S    20921        0        0 pm
3371 3369  25   5   435888128     6048                    0    S  3670191        0        0 loggerd
3372 3369  20   0  2450788352   195140                    0    S    54537        0        0 mariadbd
3383 3369  20   0     6459392     1664                    1    S       78        0        0 sfmb
3388 3369  20   0   134139904    89052                    1    S    16773        0        0 ReconcileState.
3389 3369  20   0   200073216   167776                    1    S   336172        0        0 run_hm.pl
3391 3369  20   0     3764224     2800                    1    S    11812        0        0 bash
3392 3369  20   0     3764224     2844                    1    S    11360        0        0 bash
3393 3369  20   0   155471872     6064                    0    S    10839        0        0 detectionhealth
3394 3369  20   0    12292096     2616                    1    S        0        0        0 rrd_server
3395 3369  10 -10   148701184     5232                    0    S      963        0        0 sfhassd
3396 3369  20   0  1183531008     3952                    0    S     8113        0        0 diskmanager
3397 3369  20   0  1616191488    66520                    0    S    93119        0        0 adi
3398 3369  20   0   145952768     4780                    0    S     1807        0        0 bltd
3399 3369  20   0     9748480     1852                    1    S     6208        0        0 pdts_proc
3400 3369   1 -19   222703616     5840                    0    S    43628        0        0 ndmain.bin
3401 3369   1 -19   637607936     6196                    0    S    17707        0        0 ndclientd
3402 3369  20   0     4034560     3056                    1    S     4288        0        0 syslog-ng
3403 3369  20   0     4034560     2960                    1    S     2724        0        0 sfifd
3404 3369  20   0     2523136      640                    1    S        0        0        0 rdnssd
3405 3369  20   0     1261568      844                    1    S        2        0        0 consoled
3407 3369  20   0    12087296     7052                    1    S      239        0        0 cgroup_monitor.
3441 3353  20   0   163827712    10280                    0    S      297        0        0 asa_cmd_server.
3541 3405  20   0    74158080     2064                    0    S       76        0        0 lina_monitor
3555 3404  20   0     2605056     1348                    1    S        0        0        0 rdnssd
3696 3541   0 -20  2619969536  1161472                    0    S  2036733        0        0 lina
3697 3541  20   0     7421952     2040                    1    S      328        0        0 offload_app
3710    2   0 -20           0        0                    1    I        0        0        0 kworker/1:1H-events_highpri
3711    2   0 -20           0        0                    1    I        0        0        0 kworker/3:1H-events_highpri
3712    2   0 -20           0        0                    1    I        0        0        0 kworker/2:1H-events_highpri
3851 3369  20   0    15605760     6408                    1    S     2410        0        0 fpcollect
3852 3369  20   0   201322496   189724                    1    S    18987        0        0 Syncd.pl
3853 3369  20   0   192659456   180640                    1    S    45492        0        0 Pruner.pl
3854 3369  20   0    89841664    81880                    1    S     3359        0        0 ActionQueueScra
3855 3369  20   0    93437952    85684                    1    S     1019        0        0 rotate_stats.pl
3856 3369  25   5   503795712    19824                    0    S      722        0        0 EventHandler
3867 3369  20   0  2405916672   245804                    0    S   421421        0        0 SFDataCorrelato
3868 3369  20   0    65400832    56976                    1    S     1587        0        0 expire-session.
3869 3369  20   0    69767168    58560                    1    S    12265        0        0 TSS_Daemon.pl
3870 3369  20   0    74510336    65156                    1    S      300        0        0 snapshot_manage
4380    1  20   0     6762496     4048                    1    S        2        0        0 login
4381    1  20   0     2461696     1628                    1    S        0        0        0 agetty
4385 3369   1 -19  1378750464   625204                    0    S  1726916        0        0 snort3
4386 3369  20   0  3804303360   142096                    0    S   101816        0        0 java
4387 3369  20   0   152887296     6128                    0    S     1806        0        0 ASAConfig
4388 3369  20   0  5678223360    26488                    0    S    24579        0        0 telegraf
4401 4385   1 -19     7938048     1728                    0    S        0        0        0 snort3_crash_ha
4989 4380  20   0    61247488     8948                    1    S        3        0        0 clish
5021 3369  20   0    47255552    39080                    1    S      702        0        0 ntpd.pl
5268 5021  20   0    76234752     4264                    1    S     1263        0        0 ntpd
9771    2  20   0           0        0                    1    I     1770        0        0 kworker/u10:2-events_unbound
10801    2  20   0           0        0                    1    I     7435        0        0 kworker/0:1-events
13380 3369  20   0   280854528     7188                    0    S    96115        0        0 sftunnel
13381 3369  20   0   412676096     3740                    0    S     3945        0        0 sfmgr
13382 3369  20   0   140853248     1916                    0    S     2461        0        0 sfmbservice
13383 3369  20   0    75812864     1756                    0    S     3380        0        0 sfipproxy
15013    2  20   0           0        0                    1    I        0        0        0 kworker/u10:1-events_unbound
17015 3325  20   0     8335360     6324                    1    S        1        0        0 sshd
17060 3403  20   0     2355200      200                    1    S        0        0        0 sleep
17102 17015  20   0     8335360     4436                    1    S        0        0        0 sshd
17103 17102  20   0    57053184     8728                    1    S        4        0        0 clish
17109 3357  20   0     2342912      688                    1    S        0        0        0 sleep
17185 3357  20   0     2342912      688                    1    c        0        0        0 kworker/0:0-events_power_effi
17205 17103  20   0    57053184     3572                    1    S        0        0        0 clish
17206 17103  20   0     3682304     2640                    1    S        0        0        0 sh
17207 17206  20   0     8572928     4632                    1    S        0        0        0 sudo
17208 17207  20   0    44507136    41080                    1    S       28        0        0 sfcli.pl
17211 3402  20   0     4034560     1972                    1    S        0        0        0 syslog-ng
17212 17211  20   0     3371008     2072                    1    S        0        0        0 top
17213 17211  20   0     2867200      232                    1    S        0        0        0 grep
17214 17211  20   0     2494464      208                    1    S        0        0        0 sed
17215 17211  20   0     5058560     2512                    1    S        0        0        0 awk
17216 3392  20   0     2355200      756                    1    S        0        0        0 sleep
17217 3391  20   0     2355200      696                    1    S        0        0        0 sleep
17218 17208  20   0    94416896     3488                    0    S        0        0        0 ConvergedCliCli
20719 17208  20   0    94416896     3488                    0    c        0        0        0 kworker/0:2-events_power_effi
```
It is clear due to the big technology stack within the FTD it is utilizing a lot of proccesses on the side, inorder to ensure stability and feature-set.

<h3>When to use the nlp_int_tap for captures?</h3>
As seen in the previous section the nlp_int_tap is a huge part of the functionaility both on the ASA and FTD platform.

Now we can use this information for troubleshooting some of these processes, if we encounter issues which is being transmitted on this internal backplane between processes and the LINA.

In the coming example we'll be looking into capturing and troubleshooting problems in regards to SNMP (ASA) - this would be the same procedure if you were to do capture on FTD ex. for sftunnel tshoot, however FTD has other built-in capture capabilities as well (capture-traffic for one)

<h4>Troubleshooting SNMP packets with nlp_int_tap on ASA</h4>
If we're encountering issues in getting connectivity between ASA and an NMS it might be worthwhile looking into capturing packets on the ASA. There are several ways in doing so, one of them would be to perform packet capture on the nlp_int_tap interface, as we know this interface is the internal backplane used between the non-LINA process snmpd and towards ASA/egress interface to the NMS.

When we do ingress capture on the nlp_int_tap interface we'll see the raw packets coming from the snmpd, which also means it will be sourced directly from the internal IP we discovered earlier (169.254.1.2) - if we're not seeing any packets on this interface/capture it means no SNMP traffic at all is flowing between the LINA-engine and the underlay snmpd process. 
Depending on the direction, it might be internal problems within the appliance or simply due to firewall(s) or misconfiguration on either end. Any SNMP traffic flowing at all, will at all times tverese this interface and capture.

In the example below I have setup a simple packet capture with nlp_int_tap being the ingress interface and my egress interface towards my endpoint running snmpwalk.

```
ViftrupLAB01# show capture nlp_cap_ingress 

   1: 13:07:39.652111       10.1.100.10.62685 > 169.254.1.2.161:  udp 40 
   2: 13:07:39.653637       169.254.1.2.161 > 10.1.100.10.62685:  udp 94 
   3: 13:07:39.745673       10.1.100.10.62685 > 169.254.1.2.161:  udp 43 
   4: 13:07:39.773839       169.254.1.2.161 > 10.1.100.10.62685:  udp 52 
```
Notice that as we're capturing on the nlp_int_tap interface the traffic is hitting the internal backplane 169.254.1.2 address.

If we look on the egress part (traffic has now been transmitted from nlp_int_tap backplane into the ASA / LINA-engine and vice versa)
```
ViftrupLAB01# show capture nlp_cap_egress  

   1: 13:07:39.651806       10.1.100.10.62685 > 10.1.0.1.161:  udp 40 
   2: 13:07:39.653667       10.1.0.1.161 > 10.1.100.10.62685:  udp 94 
   3: 13:07:39.745505       10.1.100.10.62685 > 10.1.0.1.161:  udp 43 
   4: 13:07:39.773885       10.1.0.1.161 > 10.1.100.10.62685:  udp 52 
```
The address 10.1.0.1 is the ASA management interface which I'm doing the snmpwalk towards. This also confirms data is being transmitted from the LINA-engine and onto my endpoint. Which confirms we're having successful SNMP operations.

```
SNMPv2-MIB::sysDescr.0 = STRING: Cisco Adaptive Security Appliance Version 9.16(3)23
```

As seen we can by utilizing the nlp_int_tap interface get a bit deeper into the troubleshooting and packets happening, and also another way to verify what happens to the SNMP packets if you were to do test directly from the ASA. These captures can help in future investigation and even to engage Cisco TAC if problem should persist and seems to be on the ASA side.

Normally you would be able to identify firewall configuration problems during simple captures, however in certain situtations and senarios you might want to try capture directly on the nlp_int_tap for full flow visibility.
