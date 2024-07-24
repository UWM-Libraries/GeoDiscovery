#!/bin/bash

LOG_FILE="/var/www/rubyapps/uwm-geoblacklight/current/log/geocombine_pull_and_index.log"
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
echo "Geocombine Pull and Index script running at: $current_time" >> $LOG_FILE

export OGM_PATH="/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/"
export RAILS_ENV=production
export SCHEMA_VERSION=Aardvark

# Set the working directory
WORK_DIR="/var/www/rubyapps/uwm-geoblacklight/current"
cd $WORK_DIR || { echo "Failed to change directory to $WORK_DIR"; exit 1; }

run_rake_task() {
    local task=$1
    echo "Running task: $task at: $(date)" >> $LOG_FILE
    bundle exec rake $task >> $LOG_FILE 2>&1
    if [ $? -ne 0 ]; then
        echo "Error running task: $task at: $(date)" >> $LOG_FILE
    else
        echo "Successfully ran task: $task at: $(date)" >> $LOG_FILE
    fi
}

tasks=(
    "geocombine:pull[edu.uwm]"
    "geocombine:pull[edu.uchicago]"
    "geocombine:pull[edu.illinois]"
    "geocombine:pull[edu.indiana]"
    "geocombine:pull[edu.uiowa]"
    "geocombine:pull[edu.umd]"
    "geocombine:pull[edu.msu]"
    "geocombine:pull[edu.umn]"
    "geocombine:pull[edu.unl]"
    "geocombine:pull[edu.nyu]"
    "geocombine:pull[edu.osu]"
    "geocombine:pull[edu.psu]"
    "geocombine:pull[edu.purdue]"
    "geocombine:pull[edu.rutgers]"
    "geocombine:pull[edu.umich]"
    "geocombine:pull[edu.berkeley]"
    "geocombine:pull[edu.wisc]"
    "geocombine:pull[edu.columbia]"
    "geocombine:pull[edu.cornell]"
    "geocombine:pull[edu.princeton.purl]"
    "geocombine:pull[edu.stanford.arks]"
    "uwm:opendataharvest:gbl1_to_aardvark"
    "uwm:index:delete_all"
    "geocombine:index"
)

for task in "${tasks[@]}"; do
    run_rake_task $task
done

current_time=$(date "+%Y.%m.%d-%H.%M.%S")
echo "Geocombine Pull and Index script finished at: $current_time" >> $LOG_FILE
