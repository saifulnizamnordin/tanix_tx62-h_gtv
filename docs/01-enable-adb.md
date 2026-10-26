# 1. Enable ADB over network (stock firmware)

The box and the PC must be on the same LAN (Ethernet recommended).

## Enable Developer options

1. **Settings → Device Preferences → About** (on some Tanix builds: *Settings → About*).
2. Highlight **Build** and press OK on the remote **7 times** until
   "You are now a developer" appears.

## Enable USB / network debugging

1. Go back to **Device Preferences → Developer options**.
2. Turn on **USB debugging**.
3. If present, also turn on **Network debugging** / **ADB over network**.
   - Many Allwinner Tanix builds listen on TCP **5555** as soon as USB debugging is on.
   - Some have it under the Tanix launcher **Settings → Other → ADB debug**.
4. Note the box IP: **Settings → Network & Internet → (your network)**.

## Connect from the PC

```powershell
.\scripts\adb-connect.ps1 -Ip <box-ip>
```

The first time, the TV shows **"Allow USB debugging?"** – tick
*Always allow from this computer* and press **OK**. If the script reports
`unauthorized`, accept the prompt and run it again.

## If port 5555 is closed

If `adb connect` is refused, ADB is only enabled over USB. Connect once with a
USB A-to-A cable (USB-OTG port, usually the one next to the SD slot), then:

```powershell
adb tcpip 5555
```

Unplug the cable and use `adb-connect.ps1` again.
