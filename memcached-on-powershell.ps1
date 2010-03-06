#-------------------------------------------------------------------
#
# Prints Memcached Cache stats to PowerShell
#
# Sample usage:
#    
#  See your Memcached Stats
#    PS> memcached-stats '127.0.0.1' '11211'
#
#  Remove your Memcached keys
#    PS> clear-memcached-items '127.0.0.1' '11211'
#
# Adam Kahtava - http://adam.kahtava.com/ - MIT Licensed    
#
#-------------------------------------------------------------------

function global:memcached-on-powershell{

  function script:get-memcached-command-result($command){
    $writer.WriteLine($command)
    $writer.Flush()
    
    $buffer = (new-object System.Byte[] 4096)
    $read = $stream.Read($buffer, 0, 4096) 
    
    return ((new-object System.Text.AsciiEncoding).GetString($buffer, 0, $read))
  }

  function script:get-memcached-slabs($results){
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

  function script:write-memcached-slabs($slabs){
    if ($slabs -eq $null){
      write-host 'No slabs found' -fore red
      return
    }
    foreach ($slab in $slabs){
      write-host 'Stats for Slab: ' $slab -fore yellow
  
      write-memcached-cachedump (get-memcached-command-result ('stats cachedump {0} 0' -f $slab))
    }
  }
  
  function script:write-memcached-cachedump($results){
    if ($results.length -eq 5){
      write-host `t 'Empty' -fore red
    }
    
    $regex = 'ITEM (?<keyid>.*) \[([0-9].*) b; (?<timestamp>.*) s'
    foreach ($match in [regex]::matches($results, $regex)){
      write-host `t 'Key: ' -fore green -no; 
      write-host $match.Groups['keyid'].Captures[0].Value; 
    }
  }
  
  function script:write-memcached-slab-stats($results){
    $regex = 'STAT curr_items (?<totalItems>.*)'
    foreach ($match in [regex]::matches($results, $regex)){
      write-host 'Total items in cache: ' ($match.Groups['totalItems'].Captures[0].Value) -fore red
    }   
  }
}

function global:clear-memcached-items($server, $port){
  memcached-on-powershell # Load memcache symbols

  $socket = new-object System.Net.Sockets.TcpClient($server, $port)
  $stream = $socket.GetStream() 
  $writer = new-object System.IO.StreamWriter $stream 
  
  $slabs = (get-memcached-slabs (get-memcached-command-result 'stats slabs'))
  
  foreach ($slab in $slabs){
    do{
      $results = get-memcached-command-result ('stats cachedump {0} 0' -f $slab)
      
      $regex = 'ITEM (?<keyid>.*) \['    
      foreach ($match in [regex]::matches($results, $regex)){
        $key = $match.Groups['keyid'].Captures[0].Value
        $deleteResult = get-memcached-command-result ('delete {0}' -f $key)
      }
    } while ($results.length -gt 5)
  }
  
  write-memcached-slab-stats (get-memcached-command-result 'stats') 
}

function global:memcached-stats($server, $port){
  memcached-on-powershell # Load memcache symbols

  $socket = new-object System.Net.Sockets.TcpClient($server, $port)
  $stream = $socket.GetStream() 
  $writer = new-object System.IO.StreamWriter $stream 

  write-memcached-slab-stats (get-memcached-command-result 'stats') 
  write-memcached-slabs (get-memcached-slabs (get-memcached-command-result 'stats slabs'))
} 