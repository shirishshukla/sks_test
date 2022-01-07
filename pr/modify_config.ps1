## powerashell modify xml ..
param (
  #[parameter(mandatory=$true)][string]$key,
  [string]$xmlfile='Web.config',
  [string]$key,
  [string]$value,
  [string]$xmlpath='/configuration/appSettings/add'
)

if ($key -and $value) {
    [xml]$xml=Get-Content $xmlfile
    $val=$xml.SelectSingleNode("/$xmlpath[@key='$key']")
    if ($val){
      $valo = $val.value
      if ($valo -ne $value){
        # change attribute on selected node
        write-host "Chainging: $key - $valo -> $value"
        $val.value=$value
        $xml.Save("$pwd/$xmlfile")
      } else {
        write-host "No Change: $key -> $value"
      }
    } else {
      Write-Host "Key: $key not exist in file: $xmlfile path: configuration/appSettings/add"
    }
} else {
  write-host "Either shoukld not blank -> key: $key, value: $xmlpath"
}
