# BADoS Demo

This folder contains a small end-to-end demo for testing BIG-IP BADoS behavior with:

- an AS3 declaration that deploys the protected HTTP service
- a baseline traffic generator
- an attack traffic generator

## Folder layout

- `as3_bados/`
  - `bados.json`: AS3 declaration for tenant/app, pool, DoS profile, WAF policy, iRule, and data groups
  - `bados_xff_insert.irule.txt`: iRule source used to insert randomized `X-Forwarded-For` values
- `attack-vm/`
  - `baseline_menu.sh`: interactive baseline traffic generator (curl-based)
  - `dos_attack.sh`: interactive attack traffic generator (ApacheBench-based)
  - `config/`: supporting files such as URL paths and user-agent lists

## Demo objective

Build baseline behavior first, then run controlled attack traffic so BADoS can detect and mitigate suspicious patterns while you observe profile behavior and logs.

## Prerequisites

- BIG-IP with AS3 installed and reachable via management API
- Target virtual address used in this demo: `192.168.57.82`
- A traffic host (attack VM) with:
  - `curl`
  - `shuf`
  - `ab` (ApacheBench)
- Reachability from source interfaces configured in scripts

## Deploy AS3 declaration

```bash
cd as3_bados
curl -sku admin:admin \
  https://<bigip-mgmt>/mgmt/shared/appsvcs/declare \
  -H "Content-Type: application/json" \
  -X POST \
  -d @bados.json
```

## Generate baseline traffic

```bash
cd ../attack-vm
chmod +x baseline_menu.sh
./baseline_menu.sh
```

Menu options:
- `increasing` (Option 1): traffic volume grows with current minute
- `alternate` (Option 2): odd/even hours switch between higher/lower traffic

Preferred selection: use Option 2 (`alternate`) for this demo.

## Observe BADoS learning state

Use this command on BIG-IP to determine the learning state of the BADoS policy attached to this demo virtual server:

```bash
admd -s vs./bados/bados_service/service_http+/bados/bados_service/bados_profile.info.learning
```

![admd-shell-output](/bados_demo/assets/shell-admd-output.png)

The key fields in the output are:

1. `baseline_learning_confidence`: confidence (%) in baseline learning. Target: `> 90%`.
2. `learned_bins_count`: number of learned bins. Target: `> 0`.
3. `good_table_size`: number of learned good requests. Target: `> 2000`.
4. `good_table_confidence`: confidence (%) in the learned good table. Target: `100` for signatures.

Notes:
- It can take several minutes (often 5+ minutes) for baseline values to populate.
- Keep baseline traffic running while learning builds and also during the attack simulation.
- Once these numbers are reached you can start the attack simulation.

## Start attack simulation

```bash
chmod +x dos_attack.sh
./dos_attack.sh
```

Menu options:
- `Attack start - similarity` (Option 1)
- `Attack start - score` (Option 2)
- `Attack end`

Preferred selection: use Option 2 (`Attack start - score`) for this demo.

## Configuration notes

- Source/target IPs are hard-coded in the scripts; update before running in a different lab.
- The virtual server IP (`VS_ADDR`, currently `192.168.57.82`) is hard-coded in both `attack-vm/baseline_menu.sh` and `attack-vm/dos_attack.sh`; change it in both files for your environment.
- `dos_attack.sh` uses three hard-coded source addresses by default:
  - `192.168.57.12`
  - `192.168.57.13`
  - `192.168.57.14`
  change these for your environment.
- `baseline_menu.sh` uses baseline hard-coded source addresses by default:
  - `192.168.57.10`
  - `192.168.57.11`
  change these for your environment.

## Safety

Run this only in an isolated test environment. The attack script intentionally generates high-volume traffic and can impact shared networks or systems.