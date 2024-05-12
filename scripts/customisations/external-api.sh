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
sed -i "s/auth_url: .*/auth_url: https:\/\/${api_fqdn}:5000\/v3/g" /opt/configuration/environments/openstack/clouds.yml

# overwrite fqdn for internal use
sed -i "s/api.testbed.osism.xyz: .*/${api_fqdn}: 192.168.16.254/g" /opt/configuration/environments/configuration.yml

# add traefik ports + services + routers
cat >> /opt/configuration/environments/infrastructure/configuration.yml <<%EOF

traefik_ports_extra:
  - 5000
  - 5050
  - 6385
  - 6780
  - 8774
  - 8776
  - 8780
  - 9001
  - 9292
  - 9311
  - 9511
  - 9696
  - 9876

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
      service-magnum:
        loadBalancer:
          servers:
            - address: "192.168.16.254:9511"
      service-designate:
        loadBalancer:
          servers:
            - address: "192.168.16.254:9001"
      service-glance:
        loadBalancer:
          servers:
            - address: "192.168.16.254:9292"
      service-octavia:
        loadBalancer:
          servers:
            - address: "192.168.16.254:9876"
      service-swift:
        loadBalancer:
          servers:
            - address: "192.168.16.254:6780"
      service-barbican:
        loadBalancer:
          servers:
            - address: "192.168.16.254:9311"
      service-ironic:
        loadBalancer:
          servers:
            - address: "192.168.16.254:6385"
      service-cinder:
        loadBalancer:
          servers:
            - address: "192.168.16.254:8776"
      service-neutron:
        loadBalancer:
          servers:
            - address: "192.168.16.254:9696"
      service-nova:
        loadBalancer:
          servers:
            - address: "192.168.16.254:8774"
      service-placement:
        loadBalancer:
          servers:
            - address: "192.168.16.254:8780"
      service-ironic-inspector:
        loadBalancer:
          servers:
            - address: "192.168.16.254:5050"
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
      router-magnum:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-magnum
        entryPoints:
          - port_9511
        tls:
          passthrough: true
      router-designate:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-designate
        entryPoints:
          - port_9001
        tls:
          passthrough: true
      router-glance:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-glance
        entryPoints:
          - port_9292
        tls:
          passthrough: true
      router-octavia:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-glance
        entryPoints:
          - port_9876
        tls:
          passthrough: true
      router-swift:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-swift
        entryPoints:
          - port_6780
        tls:
          passthrough: true
      router-barbican:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-barbican
        entryPoints:
          - port_9311
        tls:
          passthrough: true
      router-ironic:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-ironic
        entryPoints:
          - port_6385
        tls:
          passthrough: true
      router-cinder:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-cinder
        entryPoints:
          - port_8776
        tls:
          passthrough: true
      router-neutron:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-neutron
        entryPoints:
          - port_9696
        tls:
          passthrough: true
      router-nova:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-nova
        entryPoints:
          - port_8774
        tls:
          passthrough: true
      router-placement:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-placement
        entryPoints:
          - port_8780
        tls:
          passthrough: true
      router-ironic-inspector:
        rule: "HostSNI(\`${api_fqdn}\`)"
        service: service-ironic-inspector
        entryPoints:
          - port_5050
        tls:
          passthrough: true
%EOF

deactivate

osism apply hosts
osism apply traefik
