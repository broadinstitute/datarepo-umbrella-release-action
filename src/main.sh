#!/bin/bash

parseInputs () {
  # Required inputs
  if [ "${INPUT_HELM_CHARTS}" != "" ]; then
    export helm_charts=${INPUT_HELM_CHARTS}
  else
    echo "Input helm_charts cannot be empty"
    exit 1
  fi

  if [ "${INPUT_UMBRELLA_NAME}" != "" ]; then
    export umbrella_name=${INPUT_UMBRELLA_NAME}
  else
    echo "Input umbrella_name cannot be empty"
    exit 1
  fi
}

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

helmchartrelease () {
for i in $(echo $helm_charts | sed "s/,/ /g")
do
  currentverion=$(yq r charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).version")
  newversion=$(yq r charts/${i}/Chart.yaml 'version')
  printf "chartname: ${i}, current: ${currentverion}, new: ${newversion}\n\n"
  if [[ ${currentverion} == "" ]]; then
    printf "No version of this chart exists in the umbrella chart adding ${i}\n\n"
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies[+].name" ${i}
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).version" ${newversion}
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).repository" "https://broadinstitute.github.io/datarepo-helm/"
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).condition" "${i}.enabled"
    printf "printing new charts/${umbrella_name}/Chart.yaml\n\n"
    cat charts/${umbrella_name}/Chart.yaml
  elif [ $(version ${newversion}) -gt $(version ${currentverion}) ]; then
    printf  "Updating chart verion of ${i} to ${newversion}\n\n"
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).version" ${newversion}
    printf "printing new charts/${umbrella_name}/Chart.yaml"
    cat charts/${umbrella_name}/Chart.yaml
  elif [ $(version ${newversion}) -eq $(version ${currentverion}) ]; then
    printf "No new version for release for ${i}\n\n"
  elif [ $(version ${newversion}) -lt $(version ${currentverion}) ]; then
    printf "Current umbrella chart ${i} is ahead of the subchart you may need to release a new subchart version\n\n"
  else
    printf "Error chart updating subchart ${i}\n\n"
  fi
done
}

helmpackage () {
  helm repo add datarepo-helm https://broadinstitute.github.io/datarepo-helm
  helm repo update
  helm package charts/${umbrella_name} --destination .deploy -u
}

main () {
  parseInputs
  helmchartrelease
  helmpackage
}

main "${*}"
