<?hh

//var_dump($proc->registerPHPFunctions(array()));
//var_dump($proc->transformToXML($dom));

<<__EntryPoint>>
function main_entry(): void {
  include dirname(__FILE__) .'/prepare.inc';
  $phpfuncxsl = new DOMDocument();
  $phpfuncxsl->load(dirname(__FILE__)."/phpfunc.xsl");
  if(!$phpfuncxsl) {
    echo "Error while parsing the xsl document\n";
    exit;
  }
  $proc = XSLTPrepare::getProc();
  $proc->importStylesheet($phpfuncxsl);
  var_dump($proc->registerPHPFunctions());
  var_dump($proc->transformToXML(XSLTPrepare::getDOM()));
}
