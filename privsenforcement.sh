#!/bin/bash

currentUser=$(stat -f %Su /dev/console)
currentUserID=`/usr/bin/id -u $currentUser`
privCLI="/Applications/Privileges.app/Contents/Resources/PrivilegesCLI"
minutes="$4"
myOrgPrefix="com.myorg"
myOrgLocalTechAccount="myorglocaladmin"

buildTempLaunchD ()
{
  # This is the right way to launch a command in user's context
  # This will enable the icon to change colors as if user ran command
  tempPlistDir=$(mktemp -d /private/tmp/privaux.XXXX)
  tempPlistFile="$tempPlistDir/$myOrgPrefix.privenforce.plist"
  defaults write "$tempPlistFile" Label "$myOrgPrefix.privenforce"
  defaults write "$tempPlistFile" LimitLoadToSessionType "Aqua"
  defaults write "$tempPlistFile" RunAtLoad -bool true
  defaults write "$tempPlistFile" KeepAlive -bool false
  defaults write "$tempPlistFile" ProgramArguments -array "/Applications/Privileges.app/Contents/Resources/PrivilegesCLI" "--remove"
  chown root:wheel "$tempPlistFile"
  chmod 644 "$tempPlistFile"
}

revokeAdminRights ()
{
  # Runs the launchd created in buildTempLaunchD function
  # Must "bootout" first to avoid potential "already loaded" errors
  buildTempLaunchD
  launchctl bootout gui/$currentUserID "$tempPlistFile" || true
  launchctl bootstrap gui/$currentUserID "$tempPlistFile"
}

revokeAdminManual ()
{
  # The old fashion method of Privs CLI doesn't work
  dseditgroup -o edit -d "$currentUser" admin
}

# checkAdmin

checkAdmin ()
{
  # Standard test for checking if user is admin
  if ! /usr/sbin/dseditgroup -o checkmember -m $currentUser admin > /dev/null 2>&1 ;then
    exit 0
  fi
}

checkPrivApp ()
{
  # If the app CLI is in the right place and executable - all is well
  # Otherwise - revoke admin old fashion way
  if [[ ! -f "$privCLI" || ! -x "$privCLI" ]]
    then revokeAdminManual ;exit 0
  fi
}

# Using the log command to see if Privs was used in last "X" minutes/hours/etc
checkPrivLastUse ()
{
  if log show --predicate '(subsystem == "com.apple.Authorization") && (process == "authd") && (eventMessage contains "/Library/PrivilegedHelperTools/corp.sap.privileges.helper")' --last "$minutes"m --style compact | grep 'authorizing right' > /dev/null 2>&1
    then exit 0
  else revokeAdminRights ;exit 0
  fi
}

### MAIN ###
# Not doing anything at all if a real user is not logged in.
if [[ "$currentUser" = "" || "$currentUser" = "root" || "$currentUser" = "$myOrgLocalTechAccount" ]]
  then exit 0
else
  checkAdmin
  checkPrivApp
  checkPrivLastUse
fi
