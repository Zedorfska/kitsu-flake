{
  description = "Kitsu (CGWire): web frontend and Zou API";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    kitsu-src = {
      url = "github:cgwire/kitsu";
      flake = false;
    };
    zou-src = {
      url = "github:cgwire/zou";
      flake = false;
    };
    gazu-src = {
      url = "github:cgwire/gazu";
      flake = false;
    };
    flask-fs2-src = {
      url = "github:cgwire/flask-fs2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, kitsu-src, zou-src, gazu-src, flask-fs2-src }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      py = pkgs.python3Packages;

      versionFrom = file: builtins.head (
        builtins.match ''[[:space:]]*__version__ = "([^"]+)"[[:space:]]*''
          (builtins.readFile file)
      );

      kitsu = pkgs.buildNpmPackage {
        pname = "kitsu";
        version = (builtins.fromJSON (builtins.readFile "${kitsu-src}/package.json")).version;
        src = kitsu-src;

        nodejs = pkgs.nodejs_24;

        npmDepsHash = "sha256-14YzboiI4/LA0SvnlkCsz5iLJAkr2YXgeTvZadbEQwA=";

        makeCacheWritable = true;

        npmRebuildFlags = [ "--ignore-scripts" ];

        env.HUSKY = "0";

        installPhase = ''
          runHook preInstall
          cp -r dist $out
          runHook postInstall
        '';

        meta = {
          description = "Kitsu, collaboration platform for animation and VFX studios (web frontend)";
          homepage = "https://kitsu.cg-wire.com";
          license = pkgs.lib.licenses.agpl3Only;
        };
      };


      gazu = py.buildPythonPackage {
        pname = "gazu";
        version = versionFrom "${gazu-src}/gazu/__version__.py";
        pyproject = true;
        src = gazu-src;

        build-system = [ py.setuptools ];

        dependencies = with py; [
          python-socketio
          websocket-client
          requests
          typing-extensions
        ];

        doCheck = false;
        pythonImportsCheck = [ "gazu" ];

        meta = {
          description = "Python client for the Kitsu API (Zou)";
          homepage = "https://gazu.cg-wire.com";
          license = pkgs.lib.licenses.lgpl3Only;
        };
      };

      flask-fs2 = py.buildPythonPackage {
        pname = "flask-fs2";
        version = versionFrom "${flask-fs2-src}/flask_fs/__version__.py";
        pyproject = true;
        src = flask-fs2-src;

        build-system = [ py.setuptools ];

        dependencies = with py; [
          flask
          python-dateutil
          werkzeug
          cryptography
          boto3
          python-swiftclient
          python-keystoneclient
        ];

        pythonRelaxDeps = true;

        doCheck = false;
        pythonImportsCheck = [ "flask_fs" ];

        meta = {
          description = "CGWire's fork of Flask-FS, file storage backends for Flask";
          homepage = "https://github.com/cgwire/flask-fs2";
          license = pkgs.lib.licenses.mit;
        };
      };

      pysaml2-fixed = py.pysaml2.overridePythonAttrs (old: {
        doCheck = false;
        meta = old.meta // { broken = false; };
      });

      zou = py.buildPythonApplication {
        pname = "zou";
        version = versionFrom "${zou-src}/zou/__init__.py";
        pyproject = true;
        src = zou-src;

        build-system = [ py.setuptools ];

        dependencies = (with py; [
          authlib
          babel
          click
          discordpy
          email-validator
          ffmpeg-python
          fido2
          flasgger
          bcrypt
          flask-bcrypt
          flask-caching
          flask-cors
          flask-mail
          flask-sqlalchemy
          flask-jwt-extended
          flask-migrate
          flask-socketio
          flask
          gevent-websocket
          gevent
          gunicorn
          itsdangerous
          jinja2
          ldap3
          meilisearch
          numpy
          opencv4
          orjson
          pydantic
          pillow
          psutil
          psycopg
          pyjwt
          pyotp
          python-nomad
          python-slugify
          python-socketio
          pytz
          redis
          requests
          rq
          semver
          slack-sdk
          spdx-license-list
          sqlalchemy-utils
          sqlalchemy
          tabulate
          tomlkit
          ua-parser
          werkzeug
        ]) ++ [
          gazu
          flask-fs2
          pysaml2-fixed
        ];

        pythonRelaxDeps = true;

        pythonRemoveDeps = [
          "opencv-python-headless"
          "OpenTimelineIO"
          "OpenTimelineIO-Plugins"
        ];

        makeWrapperArgs = [ "--prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ffmpeg ]}" ];

        doCheck = false;

        meta = {
          description = "Zou, the Kitsu API";
          homepage = "https://zou.cg-wire.com";
          license = pkgs.lib.licenses.agpl3Only;
          mainProgram = "zou";
        };
      };
    in
    {
      packages.${system} = {
        inherit kitsu zou gazu flask-fs2;
        default = kitsu;
      };
    };
}
