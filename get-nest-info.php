<?php

/*
Requires: https://github.com/gboudreau/nest-api to be installed as $HOME/nest-api/

Change the path to nest.class.php below if needed
*/

require_once(__DIR__.'/../nest-api/nest.class.php');

// Your Nest username and password
$username = '';
$password = '';

date_default_timezone_set('America/Toronto');

$nest = new Nest($username, $password);

$location_info = $nest->getUserLocations();
$device_info = $nest->getDeviceInfo();

printf("A_OutsideTemp %.0f\n", $location_info[0]->outside_temperature);
printf("B_InsideTemp %.02f\n", $device_info->current_state->temperature);
printf("C_TargetTemp %.02f\n", $device_info->target->temperature);
printf("D_RelativeHumidity %.0f\n", $device_info->current_state->humidity);
printf("E_FurnaceOn %.0f\n", $device_info->current_state->heat);
printf("F_AirConOn %.0f\n", $device_info->current_state->ac);
printf("G_FanOn %.0f\n", $device_info->current_state->fan);
printf("H_Battery %.03f\n", $device_info->current_state->battery_level);
printf("I_OutsideHumidity %.0f\n", $location_info[0]->outside_humidity);
