<?php
/*
Primary Admin user only allow to this Manage Users page.
This page is used to manage the users.
It will send the form to API service 
and get the response from them and store into our DB.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 03-Jul-2023
*/

session_start(); // start session
error_reporting(0); // The error reporting function

include_once 'api/configuration.php'; // Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
    <script>window.location = "index";</script>
    <?php exit();
}

// If the logged in user is not Primary admin, it will redirect to Dashboard page
if ($_SESSION['yjwatsp_user_master_id'] != 1) { ?>
    <script>window.location = "dashboard";</script>
    <? exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate("Manage Users Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
// To Send the request  API
$replace_txt = '{
    "plan_master_id" : "' . $_REQUEST["plan_id"] . '"
  }';
  // Add bearer token
  $bearer_token = "Authorization: " . $_SESSION["yjwatsp_bearer_token"] . "";
  
  // It will call "p_login" API to verify, can we allow to login the already existing user for access the details
  $curl = curl_init();
  curl_setopt_array(
      $curl,
      array(
          CURLOPT_URL => $api_url . '/plan/get_plans',
          CURLOPT_RETURNTRANSFER => true,
          CURLOPT_ENCODING => '',
          CURLOPT_MAXREDIRS => 10,
          CURLOPT_TIMEOUT => 0,
          CURLOPT_FOLLOWLOCATION => true,
          CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
          CURLOPT_CUSTOMREQUEST => 'GET',
          CURLOPT_POSTFIELDS => $replace_txt,
          CURLOPT_HTTPHEADER => array(
              $bearer_token,
              'Content-Type: application/json'
          ),
      )
  );
  
  // Send the data into API and execute
  // Log file generate
  site_log_generate("View On Boarding Page : " . $uname . " Execute the service [$replace_txt, $bearer_token] on " . date("Y-m-d H:i:s"), "../");
  $response = curl_exec($curl);
  curl_close($curl);
  // After got response decode the JSON result
  $state1 = json_decode($response, false);
  // Log file generate
  site_log_generate("View On Boarding Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), "../");
  
  // To get the API response one by one data and assign to Session
  if ($state1->response_status == 200) {
  
      // Looping the indicator is less than the count of response_result.if the condition is true to continue the process.if the condition are false to stop the process
      for ($indicator = 0; $indicator < count($state1->report); $indicator++) {
          $whatsapp_no_max_count = $state1->report[$indicator]->whatsapp_no_max_count;
          $plan_title = $state1->report[$indicator]->plan_title;
          $group_no_max_count = $state1->report[$indicator]->group_no_max_count;
          $plan_price = $state1->report[$indicator]->plan_price;
          $annual_monthly = $state1->report[$indicator]->annual_monthly;
          $plan_status = $state1->report[$indicator]->plan_status;
      }
  }

?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
    <title>Plan Creation ::
        <?= $site_title ?>
    </title>
    <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

    <!-- General CSS Files -->
    <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
    <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

    <!-- CSS Libraries -->
    <!-- Template CSS -->
    <link rel="stylesheet" href="assets/css/style.css">
    <link rel="stylesheet" href="assets/css/components.css">
    <!-- style include in css -->
    <style>
        .progress {
            height: 0.2rem;
        }
    </style>
</head>

<body>
    <div id="app">
        <div class="main-wrapper main-wrapper-1">
            <div class="navbar-bg"></div>

            <!-- include header function adding -->
            <? include("libraries/site_header.php"); ?>

            <!-- include sitemenu function adding -->
            <? include("libraries/site_menu.php"); ?>

            <!-- Main Content -->
            <div class="main-content">
                <section class="section">
                    <!-- Title and Breadcrumbs -->
                    <div class="section-header">
                        <h1>Plan Creation</h1>
                        <div class="section-header-breadcrumb">
                            <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
                            <div class="breadcrumb-item active"><a href="manage_users_list">Manage Users List</a></div>
                            <div class="breadcrumb-item">Plan Creation</div>
                        </div>
                    </div>

                    <!-- User Creation Form panel -->
                    <div class="section-body">
                        <div class="row">

                            <div class="col-12 col-md-8 col-lg-8 offset-2">
                                <div class="card">
                                    <form class="needs-validation" novalidate="" id="frm_users" name="frm_users"
                                        action="#" method="post" enctype="multipart/form-data">
                                        <div class="card-body">
                                            <!-- select user type -->
                                            <div class="form-group mb-2 row">
                                                <label class="col-sm-4 col-form-label">Plan Name</label>
                                                <div class="col-sm-8">
                                                    <input type="email" name="plan_name"
                                                        onkeypress="return clsAlphaNoOnly(event)" id='plan_name'
                                                        class="form-control" maxlength="20" minlength="1" value="<?= $plan_title ?>"
                                                        tabindex="1" required="" data-toggle="tooltip"
                                                        data-placement="top" title="" data-original-title="Plan Name"
                                                        placeholder="Plan Name">
                                                </div>
                                            </div>
                                            <!-- Select Super Admin names -->
                                            <div class="form-group mb-2 row">
                                                <label class="col-sm-4 col-form-label">Pricing Validity</label>
                                                <div class="col-sm-8">
                                                    <select name="pricing_validity" id='pricing_validity' tabindex="2"
                                                        class="form-control" required="" data-toggle="tooltip"
                                                        data-placement="top" title=""
                                                        data-original-title="Monthly / Annual">
                                                        <? if($annual_monthly == 'M'){?>
                                                             <option value="M" selected>MONTHLY</option>
                                                       <? }else if($annual_monthly == 'A') {?>
                                                        <option value="Y" selected>ANNUALLY</option>
                                                      <? }else{ ?>
                                                        <option value="M">MONTHLY</option>
                                                        <option value="Y">YEARLY</option>
                                                        <? }?>
                                                    </select>
                                                </div>
                                            </div>

                                            <div class="form-group mb-2 row">
                                                <label class="col-sm-4 col-form-label">Monthly / Annual Price</label>
                                                <div class="col-sm-8">
                                                    <input type="email" name="plan_price"
                                                        onkeypress="return (event.charCode !=8 && event.charCode ==0 ||  (event.charCode >= 48 && event.charCode <= 57))"
                                                        id='plan_price' class="form-control" maxlength="6" minlength="1"
                                                        value="<?= $plan_price ?>" tabindex="3" required="" data-toggle="tooltip"
                                                        data-placement="top" title=""
                                                        data-original-title="Monthly / Annual Price"
                                                        placeholder="Monthly / Annual Price">
                                                </div>
                                            </div>

                                            <div class="form-group mb-2 row">
                                                <label class="col-sm-4 col-form-label">No of Whatsapps </label>
                                                <div class="col-sm-8">
                                                    <input type="email" name="no_of_whatsapps"
                                                        onkeypress="return (event.charCode !=8 && event.charCode ==0 ||  (event.charCode >= 48 && event.charCode <= 57))"
                                                        id='no_of_whatsapps' class="form-control" maxlength="11"
                                                        minlength="1"  value="<?= $whatsapp_no_max_count ?>" tabindex="4" required=""
                                                        data-toggle="tooltip" data-placement="top" title=""
                                                        data-original-title="No of Whatsapps"
                                                        placeholder="No of Whatsapps">
                                                </div>
                                            </div>
                                            <div class="form-group mb-2 row">
                                                <label class="col-sm-4 col-form-label">No of Groups</label>
                                                <div class="col-sm-8">
                                                    <input type="email" name="no_of_groups"
                                                        onkeypress="return (event.charCode !=8 && event.charCode ==0 ||  (event.charCode >= 48 && event.charCode <= 57))"
                                                        id='no_of_groups' class="form-control" maxlength="11"
                                                        minlength="1" value="<?= $group_no_max_count ?>" tabindex="5" required=""
                                                        data-toggle="tooltip" data-placement="top" title=""
                                                        data-original-title="No of Groups" placeholder="No of Groups">
                                                </div>
                                            </div>
                                            <!-- Error Display & Submit button -->
                                            <div class="error_display" id='id_error_display_signup'></div>
                                            <div class="card-footer text-center">
                                                <input type="hidden" class="form-control" name='temp_function'
                                                    id='temp_function' value='creation_plan' />
                                                    <input type="hidden" class="form-control" name='plan_master_id'
                                                    id='plan_master_id' value='<?= $_REQUEST["plan_id"]?>' />
                                                <input type="submit" name="submit_signup" id="submit_signup"
                                                    tabindex="6" value="Submit" class="btn btn-success">
                                            </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
            </div>

            <!-- include site footer -->
            <? include("libraries/site_footer.php"); ?>

        </div>
    </div>

    <!-- General JS Scripts -->
    <script src="assets/modules/jquery.min.js"></script>
    <script src="assets/modules/popper.js"></script>
    <script src="assets/modules/tooltip.js"></script>
    <script src="assets/modules/bootstrap/js/bootstrap.min.js"></script>
    <script src="assets/modules/nicescroll/jquery.nicescroll.min.js"></script>
    <script src="assets/modules/moment.min.js"></script>
    <script src="assets/js/stisla.js"></script>

    <!-- JS Libraies -->
    <!-- Page Specific JS File -->
    <!-- Template JS File -->
    <script src="assets/js/scripts.js"></script>
    <script src="assets/js/custom.js"></script>

    <script>

<? if(!$_REQUEST["plan_id"]){?>
            $('#plan_name').val('');
            $('#pricing_validity').val('')
                        $('#no_of_whatsapps').val('');
                        $('#no_of_groups').val('');
                        $('#no_of_messages').val('');
                        $('#plan_price').val('');
      <?  }?>
        // If Sign up submit button clicks
        $("#submit_signup").click(function (e) {
            $("#id_error_display_signup").html("");

            //get input field values
            var plan_name = $('#plan_name').val();
            var pricing_validity = $('#pricing_validity').val();
            var no_of_whatsapps = $('#no_of_whatsapps').val();
            var no_of_groups = $('#no_of_groups').val();
            // var no_of_messages = $('#no_of_messages').val();
            var plan_price = $('#plan_price').val();

            var flag = true;
            /********validate all our form fields***********/
            /* Login ID field validation  */
            if (plan_name == "") {
                $('#plan_name').css('border-color', 'red');
                flag = false;
                e.preventDefault();
            }
            /* Login Short Name field validation  */
            if (pricing_validity == "") {
                $('#pricing_validity').css('border-color', 'red');
                flag = false;
                e.preventDefault();
            }
            /* password field validation  */
            if (no_of_whatsapps == "") {
                $('#no_of_whatsapps').css('border-color', 'red');
                flag = false;
                e.preventDefault();
            }

            /* confirm_password field validation  */
            if (no_of_groups == "") {
                $('#no_of_groups').css('border-color', 'red');
                flag = false;
                e.preventDefault();
            }

            /* Email field validation  */
            // if (no_of_messages == "") {
            //     $('#no_of_messages').css('border-color', 'red');
            //     flag = false;
            //     e.preventDefault();
            // }
            /* Email field validation  */
            if (plan_price == "") {
                $('#plan_price').css('border-color', 'red');
                flag = false;
                e.preventDefault();
            }

            /********Validation end here ****/

            /* If all are ok then we send ajax request to ajax/call_functions.php *******/
            if (flag) {
                var data_serialize = $("#frm_users").serialize();
                $.ajax({
                    type: 'post',
                    url: "ajax/message_call_functions.php",
                    dataType: 'json',
                    data: data_serialize,
                    beforeSend: function () { // Before send to Ajax
                        $('#submit_signup').attr('disabled', true);
                        $('#load_page').show();
                    },
                    complete: function () { // After complete Ajax
                        $('#submit_signup').attr('disabled', false);
                        $('#load_page').hide();
                    },
                    success: function (response) { // Success
                        if (response.status == 0) { // Failure response
                            $('#plan_name').val('');
                            $('#no_of_whatsapps').val('');
                            $('#no_of_groups').val('');
                            $('#plan_price').val('');
                            $('#submit_signup').attr('disabled', true);
                            $("#id_error_display_signup").html(response.msg);
                        } else if (response.status == 1) { // Success Reponse
                            $('#submit_signup').attr('disabled', true);
                            $("#id_error_display_signup").html("Plan Created..!");
                            setInterval(function () {
                                window.location = 'user_plans_list';
                            }, 2000);
                        }
                        if (response.status == 2) { // Failure response
                            $('#submit_signup').attr('disabled', true);
                            $("#id_error_display_signup").html(response.msg);
                        }

                    },
                    error: function (response, status, error) { // Error
                        $('#plan_name').val('');
                        $('#no_of_whatsapps').val('');
                        $('#no_of_groups').val('');
                        $('#plan_price').val('');
                        $('#submit_signup').attr('disabled', false);
                        $("#id_error_display_signup").html(response.msg);
                    }
                });
            }
        });

        document.body.addEventListener("click", function (evt) {
            $("#id_error_display_signup").html("");
        })
    </script>
</body>

</html>