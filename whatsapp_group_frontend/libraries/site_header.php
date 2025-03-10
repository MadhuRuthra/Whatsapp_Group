<?php
/*
This page has some functions which is access from Frontend.
This page is act as a Backend page which is connect with Node JS API and PHP Frontend.
It will collect the form details and send it to API.
After get the response from API, send it back to Frontend.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 01-Jul-2023
*/
session_start();
error_reporting(0);
// Include configuration.php
include_once('../api/configuration.php');
extract($_REQUEST);

$current_date = date("Y-m-d H:i:s"); ?>

<nav class="navbar navbar-expand-lg main-navbar">
  <form class="form-inline mr-auto">
    <ul class="navbar-nav mr-3">
      <li><a href="#" data-toggle="sidebar" class="nav-link nav-link-lg"><i class="fas fa-bars"></i></a></li>
    </ul>
    <? $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
    //     $replace_txt = '{
    // "user_id" : "'.$_SESSION['yjwatsp_user_id'].'"    }';
    $curl = curl_init();
    curl_setopt_array(
      $curl,
      array(
        CURLOPT_URL => $api_url . '/user/user_details',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_SSL_VERIFYPEER => 0,
        CURLOPT_CUSTOMREQUEST => 'GET',
        CURLOPT_HTTPHEADER => array(
          $bearer_token,
          'Content-Type: application/json'
        ),
      )
    );
    site_log_generate("Manage Whatsappno List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [] on " . date("Y-m-d H:i:s"), '../');
    $response = curl_exec($curl);
    curl_close($curl);
    $user_dlt = json_decode($response, false);
    site_log_generate("Manage Whatsappno List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

    if ($user_dlt->response_status == 403) { ?>
      <script>window.location = "logout"</script>
    <? }
    $indicatori = 0;
    if ($user_dlt->response_status == 200) {
      for ($indicator = 0; $indicator < count($user_dlt->user_details); $indicator++) {
        $indicatori++;
        $plan_whatsapp_no_count = $user_dlt->user_details[$indicator]->plan_whatsapp_no_count;
        $plan_group_no_count = $user_dlt->user_details[$indicator]->plan_group_no_count;
        $available_whatsapp_no_count = $user_dlt->user_details[$indicator]->available_whatsapp_no_count;
        $available_group_no_count = $user_dlt->user_details[$indicator]->available_group_no_count;
        $message_limit = $user_dlt->user_details[$indicator]->message_limit;
        //  $used_credits = $user_dlt->user_details[$indicator]->used_credits;
      }
    }
    ?>
  </form>
  <div class="search-element">
    <? if ($user_dlt->response_status == 201) { ?>
      <div class="toast">
        <span class="badge badge-danger">
          <?= $user_dlt->response_msg ?>
        </span>
        <a href="pricing_plan" class="badge badge-success">
          Upgrade Now
          <!-- <i class="fa fa-level-up badge badge-secondary" style="font-size:22px;color:red"></i>Upgrade Now -->
        </a>
      </div>
    <? } else { ?>
      <div>
        <span class="badge badge-secondary"
          style="color:#FFF; font-size:15px; font-weight: bold; text-align: right;">Whatsapp Count :
          <?= $available_whatsapp_no_count ?>
        </span>
        <span class="badge badge-secondary"
          style="color:#FFF; font-size:15px; font-weight: bold; text-align: right;">Group Count :
          <?= $available_group_no_count ?>
        </span>
        <span class="badge badge-secondary"
          style="color:#FFF; font-size:15px; font-weight: bold; text-align: right;">Balance :
          <?= $message_limit ?>
        </span>
      </div>

    <? } ?>
  </div>

  <ul class="navbar-nav navbar-right">
    <li class="dropdown"><a href="#" data-toggle="dropdown" class="nav-link dropdown-toggle nav-link-lg nav-link-user">
        <img alt="image" src="assets/img/avatar/avatar-1.png" class="rounded-circle mr-1">
        <div class="d-sm-none d-lg-inline-block">Hi,
          <?= strtoupper($_SESSION['yjwatsp_user_name']) ?>
        </div>
      </a>
      <div class="dropdown-menu dropdown-menu-right">
        <a href="user_profile" class="dropdown-item has-icon">
          <i class="fas fa-user"></i> User Profile
        </a>
        <a href="change_password" class="dropdown-item has-icon">
          <i class="fas fa-bolt"></i> Change Password
        </a>

        <div class="dropdown-divider"></div>
        <a href="logout" class="dropdown-item has-icon text-danger">
          <i class="fas fa-sign-out-alt"></i> Logout
        </a>
      </div>
    </li>
  </ul>
</nav>
