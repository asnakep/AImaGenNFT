with (import <nixpkgs> {});
stdenv.mkDerivation {
  name = "pythonVirtualEnv";
  buildInputs = [

    # Python requirements (get python Virtual Env for pip install).
    # Needed for Stable Diffusion AI Image generator
    # Activate Virtual Env
    # python3 -m venv ImaGen OR virtualenv ImaGen
    # source ImaGen/bin/activate
    # pip install <module name>
    # Deactivate Virtual Env
    # deactivate
    
    python39Full
    python39Packages.virtualenv
    python39Packages.pip
    python39Packages.setuptools
    python39Packages.requests
  ];
  
  
  shellHook = 

  ''
  export REPLICATE_API_TOKEN=c59f31d2d89528ccf9f5137818476b1e6cbcdfdc
  
  python3 -m venv AImaGen/StableDiffusion/ImaGen
  source AImaGen/StableDiffusion/ImaGen/bin/activate
    
  '';

}
