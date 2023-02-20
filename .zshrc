if ! type hub > /dev/null; then
  echo "hub is not installed"
else
  alias git=hub
fi

alias kc=kubectl

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;35;40'

# Fix macOS and use openssl from brew (specifically causes issues with Python)
export DYLD_LIBRARY_PATH=/usr/local/opt/openssl/lib:$DYLD_LIBRARY_PATH
export PATH="/usr/local/opt/openjdk/bin:/opt/homebrew/bin:$PATH"

alias lsusb="system_profiler SPUSBDataType"

# Support globbing (i.e. `rm -- !(script.sh)`) doesn't work with zsh
# shopt -s extglob

function new-mac {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew update && brew upgrade

  cask_tools=(
    iterm2
    itsycal
    atom
    android-platform-tools
    bettertouchtool
    gimp
  )

  tools=(
    fanny
    minicom
    jq
    wget
    curl
    git
    hub
    gpg
    nmap
    tldr
    bat
    lastpass-cli
  )
  
  brew install --cask $cask_tools
  brew install $tools
}


function filter-whitespace {
  sed '/^$/d;s/[[:blank:]]//g'
}

function trim-empty-lines {
  sed '/^[[:space:]]*$/d'
}

function split-whitespace {
  tr " " "\n"
}

function vscode {
  VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;
}

function bid_lookup {
  /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/"$1".app/Contents/Info.plist
}

function show_office_times {
  echo -e "Seattle\t\t$(env TZ=America/Vancouver date)"
  echo -e "Scottsdale\t$(env TZ=America/Phoenix date)"
  echo -e "Tampere\t\t$(env TZ=Europe/Helsinki date)"
  echo -e "Saigon\t\t$(env TZ=Asia/Saigon date)"
}

function strip_header {
  od -j 5 -An -N 4 -vtu4 $1 | (read len; len=$((len + 10)); tail -c +$len $1)
}

function strip_footer {
  fn=$(mktemp -u)
  cp $1 $fn
  tail -c 9 $fn | od -An -N 4 -vtu4 | (read len; len=$((len + 9)); truncate -s -$len $fn)
  cat $fn
}

function strip_keys_after_equals {
  key=$1
  echo ${key}
  grep -o "${key}[^ ]*" * | cut -d'=' -f2 | grep "-" | sort | uniq
}

function strip_keys_after_colon {
  key=$1
  echo ${key}
  grep -o "${key}[^ ]*" * | cut -d':' -f2 | grep "-" | sort | uniq
}

function pdf-combine {
  output_file=$1
  shift
  input_files=$@
  "/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o ${output_file} $(echo $input_files)
}

function encrypt_ssh {
  openssl rsautl -encrypt -pubin -inkey <(ssh-keygen -f $1 -e -m PKCS8)
}

function decrypt_ssh {
  # Requires private key in PEM format which can be done with
  # cp ~/.ssh/id_rsa  ~/.ssh/id_rsa_pem
  # ssh-keygen -p -N "" -m pem -f ~/.ssh/id_rsa_pem
  openssl rsautl -decrypt -inkey ~/.ssh/id_rsa_pem -in $1
}

function vpndv1 {
  if ! signed_in; then return 1; fi
  copypass "TASERVS (DV1)"
  osascript -e "tell application \"Tunnelblick\"" -e "connect \"myvpn\"" -e "end tell"
}

function 1passin {
  if signed_in; then return 0; fi
  eval $(op signin natencate)
}

function 1passout {
  op signout
  unset OP_SESSION_natencate
}

function signed_in {
  if [ -z ${OP_SESSION_natencate+x} ]; then
    echo "Sign in required, use 1passin..."
    return 1
  fi

  return 0
}

function getuser {
  if ! signed_in; then return 1; fi
  op get item $1 | jq '.details.fields[] | select(.designation=="username").value' | tr -d '"' | tr -d '\n'
}

function getpass {
  if ! signed_in; then return 1; fi
  op get item $1 | jq '.details.fields[] | select(.designation=="password").value' | tr -d '"' | tr -d '\n'
}

function copypass {
  if ! signed_in; then return 1; fi
  getpass $1 | pbcopy
}

function mssql-toggle-pretty {
  if [ -z ${MSSQL_TABLE_VIEW+x} ]; then
    export MSSQL_TABLE_VIEW=40;
  else
    unset MSSQL_TABLE_VIEW;
  fi
}

function mssql-toggle-row-count {
  if [ -z ${MSSQL_NO_ROW_COUNT+x} ]; then
    export MSSQL_NO_ROW_COUNT=1;
  else
    unset MSSQL_NO_ROW_COUNT;
  fi
}

function fingerprint {
  openssl pkey -pubout -outform DER | openssl md5 -c
}

function kc_config {
  if [ -z "$1" ]; then
    readlink /Users/ngrubb/.kube/config |  cut -d'/' -f5 | cut -d'_' -f1
  elif [ -f /Users/ngrubb/.kube/${1}_config ]; then
    ln -sf /Users/ngrubb/.kube/${1}_config /Users/ngrubb/.kube/config
  else
    echo "Environment \"${1}\" does not exist!" >> /dev/stderr
  fi
}

function kc_find_container {
  POD=$(kubectl get pods -o=name | grep $1 | head -n 1 | cut -d '/' -f2  | tee -a /dev/stderr)
  CONTAINER=$(kubectl get pods ${POD} -o jsonpath='{.spec.containers[*].name}' | tee -a /dev/stderr)
}

function kc_exec {
  kubectl exec -c ${CONTAINER} ${POD} -- $@
}

function kc_pod_info {
  kubectl get pods ${POD} -o jsonpath='{.spec}'
}



