# Firmware

Firmware images (`*.img`, `*.zip`, `*.7z`, …) are git-ignored because they are
far larger than GitHub's 100 MB file limit. Keep them here locally and record
where they came from below. (If you want them versioned, use Git LFS or attach
them to a GitHub Release.)

| File | Type | Version | Source URL | SHA256 |
|---|---|---|---|---|
| _stock_ |  |  |  |  |
| _custom GTV_ |  |  |  |  |

Get the checksum with:

```powershell
Get-FileHash .\firmware\<file> -Algorithm SHA256
```
