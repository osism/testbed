# CA for testbed

Inspired by (i.e. mostly stolen from)
https://docs.ansible.com/ansible/latest/collections/community/crypto/docsite/guide_ownca.html

## Usage

Create a CA certificate and key:

```
testbed/contrib/ownca$ ansible-playbook create_ca.yml
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
secret_ca_passphrase:

PLAY [Create OSISM Testbed CA] *********************************************************************************************

TASK [Create private key with password protection] *************************************************************************
changed: [localhost]

TASK [Create certificate signing request (CSR) for CA certificate] *********************************************************
changed: [localhost]

TASK [Create self-signed CA certificate from CSR] **************************************************************************
changed: [localhost]

PLAY RECAP *****************************************************************************************************************
localhost                  : ok=3    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Create a wildcard certificate:

```
testbed/contrib/ownca$ ansible-playbook create_wildcard.yml
[WARNING]: No inventory was parsed, only implicit localhost is available
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
secret_ca_passphrase:

PLAY [Create wildcard cert for testbed] ************************************************************************************

TASK [Create private key for new certificate] ******************************************************************************
changed: [localhost]

TASK [Create certificate signing request (CSR) for new certificate] ********************************************************
changed: [localhost]

TASK [Sign certificate with our CA] ****************************************************************************************
changed: [localhost]

TASK [Write certificate file] **********************************************************************************************
changed: [localhost]

PLAY RECAP *****************************************************************************************************************
localhost                  : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Create a manager certificate (optional, can also use wildcard cert):

```
testbed/contrib/ownca$ ansible-playbook create_manager.yml
...
```

Install the new certificates into the environments:

```
testbed$ cp contrib/ownca/testbed-ca-certificate.pem environments/kolla/certificates/ca/testbed.crt
testbed$ cp contrib/ownca/testbed-ca-certificate.pem environments/openstack/testbed.pem
testbed$ cat contrib/ownca/testbed-{certificate.key,certificate.pem,ca-certificate.pem} > environments/kolla/certificates/haproxy.pem
testbed$ ansible-vault encrypt --vault-pass-file environments/.vault_pass environments/kolla/certificates/haproxy.pem
testbed$ cp environments/kolla/certificates/haproxy.pem environments/kolla/certificates/haproxy-internal.pem
testbed$ cat contrib/ownca/testbed-{manager,ca-certificate}.pem > environments/custom/files/keycloak/cert.crt
testbed$ cp environments/custom/files/keycloak/cert.crt environments/kolla/files/overlays/keystone/federation/oidc/keycloak-cert.pem
testbed$ cp contrib/ownca/testbed-manager.key environments/custom/files/keycloak/private_key.pem 
testbed$ ansible-vault encrypt --vault-pass-file environments/.vault_pass environments/custom/files/keycloak/private_key.pem
```

Edit `environments/infrastructure/secrets.yml` to contain the new manager key and certificate.

## TODO

* Document changing the certificate for traefik after it is moved into a file.
* Write a playbook for the installation step.
