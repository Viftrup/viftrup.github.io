---
layout: post
title: "Intercepting HTTPS traffic and redirecting to custom block page"
author: Alexander Viftrup Andersen
categories: [Umbrella, Security]
---
Blocking specific internet categories or malicious activity based on DNS is becoming more popular and requires very little effort by the IT-department to implement, control and introduces a highly efficient protection/enforcement with relatively low "time-to-action".

Especially Cisco Umbrella which offers a range of DNS protection mechanisms does this very well - however there is a lot of different vendors which provides this kind of protection. (NGFWs might also be able to do parts of this)
(Cisco Umbrella is also known as OpenDNS, and private consumers can also leverage some of the functionalities [OpenDNS Services](https://www.opendns.com/home-internet-security/))

Often enforcing and blocking specific internet-categories (either being due to company policies, or in order to protect employees from entering malicious sites) introduces more incoming tickets for the IT/Network department, as employees might not be able to access sites which they previously had no issues browsing. Example could be that in order to boost employee productivity, the company has decided to block all websites being classified as "Social Media" by policy, which means that Facebook.com would be inaccessible. 

Depending on the implementation done this might be frustrating for the employee and could result in ex. being shown "Connection Reset" or "Site could not be reached" error message in the browser. Often this would raise a ticket towards the operations as the employee thinks their computer is without internet.

Imagine this being a big company, with several thousands of users trying to access Facebook.com from the cooperative network, this could mean a lot of calls or tickets being sent at the daily operations team stating that their endpoints can no longer surf the internet.

Another solution to this could be by introducing a "block page" which would basically redirect the end-user to a customized website created by the IT-department, stating that Facebook.com is blocked due to company policy and where to send complains if they disagree on the block.
By redirecting the end-user to this page, it might reduce the number of incoming calls and tickets for the operations team, as the user is informed this only relates to the domain of Facebook.com being blocked, and with a statement why this has been implemented.

Blocking specific internet categories or malicious activity based on DNS is becoming more popular and requires very little effort by the IT-department to implement, control and introduces a highly efficient protection/enforcement with relatively low "time-to-action".

Especially Cisco Umbrella which offers a range of DNS protection mechanisms does this very well - however there is a lot of different vendors which provides this kind of protection. (NGFWs might also be able to do parts of this)
(Cisco Umbrella is also known as OpenDNS, and private consumers can also leverage some of the functionalities [OpenDNS Services](https://www.opendns.com/home-internet-security/))

Often enforcing and blocking specific internet-categories (either being due to company policies, or in order to protect employees from entering malicious sites) introduces more incoming tickets for the IT/Network department, as employees might not be able to access sites which they previously had no issues browsing. An example could be in order to boost employee productivity, the company has decided to block all websites being classified as "Social Media" by policy, which means Facebook.com would be inaccessible. 

Depending on the implementation method this might be frustrating for the employees and could result in ex. being shown "Connection Reset" or "Site could not be reached" error message in the browser. Often this would raise a ticket towards the operations as the employees believe their computer is without internet.

Imagine this being a big company, with several thousands of users trying to access Facebook.com from the cooperative network, this could potentially mean in increase of calls or tickets being sent at the daily operations team stating that their endpoints can no longer surf the internet.

Another solution to this could be by introducing a "block page" which would basically redirect the employee to a customized website created by the IT-department, stating that facebook.com is blocked due to company policy and where to send complaint, if they disagree on the block.
By redirecting the employee to this page, it could reduce the number of incoming calls and tickets for the operations team, as the user is informed this only relates to the domain of facebook.com being blocked, and with a statement why this has been implemented.

However, this can pose another technical issue in the modern days of security and network - intercepting HTTPS requests.

<h2>Intercepting HTTPS requests and redirect to block page</h2>
Nowadays the most common internet-browsing protocol is known as HTTP and its successor HTTPS (S for Secure)
HTTP was a great protocol back in the days, but as technology evolved and security becoming mandatory the majority of browsing in 2022 has converted using the more secure HTTP<b>S</b> variant which introduces the use of authentication by exchanging certificate information between endpoint and server.

Certificates is introduced in order to keep data secure, verify the ownership of the website and to prevent attackers from creating fake/look-a-like websites and tricking them entering personal data on the attacker’s website, instead of your ex. web-banking application.

With that in mind we continue to look at the redirect to a block page, in case of an employee entering Facebook.com and being blocked.

If the employee were to enter <b>http</b>://facebook.com (and not being redirected to the HTTPS version) they would be blocked, and by ex. Cisco Umbrella be redirected for a customized block page hosted by Cisco Umbrella, which has nothing to do with facebook.com
![HTTP example.com block page](/assets/pictures/b62f9ed-block_page_example.jpeg)
<center><i>Picture shows "example.com" - this could be "facebook.com"</i></center>

In other terms Umbrella did a kind of "man-in-the-middle" attack, meaning that it "hi-jacked" the request from the employee and by policy it told not to allow facebook.com and thereby instead redirected the user browser to a different domain presenting the Cisco Umbrella block-page, and not the facebook news feed.

This was straight forward as the request wasn't sent with the HTTP<b>S</b> protocol, meaning there was no certificate validation if the employee communicated with the facebook.com webserver or was (hi-jacked) redirected onto another page/webserver - ex. the Umbrella block-page.

If the employee were to enter by using http<b>s</b>://facebook.com and thereby requiring validation and certificate exchange between the employee endpoint and the facebook.com webserver, the scenario would be different.
In such case the employee's web browser would expect to be presented by a certificate matching the CN (Common Name) of “www.facebook.com” - however due to the policy put in place, we don't want the employee to enter facebook.com but instead we want to present the Cisco Umbrella block-page.
Due to the HTTPS protocol being used, Umbrella is forced to do another "man-in-the-middle” attack and in order to convince the endpoint browser, it will generate a per-domain certificate issued by Umbrella Sub-CA matching the CN of “www.facebook.com”, and thereby “trick” the browser to continue the exchange and possibility for Umbrella to decrypt the traffic – even though it’s a “fake” certificate. This makes it possible for Umbrella to redirect the browser onto the desired block page, hosted on a separate domain.

![HTTPS Facebook.com Umbrella certificate](/assets/pictures/facebook-umbrella-certificate.png)

This however of course seems like a security issue, if things were this easy...

The Umbrella Root CA is not automatically trusted by computers and browsers (that is the issuer of the certificate), meaning that without any certificates manually stored on the endpoint or pushed through MDM/GPOs the redirect of Umbrella would present the famous "Your connection is not secure/private" due to the certificate-chain not being trusted. And the company of course had security awareness training of employees learning that they should <b>never</b> bypass such warning.

And since over 80% of today’s webservers enforce the HTTPS protocol, this would be a common scenario. In order to make this efficient, it is highly recommended to push the "middle-man" (Umbrella certificate in this case) onto the company machines either through MDM-software or Group Policies in AD.

For BYOD (Bring Your Own Device) scenarios where you're not in charge of the systems, there unfortunately isn't any possibility to have this block page shown efficiently over a HTTPS connection. Unless manually trusting the certificate or proceeding through the warning.

<h2>Closing remarks</h2>
This will be the scenario no matter if you're using Cisco Umbrella or another 3rd part solution for this kind of DNS/block page protection.
Including the consumer-friendly [Pi-Hole](https://pi-hole.net/) solution.

As frustrating as it might seems, this is for the greater good and by the standard of the HTTPS protocol.
