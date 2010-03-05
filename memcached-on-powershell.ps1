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

function global:Memcached-Stats($server, $port){

  #-----------------------------------------------------------------
  # Functions local to the script
  #-----------------------------------------------------------------
  function get-Command-Result($command){
    $writer.WriteLine($command)
    $writer.Flush()
    
    $buffer = (new-object System.Byte[] 4096)
    $read = $stream.Read($buffer, 0, 4096) 
    
    return ((new-object System.Text.AsciiEncoding).GetString($buffer, 0, $read))
  }

  function get-Slabs($results){
    $slabs = @()
    $regex = 'STAT (?<slabid>.*):'
    foreach ($match in [regex]::matches($results, $regex)) {
      $item = [int]$match.Groups['slabid'].Captures[0].Value
      if ($item -notcontains $last){
        $slabs += $item
      }
      $last = $item
    }
    
    return $slabs
  }

  function write-Slabs($slabs){
    if ($slabs -eq $null){
      write-host 'No slabs found' -fore red
      return
    }
    foreach ($slab in $slabs){
      write-host 'Stats for Slab: ' $slab -fore yellow
  
      write-Cache-Dump (get-Command-Result ('stats cachedump {0} 0' -f $slab))
    }
  }
  
  function write-Cache-Dump($results){
    if ($results.length -eq 5){
      write-host `t 'Empty' -fore red
    }
    
    $regex = 'ITEM (?<keyid>.*) \[([0-9].*) b; (?<timestamp>.*) s'
    foreach ($match in [regex]::matches($results, $regex)) {
      #write-host `t 'Age: ' -fore green -no;
      #write-host (convert-From-Unix-Timestamp($match.Groups['timestamp'].Captures[0].Value)) -no
      write-host `t 'Key: ' -fore green -no; 
      write-host $match.Groups['keyid'].Captures[0].Value; 
    }
  }
  
  function convert-From-Unix-Timestamp($timestamp){
      $origin = new-object DateTime(1970, 1, 1, 0, 0, 0, 0);
      $origin.AddSeconds($timestamp);
  }

  #-----------------------------------------------------------------
  # Main	
  #-----------------------------------------------------------------
  $socket = new-object System.Net.Sockets.TcpClient($server, $port)
  $stream = $socket.GetStream() 
  $writer = new-object System.IO.StreamWriter $stream 

  write-Slabs (get-Slabs (get-Command-Result 'stats slabs'))
}