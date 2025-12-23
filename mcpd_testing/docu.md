# MCPD Multithreading

## Deploy AS3

```bash
curl -sku admin:Hacker0ne!   -H "Content-Type: application/json"   -X POST https://10.0.200.240/mgmt/shared/appsvcs/declare   -d @as3_SampleTenant_50_virtuals_memberShareNodes.json   -w "Connect: %{time_connect}s | StartTransfer: %{time_starttransfer}s | Total: %{time_total}s
```

## Delete all AS3

```bash
curl -sku admin:Hacker0ne!   -H "Content-Type: application/json"   -X DELETE https://10.0.200.240/mgmt/shared/appsvcs/declare
```

## Modify the number of MCPD worker threads worker threads

```bash
tmsh modify sys db mcpd.workerthreads value 4
```

## Get current number of MCPD worker threads worker threads

```bash
root@(bigip-v21)(cfg-sync Standalone)(Active)(/Common)(tmos)# list sys db mcpd.workerthreads
sys db mcpd.workerthreads {
    value "1"
}
```
