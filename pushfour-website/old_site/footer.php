<?php
/**
 * header.php
 *
 * Sets a default title and displays all page header information that
 * is common for all of the viewable pushfour pages
**/
// header was called out of context
if( !defined('IN_PUSHFOUR') )
{
	die("");
}

$template->set_filenames( array(
	"footer"	=> "footer.tpl",)
);


/* BEGIN links at the bottom */
$template->assign_block_vars( "footer_item", array(
	"TEXT"		=> "Rules",
	)
);
$template->assign_block_vars( "footer_item", array());
$template->assign_block_vars( "footer_item.spacer_left", array());
$template->assign_block_vars( "footer_item.link", array(
	"TEXT"		=> "About",
	"URL"		=> "about.php",
	)
);

/* END links at the bottom */

?>
