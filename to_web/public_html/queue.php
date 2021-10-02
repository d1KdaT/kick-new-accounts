<?php
require_once(__DIR__ . "/config.php");

$ms = mysqli_connect(HOST, USER, PASS, BASE);
if($ms)
{
    $query = mysqli_query($ms, "SELECT * FROM `queue`;");
    if(mysqli_num_rows($query) > 0)
    {
        while($v = mysqli_fetch_array($query))
        {
            $account_id = intval($v["account_id"]);

            $api_data = api("GetPlayerSummaries", ["steamids" => s2tos64($account_id)]);
            if(isset($api_data["players"][0]["timecreated"]))
            {
                $time_created = intval($api_data["players"][0]["timecreated"]);
                
                mysqli_query($ms, "REPLACE INTO `steamids` (`account_id`, `time_created`) VALUES (" . $account_id . ", " . $time_created . ");");
            }
            
            mysqli_query($ms, "DELETE FROM `queue` WHERE `account_id` = " . $account_id . ";");
        }
    }
}
else
{
    error_log("No database connection" . PHP_EOL);
}

// FUNCTIONS
function s2tos64($steamid2 = 1)
{
  return (76561197960265728 + $steamid2);
}

function api($method, array $query = array())
{
    foreach($query as $param => $value)
    {
        if(is_array($value))
        {
        	$query[$param] = implode(',', $value);
        }
    }

    $query["key"] = API_KEY;
    $url = "https://" . API_URL . "/ISteamUser/" . $method . "/v0002/?" . http_build_query($query);
    $result = json_decode(curl($url), true);

    if(isset($result['response']))
    {
    	return $result['response'];
    }

    return $result;
}

function curl($url)
{
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
        curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
        $result = curl_exec($ch);

        if(!$result)
        {
                return false;
        }

        curl_close($ch);
        return $result;
}
