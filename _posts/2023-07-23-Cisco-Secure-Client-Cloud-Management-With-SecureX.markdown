---
layout: post
title: "Using SecureX to maintain versions, profiles and modules within Secure Client installations"
author: Alexander Viftrup Andersen
categories: [Secure Client, SecureX, Security]
---
Last year Cisco re-branded their famous and most broadly known VPN product AnyConnect into the Cisco Secure Client (CSC). 

While AnyConnect and its modules is still exactly the same, the new CSC improves the possibilities now and in the future.
One of the great features of CSC is the possibility to deploy the new "Cloud Management" (CM) module, which allows deep integration within the Cisco SecureX portal. (And ZTNA which is exciting!)

<h3>What is Cisco SecureX?</h3>
SecureX was launched in 2020 but is still unknown for a lot of IT professionals, even though it provides great capabilities and as a bonus - **it is free** if you're already an user of Cisco Secure products (Secure Firewall, Endpoint, Email, Umbrella and more)

In short terms SecureX is a unified-experience between your suite of Cisco Secure products, by being able to integrate your products (Cisco Secure and selected 3rd party) into one unified dashboard, gaining insights and easy cross-reference between your security suite.
On top of that the integration of SecureX Orchestration enables your SecOps and NetOps to work closely together and enables both visibility and automation for both teams - being across network, endpoints or cloud.

<h3>Keep Secure Client versions and profiles up-to-date through SecureX</h3>
_Keep in mind this only works on endpoints running CSC - this is not possible with any Cisco AnyConnect versions_

Anyone which has been configuring and maintaining AnyConnect deployments, that being profiles or versions knows it can be an uphill battle to keep systems and profiles up to date at times.
That either being packet deployment from SCCM or through ASA, FTD or ISE for XML-profiles and packages updated.

This is still doable, however with the SecureX, CSC and combined with a new module "Cloud Management" (CM) it is now possible to keep all this administration (or subset of) within the SecureX cloud.
Together with this module we're able to pull certain data about the endpoints as well, and feed this into SecureX Device Insights.

While SecureX and the Cloud Management-module can keep both profiles and packages up to date there is two kind of deployment methods:
  1. Full Cloud Management
     - CM handles all package management
     - Control all profile configuration and module management in the cloud through SecureX portal
     - Possibility to use Full or Network Installer when deploying new agents

  2. Cloud Registraion without Package Management
     - CM would be registered and data feed into SecureX Device Insights and en-rollment for ZTNA (Exicting Secure Access feature coming)
     - Packages and profiles will still need to be maintained through SCCM, ASA, FTD, ISE etc.

<h3>Brief look into the portal and configuration</h3>
As previously mentioned it is possible to control all the regular profiles within the SecureX platform, just like if you were to create profile within an ASA, FTD or through the VPN Profile Editor.
Its also possible to upload existing XML profiles directly into the portal and migrate into the SecureX platform instead. (Be advised that some sections still require manual upload or some interaction with another portal - ex. Umbrella for getting the OrgInfo.json - rumours states it will be integrated directly into SecureX at some point, like Secure Endpoint feeds and links directly)
<Insert VPN Deployment Picture>


The important profile section regardless of the deployment method is the Cloud Management Profile, this profile is used to enable and change settings specific for the CM module.
Current check-in interval cannot be lower than 2 hours (rumours states this will be possible to decrease in the future - however do not expect it to go under 30 minutes)
In the far buttom there's the possibility to schedule windows for updating the client, modules and profiles.
<Insert CM Profile Picture>


Once all nessesary profiles has been created the last step is to setup a deployment which will utilize the modules and created profiles depending on the deployment function. (This is kind of similiar to creating group-policy and defining the needed modules and profiles to be included)
Like with AnyConnect all modules rely on the same version to be running as AnyConnect, hence you'll not be able to select specific versions per module - expect for the CM and Secure Endpoint modules. Secure Endpoint integrates directly into the SecureX platform from Secure Endpoint portal, so you can select your instance and desired group directly in the SecureX platform.
<Insert Small Deployment with dropdown picture>

For versions the following is possible and notable:
    <li><b>Latest:</b>This is the latest version available on the Cisco Support site.</li>
    <li><b>Recommended:</b> This is the current recommended/suggested version available on the Cisco Support site.</li>
    <li> <b>Version specific:</b> Hardcore the desired version to be running on this deployment.</li>
Keep in mind, if you change versions within an deployment which has been rolled out for users, it'll affect the clients once the CM module check-in timer hits.





<hr></hr>

![HTTPS Facebook.com Umbrella certificate](/assets/pictures/facebook-umbrella-certificate.png)

If all webservers were allowed to do a “man-in-the-middle” attack such as this, we would be facing a major problem. It would potentially allow any webserver to pose as your bank’s webserver for example. To mitigate this your web browser must trust the issuing certificate server. 

The Umbrella Root CA is not automatically trusted by computers and browsers (that is the issuer of the certificate), meaning that without any certificates manually stored on the endpoint or pushed through MDM/GPOs the redirect of Umbrella would present the famous "Your connection is not secure/private" due to the certificate-chain not being trusted. And the company of course had security awareness training of employees learning that they should <b>never</b> bypass such warning.

And since over 80% of today’s webservers enforce the HTTPS protocol, this would be a common scenario. In order to make this efficient, it is highly recommended to push the "middle-man" (Umbrella certificate in this case) onto the company machines either through MDM-software or Group Policies in AD.

For BYOD (Bring Your Own Device) scenarios where you're not in charge of the systems, there unfortunately isn't any possibility to have this block page shown efficiently over a HTTPS connection. Unless manually trusting the certificate or proceeding through the warning.

<h2>Closing remarks</h2>
This will be the scenario no matter if you're using Cisco Umbrella or another 3rd part solution for this kind of DNS/block page protection.
Including the consumer-friendly [Pi-Hole](https://pi-hole.net/) solution.

As frustrating as it might seems, this is for the greater good and by the standard of the HTTPS protocol.
