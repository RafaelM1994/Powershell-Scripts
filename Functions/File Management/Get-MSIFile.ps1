Function Get-MSIFile{
    param (
        [String]$uri,
        [String]$out
    )
    Invoke-WebRequest -uri $uri -OutFile $out
    $msifile = Get-ChildItem -Path $out -File -Filter '*.ms*' 
    write-host "$msifile "

}

Get-MSIFile -uri $uri -out $out