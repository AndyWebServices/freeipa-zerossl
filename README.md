These two scripts try to automatically obtain and install ZeroSSL certs
to FreeIPA web interface.

To use it, do this:
* BACKUP /var/lib/ipa/certs/ and /var/lib/ipa/private/ to some safe place (it contains private keys!)
* clone/unpack all scripts somewhere
* `sudo su`* Install acme.sh. Set the email to your ZeroSSL account email
  * `curl https://get.acme.sh | sh -s email=admin@andywebservices.com`
* Install GTS, ISRG, UserTrust, and ZeroSSL CA root certs `setup-le.sh` script \
  * Run `./setup-le.sh`



If you have any problem, feel free to contact FreeIPA team:
http://www.freeipa.org/page/Contribute#Communication
