
# Don't ... ask ... questions !
export DEBIAN_FRONTEND='noninteractive'

as_root() {
  if [ `id -u` -gt 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

fail() {
  echo "$@" >&2
  exit 1
}

has() {
  which $1 &>/dev/null
}

expand_path() {
  mkdir -p `dirname "$1"`
  cd `dirname "$1"`
  echo $PWD/`basename "$1"`
}

depend() {
  local depend_file="$1"
  local filter="$2"
  local deps=`cat "$depend_file" | grep " $filter" | sed -E -e "s/ +/ /g"`
  local apt_deps=`echo "$deps" | grep ' apt' | cut -d ' ' -f 1 | tr '\n' ' '`
  local gem_deps=`echo "$deps" | grep ' gem' | cut -d ' ' -f 1 | tr '\n' ' '`

  check_debs "$apt_deps"
  check_gems "$gem_deps"
}

check_debs() {
  local wanted_debs="$@"
  [ -z "$wanted_debs" ] && return

  local installed_debs=`dpkg-query -l $wanted_debs | grep -e '^ii ' | cut -d ' ' -f 3 2>/dev/null`
  local missing_debs=`echo $wanted_debs $installed_debs | tr ' ' '\n' | sort | uniq -u | tr '\n' ' '`

  [ -z "$missing_debs" ] && return

  echo "Missing DEBS: $missing_debs"
  as_root apt-get update -qq
  as_root apt-get install -qy $missing_debs
}

check_gems() {
  local wanted_gems="$@"
  [ -z "$wanted_gems" ] && return

  local installed_gems=`gem list | cut -d ' ' -f 1 | tr '\n' ' '`
  local missing_gems=`echo $wanted_gems $installed_gems | tr ' ' '\n' | sort | uniq -u | tr '\n' ' '`

  [ -z "$missing_gems" ] && return

  echo "Missing GEMS: $missing_gems"
  as_root gem install --no-ri --no-rdoc --force $missing_gems
}
