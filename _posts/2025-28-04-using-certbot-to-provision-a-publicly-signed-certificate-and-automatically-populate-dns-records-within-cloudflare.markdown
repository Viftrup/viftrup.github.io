---
layout: post
title: "Using Certbot to provision a public certificate and auto-populate DNS records in Cloudflare"
date: 2025-04-28
author: Alexander Viftrup Andersen
categories: [Certbot, Cloudflare]
---
Using Certbot to provision a publicly signed certificate and automatically populate DNS records within Cloudflare

In this post, I'll quickly go over how you can automatically, and with a simple command line statement, populate the required DNS01-challenge response with Cloudflare and generate a publicly signed certificate to be used on your services—either for production or labbing. I'll be using this purely for some upcoming lab content.

Certbot is also supporting the ACME-challenge with a built-in ACME Client. I however decided to go for the DNS-challenge in most cases, as this is solely relying on a TXT-record being present on my domain rather than a ACME-Client.

But note that this will ideally work on many different DNS providers as listed below. Beware that the syntax and plugins required are different from what you see in this post.

There is also a list of third-party plugins, which aren't maintained by Certbot but are still available to be used. 

See the list here:
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

Depending on your operating system, you might need to install Python and pip first. 

We'll be needing this for the installation of the Cloudflare plugin, as it's not officially part of the brew repo. I'll not be covering the installation process in this post.
<br>
**Create a Python virtual environment**
*This step is optional*

I like to keep things separate and clear, so I'll be making a venv for this operation.

<h3>Navigate to the desired folder to be used for Certbot</h3>
Issue the command `python3 -m venv certbot` - this creates a virtual environment named 'certbot', where we can install the needed libs.

<h3>Activating our newly created environment</h3>
`source certbot/bin/activate`

Your command line should be appended and start with `(certbot) <user@host> <folder>`

<h3>Installing Certbot and the Cloudflare plugin</h3>
`pip3 install certbot` 
`pip3 install certbot-dns-cloudflare`

<h3> Create a Cloudflare API Token</h3>
Click on your user on the far right <b>My Profile -> API Tokens</b>
Create an API Token  

*(Optional)* Security-wise, I highly recommend using a restricted API Token, as compared to a 'Global API Key', which has full permission to your Cloudflare account. Assigning "Zone" - "DNS" - "Edit" is sufficient for this operation. 

Select the domain on which you'll be provisioning the record.

Additionally, you can do filtering based on client IP for enhanced security.

TTL or Time-to-Live is essentially the lifetime of your token. If you're only doing this once and know you might forget to disable or delete the token, go ahead and add an expiration date. It might be worth adding an expiration date nevertheless—just in case!

Create a secret named `cloudflare.ini` (or something else, just make sure to point to the correct file)
```text
Cloudflare API token used by Certbot
dns_cloudflare_api_token = <TOKEN>
```
<h2>Generate the certificate for your domain(s)</h2>

There are different methods of acquiring a certificate for a given domain. 

The parameter '-d' defines the domain of the certificate. It is possible to create multiple domain statements if needed, e.g., with and without 'www.' as seen in my examples below.

<b>Option 1: Acquire certificate for 'viftrup.eu'</b>
```text
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials cloudflare.ini \
  -d viftrup.eu
```
**Option 2: Acquire a single certificate with multiple domain environments included**
```text
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials cloudflare.ini \
  -d lab.viftrup.eu \
  -d www.lab.viftrup.eu
```

**Option 3: Acquire certificate for 'viftrup.eu' - but wait 60 seconds for DNS propagation to take place (Optional)**
```text
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials cloudflare.ini \
  --dns-cloudflare-propagation-seconds 60 \
  -d viftrup.eu
```

The last option is just like option 1, but with an added DNS propagation timer. This is normally not needed, and the default of 10 seconds is in most scenarios sufficient. However, due to Cloudflare load or other things causing the DNS propagation to be slow, we can increase the wait from creating the TXT record on Cloudflare until our Certbot asks for a certificate.

I normally tend to use the last option, as I often find the default 10 seconds to be too short, and my challenge will fail.

<h2>Retrieving the certificate</h2>
Depending on your setup and system, the certificate parts will be put into '/etc/letsencrypt/live/<domain>' - it'll also be printed to your terminal for the exact location of certificate material.

Now you've successfully created a publicly signed certificate issued by Let's Encrypt to be used where needed. Keep in mind by default the certificate is valid for 90 days. You can either request a new certificate or renew the existing one by then.

**Note that in the near future Let's Encrypt and other providers will decrease the lifetime of certificates. Let's Encrypt has announced they'll start rolling out certificates with a lifetime of 47 days and short-lived certificates of 7 days.**

<h2>(Optional) - Convert to PKCS12 (.PFX) file with OpenSSL</h2>
This step is optional and can be left out.

But in case you need the certificate to be bundled into a PKCS12 (.pfx file extension format), here is how you do that.

'openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out domain.pfx'

You'll then be prompted for an export password and validation of the password for the file.

And now you can use the PKCS12 file wherever needed.

<h2>Troubleshooting</h2>

**Certbot Cloudflare plugin not working**
If you already have Certbot installed on your machine, e.g., through Brew or similar, you need to uninstall these first. Otherwise, the already installed Certbot will interfere and overwrite the ones used within our Python environment.

Confirm the plugin has been installed with certbot plugins and you should see dns-cloudflare being listed.

**Permission denied**

Depending on your system, you might be required to elevate your rights to run programs or retrieve the needed files. In that case, be sure to run the commands as an elevated user or by utilizing sudo.

