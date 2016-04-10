
<h2>{WELCOME_MESSAGE}</h2>
<!-- BEGIN error -->
<pre>
{error.ERROR}
</pre>
<!-- END error -->

<form action="register.php?" method="POST">
<table>
<tr>
	<td class="reqd">Username:</td>
	<td class="reqd"><input name="username" id="username" type="textbox" size="20" maxsize="32" /></td>
</tr>
<tr>
	<td class="reqd">Password:</td>
	<td class="reqd"><input name="password" id="password" type="password" size="20" maxsize="32" /></td>
</tr>
<tr>
	<td class="reqd">Password again:</td>
	<td class="reqd"><input name="password2" id="password2" type="password" size="20" maxsize="32" /></td>
</tr>
<tr>
	<td class="opt">Email (optional):</td>
	<td class="opt"><input name="email" id="email" type="textbox" size="20" maxsize="64" /></td>
</tr>
<tr>
	<td colspan="2" style="text-align: center;">
		<input name="pushbutton" id="pushbutton" type="submit" value="Register" />
		<input type="reset" value="Clear form" />
	</td>
</tr>
</table>
</form> 

