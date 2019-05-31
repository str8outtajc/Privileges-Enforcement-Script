# privileges enforcement

### Overview
This script is meant to be a helper tool of sorts for SAP's Privileges application

### Use Case
If Privileges.app elevates a user to local admin (without using the toggle feature), that user remains a local admin until next login.  Some cyber security departments are not satisfied with this.  `privsenforcement.sh` attempts to solve this problem.

### General Design and Intent
- Script is designed to be run as part of a JAMF cached policy and scoped to users with Privileges.app installed.  
- Depending on your needs, you could run Once a Day, every check-in, every network state change, etc.  
- Recommendation is to only run on every check-in if your check-in interval is an hour or more.  
- Network state change is a great option b/c it is less likely to impact a user's work.  
- Parameter 4 is set up as an option for "X" number of minutes, where "X" is an integer.

### Intended Behaviors
- If no user is logged in, exit  
- If logged in user is not a technician, exit
- If logged in user is not an admin, exit  
- If logged in user is an admin, but privileges not installed - revoke admin access  
- If logged in user is an admin, but privileges did not elevate permissions in past "X" minutes, revoke access using Privileges CLI.  In this case, the dock icon changes color appropriately.  

### Variables to Edit
1. Set `myOrgPrefix` to your organization (e.g. com.acme )
  - Do __NOT__ include a trailing '.'
  - This is used only for a run-once launch agent  
2. Set `myOrgLocalTechAccount` to the short name of any local admin account you have deployed for help desk, admins, field services, etc. where you would _not_ want enforcement to run  
  - If you have more than one, you will have to add those to the first condition check under `MAIN`  

### Important info regarding validation of future versions of Privileges
With each new release of `Privileges.app` - verify enforcement script will work properly by doing the following:

1. Use the app to elevate permissions
2. Run command below

`log show --predicate '(subsystem == "com.apple.Authorization") && (process == "authd") && (eventMessage contains "/Library/PrivilegedHelperTools/corp.sap.privileges.helper")' --last "$minutes"m --style compact | grep 'authorizing right' ; echo $?`

3. If result is `0` - all is well
