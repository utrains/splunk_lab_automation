	#!/bin/bash
    
    if [ $1 -eq 0 ]; then
		echo ">>>>>>>>>>>>>>>> $2 : $3 SUCESS <<<<<<<<<<<<<<<<"
		echo "$2 is installed Successfully"
		echo ">>>>>>>>>>>>>>>> Thanks to configure $3 <<<<<<<<<<<<<<<<"
	else
		echo "**************** $2 : Service $3 Failled ****************"
		echo " Sorry, we can't continue with this installation. Please check why the $3 service has not been installed."
		exit 1
	fi