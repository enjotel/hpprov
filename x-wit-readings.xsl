<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  
  <xsl:output method="text" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>

  <xsl:param name="wit_ref">
    <xsl:value-of select="concat('#', $wit_id, ' ')"/>
  </xsl:param>

  <xsl:preserve-space elements=""/>
  <xsl:strip-space elements="t:listWit"/>

  <xsl:template match="/">
    <xsl:value-of select="$wit_id"/>
    <xsl:text>,</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
</xsl:text>
  </xsl:template>
  
  <!-- text -->
  <xsl:template match="t:app[*[@type='stemmapoint']]">
    <xsl:choose>
      <xsl:when test="*[contains(concat(@wit, ' '), $wit_ref)]">
	<xsl:value-of select="*[contains(concat(@wit, ' '), $wit_ref)]"/>
      </xsl:when>
      <!-- base witness for ac and pc readings -->
      <xsl:when test="contains($wit_ref, 'ac ')">
	<xsl:variable name="base_wit">
	  <xsl:value-of select="concat(substring-before($wit_ref, 'ac '), ' ')"/>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="*[contains(concat(@wit, ' '), $base_wit)]">
	    <xsl:value-of select="*[contains(concat(@wit, ' '), $base_wit)]"/>
	  </xsl:when>
	  <!-- implicit reading with ceteri-->
	  <xsl:otherwise>
	    <xsl:value-of select="*[@wit = '#ceteri']"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:when test="contains($wit_ref, 'pc ')">
	<xsl:variable name="base_wit">
	  <xsl:value-of select="concat(substring-before($wit_ref, 'pc '), ' ')"/>
	</xsl:variable>
	<xsl:choose>
	  <xsl:when test="*[contains(concat(@wit, ' '), $base_wit)]">
	    <xsl:value-of select="*[contains(concat(@wit, ' '), $base_wit)]"/>
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
    <xsl:text>,</xsl:text>
  </xsl:template>

  <!-- ignore everything else -->
  <xsl:template match="@*|node()">
    <xsl:apply-templates/>
  </xsl:template>
  
</xsl:stylesheet>
