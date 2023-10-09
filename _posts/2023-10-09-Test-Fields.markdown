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

<h1>Procedure</h1>

Navigate into the FMC which holds the manager role for the specific FTD(s) you want to perform the recovery on.

Under <b>System -> Users -> External Authentication</b> make sure you have created either an LDAP or RADIUS object with working configuration, desired filtering for CLI access and your user has suffient and correct privileges for SSH/CLI.

Next step is either to create a new platform setting policy, or alter the platform setting currently applied to the desired FTD(s).

Under the <b>External Authentication</b> tab the previous mentioned external authentication object should be present, make sure to enable it and deploy the change to the FTD(s).

.... Insert image showcase ....

Once deployment is successful, you should be able to SSH into your FTD and use your credentials from the external authentication provider configured. <br><i>(If this is unsuccesful, go back into the external authentication page and perform an authencation test on the very buttom of the page to ensure your credentials is correct and mapped to the desired filtering for CLI acess)</i>
