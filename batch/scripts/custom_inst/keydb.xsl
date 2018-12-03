<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" />

<xsl:template match="/">
<html xsl:version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<head>
<title>SAPinst Persistence XML (kdb-format) Viewer</title>
<style>
	body {font: normal normal normal x-small verdana,serif;}

	td {font: normal normal normal xx-small verdana,serif;
		vertical-align:top;}

	.link {
		vertical-align:top;
		cursor: hand;}

</style>
<SCRIPT language="JavaScript">
<![CDATA[
	function DivElementClick (divElementId, imgElementId)
	{
		// if (imgElement) alert (document.images[imgElement.id].src);
		var divElement = document.getElementById(divElementId);
		var imgElement = null;
		if (imgElementId)
		{
			imgElement = document.getElementById(imgElementId);
		}

		if (divElement.style.display=="")
		{
			divElement.style.display="none";
			divElement.style.visibility="hidden";
			if (imgElement && document.images[imgElement.id])
			{
				document.images[imgElement.id].src = "images/state_close.gif";
			}
			else if (imgElement)
			{
				imgElement.innerText = "+";
			}
		}
		else
		{
			// Show the current Divs/Images
			divElement.style.display = "";
			divElement.style.visibility="";
			if (imgElement && document.images[imgElement.id])
			{
				document.images[imgElement.id].src = "images/state_open.gif";
			}
			else if (imgElement)
			{
				imgElement.innerText = "-";
			}
		}

	}

	function HideDivElements ()
	{
		var args = HideDivElements.arguments;
		var divElement;
		for (var i = 0; i < args.length; i++)
		{
			divElement = args[i];
			divElement.style.display="none";
			divElement.style.visibility="hidden";
		}
	}

 	function renderHTML(htmlText, spanID){
 		document.all(spanID).insertAdjacentHTML("BeforeEnd", htmlText);
 	}

]]>
</SCRIPT>
</head>

<body>

<H3>SAPinst Parameters in INIfile XML</H3>
<!--
<H4>Used set of content DVDs</H4><pre style="font-size:x-small;position:relative;left:30px"><xsl:value-of select="document('.\start_dirs.xml')/root/used_dvds" /></pre>
-->
<H4>Number of tables in the file: <xsl:value-of select="count(//tables/tableset/table)" /> </H4>

	<xsl:for-each select="//tables/tableset/table">
		<xsl:sort select="./columns/column/defaultproperties/property[@name='SAPINST_ORIGINAL_TABLE_NAME']/@value" />
		<xsl:sort select="@name" />
		<!-- Rows count: [<xsl:value-of select="count(./row/fld)" />] -->

		<span class="link" onclick="DivElementClick('{concat('param_table', position())}', '{concat('img_param_table', position())}')">
			[<span id="{concat('img_param_table', position())}">+</span>]<b>&#160;&#160;&#160;
			<xsl:variable name="org_tbl_name" select="./columns/column/defaultproperties/property[@name='SAPINST_ORIGINAL_TABLE_NAME']/@value" />
			<xsl:choose>
				<xsl:when test="starts-with(@name, 'ParameterTable')">
					t_<xsl:call-template name="substring-after-last">
						<xsl:with-param name="input" select="@name"/>
						<xsl:with-param name="substr">
							<xsl:choose><xsl:when test="contains(@name, 'tSdbInstanceMedium')">_t</xsl:when><xsl:otherwise>t_</xsl:otherwise></xsl:choose>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="string-length($org_tbl_name) &gt; 0">
					<xsl:value-of select="$org_tbl_name" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@name" />
				</xsl:otherwise>
			</xsl:choose>
			
			</b>
			<span style="position:absolute;left:420px">[<xsl:value-of select="count(.//column)" /> param/s&#160;<xsl:if test="starts-with(@name, 'ParameterTable') or (count(.//row) &gt; 1)"> X <xsl:value-of select="count(.//row)"/> rows in a Table</xsl:if>]</span>
		</span>

		<div id="{concat('param_table', position())}"  style="display: none; visibility: hidden;position:relative;left:30px">
		<span style="position:relative;left:0px; color:brown;">
			<xsl:call-template name="search-and-replace">
				<xsl:with-param name="input" select="@name" />
				<xsl:with-param name="search-string" select="'-ind-ind-ind-ind'" />
				<xsl:with-param name="replace-string" select="''" />
			</xsl:call-template>
		</span>
		<table width="90%" border="0" cellpadding="1" cellspacing="1" class="tbl"
			style="margin-top:6px; margin-left:4px; border-left: 1px solid gray; border-top: 1px solid gray; border-right: 1px solid darkgray; border-bottom: 1px solid darkgray;">

		<xsl:if test="(count(.//row) &lt;= 1)">
			<tr style="background-color: #D1D7DC">
				<td width="10%">Name</td>
				<td width="30%">Value</td>
				<td width="60%">Description</td>
			</tr>
			<xsl:for-each select=".//column">
				
			<tr>
				<td><b style="color:darkblue;"><xsl:value-of select="@name" /></b></td>
				<xsl:variable name="prop_value" select="../../row/fld[@name=current()/@name]/strval" />
				<td><nobr><b>
					<font>
						<xsl:attribute name="color">
							<xsl:choose><xsl:when test="starts-with($prop_value, 'true')">green</xsl:when><xsl:otherwise>black</xsl:otherwise></xsl:choose>
						</xsl:attribute>
						<xsl:value-of select="$prop_value" />
					</font>
					</b></nobr>
				</td>
				<td><xsl:value-of select="../../row/fld[@name=current()/@name]/properties/property[@name='doc-long']/@value" /></td>
			</tr>
			</xsl:for-each>
		</xsl:if>
		<xsl:if test="count(.//row) &gt; 1">
			<tr>
				<td colspan="{count(.//column)}">
				<xsl:for-each select="./row[1]//fld/properties/property[@name='TABLE_DOC_SHORT_LONG']">
					<xsl:value-of select="@value"/>
				</xsl:for-each>
				</td>
			</tr>
			<tr style="background-color: #D1D7DC">
				<xsl:for-each select=".//column">
					<td width="10%"><b style="color:darkblue;"><xsl:value-of select="@name" /></b></td>
				</xsl:for-each>
			</tr>
			<xsl:for-each select=".//row">
				<xsl:variable name="current_row" select="position()" />
			<tr>
				<xsl:for-each select="../columns/column">
					<xsl:variable name="prop_tbl_value" select="../../row[position()=$current_row]/fld[@name=current()/@name]/strval" />
					<td><nobr><b>
						<font>
							<xsl:attribute name="color">
								<xsl:choose><xsl:when test="starts-with($prop_tbl_value, 'true')">green</xsl:when><xsl:otherwise>black</xsl:otherwise></xsl:choose>
							</xsl:attribute>
							<xsl:value-of select="$prop_tbl_value" />
						</font>
						</b></nobr>
					</td>
				</xsl:for-each>
			</tr>
			</xsl:for-each>
		</xsl:if>
		</table>
		</div>
		<br/>
	</xsl:for-each>

</body>
</html>

</xsl:template>

<xsl:template name="search-and-replace">
     <xsl:param name="input"/>
     <xsl:param name="search-string"/>
     <xsl:param name="replace-string"/>
     <xsl:choose>
          <!-- See if the input contains the search string -->
          <xsl:when test="$search-string and
                           contains($input,$search-string)">
          <!-- If so, then concatenate the substring before the search
          string to the replacement string and to the result of
          recursively applying this template to the remaining substring.
          -->
               <xsl:value-of
                    select="substring-before($input,$search-string)"/>
               <xsl:value-of select="$replace-string"/>
               <xsl:call-template name="search-and-replace">
                    <xsl:with-param name="input"
                    select="substring-after($input,$search-string)"/>
                    <xsl:with-param name="search-string"
                    select="$search-string"/>
                    <xsl:with-param name="replace-string"
                        select="$replace-string"/>
               </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
               <!-- There are no more occurences of the search string so
               just return the current input string -->
               <xsl:value-of select="$input"/>
          </xsl:otherwise>
     </xsl:choose>
</xsl:template>


<xsl:template name="substring-after-last">
<xsl:param name="input"/>
<xsl:param name="substr"/>
   
<!-- Extract the string which comes after the first occurence -->
<xsl:variable name="temp" select="substring-after($input,$substr)"/>
   
<xsl:choose>
     <!-- If it still contains the search string the recursively process -->
     <xsl:when test="$substr and contains($temp,$substr)">
          <xsl:call-template name="substring-after-last">
               <xsl:with-param name="input" select="$temp"/>
               <xsl:with-param name="substr" select="$substr"/>
          </xsl:call-template>
     </xsl:when>
     <xsl:otherwise>
          <xsl:value-of select="$temp"/>
     </xsl:otherwise>
</xsl:choose>
</xsl:template>

</xsl:stylesheet>
