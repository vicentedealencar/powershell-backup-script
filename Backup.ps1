#TODO translate code and comments to english
#TODO tirar Roots hard coded com arquivo de configuracao
#TODO caminhos relativos para path do script
#TODO logar cada write-host
#TODO gerar hash das pastas para verificar se foi alterada
#TODO parametro -Restore

    $startTime = Get-Date
	$Roots = @{ 
                "HOME-PC" = @("D:\Backups","D:\Projetos","D:\Puc","D:\Scripts","D:\Tatuis"); 
                "WORK-NOTE" = @("D:\Projects")
              }
    $Computer = Get-Content env:computername
	$logFile = "log.txt"
	if(Test-Path $logFile)
	{
		Clear-Content $logFile
	}
	
    #Pra cada pasta do vetor de de Roots no vetor de maquinas - hard coded
	foreach($root in $Roots[$Computer]){
        $rootSize = "{0:N2}" -f (((New-Object -com  Scripting.FileSystemObject).GetFolder("$root").Size)/1MB) + " MB"
        Write-Host "$root $rootSize" -ForegroundColor cyan
        
        #Carrega arquivo com paths e data e data de modificacao de todos os arquivos e pastas, existentes no backup, em um dicionario ($DicAExcluir["path"] = data de modificacao)    
        $folder = $Computer + "\" + $root.Replace("\","!").Replace(":","#")
        $arq = $folder + ".txt"

        if(-not (Test-Path $arq)){
            New-Item $arq -type file -force | Out-Null
        }
        
        $DicAExcluir = @{}
        #preenche o DicAExcluir
        foreach($f in Get-Content $arq){
            $record = $f.Split("|")
            $DicAExcluir.Add($record[0], $record[1])
        }

        $DicBackup = @{}
        #Para cada arquivo ou pasta a ser copiado
        foreach($f in Get-ChildItem $root -recurse){
            $copia = $true
            $fName = $f.FullName
            
            #se encontrar em chaves de DicAExcluir
            if($DicAExcluir.ContainsKey($f.FullName)){
            	#se for arquivo e a data de modificacao for igual que a do backup
                if( ($f.LastWriteTime.ToString() -eq $DicAExcluir[$f.FullName]) -or $f.Attributes.ToString().Contains("Directory") ){
                    #nao vai copiar
                	$copia = $false
                    Add-Content log.txt "n - $fName"
                }
            }
            
            if($copia){
                #copia arquivo pro backup
                $dst = $fName.Replace($root,$folder)
                $dst = $dst.Substring(0, $dst.lastindexof('\'))
                
                if(-not (Test-Path $dst)){
                    New-Item $dst -type directory -force | Out-Null
                }
                
                Copy-Item $fName $dst -force
                Write-Host "$fName adicionado" -ForegroundColor green
                Add-Content log.txt "c - $fName"
    		}
            
            #adiciona em DicBackup["path"] = data de modificacao
            $DicBackup.Add($f.FullName, $f.LastWriteTime.ToString())
            
            #retira do DicAExcluir
    		$DicAExcluir.Remove($f.FullName)
        }
        
        #Deleta tudo em DicAExcluir
        foreach($key in $DicAExcluir.Keys){
            $del = $key.Replace($root,$folder)
            Write-Host "$key removido" -ForegroundColor red
            Add-Content log.txt "r - $key"
            
            #force remove $del testando antes
            if(Test-Path $del){
                Remove-Item $del -Force -Recurse -Confirm:$false
            }
        }
    	
    	#Atualiza arquivo de paths com itens de DicBackup
        Clear-Content $arq
        foreach($key in $DicBackup.Keys){
            $value = $DicBackup[$key]
            $line = "$key|$value"
            Add-Content $arq $line
        }
    }
    $endTime = Get-Date
    $totalTime = New-TimeSpan $startTime $endTime
    Write-Host "Finalizado em $totalTime"
    Write-Host "Press any key to continue ..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null