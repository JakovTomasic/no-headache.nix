{ pkgs, ... }:
let
  # Common script to run on startup
  script = ''
    # || true ensures this bash script doesn't fail if some of the commands aren't available
    # because they won't be installed in every VM

    # jq should be installed only in hemisphere VM
    echo '{"jq on scale for 1 to 10":10}' | jq &> /home/nixy/jq-output.txt || true
    # bat should be installed only in earch VM
    echo "this is bat output" &> /home/nixy/input-for-bat.txt
    bat /home/nixy/input-for-bat.txt &> /home/nixy/bat-output.txt || true
    rm /home/nixy/input-for-bat.txt
    # yq shouldn't work anywhere because it's installed in diabled flat VM
    echo "a: 1" | yq '.a' &> /home/nixy/yq-output.txt || true

    # Print the unique name of this machine
    echo "$MACHINE_NAME" > /home/nixy/machine_name.txt
    # Print the index of this VM within VMs of the same type
    echo "$MACHINE_INDEX" > /home/nixy/machine_index.txt
    # Print the base name of the machine
    echo "$MACHINE_BASE_NAME" > /home/nixy/machine_base_name.txt
    # Print the type of the machine
    echo "$MACHINE_TYPE" > /home/nixy/machine_type.txt
    # You can use these environment variables in all your bash scripts in any VM
  '';
in
{
  # There are two hemispheres, but only one Earth. And none of them is flat. :)
  hemisphere = {
    count = 2;
    init.script = script;
    nixos-config = {
      # Install jq in every hemisphere VM
      environment.systemPackages = with pkgs; [ jq ];
    };
  };
  earth = {
    count = 1;
    init.script = script;
    nixos-config = {
      # Install bat in every earth VM
      environment.systemPackages = with pkgs; [ bat ];
    };
  };
  flat = {
    # Zero instances = disabled.
    count = 0;
    nixos-config = {
      # Install bat in every flat VM
      environment.systemPackages = with pkgs; [ yq ];
    };
  };
}

