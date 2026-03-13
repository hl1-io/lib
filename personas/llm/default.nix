{ pkgs, ... }:

let
  # modelSrc = builtins.fetchurl {
  #   # url = "https://huggingface.co/hugging-quants/Llama-3.2-3B-Instruct-Q4_K_M-GGUF/resolve/main/llama-3.2-3b-instruct-q4_k_m.gguf";
  #   # url = "https://huggingface.co/unsloth/ERNIE-4.5-21B-A3B-Thinking-GGUF/resolve/main/ERNIE-4.5-21B-A3B-Thinking-UD-Q4_K_XL.gguf";
  #   # url = "https://huggingface.co/ggml-org/gpt-oss-20b-GGUF/resolve/main/gpt-oss-20b-mxfp4.gguf";
  #   # url = "https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q5_K_M.gguf";
  # };

  modelDrv = pkgs.fetchurl {
    # url = "https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q5_K_M.gguf";
    # url = "https://huggingface.co/mistralai/Devstral-Small-2507_gguf/resolve/main/Devstral-Small-2507-Q4_K_M.gguf";
    # url = "https://huggingface.co/unsloth/GLM-4.5-Air-GGUF/resolve/main/GLM-4.5-Air-UD-IQ2_M.gguf";
    url = "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf";
    sha256 = "sha256-2YzcvQPhfOR2gUNbUVDjTBQX9QtcABndVg5IgsV0V4U=";
  };
  #
  # modelSrc = lib.fileset.toSource {
  #   root = ./.;
  #   fileset = ./gpt-oss-20b.gguf;
  # };

  llama-cpp-vulkan = (
    pkgs.llama-cpp.overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DGGML_VULKAN=ON"
        # keep BLAS if you want it; your log shows it's detected
        # "-DGGML_BLAS=ON"
      ];

      # Let CMake find Vulkan + glslc
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        pkgs.pkg-config
      ];

      buildInputs = (old.buildInputs or [ ]) ++ [
        pkgs.vulkan-headers # provides Vulkan_INCLUDE_DIR
        pkgs.vulkan-loader # provides libvulkan.so (Vulkan_LIBRARY)
        pkgs.shaderc # provides `glslc`
        pkgs.glslang # (usually pulled by shaderc; safe to add)
        pkgs.spirv-tools # helpful for shader compilation chain
      ];
    })
  );
in
{

  hl1-io.node-meta.personas = [ "llm" ];
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.opengl.enable = true; # Enables Mesa + Vulkan loader
  hardware.opengl.driSupport32Bit = true;
  # hardware.opengl.driSupport = true;
  # programs.vulkan-loader.enable = true;

  environment.systemPackages = with pkgs; [
    vulkan-tools # vulkaninfo
    clinfo # useful even if you skip OpenCL/HIP
    lm_sensors
    llama-cpp-vulkan
  ];

  services.llama-cpp = {
    enable = true;
    port = 11111;
    package = llama-cpp-vulkan;

    model = modelDrv;
    # model = "${modelSrc}/gpt-oss-20b.gguf";
    extraFlags = [
      "--n-gpu-layers"
      "40"
      "--alias"
      "qwen3-8b"
      "--main-gpu"
      "1" # Skip APU
    ];
  };

  # services.ollama = {
  #   enable = true;
  #   host = "0.0.0.0";
  #   port = 11111;
  #   acceleration = "rocm";
  #   environmentVariables = {
  #     # ROC_ENABLE_PRE_VEGA = "1";
  #     # HSA_OVERRIDE_GFX_VERSION = "10.3.0";
  #     # ROCR_VISIBLE_DEVICES = "0";
  #     # HCC_AMDGPU_TARGET = "gfx1010";
  #     # HIP_VISIBLE_DEVICES = "2";
  #   };
  # };

  networking.firewall.allowedTCPPorts = [
    11111
    11112
  ];

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 11112;
    environment.OLLAMA_API_BASE_URL = "http://localhost:11112";
  };

  hl1-io.consul.services."llm" = {
    enable = true;
    label = "llm";
    port = 11111;
    subdomain = "llama";
    address = "127.0.0.1";
  };

  hl1-io.consul.services."open-webui" = {
    enable = true;
    label = "LLM Web UI";
    port = 11112;
    subdomain = "ai";
  };
}
