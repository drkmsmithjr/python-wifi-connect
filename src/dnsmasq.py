# start / stop the dnsmasq process

import subprocess, time

DEFAULT_GATEWAY="192.168.42.1"
DEFAULT_DHCP_RANGE="192.168.42.2,192.168.42.254"
DEFAULT_INTERFACE="wlan0" # use 'ip link show' to see list of interfaces
ps = None

def stop():
    global ps
    if ps is not None:
        print(f'Killing dnsmasq, PID={ps.pid}')
        ps.kill()
        ps = None
    else:
        print (f'dnsmasq was not started.')


def start():
    # first kill any existing dnsmasq
    stop()

    # build the list of args
    path = "/usr/sbin/dnsmasq"
    args = [path]
    args.append(f"--address=/#/{DEFAULT_GATEWAY}")
    args.append(f"--dhcp-range={DEFAULT_DHCP_RANGE}")
    args.append(f"--dhcp-option=option:router,{DEFAULT_GATEWAY}")
    args.append(f"--interface={DEFAULT_INTERFACE}")
    args.append(f"--keep-in-foreground")
    args.append(f"--bind-interfaces")
    args.append(f"--except-interface=lo")
    args.append(f"--conf-file")
    args.append(f"--no-hosts" )

    # run dnsmasq in the background and save a reference to the object
    global ps
    ps = subprocess.Popen(args)
    # don't wait here, proc runs in background until we kill it.

    # give a few seconds for the proc to start
    time.sleep(2)
    print(f'Started dnsmasq, PID={ps.pid}')


