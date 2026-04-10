#!/bin/bash
# reset-workspaces.sh — Consolidate windows when switching monitor setups
#
# Single monitor: moves C/D windows to A/B, flattens trees
# Dual monitor:   redistributes app-matched windows back to C/D
#
# Usage: bound to service mode key in aerospace config

count=$(aerospace list-monitors --count 2>/dev/null || echo 1)

if [ "$count" -le 1 ]; then
  # Single monitor: move all C/D windows to A1
  for ws in C1 C2 C3 C4 D1 D2 D3 D4; do
    for wid in $(aerospace list-windows --workspace "$ws" 2>/dev/null | awk -F'|' '{print $1}' | tr -d ' '); do
      aerospace move-node-to-workspace --window-id "$wid" A1 2>/dev/null
    done
  done
  # Flatten all primary workspace trees
  for ws in A1 A2 A3 A4 B1 B2 B3 B4; do
    aerospace workspace "$ws" 2>/dev/null
    aerospace flatten-workspace-tree 2>/dev/null
  done
  aerospace workspace A1 2>/dev/null
  echo "Reset: consolidated C/D → A1 (single monitor)"
else
  # Dual monitor: flatten all workspaces on both monitors
  for ws in A1 A2 A3 A4 B1 B2 B3 B4 C1 C2 C3 C4 D1 D2 D3 D4; do
    aerospace workspace "$ws" 2>/dev/null
    aerospace flatten-workspace-tree 2>/dev/null
  done
  aerospace workspace A1 2>/dev/null
  echo "Reset: flattened all workspaces (dual monitor)"
fi
