---
layout: post
title: "Intercepting HTTPS traffic and redirecting to custom block page"
author: Alexander Viftrup Andersen
categories: [Umbrella, Security]
---
Blocking specific internet categories or malious activity based on DNS is becoming more popular, and requires very little effort by the IT-department to implement, control and introduces a highly efficent protection/enforcement with realatively low "time-to-action".

Especially Cisco Umbrella which offers a range of DNS protection mechanisms does this very well - however there is a lot of different vendors which provides this kind of protection. (NGFW is also capable of doing such filtration)
(Cisco Umbrella is also known as OpenDNS, and private customers can also leverage some of the functionailies [OpenDNS Services](https://www.opendns.com/home-internet-security/))

Often enforcing and blocking specific internet-categories (either being due to company policies, or in order to protect employees from entering malious sites) introduces more incoming tickets for the IT/Network department, as emplooyes might not be able to access sites which they previously had no issues browsing. Example could be that in order to boost employee productivity, the company has decided to block all websites being classified as "Social Media" by policy, which means that Facebook.com would be inacessible. 

Depending on the implementation done this might be frustrating for the employee and could result in ex. being shown "Connection Reset" or "Site could not be reached" error message in the browser. Often this would raise a ticket towards the network-team as the employee now thinks that their internet is no longer working on their machine.

Imagine this being a big company, with several thounds of users trying to access Facebook.com from the cooperative network, this could mean a lot of calls or tickets being sent at the daily operations team stating that their endpoints can no longer surf the internet.

Another solution to this could be by introducing a "Block page" which would basiclly redirect the end-user to a customised website created by the IT-department, stating that Facebook.com is blocked due to company policy and where to send complains if they disagree on the block.
By redirecting the end-user to this page, might reduce the amount of incoming calls and tickets for the operations team, as the user is informed this only relates to Facebook.com being blocked, and with a statement why this has been implemented.

However... This can pose another technical issue in the modern days of security and network - intercepting HTTPS requests.

<h2>Intercepting HTTPS requests and redirect to block page</h2>
Nowadays the most common internet-browsing protocol is known as HTTP and its successor HTTPS (S for Secure)
HTTP was a great protocol back in the days, but as technology envolves and security is manatory the majority of browsing in 2022 has converted using the more secure HTTP<b>S</b> variant which introduces the use of certificates between endpoint and server.

Certificates is introduced in order to keep data secure, verify the actual ownership of the website and to prevent attackers from creating fake/look-a-like websites and lure them into entering personal data on the attackers website, instead of your web-banking.

With that in mind we continue to look at the redirect to a block page, in case of an employee entering Facebook.com and being blocked.

If the employee were to enter <b>http</b>://facebook.com (and not being redirected to the HTTPS version) they would be blocked, and by ex. Cisco Umbrella be redirected for a customised block page hosted by Cisco Umbrella, which actually has nothing to do with Facebook.com
-...... Block Page Example Picture ......-

In other terms Umbrella actually did a kind of "man-in-the-middle" attack, meaning that it "hi-jacked" the request from the employee and by policy it told not to allow Facebook.com and thereby instead redirected the user to an Cisco Umbrella block-page, instead of the Facebook news feed.

This was pretty straight forward as the request wasn't sent with the HTTP<b>S</b> protocol, meaning there was no certifcate validation if the employee actually communicated with the Facebook.com webserver or was (hi-jacked) redirected onto another page/webserver - ex. the Umbrella block-page.

If the employee were to enter by using http<b>s</b>://facebook.com and thereby requring validation and certificate exchange between the employee endpoint and the facebook.com webserver, the senario would be different.
In such case the employee's webbrowser would expect to be presented by a certificate matching the CN (Common Name) of facebook.com - however due to the policy put in place, we don't want the employee to enter facebook.com but instead we want to present the Cisco Umbrella block-page.
Due to the HTTPS protocol being used, Umbrella is forced to do a "man-in-the-middle attack" and in order to convince the endpoint browser, create a "fake" certificate issued by Umbrella sub-CA matching the CN of facebook.com, and thereby convince the browser that Umbrella block-page is providing the "legit" facebook.com certificate and it should proceed.

-..... Block page Facebook.com certificate example .....-

This however of course seems like a security issue, if things were this easy...

The Umbrella Root CA is not automaticlly trusted by computers and browsers, meaning that without any certificates manually stored on the endpoint or pushed through MDM/GPOs the redirect of Umbrella would present the famous "Your connection is not secure/private" due to the certificate-chain not being trusted. And the company of course had security awareness training of employees learning that they should <b>never</b> bypass such warning.

And since over 80% of todays web-servers enforce the HTTPS protocol, this would be a common senario. In order to make this efficent, it is highly recommended to push the "middle-man" (Umbrella certificate in this case) onto the company machines either through MDM-software or Group Policies in AD.

For BYOD (Bring Your Own Device) senarios where you're not in charge of the systems, there unfourently isn't any possibility to have this block page shown efficently over a HTTPS connection. Unless manually trusting the certificate or proceeding through the warning.

<h2>Closing remarks</h2>
This will be the senario no matter if you're using Cisco Umbrella or another 3rd part solution for this kind of DNS/block page protection.
Including the consumer-friendly [Pi-Hole](https://pi-hole.net/) solution.

As frustating as it might seems, this is for the greater good and by the standard of the HTTPS protocol.
