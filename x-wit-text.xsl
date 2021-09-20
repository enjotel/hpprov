<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  
  <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

  <xsl:param name="wit_ref">
    <xsl:value-of select="concat('#', $wit_id, ' ')"/>
  </xsl:param>

  <xsl:preserve-space elements=""/>
  <xsl:strip-space elements="t:listWit"/>

  <!-- identity transformation -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- saktumiva header -->
  <xsl:template match="t:teiHeader">
    <teiHeader>
      <fileDesc>
	<titleStmt>
	  <title>
	    <xsl:value-of select="normalize-space(//t:witness[@xml:id=$wit_id])"/>
	  </title>
	</titleStmt>
	<sourceDesc>
	  <msDesc>
            <msIdentifier>
              <placeName>
		<settlement>[city, town, or village]</settlement>
		<region>[region]</region>
		<country>[country]</country>
              </placeName>
              <institution>[institution]</institution>
              <repository>[repository]</repository>
              <collection>[collection]</collection>
              <idno>[manuscript identifier]</idno>
              <idno type="NCC">[NCC identifier]</idno>
              <idno type="siglum">
		<xsl:value-of select="$wit_id"/>
	      </idno>
            </msIdentifier>
            <msContents>
              <summary>[description of manuscript]</summary>
              <msItem n="1" defective="true">
		<!-- @defective: 'false' for complete, 'true' for incomplete -->
		<author xml:lang="sa" role="author">[author]</author>
		<author xml:lang="sa" role="commentator">[commentator]</author>
		<title xml:lang="sa">[title of text]</title>
		<title xml:lang="sa" type="commentary">[title of commentary]</title>
		<!-- rubric, incipit, explicit, and finalRubric are given as examples -->
		<rubric xml:lang="sa"></rubric>
		<incipit xml:lang="sa"></incipit>
		<explicit xml:lang="sa"></explicit>
		<finalRubric xml:lang="sa"></finalRubric>
		<textLang mainLang="sa">[Sanskrit in Devanāgarī script.]</textLang>
		<!-- @mainLang can be "sa-Deva", "sa-Mlym", "sa-Telu", "sa-Newa", etc. See ISO 15924 for more details. -->
              </msItem>
            </msContents>
            <physDesc>
              <objectDesc form="pothi">
		<!-- @form can be "pothi", "book", scroll", etc. -->
		<supportDesc material="paper">
		  <!-- @material can be "paper", "industrial paper", "handmade paper", "palm-leaf", "palmyra palm-leaf", "talipot palm-leaf", "birch bark", "vellum", etc. -->
		  <extent>
                    <measure quantity="XX" unit="folios"/>
                    <!-- @unit can be "folios" or "pages" -->
                    <dimensions type="leaf" unit="cm">
                      <!-- @unit can be "cm" or "in" -->
                      <height>[height]</height>
                      <width>[width]</width>
                    </dimensions>
                    <dimensions type="written" unit="cm">
                      <!-- dimensions of writing area -->
                      <height>[height]</height>
                      <width>[width]</width>
                    </dimensions>
		  </extent>
		  <foliation/>
		  <condition>[whether the manuscript is complete, description of wear and damage]</condition>
		</supportDesc>
		<layoutDesc>
		  <layout columns="@@Columns@@" writtenLines="XX" ruledLines="XX">
                    <!-- @writtenLines is the number of lines of text per page. @ruledLines is the number of rulings that have been printed or impressed on a page, i.e. the number of lines in a blank notebook. -->
                    <p>[description of marginal frame lines, etc.]</p>
		  </layout>
		</layoutDesc>
              </objectDesc>
	      <handDesc>
		<handNote scope="sole" script="devanāgarī" medium="black ink">
                  <p>[description of one hand]</p>
		</handNote>
		<handNote scope="major" script="devanāgarī" medium="red ink">
                  <p>[description of another hand]</p>
		</handNote>
		<handNote scope="minor" script="english" medium="green highlighter">
                  <p>[description of another hand]</p>
		</handNote>
              </handDesc>
	      <additions>
		<!-- the following additions are examples -->
		<p>[additional remarks]</p>
              </additions>
              <bindingDesc>
		<p>[description of cover, binding, and/or stringholes]</p>
              </bindingDesc>
            </physDesc>
            <history>
              <origin>
		<origDate calendar="" when="">[date]</origDate>
		<!-- calendar can be "Vikrama", "Śaka", etc. Dates can be approximate or exact. -->
		<origPlace xml:lang="en">[place of production]</origPlace>
              </origin>
              <provenance>[record of ownership]</provenance>
              <acquisition>[how it was acquired]</acquisition>
            </history>
	  </msDesc>
	</sourceDesc>
      </fileDesc>
      <revisionDesc>
	<xsl:element name="change">
	  <xsl:attribute name="when">
	    <xsl:value-of select="$date"/>
	  </xsl:attribute>witness extracted by <ref target="https://github.com/radardenker/hp-witness-extraction">hp-witness-extraction</ref></xsl:element>
      </revisionDesc>
    </teiHeader>
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
  </xsl:template>

  <!-- deletions -->
  <xsl:template match="t:note"/>
  
</xsl:stylesheet>
