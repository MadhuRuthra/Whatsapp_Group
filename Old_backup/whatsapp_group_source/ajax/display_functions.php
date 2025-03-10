
<?php
session_start();
error_reporting(E_ALL);
// Include configuration.php
include_once('../api/configuration.php');
extract($_REQUEST);

$current_date = date("Y-m-d H:i:s");

// manage_whatsappno_list Page manage_whatsappno_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "manage_whatsappno_list") {
  site_log_generate("Manage Whatsappno List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
  ?>
    <table class="table table-striped text-center" id="table-1">
      <thead>
        <tr class="text-center">
          <th>#</th>
          <th>User</th>
          <th>Mobile No</th>
          <th>Status</th>
          <th>Entry Date</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
      <?
      $bearer_token = 'Authorization: '.$_SESSION['yjwatsp_bearer_token'].''; 
      $replace_txt = '';
      $curl = curl_init();
      curl_setopt_array($curl, array(
        CURLOPT_URL => $api_url . '/sender_id/sender_id_list',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_SSL_VERIFYPEER => 0,
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_HTTPHEADER => array(
          $bearer_token,
          'Content-Type: application/json'
        ),
      )
      );
      site_log_generate("Manage Whatsappno List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
      $response = curl_exec($curl);
      curl_close($curl);
      $sms = json_decode($response, false);
      site_log_generate("Manage Whatsappno List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

      if ($sms->response_status == 403) { ?>
        <script>window.location="logout"</script>
      <? } 

      // print_r($sms); exit;
      $indicatori = 0;
      if ($sms->response_status == 200) {
        for ($indicator = 0; $indicator < count($sms->sender_id); $indicator++) {
          $indicatori++;
          $entry_date = date('d-m-Y h:i:s A', strtotime($sms->sender_id[$indicator]->whatspp_config_entdate));
          ?>
          <tr>
            <td><?= $indicatori ?></td>
            <td><?= strtoupper($sms->sender_id[$indicator]->user_name) ?></td>
            <td><?= $sms->sender_id[$indicator]->country_code . $sms->sender_id[$indicator]->mobile_no ?></td>
            <td>
              <? if ($sms->sender_id[$indicator]->whatspp_config_status == 'Y') { ?><a href="#!" class="btn btn-outline-success btn-disabled">Active</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'D') { ?><a href="#!" class="btn btn-outline-danger btn-disabled">Deleted</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'B') { ?><a href="#!" class="btn btn-outline-dark btn-disabled">Blocked</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'N') { ?><a href="#!" class="btn btn-outline-danger btn-disabled">Inactive</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'M') { ?><a href="#!" class="btn btn-outline-danger btn-disabled">Mobile No Mismatch</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'I') { ?><a href="#!" class="btn btn-outline-warning btn-disabled">Invalid</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'P') { ?><a href="#!" class="btn btn-outline-info btn-disabled">Processing</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'R') { ?><a href="#!" class="btn btn-outline-danger btn-disabled">Rejected</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'X') { ?><a href="#!" class="btn btn-outline-primary btn-disabled">Need Rescan</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'L') { ?><a href="#!" class="btn btn-outline-info btn-disabled">Linked</a><? } elseif ($sms->sender_id[$indicator]->whatspp_config_status == 'U') { ?><a href="#!" class="btn btn-outline-warning btn-disabled">Unlinked</a><? } ?>
            </td>
            <td><?= $entry_date ?></td>
            <td id='id_approved_lineno_<?= $indicatori ?>'>
              <? if ($sms->sender_id[$indicator]->whatspp_config_status == 'D' or $sms->sender_id[$indicator]->whatspp_config_status == 'N' or $sms->sender_id[$indicator]->whatspp_config_status == 'M' or $sms->sender_id[$indicator]->whatspp_config_status == 'I' or $sms->sender_id[$indicator]->whatspp_config_status == 'X') { ?>
                  <a href="add_senderid?mob=<?= $sms->sender_id[$indicator]->mobile_no ?>" class="btn btn-success">Scan</a>
              <? } else { ?>
                  <a href="#!" class="btn btn-outline-light btn-disabled" style="cursor: not-allowed;">Scan</a>
              <? } ?>
              <? if ($sms->sender_id[$indicator]->whatspp_config_status != 'D') { ?>
                  <button type="button" title="Delete Sender ID" onclick="remove_senderid('<?= $sms->sender_id[$indicator]->whatspp_config_id ?>', 'D', '<?= $indicatori ?>')" class="btn btn-icon btn-danger" style="padding: 0.3rem 0.41rem !important;">Delete</button>
              <? } else { ?>
                  <a href="#!" class="btn btn-outline-light btn-disabled" style="padding: 0.3rem 0.41rem !important;cursor: not-allowed;">Delete</a>
              <? } ?>
            </td>
          </tr>
        <?
        }
      }
      ?>
      </tbody>
    </table>

    <script src="assets/js/jquery.dataTables.min.js"></script>
    <script src="assets/js/dataTables.buttons.min.js"></script>
    <script src="assets/js/dataTables.searchPanes.min.js"></script>
    <script src="assets/js/dataTables.select.min.js"></script>
    <script src="assets/js/jszip.min.js"></script>
    <script src="assets/js/pdfmake.min.js"></script>
    <script src="assets/js/vfs_fonts.js"></script>
    <script src="assets/js/buttons.html5.min.js"></script>
    <script src="assets/js/buttons.colVis.min.js"></script>

    <script>
    $('#table-1').DataTable( {
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
    } );
    </script>
  <?
}
// manage_whatsappno_list Page manage_whatsappno_list - End

// manage_group_list Page manage_group_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "manage_group_list") {
  site_log_generate("Group List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
  ?>
    <table class="table table-striped text-center" id="table-1">
      <thead>
        <tr class="text-center">
          <th>#</th>
          <th>User</th>
          <th>Sender ID</th>
          <th>Group Name</th>
          <th>Total Mobile Numbers</th>
          <th>Success Mobile Numbers</th>
          <th>Failure Mobile Numbers</th>
          <th>Status</th>
          <th>Entry Date</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
      <?
      $bearer_token = 'Authorization: '.$_SESSION['yjwatsp_bearer_token'].''; 
      $replace_txt = '';
      $curl = curl_init();
      curl_setopt_array($curl, array(
        CURLOPT_URL => $api_url . '/list/group_list',
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
      site_log_generate("Group List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
      $response = curl_exec($curl);
      curl_close($curl);

      $sms = json_decode($response, false);
      site_log_generate("Group List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

      if ($sms->response_status == 403) { ?>
        <script>window.location="logout"</script>
      <? } 

      // print_r($sms); exit;
      $indicatori = 0;
      if ($sms->response_status == 200) {
        for ($indicator = 0; $indicator < count($sms->group_list); $indicator++) {
          $indicatori++;
          $entry_date = date('d-m-Y h:i:s A', strtotime($sms->group_list[$indicator]->group_contact_entdate));
          ?>
          <tr>
            <td><?= $indicatori ?></td>
            <td><?= strtoupper($sms->group_list[$indicator]->user_name) ?></td>
            <td><?= $sms->group_list[$indicator]->mobile_no ?></td>
            <td><?= $sms->group_list[$indicator]->group_name ?></td>
            <td><?= $sms->group_list[$indicator]->total_count ?></td>
            <td><?= $sms->group_list[$indicator]->success_count ?></td>
            <td><?= $sms->group_list[$indicator]->failure_count ?></td>
            <td>
              <? if ($sms->group_list[$indicator]->group_contact_status == 'Y') { ?><a href="#!" class="btn btn-outline-success btn-disabled">Active</a><? } 
                 elseif ($sms->group_list[$indicator]->group_contact_status == 'N') { ?><a href="#!" class="btn btn-outline-danger btn-disabled">Inactive</a><? } ?>
            </td>
            <td><?= $entry_date ?></td>
            <td><a href="add_contact_group?group=<?=$sms->group_list[$indicator]->group_contact_id?>&sender=<?=$sms->group_list[$indicator]->mobile_no?>" class="btn btn-primary"><i class="fas fa-edit"></i> Update Contacts</a></td>
          </tr>
        <?
        }
      }
      ?>
      </tbody>
    </table>

    <script src="assets/js/jquery.dataTables.min.js"></script>
    <script src="assets/js/dataTables.buttons.min.js"></script>
    <script src="assets/js/dataTables.searchPanes.min.js"></script>
    <script src="assets/js/dataTables.select.min.js"></script>
    <script src="assets/js/jszip.min.js"></script>
    <script src="assets/js/pdfmake.min.js"></script>
    <script src="assets/js/vfs_fonts.js"></script>
    <script src="assets/js/buttons.html5.min.js"></script>
    <script src="assets/js/buttons.colVis.min.js"></script>

    <script>
    $('#table-1').DataTable( {
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
    } );
    </script>
  <?
}
// manage_group_list Page manage_group_list - End

// campaign_report Page campaign_report - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "campaign_report") {
  site_log_generate("Campaign Report Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
  ?>
    <table class="table table-striped text-center" id="table-1">
      <thead>
        <tr class="text-center">
          <th>#</th>
          <th>User</th>
          <th>Sender ID</th>
          <th>Group Name</th>
          <th>Campaign Name</th>
          <th>Total Contacts</th>
          <th>Success Contacts</th>
          <th>Failure Contacts</th>
          <th>Entry Date</th>
        </tr>
      </thead>
      <tbody>
      <?
      $bearer_token = 'Authorization: '.$_SESSION['yjwatsp_bearer_token'].''; 
      $replace_txt = '';
      $curl = curl_init();
      curl_setopt_array($curl, array(
        CURLOPT_URL => $api_url . '/report/campaign_report',
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
      site_log_generate("Campaign Report Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
      $response = curl_exec($curl);
      curl_close($curl);

      $sms = json_decode($response, false);
      site_log_generate("Campaign Report Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

      if ($sms->response_status == 403) { ?>
        <script>window.location="logout"</script>
      <? } 

      // print_r($sms); exit;
      $indicatori = 0;
      if ($sms->response_status == 200) {
        for ($indicator = 0; $indicator < count($sms->report); $indicator++) {
          $indicatori++;
          $entry_date = date('d-m-Y h:i:s A', strtotime($sms->report[$indicator]->contact_mobile_entry_date));
          ?>
          <tr>
            <td><?= $indicatori ?></td>
            <td><?= strtoupper($sms->report[$indicator]->user_name) ?></td>
            <td><?= $sms->report[$indicator]->mobile_no ?></td>
            <td><?= $sms->report[$indicator]->group_name ?></td>
            <td><?= $sms->report[$indicator]->campaign_name ?></td>
            <td><?= $sms->report[$indicator]->total_contacts ?></td>
            <td><?= $sms->report[$indicator]->total_success ?></td>
            <td><?= $sms->report[$indicator]->total_failure ?></td>
            <td><?= $entry_date ?></td>
          </tr>
        <?
        }
      }
      ?>
      </tbody>
    </table>

    <script src="assets/js/jquery.dataTables.min.js"></script>
    <script src="assets/js/dataTables.buttons.min.js"></script>
    <script src="assets/js/dataTables.searchPanes.min.js"></script>
    <script src="assets/js/dataTables.select.min.js"></script>
    <script src="assets/js/jszip.min.js"></script>
    <script src="assets/js/pdfmake.min.js"></script>
    <script src="assets/js/vfs_fonts.js"></script>
    <script src="assets/js/buttons.html5.min.js"></script>
    <script src="assets/js/buttons.colVis.min.js"></script>

    <script>
    $('#table-1').DataTable( {
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
    } );
    </script>
  <?
}
// campaign_report Page campaign_report - End

// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with HTML Response
header('Content-type: text/html');
echo $result_value;
