## Summary of commands

> [!NOTE]
> all commands are run from `pytorch-devel`

```bash
# clone pytorch into a directory named `1`
make setup

# build the development image using Dockerfile
# This determines package versions used in the pytorch environment
make torchdev

# run the development container
# This will also set up a shared directory structure between the container and the host
make start

# build pytorch
make -C <path to pytorch> -f $PWD/Makefile build

# The `torchdev` docker image uses `uv` to manage python.
# To run any python scripts:
uv run python <script>
```

## Expected directory structure

```
pytorch-devel
|_ Dockerfile
|_ Makefile
|_ 1            # main pytorch worktree (make setup)
|_ ...          # any additional worktrees (create manually if needed)
|
|_ tmp          # the Makefile sets up the following dirs
|  |_ ccache    #
|_ cache        #
   |_ ccache    #
   |_ uv        #

```
