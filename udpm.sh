#!/bin/sh

# ______            _                ______
# \ \ \ \ _   _  __| |_ __  _ __ ___ \ \ \ \
#  \ \ \ \ | | |/ _` | '_ \| '_ ` _ \ \ \ \ \
#  / / / / |_| | (_| | |_) | | | | | |/ / / /
# /_/_/_/ \__,_|\__,_| .__/|_| |_| |_/_/_/_/
#                    |_| v1.0
# GitHub: https://github.com/SpyHoodle/updm

# Don't let the user run as sudo (and warn them) - this script requires an existing user account
[ "$EUID" -eq 0 ] && { printf "\033[31;1mThis script should NEVER be ran as root!\033[0m\n\033[31mIt \033[4mrequires\033[0m \033[31ma user account to made and excecuting it.\033[0m\nRunning as root could damage essential files on your system.\nYour root password will be asked when required.\n"; exit 1 ;}

# Global variables
errors=0
script_dir=$(pwd)

# For logging and writing to the terminal
log() { printf "\033[35m[udpm]\033[0m $@\n" ;}
error() { log "\033[31;1merror:\033[0m $1"; errors=$((errors+1)) ;}
warn() { log "\033[33;1mwarning:\033[0m $1" ;}
success() { log "\033[32;1msuccess:\033[0m $1" ;}

# Options
while getopts ":f:p:r:h:" o; do case "${o}" in
  h) echo -e "-f list file to iterate through\n-p default package manager command\n-r directory to store repositories\n-h the help message"; exit 1 ;;
  f) listfile=${OPTARG} ;;
  p) pkgman=${OPTARG} ;;
  r) reposdir=${OPTARG} ;;
  *) error "Invalid option or value: -${OPTARG}"; exit 1 ;;
esac done

# Default variables
[ -z "$listfile" ] && listfile="list.csv"
[ -z "$pkgman" ] && pkgman="paru --noconfirm --needed -S"
[ -z "$reposdir" ] && reposdir="/home/$USER/.local/src"

pkg_install()
{
	# $1: Package name (required)
	# $2: Package manager command (optional)
	[ -z "$1" ] && { error "package name required when installing a package"; return 1 ;}

	# If a package manager command is specified, then use that, else, use the default package manager variable
	[ ! -z "$2" ] && pkgcmd=$2 || { pkgcmd="$pkgman" ;}

	# Install the package using the command and check for errors
	log "\033[34;1minstalling:\033[0m \033[35m$1\033[0m with \033[36m'$pkgcmd'\033[0m"
	$pkgcmd $1 || { error "couldn't install '$1'"; return 1 ;}

	# Must be a success
	success "installed \033[35m$1\033[0m"
}

pkg_install()
{
	# $1: Package name (required)
	[ -z "$1" ] && { error "package name required when installing a package"; return 1 ;}

	# Install the package using the command and check for errors
	log "\033[34;1minstalling:\033[0m \033[35m$1\033[0m with \033[36mpip\033[0m"
	pip install --user $1 || { error "couldn't install '$1'"; return 1 ;}

	# Must be a success
	success "installed \033[35m$1\033[0m"
}

cmd_execute()
{
	# $1: The command to excecute (required)
	[ -z "$1" ] && { error "command required when executing a command"; return 1 ;}

	# Change back to the script directory, in case commands are run releative to that directory
	cd $script_dir

	# Exceute the command and check for errors
	log "\033[34;1mexecuting:\033[0m \033[35m'$1'\033[0m"
	$1 || { error "couldn't properly execute '$1'"; return 1 ;}

	# Must be a success
	success "executed \033[35m'$1'\033[0m"
}

git_placerepo()
{
	# $1: Git repository URL (required)
	# $2: Git branch (optional)
	# $3: Location to install to (required)
	[ -z "$1" ] && { error "git repository URL required when placing a git repository"; return 1 ;}
	[ -z "$3" ] && { error "the directory to install the git repository to is required when placing a git repository"; return 1 ;}

	# Get the repository name and directories
	reponame="$(basename "$1" .git)"
	dir=$(mktemp -d)
	[ ! -d "$3" ] && mkdir -p "$3"

	# Get the branch of the repository
	[ ! -z "$3" ] && branch=$3 || log "\033[33;1mwarning:\033[0m branch not specified for $reponame, assuming master"; branch="master"

	# Clone the repository and check for errors
	log "\033[34;1mplacing:\033[0m \033[35m$1\033[0m into \033[36m$3\033[0m"
	chown "$USER":wheel "$dir" "$3" ||
		{ error "couldn't chown $dir and $3"; return 1 ;}
	sudo -u "$USER" git clone --recursive -b "$branch" --depth 1 --recurse-submodules "$1" "$dir" || { error "couldn't clone $1 to $dir"; return 1 ;}

	# Copy the repository to the specified directory and check for errors
	sudo -u "$USER" cp -rfT "$dir" "$3" || { error "couldn't copy $dir to $3"; return 1 ;}

	# Must be a success
	success "installed \033[35m$1\033[0m"
}

git_install()
{
	# $1: Git repository URL (required)
	# $2: Git branch (optional)
	[ -z "$1" ] && { error "git repository URL required when installing a git repository"; return 1 ;}

	# Get the repository name and directory
  reponame="$(basename "$1" .git)"
  dir="$reposdir/$reponame"

	# Get the branch of the repository
	[ ! -z "$2" ] && branch=$2 || { log "\033[33;1mwarning:\033[0m branch not specified for $reponame, assuming master" && branch="master" ;}

	# Clone the repository, if it already exists then pull the repository and merge, accounting for any errors
	log "\033[34;1minstalling:\033[0m \033[35m$1\033[0m to \033[36m$dir\033[0m"
          sudo -u "$USER" git clone --depth 1 "$1" "$dir" || # Clone normally
		{ { cd "$dir" || { error "couldn't change directory to $dir"; return 1 ;} ;}; # Therefore change to existing repo
			sudo -u "$USER" git pull --force origin $branch || { error "can't find branch '$branch'"; return 1 ;} ;} # Merge if existing

	# Enter the repository
	cd $dir || { error "couldn't change directory to $dir"; return 1 ;}

	# Success, return 0
	return 0
}

git_runscript()
{
	# $1: Git repository URL (required)
	# $2: Git branch (optional)
	# $3: Script to execute (required)
	[ -z "$1" ] && { error "git repository URL required when placing a git repository"; return 1 ;}
	[ -z "$3" ] && { error "the script to execute is required when executing a script to install a git repository"; return 1 ;}

	# Clone and install the git repository
	git_install "$1" "$2" || { error "couldn't install $1"; return 1 ;}

	# Make the script executable and execute it
	log "\033[36mexecuting:\033[0m \033[35m'$3'\033[0m"
	sudo chmod +x $3 || { error "couldn't make $dir/$3 executable with chmod +x"; return 1 ;}
	./$3 || { error "couldn't properly execute $dir/$3"; return 1 ;}

	# Must be a success
	success "installed \033[35m$1\033[0m"
}

git_runcommand()
{
	# $1: Git repository URL (required)
	# $2: Git branch (optional)
	# $3: Command to execute (required)
	[ -z "$1" ] && { error "git repository URL required when installing a git repository"; return 1 ;}
	[ -z "$3" ] && { error "command required when executing a command to install a git repository"; return 1 ;}

	# Clone and install the git repository
	git_install "$1" "$2" || { error "couldn't install $1"; return 1 ;}

	# Run the command
	log "\033[36mexecuting:\033[0m \033[35m'$3'\033[0m"
  $3 || { error "couldn't properly execute '$3'"; return 1 ;}

	# Must be a success
	success "installed \033[35m$1\033[0m"
}

git_dotfiles()
{
	# $1: Git repository URL (required)
	# $2: Git branch (optional)
	# $3: Location to install to (required)
	[ -z "$1" ] && { error "git repository URL required when placing a dotfiles git repository"; return 1 ;}
	[ -z "$3" ] && { error "the dotfiles directory to install the git repository to is required when placing a dotfiles git repository"; return 1 ;}

	# Place the dotfiles repository
	git_placerepo "$1" "$2" "$3" || error "couldn't place dotfiles repository"

	# Remove unnessecary files from the directory
	rm -rf /home/$USER/{".git","README.md","LICENCE","FUNDING.yml"}
}

installation_loop()
{
	([ -f "$listfile" ] && cp "$listfile" /tmp/progs.csv) || curl -Ls "$listfile" | sed '/^#/d' > /tmp/progs.csv
	while IFS=, read -r tag item config_var_1 config_var_2; do
		case "$tag" in
			"DOT") git_dotfiles "$item" "$config_var_1" "/home/$USER" ;; # Dotfiles
			"PUT") git_placerepo "$item" "$config_var_1" "$config_var_2" ;; # Put a git repository into a directory
			"GIT") git_runcommand "$item" "$config_var_1" "$config_var_2" ;; # Run a command in a git repository to install it
			"SCR") git_runscript "$item" "$config_var_1" "$config_var_2" ;; # Run a script in a git repository to install it
			"PAC") pkg_install "$item" "$config_var_1" ;; # Install a package with the option to use a custom command
			"PAC") pip_install "$item" "$config_var_1" ;; # Install a pip package
			"EXC") cmd_execute "$item" ;; # Execute a custom command
		esac
	done < /tmp/progs.csv
}

# Welcome message
echo -e "\033[35;1m______            _                ______
\ \ \ \ _   _  __| |_ __  _ __ ___ \ \ \ \\
 \ \ \ \ | | |/ _\` | '_ \| '_ \` _ \ \ \ \\ \\
 / / / / |_| | (_| | |_) | | | | | |/ / / /
/_/_/_/ \__,_|\__,_| .__/|_| |_| |_/_/_/_/
                   |_|\033[0m"
printf "\033[35mUniversal dotfiles and packages manager v1.0\033[0m

\033[36mInstallation will use:\033[0m
\033[34m- Listfile: \033[32m$listfile\033[0m
\033[34m- Default package manager command: \033[32m$pkgman\033[0m
\033[34m- Repositories directory: \033[32m$reposdir\033[0m\n\n"

# Get the user to confirm before continuing
printf "\033[31mProceeding will overwrite any existing files during the installation process.\033[0m\n"
read -p "Enter 'yes' and continue to the installation: " choice
[ $choice != "yes" ] && exit 1

# Begin the installation loop
installation_loop

# Finished!
log "The installation process has finished... Enjoy!"
[ $errors -eq 0 ] || warn "There were $errors errors."
