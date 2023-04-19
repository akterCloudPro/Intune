## Create local admin account using Intune

#### Create a user account named "ITadmin"
* Login on Microsoft Intune admin center.
* Go to Devices > Configuration profiles > + Create profile.
* Select Platform as Windows 10 and later.
* Profile type as Templates.
* Select Custom
* Click on Add button to add OMA-URI settings and provide below details:
* Name: Create Local User Account
* OMA-URI: ./Device/Vendor/MSFT/Accounts/Users/ITadmin/Password
* Data type: String
* Value: Password1@

#### Add the user "ITadmin" to Local Administrators group
* Click on Add button again to add OMA-URI settings and provide below details:
* Name: Add user to Local administrator group
* OMA-URI: ./Device/Vendor/MSFT/Accounts/Users/ITadmin/LocalUserGroup
* Data type: Integer
* Value: 2



