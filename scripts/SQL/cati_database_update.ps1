try
{
    if (!$env:ENV_BLAISE_CATI_URL) {
        $CATI_URL=$env:ENV_BLAISE_EXTERNAL_SERVER_HOST_NAME
    } else {
        $CATI_URL=$env:ENV_BLAISE_CATI_URL
    }
    Write-Output "Updating Cati Database : $CATI_URL"
    c:\dev\data\sqlite3 D:\Blaise5\Settings\ServerManagerDatabase.db "Update Server Set Name='$CATI_URL', Binding='https' where id=2;"
}
catch {
    Write-Output "Cati Database Update has failed"
    Write-Output $_
    exit 1
}
Write-Output "Cati Database updated"

