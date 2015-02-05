#include:
#  - salt_virt

libvirt-etc-default:
  augeas.change:
     - lens: ShellVars.lns
     - context: /files/etc/default/libvirt-bin
     - changes:
       - set libvirtd_opts '"-d -l"'

libvirt-etc-tcp:
  file.replace:
    - name: /etc/libvirt/libvirtd.conf
    - pattern: ^#listen_tcp = 1
    - repl: "listen_tcp = 1"

libvirt-etc-tls:
  file.replace:
    - name: /etc/libvirt/libvirtd.conf
    - pattern: ^#listen_tls = 0
    - repl: "listen_tls = 0"

libvirt-etc:
  augeas.change:
    - context: /files/etc/libvirt/libvirtd.conf
    - changes:
      - set listen_tls 0
      - set listen_tcp 1
  require:
    - name: libvirt-etc-tls
    - name: libvirt-etc-tcp
 
libvirtd-service:
  service.running:
    - name: libvirt-bin
  watch:
    - file: /files/etc/default/libvirt-bin
    - file: /files/etc/libvirt/libvirtd.conf

ebtables:
  pkg.installed

## the following assumes fixed ethernet ports on a server/desktop
#eth2:
#  network.managed:
#    - enabled: True
#    - type: eth
#    - bridge: br0
#    - proto: manual
#
#br0:
#  network.managed:
#    - enabled: True
#    - type: bridge
#    - bridge: br0
#    - proto: dhcp
#    - ports: eth2
#    - use:
#      - network: eth2
#    - require:
#      - network: eth2

## the following setups a bridge with a static address which allows for nat'ing
br0:
  network.managed:
    - enabled: True
    - type: bridge
    - bridge: br0
    - proto: none
    - ipaddr: 10.0.4.1
    - netmask: 255.255.255.0
    - ports: none

dnsmasq-exclude-br0:
  file.managed:
    - name: /etc/dnsmasq.d/salt-cloud-br0
    - source: salt://cloudcontroller/files/dnsmasq-exclude-br0

setup-nat-wlan0-outbound:
    file.managed:
        - name: /usr/local/sbin/setup-nat-wlan0-outbound.sh
        - mode: 0755
        - source: salt://cloudcontroller/files/setup-nat-wlan0-outbound.sh

setup-nat-eth2-outbound:
    file.managed:
        - name: /usr/local/sbin/setup-nat-eth2-outbound.sh
        - mode: 0755
        - source: salt://cloudcontroller/files/setup-nat-eth2-outbound.sh

setup-if-pre-iptables:
    file.managed:
        - name: /etc/network/if-pre-up.d/iptables-nat
        - mode: 0755
        - source: salt://cloudcontroller/files/iptabes-nat.sh

salt-cloud-dnsmasq-conf:
    file.managed:
      - name: /srv/scripts/dnsmasq.conf
      - source: salt://cloudcontroller/files/dnsmasq.conf

ethtool:
  pkg.installed

ethtool -K br0 tx off:
  cmd.run:
    - require:
      - pkg: ethtool
      - network: br0

supervisor-dnsmasq-conf:
    file.managed:
        - name: /etc/supervisor/conf.d/salt-cloud.conf
        - source: salt://cloudcontroller/files/salt-cloud.conf
    supervisord.running:
        - name: salt-cloud-dnsmasq
        - watch:
          - file: /srv/scripts/dnsmasq.conf
        - require:
            - network: br0
