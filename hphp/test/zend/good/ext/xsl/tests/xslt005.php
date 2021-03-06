<?hh
<<__EntryPoint>> function main(): void {
echo "Test 5: Checking Indent";
include("prepare.inc");
$xsl = XSLTPrepare::getXSL();
$xp = new DOMXPath($xsl);
$res = $xp->query("/xsl:stylesheet/xsl:output/@indent");
if ($res->length != 1) {
    print "No or more than one xsl:output/@indent found";
    exit;
}
$res->item(0)->value = "yes";
$proc = XSLTPrepare::getProc();
$proc->importStylesheet($xsl);
print "\n";
print $proc->transformToXML(XSLTPrepare::getDOM());
print "\n";
}
