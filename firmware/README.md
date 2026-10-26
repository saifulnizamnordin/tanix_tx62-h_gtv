# Firmware

Firmware images (`*.img`, `*.zip`, `*.7z`, …) are git-ignored because they are
far larger than GitHub's 100 MB file limit. Keep them here locally and record
where they came from below. (If you want them versioned, use Git LFS or attach
them to a GitHub Release.)

| File | Type | Version | Source URL | SHA256 |
|---|---|---|---|---|
| _stock (on device)_ | Android 10 | 2020-12-19 Oranth | OTA `http://www.oranthservice.com:81/TX6s_Oranth/update` |  |
| _official latest_ | `.img` | 2023-04-26 | [Tanix Google Drive](https://drive.google.com/drive/folders/1g834P9UZaf7YTlzWwfgjb7jhlyZzQ29O) |  |
| _custom GTV_ |  |  |  |  |

Get the checksum with:

```powershell
Get-FileHash .\firmware\<file> -Algorithm SHA256
```
