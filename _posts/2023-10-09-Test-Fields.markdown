---
layout: post
title: "Fieldsets 123"
author: Alexander Viftrup Andersen
categories: [Secure Firewall, Security]
cover: ""
image: ""
published: true
---
<fieldset style="background-color:#FFFFCC;">
  <h4>Please note:</h4>
  <p>This is only related to FTD and expert-shell, this will not be related to ex. the Chassis Manager on 4100/9300-series.
<br>

    
  It is required that you're able to push platform setting policies to the device(s) and possibility for external SSH authentication either through LDAP or RADIUS in order to perform this kind of recovery</p>
</fieldset>

First of all, there is multiple ways to perform such password recovery/reset for the static admin user, this is just one of many methods to do so.

This specific method however doesn't require any physical interaction with the appliance, downtime on the system or knowledge of the current password for the admin user.

<h1>Initial procedure - Configuration of external authentication</h1>

Navigate into the FMC which holds the manager role for the specific FTD(s) you want to perform the recovery on.

Under <b>System -> Users -> External Authentication</b> make sure you have created either an LDAP or RADIUS object with working configuration, desired filtering for CLI access and your user has suffient and correct privileges for SSH/CLI.

Next step is either to create a new platform setting policy, or alter the platform setting currently applied to the desired FTD(s).

Under the <b>External Authentication</b> tab the previous mentioned external authentication object should be present, make sure to enable it and deploy the change to the FTD(s).

.... Insert image showcase ....

Once deployment is successful, you should be able to SSH into your FTD and use your credentials from the external authentication provider configured. <br><i>(If this is unsuccessful, go back into the external authentication page and perform an authencation test on the very buttom of the page to ensure your credentials is correct and mapped to the desired filtering for CLI acess)</i>


<h1>Resetting the admin password</h1>

Once logged in through external authentication, the actual magic can be performed in order to reset the password for the admin user.

First we need to access the linux shell and elevate our access rights, this is done by typing ```expert``` and elevate through ```sudo -i``` followed by your <b>external authentication password</b> - in other words, the same password you used in order to access the SSH itself.

Once we've elevated our privileges the fun can begin, and we can reset the admin password.

Type ```passwd admin``` <br>
Next you'll be prompted for the new desired password, type in the password you want going forward - a confirmation prompt will follow in order to ensure the passwords match.

```
> expert
ava-ftd01:~$ pwd    
/ngfw/Volume/home/bob-admin
ava-ftd01:~$ sudo -i
Password: 
root@ava-ftd01:~# passwd admin
New password: 
Retype new password: 
passwd: password updated successfully
root@ava-ftd01:~#
```

Once this has been done you've successfully recovered/reset the admin password, and you should be able to initiate another SSH session to the FTD and able to login as "admin" with your new password.

```
> expert
admin@ava-ftd01:~$ pwd
/home/admin
```


I highly suggest keeping the external authentication enabled as this makes onboarding and off-boarding of new employees a lot easier and also the audting part will be much easier. Just make sure you've limited the access for CLI to a specific security group / OU within your environment.
