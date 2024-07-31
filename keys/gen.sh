#!/usr/bin/env bash

case $(hostname) in
    pop-os)
        # path="/dev/input/by-id/usb-SONiX_USB_DEVICE-event-kbd"
        # path="/dev/input/by-id/usb-RAPOO_RAPOO_5G_Wireless_Device-event-kbd"
        path="/dev/input/by-id/usb-SEMICO_USB_Gaming_Keyboard-event-kbd"
    ;;
    think)
        # input="/dev/input/by-id/usb-Compaq_Compaq_Internet_Keyboard-event-kbd"
        path="/dev/input/by-path/platform-i8042-serio-0-event-kbd"
    ;;
    *)
        echo "unrecognized computer name no input device file slected"
        path="no_device_file_found_for_this_host_name"
    ;;
esac

sed 's!<__device-file__>!'"$path"'!g' layout.kbd > $HOME/.config/kmonad/config.kbd
