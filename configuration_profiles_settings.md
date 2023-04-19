### Create a local admin account using Intune
* Login on Microsoft Intune admin center.
* Go to Devices > Configuration profiles > + Create profile.
* Select Platform as Windows 10 and later.
* Profile type as Templates.
* Select Custom
* Click on Add button to add OMA-URI settings and provide below details:
* Name: Create Local User Account
* OMA-URI: ./Device/Vendor/MSFT/Accounts/Users/ITUAdmin/Password
* Data type: String
* Value: Password1@





