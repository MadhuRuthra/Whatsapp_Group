<?php
/*
Authendicated users only allow to view this Create Template page.
This page is used to Create new Templates.
It will send the form to API service and check with the Whatsapp Facebook
and get the response from them and store into our DB.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 03-Jul-2023
*/

session_start(); // start session
error_reporting(0); // The error reporting function

include_once "api/configuration.php"; // Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION["yjwatsp_user_id"] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER["PHP_SELF"], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate(
  "Create Template Page : User : " .
  $_SESSION["yjwatsp_user_name"] .
  " access the page on " .
  date("Y-m-d H:i:s")
);
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Create Template ::
    <?= $site_title ?>
  </title>

  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">
  <!-- <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script> -->

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">

  <!-- CSS Libraries -->
  <!-- <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script> -->
  <!-- Multi Option was selected -->
  <script src="https://code.jquery.com/jquery-3.6.4.min.js"></script>
  <link href="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote-lite.min.css" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote-lite.min.js"></script>

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/custom.css">
  <link rel="stylesheet" href="assets/css/components.css">

  <!-- style include in css -->
  <style>
    textarea {
      resize: none;
    }

    .theme-loader {
      display: block;
      position: absolute;
      top: 0;
      left: 0;
      z-index: 100;
      width: 100%;
      height: 100%;
      background-color: rgba(192, 192, 192, 0.5);
      background-image: url("assets/img/loader.gif");
      background-repeat: no-repeat;
      background-position: center;
    }

    .custom-width {
      width: auto;
      /* Set the desired width */
    }

    .note-modal-backdrop {
      display: none !important;
    }
  </style>
</head>

<body>
  <div class="theme-loader"></div>
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
            <h1>Create Template</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="template_list">Template List</a></div>
              <div class="breadcrumb-item">Create Template</div>
            </div>
          </div>

          <!-- Create Template Form -->
          <div class="section-body">
            <div class="row">

              <div class="col-12 col-md-12 col-lg-12">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frm_compose_whatsapp" name="frm_compose_whatsapp"
                    action="#" method="post" enctype="multipart/form-data">
                    <div class="card-body">

                      <!-- Choose Template Category -->
                      <div class="form-group mb-2 row" style='display: none;'>
                        <label class="col-sm-3 col-form-label">Choose Template Category <label
                            style="color:#FF0000">*</label><br>
                          <div><i class="fa fa-star checked"></i> New categories are available. <a href="#"
                              data-toggle="modal" data-target="#myModal"> Learn more about categories </a></div>
                        </label></br>
                        <div class="col-sm-7">
                          <div class="list-group" name="list_items()">
                            <div role="button" class="list-group-item list-group-item-action"><input
                                class="form-check-input" tabindex="1" type="radio" name="categories" id="MARKETING"
                                value="MARKETING" style="margin-left:2px;" checked />
                              <div style="margin-left:20px;"><i class="fas fa-bullhorn"></i> <b> Marketing </b><br> Send
                                promotions or information about your products, services or business.</div>
                            </div>
                            <div role="button" class="list-group-item list-group-item-action"><input
                                class="form-check-input" tabindex="2" type="radio" name="categories" id="UTILITY"
                                value="UTILITY" style="margin-left:2px;" />
                              <div style="margin-left:20px;"><i class="fa fa-bell"></i><b> Utility </b><br> Send
                                messages about an existing order or account.</div>
                            </div>
                            <div role="button" class="list-group-item list-group-item-action"><input
                                class="form-check-input" tabindex="3" type="radio" name="categories" id="AUTHENTICATION"
                                value="AUTHENTICATION" style="margin-left:2px;" />
                              <div style="margin-left:20px;"><i class="fa fa-key"></i> <b> Authentication </b><br> Send
                                codes to verify a transaction or login.</div>
                            </div>
                          </div>
                        </div>
                      </div>

                      <!-- Message Template Name -->
                      <div class="form-group mb-2 row" style='display: none;'>
                        <label class="col-sm-3 col-form-label">Message Template Name <label
                            style="color:#FF0000">*</label> <span data-toggle="tooltip"
                            data-original-title="Template Name allowed maximum 512 Characters. Unique values only allowed">[?]</span></label>
                        <div class="col-sm-7">
                          <input type="text" name="txt_template_name" id='txt_template_name' class="form-control"
                            value="-" tabindex="1" autofocus maxlength="30" placeholder="Enter message template name..."
                            data-toggle="tooltip" data-placement="top" title="" onCopy="return false"
                            onDrag="return false" onDrop="return false" onPaste="return false" pattern="[a-zA-Z0-9 -_]+"
                            onkeypress="return clsAlphaNoOnly(event)" data-original-title="Enter message template name"
                            onkeyup="this.value = this.value.toLowerCase();">
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <!-- Choose Languages -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Languages <label style="color:#FF0000">*</label> <span
                            data-toggle="tooltip"
                            data-original-title="Choose languages for your message template. You can delete or add more languages later.">[?]</span></label>
                        <div class="col-sm-7">
                          <select name="lang[]" id="lang" required class="form-control" tabindex="2">
                            <option value="">Choose Language</option>
                            <? // To list the Languages
                            $replace_txt = '{
                              "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
                            }'; // User ID
                            $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . ''; // Add Bearer Token
                            $curl = curl_init();
                            curl_setopt_array(
                              $curl,
                              array(
                                CURLOPT_URL => $api_url . '/list/master_language',
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
                            site_log_generate("Create Template Page : " . $uname . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
                            $response = curl_exec($curl);
                            curl_close($curl);

                            // After got response decode the JSON result
                            $state1 = json_decode($response, false);
                            site_log_generate("Create Template Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

                            // Display the response data into Option Button
                            if ($state1->num_of_rows > 0) {
                              // Looping the indicator is less than the count of report details.if the condition is true to continue the process and to get the option value.if the condition are false to stop the process.to send the message in no available data.
                              for ($indicator = 0; $indicator < count($state1->report); $indicator++) {
                                $language_name = $state1->report[$indicator]->language_name;
                                $language_id = $state1->report[$indicator]->language_id;
                                $language_code = $state1->report[$indicator]->language_code;
                                ?>
                                <option value="<?= $language_code . '-' . $language_id ?>">
                                  <?= $language_name ?>
                                </option>
                              <?php }
                            }
                            site_log_generate("Create Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " executed the Query ($sql_dashboard1) on " . date("Y-m-d H:i:s"));
                            ?>
                          </select>
                        </div>
                      </div>

                      <!-- Header -->
                      <? /*     <div class="form-group mb-2 row">
 <label class="col-sm-3 col-form-label">Header <span data-toggle="tooltip"
     data-original-title="Add a title or choose which type of media you'll use for this header">[?]</span><span
     style="margin-left:10px;"><b>Optional</b></span></label>
 <div class="col-sm-7">
   <select id="select_id" name="header" class="form-control" tabindex="3">
     <option value="None" type="radio"> None </option>
     <option value="TEXT"> Text </option>
     <option value="MEDIA"> Media </option>
   </select>
   <!-- <br> -->
<!-- Header Name -->
 <div style="display: none; margin-left:4px; " id="text"
    >
   </br><div type="text" contenteditable="true"  name="txt_header_name" id='txt_header_name' class="form-control custom-width"
       value="<?= $txt_header_name ?>" tabindex="4" maxlength="60"
       placeholder="Enter header name..." data-toggle="tooltip" data-placement="top" title=""
       data-original-title="Enter header Name"></div>Characters : ​<span id="count1"></span>
   
   </div> <div class=" container" style="display: none;" id="header_variable_btn1"> <div class="row"><div class="col-4"> ​<button name="btn1" onclick="myFunction()" type="button" id="btn1" tabindex="5"
             class="btn btn-success " style="text-align:center; margin-top:5px;" > + Add variable</button></div>
             <!-- <div class="col-4" id='txt_header_variable'> </div> -->
             <div class="col-4" >  
               <input type="text" name="txt_header_variable"  style=" height:40px;"   id='txt_header_variable_1' tabindex="6" class="form-control"
           value="<?= $txt_sample_name ?>" maxlength="60" placeholder="Header Variable"
           data-toggle="tooltip" data-placement="top" title=""
           data-original-title="Header Variable" style="display: none; margin-top:0px;">
           <div class="col-4"></div></div></div></div>

<!-- Image / Document (Media) -->
   </br><div class="row" id="image_category" style="display: none; "
     name="image_category">
     <div class="col-4" style="float: left;">
       <div role="button"><label>Image</label><input class="form-check-input" type="radio"
           name="media_category"  tabindex="7" id="image1" value="image"
           style="margin-left:2px;" onclick=" media_category_img(this)"/>
         <div style="margin-left:20px;"><i class="fa fa-image" style="font-size: 20px"></i></div>
       </div>
     </div>
     <div class="col-4" style="float: left;">
       <div role="button"><label>Video</label><input class="form-check-input" type="radio"
           name="media_category"  tabindex="8" id="image2" value="video"
           style="margin-left:2px;" onclick=" media_category_vid(this)"/>
         <div style="margin-left:20px;"><i class="fa fa-play-circle" style="font-size: 20px"></i>
         </div>
       </div>
     </div>
     <div class="col-4" style="float: left;">
       <div role="button"><label>Document</label><input class="form-check-input" type="radio"
           name="media_category" tabindex="9" id="image3" value="document"
           style="margin-left:2px;" onclick=" media_category_doc(this)"/>
         <div style="margin-left:20px;"><i class="fa fa-file-text" style="font-size: 20px"></i>
         </div>
       </div>
     </div>
     <div class="col-4 file_image_header" style="float: left; display:none;">
       <input type="file" name="file_image_header" id="file_image_header" tabindex="10" />
     </div>
   </div>
 </div>
</div> */?>

                      <!-- Body Content -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Body <label style="color:#FF0000">*</label> <span
                            data-toggle="tooltip"
                            data-original-title="Enter the text for your message in the language that you've selected.">[?]</span></label>

                        <div class="col-sm-7">
                          <!-- <div class="col-sm-8">
                        <div class="note-toolbar" role="toolbar"><div class="note-btn-group note-font"><button type="button" class="note-btn note-btn-bold" tabindex="-1" aria-label="Bold (CTRL+B)"><i class="note-icon-bold"></i></button><button type="button" class="note-btn note-btn-underline" tabindex="-1" aria-label="Underline (CTRL+U)"><i class="note-icon-underline"></i></button><button type="button" class="note-btn note-btn-italic" tabindex="-1" aria-label="Italic (CTRL+I)"><i class="note-icon-italic"></i></button><button type="button" class="note-btn" tabindex="-1" aria-label="Remove Font Style (CTRL+\)"><i class="note-icon-eraser"></i></button></div><div class="note-btn-group note-para"><button type="button" class="note-btn" tabindex="-1" aria-label="Unordered list (CTRL+SHIFT+NUM7)"><i class="note-icon-unorderedlist"></i></button><button type="button" class="note-btn" tabindex="-1" aria-label="Ordered list (CTRL+SHIFT+NUM8)"><i class="note-icon-orderedlist"></i></button></div><div class="note-btn-group note-insert"><button type="button" class="note-btn" tabindex="-1" aria-label="Link (CTRL+K)"><i class="note-icon-link"></i></button></div></div>
                          </div> -->
                          <div class="row">
                            <div class="col-8">
                              <!-- TEXT area alert -->
                              <textarea id="textarea" class="delete form-control" name="textarea" required
                                maxlength="1024" tabindex="11" placeholder="Enter Body Content" rows="6"
                                style="width: 100%; height: 150px !important;"></textarea>
                              <div class="row" style="right: 0px;">
                                <div class="col-sm" style="margin-top: 5px;"> <span
                                    id="current_text_value">0</span><span id="maximum">/ 1024</span>
                                </div>
                                <!-- <div class="col-sm" style=" margin-top: 5px;">​<a href='#!' name="btn" type="button" id="btn"  tabindex="12"
                                class="btn btn-success"> + Add variable</a></div> -->
                              </div>

                              <!-- TEXT area alert End -->
                            </div>
                            <div class="col container1" id="add_variables" style="display:none;"><label
                                class="col-form-label">Variable Values <label style="color:#FF0000"> * </label> <span
                                  data-toggle="tooltip"
                                  data-original-title="Variables must not empty.Template Name allowed maximum 60 Characters.">[?]</span></label>
                            </div>
                          </div>
                        </div>


                      </div>
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3"></label>
                        <div class=" col-sm-7" style="display:none;" id="alert_variable" style="border-color:red">
                          <div class="row"><span>
                              <ul style="list-style-type: disc;">
                                <div>
                                  <li style="width:800px;">The body text contains variable parameters at the beginning
                                    or end. You need
                                    to either change this format or add a sample.</li>
                                  <li style="width:800px;">Variables must not empty.</li>
                                  <li style="width:800px;">This template contains too many variable parameters relative
                                    to the message
                                    length. You need to decrease the number of variable parameters or increase the
                                    message length.</li>
                                  <li style="width:800px;">The body text contains variable parameters that are next to
                                    each other. You
                                    need to either change this format or add a sample.</li>
                                  <li style="width:800px;"> <a target="_blank"
                                      href="https://developers.facebook.com/docs/whatsapp/message-templates/guidelines/">Learn
                                      more about formatting in Message Template Guidelines</a></li>
                                </div>
                              </ul>
                            </span></div>
                        </div>
                      </div>


                      <!-- Footer -->
                      <? /*    <div class="form-group mb-2 row">
 <label class="col-sm-3 col-form-label">Footer <span data-toggle="tooltip"
     data-original-title="Add a short line of text to the bottom of your message template. If you add the marketing opt-out button, the associated footer will be shown here by default.">[?]</span><span
     style="margin-left:10px;"><b>Optional</b></span></label></br>
 <div class="col-sm-7">
   <div>
     <input type="text" name="txt_footer_name" id='txt_footer_name' tabindex="13"
       class="form-control" value="<?= $txt_footer_name ?>" maxlength="60"
       placeholder="Enter Footer Name..." data-toggle="tooltip" data-placement="top" title=""
       data-original-title="Enter Footer Name">Characters : ​<span id="count2"></span>
   </div>
   
 </div>
</div>

<!-- Buttons -->
<div class="form-group mb-2 row">
 <label class="col-sm-3 col-form-label">Buttons <span data-toggle="tooltip"
     data-original-title="Create buttons that let customers respond to your message or take action.">[?]</span><span
     style="margin-left:10px;"><b>Optional</b></span></label>
 <div class="col-sm-7">
   <div>
     <select id="select_action" name="select_action" class="form-control" tabindex="14">
       <option value="None" type="radio"> None </option>
       <option value="CALLTOACTION"> Call To Action </option>
       <option value="QUICK_REPLY"> Quick Reply </option>
     </select>
   </div>
   <br>

   <div class="container" style="display:none;" id="callaction">
     <div class="row">
       <div class="col">
         <label for="lang1">Type of action</label><br>

         <select id="select_action1" name="select_action1" class="form-control" tabindex="15">
           <option value="PHONE_NUMBER" > Call Phone Number </option>
           <option value="VISIT_URL"> Visit Website </option>
         </select>
       </div>
       <div class="col">
         <label for="lang1">Button text</label><br>
         <input type="text" name="button_text[]" id='button_text' class="form-control"
           value="<?= $button_text ?>" tabindex="16" maxlength="25"
           placeholder="Enter button name..." data-toggle="tooltip" data-placement="top" title=""
           data-original-title="Enter button name" >
       </div>

       <div class="col">
         <label for="lang1">Country</label><br>
         <select id="country_code" name="country_code" class="form-control" tabindex="17">
           <? // To display the country from Master API
           $replace_txt = '{
             "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
           }'; // User Id
           $bearer_token = 'Authorization: '.$_SESSION['yjwatsp_bearer_token'].''; // Add Bearer Token
           $curl = curl_init();
           curl_setopt_array($curl, array(
             CURLOPT_URL => $api_url . '/list/country_list',
             CURLOPT_RETURNTRANSFER => true,
             CURLOPT_ENCODING => '',
             CURLOPT_MAXREDIRS => 10,
             CURLOPT_TIMEOUT => 0,
             CURLOPT_FOLLOWLOCATION => true,
             CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
             CURLOPT_CUSTOMREQUEST => 'POST',
             CURLOPT_POSTFIELDS =>$replace_txt,
             CURLOPT_HTTPHEADER => array(
               $bearer_token,
               'Content-Type: application/json'
             ),
           ));

// Send the data into API and execute                                
           site_log_generate("Create Template Page : " . $uname . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
           $response = curl_exec($curl);
           curl_close($curl);

// After got response decode the JSON result
           $state1 = json_decode($response, false);
           site_log_generate("Create Template Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

// Display the Response data into option list. By default select India
           if ($state1->num_of_rows > 0) {
              // Looping the indicator is less than the count of report details.if the condition is true to continue the process and to get the option value.if the condition are false to stop the process.to send the message in no available data.
             for ($indicator = 0; $indicator < count($state1->report); $indicator++) {
               $shortname = $state1->report[$indicator]->shortname;
               $phonecode = $state1->report[$indicator]->phonecode;
               ?>
               <option value="<?= "+" . $phonecode ?>" <? if ($shortname == 'IN') { echo "selected"; } ?>><?=$shortname . "+" . $phonecode ?></option>
             <?php }
           }
           site_log_generate("Create Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " executed the Query ($sql_dashboard1) on " . date("Y-m-d H:i:s"));
           ?>
         </select></label>

       </div>
       <div class="col">
         <label for="lang1">Phone number</label><br>
         <input type="text" name="button_txt_phone_no[]" id='button_txt_phone_no' onkeypress='return event.charCode >= 48 && event.charCode <= 57'    oninput="validateInput_phone()"
           class="form-control" value="<?= $button_text1 ?>" tabindex="18" maxlength="10"
           placeholder="Phone number" style="padding: 10px 5px !important;" data-toggle="tooltip"
           data-placement="top" title="" data-original-title="Phone number">
       </div>
     </div>

     <div class="row add_phone_content"> </div>
     
     <div class="col"><a href='#!' name="add_phone_btn" type="button" id="add_phone_btn_btn" tabindex="19"
         class="btn btn-success" style="margin-top:30px; width:200px;height:30px;" >+ Add Another Button</a></div>
   </div>
   
<!-- Call to Action -->
   <div class="container" style="display:none;" id="calltoaction">
     <div class="row">                            
       <div class="col">
         <label for="lang1">Button Text</label><br>
         <input type="text" name="button_quickreply_text[]" id='button_quickreply_text'
           class="form-control" value="<?= $button_text2 ?>" tabindex="20" maxlength="25"
           placeholder="Enter Button Name 1" data-toggle="tooltip" data-placement="top" title=""
           data-original-title="Enter button name">
       </div>
       
       <div class="col" >
       ​<a href='#!' name="add_another_button" type="button" id="add_another_button" tabindex="21"
         class="btn btn-success" style="margin-top:30px;" >+ Add Another Button</a>
           </div></div>
    
     <div class="row ">
       <div class="col-md-6 add_button_textbox"> </div>
     </div>
   </div> 
   <div class="container" style="display:none;" id="visit_website">
     <div class="row">
     <div class="col"><label for="lang1">Type of action</label><br><select id="select_action3" name="select_action3" class="form-control" tabindex="22"><option value="PHONE_NUMBER">Phone Number</option> <option value="VISIT_URL" > Visit Website</option> </select> </div>
       <div class="col"><label for="select_action2" >URL Button Name</label><br>
         <input type="text" name="button_url_text[]" id='button_url_text' class="form-control"
           value="<?= $website ?>" tabindex="23" maxlength="25" placeholder="Enter url name..."
           data-toggle="tooltip" data-placement="top" title=""
           data-original-title="Enter button name" >
       </div>
       <div class="col"><label for="select_action2">Type</label><br>
         <select name="select_action2" id="select_action2" class="form-control">
           <option value="Static"> Static
           </option>
         </select>
       </div>
       <div class="col"><label for="select_action2" >URL</label><br>
         <input type="text" name="website_url[]" id='website_url' class="form-control"
           value="<?= $website ?>" tabindex="24" maxlength="2000" placeholder="Enter url..."
           data-toggle="tooltip" data-placement="top" title=""
           data-original-title="Enter url">
       </div>
     </div>
     <div class="row add_url_content"> </div>

     <div class="col"><a href='#!' name="add_url_btn_btn" type="button" id="add_url_btn_btn" tabindex="25"
         class="btn btn-success" style="margin-top:30px; width:200px;height:30px;" >+ Add Another Button</a></div>
   </div>
   
 </div>
</div>
</div> */?>
                      <div class="row">
                        <input type="hidden" class="form-control" name='tmp_qty_count' id='tmp_qty_count' value='1' />
                        <input type="hidden" class="form-control" name='temp_call_function' id='temp_call_function'
                          value='create_template' />
                        <input type="hidden" class="form-control" name='hid_sendurl' id='hid_sendurl'
                          value='<?= $server_http_referer ?>' />
                      </div>

                      <div class="error_display" id='id_error_display_submit'></div>
                      <div class="card-footer text-center" style="margin-top:40px;">
                        <input type="button" onclick="myFunction_clear()" value="Clear" class="btn btn-success"
                          id="clr_button">
                        <input type="submit" name="submit" id="submit" tabindex="26" value=" Save & Submit"
                          class="btn btn-success">
                        <input type="button" value="Preview Content" onclick="preview_content()" data-toggle="modal"
                          data-target="#previewModal" class="btn btn-success" id="pre_button" name="pre_button">
                      </div>

                  </form>

        </section>

      </div>
      <!-- Modal content-->
      <div class="modal fade" id="default-Modal" tabindex="-1" role="dialog">
        <div class="modal-dialog" role="document" style=" max-width: 75% !important;">
          <div class="modal-content">
            <div class="modal-header">
              <h4 class="modal-title">Template Details</h4>
              <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body" id="id_modal_display" style=" word-wrap: break-word; word-break: break-word;">
              <h5>No Data Available</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-success waves-effect " data-dismiss="modal">Close</button>
            </div>
          </div>
        </div>
      </div>
      <!-- Preview Data Modal content End-->

      <!-- include site footer -->
      <? include("libraries/site_footer.php"); ?>

    </div>
  </div>


  <!-- General JS Scripts -->
  <!-- <script src="assets/modules/jquery.min.js"></script> -->
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

  <script src="assets/js/xlsx.core.min.js"></script>
  <script src="assets/js/xls.core.min.js"></script>

  <script>


    // Initialize Summernote
    $('#textarea').summernote({
      height: 300,
      toolbar: [
        ['font', ['bold', 'clear']],
        ['insert', ['link']]
      ],
      callbacks: {
        onChange: function (contents, $editable) {
          // Adjust the logic based on the HTML structure
          var characterCount = getCleanText(contents).length || 0;
          $("#current_text_value").text(characterCount);
        }
      },
      placeholder: 'Type here...',
      enterParagraphs: false,
    });

    function getCleanText(html) {
      // Implement logic to clean the HTML and get plain text
      // For example, you can use a DOM parser to extract text content
      // This is just a basic example, and you may need to refine it based on your requirements
      var doc = new DOMParser().parseFromString(html, 'text/html');
      return doc.body.textContent || "";
    }

    // start function document
    $(function () {
      $('.theme-loader').fadeOut("slow");
    });

    document.body.addEventListener("click", function (evt) {
      //note evt.target can be a nested element, not the body element, resulting in misfires
      $("#id_error_display_submit").html("");
    });


    // While clicking the Submit button
    $(document).on("submit", "form#frm_compose_whatsapp", function (e) {
      flag = true;
      e.preventDefault();
      var lang = $('#lang').val();
      var textarea_value = $('#textarea').val();

      replacedString = textarea_value.replace(/<\/p><p>/g, '<br>');
      // textarea = replacedString.replace(/<\/?p>/g, '');
      // alert(textarea)
      var textarea_new = replacedString.replace(/&nbsp;/g, '');
      e.preventDefault();

      if (flag) { // If no flag is red
        var fd = new FormData(this);
        fd.append('textarea_new', textarea_new);
        // Submit the form into Ajax - ajax/whatsapp_call_functions.php
        $.ajax({
          type: 'post',
          url: "ajax/whatsapp_call_functions.php",
          dataType: 'json',
          data: fd,
          contentType: false,
          processData: false,
          beforeSend: function () { // Before send to Ajax
            $('#submit').attr('disabled', true);
            $('.theme-loader').show();
          },
          complete: function () { // After complete the Ajax
            $('#submit').attr('disabled', false);
            $('.theme-loader').hide();
            e.preventDefault();

          },
          success: function (response) { // Succes
            if (response.status == '0' || response.status == 0) { // Failed Status
              $('#submit').attr('disabled', false);
              $('.theme-loader').hide();
              $("#id_error_display_submit").html(response.msg);
            } else if (response.status == 1 || response.status == '1') { // Success Status
              $('#submit').attr('disabled', false);
              $('.theme-loader').hide();
              $("#id_error_display_submit").html("Template created successfully !!");
              setInterval(function () {
                 window.location = 'template_list';
                document.getElementById("frm_compose_whatsapp").reset();
              }, 2000);
            }
            $('.theme-loader').hide();
          },
          error: function (response, status, error) { // Error
            $('#submit').attr('disabled', false);
            $("#id_error_display_submit").html(response.msg);
            // window.location = 'template_list';
          }
        })
      }
    });

    // FORM Clear value    
    function myFunction_clear() {
      document.getElementById("frm_compose_whatsapp").reset();
      window.location.reload();
    }

    // FORM preview value
    function preview_content() {
      var lang = $('#lang').val();
      var textarea_value = $('#textarea').val();

      replacedString = textarea_value.replace(/<\/p><p>/g, '<br>');
      textarea = replacedString.replace(/<\/?p>/g, '');
      // alert(textarea)
      var textarea_new = replacedString.replace(/&nbsp;/g, '');
      var form = $("#frm_compose_whatsapp")[0]; // Get the HTMLFormElement from the jQuery selector
      var fd = new FormData(form); // Use the form element in the FormData constructor
      fd.append('textarea_new', textarea_new);

      $.ajax({
        type: 'post',
        url: "ajax/preview_call_functions.php?preview_functions=preview_template",
        data: fd,
        processData: false, // Important: Prevent jQuery from processing the data
        contentType: false, // Important: Let the browser set the content type
        success: function (response) { // Success
          $("#id_modal_display").html(response);
          console.log(response.status);
          $('#default-Modal').modal({ show: true }); // Open in a Modal Popup window
        },
        error: function (response, status, error) { // Error
          console.log("error");
          $("#id_modal_display").html(response.status);
          $('#default-Modal').modal({ show: true });
        }
      });
    }

  </script>
</body>

</html>
