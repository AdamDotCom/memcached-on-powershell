#-------------------------------------------------------------------
#
# Prints Memcached Cache stats to PowerShell
#
# Sample usage:
#    
#  Get your Memcached Stats
#    PS> Memcached-Stats '127.0.0.1' '11411'
#
# Adam Kahtava - http://adam.kahtava.com/ - MIT Licensed    
#
#-------------------------------------------------------------------

function global:memcached-on-powershell{

  function script:get-Command-Result($command){
    $writer.WriteLine($command)
    $writer.Flush()
    
    $buffer = (new-object System.Byte[] 4096)
    $read = $stream.Read($buffer, 0, 4096) 
    
    return ((new-object System.Text.AsciiEncoding).GetString($buffer, 0, $read))
  }

  function script:get-Slabs($results){
    $slabs = @()
    $regex = 'STAT (?<slabid>.*):'
    foreach ($match in [regex]::matches($results, $regex)){
      $item = [int]$match.Groups['slabid'].Captures[0].Value
      if ($item -notcontains $last){
        $slabs += $item
      }
      $last = $item
    }
    
    return $slabs
  }

  function script:write-Slabs($slabs){
    if ($slabs -eq $null){
      write-host 'No slabs found' -fore red
      return
    }
    foreach ($slab in $slabs){
      write-host 'Stats for Slab: ' $slab -fore yellow
  
      write-Cache-Dump (get-Command-Result ('stats cachedump {0} 0' -f $slab))
    }
  }
  
  function script:write-Cache-Dump($results){
    if ($results.length -eq 5){
      write-host `t 'Empty' -fore red
    }
    
    $regex = 'ITEM (?<keyid>.*) \[([0-9].*) b; (?<timestamp>.*) s'
    foreach ($match in [regex]::matches($results, $regex)){
      write-host `t 'Key: ' -fore green -no; 
      write-host $match.Groups['keyid'].Captures[0].Value; 
    }
  }
  
  function script:write-Slab-Stats($results){
    $regex = 'STAT curr_items (?<totalItems>.*)'
    foreach ($match in [regex]::matches($results, $regex)){
      write-host 'Total items in cache: ' ($match.Groups['totalItems'].Captures[0].Value) -fore red
    }   
  }
}

function global:remove-all-items($server, $port){
  memcached-on-powershell # Load in memcache symbols

  $socket = new-object System.Net.Sockets.TcpClient($server, $port)
  $stream = $socket.GetStream() 
  $writer = new-object System.IO.StreamWriter $stream 
  
  $slabs = (get-Slabs (get-Command-Result 'stats slabs'))
  
  foreach ($slab in $slabs){
    do{
      $results = get-Command-Result ('stats cachedump {0} 0' -f $slab)
      
      $regex = 'ITEM (?<keyid>.*) \['    
      foreach ($match in [regex]::matches($results, $regex)){
        $key = $match.Groups['keyid'].Captures[0].Value
        $deleteResult = get-Command-Result ('delete {0}' -f $key)
      }
    } while ($results.length -gt 5)
  }
  
  write-Slab-Stats (get-Command-Result 'stats') 
}

function global:Memcached-Stats($server, $port){
  memcached-on-powershell # Load in memcache symbols

  $socket = new-object System.Net.Sockets.TcpClient($server, $port)
  $stream = $socket.GetStream() 
  $writer = new-object System.IO.StreamWriter $stream 

  write-Slab-Stats (get-Command-Result 'stats') 
  write-Slabs (get-Slabs (get-Command-Result 'stats slabs'))
} 