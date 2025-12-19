# How to Test Runtime of `curl` with `-w` Option

This guide explains how to measure the runtime of a `curl` command using its built-in **write-out** feature.

---

## ✅ Step 1: Basic Timing Output
Use the `-w` (write-out) option to display the total time taken by the request:

```bash
curl -sku admin:yourpassword   -H "Content-Type: application/json"   -X POST https://<bigip-mgmt>/mgmt/shared/appsvcs/declare   -d @as3_100_partitions_members_shareNodes.json   -w "
Total time: %{time_total}s
"
```

### Expected Output
```
Total time: 2.345s
```

---

## ✅ Step 2: Detailed Timing Metrics
You can include multiple timing variables for deeper insight:

```bash
curl -sku admin:yourpassword   -H "Content-Type: application/json"   -X POST https://<bigip-mgmt>/mgmt/shared/appsvcs/declare   -d @as3_100_partitions_members_shareNodes.json   -w "
Connect: %{time_connect}s | StartTransfer: %{time_starttransfer}s | Total: %{time_total}s
"
```

### Variables Explained
- **`time_connect`**: Time to establish the TCP connection.
- **`time_starttransfer`**: Time until the first byte is received.
- **`time_total`**: Total time for the request.

---

## ✅ Step 3: Combine with Silent Mode
Add `-s` to suppress progress and `-o /dev/null` to discard output if you only care about timing:

```bash
curl -sku admin:yourpassword   -H "Content-Type: application/json"   -X POST https://<bigip-mgmt>/mgmt/shared/appsvcs/declare   -d @as3_100_partitions_members_shareNodes.json   -s -o /dev/null   -w "
Connect: %{time_connect}s | StartTransfer: %{time_starttransfer}s | Total: %{time_total}s
"
```

---

## ✅ Step 4: Log Results to a File
Redirect timing output to a log file for later analysis:

```bash
curl -sku admin:yourpassword   -H "Content-Type: application/json"   -X POST https://<bigip-mgmt>/mgmt/shared/appsvcs/declare   -d @as3_100_partitions_members_shareNodes.json   -s -o /dev/null   -w "Connect: %{time_connect}s | StartTransfer: %{time_starttransfer}s | Total: %{time_total}s
" >> curl_runtime.log
```

---

### ✅ Pro Tip
You can also combine this with `time` for OS-level timing:
```bash
time curl ... -w "Total: %{time_total}s
"
```

---
