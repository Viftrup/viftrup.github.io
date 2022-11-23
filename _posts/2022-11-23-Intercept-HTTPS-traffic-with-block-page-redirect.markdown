---
layout: post
title: "Intercepting HTTPS traffic and redirecting to custom blockpage for information"
author: Alexander Viftrup Andersen
categories: [Umbrella, Security]
---
Blocking specific internet categories or malious activity based on DNS is becoming more popular, and requires very little effort by the IT-department to implement, control and introduces a highly efficent protection/enforcement with realatively low "time-to-action".

Especially Cisco Umbrella which offers a range of DNS protection mechanisms does this very well - however there is a lot of different vendors which provides this kind of protection.
(Cisco Umbrella is also known as OpenDNS, and private customers can also leverage some of the functionailies [OpenDNS Services] https://www.opendns.com/home-internet-security/)

Often enforcing and blocking specific internet-categories (either being due to company policies, or in order to protect employees from entering malious sites) introduces more incoming tickets for the IT/Network department, as emplooyes might not be able to access sites which they previously had no issues browsing. Example could be that in order to boost employee productivity, the company has decided to block all websites being classified as "Social Media" by policy, which means that Facebook.com would be inacessible. 

Depending on the implementation done this might be frustrating for the employee and could result in ex. being shown "Connection Reset" or "Site could not be reached" error message in the browser. Often this would raise a ticket towards the network-team as the employee now thinks that their internet is no longer working on their machine.

Imagine this being a big company, with several thounds of users trying to access Facebook.com from the cooperative network, this could mean a lot of calls or tickets being sent at the daily operations team stating that their endpoints can no longer surf the internet.

Another solution to this could be by introducing a "Block page" which would basiclly redirect the end-user to a customised website created by the IT-department, stating that Facebook.com is blocked due to company policy and where to send complains if they disagree on the block.
By redirecting the end-user to this page, might reduce the amount of incoming calls and tickets for the operations team, as the user is informed this only relates to Facebook.com being blocked, and with a statement why this has been implemented.

However... This can pose another technical issue in the modern days of security and network - intercepting HTTPS requests.

<h2>Intercepting HTTPS requests and redirect to block page</h2>
