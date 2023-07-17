try
{
    if (!$env:ENV_BLAISE_CATI_URL) {
        $CATI_URL=$env:ENV_BLAISE_EXTERNAL_SERVER_HOST_NAME
    } else {
        $CATI_URL=$env:ENV_BLAISE_CATI_URL
    }
    Write-Information "Updating Cati Database : $CATI_URL"
    c:\dev\data\sqlite3 D:\Blaise5\Settings\ServerManagerDatabase.db "Update Server Set Name='$CATI_URL', Binding='https' where id=2;"
}
catch {
    Write-Information "Cati Database Update has failed"
    Write-Information $_
    exit 1
}
Write-Information "Cati Database updated"

