# VM Guest Setup — Arch + Hyprland under QEMU/KVM (SPICE)

The procedural "happy path" for standing up this desktop in a virt-manager
guest. For when things go *wrong*, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

Environment this was built for:
- **Host:** CachyOS (Arch-based), qtile on wlroots/Wayland, virt-manager.
- **Guest:** Arch Linux, QEMU/KVM via libvirt, **Virtio** video, **SPICE** display.
- **Goal:** themed Hyprland desktop with working clipboard, a fixed high
  resolution, and (optionally) GPU-accelerated eye candy.

---

## 1. VM device settings (virt-manager)

- **Video model:** Virtio.
- **Display:** Spice, `listen type='none'` (local only) is fine and preferred.
- For GPU acceleration (optional, see §6): Virtio video with 3D acceleration +
  SPICE OpenGL. Leave this OFF for the first boot — get everything else working
  first.

---

## 2. Get SSH in (so you can drive it from the host)

In the guest console:
```sh
sudo pacman -S --needed openssh
sudo systemctl enable --now sshd
sudo ufw allow 22/tcp        # only if ufw is active
```
From the host:
```sh
sudo virsh domifaddr <domain>       # find guest IP
ssh-copy-id user@<guest-ip>          # key auth
```
> If `ping` works but SSH times out, a guest firewall (often `ufw`) is dropping
> TCP. `sudo ufw allow 22/tcp`.

---

## 3. Clipboard + agent (spice-vdagent)

```sh
sudo pacman -S --needed spice-vdagent
sudo systemctl enable --now spice-vdagentd     # SYSTEM daemon
```
The **user** agent (`spice-vdagent.service`) is started by your session. For it
to work you need two things:

**a) device permission** — udev rule:
```
# /etc/udev/rules.d/50-spice-vdagent.rules
SUBSYSTEM=="virtio-ports", KERNEL=="vport*", TAG+="uaccess"
```
`sudo udevadm control --reload && sudo udevadm trigger`

**b) `DISPLAY` in the user environment** — handled by the compositor autostart
(already wired in `hypr/conf/autostart.conf`). Without it the agent dies with
`cannot open display:`. This is the #1 gotcha — see TROUBLESHOOTING §1.

---

## 4. Resolution

wlroots ignores `xrandr` for the real output. Set the mode with `wlr-randr` or
the Hyprland `monitor` line (already set to 2560x1440 in `conf/monitors.conf`):
```sh
wlr-randr                                   # list modes
wlr-randr --output Virtual-1 --mode 2560x1440
```

---

## 5. Install the desktop

```sh
sudo pacman -S --needed hyprland waybar wofi hyprpaper hyprlock hypridle \
  xdg-desktop-portal-hyprland polkit-kde-agent qt5-wayland qt6-wayland \
  grim slurp wl-clipboard \
  brightnessctl playerctl pamixer python-pillow

git clone <hyprland-setup-url> ~/hyprland-setup
~/hyprland-setup/install.sh --dry-run
~/hyprland-setup/install.sh --desktop
git clone <themes-url> ~/themes && ~/themes/install.sh
theme catppuccin_mocha
```
Log out, pick **Hyprland** at the greeter.

---

## 6. GPU acceleration (virgl) — optional, do this LAST

Software rendering (`llvmpipe`) makes blur laggy at 1440p. To offload to the
host GPU:

1. **Back up the XML first** (host):
   ```sh
   virsh --connect qemu:///system dumpxml <domain> > ~/vm-backup.xml
   ```
2. Enable 3D + GL in the XML (`virsh edit` or define):
   ```xml
   <model type='virtio' heads='1' primary='yes'><acceleration accel3d='yes'/></model>
   ...
   <graphics type='spice'><listen type='none'/><gl enable='yes' rendernode='/dev/dri/renderD128'/></graphics>
   ```
3. Ensure QEMU can reach the host GPU (or boot will fail with
   `EGL_NOT_INITIALIZED`):
   ```sh
   sudo usermod -aG render,video qemu && sudo systemctl restart libvirtd
   ```
4. **Cold boot** (not reboot): `virsh shutdown <domain>` then `virsh start <domain>`.
5. Verify in guest: `glxinfo | grep renderer` → should say `virgl`, not `llvmpipe`.

If it won't boot: `virsh define ~/vm-backup.xml && virsh start <domain>`.
Full detail + reasoning in TROUBLESHOOTING §3–4.

---

## Result

- Hyprland at 2560x1440, blur/shadow eye candy, 28 switchable themes.
- Clipboard sync host↔guest via spice-vdagent.
- `theme <name>` re-skins the whole desktop + wallpaper in one command.
