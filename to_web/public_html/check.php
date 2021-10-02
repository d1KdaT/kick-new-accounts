<?php
require_once(__DIR__ . "/config.php");

if(isset($_GET["account_id"]))
{
    $account_id = intval($_GET["account_id"]);
    
    if(isset($_GET["needle_days"]) && intval($_GET["needle_days"]) >= 0 && intval($_GET["needle_days"]) <= 90)
    {
        $needle_days = intval($_GET["needle_days"]);
    }
    else
    {
        $needle_days = 7;
    }
    
    $time_to_check = time() - $needle_days * 86400;
    
    $ms = mysqli_connect(HOST, USER, PASS, BASE);
    
    if($ms)
    {
        $query = mysqli_query($ms, "SELECT * FROM `steamids` WHERE `account_id` <= " . $account_id . " AND `time_created` >= " . $time_to_check . ";");
        if(mysqli_num_rows($query) == 0)
        {
            header("HTTP/1.1 200 OK");
        }
        else
        {
            header("HTTP/1.1 204 Newer");
            
            $check_query = mysqli_query($ms, "SELECT * FROM `steamids` WHERE `account_id` = " . $account_id . ";");
            if(mysqli_num_rows($check_query) == 0)
            {
                mysqli_query($ms, "REPLACE INTO `queue` (`account_id`) VALUES (" . $account_id . ");");
            }
        }
        
        mysqli_close($ms);
    }
    else
    {
        header("HTTP/1.1 500 Internal error");
    }
}
else
{
    header("HTTP/1.1 400 Invalid request parameters");
}
