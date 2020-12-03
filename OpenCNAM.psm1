<#
.SYNOPSIS
    Lookup the OpenCNAM database for specified phone number.
.DESCRIPTION
    Looks in the OpenCNAM database for the specified phone number and returns
    caller ID information. Requires authentication. Uses 10 digit North American
    phone numbers at the moment.
.PARAMETER PhoneNumber
    Number to query. May be used as an array.
.PARAMETER Sid
    Required.  You must have an account at opencnam.com to obtain this.
.PARAMETER AuthToken
    Required.  You must have an account at opencnam.com to obtain this.
.EXAMPLE
    Get-OpenCNAMResult -PhoneNumber '2024561414' -Sid '<removed>' -AuthToken '<removed>'
    Makes the query and returns the result against 202-456-1414.
.NOTES
    Author                  :  @jadedtreebeard
    Disclaimer              :  If you run it, you take all responsibility for it.
#>
function Get-OpenCNAMResult
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string[]]$PhoneNumber,
        [Parameter(Mandatory=$True)][string]$Sid,
        [Parameter(Mandatory=$True)][string]$AuthToken
    )

    # Check to see if the Sid and Token are specified. If not, return an error.
    if (($Sid -eq $null) -or ($AuthToken -eq $null)){
        Write-Error -Message 'Authentication required. Please specify Sid and AuthToken.'
    } # End if
    else{
        $results = @()
        
        # Create the headers
        $Pair = "${sid}:${AuthToken}"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($Pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $basicAuthValue = "Basic $base64"
        $Headers = @{ Authorization = $basicAuthValue }

        foreach ($number in $PhoneNumber){
            $result = $null
            $url = "https://api.opencnam.com/v3/phone/+1$number`?format=json"
            try { $result = Invoke-WebRequest -Uri $url -Headers $Headers }
            catch{
                $Code = $_.Exception.Response.StatusCode.Value__
                
                Switch ($Code){
                    200 { Write-Verbose "HTTP $Code OK.  Result returned - $number." }
                    400 { Write-Warning "HTTP $Code BAD REQUEST.  Invalid phone number - $number."}
                    402 { Write-Warning "HTTP $Code PAYMENT REQUIRED.  Out of funds on Professional tier."}
                    403 { Write-Warning "HTTP $Code FORBIDDEN.  Exceeded hourly limits on Hobbyist tier."}
                    404 { Write-Warning "HTTP $Code NOT FOUND.  No result available. - $number"}
                    503 { Write-Error "HTTP $Code SERVICE UNAVAILBLE.  Error with request, try again later."}
                    default { Write-Error "HTTP $Code error." }
                } # End switch             
            } # End catch
            
            if ($result){
                $obj = $result | ConvertFrom-Json
                $results = $results + $obj
            } # End if
        } # End for loop

        Write-Output $results

    } # End else
} # End function

#test
