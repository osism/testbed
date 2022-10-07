# testbed openstack-cli examples outside the testbed-manager

ref:
*  [preparations.html#tls-certificates-and-hostnames](https://docs.osism.tech/testbed/preparations.html#tls-certificates-and-hostnames)
*  [authentication.html#authentication-with-openid-connect](https://docs.osism.tech/testbed/authentication.html#authentication-with-openid-connect)

## Usage:

### testbed SSL CA

> **Note**
> place the testbd SSL CA in ~/.config/openstack or adjust the files
> accordingly

```bash
mkdir -p ~/.config/openstack
cd ~/.config/openstack
wget https://github.com/osism/testbed/raw/main/environments/kolla/certificates/ca/testbed.crt
```

### clouds-public.yml, clouds.yaml + secure.yaml

> **Note**
> this also works if clouds-public.yml, clouds.yaml + secure.yaml
> are place in your current working directory if you don't want to place
> them in ~/.config/openstack.

> **Warning**
> **this overwrites your local openstack cli config, use with caution
> or adjust accordingly**

```bash
wget -O clouds-public.yaml https://github.com/osism/testbed/raw/main/contrib/openstack-cli/clouds-public.yaml
wget -O clouds.yaml https://github.com/osism/testbed/raw/main/contrib/openstack-cli/clouds.yaml.example
wget -O secure.yaml https://github.com/osism/testbed/raw/main/contrib/openstack-cli/secure.yaml.example
```

