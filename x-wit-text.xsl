<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  
  <xsl:output method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>

  <xsl:param name="wit_ref">
    <xsl:value-of select="concat('#', $wit_id)"/>
  </xsl:param>

  <xsl:preserve-space elements=""/>
  <xsl:strip-space elements="t:listWit"/>

  <!-- identity transformation -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- header -->
  <xsl:template match="t:titleStmt/t:title/text()">
    <xsl:copy/>
    <xsl:text>, witness </xsl:text>
    <xsl:value-of select="$wit_id"/>
  </xsl:template>

  <xsl:template match="t:listWit/t:witness">
    <xsl:if test="@xml:id = $wit_id">
      <xsl:copy>
	<xsl:apply-templates/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <!-- text -->
  <xsl:template match="t:app">
    <xsl:choose>
      <!-- only wit -->
      <xsl:when test="*/@wit = $wit_ref"> 
	<xsl:value-of select="*[@wit = $wit_ref]"/>
      </xsl:when>
      <!-- all but last wit -->
      <xsl:when test="*[contains(@wit, concat($wit_ref, ' '))]">
	<xsl:value-of select="*[contains(@wit, concat($wit_ref, ' '))]"/>
      </xsl:when>
      <!-- end of wit-list -->
      <xsl:when test="*[contains(@wit, concat(' ', $wit_ref))]">
	<xsl:value-of select="*[contains(@wit, concat(' ', $wit_ref))]"/>
      </xsl:when>
      <!-- base witness for ac and pc readings -->
      <xsl:when test="contains($wit_ref, 'ac')">
	<xsl:variable name="base_wit">
	  <xsl:value-of select="substring-before($wit_ref, 'ac')"/>
	</xsl:variable>
	<xsl:choose>
	  <!-- only wit -->
	  <xsl:when test="*/@wit = $base_wit"> 
	    <xsl:value-of select="*[@wit = $base_wit]"/>
	  </xsl:when>
	  <!-- all but last wit -->
	  <xsl:when test="*[contains(@wit, concat($base_wit, ' '))]">
	    <xsl:value-of select="*[contains(@wit, concat($base_wit, ' '))]"/>
	  </xsl:when>
	  <!-- end of wit-list -->
	  <xsl:when test="*[contains(@wit, concat(' ', $base_wit))]">
	    <xsl:value-of select="*[contains(@wit, concat(' ', $base_wit))]"/>
	  </xsl:when>
	  <!-- implicit reading with ceteri-->
	  <xsl:otherwise>
	    <xsl:value-of select="*[@wit = '#ceteri']"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:when test="contains($wit_ref, 'pc')">
	<xsl:variable name="base_wit">
	  <xsl:value-of select="substring-before($wit_ref, 'pc')"/>
	</xsl:variable>
	<xsl:choose>
	  <!-- only wit -->
	  <xsl:when test="*/@wit = $base_wit"> 
	    <xsl:value-of select="*[@wit = $base_wit]"/>
	  </xsl:when>
	  <!-- all but last wit -->
	  <xsl:when test="*[contains(@wit, concat($base_wit, ' '))]">
	    <xsl:value-of select="*[contains(@wit, concat($base_wit, ' '))]"/>
	  </xsl:when>
	  <!-- end of wit-list -->
	  <xsl:when test="*[contains(@wit, concat(' ', $base_wit))]">
	    <xsl:value-of select="*[contains(@wit, concat(' ', $base_wit))]"/>
	  </xsl:when>
	  <!-- implicit reading with ceteri-->
	  <xsl:otherwise>
	    <xsl:value-of select="*[@wit = '#ceteri']"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <!-- implicit reading with ceteri-->
      <xsl:otherwise>
	<xsl:value-of select="*[@wit = '#ceteri']"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- deletions -->
  <xsl:template match="t:note"/>
  
</xsl:stylesheet>
