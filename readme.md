# Utility Containers
- quick drop-in Containers for quick development of quick ideas or tasks

## These scripts can be run in any locations
> BE CAREFUL: where you run `dcrun` and `dcup`. Must be in location you want to build project. It cad add files to whatever location you are in
### `dcbuild`
```bash
DESCRIPTION: Builds and pushes a multi-arch Docker image using buildx for a given service and build stage.

USAGE:
  dcbuild <service> <version> [latest] [stage]

ARGUMENTS:
  <service>      Name of the service directory (e.g., python, node, etc.)
  <version>      Version tag to apply (e.g., v0.01)
  [latest]       Optional — also tag the image as 'latest'
  [stage]        Optional — Dockerfile build stage to target (e.g., 'dev' or 'prod')
                 Defaults to 'dev' if not provided or undefined.

EXAMPLES:
  dcbuild node v0.01                    # builds dev stage (default)
  dcbuild node v0.01 latest             # builds dev stage, tags as latest
  dcbuild node v0.01 latest prod        # builds production stage

This will build and push:
  javierfraga/utilcntr-<service>:<version>
  javierfraga/utilcntr-<service>:latest  (if specified)
```
### `dcrun` and `dcup`
```bash
DESCRIPTION: dcrun will add an ephemeral container.
DESCRIPTION: dcup runs a persistent container that must be stopped with dcstop or removed with dcdown.
Usage:
  dcrun <service>:<tag> <shell> [--port HOST:CONTAINER ...]
  dcrun <service> <tag> <shell> [--port HOST:CONTAINER ...]
  dcrun <service> <shell>             # uses :latest

  dcup <service>:<tag> <shell> [project] [--port HOST:CONTAINER ...]
  dcup <service> <tag> <shell> [project] [--port HOST:CONTAINER ...]
  dcup <service> <shell> [project]    # uses :latest

```
### `dcdown`
```bash
BE CAREFUL: THIS WILL REMOVE CONTAINERS PERMANENTLY!
Usage:
  dcdown                        # shut down project for current directory
  dcdown <proj1> [proj2 ...]    # shut down multiple projects

Example:
  dcdown myproject tmpproject
  => removes containers like: myproject-node-1, tmpproject-node-1
```
### `dcstop`
```bash
DESCRIPTION: Stop persistent containers started via dcup (but don't remove them).
Usage:
  dcstop                        # stop containers for current directory
  dcstop <proj1> [proj2 ...]    # stop containers in multiple projects

Example:
  dcstop dev tmp
  => stops dev-node-1 and tmp-node-1

```
### `dcstart`
```bash
DESCRIPTION: Start persistent containers started via dcup
Usage:
  dcstart                        # start containers for current directory
  dcstart <proj1> [proj2 ...]    # start containers in multiple projects

Example:
  dcstart dev tmp
  => starts dev-node-1 and tmp-node-1
```
### `dcupdate-labelkeep`
```bash
DESCRIPTION: Applies a protection label (keep=true) to containers in one or more projects.
Usage:
  dcupdate-labelkeep                    # protects current project
  dcupdate-labelkeep <proj1> [proj2]    # protects multiple projects

Example:
  dcupdate-labelkeep myproject tmp
  => sets keep=true on: myproject-node-1, tmp-node-1, etc.

```

### Other nice to knows
#### Alpine tips
how to add man docs for a program:
1. first ensure man pages is installed properly
```bash
apk update
apk add mandoc man-pages
```
2. next, install a man page manually per program, i.e. `grep`
```bash
apk add grep-doc
```
