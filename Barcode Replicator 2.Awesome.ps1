﻿function Release-Ref ($ref) { #function releasing the internet explorer objects that will get created constantly everytime 
$ref.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) | out-null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
}


#loading screen
write-host "Loading, please wait..."

#assigning variables that only have to be assigned once
$url = "https://www.onlinelabels.com/label-generator-tools/Barcode-Generator.aspx"
$ie = new-object -comobject internetexplorer.application #opening ie
$wc = New-Object System.Net.WebClient #needed to download the barcode image onto network
$ie.visible = $false #hides ie window and works in background
$ie.silent = $true #hides notifications from ie
$ie.navigate($url)
while( $ie.busy){Start-Sleep 1} #waits for page to load before accessing html elements
$ie.Document.getElementById('ctl00_main_content_rdlBarcodeTypes_5').Checked = $true #checks the appropriate radio button for the kind of barcode to be generated
$BarcodePrompt = (Read-Host "Please enter the barcode. If more than one, add space between codes").trim()
$TotalPrompt = (Read-Host "Please enter # of tubes. If different amounts, add space between numbers").trim()
$spacesPrompt = (Read-Host "Please enter # of spaces. Just hit enter for none").trim()
$TotalArr = $TotalPrompt.split(" ") #splits user response into an array of barcodes
$combinedTotal = 0
$BarcodeArr = $BarcodePrompt.split(" ") #creates array of barcode numbers
$Word = NEW-Object –comobject Word.Application #opens word
$Word.Visible = $true #Opens word
$i = 1
$j = 1
$x = 0

if (($spacesPrompt -ne '') -or ($spacesPrompt -ne 0)){ #allow user to enter through prompt or to place a value if they wish
    $addCol = $spacesPrompt%8
    $addRow = [math]::floor($spacesPrompt/8)
    $i+=$addRow
    $j+=$addCol
}

if($totalArr.length -ne $BarcodeArr.length) {
    for ($n = $totalArr.length; $n -lt $BarcodeArr.length; $n++) {
        $totalArr+=$totalArr[$totalArr.length-1]
    }
    if ($spacesPrompt -ne 0) {
        $totalArr+=$spacesPrompt
    }
}

write-host "Generating barcodes. It may take longer if you have many barcodes. Please wait..."
forEach ($num in $totalArr){$combinedTotal += $num} #Combines the total number of barcodes into one number to make sure if it will be more than one page
$Document = $Word.documents.open("\\qdcns0002\ath_data$\ATHDept\Laboratory\Immunology\Misc\Label Templates\Phenix Microtube Labels LB-005R.doc") #opens barcoding template
$Table =$Document.Tables.item(1)
$TableCols = $Table.Columns.Count
$TableRows = $Table.Rows.Count
if ($combinedTotal -gt $TableCols*$TableRows){ #if more than one page, extend the number of rows in the document
    write-host "Extending Word Document to accomodate number of barcodes"
    $newRows = [math]::ceiling($combinedTotal/$TableCols)-$TableRows #the number of rows to add is decided by the total number of barcodes divided by the total nubmer of columns then rounded up, then the current number of rows is subtracted
    for($times = 0; $times -lt $newRows; $times++){$Table.Rows.Add()}
    $TableRows = $Table.Rows.Count
}


forEach ($Barcode in $BarcodeArr) { #downloads barcodes from barcode website and stores them in this folder
    $ie.Document.getElementById('ctl00_main_content_txtData').Value = $Barcode.toUpper() #inputs the name of the barcode in all caps into the input field
    $ie.Document.getElementById('ctl00_main_content_cmdGenerate').Click() #activates the web script to generate the barcode
    start-sleep 1 #allows time for page to load, otherwise the URL of the barcode img will be null
    $barcodeURL = $ie.Document.getElementById('ctl00_main_content_imgBarcode').src 
    $location = "\\Qdcns0002\ath_data$\ATHDept\Laboratory\Immunology\Gyros\Labels\"+$barcode.toUpper()+".png" 
    $wc.DownloadFile($barcodeURL, $location) #saves the generated URL into the network for use
}

forEach ($Barcode in $BarcodeArr) { #applies each barcode and replicates them onto the template
    $BarcodeLocation = "\\qdcns0002\ath_data$\ATHDept\Laboratory\Immunology\Gyros\Labels\"+$Barcode+".png"
    TRY {$objShape = $Table.Cell($i,$j).Range.InlineShapes.AddPicture($BarcodeLocation)}
    CATCH {write-host "Invalid Barcode :( Make sure the barcode is in this folder or check your spelling"} #if barcode doesnt exist, program will error but will not stop, it will just skip that barcode
    $objShape.height = 22
    $objShape.width = 44
    $Table.Cell($i,$j).Range.Copy()
    $count = 0
    while ($i -le $TableRows) {
        while ($j -le $TableCols) {     
            $count++
            Write-host $i "x" $j
            Write-host $count
            $table.Cell($i,$j).Range.Paste()
            $j++
            if ($j -gt 8) {
                $j = 1
                $i++
                break
            }   
            if ($count -eq $TotalArr[$x]) {
                break
            }
        }
        if ($count -eq $TotalArr[$x]) {
            break
            write-host $count
        }
        
    }
   $count = 0
   $x++
}

#deletes any PNG files created
get-childitem "\\qdcns0002\ath_data$\ATHDept\Laboratory\Immunology\Gyros\Labels\" -include *.png -recurse | foreach ($_) {remove-item $_.fullname}

Release-Ref($ie)

#ending screen
write-host "All set! Have a nice day!"
Start-Sleep 1
