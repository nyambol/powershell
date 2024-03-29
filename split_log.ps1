foreach ($i in $args){
    $out = $i.split('.')[0]
    $ext = $i.split('.')[1]
    $size = 200MB
    $reader = new-object System.IO.StreamReader($i) 
    $count = 1
    $fn = "{0}{1}.{2}" -f ($out, $count, $ext)
    while(($line = $reader.ReadLine()) -ne $null){
        Add-Content -path $fn -value $line
        if((Get-ChildItem -path $fn).Length -ge $size){
            ++$count
            $fn = $fn = "{0}{1}.{2}" -f ($out, $count, $ext)
        }
    }
    $reader.close()
}