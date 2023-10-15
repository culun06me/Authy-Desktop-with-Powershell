# Authy-Desktop-with-Powershell


## How to Install Authy Desktop Using the PowerShell App Deployment Toolkit
1. Download the Powershell App Deployment Toolkit Version 3.9.3:
       [https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases]
2. Download the zip file to a folder created at (C:\Downloads)
3. Open Windows PowerShell by Right-Clicking on Windows PowerShell and selecting Run as Administrator
4. Enter the following command to remove the **Zone.Identifier**:
      -  Unblock-File `--Path C:\Downloads\PSAppDeployToolkit_v3.8.4.zip`
5. Enter the following command to **extract** the contents of the **zip file**:
      -  Expand-Archive `--Path C:\Downloads\PSAppDeployToolkit_v3.8.4.zip -DestinationPath C:\Downloads\PADT`
6. Enter the following commands to copy the **AppDeployToolkit & Files** folders to “C:\Downloads\AuthyDesktop”:
      -  Copy-Item `--Path "C:\Downloads\PADT\Toolkit\AppDeployToolkit" -Destination "C:\Downloads\AuthyDesktop\AppDeployToolkit" -Recurse`
      -  Copy-Item `--Path "C:\Downloads\PADT\Toolkit\Files" -Destination "C:\Downloads\AuthyDesktop\Files"`
7. We also need to create two additional directories called x86 & x64
      -  New-Item "C:\Downloads\AuthyDesktop\Files\x86" -ItemType Directory
      -  New-Item "C:\Downloads\AuthyDesktop\Files\x64" -ItemType Directory
  
You should now see the **AppDeploymentToolkit** folder with files & the **Files** directory with empty **x86 & x64** folders at “C:\Downloads\AuthyDesktop“
