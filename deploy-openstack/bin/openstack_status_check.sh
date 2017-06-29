#!/bin/sh
#Modify by keanlee on June 5th of 2017

# ansi colors for formatting heredoc
ESC=$(printf "\e")
GREEN="$ESC[0;32m"
NO_COLOR="$ESC[0;0m"
RED="$ESC[0;31m"
MAGENTA="$ESC[0;35m"
YELLOW="$ESC[0;33m"
BLUE="$ESC[0;34m"
WHITE="$ESC[0;37m"
#PURPLE="$ESC[0;35m"
CYAN="$ESC[0;36m"

source $(find / -name admin-openrc)

systemctl --version >/dev/null 2>&1 && systemctl=1
[ "$systemctl" ] || RUNLEVEL=$(LANG=C who -r | sed 's/.*run-level \([0-9]\).*/\1/')

# Figure out what provides mysqld services, if installed locally
get_mysql_variant() {
    local r
    r=$(rpm -q --whatprovides mysql-server)
    if [ $? -ne 0 ]; then
        return 1
    fi
    # using bash would be faster/less forks: r=${r/-*/}
    r=$(echo $r | cut -f1 -d-)
    if [ "$r" = "mysql" ]; then
        echo mysqld
        return 0
    fi
    echo $r
}


for conf in nova/nova.conf keystone/keystone.conf glance/glance-registry.conf; do
    if grep -qF 'connection = mysql' /etc/$conf 2>/dev/null; then
        mysqld=$(get_mysql_variant)
        break
    fi
done

rpm -q openstack-nova-common > /dev/null && nova='nova'
rpm -q openstack-glance > /dev/null && glance='glance'
rpm -q openstack-dashboard > /dev/null && dashboard='httpd'
rpm -q openstack-keystone > /dev/null && keystone='keystone'
rpm -q openstack-neutron > /dev/null && neutron='neutron' ||
{ rpm -q openstack-quantum > /dev/null && neutron='quantum'; }
rpm -q openstack-swift > /dev/null && swift='swift'
rpm -q openstack-cinder > /dev/null && cinder='cinder'
rpm -q openstack-ceilometer-common > /dev/null && ceilometer='ceilometer'
rpm -q openstack-heat-common > /dev/null && heat='heat'
rpm -q openstack-sahara > /dev/null && sahara='sahara'
rpm -q openstack-trove > /dev/null && trove='trove'
rpm -q openstack-tuskar > /dev/null && tuskar='tuskar'
rpm -q openstack-ironic-common > /dev/null && ironic='ironic'
rpm -q libvirt > /dev/null && libvirtd='libvirtd'
rpm -q openvswitch > /dev/null && openvswitch='openvswitch'
rpm -q qpid-cpp-server > /dev/null && qpidd='qpidd'
rpm -q rabbitmq-server > /dev/null && rabbitmq='rabbitmq-server'
rpm -q memcached > /dev/null && memcached='memcached'

if test "$qpidd" && test "$rabbitmq"; then
  # Give preference to rabbit
  # Unless nova is installed and qpid is specifed
  if test "$nova" && grep -q '^rpc_backend.*qpid' /etc/nova/nova.conf; then
    rabbitmq=''
  else
    qpidd=''
  fi
fi

service_installed() {
  {
    systemctl list-unit-files --type service --full --all ||
    systemctl list-units --full --all --type service
  } 2>/dev/null | grep -q "^$1\.service" ||
  chkconfig --list $1 >//dev/null 2>&1
}

service_enabled() {
  if [ "$systemctl" ]; then
    systemctl --quiet is-enabled $1.service 2>/dev/null
  else
    chkconfig --levels $RUNLEVEL "$1"
  fi
}

# determine the correct dbus service name
service_installed dbus && dbus='dbus' || dbus='messagebus'

if service_enabled openstack-nova-volume 2>/dev/null ||
   service_enabled openstack-cinder-volume 2>/dev/null; then
  for target in 'target' 'targetd' 'tgtd'; do
    service_installed $target && break
  done
fi

lsb_to_string() {
  case $1 in
  0) echo ${GREEN}active${NO_COLOR};;
  1) echo $RED dead $NO_COLOR ;;
  2) echo $RED dead $NO_COLOR ;;
  3) echo "inactive" ;;
  *) echo "unknown" ;;
  esac
}

check_svc() {

  printf '%-40s' "$1:"

  bootstatus=$(service_enabled $1 && echo enabled || echo disabled)

  if [ "$systemctl" ]; then
    status=$(systemctl is-active $1.service 2>/dev/null)
    # For "simple" systemd services you get
    # "unknown" if you query a non enabled service
    if [ "$bootstatus" = 'disabled' ]; then
      [ $status = 'unknown' ] && status='inactive'
    fi
  else
    status=$(service $1 status >/dev/null 2>/dev/null ; lsb_to_string $?)
  fi

  if [ "$bootstatus" = 'disabled' ]; then
    bootstatus='(disabled on boot)'
  else
    bootstatus=''
  fi

  test "$bootstatus" && status_pad=10 || status_pad=0

  printf "%-${status_pad}s%s\n" "$status" "$bootstatus"
}


if test "$nova"; then
  echo $BLUE  == Nova services == $NO_COLOR
  for nova_opt in cert conductor volume cells console consoleauth xvpvncproxy spicehtml5proxy serialproxy; do
    service_installed openstack-nova-$nova_opt && nova_opt_inst="$nova_opt_inst $nova_opt"
  done
  for svc in api compute network scheduler $nova_opt_inst; do check_svc "openstack-nova-$svc"; done
fi

if test "$glance"; then
  echo $BLUE == Glance services == $NO_COLOR
  for svc in api registry; do check_svc "openstack-glance-$svc"; done
fi

if test "$keystone"; then
  echo $BLUE == Keystone service == $NO_COLOR
  for svc in $keystone; do check_svc "openstack-$svc"; done
fi

if test "$dashboard"; then
  echo $BLUE == Horizon service == $NO_COLOR
  horizon_status="$(curl -L -s -w '%{http_code}\n' http://localhost/dashboard -o /dev/null)"
  [ "$horizon_status" = 200 ] && horizon_status=active
  [ "$horizon_status" = 000 ] && horizon_status=uncontactable
  printf '%-40s%s\n' "openstack-dashboard:" "$horizon_status"
fi

if test "$neutron"; then
  echo $BLUE == $neutron services == $NO_COLOR
  for svc in $neutron-server; do check_svc "$svc"; done
  # Default agents
  for agent in dhcp l3 metadata lbaas lbaasv2; do
    service_installed $neutron-$agent-agent &&
    check_svc "$neutron-$agent-agent"
  done
  # Optional agents
  for agent in openvswitch linuxbridge ryu nec mlnx metering; do
    service_installed $neutron-$agent-agent &&
    check_svc "$neutron-$agent-agent"
  done
fi

if test "$swift"; then
  echo $BLUE == Swift services == $NO_COLOR
  check_svc openstack-swift-proxy
  for ringtype in account container object; do
    check_svc openstack-swift-$ringtype
    for service in replicator updater auditor; do
      if [ $ringtype != 'account' ] || [ $service != 'updater' ]; then
        : # TODO how to check status of:
          # swift-init $ringtype-$service
      fi
    done
  done
fi

if test "$cinder"; then
  echo $BLUE == Cinder services == $NO_COLOR
  service_installed openstack-cinder-backup && backup=backup
  for service in api scheduler volume $backup; do
    check_svc openstack-cinder-$service
  done
fi

if test "$ceilometer"; then
  echo $BLUE == Ceilometer services == $NO_COLOR
  service_installed openstack-ceilometer-alarm-notifier && notifier=alarm-notifier
  service_installed openstack-ceilometer-alarm-evaluator && evaluator=alarm-evaluator
  service_installed openstack-ceilometer-notification && notification=notification
  for service in api central compute collector $notifier $evaluator $notification; do
    check_svc openstack-ceilometer-$service
  done
fi

if test "$heat"; then
  echo $BLUE == Heat services == $NO_COLOR
  for service in api api-cfn api-cloudwatch engine; do
    check_svc openstack-heat-$service
  done
fi

if test "$sahara"; then
  echo $BLUE == Sahara services == $NO_COLOR
  if service_enabled 'openstack-sahara-engine'; then
    sahara_services='api engine'
  elif service_enabled 'openstack-sahara-api'; then
    sahara_services='api'
  else
    sahara_services='all'
  fi
  for service in $sahara_services; do
    check_svc openstack-sahara-$service
  done
fi

if test "$trove"; then
  echo $BLUE == Trove services == $NO_COLOR
  for service in api taskmanager conductor; do
    check_svc openstack-trove-$service
  done
fi

if test "$tuskar"; then
  echo $BLUE == Tuskar services == $NO_COLOR
  for service in api; do
    check_svc openstack-tuskar-$service
  done
fi

if test "$ironic"; then
  echo $BLUE == Ironic services == $NO_COLOR
  for service in api conductor; do
    check_svc openstack-ironic-$service
  done
fi

echo $BLUE == Support services ==$NO_COLOR
for svc in $mysqld $libvirtd $openvswitch $dbus $target $qpidd $rabbitmq $memcached; do
  check_svc "$svc"
done

if test "$keystone"; then
  echo $BLUE == Keystone users == $NO_COLOR
  if ! test "$OS_USERNAME"; then
    echo "Warning keystonerc not sourced" >&2
  else
    keystonerc=1
    keystone user-list
  fi
fi

if test "$keystonerc" && test "$glance"; then
  echo $BLUE == Glance images == $NO_COLOR
  glance image-list
fi

if test "$nova"; then
  if ! test "$keystonerc" && ! test "$NOVA_USERNAME"; then
    test "$keystone" || echo "Warning novarc not sourced" >&2
  else
    echo $BLUE == Nova managed services == $NO_COLOR
    nova service-list

    echo $BLUE == Neutron networks == $NO_COLOR
    neutron net-list

    echo $BLUE == Nova instance flavors == $NO_COLOR
    # Check direct access
    nova flavor-list

    echo $BLUE == Nova instances == $NO_COLOR
    # Check access through the API
    nova list --all-tenants # instances
  fi
fi
echo $BLUE == Neutron managed services == $NO_COLOR
neutron agent-list

echo $BLUE == Cinder managed services == $NO_COLOR
cinder service-list


