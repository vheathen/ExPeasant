$env:NERVES_HUB_KEY = Get-Content -Path 'nerves-hub/rpi3-01-key.pem' -Delimiter "`0"
$env:NERVES_HUB_CERT = Get-Content -Path 'nerves-hub/rpi3-01-cert.pem' -Delimiter "`0"
$env:NERVES_SERIAL_NUMBER = 'rpi3-01'

fwup.exe '_build\rpi3_prod\nerves\images\peasant_nerves.fw'
