<!-- BEGIN head -->
<html>
<head>
<style>
  td      {
    border    : 0px solid black;
  }
  .corner    {
  }
  .topmove  {
  }
  .leftmove  {
  }
  .rightmove  {
  }
  .botmove  {
  }
  .block  {
    border    : 1px solid black;
  }

  .spacer    {
    height    : 28px;
    width    : 28px;
  }
</style>
<script language="JavaScript">
function returnObjByID( id )
{
    if (document.getElementById)
        var returnVar = document.getElementById(id);
    else if (document.all)
        var returnVar = document.all[id];
    else if (document.layers)
        var returnVar = document.layers[id];
    return returnVar;
}

// AJAX functionality
function GetXmlHttpObject()
{
  var xmlHttp = null;
  try
  {
    // Firefox, Opera 8.0+, Safari
    xmlHttp = new XMLHttpRequest();
  }
  catch (e)
  {
    // Internet Explorer
    try
    {
      xmlHttp = new ActiveXObject("Msxml2.XMLHTTP");
    }
    catch (e)
    {
      xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
  }
  return xmlHttp;
}

/**
 * @name fb()
 * @param scol start column
 * @param ecol end column
 * @param srow start row
 * @param erow end row
**/
function fb( scol, ecol, srow, erow, color)
{
  for( var x = srow; x <= erow; x++ )
  {
    for( var y = scol; y <= ecol; y++ )
    {
      if( td = returnObjByID( y + "-" + x ) )
      {
        td.bgColor = color;
      }
      else
      {
        break;
      }
    } // END column filling
  } // END row filling
} // END fill_blocks function

function glow( item, color )
{
  var td = returnObjByID( item );
  td.bgColor = color;
}//END glow function


</script>
</head>
<body>
<!-- END head -->
<table>
  <tr>
    <td class="corner"><img src="trans.gif" class="spacer" /></td>
    <!-- BEGIN top_row -->
      <td class="topmove" id="t-{top_row.ID}"><img src="trans.gif" class="spacer"
      <!-- BEGIN t_js_actions -->
      onMouseOver="fb({top_row.ID},{top_row.ID},0,{top_row.TEND},'#aaaacc');glow('t-{top_row.ID}','{PIECE_COLOR}');" onMouseOut="fb({top_row.ID},{top_row.ID},0,{top_row.TEND},'#ffffff');glow('t-{top_row.ID}','{CLEAR_COLOR}');" onClick="get_board('game={GAMEID}&player={PLAYERID}&side=t&channel={top_row.ID}');"
      <!-- END t_js_actions -->
      /></td>
    <!-- END top_row -->
    <td class="corner"><img src="trans.gif" class="spacer" /></td>
  </tr>
  <!-- BEGIN row -->
  <tr>
    <td class="leftmove" id="l-{row.ID}"><img src="trans.gif" class="spacer"
    <!-- BEGIN l_js_actions -->
    onMouseOver="fb(0,{row.LEND},{row.ID},{row.ID},'#aaaacc');glow('l-{row.ID}','{PIECE_COLOR}');" onMouseOut="fb(0,{row.LEND},{row.ID},{row.ID},'#ffffff');glow('l-{row.ID}','{CLEAR_COLOR}');" onClick="get_board('game={GAMEID}&player={PLAYERID}&side=l&channel={row.ID}');"
    <!-- END l_js_actions -->
    /></td>
    <!-- BEGIN block -->
      <td class="block" id="{row.block.ID}" style="{row.block.STYLE}"><img src="trans.gif" class="spacer" /></td>
    <!-- END block -->
    <td class="rightmove" id="r-{row.ID}"><img src="trans.gif" class="spacer"
    <!-- BEGIN r_js_actions -->
    onMouseOver="fb({row.RSTART},{COLS},{row.ID},{row.ID},'#aaaacc');glow('r-{row.ID}','{PIECE_COLOR}');" onMouseOut="fb({row.RSTART},{COLS},{row.ID},{row.ID},'#ffffff');glow('r-{row.ID}','{CLEAR_COLOR}');" onClick="get_board('game={GAMEID}&player={PLAYERID}&side=r&channel={row.ID}');"
    <!-- END r_js_actions -->
    /></td>
  </tr>
  <!-- END row -->
  <tr>
    <td class="corner"><img src="trans.gif" class="spacer" /></td>
    <!-- BEGIN bottom_row -->
      <td class="botmove" id="b-{bottom_row.ID}"><img src="trans.gif" class="spacer"
      <!-- BEGIN b_js_actions -->
      onMouseOver="fb({bottom_row.ID},{bottom_row.ID},{bottom_row.BSTART},{ROWS},'#aaaacc');glow('b-{bottom_row.ID}','{PIECE_COLOR}');" onMouseOut="fb({bottom_row.ID},{bottom_row.ID},{bottom_row.BSTART},{ROWS},'#ffffff');glow('b-{bottom_row.ID}','{CLEAR_COLOR}');" onClick="get_board('game={GAMEID}&player={PLAYERID}&side=b&channel={bottom_row.ID}');"
      <!-- END b_js_actions -->
      /></td>
    <!-- END bottom_row -->
    <td class="corner"><img src="trans.gif" class="spacer" /></td>
  </tr>
</table>

<!-- BEGIN message -->
<div class="{message.CLASS}">
{message.MESSAGE}
</div>
<!-- END message -->

<!-- BEGIN foot -->
</body>
</html>
<!-- END foot -->
