param ([string]$BLAISE_LICENSE_KEY, [string]$BLAISE_ACTIVATION_CODE)

. "$PSScriptRoot\..\helpers\set_blaise_license_key.ps1"

SetBlaiseLicenseViaRegistry $BLAISE_LICENSE_KEY $BLAISE_ACTIVATION_CODE
