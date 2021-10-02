<?php
require_once(__DIR__ . "/config.php");

$ms = mysqli_connect(HOST, USER, PASS, BASE);
    
if($ms)
{
    $time_to_check = time() - 7 * 86400;
    $query = mysqli_query($ms, "SELECT * FROM `steamids` WHERE `time_created` >= " . $time_to_check . ";");
    if(mysqli_num_rows($query) > 0)
    {
        $data_array = array();

        while($v = mysqli_fetch_array($query))
        {
            $data_array[date("Y-m-d", $v["time_created"])] = (isset($data_array[date("Y-m-d", $v["time_created"])])) ? $data_array[date("Y-m-d", $v["time_created"])] + 1 : 1;
        }
        
        ksort($data_array);
        
        foreach($data_array as $k => $v)
        {
            echo $k . ": " . $v . "<br />" . PHP_EOL;
        }
    }
    else
    {
        echo "No data" . PHP_EOL;
    }
    
    mysqli_close($ms);
}
else
{
    echo "No database connection" . PHP_EOL;
}
