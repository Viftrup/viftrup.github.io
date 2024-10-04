---
layout: post
title: "Deploying branches with Cisco FTD and device templates"
author: Alexander Viftrup Andersen
categories: [Secure Firewall, Security, API]
cover: "/assets/pictures/secure-firewall-locked.png"
image: "/assets/pictures/secure-firewall-locked-linkedin-size.png"
published: true
---
<fieldset style="background-color:#FFFFCC;">
  <p><b>Note:</b> As of the time of writing, this feature is only supported on FMC 7.6+, FTD 7.4+, and on physical appliances 1000-, 1200-, and 3100-series (clustering, multi-instances, and failover configurations not supported). </p>
</fieldset>

Imagine if you could do (almost) zero-touch deployments of your branches with Cisco FTDs, even combined with the possibility to include FTD SD-WAN setup. 
And on top of this, imagine if you could streamline the FTD registration on the FMC with templates and custom variables through API.


As Cisco recently released the Secure Firewall Threat Defense version 7.6, this is now a reality, with a native feature set for Device Templates within the FMC and with APIs supporting registration of FTDs combined with templates, including custom variables and network overrides.

Ideally, this means doing branch deployments with FTDs has never been easier. 
Adding on top of that, we’re now able to register devices via hardware serial numbers as well (not covered in this post, yet) - YES, even for on-prem if a connection to Cisco Security Cloud has been established – this does <b>NOT</b> require you to be fully cloud deployed.

<fieldset style="background-color:#FFFFCC;">
  <p><b>Note:</b> Cisco Security Cloud Integration is formerly known as the SecureX integration. As SecureX has been deprecated, this was replaced. Security Cloud has a larger suite of features and products, but most people would know this as CDO for instance. In the coming months, CDO will be rebranded as Security Cloud Control (SCC) with an AI-First approach including several other feature enhancements and integrations to other Cisco products. </p>
</fieldset>

<h1>Getting Started with Template Management</h1>

I am not going into every single configuration item but instead provide the fundamentals and basic understanding of how this can be utilized and scaled for larger deployments.

There are three different ways of getting started with the first template, as follows:
1.	Create a new template from scratch
2.	Generate a template from an existing device
3.	Export the SFO template from an existing environment

I will mainly be focusing on the first approach, which is from scratch, and explain how to export and import this at a later stage. 
However, generating the template from an existing device might require looking into some configuration guides, as it is not done within the Template Management section, but instead at the Device Management section.

<b>Device Management -> Desired Device -> Click the three dots -> Select “Generate Template from Device”</b>

<h1>Creating a New Template from Scratch</h1>

The new Template Management section is to be found under the <i>Devices</i> tab. 

When creating a template, a desired name is required along with the ACP which will be attached to the template. 

Beware that you’re not redirected into the template configuration right away, and the creation will spawn a job within the FMC – this usually takes a few seconds and afterwards you’re able to navigate into the template settings.

<h2>Interfaces and Variables</h2>
Once the template has been created, the first section will display the “Interfaces” configuration, and by default with a very limited set of physical interfaces. 
By selecting the <i>“Add Physical Interfaces”</i> we can add additional interfaces into our configuration by selecting the slot and port index (I believe in future releases we’ll get the possibility to select other slots for additional NetMods).

As usual when operating with Secure Firewall Threat Defense, we’re also able to select <i>“Add Interface”</i> which displays a dropdown menu with extra interface features such as; Sub-Interface, Etherchannel, VLAN, VTI, and Loopbacks.

Interface configuration looks exactly like we’re used to, however, there is a change within the IPv4 and IPv6 sections when assigning “static” values – the first set of variables comes to life here.
This means instead of assigning an actual IP within my template, I can instead use a variable which I will be required to fill out during registration of a new device with this exact template.

To create this variable, you must click on the “+”-sign next to the IP address. The name you specify will be the name of our variable, so for ease of use make it self-explanatory, e.g., inside_ip.
<i>(Every time you see the variable sign (X), this means we can create variables for this function).</i>

If you’re unfamiliar with variables in general, a variable is often referred to by a “dollar-sign” aka $.

Make sure to do this for all the interfaces you intend to create for your template, including etherchannels and sub-interfaces if you need such. By utilizing the variables feature, your deployments will be a breeze and easy to use.

<i>Important: In order to minimize the manual intervention during deployment and future support, be sure your outside interface(s) is enabled for Manager Access. Even if your appliances have a separate management interface, it is required to use a data-interface for FMC connectivity.</i>

<h2>Routing and Use of Variables with Network-Objects and Overrides</h2>
Now that you’ve created your interfaces and you’re familiar with the benefits of variables, let’s continue onto the routing sections. 
Especially in this section, variables come in handy once again, this time for routing and network-objects used in my template.

In my template, I am keeping it old school by doing static routing, however, if you are using BGP many things within the BGP settings are also configurable via variables, e.g., ASN and Router ID.

If you’re deploying Cisco FTD SD-WAN, this would also be the section to configure Policy-Based Routing within your template.





----------------
------------
--------

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
