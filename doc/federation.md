# Federation in Keycloak

## Adding remote SSL certificate to Keycloak truststore

:::note

>**note:**
>The following commands are executed from the **manager** node in a working testbed.

:::

Open a login shell on the manager via SSH.

Copy the SSL certificate to the keycloak container

```sh
   docker cp cert.pem keycloak:/certificate.pem
```

Add the new certificate to the Keycloak internal truststore

```sh
   docker exec -ti -u root keycloak bash
   keytool -cacerts -import -alias remoteCertificate -file /certificate.pem -storepass "changeit" -noprompt
```

After that, Keycloak will be able to resolve the new SSL certificate without any problem.
