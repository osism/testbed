# This file is required as of OpenStack Kolla 2024.1.

LOGOUT_URL = "https://keycloak.testbed.osism.xyz/auth/realms/osism/protocol/openid-connect/logout/?client_id=keystone&post_logout_redirect_uri=https%3A%2F%2Fapi.testbed.osism.xyz%3A5000%2Fredirect_uri%3Flogout%3Dhttps%3A%2F%2Fapi.testbed.osism.xyz%3A5000%2Flogout"

WEBSSO_ENABLED = True

WEBSSO_KEYSTONE_URL = "https://api.testbed.osism.xyz:5000/v3"
WEBSSO_CHOICES = (
    ("credentials", "Keystone Credentials"),
    ("keycloak", "Authenticate via Keycloak"),
)

WEBSSO_IDP_MAPPING = {
    "keycloak": ("keycloak", "openid"),
}
