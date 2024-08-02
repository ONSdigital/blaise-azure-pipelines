param ([string]$BLAISE_LICENSE_KEY, [string]$BLAISE_ACTIVATION_CODE)

. "$PSScriptRoot\license_key_functions.ps1"

SetBlaiseLicenseViaRegistry $BLAISE_LICENSE_KEY $BLAISE_ACTIVATION_CODE
