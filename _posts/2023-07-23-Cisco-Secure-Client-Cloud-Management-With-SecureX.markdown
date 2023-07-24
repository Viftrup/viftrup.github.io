---
layout: post
title: "Maintain Secure Client configurations and package management with SecureX"
author: Alexander Viftrup Andersen
categories: [Secure Client, SecureX, Security]
cover: "/assets/pictures/SecureX-CSC-Cloud.png"
---
Last year, Cisco rebranded their famous and widely known VPN product, AnyConnect, into the Cisco Secure Client (CSC).

While AnyConnect and its modules are still exactly the same, the new CSC improves the possibilities now and in the future.
One of the great features of CSC is the capability to deploy the new "Cloud Management" (CM) module, which allows deep integration within the Cisco SecureX portal (and ZTNA, which is exciting!).

<h3>What is Cisco SecureX?</h3>
SecureX was launched in 2020 but is still unknown to many IT professionals, even though it provides great capabilities and, as a bonus, **it is free** if you're already a user of Cisco Secure products (Secure Firewall, Endpoint, Email, Umbrella, and more).

In short terms, SecureX is a unified experience between your suite of Cisco Secure products, by being able to integrate your products (Cisco Secure and selected 3rd party) into one unified dashboard, gaining insights and easy cross-reference between your security suite.
On top of that, the integration of SecureX Orchestration enables your SecOps and NetOps to work closely together and enables both visibility and automation for both teams - being across network, endpoints, or cloud.

<h3>Keep Secure Client versions and profiles up-to-date through SecureX</h3>
_Keep in mind this only works on endpoints running CSC - this is not possible with any Cisco AnyConnect versions_

Anyone who has been configuring and maintaining AnyConnect deployments, whether profiles or versions, knows it can be an uphill battle to keep systems and profiles up to date at times.
That can either be packet deployment from SCCM or through ASA, FTD, or ISE for XML profiles and packages updated.

This is still doable; however, with the SecureX + CSC, and combined with a new module "Cloud Management" (CM), it is now possible to keep all this administration (or a subset of it) within the SecureX cloud.
Together with this module, we're able to pull certain data about the endpoints as well and feed this into SecureX Device Insights.

While SecureX and the Cloud Management-module can keep both profiles and packages up to date, there are two kinds of deployment methods:

  **1. Full Cloud Management**
  - CM handles all package management
  - Control all profile configuration and module management in the cloud through SecureX portal
  - Possibility to use Full or Network Installer when deploying new agents

  **2. Cloud Registraion without Package Management**
  - CM would be registered and data fed into SecureX Device Insights and enrollment for ZTNA (Exciting Secure Access feature coming)
  - Packages and profiles will still need to be maintained through SCCM, ASA, FTD, ISE, etc.


Be advised if you're already using other means of web-headends for maintaining profiles, it can override your configurations set by SecureX - the rule of thumb is you should only have <b>one</b> system controlling the profile configurations.

<h3>A brief look into the portal and configuration</h3>
As previously mentioned, it is possible to control all the regular profiles within the SecureX platform, just like if you were to create a profile within an ASA, FTD, or through the VPN Profile Editor.
It's also possible to upload existing XML profiles directly into the portal and migrate them into the SecureX platform instead. (Be advised that some sections still require manual upload or some interaction with another portal - ex. Umbrella for getting the OrgInfo.json - rumors state it will be integrated directly into SecureX at some point, like Secure Endpoint feeds and links directly).

<a href="//viftrup.github.io/assets/pictures/vpn-profile-deployment.png" data-lightbox="vpn-profile-large" data-title="VPN Profile Deployment"> <img src="//viftrup.github.io/assets/pictures/vpn-profile-deployment.png" title="Click to enlarge - VPN Profile Deployment"> </a>


The important profile section, regardless of the deployment method, is the Cloud Management Profile. This profile is used to enable and change settings specific to the CM module.
The current check-in interval cannot be lower than 2 hours (rumors state this will be possible to decrease in the future - however, do not expect it to go under 30 minutes)
At the far bottom, there's the possibility to schedule windows for updating the client, modules, and profiles.
<a href="//viftrup.github.io/assets/pictures/cloud-management-profile.png" data-lightbox="cloud-management-profile" data-title="Cloud Management Profile"> <img src="//viftrup.github.io/assets/pictures/cloud-management-profile.png" title="Click to enlarge - Cloud Management Profile"> </a>


Once all necessary profiles have been created, the last step is to set up a deployment that will utilize the modules and created profiles depending on the deployment function. (This is kind of similar to creating group-policy and defining the needed modules and profiles to be included)
Like with AnyConnect, all modules rely on the same version to be running as AnyConnect; hence, you'll not be able to select specific versions per module - except for the CM and Secure Endpoint modules. Secure Endpoint integrates directly into the SecureX platform from the Secure Endpoint portal, so you can select your instance and desired group directly in the SecureX platform.
<a href="//viftrup.github.io/assets/pictures/small-deployment-dropdown.png" data-lightbox="small-deployment-dropdown" data-title="Deployment"> <img src="//viftrup.github.io/assets/pictures/small-deployment-dropdown.png" title="Click to enlarge - Deployment"> </a>


For versions, the following is possible and notable:
- <b>Latest:</b> This is the latest version available on the Cisco Support site.
- <b>Recommended:</b> This is the current recommended/suggested version available on the Cisco Support site.
- <b>Version specific:</b> Hardcode the desired version to be running on this deployment.
    
<i>Keep in mind that if you change versions within a deployment that has been rolled out for users, it'll affect the clients once the CM module check-in timer hits.</i>

On this deployment page, you can either download the "Full Installer" or "Network Installer":
- <b>Full Installer:</b> This includes all profiles and modules required by the specific deployment - this will be larger in size than the Network Installer.
- <b>Network Installer:</b> This is a lightweight installer that only contains the Cloud Management module and registration to the SecureX portal. Once installed, it requests a manifest from SecureX about profiles and modules needed for the specific deployment.

<h3>Device Insights and changing deployment profiles on the fly</h3>
Once an endpoint has registered to SecureX through the CM module, it will be feeding data into the Device Insights tab about that specific endpoint and CSC attributes.
<a href="//viftrup.github.io/assets/pictures/securex-device-inventory.png" data-lightbox="securex-device-inventory" data-title="Device Inventory"> <img src="//viftrup.github.io/assets/pictures/securex-device-inventory.png" title="Click to enlarge - Device Inventory"> </a>
In this tab, it is also possible, on the fly, to change the deployment that is present on the endpoint. For example, change our current deployment from "IT Deployment" to "IT Beta - Deployment" - this will change modules and profiles once the CM check-in timer has been reached and re-configure our CSC as desired by the selected deployment policy.
<a href="//viftrup.github.io/assets/pictures/securex-move-deployment.png" data-lightbox="securex-move-deployment" data-title="Device Deployment Move"> <img src="//viftrup.github.io/assets/pictures/securex-device-inventory.png" title="Click to enlarge - Move Device Deployment"> </a>
No more manual connecting into new VPN profiles or the need for pushing/reconfiguring new GPOs to the endpoints anymore for changing settings!

<a href="//viftrup.github.io/assets/pictures/securex-move-deployment.png" data-lightbox="securex-move-deployment" data-title="Device Deployment Move"> <img src="//viftrup.github.io/assets/pictures/securex-device-inventory.png" title="Click to enlarge - Move Device Deployment"> </a>
Each registered device with CM feeds certain data into the SecureX portal, including basic device information along with CSC information (Other feeds like InTune, Jamf, and more can also be integrated but go beyond this article).

This is only a brief summary of what SecureX and CSC together can do - I highly recommend the Cisco Live presentation below for a deep dive into the possibilities.<br>
Even if you're not in for a deep dive, give it a glance anyway; the speaker Aaron is hilarious and talks directly from his personal opinion.


<b>Recommended resources:<b>

<a href="https://www.ciscolive.com/on-demand/on-demand-details.html?#/session/1686177803567001VAM7">BRKSEC-2834 - Cisco's Unified Agent: Cisco Secure Client. Bringing AMP, AnyConnect, Orbital & Umbrella together </a>

<a href="https://docs.securex.security.cisco.com/SecureX-Help/Content/introduction.html">Cisco SecureX - Getting Started</a>
