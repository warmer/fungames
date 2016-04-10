<html>
<head>
<title>{TITLE}</title>
<style>
td			{
	text-align	: right;
	border		: 0px solid black;
}
.reqd		{
	font-weight	: bold;
}
.opt		{
	font-style	: italic;
}
.corner		{
}
.topmove	{
}
.leftmove	{
}
.rightmove	{
}
.botmove	{
}
.block		{
	border		: 1px solid black;
}
.main_area	{
	margin		: 10px;
}
.header_bar	{
	background-color	: #FFAE00;
	border-top			: 4px solid #A98638;
	border-bottom		: 1px solid #A98638;
	color				: #0066AF;
	font-weight			: bold;
	padding				: 0px 10px 0px 10px;
	text-align			: right;
	height				: 25px;
}
.footer	{
	color				: #0066AF;
	font-weight			: bold;
	text-align			: center;
}
.spacer		{
	height		: 28px;
	width		: 28px;
}
hr			{
	border				: 1px solid #A98638;
	background-color	: #A98638;
	color				: #A98638;
}
h1			{
	font-size			: 1.5em;
	color				: #A98638;
}
h2			{
	font-size			: 1.2em;
	color				: #A98638;
}
a			{
	color				: #1A1AAF;
}
a:visited	{
	color				: #3F0099;
}
a:hover		{
	color				: #BF5F5F;
}
a:active	{
	color				: #DDA6A6;
}
body		{
	margin		: 0px;
}
</style>
<!-- BEGIN css_include -->
<link id="{css_include.ID}" rel="stylesheet" type="text/css" href="/styles/{css_include.FILE_LOCATION}" />
<!-- END css_include -->
<!-- BEGIN js_include -->
<script type='text/javascript' src='/scripts/{js_include.FILE_LOCATION}'></script>
<!-- END js_include -->
</head>
<body onLoad="{BODY_LOAD_FUNCTION}">
<div class="header_bar">
	<div style="float: left;">
	{TITLE}
	</div>
	{MESSAGE}
	<!-- BEGIN title_link -->
		<!-- BEGIN spacer_left -->
			<!-- BEGIN note -->
			<!--
				Note to self in advance - allow the spacer look to be configured
				in the TEMPLATE itself - not by the PHP program.  It's strictly
				a style issue, not dynamic, so for cleanliness, it should be
				modified only here.
				
				However, having the spacer itself should be up to the PHP program,
				which is why there's a spacer_left and a spacer_right
			-->
			<!-- END note -->
		|
		<!-- END spacer_left -->
	{title_link.UNLINKED_TEXT}
	<a href="{title_link.URL}">{title_link.TEXT}</a>
		<!-- BEGIN spacer_right -->
		|
		<!-- END spacer_right -->
	<!-- END title_link -->
</div>
