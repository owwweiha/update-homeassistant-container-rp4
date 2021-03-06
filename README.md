# update-homeassistant-container-rp4

Simple BASH script for updating homeassistant running as container on raspberry 4.

**NOTE: For this script to work, the homeassistant container needs to be run with podman, not docker**

You could use this script in a cron job to automatically check for updates on the homeassistant container every night.

The script was developed to fulfill my needs, no guarantee that it works in different environments.

## Usage

```bash
bash update-homeassistant.sh <your-config-folder>
```
Replace <your-config-folder> with the path to the folder you want to use for your homeassistant config, e.g., `/home/pi/homeassistant/`
