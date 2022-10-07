

DEVICE_IP=""

function getIpFromOnomondo {
  asd=`curl -s --request GET --url https://api.onomondo.com/sims/$1 --header "authorization: $ONOMONDO_KEY" `
  DEVICE_IP=`echo $asd | egrep -o 'ipv4":"[0-9.]+' | egrep -o '[0-9.]+'  | tail -n 1`
}

function ssh_fn {
  asd=`curl -s --request GET --url https://api.onomondo.com/sims/$1 --header "authorization: $ONOMONDO_KEY"`
  ip=`echo $asd | egrep -o 'ipv4":"[0-9.]+' | egrep -o '[0-9.]+'  | tail -n 1`
  if echo $asd | egrep -o 'online":true' > /dev/null; then
    echo "Opening session to $ip"
    auth-wrapper ssh support@$ip 
  else
    echo $asd
    echo
    echo "Unit ${ip} (SIM: $1) is not online?"
  fi
}


function setIpFrom {

  if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    DEVICE_IP=$1
  else
    getIpFromOnomondo
  fi
}
