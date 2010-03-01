#-------------------------------------------------------------------
#
#	Prints Memcached Cache stats to PowerShell
#
# Sample usage:
#    
#  Get your Memcached Stats
#    PS> Memcached-Stats 'www.livejournal.com' '11211'
#
#	Adam Kahtava - http://adam.kahtava.com/ - MIT Licensed    
#-------------------------------------------------------------------

function global:Memcached-Stats($server, $port) {
  #-----------------------------------------------------------------
  # Functions local to the script
  #-----------------------------------------------------------------
  function script:get-Command-Result($command, $stream, $writer){
    $writer.WriteLine($command)
    $writer.Flush()
    
    $buffer = (new-object System.Byte[] 1024)
    $read = $stream.Read($buffer, 0, 1024) 
    
    return ((new-object System.Text.AsciiEncoding).GetString($buffer, 0, $read))
  }

  function script:get-Slabs($results){
    $slabs = @()
    $regex = 'STAT (?<slabid>.*):'
    foreach ($dude in [regex]::matches($result, $regex)) {
      $item = [int]$dude.Groups['slabid'].Captures[0].Value
      if ($item -notcontains $last){
        $slabs += $item
      }
      $last = $item
    }
    return $slabs
  }

  function script:write-Slabs($slabs){
    if (!$slabs){
      write-host 'No slabs found' -fore yellow
      return
    }
    foreach ($slab in $slabs){
      write-host 'Stats for Slab: ' $slab -fore yellow
  
      $writer.WriteLine(('stats cachedump {0} 0' -f $slab))
      $writer.Flush()
        
      $buffer = (new-object System.Byte[] 4096)
      $read = $stream.Read($buffer, 0, 4096) 
      
      $result = ((new-object System.Text.AsciiEncoding).GetString($buffer, 0, $read))
      
      script:write-Cache-Dump $results	
    }
  }
  
  function script:write-Cache-Dump($results){
    if ($result.length -eq 5){
      write-host `t 'Empty' -fore red
    }
    
    $regex = 'ITEM (?<keyid>.*) \[([0-9].*) b; (?<timestamp>.*) s'
    foreach ($item in [regex]::matches($result, $regex)) {
      write-host `t 'Age: ' -fore green -no; 	
      write-host (script:convert-From-Unix-Timestamp($item.Groups['timestamp'].Captures[0].Value)) -no
      write-host `t 'Key: ' -fore green -no; 
      write-host $item.Groups['keyid'].Captures[0].Value; 
    }
  }
  
  function script:convert-From-Unix-Timestamp($timestamp){
      $origin = new-object DateTime(1970, 1, 1, 0, 0, 0, 0);
      $origin.AddSeconds($timestamp);
  }

  #-----------------------------------------------------------------
  # Main	
  #-----------------------------------------------------------------
  $socket = new-object System.Net.Sockets.TcpClient($server, $port)
  $stream = $socket.GetStream() 
  $writer = new-object System.IO.StreamWriter $stream 

  write-Slabs (get-Slabs (get-Command-Result 'stats slabs' $stream $writer))
}