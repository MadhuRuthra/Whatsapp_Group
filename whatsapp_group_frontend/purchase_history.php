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
site_log_generate("Payment History List Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Payment History List ::
    <?= $site_title ?>
  </title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <link rel="stylesheet" href="assets/css/jquery.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/searchPanes.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/select.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/colReorder.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/buttons.dataTables.min.css">

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">
 <link rel="stylesheet" href="assets/css/loader.css">
</head>

<style>
  #id_whatsapp_list {
    height: 600px;
  }

  .dataTables_filter label,
  .previous,
  .next {
    font-weight: bolder;
  }
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
            <h1>Payment History List</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="compose_whatsapp">Compose Whatsapp</a></div>
              <div class="breadcrumb-item">Payment History List</div>
            </div>
          </div>

          <!-- <div class="row">
            <div class="col-12">
              <h4 class="text-right"><a href="compose_whatsapp" class="btn btn-success"><i class="fas fa-plus"></i>
                  Compose Whatsapp</a></h4>
            </div>
          </div> -->

          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <div class="table-responsive" id="id_whatsapp_list">
                      Loading ..
                    </div>
                  </div>
                </div>
              </div>
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

  <script src="assets/js/jquery.dataTables.min.js"></script>
  <script src="assets/js/dataTables.buttons.min.js"></script>
  <script src="assets/js/dataTables.searchPanes.min.js"></script>
  <script src="assets/js/dataTables.select.min.js"></script>
  <script src="assets/js/jszip.min.js"></script>
  <script src="assets/js/pdfmake.min.js"></script>
  <script src="assets/js/vfs_fonts.js"></script>
  <script src="assets/js/buttons.html5.min.js"></script>
  <script src="assets/js/buttons.colVis.min.js"></script>

  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <script>
    $(document).ready(function () {
      whatsapp_list();
    });

    function whatsapp_list() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=payment_history_list",
        dataType: 'html',
        success: function (response) {
          $("#id_whatsapp_list").html(response);
        },
        error: function (response, status, error) { }
      });
    }
    setInterval(whatsapp_list, 60000); // Every 1 min (60000), it will call


 function add_payment_status(user_name,plan_master_id,plan_amount,user_email,indicatori){
  var getAmount = plan_amount;
              var product_id = plan_master_id ;
              var useremail =  user_email;
              
              var totalAmount = getAmount * 100;
              var options = {
                "key": "<?= $rp_keyid ?>", // your Razorpay Key Id
                "amount": totalAmount,
                "name": user_name,
                "description": "Add Pricing Plans",
                "image": "https://www.codefixup.com/wp-content/uploads/2016/03/logo.png",
                "handler": function (response){
                  $.ajax({
                    url: 'ajax/rppayment_call_functions.php?action_process=razorpay_payment',
                    type: 'post',
                    dataType: 'json',
                    data: {
                      razorpay_payment_id: response.razorpay_payment_id, totalAmount : totalAmount, product_id : product_id, useremail : useremail,
                    }, 
                    success: function (data) 
                    
                    {
                      // exit;
                      // alert(data.msg);
                      // window.location = 'ajax/rppayment_call_functions.php?action_process=razorpay_payment&status=success&productCode='+ data.productCode +'&payId='+ data.paymentID +'&userEmail='+ data.userEmail +'';
                      window.location = "purchase_history";
                    },
                    error: function(response, status, error) 
                    {
                      // fail();
                      // alert("Failed");
                      // window.location = 'ajax/rppayment_call_functions.php?action_process=razorpay_payment&status=failed&productCode='+ data.productCode +'&payId='+ data.paymentID +'&userEmail='+ data.userEmail +'';
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

    $('#table-1').DataTable({
      dom: 'Bfrtip',
      colReorder: true,
      buttons: [{
        extend: 'copyHtml5',
        exportOptions: {
          columns: [0, ':visible']
        }
      }, {
        extend: 'csvHtml5',
        exportOptions: {
          columns: ':visible'
        }
      }, {
        extend: 'pdfHtml5',
        exportOptions: {
          columns: ':visible'
        }
      }, {
        extend: 'searchPanes',
        config: {
          cascadePanes: true
        }
      }, 'colvis'],
      columnDefs: [{
        searchPanes: {
          show: false
        },
        targets: [0]
      }]
    });
  </script>
</body>

</html>
