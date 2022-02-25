case "$(readlink -f /sbin/init)" in
  *systemd* )
    sudo pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
    ;;
  *)
    sudo pacman --noconfirm --needed -S artix-keyring artix-archlinux-support >/dev/null 2>&1
    for repo in extra community multilib; do
      sudo grep -q "^\[$repo\]" /etc/pacman.conf ||
        sudo echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" | sudo tee -a /etc/pacman.conf
    done
    sudo pacman -Sy >/dev/null 2>&1
    sudo pacman-key --populate archlinux
    ;;
esac

