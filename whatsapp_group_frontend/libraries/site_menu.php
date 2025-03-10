<div class="main-sidebar sidebar-style-2">
  <aside id="sidebar-wrapper">
    <div class="sidebar-brand">
      <a href="dashboard"><img src="assets/img/yeejai-logo.png" style="height:100%" /></a>
    </div>
    <div class="sidebar-brand sidebar-brand-sm">
      <a href="dashboard"><img src="assets/img/yj.png" style="height:100%" /></a>
    </div>
    <ul class="sidebar-menu">
      <li <? if ($site_page_name == 'dashboard') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="dashboard" class="nav-link"><i class="fas fa-home"></i><span>Dashboard</span></a>
      </li>

      <li <? if ($site_page_name == 'create_template' || $site_page_name == 'template_list' || $site_page_name == 'manage_senderid_list' || $site_page_name == 'add_senderid') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown" data-toggle="dropdown"><i class="fab fa-whatsapp"></i>
          <span>Sender ID</span></a>
        <ul class="dropdown-menu">

          <li <? if ($site_page_name == 'add_senderid') { ?>class="active" <? } ?>><a class="nav-link"
              href="add_senderid">Add Sender ID</a></li>
          <li <? if ($site_page_name == 'manage_senderid_list') { ?>class="active" <? } ?>><a class="nav-link"
              href="manage_senderid_list">Sender ID List</a></li>
          <li <? if ($site_page_name == 'create_template') { ?>class="active" <? } ?>><a class="nav-link"
              href="create_template">Create Template</a></li>
          <li <? if ($site_page_name == 'template_list') { ?>class="active" <? } ?>><a class="nav-link"
              href="template_list">Template List</a></li>
        </ul>
      </li>

      <li <? if ($site_page_name == 'compose_whatsapp_list' || $site_page_name == 'compose') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown" data-toggle="dropdown"><i class="fab fa-whatsapp"></i>
          <span>Compose</span></a>
        <ul class="dropdown-menu">

          <li <? if ($site_page_name == 'compose') { ?>class="active" <? } ?>><a class="nav-link"
              href="compose">Compose</a></li>
          <li <? if ($site_page_name == 'compose_whatsapp_list') { ?>class="active" <? } ?>><a class="nav-link"
              href="compose_whatsapp_list">Whatsapp List</a></li>
        </ul>
      </li>

      <li <? if ($site_page_name == 'plan_creation' || $site_page_name == 'purchase_plans_list' || $site_page_name == 'user_plans_list' || $site_page_name == 'purchase_history') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown" data-toggle="dropdown"><i class="fa-money-bill-wave"></i>
          <span>Pricing Plans</span></a>
        <ul class="dropdown-menu">

          <li <? if ($site_page_name == 'plan_creation') { ?>class="active" <? } ?>><a class="nav-link"
              href="plan_creation">Create Plans</a></li>
          <li <? if ($site_page_name == 'user_plans_list') { ?>class="active" <? } ?>><a class="nav-link"
              href="user_plans_list">Pricing Plans List</a></li>
          <li <? if ($site_page_name == 'purchase_plans_list') { ?>class="active" <? } ?>><a class="nav-link"
              href="purchase_plans_list">Purchase Plans List</a></li>
          <li <? if ($site_page_name == 'purchase_history') { ?>class="active" <? } ?>><a class="nav-link"
              href="purchase_history">Purchse History List</a></li>
        </ul>
      </li>


      <li <? if ($site_page_name == 'contacts') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="contacts" class="nav-link"><i class="fas fa-user"></i><span>Contacts</span></a>
      </li>

      <li <? if ($site_page_name == 'add_group' || $site_page_name == 'group_list' || $site_page_name == 'add_group' || $site_page_name == 'add_contact_group') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown"><i class="fas fa-user-plus"></i> <span>Groups</span></a>
        <ul class="dropdown-menu">

          <li <? if ($site_page_name == 'add_contact_group') { ?>class="active" <? } ?>><a class="nav-link"
              href="add_contact_group">Add Group Contact</a></li>
          <li <? if ($site_page_name == 'group_list') { ?>class="active" <? } ?>><a class="nav-link"
              href="group_list">Group List</a></li>
        </ul>
      </li>

      <li <? if ($site_page_name == 'manage_users' || $site_page_name == 'manage_users_list') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown"><i class="fas fa-user-plus"></i> <span>Manage Users</span></a>
        <ul class="dropdown-menu">

          <li <? if ($site_page_name == 'manage_users') { ?>class="active" <? } ?>><a class="nav-link"
              href="manage_users">User creation</a></li>
          <li <? if ($site_page_name == 'manage_users_list') { ?>class="active" <? } ?>><a class="nav-link"
              href="manage_users_list">Users List</a></li>
        </ul>
      </li>

      <li <? if ($site_page_name == 'summary_report' || $site_page_name == 'campaign_report' || $site_page_name == 'details_report') { ?>class="dropdown active" <? } else { ?>class="dropdown" <? } ?>>
        <a href="#" class="nav-link has-dropdown"><i class="fas fa-chart-bar"></i> <span>MIS Reports</span></a>
        <ul class="dropdown-menu">

          <li <? if ($site_page_name == 'summary_report') { ?>class="active" <? } ?>><a class="nav-link"
              href="summary_report">Summary Report</a></li>
          <li <? if ($site_page_name == 'details_report') { ?>class="active" <? } ?>><a class="nav-link"
              href="details_report">Detailed Report</a></li>
        </ul>
      </li>
    </ul>

  </aside>
</div>
