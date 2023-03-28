#!/bin/sh
success_color=71
warning_color=3
error_color=52
message_color=61
general_color=212
ok_emoji=':heavy_check_mark:'
not_ok_emoji=':x:'

is_command_successful=0

gum style \
	--foreground $general_color --border-foreground 212 --border double \
	--align center --width 60 --margin "1 2" --padding "2 4" \
	'Welcome to Flojoy!' 'For Installation, Follow the Link Below' 'https://docs.flojoy.io/getting-started/install/'


venv=""

# gum spin --spinner dot --title 'test' -- npx ttab -t 'test' "source $venv && pip install -r requirements.txt;exit"

djangoPort=8000
initNodePackages=true
initPythonPackages=true

feedback()
{
   is_successful=$1
   message=$2
   help_message=$3
   if [ $is_successful -eq 0 ]; then
      gum style --foreground $success_color ":heavy_check_mark: $message" | gum format -t emoji
   else
      gum style --foreground $error_color ":x: $message : $help_message" | gum format -t emoji
      exit
   fi
}


createSystemLinks()
{

   FILE=$PWD/PYTHON/WATCH/STATUS_CODES.yml
   if test -f "$FILE"; then
      gum style --foreground $warning_color ":point_right: $FILE exists." | gum format -t emoji
      is_command_successful=$(($is_command_successful+$?))
   else
      ln STATUS_CODES.yml PYTHON/WATCH/
      is_command_successful=$(($is_command_successful+$?))
   fi

   FILE=$PWD/src/STATUS_CODES.yml
   if test -f "$FILE"; then
      gum style --foreground $warning_color ":point_right: $FILE exists." | gum format -t emoji
      is_command_successful=$(($is_command_successful+$?))
   else
      ln STATUS_CODES.yml src
      is_command_successful=$(($is_command_successful+$?))
   fi
}

helpFunction()
{
   gum style --foreground $message_color ""
   gum style --foreground $message_color "Usage: $0 -n -p -r -v venv-path"
   gum style --foreground $message_color  " -r: shuts down existing redis server and spins up a fresh one"
   gum style --foreground $message_color  " -v: path to a virtualenv"
   gum style --foreground $message_color  " -n: To not install npm packages"
   gum style --foreground $message_color  " -p: To not install python packages"
   gum style --foreground $message_color 1 # Exit script after printing help
}

# Parse command-line arguments
while [ $# -gt 0 ]
do
    key="$1"
    case $key in
        -n)
        initNodePackages=false
        shift
        ;;
        -p)
        initPythonPackages=false
        shift
        ;;
        -r)
        initRedis=true
        shift
        ;;
        -v)
        venv="$2"
        shift
        shift
        ;;
        -P)
        djangoPort="$2"
        shift
        shift
        ;;
        *) # unknown option
        gum style --foreground $message_color "Unknown option: $1"
        helpFunction
        exit 1
        ;;
    esac
done

# checking if flojoy.yaml file exists

CWD="$PWD"

FILE=$HOME/.flojoy/flojoy.yaml
if test -f "$FILE"; then
   touch $HOME/.flojoy/flojoy.yaml
   echo "PATH: $CWD" > $HOME/.flojoy/flojoy.yaml
   gum style --foreground $warning_color ":point_right: $FILE exists." | gum format -t emoji

else
   gum style --foreground $warning_color ":point_right: directory ~/.flojoy/flojoy.yaml does not exists. Creating new directory with yaml file." | gum format -t emoji

   mkdir $HOME/.flojoy && touch $HOME/.flojoy/flojoy.yaml

   is_command_successful=$?

   echo "PATH: $CWD" > $HOME/.flojoy/flojoy.yaml

   is_command_successful=$(($is_command_successful+$?))

   feedback $is_command_successful 'Creating new directory with yaml file.' 'failed to create file in the home directory, check the permission or sign in as root user'
fi

# checking virtual environment

venvCmd=""

if [ ! -z "$venv" ]
then
   gum style --foreground $warning_color ":point_right: virtualenv path is provided, will use: ${venv}" | gum format -t emoji
   venvCmd="$CWD/${venv}bin/activate"
   gum style --foreground $warning_color ":point_right: venv cmd: ${venvCmd}" | gum format -t emoji
else
   venv_dir=$HOME/.flojoy/venv
   if test -d "$venv_dir";then
      gum style --foreground $warning_color ":point_right: $venv_dir exists. Will use venv from this directory" | gum format -t emoji
      venvCmd="$HOME/.flojoy/venv/bin/activate"
   else
      gum style --foreground $warning_color ":point_right: $venv_dir does not exists." | gum format -t emoji

      gum spin --spinner dot --title 'creating virtual environment...' --title.foreground="$general_color" -- sleep 2 && cd $HOME/.flojoy && mkdir venv && python3 -m venv venv/

      feedback $? 'virtual environment creation successful' 'failed to create virtual environment, check if if python is installed in your local machine'

      venvCmd="$HOME/.flojoy/venv/bin/activate"
   fi
fi

# installing node packages

if [ $initNodePackages = true ]
then
   gum style --foreground $message_color ' -n flag is not provided, Node packages will be installed from package.json'

   gum spin --spinner dot --title 'Installing Node packages...' --title.foreground="$general_color" -- sleep 2 && cd $CWD && npm install --legacy-peer-deps

   feedback $? 'Installing Node packages...' 'check if npm is installed in your local machine'
fi

#installing python packages & starting the django server

if [ $initPythonPackages = true ]
then
   gum style --foreground $warning_color ":point_right: -p flag is not provided, python packages will be installed from requirements.txt file" | gum format -t emoji

   if lsof -Pi :$djangoPort -sTCP:LISTEN -t >/dev/null ; then
      djangoPort=$((djangoPort + 1))

      gum spin --spinner dot --title "A server is already running on $((djangoPort - 1)), starting Django server on port $djangoPort..." --title.foreground="$general_color" -- npx ttab -t 'Django' "gum style --foreground $general_color 'Welcome to Django Server! :wave: ' '' 'Here you can monitor the backend LOGS of the Jobs, queued By Flojoy-Watch Worker' '' | gum format -t emoji;source $venvCmd && pip install -q -r requirements.txt && python3 write_port_to_env.py $djangoPort && python3 manage.py runserver ${djangoPort}"


   else

      gum spin --spinner dot --title "starting django server on port $djangoPort..." --title.foreground="$general_color" -- npx ttab -t 'Django' "source $venvCmd && pip install -q -r requirements.txt && python3 write_port_to_env.py $djangoPort && python3 manage.py runserver ${djangoPort}"

   fi

else
   if lsof -Pi :$djangoPort -sTCP:LISTEN -t >/dev/null ; then
      djangoPort=$((djangoPort + 1))

      gum spin --spinner dot --title 'A server is already running on $((djangoPort - 1)), starting Django server on port ${djangoPort}...' --title.foreground="$general_color" -- npx ttab -t 'Django' "source $venvCmd && python3 write_port_to_env.py $djangoPort && python3 manage.py runserver ${djangoPort}"
   else
      gum spin --spinner dot --title 'starting django server on port ${djangoPort}...' --title.foreground="$general_color" -- npx ttab -t 'Django' "source $venvCmd && python3 write_port_to_env.py $djangoPort && python3 manage.py runserver ${djangoPort}"
   fi
fi

feedback $? "starting django server on port $djangoPort..." 'check if django is installed in your local machine'

# update ES6 status codes file

gum spin --spinner dot --title 'update ES6 status codes file...' --title.foreground="$general_color" -- python3 -c 'import yaml, json; f=open("src/STATUS_CODES.json", "w"); f.write(json.dumps(yaml.safe_load(open("STATUS_CODES.yml").read()), indent=4)); f.close();'

feedback $? 'update ES6 status codes file...' 'check your python version, we use python3.10 in our project'

# creating system links

gum spin --spinner dot --title 'create symlinks...' --title.foreground="$general_color" -- sleep 2 && createSystemLinks

feedback $is_command_successful 'create symlinks...' 'check your PYTHON/WATCH or src folder, maybe one of them is missing'

# jsonify python functions

gum spin --spinner dot --title 'jsonify python functions and write to JS-readable directory' --title.foreground="$general_color" -- python3 write_python_metadata.py

feedback $? 'jsonify python functions and write to JS-readable directory' 'check write_python_metadata.py file, maybe the folders mentioned in the file, one of is missing or check your python version, we use 3.10 or later version in our project'

# Generating Manifest

gum spin --spinner dot --title 'generate manifest for python nodes to frontend' --title.foreground="$general_color" -- python3 generate_manifest.py

feedback $? 'generate manifest for python nodes to frontend' 'check generate_manifest.py file, maybe the folders mentioned in the file, one of is missing or check your python version, we use 3.10 or later version in our project'

# initializing new Redis Instance

if [ $initRedis ]
then

   gum spin --spinner dot --title 'shutting down any existing redis server and clearing redis memory...' --title.foreground="$general_color" -- npx ttab -t 'REDIS-CLI' "redis-cli SHUTDOWN;sleep 2;redis-cli FLUSHALL;exit"

   feedback 'shutting down any existing redis server and clearing redis memory...' 'redis-cli error: check if redis-cli is running or redis is installed in your local machine'

   gum spin --spinner dot --title 'spining up a fresh redis server...' --title.foreground="$general_color" -- npx ttab -t 'REDIS-CLI' "redis-server;sleep 2;exit"

   feedback 'spining up a fresh redis server...' 'try closing and restarting the redis server'
fi

# Closing All RQ Workers

gum spin --spinner dot --title 'closing all existing rq workers (if any)' --title.foreground="$general_color" -- python3 close-all-rq-workers.py

feedback $? 'closing all existing rq workers (if any)' 'failed to close rq worker, check if rq worker is installed in python packages or run the commands without -p argument'

# SHowing RQ WOrker Info

gum style --foreground $warning_color 'rq info after closing:'
rq info

# Initializing FLOJOY-WATCH RQ Worker

gum spin --spinner dot --title 'starting redis worker for flojoy-watch' --title.foreground="$general_color" -- npx ttab -t 'Flojoy-watch RQ Worker' "gum style --foreground $general_color 'Welcome to Flojoy-Watch, RQ WORKER QUEUE! :wave: ' '' 'Here you can monitor LOGS of the Jobsets, queued by our scheduler' '' | gum format -t emoji;source $venvCmd && export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES && rq worker flojoy-watch"

feedback $? 'starting redis worker for flojoy-watch' 'check if ttab is installed ( npx ttab) or check if rq worker is installed in your python package'

# Initializing FLOJOY RQ Worker

gum spin --spinner dot --title 'starting redis worker for nodes...' --title.foreground="$general_color" -- npx ttab -t 'RQ WORKER' "gum style --foreground $general_color 'Welcome to Flojoy RQ WORKER QUEUE! :wave: ' '' 'Here you can monitor LOGS of the Jobs, queued By Flojoy-Watch Worker' '' | gum format -t emoji;source $venvCmd && cd PYTHON && export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES && rq worker flojoy"


# Checking for YOLOV3 Weights


CWD="$PWD"

FILE=$PWD/PYTHON/utils/object_detection/yolov3.weights
if test -f "$FILE"; then
   gum style --foreground $warning_color ":point_right: $FILE exists." | gum format -t emoji
else
   touch $PWD/PYTHON/utils/object_detection/yolov3.weights
   wget -O $PWD/PYTHON/utils/object_detection/yolov3.weights https://pjreddie.com/media/files/yolov3.weights
fi

sleep 1

# Initializing React Server

gum spin --spinner dot --title 'starting react server...' --title.foreground="$general_color" -- npx ttab -t 'REACT' "source $venvCmd && npm start"
feedback $? 'starting react server...' 'check is npm installed in your local machine or run the script without -n flag to install the node packages'