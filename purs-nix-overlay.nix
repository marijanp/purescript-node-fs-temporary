npmlock2nix:
(_: super: {
  node-os = {
    src.git = {
      repo = "https://github.com/marijanp/purescript-node-os.git";
      rev = "d0d672eb42007b544a3148988cf58e9806e70266";
    };
    info = {
      dependencies = [
        "prelude"
        "node-buffer"
        "foreign-object"
        "datetime"
      ];
    };
  };
})
