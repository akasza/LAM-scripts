# LAM-scripts
The script will generate a correct initial CSV user file for batch processing.

Software needed:
- Ubuntu Linux
- Samba4/AD
- LDAP Account Manager
- pwgen

=============================================================================
Usage of the script:

  $(basename $0) -f /path/to/input/file -d domain.apex [-g] [-e] [-p]

	Mandatory switches:

	  -f | --file     /path/to/input/file

	     The script assumes that:
		- each user is in new a line,
        	- the attributes are separated with spaces, and
		- structured as the following (see the example file provided):
		
		    FirstName LastName Email (...) GroupName

	  -d | --domain     example.com

	Optional standalone switches:

	  -g | --group      if present: search for groups in file
	  -e | --email 	    if present: search for emails in file
	  -p | --pw-expire  if present: set default expiry for passwords
