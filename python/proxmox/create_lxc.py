import os
from proxmoxer import ProxmoxAPI


PVE_HOST = os.environ.get("PVE_HOST")
PVE_USER = os.environ.get("PVE_USER")
PVE_TOKEN_NAME = os.environ.get("PVE_TOKEN_NAME")
PVE_TOKEN_VALUE = os.environ.get("PVE_TOKEN_VALUE")
PVE_NODE = os.environ.get("PVE_NODE")


prox = ProxmoxAPI(
    PVE_HOST,
    user=PVE_USER,
    token_name=PVE_TOKEN_NAME,
    token_value=PVE_TOKEN_VALUE,
    verify_ssl=False,
    timeout=10
)


# Doc:
# https://pve.proxmox.com/pve-docs/api-viewer/index.html#/nodes/{node}/lxc
params = {
    "vmid": "114",
    "ostemplate": "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst",
    "storage": "local",
    "rootfs": "local:114,size=10G",
    "hostname": "test-api",
    "memory": "1024",
    "swap": "0",
    "cores": "1",
    "cpulimit": "1",
    "net0": "name=eth0,bridge=vmbr1,gw=10.0.0.1,ip=10.0.0.28/16,type=veth",
    "onboot": "1",
    "start": "1",
    "password": "test",
    "ssh-public-keys": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2EhVWJL1r7ydnZnAJFBG2S06ltsUDgOLYTa9HTkh2/Yk6o9p28eUO+5hsORCqQZXM9Fow0XVKTRabTRIWwQWTTAFDGLR078pzd0oBdQVT9MhyfHvqnWokJEwKUVye5hgAzwYDw3G8O83/Qc5bvGeLGqCjZ7Pj09dRPLhXSxExUc6XhYBhK0VvufkzGodvxkJvb0NNNt5SyFDfGmo0DHZ1YWwpovR2rPzGc59VoyFebnDjy3pkwfUkJMQGVjRnErR6bGWAMacNyYplQo6KAZVm11olLAZG2a3Ai95Ql5zLvbveQQVMOi584f9GvE+hi2nf1CEwrtK4TSfHTWgKudym/gxgX/WEsHW4zbPbqSoRd+nOYQfhbylji0xTc+YQGiQesn4gwrSvccIPTRKg9ghOd7JwK8YVDNakVOh+SH5GbWA8nF1ze4uwqdLd7PkNPJh1V/svPewUitTvON8v+UmHTKDHC6aLVYRVW0aTNNy5aNFXpyLAdu06+k+RBd9qSVE= barckcode@iMac-de-Cristian.local"
}


lxc = prox.nodes(PVE_NODE).lxc.post(**params)

print(lxc)
