{
  lib,
  self,
  ...
}: let
  inherit (builtins) attrValues filter match readDir pathExists concatLists;
  inherit (lib.attrsets) mapAttrsToList filterAttrs nameValuePair listToAttrs;
  inherit (lib.strings) hasPrefix hasSuffix removeSuffix;
  inherit (lib.trivial) id;
  inherit (self.attrs) mapFilterAttrs;
in rec {
  mapModules = dir: fn:
    mapFilterAttrs (n: v: v != null && !(hasPrefix "_" n)) (n: v: let
      path = "${toString dir}/${n}";
    in
      if v == "directory" && pathExists "${path}/default.nix"
      then nameValuePair n (fn path)
      else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n
      then nameValuePair (removeSuffix ".nix" n) (fn path)
      else nameValuePair "" null) (readDir dir);

  mapModules' = dir: fn: attrValues (mapModules dir fn);

  mapModulesRec = dir: fn:
    mapFilterAttrs (n: v: v != null && !(hasPrefix "_" n)) (n: v: let
      path = "${toString dir}/${n}";
    in
      if v == "directory"
      then nameValuePair n (mapModulesRec path fn)
      else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n
      then nameValuePair (removeSuffix ".nix" n) (fn path)
      else nameValuePair "" null) (readDir dir);

  mapModulesRec' = dir: fn: let
    dirs =
      mapAttrsToList (k: _: "${dir}/${k}")
      (filterAttrs (n: v: v == "directory" && !(hasPrefix "_" n))
        (readDir dir));
    files = attrValues (mapModules dir id);
    paths = files ++ concatLists (map (d: mapModulesRec' d id) dirs);
  in
    map fn paths;

  # src: https://github.com/peel/dotfiles/blob/main/flake.nix#L20
  mapModulesX = path: fn:
    let apply = fn: path: n: fn (path + ("/" + n));
        attrsIn = path: lib.attrNames (readDir path);
        isModuleIn = path: n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix"));
        named = n: x: nameValuePair ((removeSuffix ".nix") n) x;
    in
      listToAttrs (map
        (n: named n (apply fn path n))
        (filter (isModuleIn path) (attrsIn path)));

  # mapModulesX = path: fn:
  # let
  #   apply = fn: path: n: fn (path + ("/" + n));
  #   attrsIn = path: lib.attrNames (readDir path);
  #   isModuleIn = path: n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix"));
  #   named = n: x: nameValuePair ((removeSuffix ".nix") n) x;

  #   recurseIntoDir = dirPath:
  #     let
  #       dirAttrs = attrsIn dirPath;
  #       moduleAttrs = filter (n: isModuleIn dirPath n) dirAttrs;
  #       nestedDirs = filter (n: pathExists (dirPath + "/" + n) && builtins.isAttrs (readDir (dirPath + "/" + n))) dirAttrs;
  #       nestedResults = map (n: recurseIntoDir (dirPath + "/" + n)) nestedDirs;
  #     in
  #       listToAttrs (map (n: named n (apply fn dirPath n)) (moduleAttrs ++ nestedResults));

  # in recurseIntoDir path;

}
