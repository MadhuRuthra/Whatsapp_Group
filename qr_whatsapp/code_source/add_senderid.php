<?php
session_start();
error_reporting(0);
include_once('api/configuration.php');
extract($_REQUEST);

if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>
    window.location = "index";
  </script>
  <?php exit();
}

$allowd = 1;

if ($allowd == 0) { ?>
  <script>
    window.location = "whatsapp_no_api_list";
  </script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME);
site_log_generate("Manage Sender ID Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Manage Sender ID ::
    <?= $site_title ?>
  </title>

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">
</head>
<style>
  .loader {
    width: 50;
    background-color: #ffffffcf;
  }

  .loader img {}
</style>

<body>
  <div id="app">
    <div class="main-wrapper main-wrapper-1">
      <div class="navbar-bg"></div>

      <? include("libraries/site_header.php"); ?>

      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <div class="section-header">
            <h1>Manage Sender ID</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="manage_senderid_list">Manage Sender ID List</a>
              </div>
              <div class="breadcrumb-item">Manage Sender ID</div>
            </div>
          </div>

          <div class="section-body">
            <div class="row">

              <div class="col-12 col-md-8 col-lg-8 offset-2">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frm_store" name="frm_store" action="#" method="post"
                    enctype="multipart/form-data">
                    <div class="card-body">
                      <? if ($_REQUEST['mob'] == '') { ?>
                        <div class="form-group mb-2 row">
                          <label class="col-sm-3 col-form-label">Country Code</label>
                          <div class="col-sm-9">
                            <select id="txt_country_code" name="txt_country_code" class="form-control" tabindex="1"
                              autofocus>
                              <?
                              $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
                              $replace_txt = '{
                              "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
                            }';
                              $curl = curl_init();
                              curl_setopt_array(
                                $curl,
                                array(
                                  CURLOPT_URL => $api_url . '/list/country_list',
                                  CURLOPT_RETURNTRANSFER => true,
                                  CURLOPT_ENCODING => '',
                                  CURLOPT_MAXREDIRS => 10,
                                  CURLOPT_TIMEOUT => 0,
                                  CURLOPT_FOLLOWLOCATION => true,
                                  CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                                  CURLOPT_SSL_VERIFYPEER => 0,
                                  CURLOPT_CUSTOMREQUEST => 'GET',
                                  CURLOPT_POSTFIELDS => $replace_txt,
                                  CURLOPT_HTTPHEADER => array(
                                    $bearer_token,
                                    'Content-Type: application/json'
                                  ),
                                )
                              );
                              site_log_generate("Manage Sender ID Page : " . $uname . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');

                              $response = curl_exec($curl);
                              curl_close($curl);
                              $state1 = json_decode($response, false);

                              if ($response == '') { ?>
                                <script>
                                  window.location = "index"
                                </script>
                              <? } else if ($response->response_status == 403) { ?>
                                  <script>
                                    window.location = "index"
                                  </script>
                              <? }
                              site_log_generate("Manage Sender ID Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

                              if ($state1) {
                                for ($indicator = 0; $indicator < count($state1->country_list); $indicator++) {
                                  $shortname = $state1->country_list[$indicator]->shortname;
                                  $phonecode = $state1->country_list[$indicator]->phonecode;
                                  $countryid = $state1->country_list[$indicator]->id;
                                  ?>
                                  <option value="<?= $countryid . "~~" . $phonecode ?>" <? if
                                        ($shortname == 'IN') {
                                          echo "selected";
                                        } else {
                                          echo "disabled";
                                        } ?>><?=
                                           $shortname . " +" . $phonecode ?>
                                  </option>
                                <?php }
                              }
                              site_log_generate("Manage Sender ID Page : User : " . $_SESSION['yjwatsp_user_name'] . " executed the Query ($sql_dashboard1) on " . date("Y-m-d H:i:s"));
                              ?>
                            </select>
                          </div>
                        </div>
                      <? } ?>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Mobile Number <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-9">
                          <input type="text" name="mobile_number" id='mobile_number' class="form-control"
                            value="<?= $_REQUEST['mob'] ?>" tabindex="1" required="" maxlength="10"
                            placeholder="Mobile Number" data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Mobile Number" onkeypress="return validateInput(event)" <? if (
                              $_REQUEST['mob']
                              != ''
                            ) { ?> readonly <? } ?>>
                        </div>
                      </div>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Profile Name </label>
                        <div class="col-sm-9">
                          <input type="text" name="txt_display_name" id='txt_display_name' class="form-control"
                            tabindex="2" maxlength="30" value="<?= $_REQUEST['pro'] ?>" <? if ($_REQUEST['pro'] != '') {
                                ?> readonly <? } ?> placeholder="Profile Name" data-toggle="tooltip" data-placement="top"
                            title="" data-original-title="Profile Name">
                        </div>
                      </div>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Profile Image </label>
                        <div class="col-sm-9 text-left">
                          <? if ($_REQUEST['img'] != '' && $_REQUEST['img'] != '-') {
                            $_SESSION['img_name'] = $_REQUEST['img'];
                            echo "<img src='" . $_REQUEST['img'] . "' style='width:100px; max-height: 100px;'>";
                          } else if ($_REQUEST['img'] == '-') {
                            echo "<p style='padding-left:10px;padding-top:5px;'>-</p>";
                          } ?>
                          <input type="file" class="form-control" name="fle_display_logo" id='fle_display_logo'
                            tabindex="3" accept="image/png, image/jpg, image/jpeg" data-toggle="tooltip"
                            data-placement="top" title="" <? if ($_REQUEST['img'] != '') { ?> style="display: none" <? } ?>
                            data-original-title="Profile Image - Allowed only jpg, png images.Maximum 2 MB Size allowed">
                        </div>
                      </div>

                      <div class="card-footer text-center">
                        <span class="error_display" id='id_error_display'></span><br>
                        <input type="submit" name="compose_submit" id="compose_submit" tabindex="5" value="Submit"
                          class="btn btn-success">

                        <div class="container">
                          <span class="error_display" style='font-size: 12px;' id='qrcode_display'></span><Br>
                          <img src='./assets/img/loader.gif' id="id_qrcode" alt='QR Code'>
                          <!-- QR Code display Panel -->
                        </div>
                      </div>

                  </form>
                </div>
              </div>
            </div>

            <div class="text-left">
              <span class="error_display1"><b>Note :</b> <br> 1) Enter 10 digit mobile number.<br> 2) The
                sender ID or
                the mobile should not have or used whats app. We recommend a fresh mobile nos for all your
                communications. <br> 3) Super admin will have all the right to control the Sender ID,
                template ID
                creation in terms of coordination & approval <br> 4) Profile Image - Allowed only jpg, png
                images.
                Maximum 2 MB Size allowed</span>
            </div>
          </div>
        </section>
      </div>

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

  <!--Remove dublicates numbers -->
  <script>
    document.addEventListener('DOMContentLoaded', function () {
      var txt_display_name = document.getElementById('txt_display_name');
      // Add event listener for input events
      txt_display_name.addEventListener('input', function (event) {
        // Get the entered text
        var inputText = txt_display_name.value;
        // Define a regular expression pattern to match the `˜` character
        var tildeRegex = /['"`]/g;
        // Test if the entered text contains the `˜` character
        if (tildeRegex.test(inputText)) {
          // Remove the `˜` character from the text
          txt_display_name.value = inputText.replace(tildeRegex, '');
        }
      });
    });

    // On loading the page, this function will call
    $(function () {
      $('#id_qrcode').fadeOut("slow");
    });

    var fd;
    // If the Function get no response and timeout
    function show_timeout() {
      $('#id_qrcode').hide();
      $("#qrcode_display").html("Timed out, Waiting for new QR Code");
    }

    function validateInput(event) {
      const inputValue = event.target.value + String.fromCharCode(event.charCode);
      // Allow only numeric input, check the length, and ensure the first digit is between 1 and 5
      return (
        (event.charCode >= 48 && event.charCode <= 57) &&
        inputValue.length <= 10 && // Set the maximum length
        (inputValue.length === 1 ? (event.charCode >= 54 && event.charCode <= 57) : true)
      );
    } <?
    if ($_REQUEST['mob'] == '') {
      ?>
      const upload_limit = 2; //Maximum 2 MB
      // File type validation
      console.log("**")
      $("#fle_display_logo").change(function () {
        // xls, xlsx, csv, txt
        var file = this.files[0];
        var fileType = file.type;
        var match = ['image/jpeg', 'image/jpg', 'image/png'];
        if (!((fileType == match[0]) || (fileType == match[1]) || (fileType == match[2]) || (fileType ==
          match[3]) || (fileType == match[4]) || (fileType == match[5]))) {
          $("#id_error_display").html('Sorry, only PNG, JPG files are allowed to upload.');
          $("#fle_display_logo").val('');
          return false;
        }

        const size = this.files[0].size / 1024 / 1024;
        if (size < upload_limit) {
          return true;
        } else {
          $("#id_error_display").html('Maximum File size allowed - ' + upload_limit +
            ' MB. Kindly reduce and choose below ' + upload_limit + ' MB');
          $("#fle_display_logo").val('');
          return false;
        }
      }); <?
    } else {
      ?>
      $('#fle_display_logo').prop("required", false); <?
    } ?>
    var mobile_number;
    var fd;
    $(document).on("submit", "form#frm_store", function (e) {
      e.preventDefault();
      console.log("came Inside");
      $("#id_error_display").html("");
      $('#mobile_number').css('border-color', '#a0a0a0');
      $('#txt_display_name').css('border-color', '#a0a0a0');
      $('#fle_display_logo').css('border-color', '#a0a0a0');

      //get input field values
      mobile_number = $('#mobile_number').val();
      var txt_display_name = $('#txt_display_name').val();
      var fle_display_logo = $('#fle_display_logo').val();
      var flag = true; <?
      if ($_REQUEST['mob'] == '') {
        ?>
        /********validate all our form fields***********/
        /* mobile_number field validation  */
        if (mobile_number == "") {
          $('#mobile_number').css('border-color', 'red');
          console.log("##");
          flag = false;
        }

        if ((mobile_number.length <= 9)) {
          $('#mobile_number').css('border-color', 'red');
          $("#id_error_display").html("Mobile numbers must contain 10 digits!");
          console.log("##");
          flag = false;
        }

        var stt = -1;

        // If Mobile NO > 5
        if ((mobile_number.length == 10) || (mobile_number.length == 12)) {
          var letter = mobile_number.charAt(0);
          if (letter == 0 || letter == 1 || letter == 2 || letter == 3 || letter == 4 || letter ==
            5) { // First Character is in 0 to 5 then INVALID
            stt = 0;
          } else { // Else VALID
            stt = 1;
          }
          if (stt == 0) { // Send Invalid Response
            $('#mobile_number').css('border-color', 'red');
            $("#id_error_display").html("Mobile number starting from 6 to 9");
            flag = false;
          } else
            $('#mobile_number').css('border-color', '#ccc'); // Success Response
        }


        /* If all are ok then we send ajax request to ajax/master_call_functions.php *******/
        if (flag) {
          fd = new FormData(this);
          var files = $('#fle_display_logo')[0].files;
          if (files.length > 0) {
            fd.append('file', files[0]);
          }
          $.ajax({
            type: 'post',
            url: "ajax/store_call_functions.php?store_call_function=senderid_status_check",
            dataType: 'json',
            data: fd,
            contentType: false,
            processData: false,
            beforeSend: function () { // Before send to Ajax
              $('#id_qrcode').show();
              $('#compose_submit').addClass('btn-outline-light btn-disabled').removeClass(
                'btn-success');
              $('#compose_submit').css("pointer-events", "none");
            },
            complete: function () { // After complete the Ajax
            },
            success: function (response) { // Success
              if (response.status == 1) { // Success Response
                $('#mobile_number').prop('readonly', true);
                $('#txt_display_name').prop('readonly', true);
                get_qrcode_once();
              } else if (response.status == 0) { // Failure Response
                $('#mobile_number').val('');
                $('#id_qrcode').hide();
                $("#id_error_display").html(response.msg);
                $('#compose_submit').addClass('btn-success').removeClass(
                  'btn-outline-light btn-disabled');
                $('#compose_submit').css("pointer-events", "auto");
                $('#mobile_number').prop('readonly', false);
                $('#compose_submit').addClass('btn-success').removeClass(
                  'btn-outline-light btn-disabled');
                $('#compose_submit').css("pointer-events", "block");
              }
            },
            error: function (response, status, error) { // Error
              $('#mobile_number').val('');
              $('#id_qrcode').show();
              $("#id_error_display").html(response.msg);
            }
          })
          return stt;
        } <?
      } else {
        ?>
        fd = new FormData(this);
        get_qrcode_once(); <?
      } ?>

      function get_qrcode_once() {
        $.ajax({
          type: 'post',
          url: "ajax/store_call_functions.php?store_call_function=mobile_qrcode",
          dataType: 'json',
          data: fd,
          contentType: false,
          processData: false,
          beforeSend: function () { // Before send to Ajax
            $('#id_qrcode').show();
            $('#compose_submit').addClass('btn-outline-light btn-disabled').removeClass(
              'btn-success');
            $('#compose_submit').css("pointer-events", "none");
          },
          complete: function () { // After complete the Ajax
          },
          success: function (response) { // Success
            if (response.status == 1) { // Success Response
              $('#id_qrcode').show();
              $("#id_qrcode").attr("src", response.qrcode);
              $('#mobile_number').prop('readonly', true);
              $("#qrcode_display").html(
                'Please wait, automatically it will redirect after link!!');
              setInterval(show_timeout, 50000); // After 50 seconds show timeout msg
            } else if (response.status == 2 || response.status == 2) { // Loading
              if (response.msg == 'QRcode already scanned.') {
                $('#mobile_number').val('');
                $('#id_qrcode').hide();
                $('#mobile_number').prop('readonly', false);
                $('#compose_submit').css("pointer-events", "auto");
                $("#qrcode_display").html(response.msg);
                setInterval(function () {
                  window.location = "manage_senderid_list";
                }, 2000);
              } else {
                $("#qrcode_display").html(response.msg);
              }
            } else if (response.status == 0) { // Failure Response
              $('#mobile_number').val('');
              $('#txt_display_name').val('');
              $('#fle_display_logo').val('');
              $('#id_qrcode').hide();
              $("#qrcode_display").html("");
              $("#id_error_display").html(response.msg);
              $('#compose_submit').addClass('btn-success').removeClass(
                'btn-outline-light btn-disabled');
              $('#compose_submit').css("pointer-events", "auto");
              $('#mobile_number').prop('readonly', false);
              $('#compose_submit').addClass('btn-success').removeClass(
                'btn-outline-light btn-disabled');
              $('#compose_submit').css("pointer-events", "block");
            }
          },
          error: function (response, status, error) { // Error
            $('#mobile_number').val('');
            $('#id_qrcode').show();
            $("#id_error_display").html(response.msg);
          }
        })
        setInterval(get_qrcode_once, 120000); // Every min it will call
      }
    });
    document.body.addEventListener("click", function (evt) {
      $("#id_error_display").html("");
    });

    //setInterval(get_qrcode_once, 120000);   // Every min it will call
  </script>
</body>

</html>