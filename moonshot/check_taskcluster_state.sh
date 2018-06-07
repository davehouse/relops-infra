#!/usr/bin/env bash

function check_tc() {

    basename=$1
    hostname=${basename%%.*}
    dc_name=$(echo $basename | sed -e "s/.*\(mdc1\|mdc2\).*/\1/")
    
    worker_types=$(wget -q -O - https://queue.taskcluster.net/v1/provisioners/releng-hardware/worker-types/ | grep '\"workerType\"' | sed -e 's/.* "\([^"]*\)",$/\1/')
    workerType="gecko-t-linux-talos"
    for workerType in $worker_types; do
        taskId=$(wget -q -O - https://queue.taskcluster.net/v1/provisioners/releng-hardware/worker-types/${workerType}/workers/${dc_name}/${hostname} | grep 'taskId\|quarantine' | tail -1 | sed -e 's/quarantineUntil["\": ]*/ " "'${hostname}' quarantined /' | cut -d'"' -f4)
        if [[ ${#taskId} -gt 0 ]]; then
            break
        fi
    done
    {
       wget -q -O - https://queue.taskcluster.net/v1/task/${taskId}/status \
            | grep 'workerId\|started\|"state"' | tr '\n' ' ' \
            | sed -e 's/\"\([^ ]*\)\"[:]\?/ \1 /g' -e 's/state.*state//' | awk '{print $4" "$1" "$7}'
    } \
    | grep -o "${hostname}[^\",]*" || echo "${hostname} not found $taskId";
}

export -f check_tc

log=moonshot_taskcluster_state.$(date +"%H:%M:%S").log
moons=$(./moons.sh)
echo -e "$moons" \
    | xargs --max-procs=24 -I{} bash -c "check_tc {}" \
    >> $log

expected=$(echo -e "$moons"|wc -l)
missing=$(grep "not found" $log|wc -l)
total=$(grep 'running\|completed' $log|wc -l)
active=$(grep running $log|wc -l)
idle=$(grep completed $log|wc -l)

grep "not found" $log | sort
if [[ $missing -gt 0 ]]; then
    missing_detail="/$expected (missing $missing)"
else
    missing_detail=''
fi
echo "total $total$missing_detail, active $active, idle $idle"
