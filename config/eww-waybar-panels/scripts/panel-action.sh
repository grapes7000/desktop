#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  audio) case "${2:-}" in down) pamixer -d 5 2>/dev/null || true;; up) pamixer -i 5 2>/dev/null || true;; mute) pamixer -t 2>/dev/null || true;; mic-mute) pamixer --default-source -t 2>/dev/null || true;; set-vol) pamixer --set-volume "${3:-50}" 2>/dev/null || true;; set-sink) pactl set-default-sink "${3:-}" 2>/dev/null || true;; set-app-vol) pactl set-sink-input-volume "${3:-0}" "${4:-100}%" 2>/dev/null || true;; previous|play-pause|next) playerctl "$2" 2>/dev/null || true;; pavucontrol) pavucontrol >/dev/null 2>&1 &;; esac ;;
  network) case "${2:-}" in copy-local) printf '%s' "$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')" | wl-copy 2>/dev/null || true;; copy-tailscale) tailscale ip -4 2>/dev/null | wl-copy 2>/dev/null || true;; settings) nm-connection-editor >/dev/null 2>&1 &;; esac ;;
  clock) case "${2:-}" in copy-time) date '+%H:%M:%S' | wl-copy 2>/dev/null || true;; copy-date) date '+%F' | wl-copy 2>/dev/null || true;; esac ;;
esac
