import json
import os
import subprocess

platform = os.environ['PROBE_PLATFORM']
requested = os.environ['PROBE_RUNTIME']
if platform == 'macOS':
    destination = 'platform=macOS,arch=arm64'
    selected = subprocess.check_output(['sw_vers', '-productVersion'], text=True).strip()
else:
    runtimes = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'runtimes', '-j']))
    matches = [r for r in runtimes['runtimes']
               if r.get('isAvailable') and r['name'].startswith(platform + ' ')
               and (r['version'] == requested or r['version'].startswith(requested + '.'))]
    if not matches:
        raise SystemExit(f'Required {platform} {requested} runtime unavailable: {runtimes}')
    runtime = max(matches, key=lambda r: tuple(map(int, r['version'].split('.'))))
    devices = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', '-j']))
    candidates = [d for d in devices['devices'].get(runtime['identifier'], []) if d.get('isAvailable')]
    if not candidates:
        raise SystemExit(f'No available device for {runtime}')
    device = candidates[0]
    if device['state'] != 'Booted':
        subprocess.run(['xcrun', 'simctl', 'boot', device['udid']], check=True)
    subprocess.run(['xcrun', 'simctl', 'bootstatus', device['udid'], '-b'], check=True)
    destination = f'platform={platform} Simulator,id={device["udid"]}'
    selected = f'{runtime["name"]} ({runtime["buildversion"]}), {device["name"]}'
with open(os.environ['GITHUB_ENV'], 'a') as f:
    f.write(f'PROBE_DESTINATION={destination}\nSELECTED_RUNTIME={selected}\n')
print(f'Probing {selected}: {destination}')
