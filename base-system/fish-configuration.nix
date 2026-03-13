{
  pkgs,
  config,
  lib,
  ...
}:
let
  workspaces = import ./workspaces.nix;

  listToString = list: lib.concatStringsSep " " list;

  # Function to generate the content for each workspace
  generateWorkspaceContent = name: set: ''
    # Functions for workspace: ${name}
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (funcName: func: ''
        function ${set.prefix}${funcName}
          # ${func.description}
          ${func.content}
        end
      '') set.functions
    )}

    function __workspaces_cleanup_${name}
      ${set.cleanup or ""}
    end
  '';
in
{
  programs.fish.functions.hxo = {
    body = "${pkgs.helix}/bin/hx (${pkgs.xplr}/bin/xplr)";
  };
  programs.fish.interactiveShellInit = ''
      # Makes nix-shell maintain fish?
      # ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      # Base directory for function sets
          set -g __workspaces_function_sets_dir ${config.home.homeDirectory}/.config/fish/function_sets

          # Ensure the directory exists
          mkdir -p $__workspaces_function_sets_dir
    	function print_banner --description 'Prints a powerline styled banner with a topic and a message'
    		# TODO: Center in the terminal?
    		argparse s/status=\? h/help=\? -- $argv 
    		or return

    		if set -q _flag_help
    			echo "Prints a powerline styled banner with a topic and a message"
    			echo "    Flags:"
    			echo "        status=<info|error|success|warning> (default info)"
    			echo "    Usage: print_banner <topic> <message>"
    			echo "    Usage: print_banner --status=<info|error|success|warning> <topic> <message>"
    			return 0
    		end

    		# default to info
    		if test "" = "$_flag_status" || not set -q _flag_status
    			set _flag_status info
    		end

    		set word $argv[1]
    		set message $argv[2..-1]


    		switch (string lower $_flag_status)
    			case "info"
    				set fg ecf0f1
    				set bg_one 0077be
    				set bg_two 005A8F
    			case "error"
    				set fg ecf0f1
    				set bg_one e74c3c
    				set bg_two 911F12
    			case "success"
    				set fg 2c3e50
    				set bg_one 2ecc71
    				set bg_two 229652
    			case "warning"
    				set fg 2c3e50
    				set bg_one ffa500
    				set bg_two B87700
    		end

    		set_color -b $bg_one
    		set_color -o $fg

    		echo -n "  $word "
    		set_color normal
    		set_color $bg_one
    		set_color -b $bg_two
    		echo -n " "

    		set_color $fg

    		if test -n "$message"
    			echo -n " $message "
    		else
    			echo -n "  "
    		end

    		set_color normal
    		set_color $bg_two
    		echo " "

    		set_color normal
    	end
          function __workspaces_get_matching_workspace
            set -l current_path $PWD
            set -l best_match ""
            set -l best_match_length 0

            ${listToString (
              lib.mapAttrsToList (name: set: ''
                for root in ${listToString set.roots}
                  set -l expanded_root (eval echo $root)
                  if string match -q "$expanded_root*" $current_path
                    set -l match_length (string length $expanded_root)
                    if test $match_length -gt $best_match_length
                      set best_match "${name}"
                      set best_match_length $match_length
                    end
                  end
                end
              '') workspaces
            )}

            if test -n "$best_match"
              echo $best_match
              return 0
            end
            return 1
          end

          function __workspaces_load_matching_function_set
            set -l workspace (__workspaces_get_matching_workspace)
            if test -n "$workspace"
              if not set -q __active_function_set; or test "$__active_function_set" != "$workspace"
                source $__workspaces_function_sets_dir/$workspace.fish
                set -g __active_function_set $workspace
                print_banner --status="Info" Workspaces "Entering $workspace workspace"
              end
            end
          end

          function __workspaces_unload_all_function_sets
            if set -q __active_function_set
              print_banner --status="Warning" Workspaces "Leaving $__active_function_set workspace"
            end

            ${listToString (
              lib.mapAttrsToList (name: set: ''
                functions -e (functions -a | string match -r "^(${set.prefix}).*\$")
              '') workspaces
            )}

            if functions -q __workspaces_cleanup_$__active_function_set
              __workspaces_cleanup_$__active_function_set
              functions -e __workspaces_cleanup_$__active_function_set
            end

            set -e __active_function_set
          end

          function __handle_directory_change --on-variable PWD
            set -l new_workspace (__workspaces_get_matching_workspace)
            if test -n "$new_workspace"
              if not set -q __active_function_set; or test "$__active_function_set" != "$new_workspace"
                __workspaces_unload_all_function_sets
                __workspaces_load_matching_function_set
              end
            else if set -q __active_function_set
              __workspaces_unload_all_function_sets
            end
          end

          # Initial load for the current directory
          __handle_directory_change
  '';

  # Create function set files
  home.file = lib.mkMerge (
    lib.mapAttrsToList (name: set: {
      "${config.home.homeDirectory}/.config/fish/function_sets/${name}.fish".text =
        generateWorkspaceContent name set;
    }) workspaces
  );
}
