Expected directory structure

```
pytorch-devel
|_ Dockerfile
|_ Makefile
|_ 1            # main pytorch worktree
|_ ...          # any additional worktrees
|
|_ tmp          # the Makefile sets up the following dirs
|  |_ ccache    #
|_ cache        #
   |_ ccache    #
   |_ uv        #

```

Unless specified, it is assumed that all the commands are run from `pytorch-devel`.
The `Makefile` and `Dockerfile` supplied here take care of setting up the build environment and contain all the build settings.
All the build/test commands are run inside a docker container. The container image can be created by running `make torchdev`.
To start the container: `make start`. This will also set up a shared directory structure between the container and the host.
Once in the container, to build any worktree, just run: `make -C <path to worktree> -f $PWD/Makefile build`.

The `torchdev` docker image uses `uv` to manage python. To run any python scripts: `uv run python <script>`.
