<?php
session_start();
error_reporting(0);
include_once('api/configuration.php');
extract($_REQUEST);

if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME);
site_log_generate("Pricing Plan Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
$current_date = date("Y-m-d H:i:s");
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Pricing Plan ::
    <?= $site_title ?>
  </title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/pricing_plans.css">
  <link rel="stylesheet" href="assets/css/components.css">
</head>

<body translate="no">
  <div id="app">
    <div class="main-wrapper main-wrapper-1">
      <div class="navbar-bg"></div>

      <? include("libraries/site_header.php"); ?>

      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <!-- Section Header Start -->
          <div class="section-header">
            <h1>Pricing Plan</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Pricing Plan</div>
            </div>
          </div>
          <!-- Section Header End -->

          <!-- Section Body Start -->
          <form class="needs-validation" novalidate="" id="plan_purchase_frm" name="plan_purchase_frm" action="#"
            method="post" enctype="multipart/form-data">

            <div class="section-body price-sec">
              <div class="slideToggle">
                <label class="form-switch">
                  <span class="beforeinput text-success"> MONTHLY </span>
                  <input type="checkbox" id="js-contcheckbox" />
                  <i></i>
                  <span class="afterinput"> ANNUALLY </span>
                </label>
              </div>

              <div class="row">
                <?php
                $curl = curl_init();
                curl_setopt_array(
                  $curl,
                  array(
                    CURLOPT_URL => $api_url . '/plan/plan_details',
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
                $response = curl_exec($curl);
                curl_close($curl);
                $array_plan_master_id = array();
                $array_plan_expiry_date = array();

                $plan = json_decode($response, false);
                if ($plan->response_status == 200) {
                  for ($indicator = 0; $indicator < count($plan->plan_details); $indicator++) {
                    $plan_title = $plan->plan_details[$indicator]->plan_title;
                    $annual_monthly = $plan->plan_details[$indicator]->annual_monthly;
                    $whatsapp_no_max_count = $plan->plan_details[$indicator]->whatsapp_no_max_count;
                    $group_no_max_count = $plan->plan_details[$indicator]->group_no_max_count;
                    $plan_price = $plan->plan_details[$indicator]->plan_price;
                    $message_limit = $plan->plan_details[$indicator]->message_limit;
                    $plan_master_id = $plan->plan_details[$indicator]->plan_master_id;
                    //______________________________________________________________
                    if (count($plan->plan_status) > 0) {
                      $current_plan = $plan->plan_status[0]->plan_master_id;
                      $plan_master_id_status = $plan->plan_status[$indicator + 1]->plan_master_id;
                      $Expiry_date = $plan->plan_status[$indicator]->plan_expiry_date;
                      $user_id = $plan->plan_status[$indicator]->user_id;

                      if (!empty($plan_master_id_status)) {
                        $array_plan_master_id[] = $plan_master_id_status;
                      }

                      if (!empty($Expiry_date)) {
                        $array_plan_expiry_date[] = $Expiry_date;
                      }
                      $expiry = $array_plan_expiry_date[0];
                      $dateTime = DateTime::createFromFormat("Y-m-d\TH:i:s.uP", $expiry);
                      // Subtract 7 days from the DateTime object
                      $sevenDaysBefore = $dateTime->modify('-7 days');
                      // Format the result as a string
                      $sevenDaysBeforeFormatted = $sevenDaysBefore->format('Y-m-d\TH:i:s.uP');
                      $sevenDaysBeforeDateTime = new DateTime($sevenDaysBeforeFormatted);
                      $currentDateTime = new DateTime($current_date);
                    }
                    ?>
                    <? if ($annual_monthly == 'Monthly') { ?>
                      <div class="col-sm-3 price-table js-montlypricing">
                        <div class="card text-center" style="height: 430px;">
                          <div class="title ">
                            <h2>
                              <?= strtoupper($plan_title) ?>
                            </h2>
                          </div>
                          <div class="pricingtable__highlight js-montlypricing price" style="margin-bottom:50px;">
                            <h2><sup>&#8377;</sup>
                              <?= $plan_price ?> / Month
                            </h2>
                          </div>
                          <div class="option js-montlypricing">
                            <ul>
                              <li><i class="fa fa-check "></i>
                                <?= $whatsapp_no_max_count ?> Whatsapp Count
                              </li>
                              <li><i class="fa fa-check "></i>
                                <?= $group_no_max_count ?> Group Count
                              </li>
                              <li><i class="fa fa-check "></i>
                                <?= $message_limit ?> Message Limit
                              </li>
                            </ul>
                          </div>
                          <input type="hidden" class="form-control" name='validity_period[]'
                            id="validity_period_<?= $indicator ?>" value='MONTH' />
                          <input type="hidden" class="form-control" name='price_plan_amount[]'
                            id="price_plan_amount_<?= $indicator ?>" value='<?= $plan_price ?>' />
                          <input type="hidden" class="form-control" name='plan_master_id[]' value='<?= $plan_master_id ?>'
                            id="plan_master_id_<?= $indicator ?>" />
                          <?
                          if ($sevenDaysBeforeDateTime < $currentDateTime && $current_plan == $plan_master_id) { ?>
                            <a href="#!" class="submit" name="submit" id="submit_<?= $indicator ?>" tabindex="3"
                              data-indicator="<?= $indicator ?>" style="background-color: red !important;">Renew</a>
                          <? } else if (in_array($plan_master_id, $array_plan_master_id)) { ?>
                              <a href="#!" class="btn btn-outline-light btn-disabled disabled"
                                style="background-color: #f15252 !important;padding: 0.3rem 0.41rem !important;cursor: not-allowed;width: 250px;height: 50px;text-align: center;border-radius: 10px !important;"
                                name="submit" id="submit_<?= $indicator ?>" tabindex="3" data-indicator="<?= $indicator ?>">This Plan Already Purchased</a>
                          <? } else if ($current_plan == $plan_master_id) { ?>
                                <a href="#!" class="submit" name="submit" id="submit_<?= $indicator ?>" tabindex="3"
                                  data-indicator="<?= $indicator ?>"  style="background-color: #00ce6c !important;">Active Plan</a>
                          <? }else if ($current_plan > $plan_master_id) { ?>
                            <a href="#!" class="btn btn-outline-light btn-disabled disabled"
                                style="background-color: #f15252 !important;padding: 0.3rem 0.41rem !important;cursor: not-allowed !important;width: 250px;height: 50px;text-align: center;border-radius: 10px !important;" name="submit" id="submit_<?= $indicator ?>" tabindex="3" data-indicator="<?= $indicator ?>">Not A Upgrade Plan</a>
                          <? } else if (count($plan->plan_status) == 0) { ?>
                                  <a href="#!" class="submit" name="submit" id="submit_<?= $indicator ?>" tabindex="3"
                                    data-indicator="<?= $indicator ?>">Purchase Now</a>
                          <? } else if ( !in_array($plan_master_id, $array_plan_master_id)) { ?>
                                    <a href="#!" class="submit" name="submit" id="submit_<?= $indicator ?>" tabindex="3"
                                      data-indicator="<?= $indicator ?>" style="background-color: #047e3f !important;">Upgrade</a>
                          <? } ?>
                        </div>
                      </div>
                    <? }
                    if ($annual_monthly == 'Annually') { ?>
                      <div class="col-sm-3 price-table js-yearlypricing" style="display: none;margin-bottom:50px;">
                        <div class="card text-center" style="height: 430px;">
                          <div class="title">
                            <h2>
                              <?= strtoupper($plan_title) ?>
                            </h2>
                          </div>
                          <div class="pricingtable__highlight js-yearlypricing price"
                            style="margin-bottom: 50px; display: none;">
                            <h2 class="js-yearlypricing " style="display: none;"><sup>&#8377;</sup>
                              <?= $plan_price ?> / Yearly
                            </h2>
                          </div>
                          <div class="option js-yearlypricing" style="display: none;">
                            <ul>
                              <li><i class="fa fa-check"></i>
                                <?= $whatsapp_no_max_count ?> Whatsapp Count
                              </li>
                              <li><i class="fa fa-check "></i>
                                <?= $group_no_max_count ?> Group Count
                              </li>
                              <li><i class="fa fa-check "></i>
                                <?= $message_limit ?> Message Limit
                              </li>
                            </ul>
                          </div>
                          <input type="hidden" class="form-control" name='validity_period[]'
                            id="validity_period_<?= $indicator ?>" value='YEAR' />
                          <input type="hidden" class="form-control" name='price_plan_amount[]'
                            id="price_plan_amount_<?= $indicator ?>" value='<?= $plan_price ?>' />
                          <input type="hidden" class="form-control" name='plan_master_id[]' value='<?= $plan_master_id ?>'
                            id="plan_master_id_<?= $indicator ?>" />
                          <? if ($sevenDaysBeforeDateTime < $currentDateTime && $current_plan == $plan_master_id) { ?>
                            <a href="#!" class="submit" name="submit" id="submit_<?= $indicator ?>" tabindex="3"
                              data-indicator="<?= $indicator ?>" style="background-color: red !important;">Renew</a>
                          <? } else if (in_array($plan_master_id, $array_plan_master_id)) { ?>
                              <a href="#!" class="btn btn-outline-light btn-disabled disabled"
                                style="background-color: #f15252 !important;padding: 0.3rem 0.41rem !important;cursor: not-allowed;width: 250px;height: 50px;text-align: center;border-radius: 10px !important; "
                                name="submit" id="submit_<?= $indicator ?>" tabindex="3" data-indicator="<?= $indicator ?>">This Plan Already Purchased</a>
                          <? } else if ($current_plan == $plan_master_id) { ?>
                                <a href="#!" class="submit" name="submit" id="submit_<?= $indicator ?>" tabindex="3"
                                  data-indicator="<?= $indicator ?>" style="background-color: #00ce6c !important;">Active Plan</a>
                          <? } else if ($current_plan > $plan_master_id) { ?>
                            <a href="#!" class="btn btn-outline-light btn-disabled disabled"
                                style="background-color: #f15252 !important;padding: 0.3rem 0.41rem !important;cursor: not-allowed !important;width: 250px;height: 50px;text-align: center;border-radius: 10px !important;" name="submit" id="submit_<?= $indicator ?>" tabindex="3" data-indicator="<?= $indicator ?>">Not A Upgrade Plan</a>
                          <? } else if (count($plan->plan_status) == 0) { ?>
                                  <a href="#!" class="submit" name="submit" id="submit_<?= $indicator ?>" tabindex="3"
                                    data-indicator="<?= $indicator ?>">Purchase Now</a>
                          <? } else if (!in_array($plan_master_id, $array_plan_master_id)) { ?>
                                    <a href="#!" class="submit" name="submit" id="submit_<?= $indicator ?>" tabindex="3"
                                      data-indicator="<?= $indicator ?>" style="background-color: #047e3f !important;">Upgrade</a>
                          <? } ?>
                        </div>
                      </div>
                    <? }
                  }
                }
                site_log_generate("Pricing_plan_details Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
                ?>

          </form>
      </div>
      </section>
      <div style="text-align: center;margin-top:100px;"> <span class="error_display" id='id_error_display'></span></div>

    </div>

  </div>

  </div>
  </div>

  <!-- Confirmation details content-->
  <div class="modal" tabindex="-1" role="dialog" id="default-Modal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title text-center center-div">Plan details</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body" style="height: 50px;">
          <p class="id_error_display " style="font-size:20px;"></p>
        </div>
        <div class="modal-footer">
        </div>
      </div>
    </div>
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
  <!-- Page Specific JS File -->
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <!-- Template JS File -->
  <script src="assets/js/scripts.js"></script>
  <script src="assets/js/custom.js"></script>

  <script id="rendered-js">

    $("#js-contcheckbox").change(function () {
      if (this.checked) {
        $(".js-montlypricing").css("display", "none");
        $(".js-yearlypricing").css("display", "block");
        $(".afterinput").addClass("text-success");
        $(".beforeinput").removeClass("text-success");
      } else {
        $(".js-montlypricing").css("display", "block");
        $(".js-yearlypricing").css("display", "none");
        $(".afterinput").removeClass("text-success");
        $(".beforeinput").addClass("text-success");
      }
    });

    document.body.addEventListener("click", function (evt) {
      //note evt.target can be a nested element, not the body element, resulting in misfires
      $(".id_error_display").html("");
    });

    $(".submit").click(function (e) {
      var price_plan_amount;
      var plan_master_id;
      var validity_period;
      var click_id = $(this).attr('id');

      // Find the corresponding pricing data for the clicked button
      var split_id = click_id.split("_");
      price_plan_amount = $("#price_plan_amount_" + split_id[1]).val();
      plan_master_id = $("#plan_master_id_" + split_id[1]).val();
      validity_period = $("#validity_period_" + split_id[1]).val();
      var data_serialize = {
        "validity_period": validity_period,
        "plan_master_id": plan_master_id,
        "price_plan_amount": price_plan_amount
      }
      var flag = true;
      /* If all are ok then we send ajax request to ajax/master_call_functions.php *******/
      if (flag) {
        $.ajax({
          type: 'post',
          url: "ajax/message_call_functions.php?tmpl_call_function=purchase_sms_credit",
          dataType: 'json',
          data: data_serialize,
          async: true,
          beforeSend: function () {
            $('.submit').attr('disabled', true);
            $('#load_page').show();
          },
          complete: function () {
            $('.submit').attr('disabled', false);
            $('#load_page').hide();
          },
          success: function (response) {
            if (response.status == '0') {
              $('.submit').attr('disabled', false);
              $('#default-Modal').modal({ show: true });
              $(".id_error_display").html(response.msg);
            } else if (response.status == 1) {
              $('.submit').attr('disabled', false);
              $('#default-Modal').modal({ show: true });
              $(".id_error_display").html("Payment Processing..");
              var getAmount = price_plan_amount;
              var product_id = plan_master_id;
              var useremail = "<?= $_SESSION['yjwatsp_user_email'] ?>";
              var totalAmount = getAmount * 100;
              $('#default-Modal').modal({ show: false });
              var options = {
                "key": "<?= $rp_keyid ?>", // your Razorpay Key Id
                "amount": totalAmount,
                "name": "<?= $_SESSION['yjwatsp_user_name'] ?>",
                "description": "Purchase Pricing Plans",
                "image": "https://www.codefixup.com/wp-content/uploads/2016/03/logo.png",
                "handler": function (response) {
                  $.ajax({
                    url: 'ajax/rppayment_call_functions.php?action_process=razorpay_payment',
                    type: 'post',
                    dataType: 'json',
                    data: {
                      razorpay_payment_id: response.razorpay_payment_id, totalAmount: totalAmount, product_id: product_id, useremail: useremail,
                    },
                    success: function (data) {
                      window.location = "user_plans_list";
                    },
                    error: function (response, status, error) {
                      window.location = "pricing_plan";
                    }
                  });
                },
                "theme": {
                  "color": "#528FF0"
                }
              };
              var rzp1 = new Razorpay(options);
              rzp1.open();
              e.preventDefault();
            }
            $('#load_page').hide();
            $("#result").hide().html(output).slideDown();
          },
          error: function (response, status, error) {
            $('.submit').attr('disabled', false);
            $('#default-Modal').modal({ show: true });
            $(".id_error_display").html(response.msg);
          }
        });
      }
    })

  </script>
</body>

</html>