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


helmchartrelease () {
helm repo add datarepo-helm https://broadinstitute.github.io/datarepo-helm
helm repo update
for i in ${helm_charts}
do
  currentverion=$(yq r charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).version")
  newversion=$(yq r charts/${i}/Chart.yaml 'version')
  if [ "${newversion}" -gt "${newversion}" ]; then
    printf  "Updating chart verion of ${i} to ${newversion}\n"
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).version" ${newversion}
  elif [ "${newversion}" -eq "${newversion}" ]; then
    printf "No new version for release for ${i}\n"
  elif [ "${newversion}" -lt "${newversion}" ]; then
    printf "Current umbrella chart ${i} is ahead of the subchart you may need to release a new subchart version\n"
  elif [[ "${currentverion}" == "" ]]; then
    printf "No version of this chart exists in the umbrella chart adding ${i}\n"
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies[+].name" ${i}
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).version" ${newversion}
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).repository" "https://broadinstitute.github.io/datarepo-helm/"
    yq w -i charts/${umbrella_name}/Chart.yaml "dependencies.(name==${i}).condition" "${i}.enabled"
  else
    printf "Error chart updating subchart ${i}\n"
  fi
done
}

main () {
  parseInputs
  helmchartrelease
}

main "${*}"
