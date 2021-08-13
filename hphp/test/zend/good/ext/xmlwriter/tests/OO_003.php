<?hh
/* $Id$ */
<<__EntryPoint>> function main(): void {
$xw = new XMLWriter();
$xw->openMemory();
$xw->startDocument('1.0', 'UTF-8');
$xw->startElement("tag1");

$res = $xw->startAttribute('attr1');
$xw->text("attr1_value");
$xw->endAttribute();

$res = $xw->startAttribute('attr2');
$xw->text("attr2_value");
$xw->endAttribute();

$xw->text("Test text for tag1");
$res = $xw->startElement('tag2');
if (HH\Lib\Legacy_FIXME\lt($res, 1)) {
    echo "StartElement context validation failed\n";
    exit();
}
$xw->endDocument();

// Force to write and empty the buffer
echo $xw->flush(true);
echo "===DONE===\n";
}
