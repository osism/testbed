==============
Authentication
==============

Authentication with OpenID Connect
==================================

Authentication with OpenID Connect is possible via Keycloak,
which is automatically configured for the OIDC mechanism

OpenStack web dashboard (Horizon) login via OpenID Connect
----------------------------------------------------------

For logging in via OIDC, open your browser at OpenStack Dashboard Login Page,
select ``Authenticate via Keycloak``, after being redirected to the Keycloak
login page, perform the login with the credentials ``alice`` and ``password``.
After that you will be redirected back to the Horizon dashboard, where
you will be logged in with the user ``alice``.

OpenStack web dashboard (Horizon) logout
----------------------------------------

Keep in mind, that clicking ``Sign Out`` on the Horizon dashboard
currently doesn't revoke your OIDC token, and any consequent attempt
to ``Authenticate via Keycloak`` will succeed without providing the credentials.

The expiration time of the Single Sign On tokens can be
controlled on multiple levels in Keycloak.

1. On realm level under `Realm Settings` > `Tokens`.
   Assuming the `keycloak_realm` ansible variable is the default `osism`,
   and keycloak is listening on `https://keycloak.testbed.osism.xyz`, then the
   configuration form is available here:
   https://keycloak.testbed.osism.xyz/auth/admin/master/console/#/realms/osism/token-settings

   Detailed information is available in the
   Keycloak Server Administrator Documentation `Session and Token Timeouts
   <https://www.keycloak.org/docs/latest/server_admin/#_timeouts>`_ section.

2. In a realm down on the `client level
   <https://keycloak.testbed.osism.xyz/auth/admin/master/console/#/realms/osism/clients>`_
   select the client (keystone), and under `Settings` > `Advanced Settings`.

   It is recommended to keep the `Access Token Lifespan` on a relatively low value,
   with the trend of blocking third party cookies.
   For further information see the Keycloak documentation's
   `Browsers with Blocked Third-Party Cookies
   <https://www.keycloak.org/docs/latest/securing_apps/
   #browsers-with-blocked-third-party-cookies>`_ section.


[TODO]
Proper logout.

OpenStack CLI operations with OpenID Connect password
-----------------------------------------------------

Using the OpenStack cli is also possible via OIDC,
assuming you provisioned the user ``alice`` with password ``password``,
then you can perform a simple `project list` operation like this:

.. code-block:: console

   openstack \
     --os-cacert /etc/ssl/certs/ca-certificates.crt \
     --os-auth-url https://api.testbed.osism.xyz:5000/v3 \
     --os-auth-type v3oidcpassword \
     --os-client-id keystone \
     --os-client-secret 0056b89c-030f-486b-a6ad-f0fa398fa4ad \
     --os-username alice \
     --os-password password \
     --os-identity-provider keycloak \
     --os-protocol openid \
     --os-identity-api-version 3 \
     --os-discovery-endpoint https://keycloak.testbed.osism.xyz/auth/realms/osism/.well-known/openid-configuration \
   project list

OpenStack CLI token issue with OpenID Connect
---------------------------------------------

It is also possible to exchange your username/password to a token,
for further use with the cli.
The ``token issue`` subcommand returns an SQL table,
in which the `id` column's `value` field contains the token:

.. code-block:: console

   openstack \
     --os-cacert /etc/ssl/certs/ca-certificates.crt \
     --os-auth-url https://api.testbed.osism.xyz:5000/v3 \
     --os-auth-type v3oidcpassword \
     --os-client-id keystone \
     --os-client-secret 0056b89c-030f-486b-a6ad-f0fa398fa4ad \
     --os-username alice \
     --os-password password \
     --os-identity-provider keycloak \
     --os-protocol openid \
     --os-identity-api-version 3 \
     --os-discovery-endpoint https://keycloak.testbed.osism.xyz/auth/realms/osism/.well-known/openid-configuration \
     --os-openid-scope "openid profile email" \
   token issue \
       -c id
       -f value

An example token is like:

.. code-block:: console

   gAAAAABhC98gL8nsQWknro3JWDXWLFCG3CDr3Mi9OIlvVAZMjy2mNgYtlXv_0yAIy-
   nSlLAaLIGhht17-mwf8uclKgRuNVsYLSmgUpB163l89-ch2w2_OFe9zNSQNWf4qfd8
   Cl7E7XvvUoFr1N8Gh09vaYLvRvYgCGV05xBUSs76qCHa0qElPUsk56s5ft4ALrSrzD
   4cEQRVb5PXNjywdZk9_gtJziz31A7sD4LPIy82O5N9NryDoDw

OpenStack CLI operations with token
-----------------------------------

[TODO]

OpenStack CLI token revoke
--------------------------

[TODO]
