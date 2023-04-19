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

## Install Fonts on a Windows Device using Intune

#### STEP 1: Create IntuneWin file for Fonts deployment using Intune
* Create an empty folder named DeployFonts or any name you like.
* Create a subfolder under DeployFonts call it as Fonts.
* Copy all font files with .ttf or .otf extension to Fonts folder.
* Create two powershell scripts called InstallFonts.ps1 and Uninstallfonts.ps1 in DeployFonts folder (find the scripts).
* Download Microsoft Win32 Content Prep Tool. Its a zip file therefore extract its contents into a folder.
* Create an empty folder for example C:\output or anywhere you like.
* Repackage the DeployFonts folder to .intunewin file using IntuneWinAppUtil.exe which can be located in Microsoft Win32 Content Prep Tool.

#### STEP 2: Deploy Fonts using Intune
* Click on Apps and then click on All Apps.
* Click on + Add and Select Windows app (Win32) from the app type.
* Click on Select app package file to browse and select Installfonts.intunewin file and click on OK. On App information tab, provide Information about the Application.
* Update the Name, Description and Enter the name of the publisher. Click on Next to proceed.
* Provide the Install command, uninstall command, Install behavior, Device restart behavior. Click on Next to proceed.
  - Install command:  powershell.exe -Executionpolicy Bypass -File .\Installfonts.ps1
  - Uninstall command: powershell.exe -Executionpolicy Bypass -File .\Uninstallfonts.ps1
  - Install behavior: System
  - Device restart behavior: No specific Action
* Detection Rules
  - Rule type: File
  - Path: C:\windows\fonts\
  - File or folder: Alata-Regular.ttf
  - Detection Method: File or Folder exists.




