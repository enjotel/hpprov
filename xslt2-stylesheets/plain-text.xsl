<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
  exclude-result-prefixes="xsl" 
  xpath-default-namespace="http://www.tei-c.org/ns/1.0">
  
  <xsl:output method="text" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>
  
  <xsl:preserve-space elements="reg orig"/>
  <xsl:strip-space elements="teiHeader sourceDesc biblStruct monogr listWit witness text body div lg app cit notesStmt note"/>
  <xsl:template match="/">
    <xsl:if test="TEI/teiHeader/fileDesc/titleStmt/author[text()]">
      <xsl:value-of select="TEI/teiHeader/fileDesc/titleStmt/author"/><xml:text>: </xml:text>
    </xsl:if>
    <xsl:if test="TEI/teiHeader/fileDesc/titleStmt/title[text()]">
      <xsl:value-of select="TEI/teiHeader/fileDesc/titleStmt/title"/>
      <xsl:value-of select="$n"/>
      <xsl:value-of select="$n"/>
      <xsl:value-of select="$n"/>
    </xsl:if>
    <xsl:apply-templates select="TEI/text/body"/>
  </xsl:template>
  
  <!-- variables and keys -->
  <xsl:variable name="n">
    <xsl:text>
</xsl:text>
  </xsl:variable>
  
  <!-- text -->
  <!-- normalize output on all text nodes -->
  <xsl:template match="TEI/text//text()">
    <xsl:value-of select="lower-case(replace(replace(., '\s+', ' '),
			  '[ẖḫ]', 'ḥ'))"/>
  </xsl:template>

  <!--add whitespace for different contexts -->
  <xsl:template match="head">
    <xsl:value-of select="$n"/>
    <xsl:value-of select="$n"/>
    <xsl:apply-templates/>
    <xsl:value-of select="$n"/>
  </xsl:template>

  <xsl:template match="trailer">
    <xsl:value-of select="$n"/>
    <xsl:apply-templates/>
    <xsl:value-of select="$n"/>
  </xsl:template>

  <xsl:template match="p">
    <xsl:value-of select="$n"/>
    <xsl:apply-templates/>
    <xsl:if test="@xml:id">
      <xsl:text>(</xsl:text><xsl:call-template name="id2inlineref"/><xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:value-of select="$n"/>
  </xsl:template>

  <xsl:template match="lg">
    <xsl:value-of select="$n"/>
    <xsl:apply-templates/>
    <!-- print id if specified -->
    <xsl:if test="@xml:id">
      <xsl:text> </xsl:text><xsl:call-template name="id2inlineref"/>
    </xsl:if>
    <xsl:value-of select="$n"/>
  </xsl:template>

  <xsl:template match="lg/l">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::l">
      <xsl:value-of select="$n"/>
    </xsl:if>
  </xsl:template>
  
  <!-- prose div with ID -->
  <xsl:template match="div[@xml:id]">
    <xsl:apply-templates/>
    <xsl:text>(</xsl:text><xsl:call-template name="id2inlineref"/><xsl:text>)</xsl:text>
    <xsl:value-of select="$n"/>
  </xsl:template>

  <!-- commentary -->
  <xsl:template match="note[@type='commentary']">
    <xsl:element name="div">
      <xsl:apply-templates/>
      <!-- add id if specified -->
      <xsl:if test="@xml:id">
	<xsl:text>(</xsl:text><xsl:call-template name="id2inlineref"/><xsl:text>)</xsl:text>
	<xsl:value-of select="$n"/>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!-- add changed IDs inline -->
  <xsl:template name="id2inlineref">
    <xsl:choose>
      <!-- with @n attribute, always replace @xml:id -->
      <xsl:when test="@n">
	<xsl:value-of select="@n"/>
      </xsl:when>
      <!-- 4 levels -->
      <xsl:when test="matches(@xml:id, '\w+_\d+\.\d+\.\d+\.\d+')">
	<xsl:value-of select="replace(@xml:id, '(\w+_\d+)\.(\d+)\.(\d+)\.(\d+)', '$1;$2,$3.$4')"/>
      </xsl:when>
      <!-- 3 levels -->
      <xsl:when test="matches(@xml:id, '\w+_\d+\.\d+\.\d+')">
	<xsl:value-of select="replace(@xml:id, '(\w+_\d+)\.(\d+)\.(\d+)', '$1,$2.$3')"/>
      </xsl:when>
      <!-- 2 & 1 levels -->
      <xsl:otherwise>
	<xsl:value-of select="@xml:id"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- if corresp exists -->
    <xsl:if test="@corresp">
      <xsl:text> [= </xsl:text>
      <xsl:choose>
	<xsl:when test="starts-with(@corresp, '#')"><!-- internal link-->
	  <xsl:call-template name="id2inlinecorresp"/>
	</xsl:when>
	<xsl:when test="contains(@corresp, '.xml#')"><!-- external link-->
	    <xsl:call-template name="id2inlinecorresp"/>
	</xsl:when>
	<xsl:otherwise><!-- not a link-->
	  <xsl:value-of select="@corresp"/>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="id2inlinecorresp">
    <xsl:choose>
      <!-- 4 levels -->
      <xsl:when test="matches(substring-after(@corresp, '#'), '\w+_\d+\.\d+\.\d+\.\d+')">
	<xsl:value-of select="replace(substring-after(@corresp, '#'), '(\w+_\d+)\.(\d+)\.(\d+)\.(\d+)', '$1;$2,$3.$4')"/>
      </xsl:when>
      <!-- 3 levels -->
      <xsl:when test="matches(substring-after(@corresp, '#'), '\w+_\d+\.\d+\.\d+')">
	<xsl:value-of select="replace(substring-after(@corresp, '#'), '(\w+_\d+)\.(\d+)\.(\d+)', '$1,$2.$3')"/>
      </xsl:when>
      <!-- 2 & 1 levels -->
      <xsl:otherwise>
	<xsl:value-of select="substring-after(@corresp, '#')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- choices -->
  <xsl:template match="choice">
    <xsl:value-of select="reg"/>
  </xsl:template>

  <!-- apparatus -->
  <xsl:template match="app//rdg | app/lem">
    <xsl:choose>
      <xsl:when test="lem">
	<xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="position() = 1">
	<xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

  <!-- special rules for header -->
  <!-- keep refs in header -->
  <xsl:template match="teiHeader//ref">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- gaps, both illegible and lacunae -->
  <xsl:template match="gap">
    <xsl:choose>
      <xsl:when test="(@quantity and (@unit='akṣaras' or @unit='syllables' or @unit='characters'))">
	<xsl:text>[</xsl:text>
	<xsl:for-each select="1 to @quantity">.. </xsl:for-each>
	<xsl:text>]</xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>[…]</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- deletions -->
  <xsl:template match="teiHeader/*"/>
  <xsl:template match="note"/>
  <xsl:template match="ref"/>
  <xsl:template match="witDetail"/>
  <xsl:template match="orig"/>
  <xsl:template match="pb"/>
  <xsl:template match="lb"/>
  <xsl:template match="milestone"/><!-- milestone-units, currently in use: with @unit="speaker" for a change of speakers inside <lg/> -->
  <xsl:template match="link"/>
  <xsl:template match="surplus"/>
  <xsl:template match="del"/>

  <!-- skips -->
  <xsl:template match="seg">
    <xsl:apply-templates/>
  </xsl:template>
  
</xsl:stylesheet>
