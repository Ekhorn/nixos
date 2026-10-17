while true; do
  output=$(zeditor --foreground develop/nixos 2>&1)
  echo "$output"

  broken_path=$(echo "$output" | grep -o '/nix/store/[^ ]*' | tail -n1)

  if [[ -n "$broken_path" ]]; then
    echo "Repairing: $broken_path"
    sudo nix-store --repair-path "$broken_path"
  else
    echo "No broken paths detected, exiting."
    break
  fi
done
