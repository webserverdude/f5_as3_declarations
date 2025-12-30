# How to Use `gen_ssl.sh` with the Parallel Option

This guide explains how to use the `gen_ssl.sh` script with the `--parallel` option to generate SSL certificates concurrently.

## Prerequisites

- Ensure `gen_ssl.sh` is executable:  
    ```bash
    chmod +x gen_ssl.sh
    ```
- Install any required dependencies as specified in the script documentation.

## Usage

Run the script by streaming job numbers into GNU parallel (or `xargs`) to run multiple instances concurrently.

```bash
seq 1 <num_jobs> | parallel --bar -j "$(nproc)" ./gen_ssl.sh {}
```

- `<num_jobs>`: Number of certificate jobs to run (e.g., `4` to run jobs 1..4).

### Example

Generate SSL certificates using 4 parallel jobs:

```bash
seq 1 4 | parallel --bar -j "$(nproc)" ./gen_ssl.sh {}
```

You can also run the script directly to generate a single certificate by passing its index:

```bash
./gen_ssl.sh 1
```

## Notes

- Using GNU `parallel` can significantly speed up certificate generation on multi-core systems.
- Check the script's help for other supported options.
- To dry-run without writing files, prefix with `echo` or replace `./gen_ssl.sh` with `echo ./gen_ssl.sh` in the `parallel` command.