/*
 * Generated by the Jasper component of Apache Tomcat
 * Version: Apache Tomcat/7.0.54
 * Generated at: 2015-07-20 05:00:09 UTC
 * Note: The last modified time of this file was set to
 *       the last modified time of the source file after
 *       generation to assist with modification tracking.
 */
package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import org.baraza.web.*;
import org.baraza.xml.BElement;

public final class application_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static final javax.servlet.jsp.JspFactory _jspxFactory =
          javax.servlet.jsp.JspFactory.getDefaultFactory();

  private static java.util.Map<java.lang.String,java.lang.Long> _jspx_dependants;

  private javax.el.ExpressionFactory _el_expressionfactory;
  private org.apache.tomcat.InstanceManager _jsp_instancemanager;

  public java.util.Map<java.lang.String,java.lang.Long> getDependants() {
    return _jspx_dependants;
  }

  public void _jspInit() {
    _el_expressionfactory = _jspxFactory.getJspApplicationContext(getServletConfig().getServletContext()).getExpressionFactory();
    _jsp_instancemanager = org.apache.jasper.runtime.InstanceManagerFactory.getInstanceManager(getServletConfig());
  }

  public void _jspDestroy() {
  }

  public void _jspService(final javax.servlet.http.HttpServletRequest request, final javax.servlet.http.HttpServletResponse response)
        throws java.io.IOException, javax.servlet.ServletException {

    final javax.servlet.jsp.PageContext pageContext;
    javax.servlet.http.HttpSession session = null;
    final javax.servlet.ServletContext application;
    final javax.servlet.ServletConfig config;
    javax.servlet.jsp.JspWriter out = null;
    final java.lang.Object page = this;
    javax.servlet.jsp.JspWriter _jspx_out = null;
    javax.servlet.jsp.PageContext _jspx_page_context = null;


    try {
      response.setContentType("text/html");
      pageContext = _jspxFactory.getPageContext(this, request, response,
      			null, true, 8192, true);
      _jspx_page_context = pageContext;
      application = pageContext.getServletContext();
      config = pageContext.getServletConfig();
      session = pageContext.getSession();
      out = pageContext.getOut();
      _jspx_out = out;

      out.write("<!DOCTYPE html>\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\r\n");

	ServletContext context = getServletContext();
	String dbconfig = "java:/comp/env/jdbc/database";
	String xmlcnf = "application.xml";
	if(request.getParameter("logoff") == null) {
		session.setAttribute("xmlcnf", xmlcnf);
	} else {
		session.removeAttribute("xmlcnf");
		session.invalidate();
  	}

	String ps = System.getProperty("file.separator");
	String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
	String reportPath = context.getRealPath("reports") + ps;
	String projectDir = context.getInitParameter("projectDir");
	if(projectDir != null) {
		xmlfile = projectDir + ps + "configs" + ps + xmlcnf;
		reportPath = projectDir + ps + "reports" + ps;
	}

	String userIP = request.getRemoteAddr();
	String userName = request.getRemoteUser();

	BWeb web = new BWeb(dbconfig, xmlfile);
	web.setUser(userIP, userName);
	web.init(request);
	web.setMainPage("application.jsp");

	String entryformid = null;
	String action = request.getParameter("action");
	String value = request.getParameter("value");
	String post = request.getParameter("post");
	String process = request.getParameter("process");
	String actionprocess = request.getParameter("actionprocess");
	if(actionprocess != null) process = "actionProcess";
	String reportexport = request.getParameter("reportexport");
	String excelexport = request.getParameter("excelexport");

	String fieldTitles = web.getFieldTitles();
	String auditTable = null;

	String opResult = null;
	if(process != null) {
		if(process.equals("actionProcess")) {
			opResult = web.setOperation(actionprocess, request);
		} else if(process.equals("FormAction")) {
			String actionKey = request.getParameter("actionkey");
			opResult = web.setOperation(actionKey, request);
		} else if(process.equals("Update")) {
			web.updateForm(request);
		} else if(process.equals("Delete")) {
			web.deleteForm(request);
		} else if(process.equals("Submit")) {
			web.submitGrid(request);
		} else if(process.equals("Check All")) {
			web.setSelectAll();
		} else if(process.equals("Audit")) {
			auditTable = web.getAudit();
		}
	}

	if(excelexport != null) reportexport = excelexport;
	if(reportexport != null) {
		out.println("	<script>");
		out.println("		window.open('show_report?report=" + reportexport + "');");
		out.println("	</script>");
	}

      out.write("\r\n");
      out.write("\r\n");
      out.write("<!--[if IE 8]> <html lang=\"en\" class=\"ie8 no-js\"> <![endif]-->\r\n");
      out.write("<!--[if IE 9]> <html lang=\"en\" class=\"ie9 no-js\"> <![endif]-->\r\n");
      out.write("<!--[if !IE]><!-->\r\n");
      out.write("<html lang=\"en\" class=\"no-js\">\r\n");
      out.write("<!--<![endif]-->\r\n");
      out.write("<!-- BEGIN HEAD -->\r\n");
      out.write("<head>\r\n");
      out.write("\t<meta charset=\"utf-8\"/>\r\n");
      out.write("\t<title>");
      out.print( pageContext.getServletContext().getInitParameter("web_title") );
      out.write("</title>\r\n");
      out.write("\t<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">\r\n");
      out.write("\t<meta content=\"width=device-width, initial-scale=1\" name=\"viewport\"/>\r\n");
      out.write("\t<meta content=\"\" name=\"description\"/>\r\n");
      out.write("\t<meta content=\"\" name=\"author\"/>\r\n");
      out.write("\t<!-- BEGIN GLOBAL MANDATORY STYLES -->\r\n");
      out.write("\t<link href=\"http://fonts.googleapis.com/css?family=Open+Sans:400,300,600,700&subset=all\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/font-awesome/css/font-awesome.min.css\"  rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/simple-line-icons/simple-line-icons.min.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/bootstrap/css/bootstrap.min.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/uniform/css/uniform.default.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/bootstrap-switch/css/bootstrap-switch.min.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<!-- END GLOBAL MANDATORY STYLES -->\r\n");
      out.write("\t<!-- BEGIN PAGE LEVEL PLUGIN STYLES -->\r\n");
      out.write("\t<link href=\"./assets/global/plugins/bootstrap-daterangepicker/daterangepicker-bs3.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/fullcalendar/fullcalendar.min.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/jqvmap/jqvmap/jqvmap.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/morris/morris.css\" rel=\"stylesheet\" type=\"text/css\">\r\n");
      out.write("\t<!-- END PAGE LEVEL PLUGIN STYLES -->\r\n");
      out.write("\t<!-- BEGIN PAGE STYLES -->\r\n");
      out.write("\t<link href=\"./assets/admin/pages/css/tasks.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/plugins/clockface/css/clockface.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n");
      out.write("\t<link href=\"./assets/global/plugins/bootstrap-datepicker/css/bootstrap-datepicker3.min.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n");
      out.write("\t<link href=\"./assets/global/plugins/bootstrap-timepicker/css/bootstrap-timepicker.min.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n");
      out.write("\t<link href=\"./assets/global/plugins/bootstrap-colorpicker/css/colorpicker.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n");
      out.write("\t<link href=\"./assets/global/plugins/bootstrap-daterangepicker/daterangepicker-bs3.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n");
      out.write("\t<link href=\"./assets/global/plugins/bootstrap-datetimepicker/css/bootstrap-datetimepicker.min.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n");
      out.write("\t<link href=\"./assets/global/plugins/jquery-tags-input/jquery.tagsinput.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("    <link href=\"./assets/global/plugins/select2/select2.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n");
      out.write("    <link href=\"./assets/global/plugins/jquery-multi-select/css/multi-select.css\" rel=\"stylesheet\" type=\"text/css\" />\r\n");
      out.write("\r\n");
      out.write("\r\n");
      out.write("\t<!-- END PAGE STYLES -->\r\n");
      out.write("\t<!-- BEGIN THEME STYLES -->\r\n");
      out.write("\t<!-- DOC: To use 'rounded corners' style just load 'components-rounded.css' stylesheet instead of 'components.css' in the below style tag -->\r\n");
      out.write("\t<link href=\"./assets/global/css/components-rounded.css\" id=\"style_components\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/global/css/plugins.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/admin/layout4/css/layout.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("\t<link href=\"./assets/admin/layout4/css/themes/light.css\" rel=\"stylesheet\" type=\"text/css\" id=\"style_color\"/>\r\n");
      out.write("\t\r\n");
      out.write("\t<!-- END THEME STYLES -->\r\n");
      out.write("\t<link rel=\"shortcut icon\" href=\"favicon.ico\"/>\r\n");
      out.write("\r\n");
      out.write("\t<link rel=\"stylesheet\" type=\"text/css\" media=\"screen\" href=\"assets/global/plugins/jquery-ui/jquery-ui-1.10.3.custom.min.css\" />\r\n");
      out.write("    <link href=\"./jquery-ui-1.11.4.custom/jquery-ui.theme.min.css\" rel=\"search\" type=\"text/css\" />\r\n");
      out.write("    <link rel=\"stylesheet\" type=\"text/css\" media=\"screen\" href=\"assets/jqgrid/css/ui.jqgrid.css\" />\r\n");
      out.write("\r\n");
      out.write("    <link href=\"./assets/admin/layout4/css/custom.css\" rel=\"stylesheet\" type=\"text/css\"/>\r\n");
      out.write("    \r\n");
      out.write("<!--\r\n");
      out.write("    <link href=\"jquery-ui-1.11.4.custom/jquery-ui.min.css\" rel=\"search\" type=\"text/css\" />\r\n");
      out.write("    <link href=\"jquery-ui-1.11.4.custom/jquery-ui.structure.min.css\" rel=\"search\" type=\"text/css\" />\r\n");
      out.write("    <link href=\"jquery-ui-1.11.4.custom/jquery-ui.theme.min.css\" rel=\"search\" type=\"text/css\" />\r\n");
      out.write("-->\r\n");
      out.write("</head>\r\n");
      out.write("<!-- END HEAD -->\r\n");
      out.write("<!-- BEGIN BODY -->\r\n");
      out.write("<!-- DOC: Apply \"page-header-fixed-mobile\" and \"page-footer-fixed-mobile\" class to body element to force fixed header or footer in mobile devices -->\r\n");
      out.write("<!-- DOC: Apply \"page-sidebar-closed\" class to the body and \"page-sidebar-menu-closed\" class to the sidebar menu element to hide the sidebar by default -->\r\n");
      out.write("<!-- DOC: Apply \"page-sidebar-hide\" class to the body to make the sidebar completely hidden on toggle -->\r\n");
      out.write("<!-- DOC: Apply \"page-sidebar-closed-hide-logo\" class to the body element to make the logo hidden on sidebar toggle -->\r\n");
      out.write("<!-- DOC: Apply \"page-sidebar-hide\" class to body element to completely hide the sidebar on sidebar toggle -->\r\n");
      out.write("<!-- DOC: Apply \"page-sidebar-fixed\" class to have fixed sidebar -->\r\n");
      out.write("<!-- DOC: Apply \"page-footer-fixed\" class to the body element to have fixed footer -->\r\n");
      out.write("<!-- DOC: Apply \"page-sidebar-reversed\" class to put the sidebar on the right side -->\r\n");
      out.write("<!-- DOC: Apply \"page-full-width\" class to the body element to have full width page without the sidebar menu -->\r\n");
      out.write("<body class=\"page-header-fixed page-sidebar-closed-hide-logo page-sidebar-closed-hide-logo page-footer-fixed\">\r\n");
      out.write("\r\n");
      out.write("<!-- BEGIN HEADER -->\r\n");
      out.write("<div class=\"page-header navbar navbar-fixed-top\">\r\n");
      out.write("\t<!-- BEGIN HEADER INNER -->\r\n");
      out.write("\t<div class=\"page-header-inner\">\r\n");
      out.write("\t\t<!-- BEGIN LOGO -->\r\n");
      out.write("\t\t<div class=\"page-logo\">\r\n");
      out.write("\t\t\t<a href=\"index.jsp?xml=hr.xml\">\r\n");
      out.write("\t\t\t<img src=\"./assets/logos/logo_header.png\" alt=\"logo\" style=\"margin: 20px 10px 0 10px; width: 107px;\" class=\"logo-default\"/>\r\n");
      out.write("\t\t\t</a>\r\n");
      out.write("\t\t\t<div class=\"menu-toggler sidebar-toggler\">\r\n");
      out.write("\t\t\t\t<!-- DOC: Remove the above \"hide\" to enable the sidebar toggler button on header -->\r\n");
      out.write("\t\t\t</div>\r\n");
      out.write("\t\t</div>\r\n");
      out.write("\t\t<!-- END LOGO -->\r\n");
      out.write("\t\t<!-- BEGIN RESPONSIVE MENU TOGGLER -->\r\n");
      out.write("\t\t<a href=\"javascript:;\" class=\"menu-toggler responsive-toggler\" data-toggle=\"collapse\" data-target=\".navbar-collapse\">\r\n");
      out.write("\t\t</a>\r\n");
      out.write("\t\t<!-- END RESPONSIVE MENU TOGGLER -->\r\n");
      out.write("\r\n");
      out.write("\t\t<!-- BEGIN PAGE TOP -->\r\n");
      out.write("\t\t<div class=\"page-top\">\r\n");
      out.write("\r\n");
      out.write("\t\t\t<!-- BEGIN TOP NAVIGATION MENU -->\r\n");
      out.write("\t\t\t<div class=\"top-menu\">\r\n");
      out.write("\t\t\t\t<ul class=\"nav navbar-nav pull-right\">\r\n");
      out.write("\t\t\t\t\t<!-- BEGIN USER LOGIN DROPDOWN -->\r\n");
      out.write("\t\t\t\t\t<!-- DOC: Apply \"dropdown-dark\" class after below \"dropdown-extended\" to change the dropdown styte -->\r\n");
      out.write("\t\t\t\t\t<li class=\"dropdown dropdown-user dropdown-dark\">\r\n");
      out.write("\t\t\t\t\t\t<a href=\"javascript:;\" class=\"dropdown-toggle\" data-toggle=\"dropdown\" data-hover=\"dropdown\" data-close-others=\"true\">\r\n");
      out.write("\t\t\t\t\t\t<span class=\"username username-hide-on-mobile\"> </span>\r\n");
      out.write("\t\t\t\t\t\t<!-- DOC: Do not remove below empty space(&nbsp;) as its purposely used -->\r\n");
      out.write("\t\t\t\t\t\t<img alt=\"\" class=\"img-circle\" src=\"./assets/admin/layout4/img/avatar.png\"/>\r\n");
      out.write("\t\t\t\t\t\t</a>\r\n");
      out.write("\t\t\t\t\t</li>\r\n");
      out.write("\t\t\t\t\t<!-- END USER LOGIN DROPDOWN -->\r\n");
      out.write("\t\t\t\t</ul>\r\n");
      out.write("\t\t\t</div>\r\n");
      out.write("\t\t\t<!-- END TOP NAVIGATION MENU -->\r\n");
      out.write("\t\t</div>\r\n");
      out.write("\t\t<!-- END PAGE TOP -->\r\n");
      out.write("\t</div>\r\n");
      out.write("\t<!-- END HEADER INNER -->\r\n");
      out.write("</div>\r\n");
      out.write("\r\n");
      out.write("<!-- END HEADER -->\r\n");
      out.write("\r\n");
      out.write("<div class=\"clearfix\"></div>\r\n");
      out.write("\r\n");
      out.write("<!-- BEGIN CONTAINER -->\r\n");
      out.write("<div class=\"page-container\">\r\n");
      out.write("\t<!-- BEGIN CONTENT -->\r\n");
      out.write("\t<div class=\"page-content-wrapper\">\r\n");
      out.write("\t\t<div class=\"page-content\">\r\n");
      out.write("\r\n");
      out.write("\t\t\t<!-- BEGIN PAGE CONTENT-->\r\n");
      out.write("\t\t\t<form id=\"baraza\" name=\"baraza\" method=\"post\" action=\"application.jsp\" data-confirm-send=\"false\" data-ajax=\"false\">\r\n");
      out.write("\t\t\t\t");
      out.print( web.getHiddenValues() );
      out.write("\r\n");
      out.write("\t\t\t<div class=\"row\">\r\n");
      out.write("\t\t\t\t<div class=\"col-md-12\" >\r\n");
      out.write("\t\t\t\t\t<div class=\"tabbable tabbable-tabdrop\">");
      out.print( web.getTabs() );
      out.write("</div>\r\n");
      out.write("\t\t\t\t\t");
 if(opResult != null) out.println("<div style='color:#FF0000'>" + opResult + "</div>"); 
      out.write("\r\n");
      out.write("\t\t\t\t\t");
      out.print( web.getSaveMsg() );
      out.write("\r\n");
      out.write("\r\n");
      out.write("\t\t\t\t\t<div class=\"portlet box purple\">\r\n");
      out.write("\t\t\t\t\t\t<div class=\"portlet-title\">\r\n");
      out.write("\t\t\t\t\t\t\t<div class=\"caption\">\r\n");
      out.write("\t\t\t\t\t\t\t\t<i class=\"fa fa-cogs\"></i>");
      out.print( web.getViewName() );
      out.write("\r\n");
      out.write("\t\t\t\t\t\t\t</div>\r\n");
      out.write("\t\t\t\t\t\t\t<div class=\"tools\">\r\n");
      out.write("\t\t\t\t\t\t\t\t<a href=\"javascript:;\" class=\"collapse\">\r\n");
      out.write("\t\t\t\t\t\t\t\t</a>\r\n");
      out.write("\t\t\t\t\t\t\t\t<a href=\"javascript:;\" class=\"reload\">\r\n");
      out.write("\t\t\t\t\t\t\t\t</a>\r\n");
      out.write("\t\t\t\t\t\t\t\t<a href=\"javascript:;\" class=\"remove\">\r\n");
      out.write("\t\t\t\t\t\t\t\t</a>\r\n");
      out.write("\t\t\t\t\t\t\t</div>\r\n");
      out.write("\t\t\t\t\t\t\t");
      out.print( web.getButtons() );
      out.write("\r\n");
      out.write("\t\t\t\t\t\t</div>\r\n");
      out.write("\t\t\t\t\t\t<div class=\"portlet-body\">\r\n");
      out.write("\t\t\t\t\t\t\t<div class=\"table-scrollable\">\r\n");
      out.write("\t\t\t\t\t\t\t\t");
      out.print( web.getBody(request, reportPath) );
      out.write("\r\n");
      out.write("\t\t\t\t\t\t\t</div>\r\n");
      out.write("\t\t\t\t\t\t</div>\r\n");
      out.write("\r\n");
      out.write("\t\t\t\t\t\t");
      out.print( web.getFilters() );
      out.write("\r\n");
      out.write("\r\n");
      out.write("\t\t\t\t\t\t");
 String actionOp = web.getOperations();
						if(actionOp != null) {	
      out.write("\r\n");
      out.write("\t\t\t\t\t\t\t\r\n");
      out.write("                               \r\n");
      out.write("                            <div class=\"row\" style=\"\">\r\n");
      out.write("                                <div class=\"col-md-2\" >\r\n");
      out.write("                                    ");
      out.print( actionOp );
      out.write("\r\n");
      out.write("                                </div>\r\n");
      out.write("                                    \r\n");
      out.write("                                <div class=\"col-md-1\" >\r\n");
      out.write("                                    <button type=\"button\" id=\"btnAction\" name=\"process\" value=\"Action\" class=\"btn btn-sm green\">Action</button>\r\n");
      out.write("                                </div>\r\n");
      out.write("                            </div>\r\n");
      out.write("\t\t\t\t\t\t  \t\r\n");
      out.write("\t\t\t\t\t\t");
	} 
      out.write("\r\n");
      out.write("\r\n");
      out.write("\t\t\t\t\t\t");
 if(fieldTitles != null) { 
      out.write("\r\n");
      out.write("\t\t\t\t\t\t\t<table class=\"table\" style=\"margin-bottom:0px;\"><tr>\r\n");
      out.write("\t\t\t\t\t\t\t\t<td >");
      out.print( fieldTitles );
      out.write("</td>\r\n");
      out.write("\t\t\t\t\t\t\t\t<td >\r\n");
      out.write("\t\t\t\t\t\t\t\t\t<select class='fnctcombobox form-control' name='filtertype' id='filtertype'>\r\n");
      out.write("\t\t\t\t\t\t\t\t\t\t<option value='ilike'>Contains (case insensitive)</option>\r\n");
      out.write("\t\t\t\t\t\t\t\t\t\t<option value='like'>Contains (case sensitive)</option>\r\n");
      out.write("\t\t\t\t\t\t\t\t\t\t<option value='='>Equal to</option>\r\n");
      out.write("\t\t\t\t\t\t\t\t\t\t<option value='>'>Greater than</option>\r\n");
      out.write("\t\t\t\t\t\t\t\t\t\t<option value='<'>Less than</option>\r\n");
      out.write("\t\t\t\t\t\t\t\t\t\t<option value='<='>Less or Equal</option>\r\n");
      out.write("\t\t\t\t\t\t\t\t\t\t<option value='>='>Greater or Equal</option>\r\n");
      out.write("\t\t\t\t\t\t\t\t\t</select>\r\n");
      out.write("\t\t\t\t\t\t\t\t</td>\r\n");
      out.write("\t\t\t\t\t\t\t\t<td ><input class=\"form-control\" name=\"filtervalue\" type=\"text\" id=\"filtervalue\" /></td>\r\n");
      out.write("\t\t\t\t\t\t\t\t<td ><input class=\"form-control\" name='filterand' id='filterand' type='checkbox'/> And</td>\r\n");
      out.write("\t\t\t\t\t\t\t\t<td ><input class=\"form-control\" name='filteror' id='filteror' type='checkbox' /> Or</td>\r\n");
      out.write("\t\t\t\t\t\t\t\t<td ><button type=\"button\" class=\"form-control\" name=\"btSearch\" id=\"btSearch\" value=\"Search\">Search</button></td>\r\n");
      out.write("\t\t\t\t\t\t\t\t<td ></td>\r\n");
      out.write("\t\t\t\t\t\t\t</tr></table>\r\n");
      out.write("\t\t\t\t\t\t");
 } 
      out.write("\r\n");
      out.write("\r\n");
      out.write("\t\t\t\t\t\t");
      out.print( web.showFooter() );
      out.write("\r\n");
      out.write("\t\t\t\t\t</div>\r\n");
      out.write("\t\t\t\t</div>\r\n");
      out.write("\t\t\t</div>\r\n");
      out.write("\t\t\t</form>\r\n");
      out.write("\t\t</div>\r\n");
      out.write("\t</div>\r\n");
      out.write("\t<!-- END CONTENT -->\r\n");
      out.write("</div>\r\n");
      out.write("<!-- END CONTAINER -->\r\n");
      out.write("<!-- BEGIN FOOTER -->\r\n");
      out.write("<div class=\"page-footer\">\r\n");
      out.write("\t<div class=\"page-footer-inner\">\r\n");
      out.write("\t\t2015 &copy; Open Baraza. <a href=\"http://dewcis.com\">Dew Cis Solutions Ltd.</a> All Rights Reserved\r\n");
      out.write("\t</div>\r\n");
      out.write("\t<div class=\"scroll-to-top\">\r\n");
      out.write("\t\t<i class=\"icon-arrow-up\"></i>\r\n");
      out.write("\t</div>\r\n");
      out.write("</div>\r\n");
      out.write("\r\n");
      out.write("<!-- END FOOTER -->\r\n");
      out.write("<!-- BEGIN JAVASCRIPTS(Load javascripts at bottom, this will reduce page load time) -->\r\n");
      out.write("<!-- BEGIN CORE PLUGINS -->\r\n");
      out.write("<!--[if lt IE 9]>\r\n");
      out.write("<script src=\"./assets/global/plugins/respond.min.js\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/excanvas.min.js\"></script> \r\n");
      out.write("<![endif]-->\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery-migrate.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<!-- IMPORTANT! Load jquery-ui.min.js before bootstrap.min.js to fix bootstrap tooltip conflict with jquery ui tooltip -->\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery-ui/jquery-ui.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<!--<script src=\"./jquery-ui-1.11.4.custom/jquery-ui.min.js\"  type=\"text/javascript\"></script>-->\r\n");
      out.write("<script src=\"./assets/global/plugins/bootstrap/js/bootstrap.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/bootstrap-hover-dropdown/bootstrap-hover-dropdown.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery-slimscroll/jquery.slimscroll.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery.blockui.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery.cokie.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/uniform/jquery.uniform.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/bootstrap-switch/js/bootstrap-switch.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<!-- END CORE PLUGINS -->\r\n");
      out.write("<!-- BEGIN PAGE LEVEL PLUGINS -->\r\n");
      out.write("<script src=\"./assets/global/plugins/jqvmap/jqvmap/jquery.vmap.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.russia.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.world.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.europe.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.germany.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.usa.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jqvmap/jqvmap/data/jquery.vmap.sampledata.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/bootstrap-datetimepicker/js/bootstrap-datetimepicker.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/bootstrap-datepicker/js/bootstrap-datepicker.min.js\" type=\"text/javascript\" ></script>\r\n");
      out.write("\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery-inputmask/jquery.inputmask.bundle.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/select2/select2.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("\r\n");
      out.write("<!-- IMPORTANT! fullcalendar depends on jquery-ui.min.js for drag & drop support -->\r\n");
      out.write("<script src=\"./assets/global/plugins/morris/morris.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/morris/raphael-min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery.sparkline.min.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<!-- END PAGE LEVEL PLUGINS -->\r\n");
      out.write("<!-- BEGIN PAGE LEVEL SCRIPTS -->\r\n");
      out.write("<script src=\"./assets/global/scripts/metronic.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/admin/layout4/scripts/layout.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/admin/layout4/scripts/demo.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/admin/pages/scripts/index3.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/admin/pages/scripts/tasks.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/admin/pages/scripts/components-pickers.js\" type=\"text/javascript\"></script>\r\n");
      out.write("<script src=\"./assets/global/plugins/jquery-multi-select/js/jquery.multi-select.js\" type=\"text/javascript\" ></script>\r\n");
      out.write("\r\n");
      out.write("<!-- END PAGE LEVEL SCRIPTS -->\r\n");
      out.write("\r\n");
      out.write("<script type=\"text/javascript\" src=\"./assets/jqgrid/js/i18n/grid.locale-en.js\"></script>\r\n");
      out.write("<script type=\"text/javascript\" src=\"./assets/jqgrid/js/jquery.jqGrid.min.js\"></script>\r\n");
      out.write("\r\n");
      out.write("\t<script>\r\n");
      out.write("\t\tjQuery(document).ready(function() {    \r\n");
      out.write("            \r\n");
      out.write("\t\t   Metronic.init(); // init metronic core componets\r\n");
      out.write("\t\t   Layout.init(); // init layout\r\n");
      out.write("\t\t   //Demo.init(); // init demo features \r\n");
      out.write("\t\t   //Index.init(); // init index page\r\n");
      out.write("\t\t   //Tasks.initDashboardWidget(); // init tash dashboard widget  \r\n");
      out.write("\t\t   //ComponentsPickers.init();\r\n");
      out.write("            \r\n");
      out.write("            $('.date-picker').datepicker();\r\n");
      out.write("            \r\n");
      out.write("            //alert($(\".mask_currency\").length);\r\n");
      out.write("            \r\n");
      out.write("            $('.multi-select').multiSelect();\r\n");
      out.write("            \r\n");
      out.write("            /*$(\".mask_currency\").each(function(i, obj){\r\n");
      out.write("                var mask = $(this).attr('data-mask');\r\n");
      out.write("                $(this).inputmask(mask, {\r\n");
      out.write("                    numericInput: true\r\n");
      out.write("                });\r\n");
      out.write("            });*/\r\n");
      out.write("\r\n");
      out.write("            $('.select2me').select2({\r\n");
      out.write("                placeholder: \"Select an option\",\r\n");
      out.write("                allowClear: true\r\n");
      out.write("            });\r\n");
      out.write("\t\t});\r\n");
      out.write("\t</script>\r\n");
      out.write("\r\n");
      out.write("\t<script>\r\n");
      out.write("\t");
 if(web.isGrid()) { 
      out.write("\r\n");
      out.write("\t\tvar jqcf = ");
      out.print( web.getJSONHeader() );
      out.write(";\r\n");
      out.write("\r\n");
      out.write("        jqcf.rowNum = 20;\r\n");
      out.write("        jqcf.height = 300;\r\n");
      out.write("\t\tjqcf.autoencode = false;\r\n");
      out.write("        \r\n");
      out.write("        ");
 if(actionOp != null) {	
      out.write("\r\n");
      out.write("\t\t  jqcf.multiselect = true;\r\n");
      out.write("\t    ");
 } 
      out.write("\r\n");
      out.write("\r\n");
      out.write("\t\tjQuery(\"#jqlist\").jqGrid(jqcf);\r\n");
      out.write("\t\tjQuery(\"#jqlist\").jqGrid(\"navGrid\", \"#jqpager\", {edit:false,add:false,del:false});\r\n");
      out.write("\r\n");
      out.write("        $('#btSearch').click(function(){\r\n");
      out.write("            var filtername = $(\"#filtername\").val();\r\n");
      out.write("\t\t\tvar filtertype = $(\"#filtertype\").val();\r\n");
      out.write("\t\t\tvar filtervalue = $(\"#filtervalue\").val();\r\n");
      out.write("\t\t\tvar filterand = $(\"#filterand\").is(':checked');\r\n");
      out.write("\t\t\tvar filteror = $(\"#filteror\").is(':checked');\r\n");
      out.write("\r\n");
      out.write("\t\t\tconsole.log(filterand);\r\n");
      out.write("\t\t\t$.post(\"ajax?fnct=filter\", {filtername: filtername, filtertype: filtertype, filtervalue: filtervalue, filterand: filterand, filteror: filteror}, function(data){\r\n");
      out.write("\t\t\t\t$('#jqlist').trigger('reloadGrid');\r\n");
      out.write("            });\r\n");
      out.write("\t\t});\r\n");
      out.write("        \r\n");
      out.write("\t\t$(\"#jqlist\").dblclick(function(){\r\n");
      out.write("\t\t\tvar rowId =$(\"#jqlist\").jqGrid('getGridParam','selrow');  \r\n");
      out.write("\t\t\tvar rowData = jQuery(\"#jqlist\").getRowData(rowId);\r\n");
      out.write("\t\t\tvar colData = rowData['CL'];\r\n");
      out.write("\r\n");
      out.write("\t\t\tlocation.replace(colData);\r\n");
      out.write("\t\t});                                 \r\n");
      out.write("        \r\n");
      out.write("        $('#btnAction').click(function(){\r\n");
      out.write("            var operation = $(\"#operation\").val();\r\n");
      out.write("\r\n");
      out.write("            var $grid = $(\"#jqlist\"), selIds = $grid.jqGrid(\"getGridParam\", \"selarrrow\"), i, n, cellValues = [];\r\n");
      out.write("            for (i = 0, n = selIds.length; i < n; i++) {\r\n");
      out.write("                var coldata = $grid.jqGrid(\"getCell\", selIds[i], \"CL\");\r\n");
      out.write("                var begin = coldata.lastIndexOf(\"=\");\r\n");
      out.write("                var end = coldata.length;\r\n");
      out.write("                var id = coldata.substring(begin + 1, end);\r\n");
      out.write("                cellValues.push(id);\r\n");
      out.write("            }\r\n");
      out.write("            if(cellValues.join(\",\") == \"\"){\r\n");
      out.write("                alert('No row Selected');\r\n");
      out.write("            } else {\r\n");
      out.write("                //alert(cellValues.join(\",\")); \r\n");
      out.write("                //cellValues.join(\",\") returns 1,2,3,4\r\n");
      out.write("                $.post(\"ajax?fnct=operation&id=\" + operation, {ids: cellValues.join(\",\")}, function(data) {\r\n");
      out.write("\t\t\t\t\t$('#jqlist').trigger('reloadGrid');\r\n");
      out.write("                }, \"JSON\");\r\n");
      out.write("\r\n");
      out.write("            }            \r\n");
      out.write("        });\r\n");
      out.write("\t");
 } 
      out.write("\r\n");
      out.write("\t</script>\r\n");
      out.write("<!-- END JAVASCRIPTS -->\r\n");
      out.write("</body>\r\n");
      out.write("<!-- END BODY -->\r\n");
      out.write("</html>\r\n");
      out.write("\r\n");
 	web.close(); 
      out.write('\r');
      out.write('\n');
    } catch (java.lang.Throwable t) {
      if (!(t instanceof javax.servlet.jsp.SkipPageException)){
        out = _jspx_out;
        if (out != null && out.getBufferSize() != 0)
          try { out.clearBuffer(); } catch (java.io.IOException e) {}
        if (_jspx_page_context != null) _jspx_page_context.handlePageException(t);
        else throw new ServletException(t);
      }
    } finally {
      _jspxFactory.releasePageContext(_jspx_page_context);
    }
  }
}