#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

source /opt/venv/bin/activate

# prepare fqdn
api_fqdn="api-${MANAGER_PUBLIC_IP_ADDRESS//./-}.traefik.me"

# overwrite the existing haproxy.pem file
curl http://traefik.me/privkey.pem > /opt/configuration/environments/kolla/certificates/haproxy.pem
curl http://traefik.me/fullchain.pem >> /opt/configuration/environments/kolla/certificates/haproxy.pem
ansible-vault encrypt --vault-pass-file /opt/configuration/environments/.vault_pass /opt/configuration/environments/kolla/certificates/haproxy.pem

# add the certificate + key to traefik
ansible-vault decrypt --vault-pass-file /opt/configuration/environments/.vault_pass /opt/configuration/environments/infrastructure/secrets.yml
curl http://traefik.me/privkey.pem > /tmp/privkey.pem
curl http://traefik.me/fullchain.pem > /tmp/fullchain.pem
cat >> /opt/configuration/environments/infrastructure/secrets.yml <<%EOF
  traefik_me:
    cert: |
$(sed 's/^/      /' < /tmp/fullchain.pem)
    key: |
$(sed 's/^/      /' < /tmp/privkey.pem)
%EOF
ansible-vault encrypt --vault-pass-file /opt/configuration/environments/.vault_pass /opt/configuration/environments/infrastructure/secrets.yml

# use new fqdn
sed -i "s/kolla_external_fqdn: .*/kolla_external_fqdn: ${api_fqdn}/g" /opt/configuration/environments/kolla/configuration.yml

# overwrite fqdn for internal use
sed -i "s/api.testbed.osism.xyz: .*/${api_fqdn}: 192.168.16.254/g" /opt/configuration/environments/configuration.yml

# add traefik services + routers
cat >> /opt/configuration/environments/infrastructure/configuration.yml <<%EOF

traefik_configuration_dynamic:
  tcp:
    services:
      service-horizon:
        loadBalancer:
          servers:
            - address: "192.168.16.254:443"
      service-keystone:
        loadBalancer:
          servers:
            - address: "192.168.16.254:5000"
    routers:
      router-horizon:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-horizon
        entryPoints:
          - https
        tls:
          passthrough: true
      router-keystone:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-keystone
        entryPoints:
          - port_5000
        tls:
          passthrough: true
%EOF

deactivate

osism apply hosts
osism apply traefik
