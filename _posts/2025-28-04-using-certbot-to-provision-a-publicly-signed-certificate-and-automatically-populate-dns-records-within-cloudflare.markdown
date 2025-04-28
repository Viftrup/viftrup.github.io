
---
layout: post
title: "Using Certbot to Provision a Publicly Signed Certificate and Automatically Populate DNS Records within Cloudflare"
date: 2025-04-28
author: Alexander Viftrup Andersen
categories: [Certbot, Cloudflare]
---

Using Certbot to provision a publicly signed certificate and automatically populate DNS records within Cloudflare

In this post, I'll quickly go over how you can automatically, and with a simple command line statement, populate the required DNS01-challenge response with Cloudflare and generate a publicly signed certificate to be used on your services—either for production or labbing. I'll be using this purely for some upcoming lab content.

But note that this will ideally work on many different DNS providers as listed below. Beware that the syntax and plugins required are different from what you see in this post.

There is also a list of third-party plugins, which aren't maintained by Certbot but are still available to be used. See the list here:
[https://eff-certbot.readthedocs.io/en/latest/using.html#third-party-plugins](https://eff-certbot.readthedocs.io/en/latest/using.html#rtbot:
- certbot-dns-cloudflare
- certbot-dns-digitalocean
- certbot-dns-dnsimple
- certbot-dns-dnsmadeeasy
- certbot-dns-gehirn
- certbot-dns-google
- certbot-dns-linode
- certbot-dns-luadns
- certbot-dns-nsone
- certbot-dns-ovh
- certbot-dns-rfc2136
- certbot-dns-route53
- certbot-dns-sakuracloud

Depending on your operating system, you might need to install Python and pip first. We'll be needing this for the installation of the Cloudflare plugin, as it's not officially part of the brew repo. I'll not be covering the installation process in this post.

## Create a Python virtual environment
*This step is optional*

I like to keep things separate and clear, so I'll be making a venv for this operation.

Navigate to the desired folder to be used for Certbot.
Issue the command `python3 -m venv certbot` - this creates a virtual environment named 'certbot', where we can install the needed libs.

**Activating our newly created environment**
`source certbot/bin/activate`

Your command line should be appended and start with `(certbot) <user@host> <folder>`

### Installing Certbot and the Cloudflare plugin
`pip3 install certbot`  
`pip3 install certbot-dns-cloudflare`

### Go to Cloudflare and create an API token
Click on your user on the far right -> My Profile -> API Tokens  
Create an API Token  
(Optional)

Security-wise, I highly recommend using a restricted API Token, as compared to a 'Global API Key', which has full permission to your Cloudflare account. Assigning "Zone" - "DNS" - "Edit" is sufficient for this operation. Select the domain on which you'll be provisioning the record.

Additionally, you can do filtering based on client IP for enhanced security.

TTL or Time-to-Live is essentially the lifetime of your token. If you're only doing this once and know you might forget to disable or delete the token, go ahead and add an expiration date. It might be worth adding an expiration date nevertheless—just in case!

Create a secret named `cloudflare.ini` (or something else, just make sure to point to the correct file)

# Cloudflare API token used by Certbot
dns_cloudflare_api_token = <TOKEN>
