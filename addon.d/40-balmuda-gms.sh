#!/sbin/sh
#
# ADDOND_VERSION=3
#
# /system/addon.d/40-balmuda-gms.sh
#
# Keeps Play services that the TWRP GMS fix moved from the MindTheGapps APEX into
# /product/priv-app. The GApps addon.d list only has the APEX, which the fix removes,
# so without this an update leaves Play services without their system copy.
#
. /tmp/backuptool.functions

# list_files <prefix>: files present under <prefix>$S, relative to $S
list_files() {
  for f in $1$S/product/priv-app/PrebuiltGmsCore*/*.apk \
           $1$S/product/etc/permissions/privapp_allowlist_com.google.android.gmssystem.xml \
           $1$S/product/etc/sysconfig/preinstalled_packages_com.google.android.gmssystem.xml; do
    [ -f "$f" ] && echo "${f#$1$S/}"
  done
}

case "$1" in
  backup)
    list_files "" | while read FILE; do
      backup_file $S/$FILE
    done
  ;;
  restore)
    list_files "$C" | while read FILE; do
      restore_file $S/$FILE
      f=$(get_output_path "$S/$FILE")
      chown root:root $f
      chmod 644 $f
      chmod 755 $(dirname $f)
      chcon u:object_r:system_file:s0 $(dirname $f) $f 2>/dev/null
    done
  ;;
  pre-backup|post-backup|pre-restore|post-restore)
  ;;
esac
