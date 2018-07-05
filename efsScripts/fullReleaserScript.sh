#!/bin/bash
repo=https://MthreeDelegate:AlumniTrain%40M3%2FT1@bitbucket.org/mthree_consulting/javademos.git
function versionIncrement {
        split=`tr "_" " " <<< $1` #turns the underscore into a space so awk can read it
        newVersion=$((`awk '{print $2}' <<< $split`+1)) #grabs the version number and adds 1
}

function getCurrent { #function that returns the name of the latest version - meta,project and name are parameters
	currentVersion=`ls -lv $thePath | grep $name | grep -v 'DEV\|UAT\|PROD' | awk '{print $9}' | tail -1`

}

function createNewVersion { #creates a new dev release and downloads the code so the devs can start working on it
	efs create release $meta $project "$name"_"$newVersion"
	git clone $repo "$thePath"/"$name"_"$newVersion"/src/
}

if  [ -z "$1" ]; then # Ensures all the parameters are present so the program can function
	echo "You need to enter the username_function, meta and project names"
	exit 1 # notifies user if they have missed something and exits with an error code
elif [ -z "$3" ]; then
	echo "You need to enter the meta or project name"
	exit 1
else


meta=$2 #puts real words on the parameters so its a bit more readable
project=$3

split=`tr "_" " " <<< $1`
name=`awk '{print $1}' <<< $split` #splits the project name and desired function to separate variables
task=`awk '{print $2}' <<< $split`

thePath=/efs/dev/"$meta"/"$project"/ #creates the path of the efs project

getCurrent #finds out what the current version is
versionIncrement $currentVersion #using previous result determines next version

case $task in
	newDevRelease)
		createNewVersion #creates new dev version and clones the repo
		exit 0 # I use exit 0 at the end of most cases as they have executed without errors
	;;
	newDevReleaseAdvanced) #creates new dev version, clones the repo and creates a common install location, then copies
		createNewVersion #then copies the code into the common folder and creates a release link for installing on
		efs create install $meta $project "$name"_"$newVersion" common #  to a dev testing environment
		cp -r "$thePath"/"$name"_"$newVersion"/src/* "$thePath"/"$name"_"$newVersion"/install/common
		efs create releaselink $meta $project "$name"_"$newVersion" "$name"_DEV
		echo New advanced Dev release successfully created
		exit 0
	;;
	promoteDevToUAT)
		devVers=`readlink -f "$name"_DEV | tr "/" " " | awk '{print $NF}'` #returns the name of the latest dev release
                efs checkpoint $meta $project "$name"_DEV #locks the source code so devs can no longer modify this version
                efs dist release $meta $project "$name"_DEV #creates a release in /efs/dist for the current dev version
                efs create releaselink $meta $project $devVers "$name"_UAT #creates a symbolic link in dev/ for the UAT team to use
                efs dist release $meta $project "$name"_UAT #creates a release in /efs/dist for the UAT version
		echo Dev version successfully promoted to UAT
		exit 0
	;;
	promoteUATtoProd)
		UATVers=`readlink -f "$name"_UAT | tr "/" " " | awk '{print $NF}'` #returns the name of the latest UAT release
		efs create releaselink $meta $project $UATVers "$name"_PROD #creates a symbolic link that points to the original dev release of the current UAT version
                efs dist release $meta $project "$name"_PROD #copies the PROD release from dev to dist
		echo UAT version successfully promoted to Production
		exit 0
	;;
	*) # catch all case to tell the user they entered a wrong function in the 1st parameter
		echo You entered an incorrect function, only the following are acceptable:
		echo VersionName_newDevRelease
		echo VersionName_newDevReleaseAdvanced
		echo VersionName_promoteDevtoUAT
		echo VersionName_promoteUATtoProd
		exit 1 #exits with an error code
esac
fi
