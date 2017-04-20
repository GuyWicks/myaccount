<!DOCTYPE HTML>
<%@ page import="edu.internet2.middleware.shibboleth.idp.authn.LoginContext" %>
<%@ page import="edu.internet2.middleware.shibboleth.idp.authn.ShibbolethSSOLoginContext" %>
<%@ page import="edu.internet2.middleware.shibboleth.idp.session.*" %>
<%@ page import="edu.internet2.middleware.shibboleth.idp.util.HttpServletHelper" %>
<%@ page import="org.opensaml.saml2.metadata.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.net.*" %>
<%@ taglib uri="urn:mace:shibboleth:2.0:idp:ui" prefix="idpui" %> 
<%
    Boolean debuggingHeadFlag         = false;    // Set to true to see header variables table
    Boolean debuggingVarFlag          = false;    // Set to true to see header variables table

/*
 * Defaults for the login page - generic BLOA registration
 */
    Boolean  guestLogin               = false;    // Set true (by the entityID) to display the guest login option
    Boolean  registerLink             = false;    // Set true (by the entityID) to display the register option
    Boolean  rrupgradeLink            = false;    // Set true (by the entityID) to display the reader upgrade option
    Boolean  readerLink               = false;    // Display the "How to be a reader" information
    Boolean  accountLogin             = true;     // Set true to display the BLOA login option
    Integer  registerServiceId        = 0;        // Default service ID for registering new accounts

    String   referringPage            = "https://myaccount.bl.uk";   // Referring page for post registration
    String   registerServiceName      = "British Library Online Account";
    String   registerDescription      = "";

    String   registerServiceURL       = "https://registeruat.bl.uk/RegOnline.aspx";
    String   registerServiceDirectURL = "https://registeruat.bl.uk/UI/RegOnlineAccount.aspx";     // Only works for serviceid=0
    String   registerReaderPassURL    = "http://www.bl.uk/help/how-to-get-a-reader-pass";
    String   forgottenUsernameURL     = "https://myaccountuat.bl.uk/Ui/ForgottenUsername.aspx";
    String   forgottenPasswordURL     = "https://myaccountuat.bl.uk/Ui/ForgottenPassword.aspx";
    String   changePasswordURL        = "https://myaccountuat.bl.uk/Ui/MyAccountLogin.aspx";
    String   rrUpgradeURL             = "https://registeruat.bl.uk/Ui/ReaderMigration01.aspx";

    // Did the previous login attempt fail?
    Boolean  loginFailed              = "true".equals(request.getAttribute("loginFailed"));

    // Credentials to be used for guest login form
    String   guestUsername            = "OnlineShopGuest";
    String   guestPassword            = "NotASecret";

    // Entity discovery
    String   entityID                 = "";
    String   entitySubSiteID          = "explore";
    String   entrySite                = request.getHeader("referer");

    //
    // Get the SP entityID
    //
    LoginContext loginContext = HttpServletHelper.getLoginContext(HttpServletHelper.getStorageService(application), application, request);
    if(loginContext != null) {
        EntityDescriptor entityDescriptor = HttpServletHelper.getRelyingPartyMetadata(loginContext.getRelyingPartyId(), HttpServletHelper.getRelyingPartyConfirmationManager(application)); 
        entityID = entityDescriptor.getEntityID();
    } 

    //
    // Map the entityID's to the correct style of login page
    //
    // Explore/SearchArchives/OrderSubmission is the DEFAULT page
    //if (entityID.equals("https://ssoa.bl.uk/sp/shibboleth/orangefe1"))          { entitySubSiteID = "explore"; }
    // 
    
    // BLDSS API
    if (entityID.equals("https://sso.bl.uk/sp/shibboleth/bldssapipr"))          { entitySubSiteID = "bldssapi"; }

    // Default
    if (entityID.equals("https://www.bl.uk/shibboleth"))                        { entitySubSiteID = "default"; }
    if (entityID.equals("https://nginx-nle.bl.uk/shibboleth"))                  { entitySubSiteID = "default"; }

    // Business and management portal
    if (entityID.equals("https://www.bl.uk/sp/shibboleth/mbsportal"))           { entitySubSiteID = "mbsportal"; }
    if (entityID.equals("https://nginx-nle.bl.uk/sp/shibboleth/mbsportal"))     { entitySubSiteID = "mbsportal"; }

    // Social welfare portal    
    if (entityID.equals("https://www.bl.uk/sp/shibboleth/swportal"))            { entitySubSiteID = "swportal"; }
    if (entityID.equals("https://nginx-nle.bl.uk/sp/shibboleth/swportal"))      { entitySubSiteID = "swportal"; }

    // Online shop
    if (entityID.equals("https://www.bl.uk/sp/shibboleth/shop"))                { entitySubSiteID = "onlineshop"; }
    if (entityID.equals("https://nginx-nle.bl.uk/sp/shibboleth/shop"))          { entitySubSiteID = "onlineshop"; }
    if (entityID.equals("http://cdstaging.bl.uk/shop"))                         { entitySubSiteID = "onlineshop"; }

    // Override entity ID for testing
    String testLogin = request.getParameter("testlogin");
    if( testLogin != null ) { entitySubSiteID = testLogin; }

    // Customize the login form 
    if("default".equals(entitySubSiteID)) {
      guestLogin = true; 
      registerLink = true; 
      registerServiceId = 2;  
      registerServiceName = "SERVICE NAME";
      referringPage = "http://www.bl.uk/";
      registerDescription = "REGISTRATION DESCRIPTION";
    }

    if("onlineshop".equals(entitySubSiteID)) {
      guestLogin = true; 
      registerServiceId = 6;  
      registerServiceName = "the British Library Shop";
      referringPage = "http://nginx-nle.bl.uk/shop"; 
    }

    if("mbsportal".indexOf(entitySubSiteID)>=0) {
      registerLink = true; 
      registerServiceId = 2; 
      referringPage = "https://www.bl.uk/business-management"; 
      registerServiceName = "the Business and management portal";
      registerDescription = "Start by registering for an online account and then choose your Business and management portal service preferences.";
    }

    if("swportal".equals(entitySubSiteID)) {
      registerLink = true; 
      registerServiceId = 5; 
      referringPage = "https://www.bl.uk/social-welfare"; 
      registerServiceName = "the Social welfare portal";
      registerDescription = "Start by registering for an online account and then choose your Social welfare portal preferences.";
    }

    if("bldssapi".equals(entitySubSiteID)) {
      registerLink = true; 
      registerServiceId = 3; 
      referringPage = "https://api.bldss.bl.uk"; 
      registerServiceName = "British Library On Demand";
      registerDescription = "Register for British Library On Demand.";
    }

    if("explore".equals(entitySubSiteID)) {
      registerServiceId = 0; 
      registerServiceURL = registerServiceDirectURL;

      registerLink = true; 
      rrupgradeLink = true;
      readerLink = false;
      referringPage = "http://explore.bl.uk/"; 
      registerServiceName = "our catalogue";
      registerDescription = "Register your details to use our services.";
    }

// If there is no Shibboleth IDP/SP entityID then show error message
//    if(loginContext == null and entitySubSiteID == "") {
    if(entitySubSiteID == "") {
      registerLink = false;
      guestLogin = false;
      accountLogin = true;
      registerServiceName = "British Library";
    }


// If the account login failed (bad username/email) then only dispay the registered login
    if (loginFailed) {
      guestLogin = false;
      registerLink = false;
      //rrupgradeLink = false;
    }
%>
<html>
<title>Login to the British Library</title>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <!--link rel="stylesheet" href="https://www.w3schools.com/lib/w3.css"-->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
  <link rel="stylesheet" href="/idp/css/w3.css">
  <link rel="stylesheet" href="/idp/css/bl-w3.css">
<script 
  src="https://code.jquery.com/jquery-3.2.1.slim.min.js"
  integrity="sha256-k2WSCIexGzOj3Euiig+TlR8gA0EmPjuc79OEeY5L45g="
  crossorigin="anonymous"></script>
</head>

<body class="w3-content bl-body" style="max-width:990px;">

  <div class="main-page-img w3-hide-small w3-hide-medium">
    <div></div>
  </div>

  <header class="">
    <div class="w3-container bl-theme-dark bl-padding-left-off bl-logo-height bl-header-border w3-hide-small">
      <div class="w3-left"><img class="bl-logo-border" src="//www.bl.uk/britishlibrary/resources/global/images/bl_logo_100.gif" width="52px" height="100px"/></div>
    </div>
    <div class="w3-container bl-theme-mid"><h2>Secure login to <%= registerServiceName %></h2></div>
  </header>

  <div class="w3-container bl-white w3-padding-16 bl-content-height">

<% if(accountLogin) { %>                                                    

    <div class="w3-half w3-padding">
      
      <form class="w3-container" action='<%=request.getAttribute("actionUrl") %>' method="post" autocomplete="off" name="logonform">
        <legend>British Library Online Account</legend>

        <div class="w3-row w3-section">
          <label>Username or email address</label>
          <input class="w3-input w3-border bl-pale-yellow" 
              type="text" name="j_username" 
                            id="username"
                            required="required" 
                            autofocus="true"
                            xplaceholder="Username or email address"
                            aria-required="true"/>
        </div>

        <div class="w3-row w3-section">
          <label>Password</label>
          <input class="w3-input w3-border bl-pale-yellow"  
              type="password" 
              name="j_password"
              id="password"
              required="required" 
              xplaceholder="Password"
              aria-required="true"/>          
          
        </div>

        <div class="w3-row w3-section w3-right" >
          <a href="#" id="btnNeedHelp" class="w3-btn bl-theme-accent2">Need help?</a>
          <button id="btnLoginReg" class="w3-btn bl-theme-accent1">Log in<i class="fa fa-caret-right bl-fa-padding"></i></button>
        </div>

        <div class="w3-row w3-section" >
          <div class="w3-text-grey w3-hover-text-black"><a href="<%= forgottenUsernameURL %>?ServiceId=<%= registerServiceId %>&referringPage=<%= referringPage %>">Forgot your username?</a></div>
          <div class="w3-text-grey w3-hover-text-black"><a href="<%= forgottenPasswordURL %>?ServiceId=<%= registerServiceId %>&referringPage=<%= referringPage %>">Forgot your password?</a></div>
        </div>    

        <div class="w3-row w3-section" >
          <div class="w3-text-grey w3-hover-text-black"><a href="<%= changePasswordURL %>?referringPage=<%= referringPage %>">Change password<br/>Edit account preferences</a></div>
        </div>  

      </form>
    </div>

<% } else { %>

  <h3>Error: Service undefined</h3>
  <p><strong>No entity context defined.</strong></p>
  <p>Cause: This message is displayed when no Shibboleth session has been established by the browser. Check the service provider configuration.</p>
  <br/><br/><br/><br/><br/><br/><br/><br/>

<% } %>
                                                   
<% 
if(guestLogin) { 
%>
    <div class="w3-half w3-padding">
      <form action='<%=request.getAttribute("actionUrl")%>' method="post" autocomplete="off" name="logonform">
        <input name="j_username" type="hidden" tabindex="1" xstyle="width: 180px;" id="username" value="<%= guestUsername %>"/>
        <input name="j_password" type="hidden" tabindex="2" xstyle="width: 180px;" id="password" value="<%= guestPassword %>"/>
        <legend>Guest checkout</legend>

        <div class="w3-row w3-padding-16">Continue as a guest now and create an account after checkout to allow you to complete your order faster next time.</div>
        <button class="w3-btn bl-theme-accent1 w3-right">Guest checkout<i class="fa fa-caret-right bl-fa-padding"></i></button>
      </form>
    </div>
                                            
<% }
if (registerLink) {
%> 
    <div class="w3-half w3-padding">
      <legend>Are you new to the British Library?</legend>

      <div class="w3-row w3-padding-16"><%= registerDescription %></div>

      <div class="w3-right">
        <a class="w3-btn bl-theme-accent2" href="#" id="btnMoreInfoNew" target="_blank">More information</a>
        <a class="w3-btn bl-theme-accent1" href="<%=registerServiceURL%>?serviceId=<%= registerServiceId %>&referringPage=<%= referringPage %>">Register <i class="fa fa-caret-right bl-fa-padding"></i></a>        
      </div>
    </div>

<% }
if (readerLink) {
%> 
    <div class="w3-half w3-padding">
      <legend>Do you want to see our collections?</legend>

      <div class="w3-row w3-padding-16">You can register in person for your free Reader Pass, or pre-register online.</div>

      <div class="w3-right">
        <a class="w3-btn bl-theme-accent1" href="<%=registerReaderPassURL%>?serviceId=<%= registerServiceId %>&referringPage=<%= referringPage %>">Apply for a Reader Pass <i class="fa fa-caret-right bl-fa-padding"></i></a>
      </div>
    </div>

<% }
if (rrupgradeLink) {
%>  
    <div class="w3-half w3-padding">
        <legend>Do you have a Reader Pass?</legend>

        <div class="w3-row w3-padding-16">You need to have both a Reader Pass and a British Library Online Account so you can request items.</div>

        <div class="w3-right">
          <a class="w3-btn bl-theme-accent2" href="#" id="btnMoreInfoUpgrade" target="_blank">More information</a>        
          <a class="w3-btn bl-theme-accent1" href="<%=rrUpgradeURL%>">Activate <i class="fa fa-caret-right bl-fa-padding"></i></a>
        </div>
    </div>
<% } %> 

    <div id="IncorrectCredentials" class="w3-modal">
      <div class="w3-modal-content w3-card-8">
        <header class="w3-container w3-deep-orange"> 
          <span xonclick="document.getElementById('IncorrectCredentials').style.display='none'" 
          class="w3-closebtn">&times;</span>
        </header>

        <div class="w3-container">
          <h3>Login failed</h3>
          <p>Possible reasons your login did not succeed:</p>
          <ul>
            <li>You have mistyped your email or username or password</li>
            <li>You are not registered for a British Library Online Account</li>
            <li>You haven&apos;t upgraded to a British Library Online Account. </li>
            <p/>
          </ul>
        </div>

        <footer class="w3-container w3-deep-orange">
          <p></p>
        </footer>
      </div>
    </div>

    <div id="NeedHelp" class="w3-modal">
      <div class="w3-modal-content w3-card-8">
        <header class="w3-container bl-theme-accent1"> 
          <span class="w3-closebtn">&times;</span>
        </header>

        <div class="w3-container">
          <h3>Customer services</h3>
          <p>If you require assistance contact British Library Customer Services:</p>
          <ul>
              <li>Tel: + 44 (0)1937 546060 (<a href="http://www.bl.uk/aboutus/contact/">More information</a>)</li>
              <li>Fax: + 44 (0)1937 546333</li>
              <li>E-mail: <a href="mailto:Customer-Services@bl.uk">Customer-Services@bl.uk</a></li>

              <p>
              <li>Postal address:</li>
              Customer Services<br/>
              The British Library<br/>
              Wetherby<br/>
              West Yorkshire<br/>
              LS23 7BQ<br/>
              United Kingdom
              </p>
              <p/>
          </ul>
        </div>

        <footer class="w3-container bl-theme-accent1">
          <p></p>
        </footer>
      </div>
    </div>
    
    <div id="MoreInfoUpgrade" class="w3-modal">
      <div class="w3-modal-content w3-card-8">
        <header class="w3-container bl-theme-accent1"> 
          <span xonclick="document.getElementById('MoreInfo').style.display='none'" 
          class="w3-closebtn">&times;</span>
        </header>

        <div class="w3-container">
          <h3>British Library Online Account</h3>

          <strong>Why have you changed the login procedure?</strong>
          <p>The Library has many services and British Library Online Account enables you to register once and then choose the services you would like to use.</p>

          <strong>I just want to order books. Why do I need to have a British Library Online Account?</strong>
          <p>All our customers, regardless of how many services they want to use, need to be registered. You only need to activate your account once and it only takes a few minutes. If you find that you need to use one of our other services in the future you won't need to register again to do so.</p>

          <strong>I don't have an email account. Do I still need to have a British Library Online Account?</strong>
          <p>Yes. You won't be able to access other Library services without an email address.</p>

          <p>For more information, please refer to our <a target="_blank" href="https://www.bl.uk/help/british-library-online-account">FAQ page</a></p>
        </div>

        <footer class="w3-container bl-theme-accent1">
          <p></p>
        </footer>
      </div>
    </div>

    <div id="MoreInfoNew" class="w3-modal">
      <div class="w3-modal-content w3-card-8">
        <header class="w3-container bl-theme-accent1"> 
          <span xonclick="document.getElementById('MoreInfo').style.display='none'" 
          class="w3-closebtn">&times;</span>
        </header>

        <div class="w3-container">
          <h3>British Library Online Account</h3>

          <strong>Why do I need a British Library Online Account?</strong>
          <p>Many British Library services require a user account or provide additional features when you are logged in.</p>

          <p>We have created a central registration service to consolidate all the different login accounts from all the different services. We will be rolling this out to all services over time.</p>

          <p>Please refer to our <a target="_blank" href="http://www.bl.uk/aboutus/terms/privacy">Privacy policy</a> and <a target="_blank" href="http://www.bl.uk/aboutus/terms">Terms of use</a> for more information on the details we collect and how we use it.</p>
        </div>
        <footer class="w3-container bl-theme-accent1">
          <p></p>
        </footer>
      </div>
    </div>

<% if(debuggingVarFlag) { %>
<pre>
<b>Debugging</b>
Shibboleth2
entityID        : <%= entityID %>    
entrySite       : <%= entrySite %>
entitySubSiteID : <%= entitySubSiteID %>    
TestLogin       : <%= request.getParameter("testlogin") %>
actionUrl       : <%= request.getAttribute("actionUrl") %>
loginFailed     : <%= request.getAttribute("loginFailed") %>
guestLogin      : <%= guestLogin %>
registerLink    : <%= registerLink %>
referringPage   : <%= referringPage %>

</pre>
<% } %>

<script>
$( document ).ready(function() {
  $("#btnNeedHelp").click(function(){ $( '#NeedHelp' ).show(); return false; });
  $("#NeedHelp").click(function(){ $( '#NeedHelp' ).hide(); return true; });

  $("#btnMoreInfoUpgrade").click(function(){ $( '#MoreInfoUpgrade' ).show(); return false; });
  $("#MoreInfoUpgrade").click(function(){ $( '#MoreInfoUpgrade' ).hide(); return true; });

  $("#btnMoreInfoNew").click(function(){ $( '#MoreInfoNew' ).show(); return false; });
  $("#MoreInfoNew").click(function(){ $( '#MoreInfoNew' ).hide(); return true; });

  $("#IncorrectCredentials").click(function(){ $( '#IncorrectCredentials' ).hide(); return true; });
  if (<%= request.getAttribute("loginFailed") %>) {    
    $( '#IncorrectCredentials' ).show();
  }
});
</script>
</body>
</html>