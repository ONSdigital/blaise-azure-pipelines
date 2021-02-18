try
{
    write-host "Updated Cati Database : $env:ENV_BLAISE_EXTERNAL_SERVER_HOST_NAME"
    c:\dev\data\sqlite3 D:\Blaise5\Settings\ServerManagerDatabase.db "Update Server Set Name='$env:ENV_BLAISE_EXTERNAL_SERVER_HOST_NAME', Binding='https' where id=2;"
    write-host "Cati Database updated"
}
catch {
    Write-Host "Cati Database Update has failed"
    Write-Host $_
}
