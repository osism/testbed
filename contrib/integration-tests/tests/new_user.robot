*** Settings ***
Documentation     New user created via UMC can perform login to Horizon.
Library           OperatingSystem
Library           SeleniumLibrary
Library           RequestsLibrary

*** Variables ***
${UMC_URL}        http://testbed-manager:8008
${KC_URL}         http://testbed-manager:8080
${HORIZON_URL}    http://api.testbed.osism.xyz
${BROWSER_URL}    http://testbed-manager:4444
${BROWSER}        firefox
${USERNAME}       umc-admin
${PASSWORD}       password
${NEW_USERNAME}   AdministratorUUID1
${NEW_PASSWORD}   mgrt97HABCEXBYNqgv8Jpdqe
${BASE_DN}        dc=osism,dc=local
${NEW_DN}         uid=${NEW_USERNAME},cn=users,${BASE_DN}

*** Test Cases ***
As an administrator, I want to be able to
    Create another admin user using the UMC
    Log in to Horizon as the new Administrator using OIDC


*** Keywords ***
Create another admin user using the UMC
    Open Browser At UMC Login Page
    Submit Login credentials
    Create the new user
    Give the new user admin privileges

Log in to Horizon as the new Administrator using OIDC
    Open Browser At OpenStack Dashboard Login Page
    Select Authenticate via Keycloak
    Perform login via Keycloak
    OpenStack Dashboard Should Open
    Click Identity And User
    Details Of New User Should Be Visible

##############################################################################
# Keywords for
# "Create another admin user using the UMC"
##############################################################################

Open Browser At UMC Login Page
    Sleep  3
    Open Browser       ${UMC_URL}/univention/login/?lang=en-US
    ...                ${BROWSER}  remote_url=${BROWSER_URL}
    Title Should Be    Univention Login

Submit Login credentials
    Input Text       id:umcLoginUsername    ${USERNAME}
    Input Text       id:umcLoginPassword    ${PASSWORD}
    Click Button     class:umcLoginFormButton
    Wait Until Page Contains  Univention Management Console

Create the new user
    # Go to the users module
    Go To  ${UMC_URL}/univention/management/\#module=udm:users/user:0:

    # Click on the "+" (plus) symbol
    Wait Until Element Is Visible   id:umc_widgets_Button_16
    Sleep  1.0
    Click Element   id:umc_widgets_Button_16

    # Fill in lastname and username for the new user
    Input Text       name:lastname    ${NEW_USERNAME}
    Input Text       name:username    ${NEW_USERNAME}

    Wait Until Element Is Visible    id:umc_widgets_Button_91
    Sleep  0.8
    Click Element    id:umc_widgets_Button_91

    # Enter the password twice
    Input Text       id:umc_widgets_PasswordBox_4    ${NEW_PASSWORD}
    Input Text       id:umc_widgets_PasswordBox_5    ${NEW_PASSWORD}

    # Click the submit button
    Click Element    id:umc_widgets_Button_97

    # Click the cancel button
    Wait Until Element Is Visible   id:umc_widgets_Button_185
    Sleep  0.8
    Click Element    id:umc_widgets_Button_185

Give the new user admin privileges
    # Click on the newly created admin user
    Wait Until Element Is Visible
    ...  //*//div[contains(@class,"umcGridDefaultAction")][contains(.,"${NEW_USERNAME}")]
    Click Element
    ...  //*//div[contains(@class,"umcGridDefaultAction")][contains(.,"${NEW_USERNAME}")]

    # Click on Groups
    Wait Until Element Is Visible  //*//span[contains(.,"Groups")]
    Sleep  0.8
    Click Element    //*//span[contains(.,"Groups")]

    # Enter into "Primary Group" the value "Domain Admins"
    Wait Until Element Is Visible   id:umc_modules_udm_ComboBox_15
    Input Text   id:umc_modules_udm_ComboBox_15  Domain Admins
    Press Keys   None   ENTER

    # Click the Menu button and then Log out
    Click Element    id:umc_menu_Button_0
    Wait Until Element Is Visible  //*//span[contains(.,"Logout")]
    Click Element                  //*//span[contains(.,"Logout")]
    Close Browser

##############################################################################
# Keywords for
# "Log in to Horizon as the new Administrator using OIDC"
##############################################################################

Open Browser At OpenStack Dashboard Login Page
    Open Browser       ${HORIZON_URL}    ${BROWSER}  remote_url=${BROWSER_URL}
    Title Should Be    Login - OpenStack Dashboard

Select Authenticate via Keycloak
    Select From List By Value    name:auth_type    keycloak

Perform login via Keycloak
    # Click Login
    Click Button       loginBtn
    # Keycloak Login Page Should Open
    Title Should Be    Sign in to osism
    # Fill in username and password
    Input Text    id:username    ${NEW_USERNAME}
    Input Text    id:password    ${NEW_PASSWORD}
    # Submit Credentials
    Click Button       id:kc-login

OpenStack Dashboard Should Open
    Wait Until Element Is Visible
    ...  xpath://*//img[contains(@alt,"OpenStack Dashboard")]

Click Identity And User
    Click Link
    ...  xpath://*//a[contains(@data-target,"#sidebar-accordion-identity")]
    Click Link
    ...  xpath://*//a[contains(@href,"/identity/users")]


Details Of New User Should Be Visible
    Wait Until Element Is Visible
    ...  xpath://*//table[contains(@id,"users")]/*//a[contains(.,"${NEW_USERNAME.lower()}")]

    Click Link
    ...  xpath://*//table[contains(@id,"users")]/*//a[contains(.,"${NEW_USERNAME.lower()}")]
