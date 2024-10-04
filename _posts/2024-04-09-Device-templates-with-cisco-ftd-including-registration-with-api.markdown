---
layout: post
title: "Deploying branches with Cisco FTD and device templates"
author: Alexander Viftrup Andersen
categories: [Secure Firewall, Security, API]
cover: "/assets/pictures/secure-firewall-locked.png"
image: "/assets/pictures/secure-firewall-locked-linkedin-size.png"
published: false
---
<fieldset style="background-color:#FFFFCC;">
  <p><b>Note:</b> As of the time of writing, this feature is only supported on FMC 7.6+, FTD 7.4+, and on physical appliances 1000-, 1200-, and 3100-series (clustering, multi-instances, and failover configurations not supported).
<br>
</p>
</fieldset>

Imagine if you could do (almost) zero-touch deployments of your branches with Cisco FTDs, even combined with the possibility to include FTD SD-WAN setup. 
And on top of this, imagine if you could streamline the FTD registration on the FMC with templates and custom variables through API.


As Cisco recently released the Secure Firewall Threat Defense version 7.6, this is now a reality, with a native feature set for Device Templates within the FMC and with APIs supporting registration of FTDs combined with templates, including custom variables and network overrides.









First of all, there is multiple ways to perform such password recovery/reset for the static admin user, this is just one of many methods to do so.

This specific method however doesn't require any physical interaction with the appliance, downtime on the system or knowledge of the current password for the admin user.

<h1>Initial procedure - Configuration of external authentication</h1>

Navigate into the FMC which holds the manager role for the specific FTD(s) you want to perform the recovery on.

Under <b>System -> Users -> External Authentication</b> make sure you have created either an LDAP or RADIUS object with working configuration, desired filtering for CLI access and your user has suffient and correct privileges for SSH/CLI.

Next step is either to create a new platform setting policy, or alter the platform setting currently applied to the desired FTD(s).

Under the <b>External Authentication</b> tab the previous mentioned external authentication object should be present, make sure to enable it and deploy the change to the FTD(s).

<a href="//blog.viftrup.eu/assets/pictures/platform-settings-external-auth.png" data-lightbox="platform-settings-large" data-title="Platform settings"> 
  <img src="//blog.viftrup.eu/assets/pictures/platform-settings-external-auth.png" title="Click to enlarge - Platform Settings"> 
</a>

Once deployment is successful, you should be able to SSH into your FTD and use your credentials from the external authentication provider configured. <br><i>(If this is unsuccessful, go back into the external authentication page and perform an authentication test on the very buttom of the page to ensure your credentials is correct and mapped to the desired filtering for CLI access)</i>


<h1>Resetting the admin password</h1>

Once logged in through external authentication, the actual magic can be performed in order to reset the password for the admin user.

First we need to access the linux shell and elevate our access rights, this is done by typing ```expert``` and elevate through ```sudo -i``` followed by your <b>external authentication password</b> - in other words, the same password you used in order to access the SSH itself.

Once we've elevated our privileges the fun can begin, and we can reset the admin password.

Type ```passwd admin``` <br>
Next you'll be prompted for the new desired password, type in the password you want going forward - a confirmation prompt will follow in order to ensure the passwords match.

```
> expert
ava-ftd01:~$ pwd    
/ngfw/Volume/home/bob-admin <--- Verify I am logged in as external user
ava-ftd01:~$ sudo -i
Password: <Password-of-bob-admin-ext-user>
root@ava-ftd01:~# passwd admin
New password: <New-admin-password>
Retype new password: <New-admin-password>
passwd: password updated successfully
root@ava-ftd01:~#
```

Once this has been done you've successfully recovered/reset the admin password, and you should be able to initiate another SSH session to the FTD and able to login as "admin" with your new password.

```
> expert
admin@ava-ftd01:~$ pwd
/home/admin <--- Verify I am logged in as admin user
```


I highly suggest keeping the external authentication enabled as this makes onboarding and off-boarding of new employees a lot easier and also the audting part will be much easier. Just make sure you've limited the access for CLI to a specific security group / OU within your environment.
