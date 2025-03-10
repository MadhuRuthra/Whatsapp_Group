<?php
session_start();
error_reporting(0);
include_once 'api/configuration.php';
extract($_REQUEST);

if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME);
site_log_generate("Summary Report Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <!-- <meta http-equiv="refresh" content="60"> -->
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Summary Report :: <?= $site_title ?></title>
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

  <!--Date picker -->
  <script type="text/javascript" src="assets/js/daterangepicker.min.js" defer></script>
  <link rel="stylesheet" type="text/css" href="assets/css/daterangepicker.css" />

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">
  <style>
    element.style {}

    .custom-file,
    .custom-file-label,
    .custom-select,
    .custom-file-label:after,
    .form-control[type="color"],
    select.form-control:not([size]):not([multiple]) {
      height: calc(2.25rem + 6px);
    }

    .input-group-text,
    select.form-control:not([size]):not([multiple]),
    .form-control:not(.form-control-sm):not(.form-control-lg) {
      Loading… ￼ font-size: 14px;
      padding: 5px 15px;
    }

    .search {
      width: 200px;
      margin-right: 50px;
    }
  </style>
</head>

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
            <h1>Summary Report</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Summary Report</div>
            </div>
          </div>

          <div class="section-body">
            <div class="row">
              <div class="col-12">

                <div class="card">
                  <div class="card-body">
                  <form method="post">
                      <div id="table-1_filter" class="dataTables_filter">
                        <label>User :
                          <select style="height:30px;border: 1px solid #ced4da; border-radius:0.2rem;" id="srch1"
                            name="srch1" class="search">
                            <option value="">Choose User</option>
                            <?
                            $replace_txt = '{
                              "api_key" : "' . $_SESSION['yjwatsp_api_key'] . '",
                              "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
                            }';
                            $curl = curl_init();
                            curl_setopt_array($curl, array(
                              CURLOPT_URL => $api_url . '/report/report_filter_user',
                              CURLOPT_RETURNTRANSFER => true,
                              CURLOPT_ENCODING => '',
                              CURLOPT_MAXREDIRS => 10,
                              CURLOPT_TIMEOUT => 0,
                              CURLOPT_FOLLOWLOCATION => true,
                              CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                              CURLOPT_SSL_VERIFYPEER => 0,
                              CURLOPT_CUSTOMREQUEST => 'POST',
                              CURLOPT_POSTFIELDS => $replace_txt,
                              CURLOPT_HTTPHEADER => array(
                                'Content-Type: application/json'
                              ),
                            )
                            );
                            site_log_generate("Summary Report Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
                            $response = curl_exec($curl);
                            curl_close($curl);

                            $header = json_decode($response, false);
                            site_log_generate("Summary Report Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

                            if ($header->num_of_rows > 0) {
                              for ($indicator = 0; $indicator < $header->num_of_rows; $indicator++) {
                                $user_id = $header->report[$indicator]->user_id;
                                $user_name = $header->report[$indicator]->user_name;
                                ?>
                                <option value="<?= $user_id ?>" <? if ($_REQUEST['srch1'] == $user_id) { ?> selected <? } ?>>
                                  <?= $user_name ?></option>
                              <? }
                            } ?>
                          </select></label>

                        <? if ($_SESSION['yjwatsp_user_master_id'] != 3) { ?>
                          <label>Department :
                            <select style="height:30px;border: 1px solid #ced4da;border-radius:0.2rem; " name="srch_1"
                              id='srch_1' class="search">
                              <option value="">Choose Department</option>
                              <?
                              $replace_txt = '{
                              "api_key" : "' . $_SESSION['yjwatsp_api_key'] . '",
                              "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
                            }';
                              $curl = curl_init();
                              curl_setopt_array($curl, array(
                                CURLOPT_URL => $api_url . '/report/report_filter_department',
                                CURLOPT_RETURNTRANSFER => true,
                                CURLOPT_ENCODING => '',
                                CURLOPT_MAXREDIRS => 10,
                                CURLOPT_TIMEOUT => 0,
                                CURLOPT_FOLLOWLOCATION => true,
                                CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                                CURLOPT_SSL_VERIFYPEER => 0,
                                CURLOPT_CUSTOMREQUEST => 'POST',
                                CURLOPT_POSTFIELDS => $replace_txt,
                                CURLOPT_HTTPHEADER => array(
                                  'Content-Type: application/json'
                                ),
                              )
                              );
                              site_log_generate("Summary Report Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
                              $response = curl_exec($curl);
                              curl_close($curl);

                              $header = json_decode($response, false);
                              site_log_generate("Summary Report Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

                              if ($header->num_of_rows > 0) {
                                for ($indicator = 0; $indicator < $header->num_of_rows; $indicator++) {
                                  $user_master_id = $header->report[$indicator]->user_master_id;
                                  $user_type = $header->report[$indicator]->user_type;
                                  ?>
                                  <option value="<?= $user_master_id ?>" <? if ($_REQUEST['srch_1'] == $user_master_id) { ?>
                                      selected <? } ?>><?= $user_type ?></option>
                                <? }
                              } ?>
                            </select></label>
                        <? } ?>

                        <label>Date :<input type="search" name="dates" id="dates" value="<?= $_REQUEST['dates'] ?>"
                            class="form-control form-control-sm search_1" placeholder=""
                            aria-controls="table-1" /></label>
                        <input type="submit" name="submit_1" id="submit_1" tabindex="10" value="Search"
                          class="btn btn-success " style="height:30px;">

                      </div>

                    </form><br></br>
                    
                    <div class="table-responsive">
                      <table class="table table-striped" id="table-1">
                        <thead>
                          <tr>
                            <th>#</th>
                            <th>Date</th>
                            <th>User</th>
                            <th>Department</th>
                            <th>Credits</th>
                            <th>Total Pushed</th>
                            <th>Success</th>
                            <th>Failed</th>
                            <th>In processing</th>
                          </tr>
                        </thead>
                        <tbody>
                          <?
                          $srch1 = $_POST['srch1'];
                          $srch_1 = $_POST['srch_1'];
                          if ($_POST['dates']) {
                            $date = $_POST['dates'];
                          } else {
                            $date = date('m/d/Y') . "-" . date('m/d/Y'); // 01/28/2023 - 02/27/2023 
                          }

                          $td = explode('-', $date);
                          $thismonth_startdate = date("Y-m-d", strtotime($td[0]));
                          $thismonth_today = date("Y-m-d", strtotime($td[1]));

                          function date_range($first, $last, $step = '+1 day', $output_format = 'Y-m-d')
                          {

                            $dates = array();
                            $current = strtotime($first);
                            $last = strtotime($last);
                            while ($current <= $last) {
                              $dates[] = date($output_format, $current);
                              $current = strtotime($step, $current);
                            }
                            return $dates;
                          }
                          $date = date_range($thismonth_startdate, $thismonth_today);

                          $and = '';
                          if ($srch1) {
                            $and .= " and user_id = '" . $srch1 . "'";
                          }
                          if ($srch_1) {
                            $and .= " and user_master_id = '" . $srch_1 . "'";
                          }

                          $prntid = '';
                          if ($_SESSION['yjwatsp_user_master_id'] == 1 or $_SESSION['yjwatsp_user_master_id'] == 2) {
                            $sql1 = "SELECT user_id FROM user_management 
                                          where parent_id = '" . $_SESSION['yjwatsp_user_id'] . "' 
                                          ORDER BY user_id ASC";
                            $qur1 = $conn->query($sql1);
                            site_log_generate("Summary Report Page : " . $uname . " executed the query ($sql1) on " . date("Y-m-d H:i:s"), '../');
                            if ($qur1->num_rows > 0) {
                              while ($row1 = $qur1->fetch_assoc()) {
                                $prntid .= ", " . $row1["user_id"];
                              }
                            }
                            $prntid = rtrim($prntid, ", ");
                          }

                          $sql_dashboard1 = "SELECT user_id FROM user_management
                                              where (user_id = '" . $_SESSION['yjwatsp_user_id'] . "' or 
                                                parent_id in (" . $_SESSION['yjwatsp_user_id'] . " " . $prntid . ")) $and";

                          $qur_dashboard1 = $conn->query($sql_dashboard1);

                          $dashboard_user = '';
                          $sql_sntsms = '';
                          if ($qur_dashboard1->num_rows > 0) {
                            while ($row_dashboard1 = $qur_dashboard1->fetch_assoc()) {
                              $list_user_id = $row_dashboard1["user_id"];
                              for ($ij = 0; $ij < count($date); $ij++) {
                                $this_date = date("Y-m-d", strtotime($date[$ij]));

                                $newdb = "whatsapp_messenger_" . $list_user_id;
                                $sql_sntsms .= 'SELECT wht.user_id, usr.user_name,ussr.user_type,ussr.user_type,ml.available_messages, date(wht.whatsapp_entry_date) entry_date, count(stt.comwtap_status_id) total_msg, (select count(distinct comwtap_status_id) from ' . $newdb . '.compose_whatsapp_status_' . $list_user_id . ' where (date(comwtap_entry_date) BETWEEN \'' . $this_date . '\' AND \'' . $this_date . '\') and response_status = \'S\') total_success, (select count(distinct comwtap_status_id) from ' . $newdb . '.compose_whatsapp_status_' . $list_user_id . ' where (date(comwtap_entry_date) BETWEEN \'' . $this_date . '\' AND \'' . $this_date . '\') and response_status = \'F\') total_failed, (select count(distinct comwtap_status_id) from ' . $newdb . '.compose_whatsapp_status_' . $list_user_id . ' where (date(comwtap_entry_date) BETWEEN \'' . $this_date . '\' AND \'' . $this_date . '\') and response_status = \'I\') total_invalid, (select count(distinct comwtap_status_id) from ' . $newdb . '.compose_whatsapp_status_' . $list_user_id . ' where (date(comwtap_entry_date) BETWEEN \'' . $this_date . '\' AND \'' . $this_date . '\') and (response_status not in (\'I\', \'F\', \'S\') or response_status is null)) total_waiting FROM ' . $newdb . '.compose_whatsapp_' . $list_user_id . ' wht left join ' . $newdb . '.compose_whatsapp_status_' . $list_user_id . ' stt on wht.compose_whatsapp_id = stt.compose_whatsapp_id left join whatsapp_messenger.user_management usr on wht.user_id = usr.user_id left join whatsapp_messenger.message_limit ml on wht.user_id = ml.user_id left join whatsapp_messenger.user_master ussr on usr.user_master_id = ussr.user_master_id where usr.user_id = \'' . $list_user_id . '\' and (date(wht.whatsapp_entry_date) BETWEEN \'' . $this_date . '\' AND \'' . $this_date . '\')  UNION ';
                              }
                            }
                          }

                          $sql_sntsms = rtrim($sql_sntsms, " UNION ");
                          $sql_sntsms = $sql_sntsms . ' group by user_id, entry_date order by user_id, entry_date desc';


                          $qur_sntsms = $conn->query($sql_sntsms);
                          site_log_generate("Summary Report Page : User : " . $_SESSION['yjtsms_user_name'] . " executed the Query ($sql_sntsms) on " . date("Y-m-d H:i:s"));

                          $increment = 0;
                          if ($qur_sntsms->num_rows > 0) {
                            while ($row_sntsms = $qur_sntsms->fetch_assoc()) {
                              extract($row_sntsms);													
                              $entry_date = date('d-m-Y', strtotime($row_sntsms["entry_date"]));
                              $user_id = $row_sntsms["user_id"];
                              $user_name = $row_sntsms["user_name"];
                              $user_master_id = $row_sntsms["user_master_id"];
                              $user_type = $row_sntsms["user_type"];
                              $total_msg = $row_sntsms["total_msg"];
                              $credits = $row_sntsms["available_messages"];
                              $total_success = $row_sntsms["total_success"];
                              $total_failed = $row_sntsms["total_failed"];
                              $total_waiting = $row_sntsms["total_waiting"];
                              $total_invalid = $row_sntsms["total_invalid"];
                              if ($user_id != '') {
                                $increment++;
                                ?>
                                <tr style="text-align: center !important">
                                  <td>
                                    <?= $increment ?>
                                  </td>
                                  <td>
                                    <?= $entry_date ?>
                                  </td>
                                  <td>
                                    <?= $user_name ?>
                                  </td>
                                  <td>
                                    <?= $user_type ?>
                                  </td>
                                  <td>
                                    <?= $credits ?>
                                  </td>
                                  <td>
                                    <?= $total_msg ?>
                                  </td>
                                  <td>
                                    <?= $total_success ?>
                                  </td>
                                  <td>
                                    <?= $total_failed ?>
                                  </td>
                                  <td>
                                    <?= $total_waiting ?>
                                  </td>
                                </tr>
                                <?
                              }
                            }
                          }
                          ?>
                        </tbody>
                        <tfoot>
                          <tr>
                            <th>#</th>
                            <th>Date</th>
                            <th>User</th>
                            <th>Department</th>
                            <th>Credits</th>
                            <th>Total Pushed</th>
                            <th>Success</th>
                            <th>Failed</th>
                            <th>In processing</th>
                          </tr>
                        </tfoot>
                      </table>
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

  <script type="text/javascript">

    $(function () {

      var start = moment().subtract(30, 'days');
      var end = moment();

      function cb(start, end) {
        $('input[name="dates"]').html(start.format('MMMM D, YYYY') + ' - ' + end.format('MMMM D, YYYY'));
      }
      $('input[name="dates"]').daterangepicker({
        autoUpdateInput: true,
        startDate: start,
        endDate: end,
        locale: {
          cancelLabel: 'Clear'
        }
      });

      $('input[name="dates"]').on('apply.daterangepicker', function (ev, picker) {
        $(this).val(picker.startDate.format('MM/DD/YYYY') + ' - ' + picker.endDate.format('MM/DD/YYYY'));
        var first_date = picker.startDate.format('MM/DD/YYYY');
        var second = picker.endDate.format('MM/DD/YYYY');
      });

      $('input[name="dates"]').on('cancel.daterangepicker', function (ev, picker) {
        $(this).val('');
      });

    });

    $("#submit_1").click(function (e) {
      var date = $("#dates").val();
      var srch1 = $("#srch1").val();
    });

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
