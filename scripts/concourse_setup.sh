#!/usr/bin/env sh

# concourse_setup, a cool tool for creating all the folders/files required with
# our complex dependency requirements
#
# eg: ./scripts/concourse_setup.sh \
# --git-resource cloudfoundry/cf-release#f89dd4688fc44b8b34974321daedf6351a55c582 \
# --git-resource cloudfoundry-incubator/diego-release#8ad8eebffe11f55eda86713acd1233230942c32a \
# --git-resource pivotal-cf/diego-windows-msi#bdd07d6fff587b96ae761fb1c93ee1831c11fe18 \
# --s3-resource msi-file#https://diego-windows-msi.s3.amazonaws.com/output/DiegoWindowsMSI-0.411-bdd07d6.msi

set -e

popd ()
{
  command popd "$@" > /dev/null
}
pushd ()
{
  command pushd "$@" > /dev/null
}

usage ()
{
  echo "Usage: concourse-setup --git-resource repo=SHA --s3-resource dirname=URL"
  echo "eg: concourse-setup --git-resource cloudfoundry/cf-release#faec --s3-resource jimbob#https://foo.s3.amazonaws.com/beebs/jimbob"
}


run ()
{
  args="$@"
  while [[ $# > 0 ]]
  do
    key="$1"

    case $key in
      --git-resource)
        git_resource $2
        shift # past argument
        ;;
      --s3-resource)
        s3_resource $2
        shift # past argument
        ;;
      *)
        # unknown option
        echo "Invalid argument $key"
        usage
        exit 1
        ;;
    esac
    shift # past argument or value
  done
}

git_resource () 
{
  read repo sha <<<$(IFS="#"; echo $1)
  read _ dir <<<$(IFS="/"; echo $repo)
  echo "Creating git resource: $PWD/$dir at commit $sha"
  
  if [ ! -d "$dir" ]; then
    git clone git@github.com:"$repo".git --no-checkout
  fi
  pushd $dir
    git reset -q --hard $sha
  popd
}

s3_resource ()
{
  read dir url <<<$(IFS="#"; echo $1)
  echo "Creating s3 resource: $dir"
  version=$(echo $url | sed 's/^.*-\([0-9.]*\)-.*$/\1/')
  if [ ! -d "$dir" ]; then
    mkdir -p $dir >/dev/null
  fi
  pushd $dir 
    echo "$url" > url
    wget -q -N $url 
    echo "$version" > version
  popd
}

if [[ $# == 0 ]]; then
  echo "Insufficient arguments, $#"
  usage
  exit 1
fi


tmpdir=/tmp/concourse/
mkdir -p $tmpdir
pushd $tmpdir

run "$@"

echo
echo "SUCCESS!"
echo "Ensure your task config file has all the required parameters set"
echo "Then run your fly command like so:"
echo
echo 'fly -t CONCOURSE_URL -k execute -c TASK_CONFIG_FILE -i resource1=/tmp/concourse/resource1/ ...'
