---
layout: post
title: "Branch deployment using templates on Cisco FTD - including API registration"
author: Alexander Viftrup Andersen
categories: [Secure Firewall, Security, API]
cover: "/assets/pictures/secure-firewall-locked.png"
image: "/assets/pictures/template-management/branch-deployment-linkedin.png"
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

<h1>Getting started with Template Management</h1>

I am not going into every single configuration item but instead provide the fundamentals and basic understanding of how this can be utilized and scaled for larger deployments.

There are three different ways of getting started with the first template, as follows:
1.	Create a new template from scratch
2.	Generate a template from an existing device
3.	Export the SFO template from an existing environment

I will mainly be focusing on the first approach, which is from scratch, and explain how to export and import this at a later stage. 
However, generating the template from an existing device might require looking into some configuration guides, as it is not done within the Template Management section, but instead at the Device Management section.

<b>Device Management -> Desired Device -> Click the three dots -> Select “Generate Template from Device”</b>
<a href="//blog.viftrup.eu/assets/pictures/template-management/template-from-device.png" data-lightbox="template-from-device-large" data-title="Generate template from device"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/template-from-device.png" title="Click to enlarge - template from device"> 
</a>

<h1>Creating a new template from scratch</h1>

The new Template Management section is to be found under the <i>Devices</i> tab. 

When creating a template, a desired name is required along with the ACP which will be attached to the template. 

Beware that you’re not redirected into the template configuration right away, and the creation will spawn a job within the FMC – this usually takes a few seconds and afterwards you’re able to navigate into the template settings.

<a href="//blog.viftrup.eu/assets/pictures/template-management/create-template.png" data-lightbox="create-template-large" data-title="Create template"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/create-template.png" title="Click to enlarge - create template" style="width: 400px"> 
</a>

<h2>Interfaces and variables</h2>
Once the template has been created, the first section will display the “Interfaces” configuration, and by default with a very limited set of physical interfaces. 
By selecting the <i>“Add Physical Interfaces”</i> we can add additional interfaces into the template configuration by selecting the slot and port index.
(I believe in future releases we’ll get the possibility to select other slots for additional NetMods).
<a href="//blog.viftrup.eu/assets/pictures/template-management/create-physical-interface.png" data-lightbox="create-physical-interface-large" data-title="Create physical interface"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/create-physical-interface.png" title="Click to enlarge - create physical interface" style="width: 400px"> 
</a>


As usual when operating with Secure Firewall Threat Defense, we’re also able to select <i>“Add Interface”</i> which displays a dropdown menu with extra interface features such as; Sub-Interface, Etherchannel, VLAN, VTI, and Loopbacks.

Interface configuration looks exactly like we’re used to, however, there is a change within the IPv4 and IPv6 sections when assigning “static” values – the first set of variables comes to life here.
This means instead of assigning an actual IP within the template, I can instead use a variable which I will be required to fill out during registration of a new device with this exact template.

To create this variable, you must click on the “+”-sign next to the IP address. The name you specify will be the name of our variable, so for ease of use make it self-explanatory, e.g., inside_ip.

<i>(Every time you see the variable sign (X), this means we can create variables for this function).</i>
<a href="//blog.viftrup.eu/assets/pictures/template-management/ipv4-settings.png" data-lightbox="ipv4-settings-large" data-title="IPv4 settings"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/ipv4-settings.png" title="Click to enlarge - IPv4 settings"> 
</a>
<a href="//blog.viftrup.eu/assets/pictures/template-management/ipv4-variable.png" data-lightbox="ipv4-settings-large" data-title="IPv4 variable"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/ipv4-variable.png" title="Click to enlarge - IPv4 variable" style="width: 400px"> 
</a>
If you’re unfamiliar with variables in general, a variable is often referred to by a “dollar-sign” aka $.

Make sure to do this for all the interfaces you intend to create for your template, including etherchannels and sub-interfaces if you need such. By utilizing the variables feature, your deployments will be a breeze and easy to use.

<i>Important: In order to minimize the manual intervention during deployment and future support, be sure your outside interface(s) is enabled for Manager Access. Even if your appliances have a separate management interface, it is required to use a data-interface for FMC connectivity.</i>

<h2>Routing and the use of variables with network-objects and overrides</h2>
Now that you’ve created your interfaces and you’re familiar with the benefits of variables, let’s continue onto the routing sections. 
Especially in this section, variables come in handy once again, this time for routing and network-objects used in my template.

In my template, I am keeping it old school by doing static routing, however, if you are using BGP many things within the BGP settings are also configurable via variables, e.g., ASN and Router ID.

If you’re deploying Cisco FTD SD-WAN, this would also be the section to configure Policy-Based Routing within your template.

<h2>Understanding the override feature</h2>
Before we continue, it’s important to understand how objects – especially the override feature works. In essence, the object override feature allows you to define an alternative value for an object, for one or more devices.

For example, the original network-object might have the host value of 172.28.1.100. 

With override, we can specify for this specific device the value should instead be 172.28.2.100. 
The object and naming remain the same, but the value (in this case the host IP) is different depending on the device it is used on.

Summarizing, if you’re using objects of any kind during templates, be sure you’ve ticked the <i>“Allow Overrides”</i> under the object settings.

A very simple example shown below, I have created a very simple route through my inside interface towards <i>DK-SplunkCollector</i> (pay attention to the value, 192.168.0.100 I will override this during the deployment with the override feature) via Next-hop <i>DK-SplunkCollector-GW</i> on which object I also override its IP during deployment.

<a href="//blog.viftrup.eu/assets/pictures/template-management/static-route.png" data-lightbox="static-route-large" data-title="Static route"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/static-route.png" title="Click to enlarge - Static route" style="width: 500px"> 
</a>

<h2>Configuration of DHCP Pools</h2>
I am not going into deep detail about this section, but as shown in the picture below I have configured two DHCP pools, one pool for my inside and one for the IoT. 

Again, by utilizing variables during creation, I will be prompted about these values when deploying a new device with the template.

<a href="//blog.viftrup.eu/assets/pictures/template-management/dhcp-pools.png" data-lightbox="dhcp-pools-large" data-title="DHCP Pools"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/dhcp-pools.png" title="Click to enlarge - DHCP Pools"> 
</a>

Be sure when configuring new DHCP pools that they are enabled. (They aren’t by default).

<h2>Setting up VPN connection (Not covered in this post)</h2>
In this post, I will not be utilizing this section, perhaps at a later stage or in another post with a deeper dive on this subject. 

However, this would be the section you set up for instance FTD SD-WAN in a Hub-and-Spoke topology for easy and rapid deployment during new branches.

<h2>Template Settings</h2>
This section contains a lot of information and important tabs which ultimately bind everything together in the end.

<h3>General</h3>
The most important sections to pay attention to here are the <i>License”</i>“ and <i>“Applied Policies”</i> boxes. (Arguably also the <i>“Deployment Settings”</i> for automatic rollback).

Ideally, it is just a matter of assigning the correct licenses matching your template, and attaching the different kinds of policies you want (ACP, Prefilter, NAT, Platform, etc.).

<h3>Template Parameters</h3>
Right away you will (hopefully) notice why we kept this section until the end of our template creation. 

This section shows all the different variables we created in the previous sections.

The bottom section shows the <i>“Network Object Overrides”</i> which I went over earlier in depth. However, I will have to add the objects I want to override with custom values manually here. (DK-SplunkCollector-GW and DK-SplunkCollector in my examples).

This is done by pressing the <i>“Add or Remove Network Object Overrides”</i> and making sure my objects are on the far right in <i>Selected Networks</i>.

<a href="//blog.viftrup.eu/assets/pictures/template-management/template-parameters.png" data-lightbox="template-parameters-large" data-title="Template Parameters"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/template-parameters.png" title="Click to enlarge - Template Parameters"> 
</a>

<a href="//blog.viftrup.eu/assets/pictures/template-management/template-parameters-selected.png" data-lightbox="template-parameters-large" data-title="Template Parameters"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/template-parameters-selected.png" title="Click to enlarge - Template Parameters"> 
</a>

<h3>Model Mapping</h3>
The end is almost near, just one final thing and we’re done with the template itself. 

This section is all about mapping the template interfaces to the desired physical appliances and their interfaces. 

Under normal circumstances, this would be a 1:1 mapping, Ethernet 1/1 -> Ethernet 1/1, but we have the possibility to change this, including model-specific configurations. 

I will be using an FPR1010 in this example.
<a href="//blog.viftrup.eu/assets/pictures/template-management/model-mapping.png" data-lightbox="model-mapping-large" data-title="Model Mapping"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/model-mapping.png" title="Click to enlarge - Model Mapping" style="width: 500px"> 
</a>

<h2>Deployment time with my newly created template</h2>
Now let’s bring this template to use and watch the FMC and FTD do their magic. We just need to provide the wizard some site-specific data and a single command on the FTD.

<h3>Configure manager on FTD</h3>
This is the one thing that makes this a low-touch deployment rather than a true zero-touch deployment, as we do still need to at least configure the manager settings for which FMC to contact. 
<i>(Depending on your uplink environment, be sure the device has/is configured to access FMC through a data-interface).</i>

No real fuzz to this step, I will “just” be running the usual configure manager command to match my setup.
```
Configure manager add <IP or DONTRESOLVE> cisco123 cisconat123 AVA-FMC01
```
Next up, I will be configuring the FMC to establish and start the registration process. However, I will be presenting the "manual" way followed by a way to do this through the FMC API.

<h3>Configure FTD + Template on FMC including branch-specific values (manual through GUI)</h3>
<b>Step 1:</b> Navigate to the usual Device Management section and press the <i>Add -> Device (Wizard)</i>. It’s important to select the wizard option; otherwise, it’ll be a regular registration and not with a template.

In this post, I’ll only be covering the traditional method using a registration key (I’ll go over the serial number option with CDO in a later post), so we select <i>Registration Key.</i>

<b>Step 2:</b> I will select my newly created template. At this stage, I see which ACP I’ve applied, including which models the template supports. (If you forgot or didn’t do the Model Mapping described earlier, you will notice the device models don’t show up as supported).

<b>Step 3:</b> This is the device details section, which is also known from the traditional registration process. 

At the far bottom, however, we’re greeted with required fields which correspond to the variables we created earlier in the template. 
The top section is the “normal” variables, and the bottom is our object overrides for device-specific values.
<i>Due to the nature of my personal setup, I am using the NAT ID section – I trust you know the basics of FTD registration and therefore I will not go into details as to why).</b>

<a href="//blog.viftrup.eu/assets/pictures/template-management/device-wizard.png" data-lightbox="device-wizard-large" data-title="Device Wizard"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/device-wizard.png" title="Click to enlarge - Device Wizard"> 
</a>

Hopefully, if everything goes well, the registration process should slowly proceed and start discovering the FTD and applying the attached template right away. This might take several minutes before completion.

<h3>Configure FTD + template on FMC including branch-specific values (The more scalable way through API)</h3>
So, in the previous section, I was doing this manually through the FMC GUI, which is fine for one or two deployments. 

However, this doesn’t scale well in the end. If a task is repetitive, it should be automated or at least scripted! So of course, I should be including the payload example to do such.

At the far end of this post is a sample using cURL, including my customized payload with the exact same values and end-goal as in the previous section through the GUI. 

This can easily be adopted into a Python script or the programming language of your choice – even integrating this into a larger set of onboarding processes or programs.

<h2>The FTD and FMC do their magic and the process within</h2>
Once I have started the registration on both ends, the FMC will start to discover the FTD and establish the sftunnel for continuous communication and deployment.

<a href="//blog.viftrup.eu/assets/pictures/template-management/discover.png" data-lightbox="registration-large" data-title="Discover"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/discover.png" title="Click to enlarge - Discover"> 
</a>

As the FTD is properly registered, it goes right into deploying the template and configuration as specified earlier. We can also follow that process.

<a href="//blog.viftrup.eu/assets/pictures/template-management/template-start.png" data-lightbox="registration-large" data-title="Template deployment start"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/template-start.png" title="Click to enlarge - Template deployment start"> 
</a>

<a href="//blog.viftrup.eu/assets/pictures/template-management/template-deployed.png" data-lightbox="registration-large" data-title="Template deployment finished"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/template-deployed.png" title="Click to enlarge - Template deployment finished"> 
</a>

There are multiple ways to follow the deployment of the template. One would be through the traditional notifications tab as usual. 
However, by navigating to the Template Management section, you will notice that my newly created template now states it has <i>“1 Associated Device.”</i>

<a href="//blog.viftrup.eu/assets/pictures/template-management/associated-devices.png" data-lightbox="associated-large" data-title="Associated Devices"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/associated-devices.png" title="Click to enlarge - Associated Devices"> 
</a>

Clicking on the Associated Devices hyperlink will bring us directly into the process and status between FTD configuration state and the template state – in sync means the current version of the template is applied and present on my device.

<a href="//blog.viftrup.eu/assets/pictures/template-management/associated-devices-shown.png" data-lightbox="associated-large" data-title="Associated Devices"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/associated-devices-shown.png" title="Click to enlarge - Associated Devices"> 
</a>

The <i>“Reapply Template”</i> button brings up a similar dialog as seen following the device wizard.
If I, for some reason, need to change some values within my specific devices without starting all over again, I would be able to alter these and reapply the template right away; meaning only a re-deployment is necessary, but not a complete re-registration.

<a href="//blog.viftrup.eu/assets/pictures/template-management/reapply-template.png" data-lightbox="reapply-large" data-title="Reapply Template dialog"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/reapply-template.png" title="Click to enlarge - Reapply Template dialog"> 
</a>

Besides this button, we can hover over the <i>“(X)”</i> aka variables symbol to get a quick overview of which values were provided with the template for this device.

The next icon generates a very simple report summarizing which values, mappings, etc., were applied to this specific device, including timestamps for begin and finish.

<h2>The proof and final words</h2>
Aaaaand just to showcase the actual configuration output from the FTD, we see all the variables and template configurations I configured is now applied to my FTD.
<a href="//blog.viftrup.eu/assets/pictures/template-management/cli-proof.png" data-lightbox="cli-proof-large" data-title="CLI proof from device"> 
  <img src="//blog.viftrup.eu/assets/pictures/template-management/cli-proof.png" title="Click to enlarge - CLI proof from device"> 
</a>

My examples were very simple and I could have gotten into way more complex template creation, however I hope this has been informative and gives you an idea how to implement this into your environment for effective and scable deployments.

<h2>Appendix - Payload used to register FTD and apply template in one go with API</h2>

```
{
    "name": "AVA-DK-BRANCH01",
    "hostName": "IP",
    "natID": "cisconat123",
    "regKey": "cisco123",
    "type": "Device",
    "performanceTier": "Legacy",
    "actions": [
      {
        "actionType": "APPLY_TEMPLATE",
        "actionInfo": {
          "postApplyAction": "DEPLOY",
          "template": {
            "id": "865c1fd8-7ff0-11ef-94a7-d514d2b4c65f",
            "type": "DEVICE_TEMPLATE"
          },
          "variableValues": [
            {
                "key": "inside_dhcp_pool",
                "value": "192.168.100.100-192.168.100.200"
            },
            {
                "key": "inside_ip",
                "value": "192.168.100.1/24"
            },
            {
                "key": "iot_dhcp_pool",
                "value": "172.28.200.100-172.28.200.200"
            },
            {
                "key": "iot_ip",
                "value": "172.28.200.1/24"
            }
        ],
        "overriddenValues": {
            "hosts": [
                {
                    "type": "Host",
                    "value": "192.168.100.2",
                    "overridable": true,
                    "name": "DK-SplunkCollector-GW"
                },
                {
                    "type": "Host",
                    "value": "192.168.100.10",
                    "overridable": true,
                    "name": "DK-SplunkCollector"
                }
          ]
        }
      }
    }
  ]
}
```

<b>Addtional materials:</b>
<a href="https://www.cisco.com/c/en/us/td/docs/security/secure-firewall/management-center/device-config/760/management-center-device-config-76/get-started-device-templates.html">Cisco documentation - Device Management Using Device Templates</a> 

----------------
------------
--------
