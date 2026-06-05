#!/usr/bin/env bash
set -euo pipefail

echo "== Stereolabs USB devices =="
lsusb -d 2b03: || true

echo
echo "== USB topology =="
lsusb -t || true

echo
echo "== Video devices =="
ls -l /dev/video* 2>/dev/null || echo "No /dev/video* devices"

echo
echo "== ZED video device metadata =="
for video_device in /dev/video*; do
  [ -e "$video_device" ] || continue
  echo "-- $video_device --"
  udevadm info -q property -n "$video_device" 2>/dev/null \
    | grep -E 'DEVNAME|ID_VENDOR_ID|ID_MODEL_ID|ID_MODEL|ID_SERIAL|ID_V4L' || true
  printf 'readable=%s writable=%s\n' \
    "$(test -r "$video_device" && echo yes || echo no)" \
    "$(test -w "$video_device" && echo yes || echo no)"
done

echo
echo "== ZED USB device node permissions =="
for usb_device in /dev/bus/usb/*/*; do
  [ -e "$usb_device" ] || continue
  if udevadm info -q property -n "$usb_device" 2>/dev/null | grep -q 'ID_VENDOR_ID=2b03'; then
    echo "-- $usb_device --"
    ls -l "$usb_device"
    udevadm info -q property -n "$usb_device" 2>/dev/null \
      | grep -E 'DEVNAME|ID_VENDOR_ID|ID_MODEL_ID|ID_MODEL|ID_SERIAL|ID_USB_INTERFACES' || true
    printf 'readable=%s writable=%s\n' \
      "$(test -r "$usb_device" && echo yes || echo no)" \
      "$(test -w "$usb_device" && echo yes || echo no)"
  fi
done

echo
echo "== HID raw permissions, if kernel exposes them =="
for hid_device in /dev/hidraw*; do
  [ -e "$hid_device" ] || continue
  echo "-- $hid_device --"
  udevadm info -q property -n "$hid_device" 2>/dev/null \
    | grep -E 'DEVNAME|ID_VENDOR_ID|ID_MODEL_ID|ID_MODEL|ID_SERIAL|HID_NAME' || true
  printf 'readable=%s writable=%s\n' \
    "$(test -r "$hid_device" && echo yes || echo no)" \
    "$(test -w "$hid_device" && echo yes || echo no)"
done

echo
echo "== NVIDIA =="
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader || true

echo
echo "== Local ZED SDK =="
if [ -d "sdk/zed" ]; then
  du -sh sdk/zed
  find sdk/zed/tools -maxdepth 1 -type f -executable -printf '%f\n' 2>/dev/null | sort
else
  echo "sdk/zed not found"
fi
